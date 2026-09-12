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
// Defences against Zen's stale-projection race (upstream
// zen-browser/desktop#15380; DESIGN "Hardening against Zen's
// stale-projection race"): no diff off a stale projection, tombstones only
// from the deletion ledger, and a canary that refuses a destructive batch.
import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/spaces_sync/data/models/zen_records.dart';
import 'package:weblibre/features/spaces_sync/domain/entities/spaces_sync_status.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_applier.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_sync_service.dart';

import '../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';
import 'spaces_sync_test_support.dart';

/// Wraps the real applier so a test can hold an apply open and race a sync
/// against it.
class SlowApplier extends SpacesApplier {
  SlowApplier(super.ref, this.gate);

  /// Completes when the test lets the apply finish.
  final Completer<void> gate;

  /// Completes as soon as the first apply has started.
  final started = Completer<void>();

  @override
  Future<Set<String>> applyBatch(
    List<ZenIncoming> records, {
    required bool firstSync,
  }) async {
    if (!started.isCompleted) {
      started.complete();
      await gate.future;
    }
    return super.applyBatch(records, firstSync: firstSync);
  }
}

/// The lines the app logged during [body], newest last.
Future<List<String>> logsDuring(Future<void> Function() body) async {
  loggerMemory.buffer.clear();
  await body();
  return [
    for (final event in loggerMemory.buffer) event.lines.join('\n'),
  ];
}

Iterable<Map<String, Object?>> uploadedTombstones(FakeSyncServer server) =>
    server.uploads.expand((batch) => batch).where((r) => r['deleted'] == true);

SpacesSyncService serviceOf(ServiceHarness harness) =>
    harness.container.read(spacesSyncServiceProvider.notifier);

/// Seeds [count] tabs in [space1] and syncs once, so every local record has a
/// digest the server acknowledged.
Future<ServiceHarness> settledHarness({
  int tabs = 1,
  List<Override> overrides = const [],
}) async {
  final harness = await ServiceHarness.open(overrides: overrides);
  await seedSpaces(harness.db, [space1]);
  for (var i = 0; i < tabs; i++) {
    await seedTab(harness.db, 't$i', spaceUuid: space1);
  }
  final service = serviceOf(harness);
  // Two runs: the first establishes the baseline, the second settles the
  // layout record the first one could not diff yet.
  await service.sync(reason: 'baseline');
  await service.sync(reason: 'settle');
  expect(await service.debugComputeOutgoing(), isNotNull);
  return harness;
}

void main() {
  group('no diff off a stale projection', () {
    test('an applied tombstone is not re-uploaded as a create', () async {
      final harness = await settledHarness(tabs: 3);
      final service = serviceOf(harness);

      // The desktop closes t1.
      harness.server.put({'id': 't1', 'deleted': true});
      await service.sync(reason: 'inbound-tombstone');

      expect(await tabIds(harness.db), isNot(contains('t1')));
      expect(await harness.db.syncStateDao.getDigest('t1'), isNull);

      // The outbound diff computed straight after the apply sees the
      // post-apply database: nothing to say about t1, nothing at all.
      final outgoing = await service.debugComputeOutgoing();
      expect(outgoing!.changed, isEmpty);
      expect(outgoing.tombstones, isEmpty);
      expect(uploadedTombstones(harness.server), isEmpty);
    });

    test('an applied create does not produce a tombstone', () async {
      final harness = await settledHarness(tabs: 2);
      final service = serviceOf(harness);

      // The desktop adds a tab to our space.
      harness.server.put(
        ZenCleartext(
          id: 'desktop1',
          data: tabRecord('desktop1', workspaceUuid: space1),
        ).toJson(),
      );
      harness.server.put(
        ZenCleartext(
          id: space1,
          data: ZenSpaceRecord(
            uuid: space1,
            name: space1,
            icon: null,
            theme: null,
            containerGuid: null,
            children: ['t0', 't1', 'desktop1'],
          ),
        ).toJson(),
      );
      await service.sync(reason: 'inbound-create');

      expect(await tabIds(harness.db), contains('desktop1'));

      final outgoing = await service.debugComputeOutgoing();
      expect(outgoing!.tombstones, isEmpty);
      expect(outgoing.changed, isEmpty);
      expect(uploadedTombstones(harness.server), isEmpty);
    });
  });

  group('tombstones come from the ledger', () {
    test(
      'a record missing from the projection with no ledger entry is not '
      'a deletion',
      () async {
        final harness = await settledHarness();
        final service = serviceOf(harness);

        // A digest for an id nothing projects and nobody deleted: the
        // signature of a mapping bug on our side.
        await harness.db.syncStateDao.putDigest('phantom', 'space', 'stale');

        late final ({
          List<String> changed,
          List<String> tombstones,
          List<String> vanished,
        })
        outgoing;
        final lines = await logsDuring(() async {
          outgoing = (await service.debugComputeOutgoing())!;
        });

        expect(outgoing.tombstones, isEmpty);
        expect(outgoing.vanished, ['phantom']);
        expect(
          lines,
          contains(
            allOf(
              contains(
                '1 records vanished from the projection with no recorded '
                'deletion',
              ),
              contains('phantom'),
            ),
          ),
        );

        // And a full run uploads nothing for it either.
        final postsBefore = harness.server.postCount;
        await service.sync(reason: 'after-phantom');
        expect(harness.server.postCount, postsBefore);
      },
    );

    test('a ledger entry for an id we never held is not a deletion', () async {
      final harness = await settledHarness();
      final service = serviceOf(harness);

      await harness.db.syncStateDao.recordDeletion('never-uploaded', 'space');

      final outgoing = await service.debugComputeOutgoing();
      expect(outgoing!.tombstones, isEmpty);
      expect(outgoing.vanished, isEmpty);
    });

    test('a ledger entry for a record we held is a deletion', () async {
      final harness = await settledHarness(tabs: 10);
      final service = serviceOf(harness);

      await (harness.db.tab.delete()..where((t) => t.id.equals('t0'))).go();
      await harness.db.syncStateDao.recordDeletion('t0', 'tab');

      final outgoing = await service.debugComputeOutgoing();
      expect(outgoing!.tombstones, ['t0']);
      expect(outgoing.vanished, isEmpty);
    });
  });

  group('destructive-batch canary', () {
    /// Deletes [count] of the 10 seeded tabs the way a user close does: the
    /// row goes, and the deletion is recorded in the ledger.
    Future<void> deleteTabs(TabDatabase db, List<String> ids) async {
      for (final id in ids) {
        await (db.tab.delete()..where((t) => t.id.equals(id))).go();
        await db.syncStateDao.recordDeletion(id, 'tab');
      }
    }

    test('a batch tombstoning 30 % of the tabs is refused whole', () async {
      final harness = await settledHarness(tabs: 10);
      final service = serviceOf(harness);
      final postsBefore = harness.server.postCount;

      await deleteTabs(harness.db, ['t0', 't1', 't2']);
      // 7 tabs left: min(floor(0.2 * 7), 25) = 1 allowed, 3 requested.
      expect(await harness.db.tabDao.countSyncableTabs(), 7);

      await service.sync(reason: 'destructive');

      final blocked = harness.container
          .read(spacesSyncServiceProvider)
          .blockedBatch;
      expect(blocked, isNotNull);
      expect(blocked!.reason, SpacesSyncBlockReason.tombstoneVolume);
      expect(blocked.tombstoneCount, 3);
      expect(blocked.limit, 1);
      expect(blocked.sampleIds, containsAll(['t0', 't1', 't2']));

      // Nothing left the device — not the tombstones, not the space record
      // that also changed. A batch is refused as a whole.
      expect(harness.server.postCount, postsBefore);

      // A scheduled run keeps reading but still uploads nothing.
      await service.sync(reason: 'periodic');
      expect(harness.server.postCount, postsBefore);
      expect(
        harness.container.read(spacesSyncServiceProvider).blockedBatch,
        isNotNull,
      );

      // Only an explicit retry ships it.
      await service.retryBlockedBatch();
      expect(harness.server.postCount, postsBefore + 1);
      expect(
        uploadedTombstones(harness.server).map((r) => r['id']),
        containsAll(['t0', 't1', 't2']),
      );
      expect(
        harness.container.read(spacesSyncServiceProvider).blockedBatch,
        isNull,
      );
    });

    test('a create for a just-applied tombstone is refused', () async {
      final harness = await settledHarness(tabs: 10);
      final service = serviceOf(harness);
      final postsBefore = harness.server.postCount;

      // This device applied a tombstone for `ghost` 30 seconds ago...
      await harness.db.appliedTombstone.insertOne(
        AppliedTombstoneCompanion.insert(
          id: 'ghost',
          appliedAt: DateTime.now().subtract(const Duration(seconds: 30)),
        ),
      );
      // ...and the projection now wants to create it. Well under the volume
      // limit: no tombstone at all.
      await seedTab(harness.db, 'ghost', spaceUuid: space1);

      await service.sync(reason: 'resurrection');

      final blocked = harness.container
          .read(spacesSyncServiceProvider)
          .blockedBatch;
      expect(blocked, isNotNull);
      expect(blocked!.reason, SpacesSyncBlockReason.resurrection);
      expect(blocked.sampleIds, ['ghost']);
      expect(harness.server.postCount, postsBefore);

      // The resurrection check is never bypassed.
      await service.retryBlockedBatch();
      expect(harness.server.postCount, postsBefore);
      final again = harness.container
          .read(spacesSyncServiceProvider)
          .blockedBatch;
      expect(again, isNotNull);
      expect(again!.reason, SpacesSyncBlockReason.resurrection);
    });

    test('applied tombstones older than an hour are pruned', () async {
      final harness = await settledHarness();
      await harness.db.appliedTombstone.insertOne(
        AppliedTombstoneCompanion.insert(
          id: 'old',
          appliedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      );
      await serviceOf(harness).sync(reason: 'prune');
      expect(
        await harness.db.syncStateDao.appliedTombstonesSince(
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
        isEmpty,
      );
    });
  });

  group('apply mutex', () {
    test('the outbound diff refuses while an apply is in flight', () async {
      final harness = await settledHarness();
      final service = serviceOf(harness);

      await expectLater(
        service.debugWhileApplying(() => service.debugComputeOutgoing()),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a sync started during an apply waits for it', () async {
      final gate = Completer<void>();
      final harness = await ServiceHarness.open(
        overrides: [
          spacesApplierProvider.overrideWith((ref) => SlowApplier(ref, gate)),
        ],
      );
      final applier =
          harness.container.read(spacesApplierProvider) as SlowApplier;
      await seedSpaces(harness.db, [space1]);
      await seedTab(harness.db, 't0', spaceUuid: space1);
      final service = serviceOf(harness);

      // The desktop has a tab of its own, so the first run has a batch to
      // apply and the slow applier has something to hold open.
      harness.server.put(
        ZenCleartext(
          id: 'desktop1',
          data: tabRecord('desktop1', workspaceUuid: space1),
        ).toJson(),
      );
      harness.server.put(
        ZenCleartext(
          id: space1,
          data: ZenSpaceRecord(
            uuid: space1,
            name: space1,
            icon: null,
            theme: null,
            containerGuid: null,
            children: ['desktop1'],
          ),
        ).toJson(),
      );

      final first = service.sync(reason: 'slow-apply');
      await applier.started.future;

      var secondDone = false;
      final second = service
          .sync(reason: 'racing')
          .then((_) => secondDone = true);

      // The apply is still open: the racing run has not run a diff, and has
      // not finished.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(secondDone, isFalse);
      expect(harness.server.postCount, 0);

      gate.complete();
      await first;
      await second;
      expect(secondDone, isTrue);

      // The diff ran after the apply committed: the applied records are in
      // the database and were never tombstoned.
      expect(await tabIds(harness.db), containsAll(['t0', 'desktop1']));
      expect(uploadedTombstones(harness.server), isEmpty);
      expect(
        harness.container.read(spacesSyncServiceProvider).blockedBatch,
        isNull,
      );

      // And the settled state has nothing left to say.
      final outgoing = await service.debugComputeOutgoing();
      expect(outgoing!.tombstones, isEmpty);
    });
  });
}
