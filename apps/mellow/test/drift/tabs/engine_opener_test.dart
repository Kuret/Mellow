import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/data/database/functions/lexo_rank_functions.dart';
import 'package:mellow/data/database/functions/url_functions.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
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

  Future<String?> openerOf(String id) async {
    final row = await (db.tab.select()..where((t) => t.id.equals(id)))
        .getSingle();
    return row.engineOpenerId;
  }

  test('insertTab records the engine opener without filing by it', () async {
    await db.spaceDao.insertSpace(
      SpaceData(uuid: 'home', name: 'home', orderIndex: 0),
    );
    await db.spaceDao.insertSpace(
      SpaceData(uuid: 'work', name: 'work', orderIndex: 1),
    );
    await db.tabDao.insertTab(
      'opener',
      source: TabSource.addedEvent,
      spaceUuid: const Value('work'),
    );

    await db.tabDao.insertTab(
      'child',
      source: TabSource.addedEvent,
      engineOpenerId: const Value('opener'),
      spaceUuid: const Value('home'),
    );

    expect(await openerOf('opener'), isNull);
    expect(await openerOf('child'), 'opener');
    // Provenance is not placement: the child is in the space it was filed in.
    final child = await (db.tab.select()..where((t) => t.id.equals('child')))
        .getSingle();
    expect(child.spaceUuid, 'home');
  });

  test('an opener whose row is absent is still recorded', () async {
    await db.tabDao.insertTab(
      'orphan',
      source: TabSource.addedEvent,
      engineOpenerId: const Value('never-inserted'),
    );

    expect(await openerOf('orphan'), 'never-inserted');
  });

  test('engineOpenedContainerDescendants follows provenance, stays in the '
      'container and crosses neither a moved branch nor a gap', () async {
    Future<void> add(String id, {String? opener, String? container}) =>
        db.tabDao.insertTab(
          id,
          source: TabSource.addedEvent,
          engineOpenerId: Value(opener),
          containerId: Value(container),
        );
    await db.containerDao.addContainer(
      ContainerData(id: 'c1', name: 'one', orderKey: 'a'),
    );
    await db.containerDao.addContainer(
      ContainerData(id: 'c2', name: 'two', orderKey: 'b'),
    );
    await add('root', container: 'c1');
    await add('child', opener: 'root', container: 'c1');
    await add('grandchild', opener: 'child', container: 'c1');
    await add('moved', opener: 'root', container: 'c2');
    await add('below-moved', opener: 'moved', container: 'c1');
    await add('unrelated', container: 'c1');

    final ids = await db.definitionsDrift
        .engineOpenedContainerDescendants(tabId: 'root')
        .get();

    expect(ids.toSet(), {'root', 'child', 'grandchild'});
  });
}
