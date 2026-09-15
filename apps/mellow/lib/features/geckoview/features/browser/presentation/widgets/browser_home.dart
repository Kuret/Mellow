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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/domain/entities/tab_container_selection.dart';
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/browser/domain/providers.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/providers/browser_viewport_toolbar_insets.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/home/home_search_pill.dart';
import 'package:mellow/features/geckoview/features/search/domain/providers/search_section_display.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/empty_state/recent_searches_section.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/search_section_scope.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:mellow/features/geckoview/features/tabs/utils/container_colors.dart';
import 'package:mellow/features/search/domain/entities/search_provider.dart';
import 'package:mellow/features/search/domain/providers/search_provider.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/domain/presentation/widgets/active_profile_chip.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/presentation/widgets/browser_page.dart';
import 'package:mellow/presentation/widgets/sliver_center_on_underflow.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// The home surface creates tabs of the user's configured default type; the
/// child type is meaningless here because there is no tab to be a child of.
class BrowserHome extends HookConsumerWidget {
  const BrowserHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recent searches fill a text field, and this surface owns none — its
    // search entry is a pill that pushes the search screen. The chips get a
    // controller of their own so the long-press-to-fill affordance still has
    // somewhere to write, and a tap goes straight to a new tab.
    final searchTextController = useTextEditingController();

    Future<void> submitSearch(String query) async {
      final SearchProvider provider =
          ref.read(selectedSearchProviderProvider()) ??
          ref.read(defaultSearchProviderProvider);
      final container = ref.read(selectedContainerDataProvider).value;

      await ref
          .read(tabRepositoryProvider.notifier)
          .addTab(
            url: provider.searchUrl(query),
            tabMode: TabMode.regular,
            selectTab: true,
            containerSelection: container == null
                ? const TabContainerSelection.unassigned()
                : TabContainerSelection.specific(container),
          );
    }

    return BrowserPage(
      child: SafeArea(
        bottom: false,
        child: RepaintBoundary(
          child: SearchSectionScope(
            host: SearchSectionHost.home,
            // Unpinned: on the BrowserPage aura gradient an opaque band per
            // header would cut a slab across the backdrop.
            pinnedHeaderBackgroundColor: null,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverCenterOnUnderflow(
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      const SliverToBoxAdapter(child: _HomeHeader()),
                      const _HomeSearchPillSliver(),
                      RecentSearchesSection(
                        searchTextController: searchTextController,
                        submitSearch: submitSearch,
                      ),
                      const _HomeBottomInsetSpacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSearchPillSliver extends ConsumerWidget {
  const _HomeSearchPillSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placement = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (settings) => settings.effectiveHomeSearchBarPlacement(),
      ),
    );

    if (placement == HomeSearchBarPlacement.tabBar) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return const SliverPinnedHeader(child: HomeSearchPill());
  }
}

/// Brand mark, or the selected container's identity when there is one.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final container = ref.watch(
      selectedContainerDataProvider.select((value) => value.value),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          if (container != null)
            _ContainerHeader(container: container)
          else
            BrandHeader(colorScheme: theme.colorScheme),
          if (container != null) ...[
            const SizedBox(height: 12),
            Text(
              container.name.isNotEmpty ? container.name : 'Container',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          // Which profile this is, unmistakably (PLAN §7.5).
          const SizedBox(height: 12),
          const ActiveProfileChip(),
        ],
      ),
    );
  }
}

/// Trailing space so the last module clears the bottom app bar.
///
/// A spacer rather than a [SliverPadding] around the list: the inset animates
/// with the toolbar, and padding would relayout every module on each frame.
/// Owning the watch here also keeps those frames off the module list entirely.
class _HomeBottomInsetSpacer extends ConsumerWidget {
  const _HomeBottomInsetSpacer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insetPx = ref.watch(
      browserViewportToolbarInsetsControllerProvider.select(
        (state) => state.effectiveBottomInsetPx,
      ),
    );
    final inset = insetPx / MediaQuery.devicePixelRatioOf(context);

    return SliverToBoxAdapter(child: SizedBox(height: 24 + inset));
  }
}

class _ContainerHeader extends StatelessWidget {
  final ContainerData container;

  const _ContainerHeader({required this.container});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final containerColor =
        container.color.color ?? colorScheme.onSurfaceVariant;
    final containerPalette = ContainerColors.palette(context, containerColor);

    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            containerPalette.surfaceHighColor,
            containerPalette.surfaceColor,
          ],
        ),
        border: Border.all(color: containerPalette.outlineColor),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      // See [BrandHeader]: the mark needs room inside the tile, and 60 in a
      // 96 tile with 18 of padding leaves it none.
      child: Center(
        child: SvgPicture.asset('assets/icon/icon.svg', width: 48, height: 48),
      ),
    );
  }
}
