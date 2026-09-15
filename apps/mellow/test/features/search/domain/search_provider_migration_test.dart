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

import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/search/domain/entities/builtin_search_providers.dart';
import 'package:mellow/features/search/domain/entities/custom_search_providers.dart';
import 'package:mellow/features/search/domain/services/search_provider_migration.dart';

void main() {
  group('searchProviderIdFromStoredValue', () {
    test('passes a current provider id straight through', () {
      for (final provider in builtinSearchProviders) {
        expect(searchProviderIdFromStoredValue(provider.id), provider.id);
      }
    });

    test('maps the legacy bang keys onto the engines that replaced them', () {
      const expected = {
        'general::g': 'google',
        'general::google': 'google',
        'general::ddg': 'duckduckgo',
        'general::d': 'duckduckgo',
        'general::b': 'bing',
        'general::bing': 'bing',
        'general::br': 'brave',
        'general::brave': 'brave',
        'general::sp': 'startpage',
        'general::startpage': 'startpage',
        'general::e': 'ecosia',
        'general::ecosia': 'ecosia',
        'kagi::k': 'kagi',
        'kagi::kagi': 'kagi',
        'general::w': 'wikipedia',
        'general::wiki': 'wikipedia',
        'general::wikipedia': 'wikipedia',
      };

      for (final entry in expected.entries) {
        expect(
          searchProviderIdFromStoredValue(entry.key),
          entry.value,
          reason: '${entry.key} should migrate to ${entry.value}',
        );
      }
    });

    test('accepts a bare legacy trigger without its group', () {
      expect(searchProviderIdFromStoredValue('ddg'), 'duckduckgo');
    });

    test('is case-insensitive about the trigger', () {
      expect(searchProviderIdFromStoredValue('general::DDG'), 'duckduckgo');
    });

    test('ignores which bang group the trigger came from', () {
      expect(searchProviderIdFromStoredValue('kagi::g'), 'google');
    });

    test('returns null for a bang we ship no engine for', () {
      expect(searchProviderIdFromStoredValue('general::yt'), isNull);
    });

    test('returns null for nothing stored', () {
      expect(searchProviderIdFromStoredValue(null), isNull);
      expect(searchProviderIdFromStoredValue(''), isNull);
    });

    test('every mapped id names a provider we actually ship', () {
      const legacyKeys = [
        'general::g',
        'general::ddg',
        'general::b',
        'general::br',
        'general::sp',
        'general::e',
        'kagi::k',
        'general::w',
      ];

      for (final key in legacyKeys) {
        expect(
          builtinSearchProviderById(searchProviderIdFromStoredValue(key)),
          isNotNull,
          reason: '$key migrates to an id with no built-in provider',
        );
      }
    });
  });

  group('SearchProviderIdConverter', () {
    const converter = SearchProviderIdConverter();

    test('migrates on read', () {
      expect(converter.fromJson('general::ddg'), 'duckduckgo');
    });

    test('drops an unknown value so the caller can fall back', () {
      expect(converter.fromJson('general::yt'), isNull);
    });

    // This converter has no catalogue of custom engines to check an id
    // against, so it has to take a namespaced id on trust. Dropping it here
    // moved the user silently back to the fallback the next time the setting
    // was read — which is exactly what picking a custom engine as the default
    // used to do.
    test('passes a custom engine id through untouched', () {
      final id = newCustomSearchProviderId();

      expect(converter.fromJson(id), id);
      expect(searchProviderIdFromStoredValue(id), id);
    });

    test('writes the id unchanged', () {
      expect(converter.toJson('google'), 'google');
      expect(converter.toJson(null), isNull);
    });
  });
}
