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
import 'dart:math';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:mellow/core/logger.dart';
import 'package:mellow/features/geckoview/domain/providers/restore_complete.dart';
import 'package:mellow/features/geckoview/features/browser/domain/providers/lifecycle.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/spaces_sync/data/models/zen_records.dart';
import 'package:mellow/features/spaces_sync/data/snapshot_store.dart';
import 'package:mellow/features/spaces_sync/data/sync15/key_bundle.dart';
import 'package:mellow/features/spaces_sync/data/sync15/storage_client.dart';
import 'package:mellow/features/spaces_sync/data/sync15/tokenserver_client.dart';
import 'package:mellow/features/spaces_sync/domain/batch_validator.dart';
import 'package:mellow/features/spaces_sync/domain/entities/spaces_sync_status.dart';
import 'package:mellow/features/spaces_sync/domain/providers.dart';
import 'package:mellow/features/spaces_sync/domain/spaces_applier.dart';
import 'package:mellow/features/spaces_sync/domain/spaces_projection.dart';
import 'package:mellow/features/sync/domain/repositories/sync.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:mellow/features/user/domain/repositories/zen_settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

part 'spaces_sync_service.g.dart';

/// The collection this client owns a slice of (PLAN §4.1).
const spacesCollection = 'spaces';

/// The only `meta/global.engines.spaces.version` this client writes (PLAN
/// §8.6 item 3).
const spacesEngineVersion = 3;

const _periodicInterval = Duration(minutes: 1);
const _localChangeDebounce = Duration(seconds: 3);
const _tokenExpiryMargin = Duration(seconds: 60);

/// Ids per `?ids=` request when the heal pass refetches by id: the storage
/// server caps the list at 100.
const _healFetchChunk = 100;

/// How far back the resurrection canary looks: a create for an id this device
/// applied a tombstone for inside this window is the exact signature of Zen's
/// stale-projection race (DESIGN "Hardening against Zen's stale-projection
/// race", defence 5).
const _resurrectionWindow = Duration(minutes: 10);

/// Tombstones always allowed in one batch regardless of the fraction, so
/// closing a handful of tabs on a device that only holds a handful never
/// needs an "Upload anyway".
const _minTombstoneAllowance = 5;

/// `applied_tombstone` rows older than this are pruned once per run.
const _appliedTombstoneRetention = Duration(hours: 1);

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

/// The decrypted contents of one fetch.
class _Decoded {
  _Decoded({
    required this.records,
    required this.cleartexts,
    required this.newestModified,
  });

  final List<ZenIncoming> records;
  final List<Map<String, Object?>> cleartexts;

  /// The largest `modified` among the fetched BSOs, if any carried one.
  final double? newestModified;
}

/// The outbound half of one run, computed in a single pass off the live
/// database (never a cached projection — see `spaces_projection.dart`).
class _Outgoing {
  _Outgoing({
    required this.projected,
    required this.stored,
    required this.digests,
    required this.changed,
    required this.tombstones,
    required this.vanished,
  });

  /// Every record the database projects right now.
  final Map<String, ZenCleartext> projected;

  /// The digests the server last acknowledged, by record id.
  final Map<String, ({String kind, String digest})> stored;

  /// Digest per projected id, so a successful upload can be stamped without
  /// re-projecting.
  final Map<String, String> digests;

  /// Records whose content differs from [stored] — creates and modifications.
  final List<ZenCleartext> changed;

  /// Deletions justified by the `deleted_record` ledger. Empty on the first
  /// sync of a device (PLAN §8.6 item 4).
  final List<String> tombstones;

  /// Ids we hold a digest for that the projection no longer emits and the
  /// ledger never recorded: a mapping bug here, never a deletion to ship.
  final List<String> vanished;
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

  /// Re-entrancy counter for the apply mutex (DESIGN defence 2): non-zero
  /// while an inbound batch is being applied through [_guardApply].
  var _applyDepth = 0;

  /// Set for the duration of [retryBlockedBatch]'s forced run: the volume
  /// half of the canary is skipped, the resurrection half never is.
  var _bypassVolumeCheck = false;
  SyncToken? _token;
  Timer? _periodic;
  StreamSubscription<void>? _localChanges;
  var _foreground = true;

  /// What the heal pass last re-applied per id — the remote digest it applied
  /// and the local projection's digest afterwards (`null` when the id still
  /// projected nothing). A record that still diverges the same way after a
  /// re-apply cannot converge in read-only mode (a live tab projecting its
  /// own title, the layout listing a local-only space) and is left alone
  /// until either side changes; without this the pass would refetch it every
  /// minute.
  final _healAttempts = <String, ({String remote, String? local})>{};

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
      zenSettingsWithDefaultsProvider.select(
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
    final settingsRepo = ref.read(zenSettingsRepositoryProvider.notifier);
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

      // The canary only looks at a recent window; keep the ledger small.
      await ref
          .read(tabDatabaseProvider)
          .syncStateDao
          .pruneAppliedTombstones(
            DateTime.now().subtract(_appliedTombstoneRetention),
          );

      var healed = 0;
      final blocked = state.blockedBatch;
      if (settings.spacesSyncWritesEnabled && writesBlockedReason == null) {
        if (blocked != null && !_bypassVolumeCheck) {
          // A refused batch stays refused: a scheduled run must not quietly
          // ship what the canary caught. Reading carries on.
          logger.w(
            'spaces sync: upload paused since ${blocked.at} '
            '(${blocked.reason.name}, ${blocked.tombstoneCount} tombstones); '
            'reading only until the user retries',
          );
        } else {
          _healAttempts.clear();
          await _upload(
            session,
            settings,
            applied,
            tombstonesAllowed: !firstSync,
          );
        }
      } else {
        if (!settings.spacesSyncWritesEnabled) {
          logger.i('spaces sync: uploads disabled by the kill switch');
        }
        healed = await _healFromRemote(session);
      }

      state = state.copyWith(
        lastSyncAt: DateTime.now(),
        lastError: null,
        writesBlockedReason: writesBlockedReason,
        engineVersionSeen: engine.version,
        engineEnabled: true,
        lastHealedCount: healed,
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
        .read(zenSettingsRepositoryProvider.notifier)
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
        .read(zenSettingsRepositoryProvider.notifier)
        .updateSettings(
          (current) => current
              .copyWith(spacesSyncApplierVersion: spacesApplierVersion)
              .copyWith
              .spacesSyncLastModified(null),
        );
  }

  /* Mark: apply mutex */

  /// Whether an inbound batch is being applied right now.
  bool get _applying => _applyDepth > 0;

  /// Runs an [SpacesApplier.applyBatch] call with [_applying] set — the apply
  /// mutex of DESIGN defence 2. Every apply this service makes goes through
  /// here, and the outbound diff refuses to run while it is set, so a diff can
  /// never read a half-applied database the way Zen's cached projection does.
  Future<Set<String>> _guardedApply(
    List<ZenIncoming> records, {
    required bool firstSync,
  }) async {
    _applyDepth++;
    try {
      return await ref
          .read(spacesApplierProvider)
          .applyBatch(records, firstSync: firstSync);
    } finally {
      _applyDepth--;
    }
  }

  /// Test seam for the apply mutex: runs [body] as if an inbound batch were
  /// being applied, so a test can prove the outbound diff refuses.
  @visibleForTesting
  Future<T> debugWhileApplying<T>(Future<T> Function() body) async {
    _applyDepth++;
    try {
      return await body();
    } finally {
      _applyDepth--;
    }
  }

  /* Mark: incoming */

  /// Fetches what changed since the last run (everything, on the first),
  /// applies it and returns the ids that were applied — they leave this
  /// run's outgoing set (PLAN §4.4).
  Future<Set<String>> _fetchAndApply(
    _Session session,
    ZenSettings settings,
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

    final decoded = await _decode(session, bsos.values);
    final records = decoded.records;
    var newest = fetched.lastModified;
    if (decoded.newestModified case final modified?
        when newest == null || modified > newest) {
      newest = modified;
    }

    if (firstSync) {
      // The escape hatch: the whole collection as it was before this
      // profile ever wrote to it (PLAN §8.6 item 7).
      await store.write(decoded.cleartexts);
    }

    final failed = records.isEmpty
        ? <String>{}
        : await _guardedApply(records, firstSync: firstSync);
    await store.writeFailedIds(failed);

    await ref
        .read(zenSettingsRepositoryProvider.notifier)
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

  /// Decrypts and decodes [bsos]; a record that fails to decrypt is logged
  /// and skipped.
  Future<_Decoded> _decode(_Session session, Iterable<Bso> bsos) async {
    final records = <ZenIncoming>[];
    final cleartexts = <Map<String, Object?>>[];
    double? newest;
    for (final bso in bsos) {
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
    return _Decoded(
      records: records,
      cleartexts: cleartexts,
      newestModified: newest,
    );
  }

  /// Read-only mode makes the desktop authoritative. While uploads are off a
  /// record this device changed or deleted locally is never re-fetched —
  /// `newer=` only returns what changed remotely — so the local divergence
  /// would stick until the record happened to change on the desktop.
  ///
  /// Refetches by id every record whose stored digest no longer matches the
  /// local projection (including records deleted here, which project
  /// nothing) and re-applies what the server returns; ids the server no
  /// longer has are genuinely gone remotely and stay gone. Healed ids lose
  /// their local deletion notes so they do not turn into tombstones once
  /// uploads are switched back on. Returns the number of live records
  /// re-applied.
  Future<int> _healFromRemote(_Session session) async {
    final db = ref.read(tabDatabaseProvider);
    final projectionSource = ref.read(spacesProjectionProvider);
    final projection = await projectionSource.project();
    final stored = await db.syncStateDao.allDigests();
    final deletions = await db.syncStateDao.pendingDeletions();

    String? localDigestOf(Map<String, ZenCleartext> records, String id) {
      final record = records[id];
      return record == null
          ? null
          : recordDigest(record.kind, record.data.toJson());
    }

    final localDigests = <String, String?>{};
    final divergent = <String>{};
    for (final entry in stored.entries) {
      final local = localDigestOf(projection, entry.key);
      localDigests[entry.key] = local;
      if (local == entry.value.digest) {
        continue;
      }
      final previous = _healAttempts[entry.key];
      if (previous != null &&
          previous.remote == entry.value.digest &&
          previous.local == local) {
        // Re-applied before and nothing moved since: structural divergence.
        continue;
      }
      divergent.add(entry.key);
    }
    // Deleted here: these project nothing, so they diverge above already;
    // listed again so the intent is explicit.
    for (final id in deletions.keys) {
      if (stored.containsKey(id) && !_healAttempts.containsKey(id)) {
        divergent.add(id);
      }
    }
    if (divergent.isEmpty) {
      return 0;
    }

    final ids = divergent.toList();
    final bsos = <Bso>[];
    for (var start = 0; start < ids.length; start += _healFetchChunk) {
      final chunk = ids.skip(start).take(_healFetchChunk);
      final fetched = await session.client.fetchCollection(
        spacesCollection,
        ids: chunk,
      );
      bsos.addAll(fetched.records);
    }
    final decoded = await _decode(session, bsos);
    // Gone remotely: remembered so they are not asked for again until the
    // local side moves.
    final returned = {for (final record in decoded.records) _idOf(record)};
    for (final id in divergent.difference(returned)) {
      _healAttempts[id] = (remote: stored[id]!.digest, local: localDigests[id]);
    }
    if (decoded.records.isEmpty) {
      return 0;
    }

    final failed = await _guardedApply(decoded.records, firstSync: false);
    final healed = <String>{};
    for (final record in decoded.records) {
      if (record is ZenIncomingTombstone) {
        continue;
      }
      final id = _idOf(record);
      if (!failed.contains(id)) {
        healed.add(id);
      }
    }
    await db.syncStateDao.clearDeletions(healed);

    final after = await projectionSource.project();
    final storedAfter = await db.syncStateDao.allDigests();
    for (final id in returned) {
      if (failed.contains(id)) {
        continue;
      }
      final remote = storedAfter[id]?.digest;
      if (remote != null) {
        _healAttempts[id] = (remote: remote, local: localDigestOf(after, id));
      } else {
        _healAttempts.remove(id);
      }
    }
    logger.i(
      'spaces sync: healed ${healed.length} records from remote (uploads off)',
    );
    return healed.length;
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

  /// What this run would upload: the live projection diffed against the
  /// digests the server acknowledged, plus the tombstones the deletion ledger
  /// justifies.
  ///
  /// Returns `null` when an inbound apply is in flight. The assertion throws
  /// in debug; in release the upload is abandoned for the run rather than
  /// computed against a half-applied database — the failure Zen ships
  /// (DESIGN defence 2).
  Future<_Outgoing?> _computeOutgoing(
    Set<String> appliedThisSync, {
    required bool tombstonesAllowed,
  }) async {
    assert(
      !_applying,
      'outbound diff computed while an inbound batch is being applied',
    );
    if (_applying) {
      logger.e(
        'spaces sync: outbound diff requested while an inbound batch is '
        'being applied; upload abandoned for this run',
      );
      return null;
    }

    final db = ref.read(tabDatabaseProvider);
    // Straight off the database on every call; never a cached or delayed
    // projection (see the header of spaces_projection.dart).
    final projected = await ref.read(spacesProjectionProvider).project();
    final stored = await db.syncStateDao.allDigests();
    final deletions = await db.syncStateDao.pendingDeletions();

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

    // Tombstones come from the explicit ledger written at deletion time, never
    // from `stored - projected` (DESIGN defence 4, PLAN §8.6 item 5). An id must
    // also have a stored digest (we previously held it) and be absent from the
    // current projection.
    final tombstones = <String>[];
    for (final id in deletions.keys) {
      if (appliedThisSync.contains(id) ||
          projected.containsKey(id) ||
          !stored.containsKey(id)) {
        continue;
      }
      tombstones.add(id);
    }

    // Held before, gone from the projection, and nobody recorded a deletion:
    // that is a bug in our own mapping, so say so instead of deleting the
    // user's tabs on the desktop.
    final vanished = [
      for (final id in stored.keys)
        if (!projected.containsKey(id) &&
            !appliedThisSync.contains(id) &&
            !deletions.containsKey(id))
          id,
    ];
    if (vanished.isNotEmpty) {
      logger.w(
        'spaces sync: ${vanished.length} records vanished from the projection '
        'with no recorded deletion (${vanished.take(5).join(', ')})',
      );
    }

    return _Outgoing(
      projected: projected,
      stored: stored,
      digests: digests,
      changed: changed,
      tombstones: tombstonesAllowed ? tombstones : const [],
      vanished: vanished,
    );
  }

  /// The destructive-batch canary (DESIGN defence 5). Returns the block to
  /// record, or `null` to let [outgoing] through.
  Future<SpacesSyncBlockedBatch?> _canary(
    _Outgoing outgoing,
    ZenSettings settings,
  ) async {
    final db = ref.read(tabDatabaseProvider);

    // Resurrection: a create for an id this device applied a tombstone for
    // moments ago. Never bypassed — no user intent produces this shape, only
    // a stale projection does.
    final recentlyTombstoned = await db.syncStateDao.appliedTombstonesSince(
      DateTime.now().subtract(_resurrectionWindow),
    );
    final resurrected = [
      for (final record in outgoing.changed)
        if (!outgoing.stored.containsKey(record.id) &&
            recentlyTombstoned.containsKey(record.id))
          record.id,
    ];
    if (resurrected.isNotEmpty) {
      return SpacesSyncBlockedBatch(
        reason: SpacesSyncBlockReason.resurrection,
        tombstoneCount: outgoing.tombstones.length,
        limit: 0,
        sampleIds: resurrected.take(5).toList(),
        at: DateTime.now(),
      );
    }

    if (outgoing.tombstones.isEmpty || _bypassVolumeCheck) {
      return null;
    }
    final syncableTabs = await db.tabDao.countSyncableTabs();
    // The fraction guards against a runaway batch, but on a small device it
    // lands below everyday use: at 12 tabs a 20 % limit is 2, so closing
    // three tabs would pause the upload. The floor keeps ordinary tidying
    // quiet while a batch that clears out a whole sidebar still trips.
    final limit = max(
      _minTombstoneAllowance,
      min(
        (settings.spacesSyncMaxTombstoneFraction * syncableTabs).floor(),
        settings.spacesSyncMaxTombstoneCount,
      ),
    );
    if (outgoing.tombstones.length <= limit) {
      return null;
    }
    return SpacesSyncBlockedBatch(
      reason: SpacesSyncBlockReason.tombstoneVolume,
      tombstoneCount: outgoing.tombstones.length,
      limit: limit,
      sampleIds: outgoing.tombstones.take(5).toList(),
      at: DateTime.now(),
    );
  }

  /// Test seam for the outbound half of a run: the diff [_upload] would
  /// compute, without the network. `null` mirrors [_computeOutgoing] refusing
  /// because an apply is in flight.
  @visibleForTesting
  Future<
    ({List<String> changed, List<String> tombstones, List<String> vanished})?
  >
  debugComputeOutgoing({
    Set<String> appliedThisSync = const {},
    bool tombstonesAllowed = true,
  }) async {
    final outgoing = await _computeOutgoing(
      appliedThisSync,
      tombstonesAllowed: tombstonesAllowed,
    );
    if (outgoing == null) {
      return null;
    }
    return (
      changed: [for (final record in outgoing.changed) record.id],
      tombstones: outgoing.tombstones,
      vanished: outgoing.vanished,
    );
  }

  /// Clears a canary block and forces one run whose *volume* check is
  /// skipped. The resurrection check still applies: nothing the user can ask
  /// for makes re-creating a record this device just deleted correct.
  Future<void> retryBlockedBatch() async {
    if (state.blockedBatch == null) {
      return;
    }
    state = state.copyWith(blockedBatch: null);
    _bypassVolumeCheck = true;
    try {
      await sync(reason: 'retry-blocked-batch');
    } finally {
      _bypassVolumeCheck = false;
    }
  }

  Future<void> _upload(
    _Session session,
    ZenSettings settings,
    Set<String> appliedThisSync, {
    required bool tombstonesAllowed,
    bool retried = false,
  }) async {
    final db = ref.read(tabDatabaseProvider);
    final outgoing = await _computeOutgoing(
      appliedThisSync,
      tombstonesAllowed: tombstonesAllowed,
    );
    if (outgoing == null) {
      return;
    }
    final projected = outgoing.projected;
    final digests = outgoing.digests;
    final changed = outgoing.changed;
    final tombstones = outgoing.tombstones;

    // A batch is refused whole: the safe-looking half does not go either.
    if (await _canary(outgoing, settings) case final blocked?) {
      logger.e(
        'spaces sync: upload refused by the destructive-batch canary '
        '(${blocked.reason.name}): ${tombstones.length} tombstones, '
        '${changed.length} changed records, limit ${blocked.limit}, '
        'ids ${blocked.sampleIds.join(', ')}',
      );
      state = state.copyWith(blockedBatch: blocked);
      return;
    }
    state = state.copyWith(blockedBatch: null);

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
      final settingsRepo = ref.read(zenSettingsRepositoryProvider.notifier);
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
          .read(zenSettingsRepositoryProvider.notifier)
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
      final settingsRepo = ref.read(zenSettingsRepositoryProvider.notifier);
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
        await _guardedApply([...live, ...unknown], firstSync: false);
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
