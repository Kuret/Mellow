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
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

const List<SettingsSectionDefinition> homeSettingsSections = [
  SettingsSectionDefinition(
    title: 'Layout',
    keywords: ['home', 'new tab', 'sections', 'modules', 'layout'],
    entries: [
      SettingsEntryDefinition(
        title: 'Search bar position',
        subtitle: 'Where the home page offers its search field',
        keywords: [
          'search',
          'bar',
          'position',
          'address',
          'url',
          'top',
          'bottom',
          'tab bar',
          'home',
        ],
        child: _HomeSearchBarPlacementTile(),
      ),
      SettingsEntryDefinition(
        title: 'Customize home sections',
        subtitle: 'Choose and order what the home page shows',
        keywords: [
          'home',
          'sections',
          'shortcuts',
          'quote',
          'quick actions',
          'reorder',
        ],
        child: _CustomizeHomeSectionsTile(),
      ),
      SettingsEntryDefinition(
        title: 'Customize new tab sections',
        subtitle: 'Choose and order what the new tab page shows',
        keywords: ['new tab', 'sections', 'shortcuts', 'reorder'],
        child: _CustomizeNewTabSectionsTile(),
      ),
    ],
  ),
];

class HomeSettingsScreen extends StatelessWidget {
  const HomeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'Home & New Tab',
      subtitle: 'What the home and new tab pages show',
      icon: MdiIcons.homeOutline,
      sections: homeSettingsSections,
    );
  }
}

class _HomeSearchBarPlacementTile extends ConsumerWidget {
  const _HomeSearchBarPlacementTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(generalSettingsWithDefaultsProvider);
    final resolved = settings.effectiveHomeSearchBarPlacement();

    return RadioGroup<HomeSearchBarPlacement>(
      groupValue: settings.homeSearchBarPlacement,
      onChanged: (value) async {
        if (value == null) return;

        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save((s) => s.copyWith.homeSearchBarPlacement(value));
      },
      child: Column(
        children: [
          for (final placement in HomeSearchBarPlacement.values)
            RadioListTile<HomeSearchBarPlacement>(
              value: placement,
              title: Text(placement.label),
              // Auto says what it currently resolves to; the fixed choices
              // already describe themselves.
              subtitle: Text(
                placement == HomeSearchBarPlacement.auto
                    ? 'Currently: ${resolved.label.toLowerCase()}'
                    : placement.description,
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomizeHomeSectionsTile extends ConsumerWidget {
  const _CustomizeHomeSectionsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(MdiIcons.homeOutline),
      title: const Text('Customize home sections'),
      subtitle: const Text('Choose and order what the home page shows'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => const HomeModulesSettingsRoute().push(context),
    );
  }
}

class _CustomizeNewTabSectionsTile extends ConsumerWidget {
  const _CustomizeNewTabSectionsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(MdiIcons.tabPlus),
      title: const Text('Customize new tab sections'),
      subtitle: const Text('Choose and order what the new tab page shows'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => const NewTabModulesSettingsRoute().push(context),
    );
  }
}
