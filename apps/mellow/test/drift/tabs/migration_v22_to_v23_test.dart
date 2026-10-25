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
    'migration from v22 to v23 adds tab.engine_opener_id and keeps every row',
    () async {
      final schema = await verifier.schemaAt(22);
      final oldDb = schema.newConnection();

      await oldDb.executor.ensureOpen(_NoopUser());

      Future<void> run(String sql, [List<Object?> args = const []]) =>
          oldDb.executor.runCustom(sql, args);

      Future<void> insertTab(String id, String orderKey) => run(
        'INSERT INTO tab (id, engine_tab_id, source, order_key, url, title, '
        'has_static_icon, default_container, tab_mode, timestamp) '
        "VALUES (?, ?, 0, ?, 'https://example.org/', ?, 0, 0, 0, 1700000000)",
        [id, id, orderKey, id],
      );
      await insertTab('A', 'a');
      await insertTab('B', 'b');

      await oldDb.executor.close();

      final db = TabDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 23);

      // Every row survives, and engine provenance was never recorded for any.
      final rows = await db.tab.select().get();
      expect(rows.map((r) => r.id).toSet(), {'A', 'B'});
      expect(rows.every((r) => r.engineOpenerId == null), isTrue);
      expect(rows.firstWhere((r) => r.id == 'A').orderKey, 'a');

      // The column is writable and is read back by the provenance walk.
      await db.customStatement(
        "UPDATE tab SET engine_opener_id = 'A' WHERE id = 'B'",
      );
      expect(
        (await db.definitionsDrift
                .engineOpenedContainerDescendants(tabId: 'A')
                .get())
            .toSet(),
        {'A', 'B'},
      );

      await db.close();
    },
  );
}

class _NoopUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 22;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
