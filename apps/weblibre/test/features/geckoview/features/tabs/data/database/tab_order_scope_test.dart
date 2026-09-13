import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:lexo_rank/lexo_rank.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/scope_slot.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_split_data.dart';

import 'tab_db_test_helpers.dart';

void main() {
  late TabDatabase db;

  const spaceA = '{aaaaaaaa-0000-0000-0000-000000000000}';
  const spaceB = '{bbbbbbbb-0000-0000-0000-000000000000}';
  const folderF = 'folder-f';

  final aNormal = TabOrderScope.normal(spaceUuid: spaceA);
  final aPinned = TabOrderScope.pinned(spaceA);
  final aFolder = TabOrderScope.normal(spaceUuid: spaceA, folderId: folderF);
  final bNormal = TabOrderScope.normal(spaceUuid: spaceB);
  final bPinned = TabOrderScope.pinned(spaceB);

  setUp(() async {
    db = openTestTabDatabase();
    await seedSpaces(db, const [spaceA, spaceB]);
    await db.tabFolderDao.insertFolder(
      TabFolderData(id: folderF, name: 'F', spaceUuid: spaceA, orderKey: 'f'),
    );
    // Two spaces × pinned/normal, plus one folder in space A.
    await seedTab(db, 'a1', spaceUuid: spaceA);
    await seedTab(db, 'a2', spaceUuid: spaceA);
    await seedTab(db, 'ap1', spaceUuid: spaceA, shelf: TabShelf.pinned);
    await seedTab(db, 'ap2', spaceUuid: spaceA, shelf: TabShelf.pinned);
    await seedTab(db, 'f1', spaceUuid: spaceA, folderId: folderF);
    await seedTab(db, 'f2', spaceUuid: spaceA, folderId: folderF);
    await seedTab(db, 'b1', spaceUuid: spaceB);
    await seedTab(db, 'b2', spaceUuid: spaceB);
    await seedTab(db, 'bp1', spaceUuid: spaceB, shelf: TabShelf.pinned);
  });

  tearDown(() => db.close());

  int compareKeys(String a, String b) =>
      LexoRank.parse(a).compareTo(LexoRank.parse(b));

  test('inserts rank against their own scope only', () async {
    expect(await idsInScope(db, aNormal), ['a1', 'a2']);
    expect(await idsInScope(db, aPinned), ['ap1', 'ap2']);
    expect(await idsInScope(db, aFolder), ['f1', 'f2']);
    expect(await idsInScope(db, bNormal), ['b1', 'b2']);
    expect(await idsInScope(db, bPinned), ['bp1']);

    // Each scope starts from the same seed key: the first tab of every scope
    // gets an identical key, which is only possible if generation never
    // looked across scopes.
    final a1 = await summaryOf(db, 'a1');
    final b1 = await summaryOf(db, 'b1');
    final f1 = await summaryOf(db, 'f1');
    final ap1 = await summaryOf(db, 'ap1');
    expect(b1.orderKey, a1.orderKey);
    expect(f1.orderKey, a1.orderKey);
    expect(ap1.orderKey, a1.orderKey);
  });

  test('leading and trailing keys bracket the scope', () async {
    for (final (scope, first, last) in [
      (aNormal, 'a1', 'a2'),
      (aPinned, 'ap1', 'ap2'),
      (aFolder, 'f1', 'f2'),
      (bNormal, 'b1', 'b2'),
    ]) {
      final leading = await db.tabDao.leadingOrderKey(scope).getSingle();
      final trailing = await db.tabDao.trailingOrderKey(scope).getSingle();
      final firstKey = (await summaryOf(db, first)).orderKey;
      final lastKey = (await summaryOf(db, last)).orderKey;
      expect(compareKeys(leading, firstKey), lessThan(0), reason: '$scope');
      expect(compareKeys(trailing, lastKey), greaterThan(0), reason: '$scope');
    }
  });

  test('after/before keys land between scope neighbours', () async {
    final a1 = (await summaryOf(db, 'a1')).orderKey;
    final a2 = (await summaryOf(db, 'a2')).orderKey;

    final after = await db.tabDao
        .orderKeyAfterTab('a1', scope: aNormal)
        .getSingleOrNull();
    expect(after, isNotNull);
    expect(compareKeys(after!, a1), greaterThan(0));
    expect(compareKeys(after, a2), lessThan(0));

    final before = await db.tabDao
        .orderKeyBeforeTab('a2', scope: aNormal)
        .getSingleOrNull();
    expect(before, isNotNull);
    expect(compareKeys(before!, a1), greaterThan(0));
    expect(compareKeys(before, a2), lessThan(0));
  });

  test('after/before keys ignore tabs outside the scope', () async {
    // a1 is not in space B, nor on A's pinned shelf, nor in the folder.
    expect(
      await db.tabDao.orderKeyAfterTab('a1', scope: bNormal).getSingleOrNull(),
      isNull,
    );
    expect(
      await db.tabDao.orderKeyAfterTab('a1', scope: aPinned).getSingleOrNull(),
      isNull,
    );
    expect(
      await db.tabDao.orderKeyBeforeTab('a1', scope: aFolder).getSingleOrNull(),
      isNull,
    );
    expect(
      await db.tabDao.orderKeyBeforeTab('b1', scope: aNormal).getSingleOrNull(),
      isNull,
    );
  });

  test('a new tab appends to the end of its scope', () async {
    await seedTab(db, 'a3', spaceUuid: spaceA);
    expect(await idsInScope(db, aNormal), ['a1', 'a2', 'a3']);

    expect(await idsInScope(db, aFolder), ['f1', 'f2']);
    expect(await idsInScope(db, bNormal), ['b1', 'b2']);
  });

  test('scopeSiblings ignores other scopes', () async {
    Future<List<String>> siblings(TabOrderScope scope) => db.tabDao
        .scopeSiblings(scope)
        .get()
        .then((rows) => [for (final row in rows) row.id]);

    expect(await siblings(aNormal), ['a1', 'a2']);
    expect(await siblings(aPinned), ['ap1', 'ap2']);
    expect(await siblings(aFolder), ['f1', 'f2']);
    expect(await siblings(bNormal), ['b1', 'b2']);
  });

  test('scopeChildSlots lists the pinned section, folders included, then the '
      'normal slots by key', () async {
    // Rebuild space A with explicit keys so the interleaving is
    // unambiguous. Folders live in the pinned section (Zen), so the pinned
    // sequence is ap1 < folder < ap2 and the normal one a1 < split < a2.
    var rank = LexoRank.middle();
    final keys = <String>[];
    for (var i = 0; i < 6; i++) {
      keys.add(rank.value);
      rank = rank.genNext();
    }
    await (db.tab.update()..where((t) => t.id.equals('ap1'))).write(
      TabCompanion(orderKey: Value(keys[0])),
    );
    await (db.tab.update()..where((t) => t.id.equals('ap2'))).write(
      TabCompanion(orderKey: Value(keys[2])),
    );
    await (db.tab.update()..where((t) => t.id.equals('a1'))).write(
      TabCompanion(orderKey: Value(keys[3])),
    );
    await (db.tabFolder.update()..where((f) => f.id.equals(folderF))).write(
      TabFolderCompanion(orderKey: Value(keys[1])),
    );
    await seedTab(db, 's1', spaceUuid: spaceA);
    await seedTab(db, 's2', spaceUuid: spaceA);
    await db.tabSplitDao.insertSplit(
      TabSplitData(id: 'split', spaceUuid: spaceA, orderKey: keys[4]),
    );
    await db.tabSplitDao.setMembers('split', ['s1', 's2']);
    await (db.tab.update()..where((t) => t.id.equals('a2'))).write(
      TabCompanion(orderKey: Value(keys[5])),
    );

    final slots = await db.tabDao.scopeChildSlots(spaceA, null);
    expect(
      [for (final slot in slots) (slot.kind, slot.id)],
      [
        (ScopeSlotKind.tab, 'ap1'),
        (ScopeSlotKind.folder, folderF),
        (ScopeSlotKind.tab, 'ap2'),
        (ScopeSlotKind.tab, 'a1'),
        (ScopeSlotKind.split, 'split'),
        (ScopeSlotKind.tab, 'a2'),
      ],
    );
    expect(slots.take(3).every((s) => s.shelf == TabShelf.pinned), isTrue);
    expect(slots.skip(3).every((s) => s.shelf == TabShelf.normal), isTrue);
    // Split members and the folder's tabs are not slots of the space root.
    final ids = slots.map((s) => s.id).toSet();
    expect(ids, isNot(contains('s1')));
    expect(ids, isNot(contains('s2')));
    expect(ids, isNot(contains('f1')));

    final folderSlots = await db.tabDao.scopeChildSlots(spaceA, folderF);
    expect([for (final s in folderSlots) s.id], ['f1', 'f2']);
  });
}
