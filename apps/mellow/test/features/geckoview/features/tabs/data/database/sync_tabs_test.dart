import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_shelf.dart';

import 'tab_db_test_helpers.dart';

void main() {
  late TabDatabase db;

  const spaceA = '{aaaaaaaa-0000-0000-0000-000000000000}';

  setUp(() async {
    db = openTestTabDatabase();
    await seedSpaces(db, const [spaceA]);
    await seedTab(db, 'cold', spaceUuid: spaceA);
    await db.tabDao.setEngineTabId('cold', null);
    await seedTab(db, 'live-kept', spaceUuid: spaceA);
    await seedTab(db, 'live-lost', spaceUuid: spaceA);
    await seedTab(db, 'private-lost', tabMode: TabMode.private);
    await seedTab(db, 'private-kept', tabMode: TabMode.private);
  });

  tearDown(() => db.close());

  test('reconciles rows against the engine list', () async {
    final result = await db.tabDao.syncTabs(
      engineTabIds: ['live-kept', 'private-kept', 'new-engine-tab'],
      defaultSpaceUuid: spaceA,
    );

    // Cold row untouched.
    final cold = await summaryOf(db, 'cold');
    expect(cold.engineTabId, isNull);
    expect(cold.spaceUuid, spaceA);
    expect(result.deletedTabIds, isNot(contains('cold')));
    expect(result.demotedTabIds, isNot(contains('cold')));

    // Lost live regular row demoted, not deleted.
    final demoted = await summaryOf(db, 'live-lost');
    expect(demoted.engineTabId, isNull);
    expect(demoted.spaceUuid, spaceA);
    expect(result.demotedTabIds, {'live-lost'});

    // Lost private row deleted.
    expect(
      await db.tabDao.getTabSummaryById('private-lost').getSingleOrNull(),
      isNull,
    );
    expect(result.deletedTabIds, {'private-lost'});

    // Listed rows stay live.
    expect((await summaryOf(db, 'live-kept')).engineTabId, 'live-kept');
    expect((await summaryOf(db, 'private-kept')).engineTabId, 'private-kept');

    // Unknown engine id inserted into the default space, live, normal shelf.
    final inserted = await summaryOf(db, 'new-engine-tab');
    expect(inserted.engineTabId, 'new-engine-tab');
    expect(inserted.spaceUuid, spaceA);
    expect(inserted.tabShelf, TabShelf.normal);
    expect(inserted.tabMode, TabModeDbValue.regular);
    expect(result.insertedTabIds, {'new-engine-tab'});

    expect(
      await db.tabDao.coldTabIds().get(),
      unorderedEquals(['cold', 'live-lost']),
    );
    expect(await db.tabDao.liveTabCount().getSingle(), 3);
  });

  test('a cold row the engine lists becomes live again', () async {
    final result = await db.tabDao.syncTabs(
      engineTabIds: [
        'cold',
        'live-kept',
        'live-lost',
        'private-lost',
        'private-kept',
      ],
      defaultSpaceUuid: spaceA,
    );

    expect((await summaryOf(db, 'cold')).engineTabId, 'cold');
    expect(result.insertedTabIds, isEmpty);
    expect(result.deletedTabIds, isEmpty);
    expect(result.demotedTabIds, isEmpty);
  });

  test('an empty engine list demotes everything regular', () async {
    final result = await db.tabDao.syncTabs(
      engineTabIds: const [],
      defaultSpaceUuid: spaceA,
    );

    expect(result.demotedTabIds, {'live-kept', 'live-lost'});
    expect(result.deletedTabIds, {'private-lost', 'private-kept'});
    expect(await db.tabDao.liveTabCount().getSingle(), 0);
    expect(
      await db.tabDao.coldTabIds().get(),
      unorderedEquals(['cold', 'live-kept', 'live-lost']),
    );
  });
}
