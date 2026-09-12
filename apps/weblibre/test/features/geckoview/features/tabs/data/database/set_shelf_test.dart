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
    await seedTab(db, 'parent', spaceUuid: spaceA, containerId: containerC);
    await seedTab(db, 'child', parentId: 'parent', containerId: containerC);
    await seedTab(db, 'grandchild', parentId: 'child', containerId: containerC);
    await seedTab(db, 'sibling', spaceUuid: spaceA);
  });

  tearDown(() => db.close());

  test(
    'to essential nulls space and folder and keys in the container strip',
    () async {
      final moved = await db.tabDao.setShelf(
        'parent',
        TabShelf.essential,
        target: TabOrderScope.essential(containerC),
      );
      expect(moved, isTrue);

      final parent = await summaryOf(db, 'parent');
      expect(parent.tabShelf, TabShelf.essential);
      expect(parent.spaceUuid, isNull);
      expect(parent.folderId, isNull);
      expect(parent.splitId, isNull);
      expect(parent.parentId, isNull);
      expect(await db.tabDao.essentialTabIds(containerC).get(), [
        'other-essential',
        'parent',
      ]);

      // Essentials carry no tree: the child is handed to the grandparent (none,
      // so it becomes a root) and keeps its space rather than following into
      // the strip.
      final child = await summaryOf(db, 'child');
      expect(child.parentId, isNull);
      expect(child.spaceUuid, spaceA);
      expect(child.tabShelf, TabShelf.normal);
      final grandchild = await summaryOf(db, 'grandchild');
      expect(grandchild.parentId, 'child');
      expect(grandchild.spaceUuid, spaceA);

      expect(await idsInScope(db, TabOrderScope.normal(spaceUuid: spaceA)), [
        'child',
        'grandchild',
        'sibling',
      ]);
    },
  );

  test('to pinned with a target space restores the space', () async {
    await db.tabDao.setShelf(
      'parent',
      TabShelf.essential,
      target: TabOrderScope.essential(containerC),
    );

    final moved = await db.tabDao.setShelf(
      'parent',
      TabShelf.pinned,
      target: TabOrderScope.pinned(spaceB),
    );
    expect(moved, isTrue);

    final parent = await summaryOf(db, 'parent');
    expect(parent.tabShelf, TabShelf.pinned);
    expect(parent.spaceUuid, spaceB);
    expect(parent.folderId, isNull);
    expect(await idsInScope(db, TabOrderScope.pinned(spaceB)), ['parent']);
    expect(await db.tabDao.essentialTabIds(containerC).get(), [
      'other-essential',
    ]);
  });

  test('F1: children follow when the parent changes scope', () async {
    final moved = await db.tabDao.setShelf(
      'parent',
      TabShelf.pinned,
      target: TabOrderScope.pinned(spaceB),
    );
    expect(moved, isTrue);

    final parent = await summaryOf(db, 'parent');
    expect(parent.spaceUuid, spaceB);
    expect(parent.tabShelf, TabShelf.pinned);

    // Direct child: moved by the `tab_child_follows_parent_scope` trigger.
    final child = await summaryOf(db, 'child');
    expect(child.parentId, 'parent');
    expect(child.spaceUuid, spaceB);
    // Grandchild: cascaded by the DAO (recursive triggers are off).
    final grandchild = await summaryOf(db, 'grandchild');
    expect(grandchild.parentId, 'child');
    expect(grandchild.spaceUuid, spaceB);

    // The unrelated sibling stays.
    expect((await summaryOf(db, 'sibling')).spaceUuid, spaceA);
  });

  test(
    'the trigger alone moves a direct child on a raw scope update',
    () async {
      await db.tabDao.moveToScope([
        'parent',
      ], TabOrderScope.normal(spaceUuid: spaceB));

      expect((await summaryOf(db, 'parent')).spaceUuid, spaceB);
      expect((await summaryOf(db, 'child')).spaceUuid, spaceB);
      expect((await summaryOf(db, 'grandchild')).spaceUuid, spaceB);
      expect(await idsInScope(db, TabOrderScope.normal(spaceUuid: spaceB)), [
        'parent',
        'child',
        'grandchild',
      ]);
      expect(await idsInScope(db, TabOrderScope.normal(spaceUuid: spaceA)), [
        'sibling',
      ]);
    },
  );

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
