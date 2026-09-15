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
import 'package:mellow/features/search/domain/entities/search_provider.dart';
import 'package:mellow/features/search/domain/services/search_provider_match.dart';

const _testProvider = SearchProvider(
  id: 'test',
  name: 'Test',
  urlTemplate: 'https://example.org/search?q={searchTerms}&hl=en',
  suggestionsTemplate: 'https://example.org/ac?q={searchTerms}',
  iconHost: 'example.org',
);

void main() {
  group('SearchProvider.searchUrl', () {
    test('substitutes the query into the template', () {
      expect(
        _testProvider.searchUrl('cats').toString(),
        'https://example.org/search?q=cats&hl=en',
      );
    });

    test('encodes spaces as plus', () {
      expect(_testProvider.searchUrl('two words').query, 'q=two+words&hl=en');
    });

    test('percent-encodes characters that would otherwise break the URL', () {
      final url = _testProvider.searchUrl('a&b=c #d/e?f');

      // The terms must survive as one parameter value, not split the query.
      expect(url.queryParameters['q'], 'a&b=c #d/e?f');
      expect(url.queryParameters['hl'], 'en');
    });

    test('leaves non-ASCII intact through a round trip', () {
      final url = _testProvider.searchUrl('östliche größe');

      expect(url.queryParameters['q'], 'östliche größe');
    });

    test('an empty query opens the engine home page', () {
      expect(_testProvider.searchUrl('').toString(), 'https://example.org');
    });
  });

  group('SearchProvider.suggestionsUrl', () {
    test('substitutes the query when the engine has a template', () {
      expect(
        _testProvider.suggestionsUrl('cats').toString(),
        'https://example.org/ac?q=cats',
      );
    });

    test('is null without a template', () {
      const noSuggestions = SearchProvider(
        id: 'none',
        name: 'None',
        urlTemplate: 'https://example.org/?q={searchTerms}',
        iconHost: 'example.org',
      );

      expect(noSuggestions.suggestionsUrl('cats'), isNull);
    });

    test('is null for an empty query', () {
      expect(_testProvider.suggestionsUrl(''), isNull);
    });
  });

  group('builtinSearchProviders', () {
    test('every provider has a unique id', () {
      final ids = builtinSearchProviders.map((p) => p.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every provider substitutes its terms', () {
      for (final provider in builtinSearchProviders) {
        expect(
          provider.urlTemplate,
          contains(SearchProvider.searchTermsPlaceholder),
          reason: '${provider.id} has no placeholder',
        );
        expect(
          provider.searchUrl('cats').toString(),
          isNot(contains(SearchProvider.searchTermsPlaceholder)),
          reason: '${provider.id} left its placeholder in the URL',
        );
      }
    });

    test('the fallback is one of the built-ins', () {
      expect(builtinSearchProviderById(fallbackSearchProvider.id), isNotNull);
    });

    test('lookup by id misses cleanly', () {
      expect(builtinSearchProviderById('nope'), isNull);
      expect(builtinSearchProviderById(null), isNull);
    });
  });

  group('matchSearchUrl', () {
    test('recovers the query from a results page', () {
      final match = matchSearchUrl(
        Uri.parse('https://duckduckgo.com/?q=two+words'),
      );

      expect(match?.provider.id, 'duckduckgo');
      expect(match?.searchTerms, 'two words');
    });

    test('round-trips every built-in provider', () {
      for (final provider in builtinSearchProviders) {
        final match = matchSearchUrl(provider.searchUrl('two words'));

        expect(match?.provider.id, provider.id);
        expect(match?.searchTerms, 'two words');
      }
    });

    test('ignores a non-search page on a provider host', () {
      expect(matchSearchUrl(Uri.parse('https://duckduckgo.com/about')), isNull);
    });

    test('ignores an unrelated host', () {
      expect(matchSearchUrl(Uri.parse('https://example.org/?q=cats')), isNull);
    });

    test('ignores a results URL with an empty query', () {
      expect(matchSearchUrl(Uri.parse('https://duckduckgo.com/?q=')), isNull);
    });
  });
}
