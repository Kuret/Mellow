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
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/features/search/domain/entities/builtin_search_providers.dart';
import 'package:weblibre/features/search/domain/entities/custom_search_providers.dart';
import 'package:weblibre/features/search/domain/entities/search_provider.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

part 'search_provider.g.dart';

/// The engines the user defined, as the browser searches with them.
///
/// Derived rather than stored: `ZenSettings` keeps the name and the template,
/// and everything else about an engine — its icon host above all — follows from
/// those.
@Riverpod(keepAlive: true)
List<SearchProvider> customSearchProviders(Ref ref) {
  final engines = ref
      .watch(zenSettingsWithDefaultsProvider)
      .customSearchProviders;

  return engines.map(customSearchProvider).toList(growable: false);
}

/// Every engine there is, in the order pickers show them: the built-ins first,
/// then the user's own.
///
/// Custom engines come last so the list a user has been reading for months does
/// not reshuffle the moment they add one of their own.
@Riverpod(keepAlive: true)
List<SearchProvider> allSearchProviders(Ref ref) => [
  ...builtinSearchProviders,
  ...ref.watch(customSearchProvidersProvider),
];

/// The engine with [id], built-in or user-defined, or null when nothing carries
/// that id any more — a custom engine the user has since deleted, say.
@riverpod
SearchProvider? searchProviderById(Ref ref, String? id) =>
    findSearchProvider(ref.watch(allSearchProvidersProvider), id);

/// The engine typed queries go to unless something nearer overrides it.
///
/// Never null: an id naming no engine we still have — a deleted custom one, or
/// a setting from a build that shipped a different catalogue — lands on
/// [fallbackSearchProvider], so deleting the engine that was the default leaves
/// the browser searchable rather than broken.
@Riverpod(keepAlive: true)
SearchProvider defaultSearchProvider(Ref ref) {
  final id = ref.watch(
    generalSettingsWithDefaultsProvider.select(
      (settings) => settings.defaultSearchProvider,
    ),
  );

  return findSearchProvider(ref.watch(allSearchProvidersProvider), id) ??
      fallbackSearchProvider;
}
