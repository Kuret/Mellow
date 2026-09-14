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
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/addons/presentation/widgets/pinned_addon_bar.dart';
import 'package:weblibre/features/geckoview/domain/controllers/bottom_sheet.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/sheet.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/data/providers/toolbar_button_configs.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/domain/entities/toolbar_button_id.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/domain/entities/toolbar_config_location.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/presentation/widgets/contextual_bar_buttons.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/presentation/widgets/contextual_toolbar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/toolbar_visibility.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/app_bar_title.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/compact_tab_bar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_layout.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_tab_list.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_icon_rail.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_swipe.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/container_colors.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

export 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/quick_tab_switcher_chip.dart'
    show QuickTabSwitcherItem;

class BrowserTopAppBar extends StatelessWidget {
  final bool showMainToolbar;
  final int quickTabSwitcherRowCount;
  final bool enableGestures;
  final bool suppressMainToolbar;

  late final BrowserTabBar _tabBar;
  late final _size = Size.fromHeight(_tabBar.getToolbarHeight());

  BrowserTopAppBar({
    super.key,
    required this.showMainToolbar,
    required this.quickTabSwitcherRowCount,
    this.enableGestures = true,
    this.suppressMainToolbar = false,
  }) {
    _tabBar = BrowserTabBar(
      showMainToolbar: showMainToolbar,
      displayedSheet: null,
      // The contextual toolbar is always drawn, but always at the bottom: a
      // top bar gets its own BrowserBottomAppBar for it.
      showContextualToolbar: false,
      quickTabSwitcherRowCount: 0,
      enableGestures: enableGestures,
      hideMainToolbarButtonsDuplicatedInContextualToolbar: true,
      suppressMainToolbar: suppressMainToolbar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(height: preferredSize.height, child: _tabBar),
    );
  }

  Size get preferredSize => _size;
}

class BrowserBottomAppBar extends StatelessWidget {
  final bool showMainToolbar;
  final int quickTabSwitcherRowCount;
  final Sheet? displayedSheet;
  final bool enableGestures;
  final bool suppressMainToolbar;

  late final BrowserTabBar _tabBar;
  late final _size = Size.fromHeight(_tabBar.getToolbarHeight());

  BrowserBottomAppBar({
    super.key,
    required this.showMainToolbar,
    required this.displayedSheet,
    required this.quickTabSwitcherRowCount,
    this.enableGestures = true,
    this.suppressMainToolbar = false,
  }) {
    _tabBar = BrowserTabBar(
      displayedSheet: displayedSheet,
      showMainToolbar: showMainToolbar,
      showContextualToolbar: true,
      quickTabSwitcherRowCount: quickTabSwitcherRowCount,
      enableGestures: enableGestures,
      hideMainToolbarButtonsDuplicatedInContextualToolbar: true,
      suppressMainToolbar: suppressMainToolbar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      // Transparent so the navigation-bar inset region behind this padding is
      // filled by the BrowserSystemBars tint strip (matching the active
      // container color), instead of a fixed surfaceContainer fill.
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(height: _size.height, child: _tabBar),
      ),
    );
  }

  Size get preferredSize => _size;
}

/// The wide-viewport side rail, docked to [side]. Exposes a fixed content
/// [preferredSize] width; the caller adds the horizontal safe-area inset on
/// the rail's outer edge to compute the browser content offset.
class BrowserSideRail extends ConsumerWidget {
  final int quickTabSwitcherRowCount;

  /// Which edge the rail is docked to.
  final RailSide side;

  final bool suppressMainToolbar;

  /// Content width for the rail; the caller has already applied
  /// [effectiveRailWidth].
  final double railWidth;

  late final BrowserTabBar _tabBar;
  late final _size = Size.fromWidth(railWidth);

  BrowserSideRail({
    super.key,
    required this.quickTabSwitcherRowCount,
    required this.side,
    required this.railWidth,
    this.suppressMainToolbar = false,
  }) {
    _tabBar = BrowserTabBar(
      displayedSheet: null,
      showMainToolbar: true,
      showContextualToolbar: true,
      quickTabSwitcherRowCount: quickTabSwitcherRowCount,
      enableGestures: true,
      hideMainToolbarButtonsDuplicatedInContextualToolbar: true,
      suppressMainToolbar: suppressMainToolbar,
      railSide: side,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLeft = side == RailSide.left;

    // Tint the outer fill with the active container's surface color (same tint
    // the content and BrowserSystemBars use) so the rail's system safe-area
    // strips (status/nav bar, docked-edge notch) blend with the rail instead
    // of showing a neutral surfaceContainer gap. Falls back to surfaceContainer
    // when no container is active.
    final selectedTabId = ref.watch(selectedTabProvider);
    final showContainerUi = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.showContainerUi),
    );
    final containerColor = ref.watch(
      watchTabContainerDataProvider(
        selectedTabId,
      ).select((data) => data.value?.color.color),
    );
    final effectiveContainerColor = (showContainerUi && containerColor != null)
        ? containerColor
        : null;
    final tintColor = effectiveContainerColor != null
        ? ContainerColors.palette(context, effectiveContainerColor).surfaceColor
        : Theme.of(context).colorScheme.surfaceContainer;

    return ColoredBox(
      color: tintColor,
      child: SafeArea(
        left: isLeft,
        right: !isLeft,
        child: SizedBox(width: _size.width, child: _tabBar),
      ),
    );
  }

  Size get preferredSize => _size;
}

class BrowserTabBar extends HookConsumerWidget {
  final bool showMainToolbar;
  final bool showContextualToolbar;
  final int quickTabSwitcherRowCount;
  final Sheet? displayedSheet;
  final bool hideMainToolbarButtonsDuplicatedInContextualToolbar;
  final bool enableGestures;

  /// Drops the main toolbar row entirely — not just its contents.
  ///
  /// Set on the home surface, where this row has nothing left to say: its
  /// address field is replaced by the home surface's own pinned search pill,
  /// and what sits beside it — the pinned add-ons, the reader button — acts on
  /// a page that is not open. Blanking only the title would strand the add-ons
  /// at the right of an empty strip and still reserve [kToolbarHeight] here.
  ///
  /// The caller resolves this rather than deriving it from
  /// `shouldShowBrowserHomeProvider`, for two reasons: [getToolbarHeight] runs
  /// outside the widget tree (from the wrappers' constructors, to size the bar
  /// before it is built), and the decision also depends on whether a contextual
  /// toolbar exists to take over the tab count and navigation menu — which the
  /// wrappers rewrite before it reaches this widget.
  final bool suppressMainToolbar;

  /// Set when this bar is the wide-viewport side rail, docked to that edge;
  /// null renders the horizontal bar. The browser decides from the viewport
  /// width ([isWideViewport]), not from any setting.
  final RailSide? railSide;

  const BrowserTabBar({
    super.key,
    required this.showMainToolbar,
    required this.displayedSheet,
    required this.showContextualToolbar,
    required this.quickTabSwitcherRowCount,
    required this.enableGestures,
    this.hideMainToolbarButtonsDuplicatedInContextualToolbar = false,
    this.suppressMainToolbar = false,
    this.railSide,
  });

  static const contextualToolabarHeight = 54.0;
  static const quickTabSwitcherHeight = CompactTabBar.height;

  bool get displayAppBar =>
      showMainToolbar &&
      !suppressMainToolbar &&
      (!showContextualToolbar || displayedSheet is! ViewTabsSheet);

  bool get displayQuickTabSwitcher =>
      quickTabSwitcherRowCount > 0 && displayedSheet is! ViewTabsSheet;

  double getToolbarHeight() {
    var height = 0.0;

    if (displayAppBar) {
      height += kToolbarHeight;
    }

    if (showContextualToolbar) {
      height += contextualToolabarHeight;
    }

    if (displayQuickTabSwitcher) {
      height += quickTabSwitcherHeight * quickTabSwitcherRowCount;
    }

    return height;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTabId = ref.watch(selectedTabProvider);
    final settings = ref.watch(generalSettingsWithDefaultsProvider);
    final showRailToolbar = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.showRailToolbar),
    );

    // Determine which buttons are actually visible in the contextual toolbar
    // so we only hide them from the main toolbar when they're genuinely present there.
    final contextualConfigs = ref
        .watch(
          effectiveToolbarButtonConfigsProvider(
            ToolbarConfigLocation.contextual,
          ),
        )
        .value;

    final tabsCountInContextual =
        hideMainToolbarButtonsDuplicatedInContextualToolbar &&
        contextualConfigs.any(
          (c) => c.buttonId == ToolbarButtonId.tabsCount.name && c.isVisible,
        );

    final menuInContextual =
        hideMainToolbarButtonsDuplicatedInContextualToolbar &&
        contextualConfigs.any(
          (c) =>
              c.buttonId == ToolbarButtonId.navigationMenu.name && c.isVisible,
        );

    final showMainToolbarTabsCount = !tabsCountInContextual;
    final showMainToolbarNavigationButton = !menuInContextual;

    final containerColor = ref.watch(
      watchTabContainerDataProvider(
        selectedTabId,
      ).select((data) => data.value?.color.color),
    );

    final railSide = this.railSide;
    final tabBarPosition = settings.effectiveTabBarPosition;

    final dragStartPosition = useRef(Offset.zero);

    void dismissToolbar() {
      if (ref.read(bottomSheetControllerProvider) == null) {
        unawaited(HapticFeedback.lightImpact());
        ref
            .read(toolbarVisibilityControllerProvider(selectedTabId).notifier)
            .dismiss();
      }
    }

    // Counterpart of dismissToolbar: swiping the bar *inward* (away from the
    // edge it is docked to) opens the tab view, the same surface the tab count
    // button opens — so the dismiss axis reads as one continuous control,
    // pushing the bar off screen in one direction and pulling the tab view out
    // of it in the other.
    void showTabView() {
      if (ref.read(bottomSheetControllerProvider) != null) return;

      unawaited(HapticFeedback.lightImpact());

      unawaited(const TabViewRoute().push(context));
    }

    final showTabTitle = displayedSheet is! ViewTabsSheet;

    final effectiveContainerColor =
        (settings.showContainerUi &&
            containerColor != null &&
            displayedSheet is! ViewTabsSheet)
        ? containerColor
        : null;
    final effectiveContainerPalette = effectiveContainerColor != null
        ? ContainerColors.palette(context, effectiveContainerColor)
        : null;

    void dragStartHandler(DragStartDetails details) {
      dragStartPosition.value = details.globalPosition;
    }

    const dismissThreshold = kToolbarHeight * 0.5;

    // Rail: a horizontal swipe outside the tab list dismisses toward the
    // docked edge, and the opposite (inward) swipe opens the tab view. Over
    // the tab list itself the swipe switches spaces instead (the list's own
    // SpaceSwipeDetector wins the arena there).
    void railHorizontalDragEndHandler(DragEndDetails details) {
      // distance = start - end, so a leftward swipe is positive dx.
      final distance = dragStartPosition.value - details.globalPosition;
      final shouldDismiss = switch (railSide!) {
        RailSide.left => distance.dx > dismissThreshold,
        RailSide.right => distance.dx < -dismissThreshold,
      };
      final shouldShowTabView = switch (railSide) {
        RailSide.left => distance.dx < -dismissThreshold,
        RailSide.right => distance.dx > dismissThreshold,
      };
      if (shouldDismiss) {
        dismissToolbar();
      } else if (shouldShowTabView) {
        showTabView();
      }
    }

    // Horizontal bar: the dismiss direction depends on the edge; the
    // opposite (inward) swipe opens the tab view:
    // - Bottom bar: swipe down to dismiss, swipe up for the tab view
    // - Top bar: swipe up to dismiss, swipe down for the tab view
    void barVerticalDragEndHandler(DragEndDetails details) {
      final distance = dragStartPosition.value - details.globalPosition;
      final shouldDismiss = switch (tabBarPosition) {
        TabBarPosition.bottom =>
          distance.dy.isNegative && distance.dy.abs() > dismissThreshold,
        _ => !distance.dy.isNegative && distance.dy.abs() > dismissThreshold,
      };
      final shouldShowTabView = switch (tabBarPosition) {
        TabBarPosition.bottom =>
          !distance.dy.isNegative && distance.dy.abs() > dismissThreshold,
        _ => distance.dy.isNegative && distance.dy.abs() > dismissThreshold,
      };
      if (shouldDismiss) {
        dismissToolbar();
      } else if (shouldShowTabView) {
        showTabView();
      }
    }

    final actions = <Widget>[
      const PinnedAddonBar(),
      if (showMainToolbarTabsCount)
        TabsCountButton(
          selectedTabId: selectedTabId,
          displayedSheet: displayedSheet,
          showLongPressMenu: true,
        ),
      if (showMainToolbarNavigationButton)
        NavigationMenuButton(selectedTabId: selectedTabId),
    ];

    if (railSide != null) {
      // The rail is the Arc/Zen sidebar (PLAN §9 W1): address row on top,
      // the selected space's shelves filling the height, the toolbar buttons
      // above the space switcher at the foot.
      final uprightTitle = CompactAppBarTitle(
        containerColor: effectiveContainerColor,
      );
      return WideRailLayout(
        backgroundColor: effectiveContainerPalette?.surfaceColor,
        showUrlRow: displayAppBar && showTabTitle,
        // Scoped to the wide rail only: the narrow compact bar always shows
        // its toolbar row, since the "+" long-press menu that replaces it
        // for the rail only exists there.
        showToolbar: displayAppBar && showRailToolbar,
        urlRow: WideRailUrlRow(
          title: uprightTitle,
          collapsed: const WideRailCollapsedUrlButton(),
        ),
        tabs: const _RailSpaceTabs(),
        contextualToolbar: showContextualToolbar
            ? ContextualToolbar(
                selectedTabId: selectedTabId,
                displayedSheet: displayedSheet,
              )
            : null,
        toolbar: WideRailToolbarRow(
          buttons: [
            // The add-on bar is a rigid row of however many add-ons the tab
            // pinned; in the rail's share of one row it has to scroll rather
            // than overflow.
            for (final action in actions)
              if (action is PinnedAddonBar)
                const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: PinnedAddonBar(),
                )
              else
                action,
          ],
        ),
        spaces: const SpaceIconRail(),
        onHorizontalDragStart: enableGestures ? dragStartHandler : null,
        onHorizontalDragEnd: enableGestures
            ? railHorizontalDragEndHandler
            : null,
      );
    }

    return BrowserTabBarView(
      showMainToolbar: showMainToolbar,
      showContextualToolbar: showContextualToolbar,
      showQuickTabSwitcherBar: quickTabSwitcherRowCount > 0,
      displayAppBar: displayAppBar,
      displayQuickTabSwitcher: displayQuickTabSwitcher,
      backgroundColor: effectiveContainerPalette?.surfaceColor,
      title: showTabTitle
          ? CompactAppBarTitle(containerColor: effectiveContainerColor)
          : null,
      actions: actions,
      quickTabSwitcher: const CompactTabBar(),
      contextualToolbar: ContextualToolbar(
        selectedTabId: selectedTabId,
        displayedSheet: displayedSheet,
      ),
      onVerticalDragStart: enableGestures ? dragStartHandler : null,
      onVerticalDragEnd: enableGestures ? barVerticalDragEndHandler : null,
    );
  }
}

/// The rail's shelves: a horizontal swipe anywhere on the list steps to the
/// neighbouring space, and the list slides over with it.
class _RailSpaceTabs extends ConsumerWidget {
  const _RailSpaceTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceUuid = ref.watch(selectedSpaceProvider);
    return SpaceSwipeDetector(
      child: SpaceSlide(
        spaceUuid: spaceUuid,
        child: WideRailTabList(spaceUuid: spaceUuid),
      ),
    );
  }
}

/// The horizontal bar's structure: the quick tab switcher row, the main
/// toolbar row (address field and actions) and the contextual strip stacked
/// in that order. Purely structural, so the settings preview renders the
/// same skeleton around static stand-ins.
class BrowserTabBarView extends StatelessWidget {
  const BrowserTabBarView({
    super.key,
    required this.showMainToolbar,
    required this.showContextualToolbar,
    required this.showQuickTabSwitcherBar,
    required this.displayAppBar,
    required this.displayQuickTabSwitcher,
    required this.backgroundColor,
    required this.title,
    required this.actions,
    required this.quickTabSwitcher,
    required this.contextualToolbar,
    this.onVerticalDragStart,
    this.onVerticalDragEnd,
  });

  final bool showMainToolbar;
  final bool showContextualToolbar;
  final bool showQuickTabSwitcherBar;
  final bool displayAppBar;
  final bool displayQuickTabSwitcher;
  final Color? backgroundColor;
  final Widget? title;
  final List<Widget> actions;
  final Widget quickTabSwitcher;
  final Widget contextualToolbar;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.surfaceContainer;

    return GestureDetector(
      // Tap handling moved to AppBarTitle for split icon/title behavior. No
      // horizontal handler here: the chip strip scrolls horizontally, so a
      // drag over it belongs to the strip. The address row below it takes
      // the space swipe instead (see its SpaceSwipeDetector).
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragEnd: onVerticalDragEnd,
      child: ColoredBox(
        color: effectiveBackgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showQuickTabSwitcherBar)
              Visibility(
                visible: displayQuickTabSwitcher,
                maintainState: true,
                child: quickTabSwitcher,
              ),
            if (showMainToolbar)
              Visibility(
                visible: displayAppBar,
                maintainState: true,
                // The address row is the strip's full-width neighbour and
                // never scrolls sideways itself, so it can carry the space
                // swipe: reaching the end of a long chip strip to overscroll
                // is not a gesture anyone would find.
                child: SpaceSwipeDetector(
                  child: AppBar(
                    primary: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    titleSpacing: 0.0,
                    leadingWidth: 40.0,
                    toolbarHeight: kToolbarHeight,
                    title: title,
                    actions: actions,
                  ),
                ),
              ),
            if (showContextualToolbar) contextualToolbar,
          ],
        ),
      ),
    );
  }
}
