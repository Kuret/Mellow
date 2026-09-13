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
import 'package:weblibre/features/search/domain/entities/search_provider.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

part 'search_provider.g.dart';

/// The engine typed queries go to unless something nearer overrides it.
///
/// Never null: an unrecognised stored id lands on [fallbackSearchProvider], so
/// every caller can search without a null check.
@Riverpod(keepAlive: true)
SearchProvider defaultSearchProvider(Ref ref) {
  final id = ref.watch(
    generalSettingsWithDefaultsProvider.select(
      (settings) => settings.defaultSearchProvider,
    ),
  );

  return builtinSearchProviderById(id) ?? fallbackSearchProvider;
}
