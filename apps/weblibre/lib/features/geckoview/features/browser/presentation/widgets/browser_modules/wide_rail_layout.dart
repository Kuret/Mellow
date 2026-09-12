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
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/app_bar_title.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/web_search/domain/controllers/sandbox_capture_controller.dart';

/// The wide vertical rail (PLAN §9 W1), laid out like Arc/Zen: the address
/// field in one upright row at the top, the tab shelves filling the height
/// below it, the toolbar buttons in a row above the space switcher at the
/// foot. Purely structural — every block is handed in — so the settings
/// preview can render the same skeleton around static stand-ins.
class WideRailLayout extends StatelessWidget {
  const WideRailLayout({
    super.key,
    required this.urlRow,
    required this.tabs,
    required this.toolbar,
    required this.spaces,
    this.contextualToolbar,
    this.showUrlRow = true,
    this.showToolbar = true,
    this.backgroundColor,
    this.onHorizontalDragStart,
    this.onHorizontalDragEnd,
    this.onVerticalDragStart,
    this.onVerticalDragEnd,
  });

  static const urlRowKey = Key('wideRailUrlRow');
  static const tabsKey = Key('wideRailTabs');
  static const toolbarKey = Key('wideRailToolbar');
  static const spacesKey = Key('wideRailSpaces');

  /// Block 1: the upright address row.
  final Widget urlRow;

  /// Block 2: the tab shelves. Takes all remaining height.
  final Widget tabs;

  /// Optional contextual toolbar strip, sitting between the shelves and the
  /// main toolbar row.
  final Widget? contextualToolbar;

  /// Block 3: the main toolbar buttons.
  final Widget toolbar;

  /// Block 4: the space switcher.
  final Widget spaces;

  /// Both the address row and the toolbar buttons belong to the main toolbar,
  /// which the home surface suppresses ([BrowserTabBar.suppressMainToolbar]).
  /// They keep their state while hidden, as the horizontal bars do.
  final bool showUrlRow;
  final bool showToolbar;

  final Color? backgroundColor;
  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onHorizontalDragStart: onHorizontalDragStart,
      onHorizontalDragEnd: onHorizontalDragEnd,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragEnd: onVerticalDragEnd,
      child: ColoredBox(
        color: backgroundColor ?? colorScheme.surfaceContainer,
        child: Column(
          children: [
            Visibility(
              visible: showUrlRow,
              maintainState: true,
              child: KeyedSubtree(key: urlRowKey, child: urlRow),
            ),
            Expanded(
              child: KeyedSubtree(key: tabsKey, child: tabs),
            ),
            if (contextualToolbar != null) contextualToolbar!,
            Visibility(
              visible: showToolbar,
              maintainState: true,
              child: KeyedSubtree(key: toolbarKey, child: toolbar),
            ),
            KeyedSubtree(key: spacesKey, child: spaces),
          ],
        ),
      ),
    );
  }
}

/// The address row of the wide rail: the same upright title the horizontal
/// bars use, spanning the rail width. Below [collapseWidth] there is no room
/// for the favicon and the host side by side, so the row collapses to
/// [collapsed] — an icon-only button that opens the same search screen.
class WideRailUrlRow extends StatelessWidget {
  const WideRailUrlRow({super.key, required this.title, this.collapsed});

  /// The upright title ([CompactAppBarTitle] or [AppBarTitle]).
  final Widget title;

  /// Icon-only stand-in for narrow rails. When null the row never collapses.
  final Widget? collapsed;

  /// Same as the horizontal bar row: the title's own site-settings button
  /// carries [kToolbarHeight] of vertical padding.
  static const height = kToolbarHeight;

  /// Rail widths below this collapse the row to [collapsed].
  static const collapseWidth = 168.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final collapsed = this.collapsed;
            if (collapsed != null && constraints.maxWidth < collapseWidth) {
              return Center(child: collapsed);
            }
            return title;
          },
        ),
      ),
    );
  }
}

/// Icon-only address button for a wide rail too narrow to show the host:
/// the selected tab's search screen behind a search glyph.
class WideRailCollapsedUrlButton extends ConsumerWidget {
  const WideRailCollapsedUrlButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(selectedTabStateProvider);
    final selectedTabType = ref.watch(selectedTabTypeProvider);
    final defaultTabType = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.effectiveDefaultCreateTabType,
      ),
    );
    final sandboxSourceUri = tabState == null
        ? null
        : ref.watch(sandboxSourceUriForTabProvider(tabId: tabState.id));

    return IconButton(
      tooltip: 'Search or enter URL',
      icon: const Icon(Icons.search),
      onPressed: () async {
        if (tabState == null) {
          await SearchRoute(
            tabType: selectedTabType ?? defaultTabType,
            searchText: SearchRoute.emptySearchText,
          ).push(context);
          return;
        }
        await SearchRoute(
          tabId: tabState.id,
          searchText: searchTextForTab(tabState, sandboxSourceUri),
          tabType: tabState.tabMode.toTabType(),
        ).push(context);
      },
    );
  }
}

/// The main toolbar buttons of the wide rail in one horizontal row, spread
/// evenly; when they do not fit the rail width they wrap onto a second row
/// rather than scrolling or clipping. Each button sits in a 48dp target.
class WideRailToolbarRow extends StatelessWidget {
  const WideRailToolbarRow({super.key, required this.buttons});

  final List<Widget> buttons;

  static const targetSize = 48.0;

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final button in buttons)
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: targetSize,
                minHeight: targetSize,
              ),
              child: Center(child: button),
            ),
        ],
      ),
    );
  }
}
