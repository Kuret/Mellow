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
    'migration from v21 to v22 adds uploaded_tombstone and keeps the ledgers',
    () async {
      final schema = await verifier.schemaAt(21);
      final oldDb = schema.newConnection();

      await oldDb.executor.ensureOpen(_NoopUser());

      Future<void> run(String sql, [List<Object?> args = const []]) =>
          oldDb.executor.runCustom(sql, args);

      await run(
        "INSERT INTO deleted_record (id, kind, deleted_at) "
        "VALUES ('gone', 'tab', 1700000000)",
      );
      await run(
        "INSERT INTO applied_tombstone (id, applied_at) "
        "VALUES ('applied', 1700000001)",
      );

      await oldDb.executor.close();

      final db = TabDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 22);

      // The new ledger exists, empty, with its default echo count.
      final table = await db
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name = 'uploaded_tombstone'",
          )
          .get();
      expect(table, hasLength(1));
      expect(await db.uploadedTombstone.select().get(), isEmpty);
      await db.syncStateDao.recordUploadedTombstone('fresh');
      final rows = await db.uploadedTombstone.select().get();
      expect(rows.single.id, 'fresh');
      expect(rows.single.echoes, 0);

      // The existing ledgers survive untouched.
      expect(await db.syncStateDao.pendingDeletions(), {'gone': 'tab'});
      final applied = await db.syncStateDao.appliedTombstonesSince(
        DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(applied.keys, ['applied']);

      await db.close();
    },
  );
}

class _NoopUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 21;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
