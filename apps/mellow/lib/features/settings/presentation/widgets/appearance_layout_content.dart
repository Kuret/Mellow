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
import 'package:mellow/core/design/app_theme.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/settings/presentation/controllers/save_settings.dart';
import 'package:mellow/features/settings/presentation/widgets/settings_detail.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/zen_settings.dart';
import 'package:mellow/presentation/hooks/keyed_state.dart';

const List<SettingsSectionDefinition> appearanceLayoutSettingsSections = [
  SettingsSectionDefinition(
    title: 'Theme',
    keywords: ['appearance', 'colors'],
    entries: [
      SettingsEntryDefinition(
        title: 'Theme',
        subtitle: 'Choose system, light, or dark mode',
        keywords: ['light', 'dark', 'theme mode'],
        child: _ThemeSection(),
      ),
      SettingsEntryDefinition(
        title: 'Pure Black (OLED)',
        subtitle:
            'Use true-black surfaces in dark mode to save power on OLED '
            'screens',
        keywords: ['oled', 'amoled', 'high contrast', 'black', 'dark'],
        child: _PureBlackTile(),
      ),
      SettingsEntryDefinition(
        title: 'Accent Color',
        subtitle: 'The highlight color used for toggles and selections',
        keywords: [
          'accent',
          'color',
          'colour',
          'highlight',
          'primary',
          'theme',
        ],
        child: _AccentColorTile(),
      ),
    ],
  ),
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
      SettingsEntryDefinition(
        title: 'Swipe to Move the Rail',
        subtitle:
            'A back swipe from the edge opposite the rail moves it there; '
            "a swipe from the rail's own edge still goes back",
        keywords: ['rail', 'move', 'swipe', 'back gesture', 'side', 'vertical'],
        child: _SwipeToMoveRailTile(),
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
      SettingsEntryDefinition(
        title: 'Space Switcher Side',
        subtitle: 'Which side of the tab chips the space switcher sits on',
        keywords: [
          'space',
          'switcher',
          'indicator',
          'side',
          'left',
          'right',
          'handed',
          'compact bar',
        ],
        child: _SpaceIndicatorSideSection(),
      ),
      SettingsEntryDefinition(
        title: 'Slide-out Tab Rail',
        subtitle:
            'On narrow screens, replace the bar with a tab rail that slides '
            'in on a back swipe from this edge (or, on Either side, from '
            'whichever edge the swipe comes from); a back swipe from the '
            'other edge still goes back',
        keywords: [
          'rail',
          'drawer',
          'slide',
          'tabs',
          'sidebar',
          'left',
          'right',
          'back gesture',
          'compact bar',
        ],
        child: _CompactRailSideSection(),
      ),
      SettingsEntryDefinition(
        title: 'Title Width on Compact Bar Chips',
        subtitle:
            'Maximum width of a tab title on the compact bar, so a narrower '
            'screen fits more chips; the side rail always uses its full width',
        keywords: [
          'width',
          'title',
          'chip',
          'length',
          'compact bar',
          'tab chips',
          'quick tab switcher',
          'switcher',
        ],
        child: _QuickTabSwitcherTitleWidthTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Customize',
    keywords: ['buttons', 'arrange', 'layout'],
    entries: [
      SettingsEntryDefinition(
        title: 'Show Toolbar Buttons',
        subtitle:
            "Off, the chrome shows only tabs and spaces. Back, forward, "
            "reload, tabs and settings stay available by long-pressing + in "
            "the rail's space row, or tapping the space icon on the compact "
            "bar.",
        keywords: [
          'toolbar',
          'buttons',
          'hide',
          'navigation',
          'back',
          'forward',
          'refresh',
          'settings',
          'rail',
          'compact bar',
          'space indicator',
        ],
        child: _RailToolbarTile(),
      ),
      SettingsEntryDefinition(
        title: 'Customize Toolbar Buttons',
        subtitle: 'Choose which actions appear in the toolbar',
        keywords: ['buttons', 'toolbar'],
        child: _CustomizeToolbarButtonsTile(),
      ),
      SettingsEntryDefinition(
        title: 'Customize Menu',
        subtitle:
            'Choose and order the sections and rows of the three-dot menu',
        keywords: [
          'sections',
          'rows',
          'reorder',
          'menu',
          'three dot',
          'overflow',
        ],
        child: _CustomizeMenuTile(),
      ),
    ],
  ),
];

class AppearanceLayoutContent extends StatelessWidget {
  final String query;

  const AppearanceLayoutContent({super.key, this.query = ''});

  @override
  Widget build(BuildContext context) {
    final filteredSections = filterSettingsSections(
      sections: appearanceLayoutSettingsSections,
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

class _CompactRailSideSection extends HookConsumerWidget {
  const _CompactRailSideSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compactRailSide = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.compactRailSide),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Slide-out Tab Rail'),
            subtitle: Text(
              'On narrow screens, replace the bar with a tab rail that '
              'slides in on a back swipe from this edge; a back swipe from '
              'the other edge still goes back. On Either side, the panel '
              'opens on whichever edge the swipe comes from',
            ),
            leading: Icon(MdiIcons.dockLeft),
            contentPadding: EdgeInsets.zero,
          ),
          RadioGroup<CompactRailSide?>(
            groupValue: compactRailSide,
            onChanged: (value) async {
              await ref
                  .read(saveZenSettingsControllerProvider.notifier)
                  .save(
                    (currentSettings) =>
                        currentSettings.copyWith.compactRailSide(value),
                  );
            },
            child: const Column(
              children: [
                RadioListTile<CompactRailSide?>.adaptive(
                  value: null,
                  title: Text('Off'),
                ),
                RadioListTile<CompactRailSide?>.adaptive(
                  value: CompactRailSide.left,
                  title: Text('Left'),
                ),
                RadioListTile<CompactRailSide?>.adaptive(
                  value: CompactRailSide.right,
                  title: Text('Right'),
                ),
                RadioListTile<CompactRailSide?>.adaptive(
                  value: CompactRailSide.either,
                  title: Text('Either side'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeToMoveRailTile extends HookConsumerWidget {
  const _SwipeToMoveRailTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swipeToMoveRail = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.swipeToMoveRail),
    );

    return SwitchListTile.adaptive(
      title: const Text('Swipe to Move the Rail'),
      subtitle: const Text(
        'On wide screens, a back swipe from the edge opposite the rail '
        "moves it there; a swipe from the rail's own edge still goes back",
      ),
      secondary: const Icon(MdiIcons.dockLeft),
      value: swipeToMoveRail,
      onChanged: (value) async {
        await ref
            .read(saveZenSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.swipeToMoveRail(value),
            );
      },
    );
  }
}

class _SpaceIndicatorSideSection extends HookConsumerWidget {
  const _SpaceIndicatorSideSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceIndicatorSide = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.spaceIndicatorSide),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Space Switcher Side'),
            subtitle: Text(
              'Which side of the tab chips the space switcher sits on',
            ),
            leading: Icon(MdiIcons.dockLeft),
            contentPadding: EdgeInsets.zero,
          ),
          RadioGroup(
            groupValue: spaceIndicatorSide,
            onChanged: (value) async {
              if (value != null) {
                await ref
                    .read(saveZenSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) =>
                          currentSettings.copyWith.spaceIndicatorSide(value),
                    );
              }
            },
            child: Column(
              children: [
                for (final side in SpaceIndicatorSide.values)
                  RadioListTile.adaptive(value: side, title: Text(side.label)),
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

class _CustomizeToolbarButtonsTile extends StatelessWidget {
  const _CustomizeToolbarButtonsTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('Customize Toolbar Buttons'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await const ContextualToolbarSettingsRoute().push(context);
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
    final sliderValue = useKeyedState(titleWidth, [titleWidth]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Title Width on Compact Bar Chips'),
            subtitle: Text(
              'Maximum width of a tab title on the compact bar, so a narrower '
              'screen fits more chips; the side rail always uses its full '
              'width',
            ),
            leading: Icon(MdiIcons.arrowExpandHorizontal),
            contentPadding: EdgeInsets.zero,
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
                  onChanged: (value) {
                    sliderValue.value = value;
                  },
                  onChangeEnd: (value) async {
                    final normalized =
                        (value / quickTabSwitcherTitleWidthStep).round() *
                        quickTabSwitcherTitleWidthStep;
                    sliderValue.value = normalized;
                    await ref
                        .read(saveGeneralSettingsControllerProvider.notifier)
                        .save(
                          (currentSettings) => currentSettings.copyWith
                              .quickTabSwitcherTitleWidth(normalized),
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

class _RailToolbarTile extends HookConsumerWidget {
  const _RailToolbarTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showToolbarButtons = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.showToolbarButtons),
    );

    return SwitchListTile.adaptive(
      title: const Text('Show Toolbar Buttons'),
      subtitle: const Text(
        "Off, the chrome shows only tabs and spaces. Back, forward, reload, "
        "tabs and settings stay available by long-pressing + in the rail's "
        "space row, or tapping the space icon on the compact bar.",
      ),
      secondary: const Icon(MdiIcons.dockTop),
      value: showToolbarButtons,
      onChanged: (value) async {
        await ref
            .read(saveZenSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.showToolbarButtons(value),
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

class _PureBlackTile extends HookConsumerWidget {
  const _PureBlackTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pureBlack = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.pureBlack),
    );
    final themeMode = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.themeMode),
    );

    // OLED surfaces only apply to dark mode; disable the toggle when the app
    // is locked to light mode so the setting can't appear to have no effect.
    final enabled = themeMode != ThemeMode.light;

    return SwitchListTile.adaptive(
      title: const Text('Pure Black (OLED)'),
      subtitle: const Text(
        'Use true-black surfaces in dark mode to save power on OLED screens',
      ),
      secondary: const Icon(Icons.contrast),
      value: pureBlack,
      onChanged: enabled
          ? (value) async {
              await ref
                  .read(saveGeneralSettingsControllerProvider.notifier)
                  .save(
                    (currentSettings) =>
                        currentSettings.copyWith.pureBlack(value),
                  );
            }
          : null,
    );
  }
}

class _AccentColorTile extends HookConsumerWidget {
  const _AccentColorTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.accentColor),
    );
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> setAccent(Color? color) {
      return ref
          .read(saveZenSettingsControllerProvider.notifier)
          .save(
            (currentSettings) =>
                currentSettings.copyWith.accentColor(color?.toARGB32()),
          );
    }

    Widget swatch({
      required Color? color,
      required bool selected,
      required String label,
      required VoidCallback onTap,
    }) {
      final swatchColor = color ?? colorScheme.surfaceContainerHighest;
      final borderColor = selected ? colorScheme.primary : colorScheme.outline;

      return Semantics(
        label: label,
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: swatchColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: color == null
                  ? Icon(
                      MdiIcons.themeLightDark,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    )
                  : selected
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: contrastingOnColor(color),
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Accent Color'),
            subtitle: Text(
              'The highlight color used for toggles and selections',
            ),
            leading: Icon(Icons.color_lens),
            contentPadding: EdgeInsets.zero,
          ),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              swatch(
                color: null,
                selected: accentColor == null,
                label: 'System',
                onTap: () => setAccent(null),
              ),
              for (final choice in kAccentChoices)
                swatch(
                  color: choice,
                  selected: accentColor == choice.toARGB32(),
                  label: 'Custom color',
                  onTap: () => setAccent(choice),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeSection extends HookConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.themeMode),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Theme'),
            leading: Icon(Icons.palette),
            contentPadding: EdgeInsets.zero,
          ),
          Center(
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (value) async {
                await ref
                    .read(saveGeneralSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) =>
                          currentSettings.copyWith.themeMode(value.first),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}
