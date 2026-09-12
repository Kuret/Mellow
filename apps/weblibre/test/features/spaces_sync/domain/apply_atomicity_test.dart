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
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:weblibre/features/spaces_sync/data/models/zen_records.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_applier.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_projection.dart';

import '../../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';
import '../spaces_sync_test_support.dart';

/// The digests a device that had just uploaded everything would hold.
Future<void> stampWholeProjection(
  TabDatabase db,
  SpacesProjection projection,
) async {
  for (final entry in (await projection.project()).entries) {
    await db.syncStateDao.putDigest(
      entry.key,
      entry.value.kind,
      recordDigest(entry.value.kind, entry.value.data.toJson()),
    );
  }
}

/// Ids where the live projection and the stored digests disagree — what
/// `computeChangedIDs` would see as outgoing work.
Future<Set<String>> projectionVsDigests(
  TabDatabase db,
  SpacesProjection projection,
) async {
  final projected = await projection.project();
  final digests = await db.syncStateDao.allDigests();
  final differing = <String>{};
  for (final entry in projected.entries) {
    final stored = digests[entry.key]?.digest;
    if (stored != recordDigest(entry.value.kind, entry.value.data.toJson())) {
      differing.add(entry.key);
    }
  }
  for (final id in digests.keys) {
    if (!projected.containsKey(id)) {
      differing.add(id);
    }
  }
  return differing;
}

SpacesProjection projectionOf(ProviderContainer container, TabDatabase db) =>
    SpacesProjection(db, container.read(containerRepositoryProvider.notifier));

void main() {
  test(
    'a throw in the apply leaves the rows and the digests untouched',
    () async {
      final harness = openApplierHarness();
      await seedSpaces(harness.db, [space1]);
      await seedTab(harness.db, 'keep', spaceUuid: space1);
      await harness.db.syncStateDao.putDigest('keep', 'tab', 'stamped-before');

      final rowsBefore = await tabIds(harness.db);
      final digestsBefore = await harness.db.syncStateDao.allDigests();

      final applier = harness.container.read(spacesApplierProvider);
      // Stands in for the process dying with the rows written and the snapshot
      // not yet stamped — the window Zen leaves open (gh-15380).
      applier.debugAfterApply = () async => throw StateError('boom');

      await expectLater(
        applier.applyBatch([
          record(tabRecord('fresh', workspaceUuid: space1)),
          ZenIncomingTombstone('keep'),
        ], firstSync: false),
        throwsStateError,
      );

      expect(await tabIds(harness.db), rowsBefore);
      expect(await harness.db.syncStateDao.allDigests(), digestsBefore);
      expect(await harness.db.tabDao.pendingEngineCloseIds(), isEmpty);
      expect(
        await harness.db.syncStateDao.appliedTombstonesSince(
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
        isEmpty,
      );
    },
  );

  test('a committed batch stamps exactly what it wrote', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1]);

    final incoming = record(tabRecord('fresh', workspaceUuid: space1));
    final failed = await harness.container
        .read(spacesApplierProvider)
        .applyBatch([incoming], firstSync: false);

    expect(failed, isEmpty);
    expect(await tabIds(harness.db), contains('fresh'));

    final digests = await harness.db.syncStateDao.allDigests();
    expect(
      digests['fresh']?.digest,
      recordDigest('tab', incoming.cleartext.data.toJson()),
    );

    // And the row really is what that digest describes.
    final projected = await projectionOf(
      harness.container,
      harness.db,
    ).project();
    expect(
      recordDigest('tab', projected['fresh']!.data.toJson()),
      digests['fresh']?.digest,
    );
  });

  test(
    'a rolled-back apply leaves nothing for the next diff to find',
    () async {
      final harness = openApplierHarness();
      await seedSpaces(harness.db, [space1]);
      await seedTab(harness.db, 'held', spaceUuid: space1);

      // A device in the steady state: every projected record uploaded, every
      // digest stored.
      final projection = projectionOf(harness.container, harness.db);
      await stampWholeProjection(harness.db, projection);
      expect(await projectionVsDigests(harness.db, projection), isEmpty);

      final applier = harness.container.read(spacesApplierProvider);
      applier.debugAfterApply = () async => throw StateError('boom');

      await expectLater(
        applier.applyBatch([
          ZenIncomingTombstone('held'),
          record(tabRecord('fresh', workspaceUuid: space1)),
        ], firstSync: false),
        throwsStateError,
      );

      // The "killed between apply and stamp" case: with the stamp inside the
      // transaction there is no skew for the outgoing diff to misread.
      expect(await projectionVsDigests(harness.db, projection), isEmpty);
    },
  );
}
