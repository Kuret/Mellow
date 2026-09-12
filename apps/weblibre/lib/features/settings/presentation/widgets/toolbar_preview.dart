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
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/security.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/presentation/widgets/contextual_bar_buttons.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/presentation/widgets/contextual_toolbar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/providers/site_settings_badge_provider.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/app_bar_title.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/bottom_app_bar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/navigation_buttons.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tabs_action_button.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/container_colors.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';

class TabBarPreviewHeaderDelegate extends SliverPersistentHeaderDelegate {
  const TabBarPreviewHeaderDelegate({
    required this.settings,
    this.backgroundColor,
    this.compact = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0),
  });

  static const _kPreviewBaseHeight = 90.0;
  static const _kCompactPreviewBaseHeight = 42.0;
  static const _kHeaderHeight = 72.0;

  final GeneralSettings settings;
  final Color? backgroundColor;
  final bool compact;
  final EdgeInsets padding;

  double get _toolbarHeight {
    var height = kToolbarHeight;

    if (settings.tabBarShowContextualBar) {
      height += BrowserTabBar.contextualToolabarHeight;
    }

    final quickTabSwitcherRows = switch (settings
        .effectiveTabBarStackingMode()) {
      TabBarStackingMode.disabled => 0,
      TabBarStackingMode.twoLevel => 2,
      TabBarStackingMode.spaceTabs when !settings.tabBarPosition.isVertical =>
        2,
      _ => 1,
    };

    return height + BrowserTabBar.quickTabSwitcherHeight * quickTabSwitcherRows;
  }

  double get _baseHeight =>
      compact ? _kCompactPreviewBaseHeight : _kPreviewBaseHeight;

  double get _headerHeight => compact ? 0.0 : _kHeaderHeight;

  /// Fixed preview height for the vertical rail (the rail flows along the
  /// height, so it can't be derived from stacked section heights).
  static const _kRailPreviewHeight = 220.0;
  static const _kCompactRailPreviewHeight = 140.0;

  double get _contentHeight => settings.tabBarPosition.isVertical
      ? (compact ? _kCompactRailPreviewHeight : _kRailPreviewHeight)
      : _baseHeight + _toolbarHeight;

  @override
  double get minExtent => _contentHeight + _headerHeight + padding.vertical;

  @override
  double get maxExtent => _contentHeight + _headerHeight + padding.vertical;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: padding,
        child: TabBarPreviewCard(settings: settings, compact: compact),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant TabBarPreviewHeaderDelegate oldDelegate) {
    return oldDelegate.settings != settings ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.compact != compact;
  }
}

class TabBarPreviewCard extends HookWidget {
  const TabBarPreviewCard({
    super.key,
    required this.settings,
    this.compact = false,
  });

  final GeneralSettings settings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final quickTabsController = useScrollController();
    final quickTabsSecondRowController = useScrollController();
    final showMainToolbarActionButtons = !settings.tabBarShowContextualBar;

    final previewTabState = TabState.$default('preview-tab').copyWith(
      url: Uri.parse('https://weblibre.eu/docs'),
      title: 'WebLibre Preview',
      securityInfoState: SecurityState(
        secure: true,
        host: 'weblibre.eu',
        issuer: 'WebLibre',
      ),
    );

    final previewQuickItems = <QuickTabSwitcherItem>[
      QuickTabSwitcherItem(
        id: 'regular-preview-tab',
        isActive: true,
        title: 'News',
        tabMode: TabMode.regular,
        isHistory: false,
        isPinned:
            settings.effectiveTabBarStackingMode() ==
            TabBarStackingMode.containerTabs,
        url: Uri.parse('https://example.com/news'),
        color: settings.showContainerUi ? colorScheme.primary : null,
        avatar: const Icon(MdiIcons.web, size: 20),
      ),
      QuickTabSwitcherItem(
        id: 'private-preview-tab',
        isActive: false,
        title: 'Private',
        tabMode: TabMode.private,
        isHistory: false,
        isPinned: false,
        depth: 1,
        url: Uri.parse('https://example.com/private'),
        color: null,
        avatar: const Icon(MdiIcons.web, size: 20),
      ),
      if (settings.quickTabSwitcherShowHistorySuggestions)
        QuickTabSwitcherItem(
          id: 'history-preview-tab',
          isActive: false,
          title: 'Search',
          tabMode: TabMode.regular,
          isHistory: true,
          isPinned: false,
          url: Uri.parse('https://search.example.com'),
          color: null,
          avatar: const Icon(MdiIcons.web, size: 20),
        ),
    ];
    final previewContainerPalette = settings.showContainerUi
        ? ContainerColors.palette(context, colorScheme.primary)
        : null;

    final tabCountButton = TabsCountButtonView(
      isActive: false,
      onTap: () {},
      onLongPress: () {},
      buttonBuilder: (isActive, onTap, onLongPress) {
        return TabsActionButtonView(
          isActive: isActive,
          tabCountText: '5',
          onTap: onTap,
          onLongPress: onLongPress,
        );
      },
    );

    Widget buildQuickTabSwitcherRow(
      ScrollController scrollController, {
      Axis axis = Axis.horizontal,
    }) {
      // Mirrors isWideRail, but ignores the viewport breakpoint: this preview
      // shows what the configured railWidth looks like regardless of the
      // settings screen's own current width.
      final wideRail =
          settings.tabBarPosition.isVertical &&
          settings.railWidth >= minWideRailWidth;
      final showTitles =
          (axis != Axis.vertical || wideRail) &&
          settings.quickTabSwitcherShowTitles;
      final titleMaxWidth = wideRail && axis == Axis.vertical
          ? settings.quickTabSwitcherTitleWidth.clamp(
              0.0,
              (settings.railWidth - railChipChromeWidth).clamp(
                0.0,
                double.infinity,
              ),
            )
          : settings.quickTabSwitcherTitleWidth;
      return QuickTabSwitcherView(
        availableItems: previewQuickItems,
        activeItem: previewQuickItems.firstWhere((item) => item.isActive),
        scrollController: scrollController,
        axis: axis,
        showTitles: showTitles,
        hierarchyGlyphs: settings.quickTabSwitcherHierarchyGlyphs,
        titleMaxWidth: titleMaxWidth,
        closeButtonMode: settings.quickTabSwitcherCloseButtonMode,
        enablePinTabInMenu: false,
        onSelected: (_) async {},
        onCloseItem: (_) async {},
      );
    }

    // Static stand-in for the space chip row of [TabBarStackingMode.spaceTabs]:
    // the live row needs the space table, which the preview does not have.
    Widget buildSpaceChipsRow({Axis axis = Axis.horizontal}) {
      final chips = [
        for (final (name, selected) in const [
          ('Work', true),
          ('Personal', false),
        ])
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: ChoiceChip(
              avatar: const Icon(MdiIcons.viewDashboardOutline, size: 18),
              label: Text(name),
              selected: selected,
              onSelected: (_) {},
            ),
          ),
      ];
      return SizedBox(
        height: axis == Axis.vertical
            ? null
            : BrowserTabBar.quickTabSwitcherHeight,
        width: axis == Axis.vertical
            ? BrowserTabBar.quickTabSwitcherHeight
            : null,
        child: SingleChildScrollView(
          scrollDirection: axis,
          child: axis == Axis.vertical
              ? Column(mainAxisSize: MainAxisSize.min, children: chips)
              : Row(mainAxisSize: MainAxisSize.min, children: chips),
        ),
      );
    }

    Widget buildQuickTabSwitcher({Axis axis = Axis.horizontal}) {
      // The accordion preview reuses the single-row layout; container header
      // chips need live container data that the static preview doesn't have.
      final mode = settings.effectiveTabBarStackingMode();
      if (mode == TabBarStackingMode.spaceTabs) {
        final tabs = buildQuickTabSwitcherRow(quickTabsController, axis: axis);
        return axis == Axis.vertical
            ? Column(
                children: [
                  buildSpaceChipsRow(axis: axis),
                  Expanded(child: tabs),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [buildSpaceChipsRow(), tabs],
              );
      }
      if (mode == TabBarStackingMode.twoLevel) {
        final rows = [
          buildQuickTabSwitcherRow(quickTabsController, axis: axis),
          buildQuickTabSwitcherRow(quickTabsSecondRowController, axis: axis),
        ];
        return axis == Axis.vertical
            ? Column(children: [for (final row in rows) Expanded(child: row)])
            : Column(mainAxisSize: MainAxisSize.min, children: rows);
      }
      return buildQuickTabSwitcherRow(quickTabsController, axis: axis);
    }

    Widget buildContextualToolbar({Axis axis = Axis.horizontal}) {
      return ContextualToolbarView(
        axis: axis,
        buttons: [
          NavigateBackButtonView(
            canGoBack: true,
            isLoading: false,
            onPressed: () {},
            onLongPress: () {},
          ),
          NavigateForwardButtonView(
            canGoForward: true,
            onPressed: () {},
            onLongPress: () {},
          ),
          AddTabButtonView(onPressed: () {}, onLongPress: () {}),
          tabCountButton,
          NavigationMenuButtonView(onTap: () {}),
        ],
      );
    }

    final mainToolbarActions = <Widget>[
      if (showMainToolbarActionButtons) tabCountButton,
      if (showMainToolbarActionButtons) NavigationMenuButtonView(onTap: () {}),
    ];

    final showQuickTabSwitcherBar =
        settings.effectiveTabBarStackingMode() != TabBarStackingMode.disabled;

    final bottomCombinedToolbar = BrowserTabBarView(
      showMainToolbar: true,
      showContextualToolbar: settings.tabBarShowContextualBar,
      showQuickTabSwitcherBar: showQuickTabSwitcherBar,
      displayAppBar: true,
      displayQuickTabSwitcher: true,
      backgroundColor:
          previewContainerPalette?.surfaceColor ?? colorScheme.surfaceContainer,
      title: settings.tabBarLayout == TabBarLayout.compact
          ? _CompactPreviewTitle(tabState: previewTabState)
          : _RegularPreviewTitle(tabState: previewTabState),
      actions: mainToolbarActions,
      quickTabSwitcher: buildQuickTabSwitcher(),
      contextualToolbar: buildContextualToolbar(),
    );

    final topMainToolbar = BrowserTabBarView(
      showMainToolbar: true,
      showContextualToolbar: false,
      showQuickTabSwitcherBar: false,
      displayAppBar: true,
      displayQuickTabSwitcher: false,
      backgroundColor:
          previewContainerPalette?.surfaceColor ?? colorScheme.surfaceContainer,
      title: settings.tabBarLayout == TabBarLayout.compact
          ? _CompactPreviewTitle(tabState: previewTabState)
          : _RegularPreviewTitle(tabState: previewTabState),
      actions: mainToolbarActions,
      quickTabSwitcher: const SizedBox.shrink(),
      contextualToolbar: const SizedBox.shrink(),
    );

    final topBottomToolbar = BrowserTabBarView(
      showMainToolbar: false,
      showContextualToolbar: settings.tabBarShowContextualBar,
      showQuickTabSwitcherBar: showQuickTabSwitcherBar,
      displayAppBar: false,
      displayQuickTabSwitcher: true,
      backgroundColor: colorScheme.surfaceContainer,
      title: null,
      actions: const [],
      quickTabSwitcher: buildQuickTabSwitcher(),
      contextualToolbar: buildContextualToolbar(),
    );

    final isRailPreview = settings.tabBarPosition.isVertical;
    final isWideRailPreview =
        isRailPreview && settings.railWidth >= minWideRailWidth;

    final railToolbar = BrowserTabBarView(
      axis: Axis.vertical,
      railOnLeft: settings.tabBarPosition == TabBarPosition.left,
      showMainToolbar: true,
      showContextualToolbar: settings.tabBarShowContextualBar,
      showQuickTabSwitcherBar: showQuickTabSwitcherBar,
      displayAppBar: true,
      displayQuickTabSwitcher: true,
      backgroundColor:
          previewContainerPalette?.surfaceColor ?? colorScheme.surfaceContainer,
      title: isWideRailPreview
          ? ConstrainedBox(
              constraints: BoxConstraints(maxWidth: settings.railWidth),
              child: settings.tabBarLayout == TabBarLayout.compact
                  ? _CompactPreviewTitle(tabState: previewTabState)
                  : _RegularPreviewTitle(tabState: previewTabState),
            )
          : _RailPreviewTitle(
              tabState: previewTabState,
              quarterTurns: settings.tabBarPosition == TabBarPosition.left
                  ? 3
                  : 1,
            ),
      actions: mainToolbarActions,
      quickTabSwitcher: buildQuickTabSwitcher(axis: Axis.vertical),
      contextualToolbar: buildContextualToolbar(axis: Axis.vertical),
    );

    final pageContentBox = Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: compact
            ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.7)
            : colorScheme.surfaceContainerLowest,
        border: Border.symmetric(
          horizontal: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Text(
        'Page Content',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );

    final Widget previewContent;
    if (isRailPreview) {
      final rail = SizedBox(width: settings.railWidth, child: railToolbar);
      final railOnLeft = settings.tabBarPosition == TabBarPosition.left;
      previewContent = Container(
        clipBehavior: Clip.antiAlias,
        height: compact ? 140 : 220,
        decoration: BoxDecoration(
          color: compact
              ? colorScheme.surface.withValues(alpha: 0.7)
              : colorScheme.surface,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: railOnLeft
              ? [rail, Expanded(child: pageContentBox)]
              : [Expanded(child: pageContentBox), rail],
        ),
      );
    } else {
      previewContent = Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: compact
              ? colorScheme.surface.withValues(alpha: 0.7)
              : colorScheme.surface,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            if (settings.tabBarPosition == TabBarPosition.top) topMainToolbar,
            SizedBox(height: compact ? 40 : 72, child: pageContentBox),
            if (settings.tabBarPosition == TabBarPosition.top)
              topBottomToolbar
            else
              bottomCombinedToolbar,
          ],
        ),
      );
    }

    if (compact) {
      return previewContent;
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              title: Text('Live Preview'),
              subtitle: Text(
                'Reflects your current toolbar and layout settings',
              ),
              leading: Icon(MdiIcons.televisionGuide),
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
            previewContent,
          ],
        ),
      ),
    );
  }
}

class _RegularPreviewTitle extends StatelessWidget {
  const _RegularPreviewTitle({required this.tabState});

  final TabState tabState;

  @override
  Widget build(BuildContext context) {
    return AppBarTitleView(
      tabState: tabState,
      isTabTunneled: false,
      siteSettingsBadgeState: SiteSettingsBadgeState.hidden,
      onSiteSettingsTap: _noop,
      onTitleTap: _noop,
      tabIcon: const Icon(MdiIcons.web, size: 24),
      longPressUrlCopy: false,
    );
  }
}

class _CompactPreviewTitle extends StatelessWidget {
  const _CompactPreviewTitle({required this.tabState});

  final TabState tabState;

  @override
  Widget build(BuildContext context) {
    return CompactAppBarTitleView(
      tabState: tabState,
      isTabTunneled: false,
      siteSettingsBadgeState: SiteSettingsBadgeState.hidden,
      onSiteSettingsTap: _noop,
      onTitleTap: _noop,
      tabIcon: const Icon(MdiIcons.web, size: 24),
    );
  }
}

class _RailPreviewTitle extends StatelessWidget {
  const _RailPreviewTitle({required this.tabState, required this.quarterTurns});

  final TabState tabState;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    return RailAppBarTitleView(
      tabState: tabState,
      quarterTurns: quarterTurns,
      isTabTunneled: false,
      siteSettingsBadgeState: SiteSettingsBadgeState.hidden,
      onSiteSettingsTap: _noop,
      onTitleTap: _noop,
      tabIcon: const Icon(MdiIcons.web, size: 24),
      longPressUrlCopy: false,
    );
  }
}

void _noop() {}
