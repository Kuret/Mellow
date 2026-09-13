// dart format width=80
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:weblibre/data/database/functions/lexo_rank_functions.dart';
import 'package:weblibre/features/user/data/database/database.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/data/providers.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(
      GeneratedHelper(),
      setup: registerLexorankFunctions,
    );
  });

  /// Wires [db] up to a container and keeps the teardown order right: the
  /// repositories hold a streaming query, so the container has to go before
  /// the database does or `close()` waits on a subscription that never ends.
  ProviderContainer containerFor(UserDatabase db) {
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [userDatabaseProvider.overrideWith((ref) => db)],
    );
    addTearDown(container.dispose);
    return container;
  }

  // These twelve values are live on real devices. The sync bookkeeping drives
  // incremental sync, so losing it forces a full re-fetch that can resurrect
  // deleted records, and losing `spacesSyncWritesEnabled` silently turns
  // uploads back on.
  test('migration from v12 to v13 carries every fork setting into the zen '
      'partition', () async {
    final schema = await verifier.schemaAt(12);
    final oldDb = schema.newConnection();

    await oldDb.executor.ensureOpen(_NoopUser());

    Future<void> put(String key, Object? value) => oldDb.executor.runCustom(
      'INSERT INTO setting ("key", partition_key, "value") '
      "VALUES (?, 'general', ?)",
      [key, value],
    );

    // Deliberately non-default in every field, so a value that fails to
    // cross shows up as the default rather than passing by luck.
    await put('spacesSyncEnabled', 0);
    await put('spacesSyncWritesEnabled', 0);
    await put('spacesSyncLastSyncId', 'zGVfP2Kx1A');
    await put('spacesSyncLastModified', 1758000123.45);
    await put('spacesSyncBaselineDone', 1);
    await put('spacesSyncApplierVersion', 4);
    await put('spacesSyncMaxTombstoneFraction', 0.35);
    await put('spacesSyncMaxTombstoneCount', 12);
    await put('railSide', 'right');
    await put('railWidth', 216.0);
    await put('maxLiveTabs', 40);
    await put('separateEssentials', 0);

    // An upstream setting in the same partition, which must not move.
    await put('themeMode', 'dark');

    await oldDb.executor.close();

    final db = UserDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 13);

    final container = containerFor(db);

    final zen = await container
        .read(zenSettingsRepositoryProvider.notifier)
        .fetchSettings();

    expect(zen.spacesSyncEnabled, isFalse);
    expect(zen.spacesSyncWritesEnabled, isFalse);
    expect(zen.spacesSyncLastSyncId, 'zGVfP2Kx1A');
    expect(zen.spacesSyncLastModified, 1758000123.45);
    expect(zen.spacesSyncBaselineDone, isTrue);
    expect(zen.spacesSyncApplierVersion, 4);
    expect(zen.spacesSyncMaxTombstoneFraction, 0.35);
    expect(zen.spacesSyncMaxTombstoneCount, 12);
    expect(zen.railSide, RailSide.right);
    expect(zen.railWidth, 216.0);
    expect(zen.maxLiveTabs, 40);
    expect(zen.separateEssentials, isFalse);

    // Upstream's own settings are untouched.
    final general = await container
        .read(generalSettingsRepositoryProvider.notifier)
        .fetchSettings();
    expect(general.themeMode.name, 'dark');

    // And nothing of ours is left behind in `general`.
    final partitions = {
      for (final row
          in await db
              .customSelect('SELECT "key", partition_key FROM setting')
              .get())
        row.read<String>('key'): row.read<String?>('partition_key'),
    };
    expect(partitions['themeMode'], 'general');
    for (final key in zenSettingColumnTypes.keys) {
      expect(partitions[key], 'zen', reason: '$key stayed behind');
    }
  });

  test('the migration leaves a profile that never wrote them alone', () async {
    final schema = await verifier.schemaAt(12);
    final oldDb = schema.newConnection();

    await oldDb.executor.ensureOpen(_NoopUser());
    await oldDb.executor.runCustom(
      'INSERT INTO setting ("key", partition_key, "value") '
      "VALUES ('themeMode', 'general', 'dark')",
    );
    await oldDb.executor.close();

    final db = UserDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 13);

    final zen = await containerFor(
      db,
    ).read(zenSettingsRepositoryProvider.notifier).fetchSettings();

    expect(zen, ZenSettings.withDefaults());
  });

  test('a setting written after the migration lands in zen', () async {
    final db = UserDatabase(
      NativeDatabase.memory(setup: registerLexorankFunctions),
    );
    final container = containerFor(db);

    await container
        .read(zenSettingsRepositoryProvider.notifier)
        .updateSettings((current) => current.copyWith.railWidth(184));

    final partition = await db
        .customSelect(
          'SELECT partition_key FROM setting WHERE "key" = ?',
          variables: [Variable<String>('railWidth')],
        )
        .getSingle();
    expect(partition.read<String?>('partition_key'), zenSettingsPartitionKey);

    expect(
      (await container
              .read(zenSettingsRepositoryProvider.notifier)
              .fetchSettings())
          .railWidth,
      184,
    );
  });
}

class _NoopUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 12;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
