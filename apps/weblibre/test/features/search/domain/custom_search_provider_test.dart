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
import 'package:weblibre/features/search/domain/entities/builtin_search_providers.dart';
import 'package:weblibre/features/search/domain/entities/custom_search_providers.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';

void main() {
  group('custom engine ids', () {
    test('are namespaced away from the built-in ids', () {
      final id = newCustomSearchProviderId();

      expect(id, startsWith(customSearchProviderIdPrefix));
      expect(isCustomSearchProviderId(id), isTrue);

      for (final provider in builtinSearchProviders) {
        expect(isCustomSearchProviderId(provider.id), isFalse);
        expect(provider.id, isNot(id));
      }
    });

    test('are unique per engine', () {
      expect(newCustomSearchProviderId(), isNot(newCustomSearchProviderId()));
    });

    // The id is what `GeneralSettings.defaultSearchProvider` persists, so an
    // edit that minted a new one would quietly drop the user back to the
    // fallback engine.
    test('survive an edit of the name and the template', () {
      final engine = CustomSearchEngine(
        id: newCustomSearchProviderId(),
        name: 'Searx',
        urlTemplate: 'https://searx.be/search?q={searchTerms}',
      );

      final edited = engine.copyWith
          .name('SearXNG')
          .copyWith
          .urlTemplate('https://searxng.example.com/?q={searchTerms}');

      expect(edited.id, engine.id);
      expect(customSearchProvider(edited).id, engine.id);
    });

    test('are never mistaken for a built-in', () {
      expect(builtinSearchProviderById('custom:duckduckgo'), isNull);
      expect(builtinSearchProviderById(newCustomSearchProviderId()), isNull);
      expect(builtinSearchProviderById('duckduckgo'), isNotNull);
    });
  });

  group('custom engine validation', () {
    test('accepts a well-formed engine', () {
      expect(
        customSearchEngineError(
          name: 'Searx',
          urlTemplate: 'https://searx.be/search?q={searchTerms}',
        ),
        isNull,
      );
    });

    test('rejects an empty name', () {
      expect(
        customSearchEngineError(
          name: '   ',
          urlTemplate: 'https://searx.be/search?q={searchTerms}',
        ),
        contains('name'),
      );
    });

    test('rejects a template without the placeholder', () {
      final error = customSearchEngineError(
        name: 'Searx',
        urlTemplate: 'https://searx.be/search?q=cats',
      );

      expect(error, isNotNull);
      expect(error, contains('{searchTerms}'));
    });

    test('rejects a template that is not an http(s) address', () {
      for (final template in [
        'searx.be/search?q={searchTerms}',
        'ftp://searx.be/search?q={searchTerms}',
        'javascript:alert({searchTerms})',
        'https:///search?q={searchTerms}',
      ]) {
        expect(
          customSearchEngineError(name: 'Searx', urlTemplate: template),
          contains('http'),
          reason: template,
        );
      }
    });
  });

  group('customSearchProvider', () {
    final engine = CustomSearchEngine(
      id: 'custom:test',
      name: '  Searx  ',
      urlTemplate: '  https://searx.be/search?q={searchTerms}  ',
    );

    test('derives the icon host from the template', () {
      expect(customSearchProvider(engine).iconHost, 'searx.be');
      expect(
        customSearchEngineIconHost(
          'https://wiki.example.com/find?query={searchTerms}#top',
        ),
        'wiki.example.com',
      );
    });

    test('trims the name and template it was given', () {
      final provider = customSearchProvider(engine);

      expect(provider.name, 'Searx');
      expect(provider.urlTemplate, 'https://searx.be/search?q={searchTerms}');
    });

    test('substitutes and encodes the query like a built-in does', () {
      final provider = customSearchProvider(engine);

      expect(
        provider.searchUrl('black cats & dogs').toString(),
        'https://searx.be/search?q=black+cats+%26+dogs',
      );
    });

    test('an empty query opens the engine home page', () {
      expect(
        customSearchProvider(engine).searchUrl('').toString(),
        'https://searx.be',
      );
    });
  });
}
