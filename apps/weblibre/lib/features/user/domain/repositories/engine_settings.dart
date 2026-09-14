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
import 'package:weblibre/features/user/data/models/engine_settings.dart';
import 'package:weblibre/features/user/data/providers.dart';

part 'engine_settings.g.dart';

typedef UpdateEngineSettingsFunc =
    EngineSettings Function(EngineSettings currentSettings);

/// Column type for every persisted `engine` setting, keyed by its JSON name.
///
/// **Every field on [EngineSettings] must appear here or in
/// [engineSettingJsonKeys].** A missing entry means the setting writes fine
/// but silently reverts to its default on the next launch, because it is
/// never read back out of the database. `engine_settings_deserialize_test.dart`
/// guards this.
@visibleForTesting
const engineSettingColumnTypes = <String, DriftSqlType>{
  'incognitoMode': DriftSqlType.bool,
  'javascriptEnabled': DriftSqlType.bool,
  'trackingProtectionPolicy': DriftSqlType.string,
  'userAgent': DriftSqlType.string,
  'enterpriseRootsEnabled': DriftSqlType.bool,
  'remoteDebuggingEnabled': DriftSqlType.bool,
  'addonCollection': DriftSqlType.string,
  'ublockFilterListSettings': DriftSqlType.string,
  'dohSettingsMode': DriftSqlType.string,
  'dohProviderUrl': DriftSqlType.string,
  'dohDefaultProviderUrl': DriftSqlType.string,
  // Custom Tracking Protection
  // Web Content Settings
  'displayDensityOverride': DriftSqlType.double,
  'screenWidthOverride': DriftSqlType.int,
  'screenHeightOverride': DriftSqlType.int,
  // Process Isolation Settings
  'isolatedProcessEnabled': DriftSqlType.bool,
  'appZygoteProcessEnabled': DriftSqlType.bool,
  // LNA Settings
  // No writer today: nothing calls copyWith for these, so no row for them can
  // exist yet. Listed so that wiring up a writer later cannot silently revert.
  'preferredColorScheme': DriftSqlType.string,
  'cookieBannerHandlingMode': DriftSqlType.string,
  'cookieBannerHandlingModePrivateBrowsing': DriftSqlType.string,
  'cookieBannerHandlingGlobalRules': DriftSqlType.bool,
  'cookieBannerHandlingGlobalRulesSubFrames': DriftSqlType.bool,
};

/// Settings stored as a JSON document in a TEXT column. Their value has to be
/// decoded before it reaches `EngineSettings.fromJson`, which expects the
/// already-parsed list/map.
@visibleForTesting
const engineSettingJsonKeys = <String>{
  'dohExceptionsList',
  'customDohProviders',
};

@Riverpod(keepAlive: true)
class EngineSettingsRepository extends _$EngineSettingsRepository {
  final _partitionKey = 'engine';

  EngineSettings _deserializeSettings(
    List<MapEntry<String, DriftAny?>> entries,
  ) {
    final settings = Map.fromEntries(entries);

    final typeMapping = ref.read(userDatabaseProvider).typeMapping;

    return EngineSettings.fromJson({
      for (final MapEntry(key: key, value: type)
          in engineSettingColumnTypes.entries)
        key: settings[key]?.readAs(type, typeMapping),
      for (final key in engineSettingJsonKeys)
        key: settings[key]
            ?.readAs(DriftSqlType.string, typeMapping)
            .mapNotNull(jsonDecode),
    });
  }

  Future<void> updateSettings(
    UpdateEngineSettingsFunc updateWithCurrent,
  ) async {
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

  Future<EngineSettings> fetchSettings() {
    return ref
        .read(userDatabaseProvider)
        .settingDao
        .getAllSettingsOfPartitionKey(_partitionKey)
        .get()
        .then(_deserializeSettings);
  }

  @override
  Stream<EngineSettings> build() {
    final db = ref.watch(userDatabaseProvider);

    return db.settingDao
        .getAllSettingsOfPartitionKey(_partitionKey)
        .watch()
        .map((entries) {
          return _deserializeSettings(entries);
        });
  }
}

/// Kept alive like its `generalSettingsWithDefaults` counterpart: it is
/// a pure projection of the keep-alive repository, so caching it costs a single
/// derived value and lets keep-alive consumers read it without pinning an
/// auto-disposed provider.
@Riverpod(keepAlive: true)
EngineSettings engineSettingsWithDefaults(Ref ref) {
  return ref.watch(
    engineSettingsRepositoryProvider.select(
      (value) => value.value ?? EngineSettings.withDefaults(),
    ),
  );
}
