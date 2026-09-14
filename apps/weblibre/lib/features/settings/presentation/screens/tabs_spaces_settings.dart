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
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:weblibre/features/settings/presentation/controllers/save_settings.dart';
import 'package:weblibre/features/settings/presentation/widgets/settings_detail.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

/// One card: the space list sits with the tab budget and the container
/// switches because a space *is* a container here, and picking between them is
/// the same decision.
const List<SettingsSectionDefinition> tabsSpacesSettingsSections = [
  SettingsSectionDefinition(
    title: 'Tabs & Spaces',
    keywords: ['tabs'],
    showTitle: false,
    entries: [
      SettingsEntryDefinition(
        title: 'Spaces',
        subtitle: 'Create, reorder and edit spaces',
        keywords: ['workspaces', 'zen', 'spaces', 'containers'],
        child: _SpacesTile(),
      ),
      SettingsEntryDefinition(
        title: 'Keep at most N tabs loaded',
        subtitle: 'Unload the least recently used tabs beyond this many',
        keywords: ['memory', 'unload', 'cold', 'live', 'loaded'],
        child: _MaxLiveTabsSection(),
      ),
      SettingsEntryDefinition(
        title: 'Separate essentials per container',
        subtitle: 'Each container keeps its own Essentials strip',
        keywords: ['essentials', 'pinned', 'spaces', 'containers', 'zen'],
        child: _SeparateEssentialsTile(),
      ),
      SettingsEntryDefinition(
        title: 'Show Container UI',
        subtitle: 'Show container selectors, menus, and management',
        keywords: ['containers'],
        child: _ShowContainerUiTile(),
      ),
    ],
  ),
];

class TabsSpacesSettingsScreen extends StatelessWidget {
  const TabsSpacesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'Tabs & Spaces',
      subtitle: 'Spaces, the tab budget, and container visibility.',
      icon: MdiIcons.viewDashboardOutline,
      sections: tabsSpacesSettingsSections,
    );
  }
}

/// The space list lives on its own screen; this is the row that reaches it,
/// and it is the same route the settings index used to offer as a category.
class _SpacesTile extends StatelessWidget {
  const _SpacesTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(MdiIcons.viewDashboardOutline),
      title: const Text('Spaces'),
      subtitle: const Text('Create, reorder and edit spaces'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await const SpaceListRoute().push(context);
      },
    );
  }
}

/// Zen's `zen.workspaces.separate-essentials` (PLAN §6.4): whether the
/// Essentials strip is keyed on the current space's container or shared by
/// every space.
class _SeparateEssentialsTile extends ConsumerWidget {
  const _SeparateEssentialsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final separateEssentials = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.separateEssentials),
    );

    return SwitchListTile.adaptive(
      title: const Text('Separate essentials per container'),
      subtitle: const Text(
        'A space shows the essentials of its own container, as on the Zen '
        'desktop; off, every space shows all essentials',
      ),
      secondary: const Icon(MdiIcons.starBoxMultipleOutline),
      value: separateEssentials,
      onChanged: (value) async {
        await ref
            .read(saveZenSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.separateEssentials(value),
            );
      },
    );
  }
}

class _ShowContainerUiTile extends HookConsumerWidget {
  const _ShowContainerUiTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showContainerUi = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.showContainerUi),
    );

    return SwitchListTile.adaptive(
      title: const Text('Show Container UI'),
      subtitle: const Text('Show container selectors, menus, and management'),
      secondary: const Icon(MdiIcons.folder),
      value: showContainerUi,
      onChanged: (value) async {
        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.showContainerUi(value),
            );

        if (!value) {
          ref.read(selectedContainerProvider.notifier).clearContainer();
        }
      },
    );
  }
}

/// "Keep at most N tabs loaded" — [GeneralSettings.maxLiveTabs], the budget
/// `LiveTabBudget` enforces (PLAN §7.4). Steps of five between
/// [minMaxLiveTabs] and [maxMaxLiveTabs].
class _MaxLiveTabsSection extends HookConsumerWidget {
  static const _step = 5;

  const _MaxLiveTabsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxLiveTabs = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.maxLiveTabs),
    );
    final sliderValue = useState(maxLiveTabs.toDouble());
    useEffect(() {
      sliderValue.value = maxLiveTabs.toDouble();
      return null;
    }, [maxLiveTabs]);
    final shown = sliderValue.value.round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(MdiIcons.snowflakeVariant),
          title: Text('Keep at most $shown tabs loaded'),
          subtitle: const Text(
            'Tabs beyond this are unloaded, least recently used first, and '
            'load again when tapped',
          ),
          contentPadding: EdgeInsets.zero,
        ),
        Slider(
          min: minMaxLiveTabs.toDouble(),
          max: maxMaxLiveTabs.toDouble(),
          divisions: (maxMaxLiveTabs - minMaxLiveTabs) ~/ _step,
          label: '$shown',
          value: sliderValue.value.clamp(
            minMaxLiveTabs.toDouble(),
            maxMaxLiveTabs.toDouble(),
          ),
          onChanged: (value) {
            sliderValue.value = value;
          },
          onChangeEnd: (value) async {
            final rounded = ((value / _step).round() * _step).clamp(
              minMaxLiveTabs,
              maxMaxLiveTabs,
            );
            sliderValue.value = rounded.toDouble();
            await ref
                .read(saveZenSettingsControllerProvider.notifier)
                .save(
                  (currentSettings) =>
                      currentSettings.copyWith.maxLiveTabs(rounded),
                );
          },
        ),
      ],
    );
  }
}
