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
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/search/domain/entities/abstract/i_search_suggestion_provider.dart';
import 'package:mellow/features/settings/presentation/controllers/save_settings.dart';
import 'package:mellow/features/settings/presentation/widgets/custom_search_engines_editor.dart';
import 'package:mellow/features/settings/presentation/widgets/default_search_selector.dart';
import 'package:mellow/features/settings/presentation/widgets/settings_detail.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/presentation/widgets/url_icon.dart';
import 'package:nullability/nullability.dart';

const List<SettingsSectionDefinition> searchSettingsSections = [
  SettingsSectionDefinition(
    title: 'Search',
    keywords: ['engines'],
    showTitle: false,
    entries: [
      SettingsEntryDefinition(
        title: 'Default Search Provider',
        subtitle: 'Choose the default engine for searches',
        keywords: ['search engine', 'providers'],
        child: _DefaultSearchProviderSection(),
      ),
      SettingsEntryDefinition(
        title: 'Search engines',
        subtitle: 'Add and manage your own search engines',
        keywords: ['custom search engine', 'add engine', 'providers'],
        child: _SearchEnginesSection(),
      ),
      SettingsEntryDefinition(
        title: 'Default Autocomplete Provider',
        subtitle: 'Choose the provider for search suggestions',
        keywords: ['suggestions', 'providers'],
        child: _AutocompleteProviderSection(),
      ),
      SettingsEntryDefinition(
        title: 'Indexed pages',
        subtitle: 'View and clear the local index',
        keywords: [
          'clear index',
          'stats',
          'local search index',
          'on device search',
          'index',
        ],
        child: _LocalIndexStatsTile(),
      ),
    ],
  ),
];

class SearchSettingsScreen extends StatelessWidget {
  const SearchSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'Search',
      subtitle: 'Providers, history suggestions, and on-device search.',
      icon: MdiIcons.magnify,
      sections: searchSettingsSections,
    );
  }
}

class _DefaultSearchProviderSection extends StatelessWidget {
  const _DefaultSearchProviderSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Default Search Provider'),
            leading: Icon(MdiIcons.cloudSearch),
            contentPadding: EdgeInsets.zero,
          ),
          Padding(
            padding: EdgeInsets.only(left: 40),
            child: DefaultSearchSelector(),
          ),
        ],
      ),
    );
  }
}

class _SearchEnginesSection extends StatelessWidget {
  const _SearchEnginesSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: ListTile(
              title: Text('Search engines'),
              subtitle: Text(
                'The engines every picker offers. Add your own with a URL '
                'that has {searchTerms} where the query goes.',
              ),
              leading: Icon(MdiIcons.magnify),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          CustomSearchEnginesEditor(),
        ],
      ),
    );
  }
}

class _AutocompleteProviderSection extends HookConsumerWidget {
  const _AutocompleteProviderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultSearchSuggestionsProvider = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.defaultSearchSuggestionsProvider,
      ),
    );
    final suggestionIconUrl = defaultSearchSuggestionsProvider.iconUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Default Autocomplete Provider'),
            leading: Icon(MdiIcons.weatherCloudyArrowRight),
            contentPadding: EdgeInsets.zero,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: DropdownMenu<SearchSuggestionProviders>(
              initialSelection: defaultSearchSuggestionsProvider,
              inputDecorationTheme: InputDecorationTheme(
                prefixIconConstraints: BoxConstraints.tight(
                  const Size.square(24),
                ),
              ),
              width: double.infinity,
              leadingIcon: suggestionIconUrl.mapNotNull(
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
          ),
        ],
      ),
    );
  }
}

class _LocalIndexStatsTile extends HookConsumerWidget {
  const _LocalIndexStatsTile();

  Future<bool?> _confirmClear(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local search index?'),
        content: const Text(
          'This removes all locally indexed page content. Engine history '
          '(visit metadata) is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bump on Clear to re-trigger the count query.
    final refreshTick = useState(0);
    final countSnapshot = useFuture(
      useMemoized(() => ref.read(tabDatabaseProvider).historyDao.countRows(), [
        refreshTick.value,
      ]),
    );
    final count = countSnapshot.data;

    return ListTile(
      leading: const Icon(MdiIcons.databaseOutline),
      title: const Text('Indexed pages'),
      subtitle: Text(count.mapNotNull((c) => '$c pages indexed') ?? 'Loading…'),
      trailing: TextButton.icon(
        icon: const Icon(MdiIcons.deleteOutline),
        label: const Text('Clear'),
        onPressed: count == null || count == 0
            ? null
            : () async {
                final confirmed = await _confirmClear(context);
                if (confirmed != true) return;
                await ref.read(tabDatabaseProvider).historyDao.clear();
                refreshTick.value++;
              },
      ),
    );
  }
}
