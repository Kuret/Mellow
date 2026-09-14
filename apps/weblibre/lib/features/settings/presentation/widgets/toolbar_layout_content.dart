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
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/settings/presentation/controllers/save_settings.dart';
import 'package:weblibre/features/settings/presentation/widgets/settings_detail.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';
import 'package:weblibre/presentation/hooks/keyed_state.dart';

const List<SettingsSectionDefinition> toolbarLayoutSettingsSections = [
  SettingsSectionDefinition(
    title: 'Side Rail',
    keywords: ['wide screens', 'tablet', 'landscape', 'sidebar'],
    entries: [
      SettingsEntryDefinition(
        title: 'Rail Side',
        subtitle: 'Dock the side rail to the left or right on wide screens',
        keywords: ['left', 'right', 'side', 'vertical', 'rail'],
        child: _RailSideSection(),
      ),
      SettingsEntryDefinition(
        title: 'Rail Width',
        subtitle: 'Width of the side rail on wide screens',
        keywords: ['rail', 'width', 'side', 'vertical', 'sidebar'],
        child: _RailWidthTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Compact Bar',
    keywords: ['narrow screens', 'phone', 'portrait'],
    entries: [
      SettingsEntryDefinition(
        title: 'Tab Bar Position',
        subtitle:
            'Choose whether the compact bar stays at the top or bottom on '
            'narrow screens',
        keywords: ['top', 'bottom'],
        child: _TabBarPositionSection(),
      ),
      SettingsEntryDefinition(
        title: 'Auto Hide Tab Bar',
        subtitle: 'Hide the compact bar when scrolling',
        keywords: ['scroll'],
        child: _AutoHideTabBarTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Contextual Toolbar',
    entries: [
      SettingsEntryDefinition(
        title: 'Show Contextual Toolbar',
        subtitle: 'Show an additional toolbar for navigation and actions',
        keywords: ['bottom toolbar'],
        child: _ShowContextualTabBarTile(),
      ),
      SettingsEntryDefinition(
        title: 'Customize Toolbar Buttons',
        subtitle: 'Choose which actions appear in the contextual toolbar',
        keywords: ['buttons'],
        child: _CustomizeToolbarButtonsTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Tab Chips',
    keywords: ['quick tab switcher', 'switcher'],
    entries: [
      SettingsEntryDefinition(
        title: 'Customize Switcher Buttons',
        subtitle: 'Choose which action buttons appear at the end of the bar',
        keywords: ['buttons', 'new tab', 'actions', 'trailing'],
        child: _CustomizeQuickSwitcherButtonsTile(),
      ),
      SettingsEntryDefinition(
        title: 'Show Titles on Tab Chips',
        subtitle: 'Display page titles on the chips of the compact bar',
        keywords: ['page titles'],
        child: _QuickTabSwitcherShowTitlesTile(),
      ),
      SettingsEntryDefinition(
        title: 'Title Width on Tab Chips',
        subtitle: 'Maximum width of tab titles on chips',
        keywords: ['width', 'title', 'chip', 'length'],
        child: _QuickTabSwitcherTitleWidthTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Tab View',
    entries: [
      SettingsEntryDefinition(
        title: 'Show Favicons in List View',
        subtitle: 'Display site icons in the tab list',
        keywords: ['icons'],
        child: _TabListShowFaviconsTile(),
      ),
    ],
  ),
];

/// The browser menu's own arrangement entry.
///
/// Kept out of [toolbarLayoutSettingsSections] because arranging the menu is
/// a separate concern from the toolbar layout. Offered to the
/// settings screen as [ToolbarLayoutContent.extraSections] so it takes part in
/// the same filtering — a row rendered beside the filtered list would survive a
/// query that empties the list, leaving a match sitting above "No settings
/// match".
const List<SettingsSectionDefinition> menuLayoutSettingsSections = [
  SettingsSectionDefinition(
    title: 'Menu',
    keywords: ['three dot', 'overflow'],
    entries: [
      SettingsEntryDefinition(
        title: 'Customize Menu',
        subtitle:
            'Choose and order the sections and rows of the three-dot menu',
        keywords: ['sections', 'rows', 'reorder'],
        child: _CustomizeMenuTile(),
      ),
    ],
  ),
];

class ToolbarLayoutContent extends StatelessWidget {
  final String query;

  /// Sections shown after the toolbar's own, filtered by the same [query].
  final List<SettingsSectionDefinition> extraSections;

  const ToolbarLayoutContent({
    super.key,
    this.query = '',
    this.extraSections = const [],
  });

  @override
  Widget build(BuildContext context) {
    final filteredSections = filterSettingsSections(
      sections: [...toolbarLayoutSettingsSections, ...extraSections],
      query: query,
    );

    return SettingsSectionList(sections: filteredSections, query: query);
  }
}

class _CustomizeMenuTile extends StatelessWidget {
  const _CustomizeMenuTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('Customize Menu'),
      subtitle: const Text(
        'Choose and order the sections and rows of the three-dot menu',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await const MenuLayoutSettingsRoute().push(context);
      },
    );
  }
}

class _RailSideSection extends HookConsumerWidget {
  const _RailSideSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final railSide = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.railSide),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Rail Side'),
            subtitle: Text(
              'On wide screens the tabs live in a side rail; pick its edge',
            ),
            leading: Icon(MdiIcons.dockLeft),
            contentPadding: EdgeInsets.zero,
          ),
          RadioGroup(
            groupValue: railSide,
            onChanged: (value) async {
              if (value != null) {
                await ref
                    .read(saveZenSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) =>
                          currentSettings.copyWith.railSide(value),
                    );
              }
            },
            child: const Column(
              children: [
                RadioListTile.adaptive(
                  value: RailSide.left,
                  title: Text('Left'),
                ),
                RadioListTile.adaptive(
                  value: RailSide.right,
                  title: Text('Right'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarPositionSection extends HookConsumerWidget {
  const _TabBarPositionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The legacy side values read as bottom here, the way the browser does.
    final tabBarPosition = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.effectiveTabBarPosition,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Tab Bar Position'),
            subtitle: Text(
              'On narrow screens the tabs live in a compact bar; pick its edge',
            ),
            leading: Icon(MdiIcons.dockWindow),
            contentPadding: EdgeInsets.zero,
          ),
          RadioGroup(
            groupValue: tabBarPosition,
            onChanged: (value) async {
              if (value != null) {
                await ref
                    .read(saveGeneralSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) =>
                          currentSettings.copyWith.tabBarPosition(value),
                    );
              }
            },
            child: const Column(
              children: [
                RadioListTile.adaptive(
                  value: TabBarPosition.top,
                  title: Text('Top'),
                  subtitle: Text('Persistent tab bar without auto-hide'),
                ),
                RadioListTile.adaptive(
                  value: TabBarPosition.bottom,
                  title: Text('Bottom'),
                  subtitle: Text('Tab bar with auto-hide support'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowContextualTabBarTile extends HookConsumerWidget {
  const _ShowContextualTabBarTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabBarShowContextualBar = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.tabBarShowContextualBar,
      ),
    );

    return SwitchListTile.adaptive(
      title: const Text('Show Contextual Toolbar'),
      subtitle: const Text(
        'Show additional bottom toolbar for navigation and actions',
      ),
      secondary: const Icon(MdiIcons.dockBottom),
      value: tabBarShowContextualBar,
      onChanged: (value) async {
        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.tabBarShowContextualBar(value),
            );
      },
    );
  }
}

class _CustomizeToolbarButtonsTile extends HookConsumerWidget {
  const _CustomizeToolbarButtonsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabBarShowContextualBar = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.tabBarShowContextualBar,
      ),
    );

    return ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('Customize Toolbar Buttons'),
      trailing: const Icon(Icons.chevron_right),
      enabled: tabBarShowContextualBar,
      onTap: () async {
        await const ContextualToolbarSettingsRoute().push(context);
      },
    );
  }
}

class _CustomizeQuickSwitcherButtonsTile extends StatelessWidget {
  const _CustomizeQuickSwitcherButtonsTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('Customize Switcher Buttons'),
      subtitle: const Text(
        'Action buttons pinned at the end of the compact bar and in the rail '
        'toolbar (independent of the contextual toolbar)',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await const QuickSwitcherToolbarSettingsRoute().push(context);
      },
    );
  }
}

class _QuickTabSwitcherTitleWidthTile extends HookConsumerWidget {
  const _QuickTabSwitcherTitleWidthTile();

  static final _divisions =
      ((maxQuickTabSwitcherTitleWidth - minQuickTabSwitcherTitleWidth) /
              quickTabSwitcherTitleWidthStep)
          .round();

  static String _label(double width) => '${width.round()} px';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleWidth = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.quickTabSwitcherTitleWidth,
      ),
    );
    final showTitles = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.quickTabSwitcherShowTitles,
      ),
    );

    final sliderValue = useKeyedState(titleWidth, [titleWidth]);

    final enabled = showTitles;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text('Title Width on Tab Chips'),
            subtitle: const Text('Maximum width of tab titles on chips'),
            leading: const Icon(MdiIcons.arrowExpandHorizontal),
            contentPadding: EdgeInsets.zero,
            enabled: enabled,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  min: minQuickTabSwitcherTitleWidth,
                  max: maxQuickTabSwitcherTitleWidth,
                  divisions: _divisions,
                  label: _label(sliderValue.value),
                  value: sliderValue.value.clamp(
                    minQuickTabSwitcherTitleWidth,
                    maxQuickTabSwitcherTitleWidth,
                  ),
                  onChanged: enabled
                      ? (value) {
                          sliderValue.value = value;
                        }
                      : null,
                  onChangeEnd: enabled
                      ? (value) async {
                          final normalized =
                              (value / quickTabSwitcherTitleWidthStep).round() *
                              quickTabSwitcherTitleWidthStep;
                          sliderValue.value = normalized;
                          await ref
                              .read(
                                saveGeneralSettingsControllerProvider.notifier,
                              )
                              .save(
                                (currentSettings) => currentSettings.copyWith
                                    .quickTabSwitcherTitleWidth(normalized),
                              );
                        }
                      : null,
                ),
              ),
              Text(
                _label(sliderValue.value),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RailWidthTile extends HookConsumerWidget {
  const _RailWidthTile();

  static final _divisions = ((maxRailWidth - minRailWidth) / railWidthStep)
      .round();

  static String _label(double width) => '${width.round()} px';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = ref.watch(
      zenSettingsWithDefaultsProvider.select(
        (s) => effectiveRailWidth(railWidth: s.railWidth),
      ),
    );

    final sliderValue = useKeyedState(width, [width]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Rail Width'),
            subtitle: Text('Width of the side rail on wide screens'),
            leading: Icon(MdiIcons.arrowExpand),
            contentPadding: EdgeInsets.zero,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  min: minRailWidth,
                  max: maxRailWidth,
                  divisions: _divisions,
                  label: _label(sliderValue.value),
                  value: sliderValue.value.clamp(minRailWidth, maxRailWidth),
                  onChanged: (value) {
                    sliderValue.value = value;
                  },
                  onChangeEnd: (value) async {
                    final normalized =
                        (value / railWidthStep).round() * railWidthStep;
                    sliderValue.value = normalized;
                    await ref
                        .read(saveZenSettingsControllerProvider.notifier)
                        .save(
                          (currentSettings) =>
                              currentSettings.copyWith.railWidth(normalized),
                        );
                  },
                ),
              ),
              Text(
                _label(sliderValue.value),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTabSwitcherShowTitlesTile extends HookConsumerWidget {
  const _QuickTabSwitcherShowTitlesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickTabSwitcherShowTitles = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.quickTabSwitcherShowTitles,
      ),
    );

    return SwitchListTile.adaptive(
      title: const Text('Show Titles on Tab Chips'),
      subtitle: const Text(
        'Display tab titles alongside icons on the chips of the compact bar',
      ),
      secondary: const Icon(MdiIcons.textRecognition),
      value: quickTabSwitcherShowTitles,
      onChanged: (value) async {
        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.quickTabSwitcherShowTitles(value),
            );
      },
    );
  }
}

class _AutoHideTabBarTile extends HookConsumerWidget {
  const _AutoHideTabBarTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoHideTabBar = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.autoHideTabBar),
    );

    return SwitchListTile.adaptive(
      title: const Text('Auto Hide Tab Bar'),
      subtitle: const Text(
        'Hide the compact bar when scrolling; the side rail never hides',
      ),
      secondary: const Icon(MdiIcons.folderHidden),
      value: autoHideTabBar,
      onChanged: (value) async {
        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.autoHideTabBar(value),
            );
      },
    );
  }
}

class _TabListShowFaviconsTile extends HookConsumerWidget {
  const _TabListShowFaviconsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabListShowFavicons = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.tabListShowFavicons),
    );

    return SwitchListTile.adaptive(
      title: const Text('Show Favicons in List View'),
      subtitle: const Text(
        'Display website icons instead of page thumbnails in tab list view',
      ),
      secondary: const Icon(MdiIcons.web),
      value: tabListShowFavicons,
      onChanged: (value) async {
        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.tabListShowFavicons(value),
            );
      },
    );
  }
}
