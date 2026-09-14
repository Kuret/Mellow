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
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/security.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/presentation/widgets/contextual_bar_buttons.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/presentation/widgets/contextual_toolbar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/providers/site_settings_badge_provider.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/app_bar_title.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/bottom_app_bar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/compact_tab_bar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/quick_tab_switcher_chip.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_layout.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_tab_list.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/navigation_buttons.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tabs_action_button.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_icon_rail.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_indicator.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/container_colors.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';

/// Pinned header showing both layouts the browser picks from by viewport
/// width: the compact bar of narrow screens and the side rail of wide ones.
/// [compact] puts the two side by side (the settings screens pin this header,
/// so it has to stay short); otherwise they stack inside a card.
class TabBarPreviewHeaderDelegate extends SliverPersistentHeaderDelegate {
  const TabBarPreviewHeaderDelegate({
    required this.settings,
    required this.zenSettings,
    this.backgroundColor,
    this.compact = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0),
  });

  final GeneralSettings settings;
  final ZenSettings zenSettings;
  final Color? backgroundColor;
  final bool compact;
  final EdgeInsets padding;

  double get _contentHeight => compact
      ? TabBarPreviewCard.compactHeight(settings)
      : TabBarPreviewCard.stackedHeight(settings);

  @override
  double get minExtent => _contentHeight + padding.vertical;

  @override
  double get maxExtent => _contentHeight + padding.vertical;

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
        child: TabBarPreviewCard(
          settings: settings,
          zenSettings: zenSettings,
          compact: compact,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant TabBarPreviewHeaderDelegate oldDelegate) {
    return oldDelegate.settings != settings ||
        oldDelegate.zenSettings != zenSettings ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.compact != compact;
  }
}

class TabBarPreviewCard extends StatelessWidget {
  const TabBarPreviewCard({
    super.key,
    required this.settings,
    required this.zenSettings,
    this.compact = false,
  });

  final GeneralSettings settings;
  final ZenSettings zenSettings;
  final bool compact;

  static const wideScreensLabel = 'Wide screens';
  static const narrowScreensLabel = 'Narrow screens';

  static const _kLabelHeight = 20.0;
  static const _kPageContentHeight = 72.0;
  static const _kCompactPageContentHeight = 40.0;
  static const _kHeaderHeight = 72.0;
  static const _kGap = 8.0;

  /// The wide preview is drawn at this logical size and scaled to fit, so
  /// the rail keeps its configured proportion to the page whatever the
  /// settings screen's own width.
  static const _kWideCanvasWidth = 640.0;
  static const _kWideCanvasHeight = 300.0;

  /// The compact bar's chrome: the address row, one switcher row and, when
  /// on, the contextual strip.
  static double toolbarHeight(GeneralSettings settings) =>
      kToolbarHeight +
      BrowserTabBar.quickTabSwitcherHeight +
      BrowserTabBar.contextualToolabarHeight;

  /// Height of the narrow-screen preview box (content plus its border).
  static double narrowPreviewHeight(
    GeneralSettings settings, {
    required bool compact,
  }) =>
      (compact ? _kCompactPageContentHeight : _kPageContentHeight) +
      toolbarHeight(settings) +
      2;

  /// Both previews side by side under their labels.
  static double compactHeight(GeneralSettings settings) =>
      _kLabelHeight + narrowPreviewHeight(settings, compact: true);

  /// The card: header, then the two previews stacked under their labels.
  static double stackedHeight(GeneralSettings settings) =>
      _kHeaderHeight +
      _kLabelHeight +
      narrowPreviewHeight(settings, compact: false) +
      _kGap +
      _kLabelHeight +
      _kWideCanvasHeight +
      8.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final previewTabState = TabState.$default('preview-tab').copyWith(
      url: Uri.parse('https://weblibre.eu/docs'),
      title: 'WebLibre Preview',
      securityInfoState: SecurityState(
        secure: true,
        host: 'weblibre.eu',
        issuer: 'WebLibre',
      ),
    );

    final previewContainerPalette = settings.showContainerUi
        ? ContainerColors.palette(context, colorScheme.primary)
        : null;
    final chromeColor =
        previewContainerPalette?.surfaceColor ?? colorScheme.surfaceContainer;

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

    Widget buildContextualToolbar() {
      return ContextualToolbarView(
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
    ];

    Widget title() => _CompactPreviewTitle(tabState: previewTabState);

    Widget pageContent({double? height}) => Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: compact
            ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.7)
            : colorScheme.surfaceContainerLowest,
        border: Border.symmetric(
          horizontal: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Text('Page Content', style: textTheme.labelMedium),
    );

    BoxDecoration frame() => BoxDecoration(
      color: compact
          ? colorScheme.surface.withValues(alpha: 0.7)
          : colorScheme.surface,
      border: Border.all(color: colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(4),
    );

    // --- Narrow screens: the compact bar at the configured edge. ---------

    final compactBar = _CompactBarPreview(settings: settings);
    final position = settings.effectiveTabBarPosition;
    final pageHeight = compact
        ? _kCompactPageContentHeight
        : _kPageContentHeight;

    final Widget narrowPreview;
    if (position == TabBarPosition.top) {
      narrowPreview = Column(
        children: [
          BrowserTabBarView(
            showMainToolbar: true,
            showContextualToolbar: false,
            showQuickTabSwitcherBar: false,
            displayAppBar: true,
            displayQuickTabSwitcher: false,
            backgroundColor: chromeColor,
            title: title(),
            actions: mainToolbarActions,
            quickTabSwitcher: const SizedBox.shrink(),
            contextualToolbar: const SizedBox.shrink(),
          ),
          pageContent(height: pageHeight),
          BrowserTabBarView(
            showMainToolbar: false,
            showContextualToolbar: true,
            showQuickTabSwitcherBar: true,
            displayAppBar: false,
            displayQuickTabSwitcher: true,
            backgroundColor: colorScheme.surfaceContainer,
            title: null,
            actions: const [],
            quickTabSwitcher: compactBar,
            contextualToolbar: buildContextualToolbar(),
          ),
        ],
      );
    } else {
      narrowPreview = Column(
        children: [
          pageContent(height: pageHeight),
          BrowserTabBarView(
            showMainToolbar: true,
            showContextualToolbar: true,
            showQuickTabSwitcherBar: true,
            displayAppBar: true,
            displayQuickTabSwitcher: true,
            backgroundColor: chromeColor,
            title: title(),
            actions: mainToolbarActions,
            quickTabSwitcher: compactBar,
            contextualToolbar: buildContextualToolbar(),
          ),
        ],
      );
    }
    final narrowBox = Container(
      clipBehavior: Clip.antiAlias,
      decoration: frame(),
      child: narrowPreview,
    );

    // --- Wide screens: the rail on the configured side. -------------------

    final railWidth = effectiveRailWidth(railWidth: zenSettings.railWidth);
    const closeMode = TabChipCloseButtonMode.activeTabOnly;
    final rail = SizedBox(
      width: railWidth,
      child: WideRailLayout(
        backgroundColor: chromeColor,
        urlRow: WideRailUrlRow(
          title: title(),
          collapsed: const Icon(Icons.search),
        ),
        tabs: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          children: [
            WideRailTabRowView(
              icon: const Icon(MdiIcons.web, size: WideRailTabRowView.iconSize),
              title: 'News',
              isActive: true,
              onTap: () {},
              onClose: closeMode.showsFor(isActive: true) ? () {} : null,
            ),
            WideRailTabRowView(
              icon: const Icon(MdiIcons.web, size: WideRailTabRowView.iconSize),
              title: 'Docs',
              isActive: false,
              depth: 1,
              onTap: () {},
              onClose: closeMode.showsFor(isActive: false) ? () {} : null,
            ),
          ],
        ),
        contextualToolbar: buildContextualToolbar(),
        toolbar: WideRailToolbarRow(buttons: mainToolbarActions),
        spaces: const SpaceIconRailView(
          entries: [
            SpaceIconRailEntry(
              id: 'work',
              icon: null,
              name: 'Work',
              selected: true,
            ),
            SpaceIconRailEntry(
              id: 'personal',
              icon: null,
              name: 'Personal',
              selected: false,
            ),
          ],
        ),
      ),
    );
    final wideCanvas = Container(
      width: _kWideCanvasWidth,
      height: _kWideCanvasHeight,
      clipBehavior: Clip.antiAlias,
      decoration: frame(),
      child: Row(
        children: zenSettings.railSide == RailSide.left
            ? [rail, Expanded(child: pageContent())]
            : [Expanded(child: pageContent()), rail],
      ),
    );
    final wideBox = FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: wideCanvas,
    );

    Widget label(String text) => SizedBox(
      height: _kLabelHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );

    if (compact) {
      final previewHeight = narrowPreviewHeight(settings, compact: true);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label(narrowScreensLabel),
                SizedBox(height: previewHeight, child: narrowBox),
              ],
            ),
          ),
          const SizedBox(width: _kGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label(wideScreensLabel),
                SizedBox(height: previewHeight, child: wideBox),
              ],
            ),
          ),
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: _kHeaderHeight,
              child: ListTile(
                title: Text('Live Preview'),
                subtitle: Text(
                  'Reflects your current toolbar and layout settings',
                ),
                leading: Icon(MdiIcons.televisionGuide),
                contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
            ),
            label(narrowScreensLabel),
            narrowBox,
            const SizedBox(height: _kGap),
            label(wideScreensLabel),
            SizedBox(height: _kWideCanvasHeight, child: wideBox),
          ],
        ),
      ),
    );
  }
}

/// Static stand-in for [CompactTabBar]: the space indicator, two Essentials
/// squares, the divider, a folder chip and two tab chips. The live bar needs
/// the tab and space tables, which the preview does not have.
class _CompactBarPreview extends StatelessWidget {
  const _CompactBarPreview({required this.settings});

  final GeneralSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <QuickTabSwitcherItem>[
      QuickTabSwitcherItem(
        id: 'regular-preview-tab',
        isActive: true,
        title: 'News',
        tabMode: TabMode.regular,
        isHistory: false,
        isPinned: false,
        url: Uri.parse('https://example.com/news'),
        color: settings.showContainerUi ? scheme.primary : null,
        avatar: const Icon(MdiIcons.web, size: 20),
      ),
      QuickTabSwitcherItem(
        id: 'private-preview-tab',
        isActive: false,
        title: 'Private',
        tabMode: TabMode.private,
        isHistory: false,
        isPinned: false,
        url: Uri.parse('https://example.com/private'),
        color: null,
        avatar: const Icon(MdiIcons.web, size: 20),
      ),
    ];
    final decoration = buildQuickTabSwitcherChipDecoration(
      context,
      showTitles: settings.quickTabSwitcherShowTitles,
    );

    Widget essential() => Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Center(
        child: Container(
          width: compactEssentialSize,
          height: compactEssentialSize,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(MdiIcons.web, size: 16),
        ),
      ),
    );

    return SizedBox(
      height: CompactTabBar.height,
      child: Row(
        children: [
          const SpaceIndicatorView(
            icon: null,
            name: 'Work',
            index: 0,
            count: 2,
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              children: [
                essential(),
                essential(),
                const Padding(
                  padding: EdgeInsets.only(left: 2.0, right: 6.0),
                  child: VerticalDivider(width: 1, indent: 12, endIndent: 12),
                ),
                const Center(
                  child: CompactFolderChip(
                    name: 'Reading',
                    childCount: 3,
                    expanded: false,
                  ),
                ),
                for (final item in items)
                  Center(
                    child: QuickTabSwitcherChip(
                      item: item,
                      isSelected: item.isActive,
                      selectedBorderColor: scheme.primary,
                      decoration: decoration,
                      label: buildQuickTabSwitcherChipLabel(
                        context,
                        item,
                        isSelected: item.isActive,
                        showTitles: settings.quickTabSwitcherShowTitles,
                        titleMaxWidth: settings.quickTabSwitcherTitleWidth,
                      ),
                      padding: const EdgeInsets.only(right: 8.0),
                      onTap: () async {},
                      onDelete:
                          TabChipCloseButtonMode.activeTabOnly.showsFor(
                            isActive: item.isActive,
                          )
                          ? () async {}
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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
    );
  }
}

void _noop() {}
