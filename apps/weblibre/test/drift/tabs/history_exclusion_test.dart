import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/data/database/functions/lexo_rank_functions.dart';
import 'package:weblibre/data/database/functions/url_functions.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_local_data.dart';

void main() {
  late TabDatabase db;

  setUp(() async {
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

  test('reports every tab, flagging the ones in excluded containers', () async {
    await _insertContainer(db, 'excluded', excludeFromHistory: true);
    await _insertContainer(db, 'recorded', excludeFromHistory: false);
    await _insertTab(db, id: 'excluded-tab', containerId: 'excluded');
    await _insertTab(db, id: 'recorded-tab', containerId: 'recorded');
    await _insertTab(db, id: 'uncontained-tab', containerId: null);

    final rows = await db.tabDao.historyExclusionTabs().get();

    expect(
      {for (final row in rows) row.tabId: row.excluded},
      {
        'excluded-tab': true,
        'recorded-tab': false,
        // An uncontained tab has no container to opt it out.
        'uncontained-tab': false,
      },
    );
  });

  test('excludes a container regardless of pinning', () async {
    // Every container's Gecko contextId is simply its own id now (no
    // separate cookie-isolation identity), so a plain container can use
    // exclude-from-history just like any other.
    await _insertContainer(db, 'plain', excludeFromHistory: true);
    await _insertTab(db, id: 'tab', containerId: 'plain');

    final rows = await db.tabDao.historyExclusionTabs().get();

    expect(rows.single.excluded, isTrue);
    expect(await db.containerDao.excludedHistoryContextIds().get(), ['plain']);
  });

  test('reports contextIds of excluded containers', () async {
    await _insertContainer(db, 'isolated-excluded', excludeFromHistory: true);
    await _insertContainer(db, 'isolated-recorded', excludeFromHistory: false);

    expect(await db.containerDao.excludedHistoryContextIds().get(), [
      'isolated-excluded',
    ]);
  });

  test('keeps excluded containers out of the local search index', () async {
    await db.customStatement(
      'INSERT INTO local_index_setting ("key", value) '
      "VALUES ('enabled', 1), ('index_private', 0)",
    );
    await _insertContainer(db, 'excluded', excludeFromHistory: true);
    await _insertContainer(db, 'recorded', excludeFromHistory: false);

    await _insertTab(db, id: 'recorded-tab', containerId: 'recorded');
    expect(await _indexedHosts(db), ['example.com']);

    await _insertTab(db, id: 'excluded-tab', containerId: 'excluded');
    expect(await _indexedHosts(db), ['example.com']);

    // Only the recorded tab's page is indexed; the excluded one never enters.
    final canonicals = await _indexedCanonicals(db);
    expect(canonicals, ['https://example.com/recorded-tab']);
  });

  test('turning the flag on evicts already indexed pages', () async {
    await db.customStatement(
      'INSERT INTO local_index_setting ("key", value) '
      "VALUES ('enabled', 1), ('index_private', 0)",
    );
    await _insertContainer(db, 'container', excludeFromHistory: false);
    await _insertTab(db, id: 'tab', containerId: 'container');

    expect(await _indexedCanonicals(db), ['https://example.com/tab']);

    await db.containerDao.upsertLocal(
      ContainerLocalData(containerId: 'container', excludeFromHistory: true),
    );

    expect(await _indexedCanonicals(db), isEmpty);
  });

  test('follows a tab moved between containers', () async {
    await _insertContainer(db, 'excluded', excludeFromHistory: true);
    await _insertContainer(db, 'recorded', excludeFromHistory: false);
    await _insertTab(db, id: 'tab', containerId: 'recorded');

    expect(
      (await db.tabDao.historyExclusionTabs().get()).single.excluded,
      isFalse,
    );

    await db.customStatement(
      "UPDATE tab SET container_id = 'excluded' WHERE id = 'tab'",
    );

    expect(
      (await db.tabDao.historyExclusionTabs().get()).single.excluded,
      isTrue,
    );
  });
}

Future<List<String?>> _indexedHosts(TabDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT url_host FROM history ORDER BY url_canonical',
        readsFrom: {db.history},
      )
      .get();

  return [for (final row in rows) row.read<String?>('url_host')];
}

Future<List<String?>> _indexedCanonicals(TabDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT url_canonical FROM history ORDER BY url_canonical',
        readsFrom: {db.history},
      )
      .get();

  return [for (final row in rows) row.read<String?>('url_canonical')];
}

Future<void> _insertContainer(
  TabDatabase db,
  String id, {
  required bool excludeFromHistory,
}) async {
  await db.containerDao.addContainer(
    ContainerData(id: id, name: id, orderKey: id),
  );
  await db.containerDao.upsertLocal(
    ContainerLocalData(containerId: id, excludeFromHistory: excludeFromHistory),
  );
}

Future<void> _insertTab(
  TabDatabase db, {
  required String id,
  required String? containerId,
}) {
  return db.tabDao.insertTab(
    id,
    source: TabSource.manual,
    parentId: const Value.absent(),
    containerId: Value(containerId),
    url: Value(Uri.parse('https://example.com/$id')),
  );
}
