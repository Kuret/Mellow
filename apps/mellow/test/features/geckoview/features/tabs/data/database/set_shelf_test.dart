import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';

import 'tab_db_test_helpers.dart';

void main() {
  late TabDatabase db;

  const spaceA = '{aaaaaaaa-0000-0000-0000-000000000000}';
  const spaceB = '{bbbbbbbb-0000-0000-0000-000000000000}';
  const containerC = 'container-c';

  setUp(() async {
    db = openTestTabDatabase();
    await seedSpaces(db, const [spaceA, spaceB]);
    await seedContainer(db, containerC);
    await seedTab(
      db,
      'other-essential',
      containerId: containerC,
      shelf: TabShelf.essential,
    );
    await seedTab(db, 'moving', spaceUuid: spaceA, containerId: containerC);
    await seedTab(db, 'sibling', spaceUuid: spaceA);
  });

  tearDown(() => db.close());

  test(
    'to essential nulls space and folder and keys in the container strip',
    () async {
      final moved = await db.tabDao.setShelf(
        'moving',
        TabShelf.essential,
        target: TabOrderScope.essential(containerC),
      );
      expect(moved, isTrue);

      final moving = await summaryOf(db, 'moving');
      expect(moving.tabShelf, TabShelf.essential);
      expect(moving.spaceUuid, isNull);
      expect(moving.folderId, isNull);
      expect(moving.splitId, isNull);
      expect(await db.tabDao.essentialTabIds(containerC).get(), [
        'other-essential',
        'moving',
      ]);

      expect(await idsInScope(db, TabOrderScope.normal(spaceUuid: spaceA)), [
        'sibling',
      ]);
    },
  );

  test('to pinned with a target space restores the space', () async {
    await db.tabDao.setShelf(
      'moving',
      TabShelf.essential,
      target: TabOrderScope.essential(containerC),
    );

    final moved = await db.tabDao.setShelf(
      'moving',
      TabShelf.pinned,
      target: TabOrderScope.pinned(spaceB),
    );
    expect(moved, isTrue);

    final moving = await summaryOf(db, 'moving');
    expect(moving.tabShelf, TabShelf.pinned);
    expect(moving.spaceUuid, spaceB);
    expect(moving.folderId, isNull);
    expect(await idsInScope(db, TabOrderScope.pinned(spaceB)), ['moving']);
    expect(await db.tabDao.essentialTabIds(containerC).get(), [
      'other-essential',
    ]);
  });

  test('moveToScope rewrites the space of the moving tab only', () async {
    await db.tabDao.moveToScope([
      'moving',
    ], TabOrderScope.normal(spaceUuid: spaceB));

    expect((await summaryOf(db, 'moving')).spaceUuid, spaceB);
    expect(await idsInScope(db, TabOrderScope.normal(spaceUuid: spaceB)), [
      'moving',
    ]);
    expect(await idsInScope(db, TabOrderScope.normal(spaceUuid: spaceA)), [
      'sibling',
    ]);
  });

  test('a private tab cannot be pinned', () async {
    await seedTab(db, 'private', tabMode: null);
    // Mark private through the engine-state path the DAO exposes.
    await (db.tab.update()..where((t) => t.id.equals('private'))).write(
      const TabCompanion(tabMode: Value(TabModeDbValue.private)),
    );
    expect(
      await db.tabDao.setShelf(
        'private',
        TabShelf.pinned,
        target: TabOrderScope.pinned(spaceA),
      ),
      isFalse,
    );
  });
}
