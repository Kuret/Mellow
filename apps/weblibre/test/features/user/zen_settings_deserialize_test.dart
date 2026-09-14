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
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

void main() {
  group('ZenSettings deserialization coverage', () {
    // The failure this guards against is silent: a field added to ZenSettings
    // without a matching read in the deserializer saves to the database
    // correctly and then reverts to its default on the next launch, because
    // nothing ever reads it back out. Two of these fields are the sync
    // client's incremental bookkeeping, so a silent revert there costs a full
    // re-fetch of the collection.
    test('every serialized field is read back by the deserializer', () {
      final serializedKeys = ZenSettings.withDefaults().toJson().keys.toSet();
      final readKeys = {...zenSettingColumnTypes.keys, ...zenSettingJsonKeys};

      expect(
        serializedKeys.difference(readKeys),
        isEmpty,
        reason:
            'These ZenSettings fields are written but never read back. '
            'Add each one to zenSettingColumnTypes (with its DriftSqlType) '
            'or, for JSON documents, to zenSettingJsonKeys.',
      );
    });

    test('the read keys carry nothing the model does not write', () {
      final serializedKeys = ZenSettings.withDefaults().toJson().keys.toSet();
      final readKeys = {...zenSettingColumnTypes.keys, ...zenSettingJsonKeys};

      expect(readKeys.difference(serializedKeys), isEmpty);
    });

    test('a key is never both a plain column and a JSON document', () {
      expect(
        zenSettingColumnTypes.keys.toSet().intersection(zenSettingJsonKeys),
        isEmpty,
      );
    });

    test('column types are limited to the kinds the setting table stores', () {
      const supported = {
        DriftSqlType.string,
        DriftSqlType.bool,
        DriftSqlType.int,
        DriftSqlType.double,
      };

      for (final MapEntry(key: key, value: type)
          in zenSettingColumnTypes.entries) {
        expect(supported, contains(type), reason: '$key has type $type');
      }
    });

    test('round-trips a fully populated document', () {
      final settings = ZenSettings.withDefaults(
        spacesSyncEnabled: false,
        spacesSyncWritesEnabled: false,
        spacesSyncLastSyncId: 'sync-id',
        spacesSyncLastModified: 1234.56,
        spacesSyncBaselineDone: true,
        spacesSyncApplierVersion: 7,
        spacesSyncMaxTombstoneFraction: 0.5,
        spacesSyncMaxTombstoneCount: 11,
        railSide: RailSide.right,
        railWidth: 200,
        maxLiveTabs: 42,
        separateEssentials: false,
        customSearchProviders: [
          CustomSearchEngine(
            id: 'custom:1cb2',
            name: 'Searx',
            urlTemplate: 'https://searx.be/search?q={searchTerms}',
          ),
          CustomSearchEngine(
            id: 'custom:9fa4',
            name: 'Internal wiki',
            urlTemplate: 'https://wiki.example.com/find?query={searchTerms}',
          ),
        ],
      );

      expect(ZenSettings.fromJson(settings.toJson()), settings);
    });

    // The custom engine list reaches the database as a JSON string, so it makes
    // the same trip the deserializer makes: encode on the way in, decode before
    // `fromJson` ever sees it.
    test('custom engines survive the encode/decode the setting row makes', () {
      final settings = ZenSettings.withDefaults(
        customSearchProviders: [
          CustomSearchEngine(
            id: 'custom:1cb2',
            name: 'Searx',
            urlTemplate: 'https://searx.be/search?q={searchTerms}',
          ),
        ],
      );

      final json = settings.toJson();
      final encoded = jsonEncode(json['customSearchProviders']);

      final restored = ZenSettings.fromJson({
        ...json,
        'customSearchProviders': jsonDecode(encoded),
      });

      expect(restored.customSearchProviders, settings.customSearchProviders);
      expect(restored, settings);
    });
  });
}
