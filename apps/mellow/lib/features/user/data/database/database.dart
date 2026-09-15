/*
 * Copyright (c) 2024-2026 Fabian Freund.
 *
 * This file is part of WebLibre
 * (see https://weblibre.eu).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import 'package:drift/drift.dart';
import 'package:drift/internal/versioned_schema.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter/foundation.dart';
import 'package:weblibre/features/user/data/database/daos/cache.dart';
import 'package:weblibre/features/user/data/database/daos/search_history.dart';
import 'package:weblibre/features/user/data/database/daos/search_tokens.dart';
import 'package:weblibre/features/user/data/database/daos/setting.dart';
import 'package:weblibre/features/user/data/database/daos/toolbar_button_config.dart';
import 'package:weblibre/features/user/data/database/database.drift.dart';
import 'package:weblibre/features/user/data/database/database.steps.dart';

@DriftDatabase(
  include: {'definitions.drift'},
  daos: [
    SettingDao,
    CacheDao,
    ToolbarButtonConfigDao,
    SearchTokensDao,
    SearchHistoryDao,
  ],
)
class UserDatabase extends $UserDatabase {
  @override
  final int schemaVersion = 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      if (kDebugMode) {
        // This check pulls in a fair amount of code that's not needed
        // anywhere else, so we recommend only doing it in debug builds.
        await validateDatabaseSchema();
      }

      await customStatement('PRAGMA foreign_keys = ON;');

      await onAfterOpen?.call(this);
    },
    onUpgrade: (m, from, to) async {
      // Following the advice from https://drift.simonbinder.eu/Migrations/api/#general-tips
      await customStatement('PRAGMA foreign_keys = OFF');

      await transaction(
        () => VersionedSchema.runMigrationSteps(
          migrator: m,
          from: from,
          to: to,
          steps: _upgrade,
        ),
      );

      if (kDebugMode) {
        final wrongForeignKeys = await customSelect(
          'PRAGMA foreign_key_check',
        ).get();
        assert(
          wrongForeignKeys.isEmpty,
          '${wrongForeignKeys.map((e) => e.data)}',
        );
      }

      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  UserDatabase(super.e, {this.onAfterOpen});

  final Future<void> Function(UserDatabase db)? onAfterOpen;

  static final _upgrade = migrationSteps(
    from1To2: (m, schema) async {
      await m.createTable(schema.riverpod);
    },
    from2To3: (m, schema) async {
      await m.createTable(schema.toolbarButtonConfigs);
      await m.createIndex(schema.idxToolbarOrderKey);
    },
    from3To4: (m, schema) async {
      await m.createTable(schema.searchTokens);
      await m.createIndex(schema.idxSearchTokensInsertedAt);
    },
    from4To5: (m, schema) async {
      await m.addColumn(schema.searchTokens, schema.searchTokens.reservedAt);
      await m.createIndex(schema.idxSearchTokensReservedAt);
    },
    from5To6: (m, schema) async {
      await m.createTable(schema.proxyProfile);
      await m.createIndex(schema.idxProxyProfileUpdatedAt);
      await m.createTable(schema.proxyRoutingSetting);
    },
    from6To7: (m, schema) async {
      await m.addColumn(
        schema.proxyProfile,
        schema.proxyProfile.dnsOverrideJson,
      );
    },
    from7To8: (m, schema) async {
      await m.database.customStatement(
        'DROP TABLE IF EXISTS proxy_routing_setting',
      );
    },
    from8To9: (m, schema) async {
      await m.createTable(schema.quickSwitcherButtonConfigs);
      await m.createIndex(schema.idxQuickSwitcherOrderKey);
    },
    from9To10: (m, schema) async {
      await m.addColumn(schema.proxyProfile, schema.proxyProfile.autostart);
    },
    from10To11: (m, schema) async {
      // Proxy/Tor support was removed; the sing-box profile store goes with
      // it. Frozen DROP rather than `m.deleteTable(schema.proxyProfile)`,
      // matching the from7To8 precedent for proxy_routing_setting — this
      // step's meaning must not drift with the current schema.
      await m.database.customStatement('DROP TABLE IF EXISTS proxy_profile');
    },
    from11To12: (m, schema) async {
      await m.createTable(schema.searchHistory);
      await m.createIndex(schema.idxSearchHistoryDate);
    },
    from12To13: (m, schema) async {
      // The settings this fork owns left upstream's `GeneralSettings` for
      // `ZenSettings`, so their rows move from the `general` partition to
      // `zen`. Data only — the `setting` table itself is unchanged, and
      // `key` is its primary key, so re-tagging the partition carries every
      // value across untouched. Losing them would cost the user their rail
      // width and side, silently re-enable uploads, and — worst — drop the
      // incremental sync bookkeeping, forcing a full re-fetch that can
      // resurrect deleted records.
      //
      // Frozen literals rather than `zenSettingColumnTypes`: this step's
      // meaning must not drift with the current model, following the
      // from7To8 precedent above.
      await m.database.customStatement('''
UPDATE setting SET partition_key = 'zen'
WHERE partition_key = 'general' AND "key" IN (
  'spacesSyncEnabled',
  'spacesSyncWritesEnabled',
  'spacesSyncLastSyncId',
  'spacesSyncLastModified',
  'spacesSyncBaselineDone',
  'spacesSyncApplierVersion',
  'spacesSyncMaxTombstoneFraction',
  'spacesSyncMaxTombstoneCount',
  'railSide',
  'railWidth',
  'maxLiveTabs',
  'separateEssentials'
)''');
    },
    from13To14: (m, schema) async {
      // The onboarding wizard is gone (along with `OnboardingRepository` and
      // `OnboardingDao`), and with it the only code that ever wrote this
      // table: a single row recording which wizard revision a profile had
      // completed. Frozen DROP rather than `m.deleteTable(schema.onboarding)`,
      // matching the from7To8/from11To12 precedent — this step's meaning must
      // not drift with the current schema. Losing the row is safe: nothing
      // reads it, and there is no wizard left for it to gate.
      await m.database.customStatement('DROP TABLE IF EXISTS onboarding');
    },
    from14To15: (m, schema) async {
      // The quick switcher button cluster is gone (along with
      // `QuickSwitcherButtonRow`, `QuickSwitcherToolbarConfigRepository` and
      // `QuickSwitcherButtonConfigDao`), and with it the only code that ever
      // read or wrote this table. Its defaults shipped with every button
      // hidden, so no user ever saw the cluster or configured it. Frozen
      // DROP rather than `m.deleteTable(schema.quickSwitcherButtonConfigs)`,
      // matching the from7To8/from11To12/from13To14 precedent — this step's
      // meaning must not drift with the current schema. Losing the rows is
      // safe: nothing reads them, and there is no cluster left for them to
      // configure. Dropping the table takes its index
      // (`idx_quick_switcher_order_key`) with it, so there is no separate
      // DROP INDEX.
      await m.database.customStatement(
        'DROP TABLE IF EXISTS quick_switcher_button_configs',
      );
    },
  );
}
