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
import 'package:weblibre/features/search/domain/entities/builtin_search_providers.dart';
import 'package:weblibre/features/search/domain/entities/search_provider.dart';

/// A search results page recognised as one of our providers.
typedef SearchProviderMatch = ({SearchProvider provider, String searchTerms});

/// Stands in for the placeholder while the template is parsed as a URL — `{`
/// and `}` are not legal URL characters, so they cannot survive a round trip.
const _placeholderSentinel = 'weblibresearchtermssentinel';

/// Recognises [url] as a search on one of [providers] and recovers the query
/// that produced it.
///
/// This is what lets the address bar open on `cats` rather than on
/// `https://duckduckgo.com/?q=cats` when the user edits a results page. The
/// caller passes the catalogue so an engine the user defined is recognised on
/// the same terms as a built-in; [builtinSearchProviders] is the default for
/// the callers that have no `Ref` to read it from.
SearchProviderMatch? matchSearchUrl(
  Uri url, {
  Iterable<SearchProvider> providers = builtinSearchProviders,
}) {
  for (final provider in providers) {
    final searchTerms = _searchTermsOf(provider, url);
    if (searchTerms != null) {
      return (provider: provider, searchTerms: searchTerms);
    }
  }

  return null;
}

String? _searchTermsOf(SearchProvider provider, Uri url) {
  final template = Uri.parse(
    provider.urlTemplate.replaceAll(
      SearchProvider.searchTermsPlaceholder,
      _placeholderSentinel,
    ),
  );

  if (template.host.toLowerCase() != url.host.toLowerCase() ||
      template.path != url.path) {
    return null;
  }

  for (final parameter in template.queryParameters.entries) {
    if (parameter.value != _placeholderSentinel) {
      continue;
    }

    final searchTerms = url.queryParameters[parameter.key];

    return (searchTerms == null || searchTerms.isEmpty) ? null : searchTerms;
  }

  return null;
}
