// dart format width=80
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/data/database/functions/url_functions.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper(), setup: registerUrlFunctions);
  });

  test(
    'migration from v20 to v21 drops parent_id and keeps every row',
    () async {
      final schema = await verifier.schemaAt(20);
      final oldDb = schema.newConnection();

      await oldDb.executor.ensureOpen(_NoopUser());

      Future<void> run(String sql, [List<Object?> args = const []]) =>
          oldDb.executor.runCustom(sql, args);

      const spaceUuid = '{aaaaaaaa-0000-0000-0000-000000000000}';
      await run(
        "INSERT INTO space (uuid, name, order_index) VALUES (?, 'Work', 0)",
        [spaceUuid],
      );
      await run(
        "INSERT INTO tab_folder (id, name, space_uuid, order_key, is_collapsed) "
        "VALUES ('F', 'Folder', ?, 'f', 0)",
        [spaceUuid],
      );

      // A parent, a child and a grandchild, plus a folder member and a tab with
      // no space at all: every shape the column could be holding.
      Future<void> insertTab({
        required String id,
        String? parentId,
        String? spaceUuid,
        String? folderId,
        int tabShelf = 0,
        required String orderKey,
      }) => run(
        'INSERT INTO tab (id, engine_tab_id, source, parent_id, space_uuid, '
        'folder_id, tab_shelf, order_key, url, title, has_static_icon, '
        'default_container, tab_mode, timestamp) '
        'VALUES (?, ?, 0, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 1700000000)',
        [
          id,
          id,
          parentId,
          spaceUuid,
          folderId,
          tabShelf,
          orderKey,
          'https://$id.example/',
          id,
        ],
      );

      await insertTab(id: 'root', spaceUuid: spaceUuid, orderKey: 'a');
      await insertTab(
        id: 'child',
        parentId: 'root',
        spaceUuid: spaceUuid,
        orderKey: 'b',
      );
      await insertTab(
        id: 'grandchild',
        parentId: 'child',
        spaceUuid: spaceUuid,
        orderKey: 'c',
      );
      await insertTab(
        id: 'filed',
        spaceUuid: spaceUuid,
        folderId: 'F',
        tabShelf: 1,
        orderKey: 'd',
      );
      await insertTab(id: 'private', orderKey: 'e');

      await oldDb.executor.close();

      final db = TabDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 21);

      // Every row survives, with every other column intact.
      final rows = {
        for (final row
            in await db
                .customSelect(
                  'SELECT id, engine_tab_id, space_uuid, folder_id, tab_shelf, '
                  'order_key, CAST(url AS TEXT) AS url, title FROM tab',
                )
                .get())
          row.read<String>('id'): row,
      };
      expect(
        rows.keys,
        unorderedEquals(<String>[
          'root',
          'child',
          'grandchild',
          'filed',
          'private',
        ]),
      );
      expect(rows['child']!.read<String>('order_key'), 'b');
      expect(rows['child']!.read<String>('engine_tab_id'), 'child');
      expect(rows['child']!.read<String>('url'), 'https://child.example/');
      expect(rows['child']!.read<String>('title'), 'child');
      expect(rows['child']!.read<String?>('space_uuid'), spaceUuid);
      expect(rows['filed']!.read<String?>('folder_id'), 'F');
      expect(rows['filed']!.read<int>('tab_shelf'), 1);
      expect(rows['private']!.read<String?>('space_uuid'), isNull);

      // The column, its index and its two triggers are gone.
      final columns = await db.customSelect("PRAGMA table_info('tab')").get();
      expect(
        columns.map((row) => row.read<String>('name')),
        isNot(contains('parent_id')),
      );

      final leftovers = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name IN "
            "('idx_tab_parent_space', 'tab_maintain_parent_chain_on_delete', "
            "'tab_child_follows_parent_scope')",
          )
          .get();
      expect(leftovers, isEmpty);

      // The FTS index was rebuilt against the new rowids, so a search still
      // finds the migrated rows.
      final hits = await db
          .customSelect("SELECT rowid FROM tab_fts WHERE tab_fts MATCH 'child'")
          .get();
      expect(hits, isNotEmpty);

      await db.close();
    },
  );
}

class _NoopUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 20;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
