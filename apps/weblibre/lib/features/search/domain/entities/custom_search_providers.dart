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
import 'package:uuid/uuid.dart';
import 'package:weblibre/features/search/domain/entities/search_provider.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';

/// Prefix on the id of every engine the user defined.
///
/// Built-in ids are bare words (`duckduckgo`, `kagi`), so the namespace keeps
/// the two sets apart for good: no built-in can ever be shadowed by a user
/// entry, and `builtinSearchProviderById` can reject a custom id outright
/// rather than scanning for one it could never hold.
const customSearchProviderIdPrefix = 'custom:';

/// Whether [id] names a user-defined engine rather than a built-in one.
bool isCustomSearchProviderId(String? id) =>
    id != null && id.startsWith(customSearchProviderIdPrefix);

/// A fresh id for an engine the user is adding.
///
/// Minted once, when the engine is created, and never again: the id is what
/// `GeneralSettings.defaultSearchProvider` persists, so editing the engine's
/// name or template must leave the default pointing at it.
String newCustomSearchProviderId() =>
    '$customSearchProviderIdPrefix${const Uuid().v4()}';

/// Stands in for the placeholder while a template is parsed as a URL — `{` and
/// `}` are not legal URL characters, so they cannot survive a round trip. The
/// same trick `search_provider_match.dart` plays.
const _placeholderSentinel = 'weblibresearchtermssentinel';

Uri? _parseTemplate(String urlTemplate) => Uri.tryParse(
  urlTemplate.trim().replaceAll(
    SearchProvider.searchTermsPlaceholder,
    _placeholderSentinel,
  ),
);

/// Why [name] and [urlTemplate] cannot be saved as an engine, phrased for the
/// user, or null when they can.
///
/// Saving a template with no placeholder, or one that is not a web address,
/// would produce an engine that silently fails to search — the user would only
/// find out the next time they typed a query.
String? customSearchEngineError({
  required String name,
  required String urlTemplate,
}) {
  if (name.trim().isEmpty) {
    return 'Give the engine a name.';
  }

  final template = urlTemplate.trim();
  if (template.isEmpty) {
    return "Enter the engine's search URL.";
  }

  final uri = _parseTemplate(template);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty) {
    return 'The search URL must be a full http:// or https:// address.';
  }

  if (!template.contains(SearchProvider.searchTermsPlaceholder)) {
    return 'The search URL needs ${SearchProvider.searchTermsPlaceholder} '
        'where the query goes.';
  }

  return null;
}

/// The host [urlTemplate] searches, which is what represents the engine in
/// pickers and where an empty query lands.
///
/// Derived rather than asked for: a favicon host the user typed could disagree
/// with the engine it decorates, and there is nothing useful to do about that.
/// Empty when the template is not a URL, which validation rules out before an
/// engine can be saved.
String customSearchEngineIconHost(String urlTemplate) =>
    _parseTemplate(urlTemplate)?.host ?? '';

/// The stored [engine] as the browser searches with it.
SearchProvider customSearchProvider(CustomSearchEngine engine) =>
    SearchProvider(
      id: engine.id,
      name: engine.name.trim(),
      urlTemplate: engine.urlTemplate.trim(),
      iconHost: customSearchEngineIconHost(engine.urlTemplate),
    );
