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
import 'package:json_annotation/json_annotation.dart';
import 'package:mellow/features/search/domain/entities/builtin_search_providers.dart';
import 'package:mellow/features/search/domain/entities/custom_search_providers.dart';

/// Bang triggers that named an engine we still ship, mapped to its provider id.
///
/// `defaultSearchProvider` used to hold a `BangKey`, serialized as
/// `group::trigger` (e.g. `general::ddg`). Those rows are still on disk, so the
/// trigger half is translated here rather than being thrown away — otherwise
/// upgrading would silently move the user to a different engine.
const _providerIdByLegacyTrigger = <String, String>{
  'g': 'google',
  'google': 'google',
  'ddg': 'duckduckgo',
  'd': 'duckduckgo',
  'duckduckgo': 'duckduckgo',
  'b': 'bing',
  'bing': 'bing',
  'br': 'brave',
  'brave': 'brave',
  'sp': 'startpage',
  'startpage': 'startpage',
  'e': 'ecosia',
  'ecosia': 'ecosia',
  'k': 'kagi',
  'kagi': 'kagi',
  'w': 'wikipedia',
  'wiki': 'wikipedia',
  'wikipedia': 'wikipedia',
};

/// Reads a stored `defaultSearchProvider` value, in either the current form (a
/// [SearchProvider] id) or the legacy `BangKey` form (`group::trigger`).
///
/// Returns null for anything unrecognised — an obscure bang nobody ships an
/// equivalent for — which leaves the caller on [fallbackSearchProvider] rather
/// than on a browser that cannot search.
String? searchProviderIdFromStoredValue(String? stored) {
  if (stored == null || stored.isEmpty) {
    return null;
  }

  // A user engine's id is ours the moment it is namespaced: this converter has
  // no catalogue of custom engines to check it against, and must not discard an
  // id it cannot see the engine for — doing so silently moved the user back to
  // the fallback the next time the setting was read.
  if (isCustomSearchProviderId(stored) ||
      builtinSearchProviderById(stored) != null) {
    return stored;
  }

  // Legacy `BangKey.toString()` is `group::trigger`; the group no longer means
  // anything to us, only which engine the trigger named.
  final trigger = stored.contains('::') ? stored.split('::').last : stored;

  return _providerIdByLegacyTrigger[trigger.toLowerCase()];
}

/// Reads `defaultSearchProvider` out of the settings store, migrating a legacy
/// `BangKey` string on the way in. Writes are already provider ids.
class SearchProviderIdConverter implements JsonConverter<String?, String?> {
  const SearchProviderIdConverter();

  @override
  String? fromJson(String? json) => searchProviderIdFromStoredValue(json);

  @override
  String? toJson(String? object) => object;
}
