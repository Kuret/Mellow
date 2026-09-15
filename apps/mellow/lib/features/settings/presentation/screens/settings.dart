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
import 'package:fading_scroll/fading_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/settings/domain/providers/pending_settings_highlight.dart';
import 'package:mellow/features/settings/presentation/screens/advanced_settings.dart';
import 'package:mellow/features/settings/presentation/screens/appearance_layout_settings.dart';
import 'package:mellow/features/settings/presentation/screens/extensions_settings.dart';
import 'package:mellow/features/settings/presentation/screens/links_sites_settings.dart';
import 'package:mellow/features/settings/presentation/screens/privacy_security_settings.dart';
import 'package:mellow/features/settings/presentation/screens/search_settings.dart';
import 'package:mellow/features/settings/presentation/screens/settings_layout.dart';
import 'package:mellow/features/settings/presentation/screens/tabs_spaces_settings.dart';
import 'package:mellow/features/settings/presentation/widgets/appearance_layout_content.dart';
import 'package:mellow/features/settings/presentation/widgets/settings_detail.dart';
import 'package:mellow/features/sync/presentation/screens/sync_settings.dart';

/// Activates [category] — either by pushing its route (narrow layout) or by
/// selecting it into the two-pane layout's right-hand pane (wide layout).
/// Shared by [_CategoryTile] and [_SearchResultTile] so neither tile encodes
/// which layout it is running in.
typedef _CategoryActivate =
    Future<void> Function(
      BuildContext context,
      _SettingsCategoryDefinition category,
    );

class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isTwoPane = useTwoPaneSettings(viewportWidth);

    final search = useSettingsSearch();
    final categories = _buildCategories();
    final allCategories = [...categories.browser, ...categories.services];

    // Local to the widget: which category is shown in the right pane, and a
    // counter bumped on every selection so the pane can be keyed on it and
    // remounted even when the same category is picked again (a settings
    // search result can point back into the category already open).
    final selectedIndex = useState(0);
    final selectionCounter = useState(0);
    final selectedCategory = allCategories[selectedIndex.value];

    Future<void> pushRoute(
      BuildContext context,
      _SettingsCategoryDefinition category,
    ) => category.onTap(context);

    Future<void> selectCategory(
      BuildContext context,
      _SettingsCategoryDefinition category,
    ) async {
      final index = allCategories.indexOf(category);
      if (index == -1) return;
      selectedIndex.value = index;
      selectionCounter.value++;
    }

    final activate = isTwoPane ? selectCategory : pushRoute;

    final sections = search.normalizedQuery.isEmpty
        ? _buildCategorySections(
            categories,
            activate,
            selected: isTwoPane ? selectedCategory : null,
          )
        : _buildSearchSections(allCategories, search.normalizedQuery, activate);

    final indexContent = SafeArea(
      child: FadingScroll(
        fadingSize: 25,
        builder: (context, controller) {
          return CustomScrollView(
            controller: controller,
            slivers: [
              const SliverAppBar.large(
                centerTitle: false,
                title: Text('Settings'),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: SettingsSearchField(
                    controller: search.controller,
                    hintText: 'Search all settings',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                sliver: SliverToBoxAdapter(
                  child: SettingsSectionList(
                    sections: sections,
                    query: search.rawQuery,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (!isTwoPane) {
      return Scaffold(body: indexContent);
    }

    final paneWidth = (viewportWidth * 0.34).clamp(320.0, 420.0);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: paneWidth, child: indexContent),
          const VerticalDivider(key: Key('settingsTwoPaneDivider'), width: 1),
          Expanded(
            // Its own Navigator, with the selected category's screen as the
            // sole (root) route: that keeps `ModalRoute.canPop` false inside
            // the pane, so the screen's SliverAppBar.large does not grow a
            // back arrow that would pop the whole Settings route. Keyed on
            // the selection counter so choosing a category — even the one
            // already shown — remounts the pane from scratch, which is what
            // lets a settings-search result re-trigger the pending-highlight
            // scroll/flash on a category already open.
            child: Navigator(
              key: ValueKey(selectionCounter.value),
              onGenerateRoute: (_) =>
                  MaterialPageRoute<void>(builder: selectedCategory.screen),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _CategoryGroups = ({
  List<_SettingsCategoryDefinition> browser,
  List<_SettingsCategoryDefinition> services,
});

_CategoryGroups _buildCategories() {
  final browser = [
    _SettingsCategoryDefinition(
      title: 'Appearance & Layout',
      subtitle: 'Theme, side rail, compact bar, customization',
      icon: MdiIcons.paletteOutline,
      keywords: const [
        'appearance',
        'theme',
        'toolbar buttons',
        'quick tab switcher',
        'menu',
      ],
      sections: appearanceLayoutSettingsSections,
      onTap: (context) => AppearanceLayoutSettingsRoute().push(context),
      screen: (context) => const AppearanceLayoutSettingsScreen(),
    ),
    _SettingsCategoryDefinition(
      title: 'Tabs & Spaces',
      subtitle: 'Spaces, tab budget, containers',
      icon: MdiIcons.viewDashboardOutline,
      keywords: const ['workspaces', 'zen', 'spaces', 'containers', 'tabs'],
      sections: tabsSpacesSettingsSections,
      onTap: (context) => TabsSpacesSettingsRoute().push(context),
      screen: (context) => const TabsSpacesSettingsScreen(),
    ),
    _SettingsCategoryDefinition(
      title: 'Links & Sites',
      subtitle: 'App links, desktop mode, installed sites',
      icon: MdiIcons.linkVariant,
      keywords: const ['navigation', 'external links', 'desktop mode', 'pwa'],
      sections: linksSitesSettingsSections,
      onTap: (context) => LinksSitesSettingsRoute().push(context),
      screen: (context) => const LinksSitesSettingsScreen(),
    ),
    _SettingsCategoryDefinition(
      title: 'Search',
      subtitle: 'Providers, suggestions, search history',
      icon: MdiIcons.magnify,
      keywords: const ['engines', 'suggestions', 'local search index'],
      sections: searchSettingsSections,
      onTap: (context) => SearchSettingsRoute().push(context),
      screen: (context) => const SearchSettingsScreen(),
    ),
    _SettingsCategoryDefinition(
      title: 'Privacy & Security',
      subtitle: 'Tracking protection, data clearing',
      icon: MdiIcons.shieldLock,
      keywords: const ['tracking protection', 'doh', 'incognito'],
      sections: privacySecuritySettingsSections,
      onTap: (context) => PrivacySecuritySettingsRoute().push(context),
      screen: (context) => const PrivacySecuritySettingsScreen(),
    ),
  ];

  final services = [
    _SettingsCategoryDefinition(
      title: 'Extensions',
      subtitle: 'Install and manage extension sources',
      icon: MdiIcons.puzzleOutline,
      keywords: const ['addons', 'unsigned extensions'],
      sections: extensionsSettingsSections,
      onTap: (context) => ExtensionsSettingsRoute().push(context),
      screen: (context) => const ExtensionsSettingsScreen(),
    ),
    _SettingsCategoryDefinition(
      title: 'Firefox Sync',
      subtitle: 'Account, sync now, engine selection',
      icon: Icons.sync,
      keywords: const ['pair', 'device name', 'engines'],
      onTap: (context) => SyncSettingsRoute().push(context),
      screen: (context) => const SyncSettingsScreen(),
    ),
    _SettingsCategoryDefinition(
      title: 'Advanced',
      subtitle: 'Web engine, developer tools, profile',
      icon: Icons.developer_mode,
      keywords: const [
        'error logs',
        'javascript',
        'user agent',
        'profile',
        'backup',
        'default browser',
      ],
      sections: advancedSettingsSections,
      onTap: (context) => AdvancedSettingsRoute().push(context),
      screen: (context) => const AdvancedSettingsScreen(),
    ),
  ];

  return (browser: browser, services: services);
}

List<SettingsSectionDefinition> _buildCategorySections(
  _CategoryGroups categories,
  _CategoryActivate activate, {
  _SettingsCategoryDefinition? selected,
}) {
  return [
    SettingsSectionDefinition(
      title: 'Browser',
      entries: [
        for (final category in categories.browser)
          _buildCategoryEntry(
            category,
            activate,
            selected: category == selected,
          ),
      ],
    ),
    SettingsSectionDefinition(
      title: 'Services & Advanced',
      entries: [
        for (final category in categories.services)
          _buildCategoryEntry(
            category,
            activate,
            selected: category == selected,
          ),
      ],
    ),
  ];
}

List<SettingsSectionDefinition> _buildSearchSections(
  List<_SettingsCategoryDefinition> categories,
  String normalizedQuery,
  _CategoryActivate activate,
) {
  final results = <String, List<SettingsEntryDefinition>>{};

  for (final category in categories) {
    final categoryEntries = <SettingsEntryDefinition>[];

    if (matchesSettingsSearch(normalizedQuery, [
      category.title,
      category.subtitle,
      ...category.keywords,
    ])) {
      categoryEntries.add(_buildCategoryEntry(category, activate));
    }

    for (final section in filterSettingsSections(
      sections: category.sections,
      query: normalizedQuery,
    )) {
      // A category rendered as one heading-less card has no section to name,
      // and its section title is the category's own — saying it twice would
      // read as a path that does not exist on the screen.
      final sectionLabel = section.showTitle && section.title != category.title
          ? section.title
          : null;

      for (final entry in section.entries) {
        categoryEntries.add(
          SettingsEntryDefinition(
            title: entry.title,
            subtitle: sectionLabel == null
                ? category.title
                : '$sectionLabel • ${category.title}',
            keywords: entry.keywords,
            child: _SearchResultTile(
              title: entry.title,
              subtitle: entry.subtitle,
              category: category.title,
              section: sectionLabel,
              icon: category.icon,
              onTap: (context) => activate(context, category),
            ),
          ),
        );
      }
    }

    if (categoryEntries.isNotEmpty) {
      results[category.title] = categoryEntries;
    }
  }

  return [
    for (final result in results.entries)
      SettingsSectionDefinition(title: result.key, entries: result.value),
  ];
}

SettingsEntryDefinition _buildCategoryEntry(
  _SettingsCategoryDefinition category,
  _CategoryActivate activate, {
  bool selected = false,
}) {
  return SettingsEntryDefinition(
    title: category.title,
    subtitle: category.subtitle,
    keywords: category.keywords,
    child: _CategoryTile(
      category: category,
      selected: selected,
      onTap: (context) => activate(context, category),
    ),
  );
}

class _SettingsCategoryDefinition {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> keywords;
  final List<SettingsSectionDefinition> sections;
  final Future<void> Function(BuildContext context) onTap;

  /// Builds the screen this category opens. Used to host it directly in the
  /// two-pane layout's right pane; the narrow layout still gets there by
  /// pushing the route via [onTap].
  final WidgetBuilder screen;

  const _SettingsCategoryDefinition({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.screen,
    this.keywords = const [],
    this.sections = const [],
  });
}

class _CategoryTile extends StatelessWidget {
  final _SettingsCategoryDefinition category;

  /// Whether this tile is the category currently shown in the two-pane
  /// layout's right pane. Never true in the narrow layout, where a tile
  /// only ever pushes a route and nothing stays "open" beside it.
  final bool selected;
  final Future<void> Function(BuildContext context) onTap;

  const _CategoryTile({
    required this.category,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(category.title),
      subtitle: Text(category.subtitle),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      leading: Icon(category.icon),
      trailing: selected ? null : const Icon(Icons.chevron_right),
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      onTap: () async {
        await onTap(context);
      },
    );
  }
}

class _SearchResultTile extends HookConsumerWidget {
  final String title;
  final String? subtitle;
  final String category;
  final String? section;
  final IconData icon;
  final Future<void> Function(BuildContext context) onTap;

  const _SearchResultTile({
    required this.title,
    required this.category,
    required this.icon,
    required this.onTap,
    this.section,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breadcrumb = section == null ? category : '$category • $section';

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle == null || subtitle!.isEmpty
            ? breadcrumb
            : '$breadcrumb\n$subtitle',
      ),
      isThreeLine: subtitle != null && subtitle!.isNotEmpty,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final pendingHighlight = ref.read(
          pendingSettingsHighlightProvider.notifier,
        );
        pendingHighlight.set(title);
        try {
          await onTap(context);
        } catch (_) {
          pendingHighlight.clear();
          rethrow;
        }
      },
    );
  }
}
