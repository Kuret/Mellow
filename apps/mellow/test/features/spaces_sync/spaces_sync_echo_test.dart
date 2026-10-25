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
// The incoming echo guard (DESIGN defence 6): a desktop without the
// gh-15485 fix applies our tombstone and then re-uploads the tab from a
// stale projection (Zen gh-15380). The fetch path must not take that
// create as the user's wish, and a local close whose tombstone has not gone
// out yet must beat an incoming modification of the same tab.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:mellow/features/spaces_sync/data/models/zen_records.dart';
import 'package:mellow/features/spaces_sync/domain/spaces_sync_service.dart';

import '../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';
import 'spaces_sync_test_support.dart';

Iterable<Map<String, Object?>> uploadedTombstones(FakeSyncServer server) =>
    server.uploads.expand((batch) => batch).where((r) => r['deleted'] == true);

int tombstonesFor(FakeSyncServer server, String id) =>
    uploadedTombstones(server).where((r) => r['id'] == id).length;

SpacesSyncService serviceOf(ServiceHarness harness) =>
    harness.container.read(spacesSyncServiceProvider.notifier);

/// Seeds [ids] in [space1] and syncs twice, so every local record has a
/// digest the server acknowledged and the layout record is settled.
Future<ServiceHarness> settledHarness(List<String> ids) async {
  final harness = await ServiceHarness.open();
  await seedSpaces(harness.db, [space1]);
  for (final id in ids) {
    await seedTab(harness.db, id, spaceUuid: space1);
  }
  final service = serviceOf(harness);
  await service.sync(reason: 'baseline');
  await service.sync(reason: 'settle');
  return harness;
}

/// A local close as the tab repository records it: the ledger entry, then
/// the row goes.
Future<void> closeLocally(TabDatabase db, String id) async {
  await db.syncStateDao.recordDeletion(id, 'tab');
  await (db.tab.delete()..where((t) => t.id.equals(id))).go();
}

Future<UploadedTombstoneData?> uploadedRow(TabDatabase db, String id) =>
    (db.uploadedTombstone.select()..where((t) => t.id.equals(id)))
        .getSingleOrNull();

/// The desktop uploads [id] as a live tab in [space1].
void putTab(FakeSyncServer server, String id, {String title = ''}) =>
    server.put(
      ZenCleartext(
        id: id,
        data: tabRecord(id, title: title, workspaceUuid: space1),
      ).toJson(),
    );

/// Closes `t1` on this device and syncs: the tombstone goes out and is
/// remembered.
Future<ServiceHarness> closedAndUploaded() async {
  final harness = await settledHarness(['t0', 't1']);
  await closeLocally(harness.db, 't1');
  await serviceOf(harness).sync(reason: 'close');

  expect(tombstonesFor(harness.server, 't1'), 1);
  expect(await harness.db.syncStateDao.pendingDeletions(), isEmpty);
  expect(await harness.db.syncStateDao.getDigest('t1'), isNull);
  final row = await uploadedRow(harness.db, 't1');
  expect(row, isNotNull);
  expect(row!.echoes, 0);
  return harness;
}

void main() {
  test(
    'an echo of our own tombstone is refused and tombstoned again',
    () async {
      final harness = await closedAndUploaded();

      // The desktop applied the tombstone, then re-uploaded t1 from its stale
      // projection.
      putTab(harness.server, 't1');
      await serviceOf(harness).sync(reason: 'echo');

      expect(await tabIds(harness.db), isNot(contains('t1')));
      expect(tombstonesFor(harness.server, 't1'), 2);
      expect(harness.server.records, isNot(contains('t1')));
      final row = await uploadedRow(harness.db, 't1');
      expect(row!.echoes, 1);
      // The second tombstone settled the ledger and the digest again.
      expect(await harness.db.syncStateDao.pendingDeletions(), isEmpty);
      expect(await harness.db.syncStateDao.getDigest('t1'), isNull);
    },
  );

  test('a second create for the same id is the peer insisting', () async {
    final harness = await closedAndUploaded();
    putTab(harness.server, 't1');
    await serviceOf(harness).sync(reason: 'echo');
    expect(await tabIds(harness.db), isNot(contains('t1')));

    // Undo-close on the desktop reuses the id: this one is deliberate.
    putTab(harness.server, 't1', title: 'Back');
    await serviceOf(harness).sync(reason: 'insist');

    expect(await tabIds(harness.db), contains('t1'));
    expect(await uploadedRow(harness.db, 't1'), isNull);
    expect(tombstonesFor(harness.server, 't1'), 2);
    expect(await harness.db.syncStateDao.getDigest('t1'), isNotNull);
    expect(await harness.db.syncStateDao.pendingDeletions(), isEmpty);
  });

  test('a tombstone uploaded outside the window no longer guards', () async {
    final harness = await settledHarness(['t0']);
    await harness.db.uploadedTombstone.insertOne(
      UploadedTombstoneCompanion.insert(
        id: 't1',
        uploadedAt: DateTime.now().subtract(const Duration(minutes: 11)),
      ),
    );

    putTab(harness.server, 't1');
    await serviceOf(harness).sync(reason: 'late');

    expect(await tabIds(harness.db), contains('t1'));
    expect(uploadedTombstones(harness.server), isEmpty);
  });

  test('a pending local deletion beats an incoming modification', () async {
    final harness = await settledHarness(['t0', 't1']);
    expect(await harness.db.syncStateDao.getDigest('t1'), isNotNull);

    // Closed here, and the desktop renamed it before this device synced.
    await closeLocally(harness.db, 't1');
    putTab(harness.server, 't1', title: 'Renamed');
    await serviceOf(harness).sync(reason: 'race');

    expect(await tabIds(harness.db), isNot(contains('t1')));
    expect(tombstonesFor(harness.server, 't1'), 1);
    expect(harness.server.records, isNot(contains('t1')));
    expect(await harness.db.syncStateDao.pendingDeletions(), isEmpty);
    expect(await harness.db.syncStateDao.getDigest('t1'), isNull);
    expect(await uploadedRow(harness.db, 't1'), isNotNull);
  });

  test('a create for an id never tombstoned applies as before', () async {
    final harness = await settledHarness(['t0']);

    putTab(harness.server, 'fresh');
    await serviceOf(harness).sync(reason: 'create');

    expect(await tabIds(harness.db), contains('fresh'));
    expect(uploadedTombstones(harness.server), isEmpty);
    expect(await harness.db.syncStateDao.getDigest('fresh'), isNotNull);
  });
}
