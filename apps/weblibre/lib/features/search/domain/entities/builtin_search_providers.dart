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
import 'package:weblibre/features/search/domain/entities/search_provider.dart';

/// Every engine the browser can search with, in the order pickers show them.
const builtinSearchProviders = <SearchProvider>[
  SearchProvider(
    id: 'duckduckgo',
    name: 'DuckDuckGo',
    urlTemplate: 'https://duckduckgo.com/?q={searchTerms}',
    suggestionsTemplate: 'https://duckduckgo.com/ac/?q={searchTerms}',
    iconHost: 'duckduckgo.com',
  ),
  SearchProvider(
    id: 'google',
    name: 'Google',
    urlTemplate: 'https://www.google.com/search?q={searchTerms}',
    iconHost: 'www.google.com',
  ),
  SearchProvider(
    id: 'bing',
    name: 'Bing',
    urlTemplate: 'https://www.bing.com/search?q={searchTerms}',
    iconHost: 'www.bing.com',
  ),
  SearchProvider(
    id: 'brave',
    name: 'Brave',
    urlTemplate: 'https://search.brave.com/search?q={searchTerms}',
    suggestionsTemplate: 'https://search.brave.com/api/suggest?q={searchTerms}',
    iconHost: 'search.brave.com',
  ),
  SearchProvider(
    id: 'startpage',
    name: 'Startpage',
    urlTemplate: 'https://www.startpage.com/sp/search?query={searchTerms}',
    iconHost: 'www.startpage.com',
  ),
  SearchProvider(
    id: 'ecosia',
    name: 'Ecosia',
    urlTemplate: 'https://www.ecosia.org/search?q={searchTerms}',
    iconHost: 'www.ecosia.org',
  ),
  SearchProvider(
    id: 'kagi',
    name: 'Kagi',
    urlTemplate: 'https://kagi.com/search?q={searchTerms}',
    suggestionsTemplate: 'https://kagi.com/api/autosuggest?q={searchTerms}',
    iconHost: 'kagi.com',
  ),
  SearchProvider(
    id: 'wikipedia',
    name: 'Wikipedia',
    urlTemplate: 'https://en.wikipedia.org/w/index.php?search={searchTerms}',
    iconHost: 'en.wikipedia.org',
  ),
];

/// The engine used when the stored setting names nothing we recognise.
///
/// Wikipedia, because that is the default this fork inherited — a user who
/// never touched the setting keeps the engine they have been searching with.
const fallbackSearchProvider = SearchProvider(
  id: 'wikipedia',
  name: 'Wikipedia',
  urlTemplate: 'https://en.wikipedia.org/w/index.php?search={searchTerms}',
  iconHost: 'en.wikipedia.org',
);

/// The built-in provider with [id], or null if there is none.
SearchProvider? builtinSearchProviderById(String? id) {
  if (id == null) {
    return null;
  }

  for (final provider in builtinSearchProviders) {
    if (provider.id == id) {
      return provider;
    }
  }

  return null;
}
