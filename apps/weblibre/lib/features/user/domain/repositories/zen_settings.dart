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
import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:nullability/nullability.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/data/providers.dart';

part 'zen_settings.g.dart';

typedef UpdateZenSettingsFunc =
    ZenSettings Function(ZenSettings currentSettings);

/// Partition key of every setting this fork owns. Kept next to the column map
/// because the two travel together: the user database's v12 -> v13 step moves
/// exactly [zenSettingColumnTypes]'s keys out of the `general` partition and
/// into this one.
const zenSettingsPartitionKey = 'zen';

/// Column type for every persisted `zen` setting, keyed by its JSON name.
///
/// **Every field on [ZenSettings] must appear here or in
/// [zenSettingJsonKeys].** A missing entry means the setting writes fine but
/// silently reverts to its default on the next launch, because it is never read
/// back out of the database. `zen_settings_deserialize_test.dart` guards this.
@visibleForTesting
const zenSettingColumnTypes = <String, DriftSqlType>{
  'spacesSyncEnabled': DriftSqlType.bool,
  'spacesSyncWritesEnabled': DriftSqlType.bool,
  'spacesSyncLastSyncId': DriftSqlType.string,
  'spacesSyncLastModified': DriftSqlType.double,
  'spacesSyncBaselineDone': DriftSqlType.bool,
  'spacesSyncApplierVersion': DriftSqlType.int,
  'spacesSyncMaxTombstoneFraction': DriftSqlType.double,
  'spacesSyncMaxTombstoneCount': DriftSqlType.int,
  'railSide': DriftSqlType.string,
  'spaceIndicatorSide': DriftSqlType.string,
  'railWidth': DriftSqlType.double,
  'compactRailSide': DriftSqlType.string,
  'swipeToMoveRail': DriftSqlType.bool,
  // Persisted name for ZenSettings.showToolbarButtons: kept as
  // 'showRailToolbar' (its old field name, from before the setting also
  // covered the compact bar) so profiles that already turned it off are not
  // silently reset by the rename. See the @JsonKey on the field itself.
  'showRailToolbar': DriftSqlType.bool,
  'maxLiveTabs': DriftSqlType.int,
  'separateEssentials': DriftSqlType.bool,
  'profileDefaultsRevision': DriftSqlType.int,
  'accentColor': DriftSqlType.int,
};

/// Settings stored as a JSON document in a TEXT column. Their value has to be
/// decoded before it reaches [ZenSettings.fromJson], which expects the
/// already-parsed list/map — listing one in [zenSettingColumnTypes] as well
/// would hand `fromJson` the raw encoded string.
///
/// These keys need no database migration: the `setting` table is a key/value
/// store partitioned by name, so a JSON document is another TEXT row in the
/// `zen` partition.
@visibleForTesting
const zenSettingJsonKeys = <String>{'customSearchProviders'};

@Riverpod(keepAlive: true)
class ZenSettingsRepository extends _$ZenSettingsRepository {
  final _partitionKey = zenSettingsPartitionKey;

  ZenSettings _deserializeSettings(List<MapEntry<String, DriftAny?>> entries) {
    final settings = Map.fromEntries(entries);

    final typeMapping = ref.read(userDatabaseProvider).typeMapping;

    return ZenSettings.fromJson({
      for (final MapEntry(key: key, value: type)
          in zenSettingColumnTypes.entries)
        key: settings[key]?.readAs(type, typeMapping),
      for (final key in zenSettingJsonKeys)
        key: settings[key]
            ?.readAs(DriftSqlType.string, typeMapping)
            .mapNotNull(jsonDecode),
    });
  }

  //Eager fetch, when up to date settings are required
  Future<ZenSettings> fetchSettings() {
    return ref
        .read(userDatabaseProvider)
        .settingDao
        .getAllSettingsOfPartitionKey(_partitionKey)
        .get()
        .then(_deserializeSettings);
  }

  Future<void> updateSettings(UpdateZenSettingsFunc updateWithCurrent) async {
    final db = ref.read(userDatabaseProvider);

    final current = await fetchSettings();

    final oldJson = current.toJson();
    final newJson = updateWithCurrent(current).toJson();

    return db.transaction(() async {
      for (final MapEntry(:key, :value) in newJson.entries) {
        if (oldJson[key] != value) {
          await db.settingDao.updateSetting(key, _partitionKey, value);
        }
      }
    });
  }

  @override
  Stream<ZenSettings> build() {
    final db = ref.watch(userDatabaseProvider);

    return db.settingDao
        .getAllSettingsOfPartitionKey(_partitionKey)
        .watch()
        .map((event) {
          return _deserializeSettings(event);
        });
  }
}

@Riverpod(keepAlive: true)
ZenSettings zenSettingsWithDefaults(Ref ref) {
  return ref.watch(
    zenSettingsRepositoryProvider.select(
      (value) => value.value ?? ZenSettings.withDefaults(),
    ),
  );
}
