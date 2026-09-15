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
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/user/data/models/engine_settings.dart';
import 'package:weblibre/features/user/domain/repositories/engine_settings.dart';

void main() {
  // EngineSettings.withDefaults() reads platform values off the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EngineSettings deserialization coverage', () {
    // The failure this guards against is silent: a field added to
    // EngineSettings without a matching read in the deserializer saves to the
    // database correctly and then reverts to its default on the next launch,
    // because nothing ever reads it back out.
    test('every serialized field is read back by the deserializer', () {
      final serializedKeys = EngineSettings.withDefaults()
          .toJson()
          .keys
          .toSet();
      final readKeys = {
        ...engineSettingColumnTypes.keys,
        ...engineSettingJsonKeys,
      };

      expect(
        serializedKeys.difference(readKeys),
        isEmpty,
        reason:
            'These EngineSettings fields are written but never read back. '
            'Add each one to engineSettingColumnTypes (with its DriftSqlType) '
            'or, for JSON documents, to engineSettingJsonKeys.',
      );
    });

    test('a key is never both a plain column and a JSON document', () {
      expect(
        engineSettingColumnTypes.keys.toSet().intersection(
          engineSettingJsonKeys,
        ),
        isEmpty,
      );
    });

    test('JSON-backed settings are absent from the plain column types', () {
      // They are read as strings and decoded, so listing them in the column map
      // as well would hand fromJson the raw encoded string.
      for (final key in engineSettingJsonKeys) {
        expect(engineSettingColumnTypes.containsKey(key), isFalse);
      }
    });

    test('column types are limited to the kinds the setting table stores', () {
      const supported = {
        DriftSqlType.string,
        DriftSqlType.bool,
        DriftSqlType.int,
        DriftSqlType.double,
      };

      for (final MapEntry(key: key, value: type)
          in engineSettingColumnTypes.entries) {
        expect(supported, contains(type), reason: '$key has type $type');
      }
    });
  });
}
