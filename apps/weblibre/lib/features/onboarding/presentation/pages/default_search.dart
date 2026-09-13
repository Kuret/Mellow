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
import 'package:nullability/nullability.dart';
import 'package:weblibre/features/search/domain/entities/abstract/i_search_suggestion_provider.dart';
import 'package:weblibre/features/search/domain/entities/builtin_search_providers.dart';
import 'package:weblibre/features/search/domain/entities/search_provider.dart';
import 'package:weblibre/features/search/domain/providers/search_provider.dart';
import 'package:weblibre/features/search/presentation/widgets/search_provider_icon.dart';
import 'package:weblibre/features/settings/presentation/controllers/save_settings.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/presentation/widgets/browser_page.dart';
import 'package:weblibre/presentation/widgets/url_icon.dart';

class DefaultSearchPage extends HookConsumerWidget {
  const DefaultSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final activeProvider = ref.watch(defaultSearchProviderProvider);
    final activeAutosuggest = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (value) => value.defaultSearchSuggestionsProvider,
      ),
    );

    Future<void> updateSearchProvider(SearchProvider provider) async {
      await ref
          .read(saveGeneralSettingsControllerProvider.notifier)
          .save(
            (currentSettings) =>
                currentSettings.copyWith.defaultSearchProvider(provider.id),
          );
    }

    return BrowserPage(
      child: BrowserPageContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text('Search', style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: 24),
            const ListTile(
              title: Text('Default Search Provider'),
              leading: Icon(MdiIcons.cloudSearch),
              contentPadding: EdgeInsets.zero,
            ),
            Wrap(
              spacing: 8.0,
              children: [
                for (final provider in builtinSearchProviders)
                  FilterChip(
                    showCheckmark: false,
                    label: Text(provider.name),
                    avatar: SearchProviderIcon(provider: provider),
                    selected: provider.id == activeProvider.id,
                    onSelected: (selected) async {
                      if (selected) {
                        await updateSearchProvider(provider);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const ListTile(
              title: Text('Default Autocomplete Provider'),
              leading: Icon(MdiIcons.weatherCloudyArrowRight),
              contentPadding: EdgeInsets.zero,
            ),
            DropdownMenu<SearchSuggestionProviders>(
              initialSelection: activeAutosuggest,
              inputDecorationTheme: InputDecorationTheme(
                prefixIconConstraints: BoxConstraints.tight(
                  const Size.square(24),
                ),
              ),
              width: double.infinity,
              leadingIcon: activeAutosuggest.iconUrl.mapNotNull(
                (url) => UrlIcon([url], iconSize: 20),
              ),
              dropdownMenuEntries: SearchSuggestionProviders.values.map((
                provider,
              ) {
                return DropdownMenuEntry(
                  value: provider,
                  label: provider.label,
                  leadingIcon: provider.iconUrl.mapNotNull(
                    (url) => UrlIcon([url], iconSize: 20),
                  ),
                );
              }).toList(),
              onSelected: (value) async {
                if (value != null) {
                  await ref
                      .read(saveGeneralSettingsControllerProvider.notifier)
                      .save(
                        (currentSettings) => currentSettings.copyWith
                            .defaultSearchSuggestionsProvider(value),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
