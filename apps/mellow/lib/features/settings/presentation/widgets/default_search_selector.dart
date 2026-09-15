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
import 'package:mellow/features/search/domain/providers/search_provider.dart';
import 'package:mellow/features/search/presentation/widgets/search_provider_icon.dart';
import 'package:mellow/features/settings/presentation/controllers/save_settings.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';

class DefaultSearchSelector extends HookConsumerWidget {
  const DefaultSearchSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProvider = ref.watch(defaultSearchProviderProvider);
    final providers = ref.watch(allSearchProvidersProvider);

    return DropdownMenu(
      key: ValueKey(activeProvider.id),
      initialSelection: activeProvider,
      inputDecorationTheme: InputDecorationTheme(
        prefixIconConstraints: BoxConstraints.tight(const Size.square(24)),
      ),
      width: double.infinity,
      leadingIcon: SearchProviderIcon(provider: activeProvider, iconSize: 20),
      dropdownMenuEntries: providers.map((provider) {
        return DropdownMenuEntry(
          value: provider,
          label: provider.name,
          leadingIcon: SearchProviderIcon(provider: provider, iconSize: 20),
        );
      }).toList(),
      onSelected: (provider) async {
        if (provider != null) {
          await ref
              .read(saveGeneralSettingsControllerProvider.notifier)
              .save(
                (currentSettings) =>
                    currentSettings.copyWith.defaultSearchProvider(provider.id),
              );
        }
      },
    );
  }
}
