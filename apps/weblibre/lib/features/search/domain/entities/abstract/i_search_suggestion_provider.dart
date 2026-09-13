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
import 'package:exceptions/exceptions.dart';
import 'package:nullability/nullability.dart';

enum SearchSuggestionProviders {
  none('Disabled', null),
  brave('Brave', 'search.brave.com'),
  ddg('DuckDuckGo', 'duckduckgo.com'),
  kagi('Kagi', 'kagi.com'),
  qwant('Qwant', 'www.qwant.com');

  final String label;

  /// Host whose favicon stands for the service in pickers. The autocomplete
  /// endpoint itself is hardcoded by each implementation under
  /// `features/search/domain/autosuggest/`, so this is presentation only.
  final String? iconHost;

  const SearchSuggestionProviders(this.label, this.iconHost);

  /// Page the favicon is fetched from, or null for [none].
  Uri? get iconUrl => iconHost.mapNotNull(Uri.https);
}

abstract interface class ISearchSuggestionProvider {
  Future<Result<List<String>>> getSuggestions(String query);
}
