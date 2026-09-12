/*
 * Copyright (c) 2024-2026 Fabian Freund.
 *
 * This file is part of WebLibre
 * (see https://weblibre.eu).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// Mirrors the record model of Zen Browser's ZenSpacesSync (MPL-2.0), src/zen/sync/, commit 22961e9.
import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers/lifecycle.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/spaces_sync/data/models/zen_records.dart';
import 'package:weblibre/features/spaces_sync/data/snapshot_store.dart';
import 'package:weblibre/features/spaces_sync/data/sync15/key_bundle.dart';
import 'package:weblibre/features/spaces_sync/data/sync15/storage_client.dart';
import 'package:weblibre/features/spaces_sync/data/sync15/tokenserver_client.dart';
import 'package:weblibre/features/spaces_sync/domain/batch_validator.dart';
import 'package:weblibre/features/spaces_sync/domain/entities/spaces_sync_status.dart';
import 'package:weblibre/features/spaces_sync/domain/providers.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_applier.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_projection.dart';
import 'package:weblibre/features/sync/domain/repositories/sync.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

part 'spaces_sync_service.g.dart';

/// The collection this client owns a slice of (PLAN §4.1).
const spacesCollection = 'spaces';

/// The only `meta/global.engines.spaces.version` this client writes (PLAN
/// §8.6 item 3).
const spacesEngineVersion = 3;

const _periodicInterval = Duration(minutes: 1);
const _localChangeDebounce = Duration(seconds: 3);
const _tokenExpiryMargin = Duration(seconds: 60);

/// Thrown when the outgoing batch fails [validateOutgoingBatch]: nothing
/// leaves the device (PLAN §8.6 item 2).
class OutgoingBatchRejected implements Exception {
  OutgoingBatchRejected(this.violations);

  final List<BatchViolation> violations;

  @override
  String toString() =>
      'outgoing batch refused: ${violations.take(5).join('; ')}'
      '${violations.length > 5 ? ' (+${violations.length - 5} more)' : ''}';
}

/// Everything one sync run needs after the handshake.
class _Session {
  _Session({required this.client, required this.keys});

  final SyncStorageClient client;
  final KeyBundle keys;
}

/// The two-way Firefox Sync client for Zen's `spaces` collection (PLAN §8,
/// W6.3). Runs on start, on resume, every minute in the foreground, three
/// seconds after the tab model last changed, and from `background_fetch`;
/// every run is serialised through one lock.
@Riverpod(keepAlive: true)
class SpacesSyncService extends _$SpacesSyncService {
  final _lock = Lock();
  var _rerunRequested = false;
  SyncToken? _token;
  Timer? _periodic;
  StreamSubscription<void>? _localChanges;
  var _foreground = true;

  @override
  SpacesSyncStatus build() {
    ref.listen(browserRestoreCompleteProvider, fireImmediately: true, (
      previous,
      next,
    ) {
      if (next && previous != true) {
        _requestSync('start');
      }
    });

    ref.listen(browserViewLifecycleProvider, (previous, next) {
      final resumed = next == null || next == AppLifecycleState.resumed;
      _foreground = resumed;
      _armPeriodicTimer();
      if (next == AppLifecycleState.resumed &&
          previous != AppLifecycleState.resumed) {
        _requestSync('resume');
      }
    });

    ref.listen(
      generalSettingsWithDefaultsProvider.select(
        (settings) => settings.spacesSyncEnabled,
      ),
      (previous, next) {
        if (next && previous == false) {
          _requestSync('enabled');
        }
      },
    );

    final db = ref.watch(tabDatabaseProvider);
    _localChanges = db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            db.tab,
            db.space,
            db.tabFolder,
            db.tabSplit,
            db.container,
            db.deletedRecord,
          ]),
        )
        .debounceTime(_localChangeDebounce)
        .listen((_) => _requestSync('local-change'));

    _armPeriodicTimer();

    ref.onDispose(() {
      _periodic?.cancel();
      unawaited(_localChanges?.cancel());
    });

    return SpacesSyncStatus();
  }

  void _armPeriodicTimer() {
    _periodic?.cancel();
    _periodic = null;
    if (_foreground) {
      _periodic = Timer.periodic(
        _periodicInterval,
        (_) => _requestSync('periodic'),
      );
    }
  }

  /// Fire-and-forget entry for the schedulers: coalesces bursts into one
  /// run after the current one, and stays quiet while the session is still
  /// being restored (the tab model is in flux then).
  void _requestSync(String reason) {
    if (!ref.read(browserRestoreCompleteProvider)) {
      return;
    }
    unawaited(
      sync(reason: reason).catchError((Object error, StackTrace stackTrace) {
        logger.e(
          'spaces sync: scheduled run ($reason) failed',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  /// One full sync: fetch and apply what changed on the server, then upload
  /// what changed here. Serialised; a call during a run queues exactly one
  /// more run. Never throws — failures land in [SpacesSyncStatus.lastError].
  Future<void> sync({String reason = 'manual'}) async {
    if (_lock.locked) {
      _rerunRequested = true;
      return _lock.synchronized(() {});
    }
    await _lock.synchronized(() async {
      do {
        _rerunRequested = false;
        await _syncOnce(reason);
      } while (_rerunRequested);
    });
  }

  Future<void> _syncOnce(String reason) async {
    final settingsRepo = ref.read(generalSettingsRepositoryProvider.notifier);
    var settings = await settingsRepo.fetchSettings();
    if (!settings.spacesSyncEnabled) {
      return;
    }
    if (!ref.read(syncIsAuthenticatedProvider)) {
      return;
    }
    final credentials = await ref.read(spacesSyncCredentialsProvider)();
    if (credentials == null) {
      return;
    }

    logger.i('spaces sync: run ($reason)');
    state = state.copyWith(syncing: true);
    try {
      final client = await _storageClient(credentials);
      final metaGlobal = await client.getMetaGlobal();
      final engine = metaGlobal?.spacesEngine;
      if (engine == null) {
        // Zen owns the engine entry; until the desktop creates it there is
        // nothing to read and nothing safe to write.
        logger.i('spaces sync: no spaces engine in meta/global; idle');
        state = state.copyWith(
          engineEnabled: false,
          lastSyncAt: DateTime.now(),
          lastError: null,
        );
        return;
      }

      final writesBlockedReason = engine.version == spacesEngineVersion
          ? null
          : 'The desktop uses spaces format version ${engine.version}; '
                'this app only writes version $spacesEngineVersion. '
                'Reading only until the app is updated.';
      if (writesBlockedReason != null) {
        logger.w('spaces sync: $writesBlockedReason');
      }

      if (engine.syncId != settings.spacesSyncLastSyncId) {
        logger.w(
          'spaces sync: syncID changed '
          '(${settings.spacesSyncLastSyncId} -> ${engine.syncId}); '
          'resetting local sync state',
        );
        await _resetSyncState(engine.syncId);
        settings = await settingsRepo.fetchSettings();
      }

      if (settings.spacesSyncApplierVersion != spacesApplierVersion) {
        logger.i(
          'spaces sync: applier version '
          '${settings.spacesSyncApplierVersion} -> $spacesApplierVersion; '
          're-applying the whole collection',
        );
        await _resetForApplierVersion();
        settings = await settingsRepo.fetchSettings();
      }

      final keys = await client.getCryptoKeys(
        KeyBundle.fromSyncKey(_decodeSyncKey(credentials.syncKeyBase64Url)),
      );
      final session = _Session(
        client: client,
        keys: keys.bundleFor(spacesCollection),
      );

      // Decided before the fetch flips the flag: the first sync of a device
      // never projects a tombstone (PLAN §8.6 item 4).
      final firstSync = !settings.spacesSyncBaselineDone;
      final applied = await _fetchAndApply(session, settings);
      settings = await settingsRepo.fetchSettings();

      if (!settings.spacesSyncWritesEnabled) {
        logger.i('spaces sync: uploads disabled by the kill switch');
      } else if (writesBlockedReason == null) {
        await _upload(
          session,
          settings,
          applied,
          tombstonesAllowed: !firstSync,
        );
      }

      state = state.copyWith(
        lastSyncAt: DateTime.now(),
        lastError: null,
        writesBlockedReason: writesBlockedReason,
        engineVersionSeen: engine.version,
        engineEnabled: true,
      );
    } on SyncAuthException catch (e, s) {
      // The Hawk token expired mid-run; the next run fetches a fresh one.
      _token = null;
      logger.w(
        'spaces sync: storage rejected the token',
        error: e,
        stackTrace: s,
      );
      state = state.copyWith(lastError: 'Sync credentials expired; retrying');
    } catch (e, s) {
      logger.e('spaces sync: run failed', error: e, stackTrace: s);
      state = state.copyWith(lastError: e.toString());
    } finally {
      state = state.copyWith(syncing: false);
    }
  }

  /* Mark: handshake */

  static List<int> _decodeSyncKey(String base64UrlKey) =>
      base64Url.decode(base64Url.normalize(base64UrlKey));

  Future<SyncStorageClient> _storageClient(
    SpacesSyncCredentials credentials,
  ) async {
    final httpClient = ref.read(spacesSyncHttpClientProvider);
    var token = _token;
    final expiresAt = token?.obtainedAt.add(token.duration);
    if (token == null ||
        expiresAt == null ||
        DateTime.now().isAfter(expiresAt.subtract(_tokenExpiryMargin))) {
      token = await TokenServerClient(httpClient).fetch(
        tokenServerUrl: Uri.parse(credentials.tokenServerUrl),
        accessToken: credentials.accessToken,
        kid: credentials.keyId,
      );
      _token = token;
    }
    return SyncStorageClient(httpClient, token);
  }

  /// A new `syncID` is how Firefox Sync signals a reset: every digest and
  /// foreign copy is stale, the baseline has to be refetched, and nothing
  /// may be tombstoned until it has (PLAN §8.3 item 4).
  Future<void> _resetSyncState(String syncId) async {
    final db = ref.read(tabDatabaseProvider);
    await db.syncStateDao.clearAll();
    await db.syncStateDao.clearAllForeign();
    await db.syncStateDao.clearAllDeletions();
    await ref.read(spacesSyncSnapshotStoreProvider).writeFailedIds({});
    await ref
        .read(generalSettingsRepositoryProvider.notifier)
        .updateSettings(
          (current) => current
              .copyWith(
                spacesSyncLastSyncId: syncId,
                spacesSyncBaselineDone: false,
              )
              .copyWith
              .spacesSyncLastModified(null),
        );
  }

  /// A new applier files rows differently: forget every digest and foreign
  /// copy and fetch from the beginning, so the next run re-applies every
  /// remote record (incoming always wins, PLAN §4.4). The baseline flag and
  /// syncID stay — this is not a first sync — and with no digest stored no
  /// tombstone can be projected from it either.
  Future<void> _resetForApplierVersion() async {
    final db = ref.read(tabDatabaseProvider);
    await db.syncStateDao.clearAll();
    await db.syncStateDao.clearAllForeign();
    await ref
        .read(generalSettingsRepositoryProvider.notifier)
        .updateSettings(
          (current) => current
              .copyWith(spacesSyncApplierVersion: spacesApplierVersion)
              .copyWith
              .spacesSyncLastModified(null),
        );
  }

  /* Mark: incoming */

  /// Fetches what changed since the last run (everything, on the first),
  /// applies it and returns the ids that were applied — they leave this
  /// run's outgoing set (PLAN §4.4).
  Future<Set<String>> _fetchAndApply(
    _Session session,
    GeneralSettings settings,
  ) async {
    final store = ref.read(spacesSyncSnapshotStoreProvider);
    final firstSync = !settings.spacesSyncBaselineDone;
    final since = firstSync ? null : settings.spacesSyncLastModified;

    final fetched = await session.client.fetchCollection(
      spacesCollection,
      newer: since,
    );
    final bsos = <String, Bso>{for (final bso in fetched.records) bso.id: bso};

    final previouslyFailed = await store.readFailedIds();
    final refetch = previouslyFailed.difference(bsos.keys.toSet());
    if (refetch.isNotEmpty) {
      final again = await session.client.fetchCollection(
        spacesCollection,
        ids: refetch,
      );
      for (final bso in again.records) {
        bsos[bso.id] = bso;
      }
    }

    final records = <ZenIncoming>[];
    final cleartexts = <Map<String, Object?>>[];
    double? newest = fetched.lastModified;
    for (final bso in bsos.values) {
      try {
        final payload = jsonDecode(bso.payload) as Map<String, Object?>;
        final cleartext = await _decrypt(session, payload);
        cleartexts.add(cleartext);
        records.add(ZenRecordCodec.decode(cleartext));
      } catch (e, s) {
        logger.e(
          'spaces sync: record ${bso.id} could not be decrypted; skipped',
          error: e,
          stackTrace: s,
        );
      }
      final modified = bso.modified;
      if (modified != null && (newest == null || modified > newest)) {
        newest = modified;
      }
    }

    if (firstSync) {
      // The escape hatch: the whole collection as it was before this
      // profile ever wrote to it (PLAN §8.6 item 7).
      await store.write(cleartexts);
    }

    final failed = records.isEmpty
        ? <String>{}
        : await ref
              .read(spacesApplierProvider)
              .applyBatch(records, firstSync: firstSync);
    await store.writeFailedIds(failed);

    await ref
        .read(generalSettingsRepositoryProvider.notifier)
        .updateSettings(
          (current) => current
              .copyWith(spacesSyncBaselineDone: true)
              .copyWith
              .spacesSyncLastModified(newest ?? current.spacesSyncLastModified),
        );

    return {
      for (final record in records)
        if (!failed.contains(_idOf(record))) _idOf(record),
    };
  }

  static String _idOf(ZenIncoming record) => switch (record) {
    ZenIncomingRecord(:final cleartext) => cleartext.id,
    ZenIncomingTombstone(:final id) => id,
    ZenIncomingUnknownKind(:final id) => id,
  };

  Future<Map<String, Object?>> _decrypt(
    _Session session,
    Map<String, Object?> payload,
  ) async {
    final bso = Bso(id: '', payload: jsonEncode(payload));
    // `decryptBso` decodes straight to a ZenIncoming; the snapshot needs the
    // raw cleartext too, so decrypt through the crypto layer directly.
    final incoming = await session.client.decryptBso(bso, session.keys);
    return switch (incoming) {
      ZenIncomingRecord(:final cleartext) => cleartext.toJson(),
      ZenIncomingTombstone(:final id) => {'id': id, 'deleted': true},
      ZenIncomingUnknownKind(:final id, :final kind, :final rawData) => {
        'id': id,
        'kind': kind,
        'data': rawData,
      },
    };
  }

  /* Mark: outgoing */

  Future<void> _upload(
    _Session session,
    GeneralSettings settings,
    Set<String> appliedThisSync, {
    required bool tombstonesAllowed,
    bool retried = false,
  }) async {
    final db = ref.read(tabDatabaseProvider);
    final projected = await ref.read(spacesProjectionProvider).project();
    final stored = await db.syncStateDao.allDigests();

    final changed = <ZenCleartext>[];
    final digests = <String, String>{};
    for (final entry in projected.entries) {
      if (appliedThisSync.contains(entry.key)) {
        continue;
      }
      final digest = recordDigest(entry.value.kind, entry.value.data.toJson());
      digests[entry.key] = digest;
      if (stored[entry.key]?.digest != digest) {
        changed.add(entry.value);
      }
    }

    final tombstones = <String>[];
    if (tombstonesAllowed) {
      // Tombstones need a reason (PLAN §8.6 item 5): held before, and seen
      // deleted by the user here.
      final deletions = await db.syncStateDao.pendingDeletions();
      final closedTabs = (await db.tabDao.allClosedTabTombstoneIds().get())
          .toSet();
      for (final id in stored.keys) {
        if (projected.containsKey(id) || appliedThisSync.contains(id)) {
          continue;
        }
        if (deletions.containsKey(id) || closedTabs.contains(id)) {
          tombstones.add(id);
        }
      }
    }

    if (changed.isEmpty && tombstones.isEmpty) {
      return;
    }
    logger.i(
      'spaces sync: uploading ${changed.length} records, '
      '${tombstones.length} tombstones',
    );

    final validation = validateOutgoingBatch(
      changed,
      knownIds: {...projected.keys, ...await _localIds(db)},
      knownContainerGuids: await _localContainerGuids(db),
    );
    if (validation case BatchValidationRejected(:final violations)) {
      for (final violation in violations) {
        logger.e('spaces sync: outgoing batch violation: $violation');
      }
      throw OutgoingBatchRejected(violations);
    }

    final bsos = <Bso>[
      for (final record in changed)
        Bso(
          id: record.id,
          payload: await session.client.encryptCleartext(
            record.toJson(),
            session.keys,
          ),
        ),
      for (final id in tombstones)
        Bso(
          id: id,
          payload: await session.client.encryptCleartext(
            ZenTombstone(id: id).toJson(),
            session.keys,
          ),
        ),
    ];

    final PostResult result;
    try {
      result = await session.client.postRecords(
        spacesCollection,
        bsos,
        ifUnmodifiedSince: settings.spacesSyncLastModified ?? 0,
      );
    } on PreconditionFailed {
      if (retried) {
        rethrow;
      }
      // Someone else wrote first: take their changes, then try once more.
      logger.i('spaces sync: collection changed underneath us; refetching');
      final settingsRepo = ref.read(generalSettingsRepositoryProvider.notifier);
      final applied = await _fetchAndApply(session, settings);
      final refreshed = await settingsRepo.fetchSettings();
      return _upload(
        session,
        refreshed,
        {...appliedThisSync, ...applied},
        tombstonesAllowed: tombstonesAllowed,
        retried: true,
      );
    }

    final tombstoneIds = tombstones.toSet();
    for (final id in result.success) {
      if (tombstoneIds.contains(id)) {
        await db.syncStateDao.deleteDigest(id);
        await db.syncStateDao.clearDeletions([id]);
      } else if (digests[id] case final digest?) {
        await db.syncStateDao.putDigest(id, projected[id]!.kind, digest);
      }
    }
    for (final entry in result.failed.entries) {
      logger.w('spaces sync: server refused ${entry.key}: ${entry.value}');
    }
    if (result.modified case final modified?) {
      await ref
          .read(generalSettingsRepositoryProvider.notifier)
          .updateSettings(
            (current) => current.copyWith.spacesSyncLastModified(modified),
          );
    }
  }

  Future<Set<String>> _localIds(TabDatabase db) async {
    final ids = <String>{};
    ids.addAll(await db.tabDao.getAllTabIds().get());
    ids.addAll(
      (await (db.selectOnly(db.tabFolder)..addColumns([db.tabFolder.id])).get())
          .map((row) => row.read(db.tabFolder.id)!),
    );
    ids.addAll(
      (await (db.selectOnly(db.tabSplit)..addColumns([db.tabSplit.id])).get())
          .map((row) => row.read(db.tabSplit.id)!),
    );
    ids.addAll((await db.spaceDao.getAll()).map((space) => space.uuid));
    return ids;
  }

  Future<Set<String>> _localContainerGuids(TabDatabase db) async {
    final rows =
        await (db.selectOnly(db.container)
              ..addColumns([db.container.syncGuid])
              ..where(db.container.syncGuid.isNotNull()))
            .get();
    return {for (final row in rows) row.read(db.container.syncGuid)!};
  }

  /* Mark: snapshots */

  Future<List<SpacesSnapshot>> listSnapshots() =>
      ref.read(spacesSyncSnapshotStoreProvider).list();

  /// Uploads every record of [snapshot] and applies it locally too, so both
  /// sides converge on the saved state instead of this device re-uploading
  /// its own divergence on the next run. Gated by the kill switch.
  Future<void> restoreSnapshot(SpacesSnapshot snapshot) {
    return _lock.synchronized(() async {
      final settingsRepo = ref.read(generalSettingsRepositoryProvider.notifier);
      final settings = await settingsRepo.fetchSettings();
      if (!settings.spacesSyncWritesEnabled) {
        state = state.copyWith(
          lastError: 'Uploads are disabled; enable them to restore a snapshot',
        );
        return;
      }
      final credentials = await ref.read(spacesSyncCredentialsProvider)();
      if (credentials == null || !ref.read(syncIsAuthenticatedProvider)) {
        state = state.copyWith(lastError: 'Not signed in');
        return;
      }
      state = state.copyWith(syncing: true);
      try {
        final client = await _storageClient(credentials);
        final engine = (await client.getMetaGlobal())?.spacesEngine;
        if (engine == null || engine.version != spacesEngineVersion) {
          throw StateError(
            'the desktop spaces engine is missing or not version '
            '$spacesEngineVersion',
          );
        }
        final keys = await client.getCryptoKeys(
          KeyBundle.fromSyncKey(_decodeSyncKey(credentials.syncKeyBase64Url)),
        );
        final session = _Session(
          client: client,
          keys: keys.bundleFor(spacesCollection),
        );
        final records = await ref
            .read(spacesSyncSnapshotStoreProvider)
            .read(snapshot);
        final live = records.whereType<ZenIncomingRecord>().toList();
        final unknown = records.whereType<ZenIncomingUnknownKind>().toList();

        final bsos = <Bso>[
          for (final record in live)
            Bso(
              id: record.cleartext.id,
              payload: await session.client.encryptCleartext(
                record.cleartext.toJson(),
                session.keys,
              ),
            ),
          for (final record in unknown)
            Bso(
              id: record.id,
              payload: await session.client.encryptCleartext({
                'id': record.id,
                'kind': record.kind,
                'data': record.rawData,
              }, session.keys),
            ),
        ];
        final info = await client.getCollectionInfo();
        final result = await client.postRecords(
          spacesCollection,
          bsos,
          ifUnmodifiedSince: info[spacesCollection] ?? 0,
        );
        if (result.failed.isNotEmpty) {
          logger.w(
            'spaces sync: snapshot restore refused ${result.failed.length} '
            'records: ${result.failed}',
          );
        }
        await ref.read(spacesApplierProvider).applyBatch([
          ...live,
          ...unknown,
        ], firstSync: false);
        if (result.modified case final modified?) {
          await settingsRepo.updateSettings(
            (current) => current.copyWith.spacesSyncLastModified(modified),
          );
        }
        logger.i(
          'spaces sync: restored ${result.success.length} records from '
          '${snapshot.file.path}',
        );
        state = state.copyWith(lastSyncAt: DateTime.now(), lastError: null);
      } catch (e, s) {
        logger.e(
          'spaces sync: snapshot restore failed',
          error: e,
          stackTrace: s,
        );
        state = state.copyWith(lastError: e.toString());
      } finally {
        state = state.copyWith(syncing: false);
      }
    });
  }
}
