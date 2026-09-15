import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_split_data.dart';

import 'tab_db_test_helpers.dart';

void main() {
  late TabDatabase db;

  const spaceA = '{aaaaaaaa-0000-0000-0000-000000000000}';

  setUp(() async {
    db = openTestTabDatabase();
    await seedSpaces(db, const [spaceA]);
    for (final id in ['s1', 's2', 's3']) {
      await seedTab(db, id, spaceUuid: spaceA);
    }
    await db.tabSplitDao.insertSplit(
      TabSplitData(id: 'split', spaceUuid: spaceA, orderKey: 'k'),
    );
  });

  tearDown(() => db.close());

  Future<List<(String, int?)>> membership(List<String> ids) async {
    return [for (final id in ids) (id, (await summaryOf(db, id)).splitIndex)];
  }

  test('setMembers assigns dense indices and clears dropped members', () async {
    await db.tabSplitDao.setMembers('split', ['s1', 's2', 's3']);
    expect(await db.tabSplitDao.members('split'), ['s1', 's2', 's3']);
    expect(await membership(['s1', 's2', 's3']), [
      ('s1', 0),
      ('s2', 1),
      ('s3', 2),
    ]);
    for (final id in ['s1', 's2', 's3']) {
      expect((await summaryOf(db, id)).splitId, 'split');
    }

    await db.tabSplitDao.setMembers('split', ['s3', 's1']);
    expect(await db.tabSplitDao.members('split'), ['s3', 's1']);
    expect(await membership(['s3', 's1', 's2']), [
      ('s3', 0),
      ('s1', 1),
      ('s2', null),
    ]);
    expect((await summaryOf(db, 's2')).splitId, isNull);
  });

  test('removeMember re-indexes while two or more remain', () async {
    await db.tabSplitDao.setMembers('split', ['s1', 's2', 's3']);

    final result = await db.tabSplitDao.removeMember('s1');
    expect(result, isNotNull);
    expect(result!.dissolved, isFalse);
    expect(result.splitId, 'split');
    expect(result.survivorTabId, isNull);
    expect(await db.tabSplitDao.members('split'), ['s2', 's3']);
    expect(await membership(['s1', 's2', 's3']), [
      ('s1', null),
      ('s2', 0),
      ('s3', 1),
    ]);
  });

  test('removeMember below two members dissolves the split', () async {
    await db.tabSplitDao.setMembers('split', ['s1', 's2']);

    final result = await db.tabSplitDao.removeMember('s2');
    expect(result, isNotNull);
    expect(result!.dissolved, isTrue);
    expect(result.survivorTabId, 's1');
    expect(await db.tabSplitDao.getById('split').getSingleOrNull(), isNull);
    final survivor = await summaryOf(db, 's1');
    expect(survivor.splitId, isNull);
    expect(survivor.splitIndex, isNull);
    expect(await db.tabSplitDao.members('split'), isEmpty);
  });

  test('removeMember on a plain tab is a no-op', () async {
    expect(await db.tabSplitDao.removeMember('s1'), isNull);
  });
}
