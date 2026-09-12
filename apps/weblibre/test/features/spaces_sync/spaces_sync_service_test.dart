import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/space.dart';
import 'package:weblibre/features/spaces_sync/data/models/zen_records.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_applier.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_projection.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_sync_service.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';

import '../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';
import 'spaces_sync_test_support.dart';

const remoteSpace = '{cccccccc-cccc-4ccc-8ccc-cccccccccccc}';

/// A desktop with one space holding one pinned tab, and the layout.
FakeSyncServer serverWithRemoteState() {
  final server = FakeSyncServer();
  server.put(
    ZenCleartext(
      id: remoteSpace,
      data: ZenSpaceRecord(
        uuid: remoteSpace,
        name: 'Desktop',
        icon: null,
        theme: null,
        containerGuid: null,
        children: ['rt1'],
      ),
    ).toJson(),
  );
  server.put(
    ZenCleartext(
      id: 'rt1',
      data: tabRecord(
        'rt1',
        title: 'Remote',
        pinned: true,
        workspaceUuid: remoteSpace,
      ),
    ).toJson(),
  );
  server.put(
    ZenCleartext(
      id: 'layout',
      data: ZenLayoutRecord(spaces: [remoteSpace], essentials: const {}),
    ).toJson(),
  );
  return server;
}

Future<void> seedLocalState(ServiceHarness harness) async {
  await seedSpaces(harness.db, [space1]);
  await seedTab(harness.db, 'local1', spaceUuid: space1);
}

Iterable<String> uploadedIds(FakeSyncServer server) =>
    server.uploads.expand((batch) => batch).map((r) => r['id']! as String);

Iterable<Map<String, Object?>> uploadedTombstones(FakeSyncServer server) =>
    server.uploads.expand((batch) => batch).where((r) => r['deleted'] == true);

void main() {
  test(
    'the first sync applies remote state and uploads no tombstones',
    () async {
      final harness = await ServiceHarness.open(
        server: serverWithRemoteState(),
        initialSettings: GeneralSettings.withDefaults(
          spacesSyncLastSyncId: 'spaces-sync-1',
        ),
      );
      await seedLocalState(harness);
      // A stale digest with a matching deletion note: exactly what would
      // become a tombstone on any later sync, and must not on the first.
      await harness.db.syncStateDao.putDigest('ghost', 'space', 'stale');
      await harness.db.syncStateDao.recordDeletion('ghost', 'space');

      final service = harness.container.read(
        spacesSyncServiceProvider.notifier,
      );
      await service.sync(reason: 'test');

      final status = harness.container.read(spacesSyncServiceProvider);
      expect(status.lastError, isNull);
      expect(status.engineEnabled, isTrue);
      expect(status.writesBlockedReason, isNull);

      // Remote applied: the desktop's space and its cold pinned tab.
      expect(
        await harness.db.spaceDao.getByUuid(remoteSpace).getSingleOrNull(),
        isNotNull,
      );
      expect((await summaryOf(harness.db, 'rt1')).isCold, isTrue);

      // Local-only records uploaded as creates; nothing applied this sync is
      // re-uploaded; no tombstone at all.
      expect(harness.server.postCount, 1);
      final ids = uploadedIds(harness.server).toSet();
      expect(ids, containsAll([space1, 'local1']));
      expect(ids, isNot(contains(remoteSpace)));
      expect(ids, isNot(contains('rt1')));
      expect(ids, isNot(contains('layout')));
      expect(uploadedTombstones(harness.server), isEmpty);

      // Bookkeeping.
      expect(harness.settings.current.spacesSyncBaselineDone, isTrue);
      expect(
        harness.settings.current.spacesSyncLastModified,
        harness.server.collectionModified,
      );
      final snapshots = harness.snapshotDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.contains('snapshot-'))
          .toList();
      expect(snapshots, hasLength(1));
      final snapshot =
          jsonDecode(await snapshots.single.readAsString()) as List;
      expect(
        snapshot.map((r) => (r as Map)['id']),
        containsAll([remoteSpace, 'rt1', 'layout']),
      );
    },
  );

  test(
    'later syncs upload only changed digests; applied ids leave the outgoing set',
    () async {
      final harness = await ServiceHarness.open(
        server: serverWithRemoteState(),
      );
      await seedLocalState(harness);
      final service = harness.container.read(
        spacesSyncServiceProvider.notifier,
      );
      await service.sync(reason: 'first');
      expect(harness.server.postCount, 1);

      // The desktop's layout applied on the first sync and left the outgoing
      // set; now that this device's space is in the local layout too, the
      // divergence re-uploads exactly that record (Zen's self-healing).
      await service.sync(reason: 'heal');
      expect(harness.server.postCount, 2);
      expect(harness.server.uploads.last.map((r) => r['id']), ['layout']);

      // Nothing changed anywhere: no upload.
      await service.sync(reason: 'idle');
      expect(harness.server.postCount, 2);

      // A local rename: only that record.
      await harness.container
          .read(spaceRepositoryProvider.notifier)
          .renameSpace(space1, 'Renamed');
      await service.sync(reason: 'local-change');
      expect(harness.server.postCount, 3);
      expect(harness.server.uploads.last.map((r) => r['id']), [space1]);
      expect(
        (harness.server.uploads.last.single['data']! as Map)['name'],
        'Renamed',
      );

      // The desktop retitles our live tab: the record applies (incoming always
      // wins) and, having been applied this sync, is not re-uploaded even
      // though the live row still projects its own title.
      harness.server.put(
        ZenCleartext(
          id: 'local1',
          data: tabRecord(
            'local1',
            title: 'Desktop title',
            workspaceUuid: space1,
          ),
        ).toJson(),
      );
      final uploadsBefore = harness.server.uploads.length;
      await service.sync(reason: 'remote-change');
      final uploadedNow = harness.server.uploads
          .skip(uploadsBefore)
          .expand((batch) => batch)
          .map((r) => r['id']);
      expect(uploadedNow, isNot(contains('local1')));
      expect((await summaryOf(harness.db, 'local1')).title, 'local1');

      // The divergence surfaces on the next diff instead (self-healing).
      await service.sync(reason: 'heal');
      expect(harness.server.uploads.last.map((r) => r['id']), ['local1']);
    },
  );

  test('engine version 4 blocks writes but keeps reading', () async {
    final server = serverWithRemoteState()..engineVersion = 4;
    final harness = await ServiceHarness.open(server: server);
    await seedLocalState(harness);

    await harness.container
        .read(spacesSyncServiceProvider.notifier)
        .sync(reason: 'test');

    final status = harness.container.read(spacesSyncServiceProvider);
    expect(status.writesBlockedReason, contains('version 4'));
    expect(status.engineVersionSeen, 4);
    expect(status.lastError, isNull);
    expect(harness.server.postCount, 0);
    expect(
      await harness.db.spaceDao.getByUuid(remoteSpace).getSingleOrNull(),
      isNotNull,
    );
  });

  test('a missing spaces engine does nothing', () async {
    final server = serverWithRemoteState()..omitSpacesEngine = true;
    final harness = await ServiceHarness.open(server: server);
    await seedLocalState(harness);

    await harness.container
        .read(spacesSyncServiceProvider.notifier)
        .sync(reason: 'test');

    expect(
      harness.container.read(spacesSyncServiceProvider).engineEnabled,
      isFalse,
    );
    expect(harness.server.postCount, 0);
    expect(harness.server.fetches, isEmpty);
    expect(
      await harness.db.spaceDao.getByUuid(remoteSpace).getSingleOrNull(),
      isNull,
    );
  });

  test('a syncID change resets local sync state', () async {
    final harness = await ServiceHarness.open(server: serverWithRemoteState());
    await seedLocalState(harness);
    final service = harness.container.read(spacesSyncServiceProvider.notifier);
    await service.sync(reason: 'first');
    expect(harness.settings.current.spacesSyncLastSyncId, 'spaces-sync-1');
    final before = (await harness.db.syncStateDao.allDigests()).length;
    expect(before, greaterThan(0));

    // The server was wiped and re-seeded under a new syncID.
    harness.server.syncId = 'spaces-sync-2';
    harness.server.records.clear();
    await service.sync(reason: 'reset');

    expect(harness.settings.current.spacesSyncLastSyncId, 'spaces-sync-2');
    expect(harness.settings.current.spacesSyncBaselineDone, isTrue);
    // Everything local re-uploaded as creates, nothing tombstoned.
    final lastUpload = harness.server.uploads.last.map((r) => r['id']).toSet();
    expect(
      lastUpload,
      containsAll([space1, 'local1', remoteSpace, 'rt1', 'layout']),
    );
    expect(uploadedTombstones(harness.server), isEmpty);
  });

  test('a 412 refetches and retries once', () async {
    final harness = await ServiceHarness.open(server: serverWithRemoteState());
    await seedLocalState(harness);
    final service = harness.container.read(spacesSyncServiceProvider.notifier);
    await service.sync(reason: 'first');
    await service.sync(reason: 'heal');
    final fetchesBefore = harness.server.fetches.length;
    final postsBefore = harness.server.postCount;

    await harness.container
        .read(spaceRepositoryProvider.notifier)
        .renameSpace(space1, 'Again');
    harness.server.rejectNextPosts = 1;
    // Something the other client wrote in between.
    harness.server.put(
      ZenCleartext(
        id: 'rt2',
        data: tabRecord('rt2', pinned: true, workspaceUuid: remoteSpace),
      ).toJson(),
    );
    await service.sync(reason: 'conflict');

    expect(harness.container.read(spacesSyncServiceProvider).lastError, isNull);
    expect(harness.server.postCount, postsBefore + 2); // rejected + retry
    expect(harness.server.fetches.length, fetchesBefore + 2);
    expect(await tabIds(harness.db), contains('rt2'));
    // The retried upload carries the rename; the refetched tab is not echoed
    // back, though its space's children (now including it) self-heal.
    final retried = harness.server.uploads.last.map((r) => r['id']).toSet();
    expect(retried, contains(space1));
    expect(retried, isNot(contains('rt2')));
    expect(retried.difference({space1, remoteSpace}), isEmpty);
  });

  /// Stores the digest of every record on [server], as if this device had
  /// applied all of them on an earlier sync.
  Future<void> storeServerDigests(ServiceHarness harness) async {
    for (final entry in harness.server.records.entries) {
      final cleartext = entry.value.cleartext;
      await harness.db.syncStateDao.putDigest(
        entry.key,
        cleartext['kind']! as String,
        recordDigest(
          cleartext['kind']! as String,
          (cleartext['data']! as Map).cast<String, Object?>(),
        ),
      );
    }
  }

  /// A device that applied the whole collection earlier: the collection has
  /// not changed since, so `newer=` returns nothing.
  GeneralSettings settledSettings(
    FakeSyncServer server, {
    bool writesEnabled = true,
  }) => GeneralSettings.withDefaults(
    spacesSyncLastSyncId: server.syncId,
    spacesSyncBaselineDone: true,
    spacesSyncLastModified: server.collectionModified,
    spacesSyncWritesEnabled: writesEnabled,
  );

  test(
    'an applier version change re-applies every remote record, no tombstones',
    () async {
      final server = serverWithRemoteState();
      final harness = await ServiceHarness.open(
        server: server,
        initialSettings: settledSettings(server),
        applierVersion: 1,
      );
      await seedLocalState(harness);
      // Digests say the remote records were applied, but the rows the old
      // applier produced are gone (or filed wrongly): nothing changed
      // remotely, so a `newer=` fetch alone would never bring them back.
      await storeServerDigests(harness);
      // A stale digest with a deletion note: a tombstone on any normal sync.
      await harness.db.syncStateDao.putDigest('ghost', 'space', 'stale');
      await harness.db.syncStateDao.recordDeletion('ghost', 'space');

      await harness.container
          .read(spacesSyncServiceProvider.notifier)
          .sync(reason: 'test');

      expect(
        harness.container.read(spacesSyncServiceProvider).lastError,
        isNull,
      );
      // The whole collection was fetched (no `newer=`) and re-applied.
      expect(
        server.fetches.any(
          (request) => !request.url.queryParameters.containsKey('newer'),
        ),
        isTrue,
      );
      expect(
        await harness.db.spaceDao.getByUuid(remoteSpace).getSingleOrNull(),
        isNotNull,
      );
      expect(await tabIds(harness.db), contains('rt1'));
      // No digest survived the reset, so nothing could become a tombstone;
      // the local-only records were uploaded as creates.
      expect(uploadedTombstones(server), isEmpty);
      expect(uploadedIds(server), containsAll([space1, 'local1']));
      expect(
        harness.settings.current.spacesSyncApplierVersion,
        spacesApplierVersion,
      );
      expect(harness.settings.current.spacesSyncBaselineDone, isTrue);
    },
  );
  Iterable<http.Request> idFetches(FakeSyncServer server) => server.fetches
      .where((request) => request.url.queryParameters.containsKey('ids'));

  test(
    'with uploads off, records deleted here are healed from the desktop',
    () async {
      final server = serverWithRemoteState();
      final harness = await ServiceHarness.open(
        server: server,
        initialSettings: settledSettings(server, writesEnabled: false),
      );
      await seedLocalState(harness);
      await storeServerDigests(harness);
      // The user deleted the desktop's space on the phone and closed its
      // tab: both would be tombstones if uploads were on.
      await harness.db.syncStateDao.recordDeletion(remoteSpace, 'space');
      await harness.db.tabDao.addClosedTabTombstones(['rt1']);

      await harness.container
          .read(spacesSyncServiceProvider.notifier)
          .sync(reason: 'test');

      final status = harness.container.read(spacesSyncServiceProvider);
      expect(status.lastError, isNull);
      expect(server.postCount, 0);
      // The space, its tab and the layout (which projected differently
      // without the space) came back from the desktop.
      expect(status.lastHealedCount, 3);
      expect(
        await harness.db.spaceDao.getByUuid(remoteSpace).getSingleOrNull(),
        isNotNull,
      );
      expect(await tabIds(harness.db), contains('rt1'));
      expect(idFetches(server), isNotEmpty);
      // The deletion notes are settled: switching uploads back on must not
      // tombstone what the desktop still has.
      expect(
        await harness.db.syncStateDao.pendingDeletions(),
        isNot(contains(remoteSpace)),
      );
      expect(
        await harness.db.tabDao.allClosedTabTombstoneIds().get(),
        isNot(contains('rt1')),
      );

      // Settled: the next run has nothing to heal.
      await harness.container
          .read(spacesSyncServiceProvider.notifier)
          .sync(reason: 'again');
      expect(
        harness.container.read(spacesSyncServiceProvider).lastHealedCount,
        0,
      );
    },
  );

  test('a record the desktop no longer has stays deleted', () async {
    final server = serverWithRemoteState();
    final harness = await ServiceHarness.open(
      server: server,
      initialSettings: settledSettings(server, writesEnabled: false),
    );
    await seedLocalState(harness);
    await storeServerDigests(harness);
    await harness.db.syncStateDao.putDigest('gone', 'tab', 'stale');
    await harness.db.tabDao.addClosedTabTombstones(['gone']);

    await harness.container
        .read(spacesSyncServiceProvider.notifier)
        .sync(reason: 'test');

    expect(await tabIds(harness.db), isNot(contains('gone')));
    // Not healed, so the note stays until uploads are on again.
    expect(
      await harness.db.tabDao.allClosedTabTombstoneIds().get(),
      contains('gone'),
    );
  });

  test('with uploads on, the heal pass does not run', () async {
    final server = serverWithRemoteState();
    final harness = await ServiceHarness.open(
      server: server,
      initialSettings: settledSettings(server),
    );
    await seedLocalState(harness);
    await storeServerDigests(harness);
    await harness.db.syncStateDao.recordDeletion(remoteSpace, 'space');

    await harness.container
        .read(spacesSyncServiceProvider.notifier)
        .sync(reason: 'test');

    // The local deletion wins through the digest diff instead.
    expect(idFetches(server), isEmpty);
    expect(
      harness.container.read(spacesSyncServiceProvider).lastHealedCount,
      0,
    );
    expect(
      uploadedTombstones(server).map((r) => r['id']),
      contains(remoteSpace),
    );
  });

  test('the kill switch blocks uploads', () async {
    final harness = await ServiceHarness.open(
      server: serverWithRemoteState(),
      initialSettings: GeneralSettings.withDefaults(
        spacesSyncWritesEnabled: false,
      ),
    );
    await seedLocalState(harness);

    await harness.container
        .read(spacesSyncServiceProvider.notifier)
        .sync(reason: 'test');

    expect(harness.server.postCount, 0);
    expect(harness.container.read(spacesSyncServiceProvider).lastError, isNull);
    // Reading still happened.
    expect(await tabIds(harness.db), contains('rt1'));
  });

  test('a validator violation uploads nothing and sets lastError', () async {
    final harness = await ServiceHarness.open(
      server: serverWithRemoteState(),
      overrides: [
        spacesProjectionProvider.overrideWith(
          (ref) => CannedProjection(
            ref.watch(tabDatabaseProvider),
            ref.watch(containerRepositoryProvider.notifier),
            {
              'bad': ZenCleartext(
                id: 'bad',
                data: ZenTabRecord(
                  tabId: 'bad',
                  url: 'https://bad.example/',
                  title: '',
                  icon: '',
                  containerGuid: null,
                  essential: true,
                  pinned: true,
                  workspaceUuid: space1,
                  folderId: null,
                  staticLabel: null,
                  hasStaticIcon: false,
                  defaultContainer: false,
                ),
              ),
              'fine': ZenCleartext(
                id: 'fine',
                data: tabRecord('fine', workspaceUuid: remoteSpace),
              ),
            },
          ),
        ),
      ],
    );
    await seedLocalState(harness);

    await harness.container
        .read(spacesSyncServiceProvider.notifier)
        .sync(reason: 'test');

    expect(harness.server.postCount, 0);
    final status = harness.container.read(spacesSyncServiceProvider);
    expect(status.lastError, contains('outgoing batch refused'));
    expect(status.lastError, contains('workspaceUuid'));
  });

  test(
    'tombstones are uploaded only for held records the user deleted',
    () async {
      final harness = await ServiceHarness.open(
        server: serverWithRemoteState(),
      );
      await seedLocalState(harness);
      await seedSpaces(harness.db, [space2]);
      await seedTab(harness.db, 'closeme', spaceUuid: space2);
      final service = harness.container.read(
        spacesSyncServiceProvider.notifier,
      );
      await service.sync(reason: 'first');
      expect(uploadedIds(harness.server), containsAll([space2, 'closeme']));

      // The user closes a tab (tombstone) and deletes a space (ledger); a
      // third record simply vanishes with no reason and must not be echoed.
      await harness.container.read(tabRepositoryProvider.notifier).closeTabs([
        'closeme',
      ]);
      await harness.container
          .read(spaceRepositoryProvider.notifier)
          .deleteSpace(space2);
      await (harness.db.tab.delete()..where((t) => t.id.equals('local1'))).go();

      await service.sync(reason: 'deletions');

      final tombstones = uploadedTombstones(
        harness.server,
      ).map((r) => r['id']).toSet();
      expect(tombstones, {space2, 'closeme'});
      expect(await harness.db.syncStateDao.getDigest(space2), isNull);
      expect(await harness.db.syncStateDao.getDigest('closeme'), isNull);
      expect(await harness.db.syncStateDao.getDigest('local1'), isNotNull);
      expect(await harness.db.syncStateDao.pendingDeletions(), isEmpty);
    },
  );
}
