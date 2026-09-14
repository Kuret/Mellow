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
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/features/search/domain/providers/search_modules_view.dart';
import 'package:weblibre/features/geckoview/features/search/presentation/widgets/search_modules/search_module_section.dart';
import 'package:weblibre/features/search/domain/providers/search_provider.dart';
import 'package:weblibre/features/search/presentation/widgets/search_provider_chips.dart';

/// Hosts the engine picker inside the standard collapsible/reorderable search
/// module header. The chips scroll horizontally on their own, so this section
/// runs with `showPagination: false` — the header keeps its collapse / reorder
/// affordances but the "Show all N / Show less" button is suppressed.
class SearchProvidersSection extends ConsumerWidget {
  final String? domain;

  const SearchProvidersSection({required this.domain, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchModuleSection(
      title: 'Search Providers',
      moduleType: SearchModuleType.searchProviders,
      totalCount: ref.watch(allSearchProvidersProvider).length,
      showPagination: false,
      contentSliverBuilder:
          ({required bool isCollapsed, required int visibleCount}) => [
            if (!isCollapsed)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                  child: SearchProviderChips(domain: domain),
                ),
              ),
          ],
    );
  }
}
