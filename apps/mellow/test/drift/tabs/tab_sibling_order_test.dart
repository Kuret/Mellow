import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexo_rank/lexo_rank.dart';
import 'package:mellow/data/database/functions/lexo_rank_functions.dart';
import 'package:mellow/data/database/functions/url_functions.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';

void main() {
  late TabDatabase db;

  setUp(() {
    db = TabDatabase(
      NativeDatabase.memory(
        setup: (database) {
          registerLexorankFunctions(database);
          registerUrlFunctions(database);
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'moveTabAmongSiblings moves a tab past the next tab in its scope',
    () async {
      await _insertTabs(db, const [
        _TabFixture('first'),
        _TabFixture('second'),
        _TabFixture('third'),
      ]);

      final moved = await db.tabDao.moveTabAmongSiblings('first', down: true);

      expect(moved, isTrue);
      expect(await _orderedTabIdsInSpace(db, null), [
        'second',
        'first',
        'third',
      ]);
    },
  );

  test('moveTabAmongSiblings moves a tab up past its predecessor', () async {
    await _insertTabs(db, const [
      _TabFixture('first'),
      _TabFixture('second'),
      _TabFixture('third'),
    ]);

    final moved = await db.tabDao.moveTabAmongSiblings('third', down: false);

    expect(moved, isTrue);
    expect(await _orderedTabIdsInSpace(db, null), ['first', 'third', 'second']);
  });

  test('moveTabAmongSiblings refuses at the end of the scope', () async {
    await _insertTabs(db, const [_TabFixture('only')]);

    expect(await db.tabDao.moveTabAmongSiblings('only', down: true), isFalse);
    expect(await db.tabDao.moveTabAmongSiblings('only', down: false), isFalse);
  });

  test('moveTabAmongSiblings stays inside its own space', () async {
    await _insertSpaces(db, const ['home', 'work']);
    await _insertTabs(db, const [
      _TabFixture('home-first', spaceUuid: 'home'),
      _TabFixture('work-first', spaceUuid: 'work'),
      _TabFixture('work-second', spaceUuid: 'work'),
      _TabFixture('home-second', spaceUuid: 'home'),
    ]);

    final moved = await db.tabDao.moveTabAmongSiblings(
      'work-first',
      down: true,
    );

    expect(moved, isTrue);
    expect(await _orderedTabIdsInSpace(db, 'work'), [
      'work-second',
      'work-first',
    ]);
    expect(await _orderedTabIdsInSpace(db, 'home'), [
      'home-first',
      'home-second',
    ]);
  });
}

Future<List<String>> _orderedTabIdsInSpace(
  TabDatabase db,
  String? spaceUuid,
) async {
  final tabs = await db.tabDao.getSpaceTabsData(spaceUuid).get();

  return (tabs.toList()..sort((a, b) => a.orderKey.compareTo(b.orderKey)))
      .map((tab) => tab.id)
      .toList();
}

Future<void> _insertTabs(TabDatabase db, List<_TabFixture> tabs) async {
  final orderKeys = _spacedOrderKeys(tabs.length);

  for (final (index, tab) in tabs.indexed) {
    await db.tabDao.insertTab(
      tab.id,
      source: tab.source,
      spaceUuid: Value(tab.spaceUuid),
      orderKey: Value(orderKeys[index]),
    );
  }
}

Future<void> _insertSpaces(TabDatabase db, List<String> uuids) async {
  for (final (index, uuid) in uuids.indexed) {
    await db.spaceDao.insertSpace(
      SpaceData(uuid: uuid, name: uuid, orderIndex: index),
    );
  }
}

List<String> _spacedOrderKeys(int count) {
  var rank = LexoRank.middle();
  final orderKeys = <String>[];

  for (var i = 0; i < count; i++) {
    orderKeys.add(rank.value);
    for (var gap = 0; gap < 4; gap++) {
      rank = rank.genNext();
    }
  }

  return orderKeys;
}

class _TabFixture {
  final String id;
  final String? spaceUuid;
  final TabSource source;

  const _TabFixture(this.id, {this.spaceUuid, this.source = TabSource.manual});
}
