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
import 'package:flutter/foundation.dart';

/// The engine an address-bar query is sent to.
///
/// A provider is a URL template and a name; there is deliberately no database
/// behind it. The built-in set lives in `builtin_search_providers.dart` and is
/// the whole catalogue, so lookups are a list scan over a handful of entries.
@immutable
class SearchProvider {
  /// Stable identifier. It is what [GeneralSettings.defaultSearchProvider]
  /// persists, so an id is never renamed or reused for a different engine.
  final String id;

  /// Name shown in pickers and settings.
  final String name;

  /// Search URL with [searchTermsPlaceholder] standing in for the query, e.g.
  /// `https://duckduckgo.com/?q={searchTerms}`.
  final String urlTemplate;

  /// Autocomplete endpoint in the same template form, when the engine has one.
  ///
  /// Nothing consumes this yet — suggestions come from
  /// `features/search/domain/autosuggest/` — but it belongs with the engine
  /// rather than in a second parallel table.
  final String? suggestionsTemplate;

  /// Host whose favicon represents the provider, and the page opened when a
  /// provider is chosen without a query.
  final String iconHost;

  const SearchProvider({
    required this.id,
    required this.name,
    required this.urlTemplate,
    required this.iconHost,
    this.suggestionsTemplate,
  });

  /// The token [urlTemplate] and [suggestionsTemplate] substitute.
  static const searchTermsPlaceholder = '{searchTerms}';

  /// The engine's home page — used as the favicon source and as the
  /// destination when the user picks a provider with an empty query.
  Uri get homeUrl => Uri.https(iconHost);

  /// Builds the URL that searches for [searchTerms].
  ///
  /// Terms are URL-encoded as a query component (space becomes `+`), matching
  /// what every engine in the built-in list expects. An empty query yields the
  /// engine's [homeUrl] rather than a search for nothing.
  Uri searchUrl(String searchTerms) {
    if (searchTerms.isEmpty) {
      return homeUrl;
    }

    return Uri.parse(_substitute(urlTemplate, searchTerms));
  }

  /// Builds the autocomplete URL for [searchTerms], or null when the engine
  /// has no [suggestionsTemplate].
  Uri? suggestionsUrl(String searchTerms) {
    final template = suggestionsTemplate;
    if (template == null || searchTerms.isEmpty) {
      return null;
    }

    return Uri.parse(_substitute(template, searchTerms));
  }

  static String _substitute(String template, String searchTerms) =>
      template.replaceAll(
        searchTermsPlaceholder,
        Uri.encodeQueryComponent(searchTerms),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SearchProvider && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SearchProvider($id)';
}
