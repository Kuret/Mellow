import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:mellow/features/spaces_sync/data/models/zen_records.dart';
import 'package:mellow/features/spaces_sync/domain/spaces_applier.dart';
import 'package:mellow/features/spaces_sync/domain/spaces_projection.dart';

import '../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';
import 'spaces_sync_test_support.dart';

/// PLAN §8.6 item 1: every record kind survives apply → project with
/// byte-identical canonical JSON. Nothing writes to the desktop until this
/// holds.
void main() {
  test('all six kinds and an unknown seventh round-trip verbatim', () async {
    final harness = openApplierHarness();
    final fixture = roundTripFixture();

    final failed = await harness.container
        .read(spacesApplierProvider)
        .applyBatch(fixture, firstSync: true);
    expect(failed, isEmpty);

    final projected = await harness.container
        .read(spacesProjectionProvider)
        .project();

    final expected = cleartextsOf(fixture);
    expect(projected.keys.toSet(), expected.keys.toSet());
    for (final entry in expected.entries) {
      final actual = projected[entry.key]!;
      expect(actual.id, entry.key);
      expect(actual.kind, entry.value['kind']);
      expect(
        canonicalJson(actual.data.toJson()),
        canonicalJson(entry.value['data']),
        reason: 'record ${entry.key} (${entry.value['kind']}) diverged',
      );
    }
  });

  test(
    'folder members stay in their folder, out of the space children',
    () async {
      final harness = openApplierHarness();
      await harness.container
          .read(spacesApplierProvider)
          .applyBatch(roundTripFixture(), firstSync: true);

      for (final id in ['t8', 't9']) {
        final member = await summaryOf(harness.db, id);
        expect(member.folderId, 'f2', reason: id);
        expect(member.tabShelf, TabShelf.pinned, reason: id);
      }
      expect((await summaryOf(harness.db, 't3')).folderId, 'f1');

      final projected = await harness.container
          .read(spacesProjectionProvider)
          .project();
      final space = projected[space1]!.data as ZenSpaceRecord;
      // The space's children name the root folder, never its members; the
      // folder sits in the pinned section, ahead of the normal tabs.
      expect(space.children, ['t1', 'f1', 't2', 'sp1']);
      final f1 = projected['f1']!.data as ZenFolderRecord;
      expect(f1.children, ['t3', 'f2']);
      final f2 = projected['f2']!.data as ZenFolderRecord;
      expect(f2.children, ['t8', 't9']);
      for (final id in ['t3', 't8', 't9']) {
        final tab = projected[id]!.data as ZenTabRecord;
        expect(tab.pinned, isTrue, reason: id);
        expect(tab.folderId, isNotNull, reason: id);
      }
    },
  );

  test('applying the same batch twice changes nothing', () async {
    final harness = openApplierHarness();
    final applier = harness.container.read(spacesApplierProvider);
    await applier.applyBatch(roundTripFixture(), firstSync: true);
    final first = await harness.container
        .read(spacesProjectionProvider)
        .project();

    final failed = await applier.applyBatch(
      roundTripFixture(),
      firstSync: false,
    );
    expect(failed, isEmpty);
    final second = await harness.container
        .read(spacesProjectionProvider)
        .project();

    expect(second.keys.toSet(), first.keys.toSet());
    for (final id in first.keys) {
      expect(
        canonicalJson(second[id]!.data.toJson()),
        canonicalJson(first[id]!.data.toJson()),
      );
    }
  });

  test('applied digests equal the incoming payload digests', () async {
    final harness = openApplierHarness();
    final fixture = roundTripFixture();
    await harness.container
        .read(spacesApplierProvider)
        .applyBatch(fixture, firstSync: true);

    final digests = await harness.db.syncStateDao.allDigests();
    for (final entry in cleartextsOf(fixture).entries) {
      expect(
        digests[entry.key]?.digest,
        recordDigest(
          entry.value['kind']! as String,
          (entry.value['data']! as Map).cast<String, Object?>(),
        ),
        reason: 'digest of ${entry.key}',
      );
    }
  });
}
