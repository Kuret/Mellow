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
part of 'routes.dart';

@TypedGoRoute<BrowserRoute>(
  name: BrowserRoute.name,
  path: '/browser',
  routes: [
    TypedGoRoute<SearchRoute>(
      name: 'SearchRoute',
      path: 'search/:tabType/:searchText',
    ),
    TypedGoRoute<TabViewRoute>(name: 'TabViewRoute', path: 'tab_view'),
    TypedGoRoute<ContextMenuRoute>(
      name: 'ContextMenuRoute',
      path: 'context_menu',
    ),
    TypedGoRoute<ContainerDraftRoute>(
      name: 'ContainerDraftRoute',
      path: 'container_draft',
    ),
    TypedGoRoute<ContainerListRoute>(
      name: 'ContainerListRoute',
      path: 'containers',
      routes: [
        TypedGoRoute<ContainerCreateRoute>(
          name: 'ContainerCreateRoute',
          path: 'create/:containerData',
        ),
        TypedGoRoute<ContainerEditRoute>(
          name: 'ContainerEditRoute',
          path: 'edit/:containerData',
        ),
      ],
    ),
    TypedGoRoute<ContainerSelectionRoute>(
      name: 'ContainerSelectionRoute',
      path: 'select_container',
    ),
    TypedGoRoute<TabTreeRoute>(
      name: 'TabTreeRoute',
      path: 'tab_tree/:rootTabId',
    ),
    TypedGoRoute<OpenSharedContentRoute>(
      name: 'OpenSharedContentRoute',
      path: 'open_content',
    ),
    TypedGoRoute<SelectProfileRoute>(
      name: 'SelectProfileRoute',
      path: 'profile',
    ),
  ],
)
class BrowserRoute extends GoRouteData with $BrowserRoute {
  static const name = 'BrowserRoute';

  const BrowserRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const BrowserScreen();
  }
}

class SearchRoute extends GoRouteData with $SearchRoute {
  static const String emptySearchText = ' ';

  final TabType tabType;

  //This should be nullable but isnt allowed by go_router
  final String searchText;

  final bool launchedFromIntent;

  final bool autoSubmitSearch;

  /// When provided, the search screen will load URLs into this existing tab
  /// instead of creating a new tab. This also changes the UI to show
  /// a site-specific search provider instead of the tab type selector.
  final String? tabId;

  /// Whether the search floats over the page as a command panel or takes the
  /// screen. Panel is the default because the common way in is a tap on the
  /// address bar, where the page behind is the context for the edit.
  final SearchPresentation presentation;

  const SearchRoute({
    required this.tabType,
    this.searchText = SearchRoute.emptySearchText,
    this.launchedFromIntent = false,
    this.autoSubmitSearch = false,
    this.tabId,
    this.presentation = SearchPresentation.panel,
  });

  /// An intent from outside the app has no browser behind it to float over,
  /// and an auto-submitted search lands on a page of results rather than a
  /// suggestion list. Both take the screen whatever the caller asked for.
  SearchPresentation get effectivePresentation =>
      (launchedFromIntent || autoSubmitSearch)
      ? SearchPresentation.fullScreen
      : presentation;

  String? get _initialSearchText =>
      (searchText.isEmpty || searchText == emptySearchText) ? null : searchText;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SearchScreen(
      tabType: tabType,
      initialSearchText: _initialSearchText,
      launchedFromIntent: launchedFromIntent,
      autoSubmitSearch: autoSubmitSearch,
      tabId: tabId,
    );
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if (effectivePresentation == SearchPresentation.fullScreen) {
      return MaterialPage(key: state.pageKey, child: build(context, state));
    }

    return searchPanelPage<void>(
      key: state.pageKey,
      child: SearchPanel(
        builder: (context, metrics) => SearchScreen(
          tabType: tabType,
          initialSearchText: _initialSearchText,
          tabId: tabId,
          presentation: SearchPresentation.panel,
          panelMaxHeight: metrics.maxHeight,
          panelExpandedMaxHeight: metrics.expandedMaxHeight,
        ),
      ),
    );
  }
}

bool _isContainerUiEnabled(BuildContext context) {
  final settings = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(generalSettingsWithDefaultsProvider);

  return settings.showContainerUi;
}

class ContainerDraftRoute extends GoRouteData with $ContainerDraftRoute {
  const ContainerDraftRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    return _isContainerUiEnabled(context)
        ? null
        : const BrowserRoute().location;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ContainerDraftSuggestionsScreen();
  }
}

class ContainerListRoute extends GoRouteData with $ContainerListRoute {
  const ContainerListRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    return _isContainerUiEnabled(context)
        ? null
        : const BrowserRoute().location;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ContainerListScreen();
  }
}

class ContainerSelectionRoute extends GoRouteData
    with $ContainerSelectionRoute {
  const ContainerSelectionRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    return _isContainerUiEnabled(context)
        ? null
        : const BrowserRoute().location;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ContainerSelectionScreen();
  }
}

class ContainerEditRoute extends GoRouteData with $ContainerEditRoute {
  final String containerData;

  const ContainerEditRoute({required this.containerData});

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    return _isContainerUiEnabled(context)
        ? null
        : const BrowserRoute().location;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ContainerEditScreen.edit(
      initialContainer: ContainerDataWithCount.fromJson(
        jsonDecode(containerData) as Map<String, dynamic>,
      ),
    );
  }
}

class ContainerCreateRoute extends GoRouteData with $ContainerCreateRoute {
  final String containerData;
  final String tabIds;

  ContainerCreateRoute({required this.containerData, this.tabIds = '[]'});

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    return _isContainerUiEnabled(context)
        ? null
        : const BrowserRoute().location;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final tabIdsList = jsonDecode(tabIds) as List;
    final tabIdsSet = tabIdsList.cast<String>().toSet();

    return ContainerEditScreen.create(
      initialContainer: ContainerData.fromJson(
        jsonDecode(containerData) as Map<String, dynamic>,
      ),
      tabIds: tabIdsSet.isNotEmpty ? tabIdsSet : null,
    );
  }
}

class ContextMenuRoute extends GoRouteData with $ContextMenuRoute {
  final String hitResult;

  const ContextMenuRoute({required this.hitResult});

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return DialogPage(
      builder: (_) =>
          ContextMenuDialog(hitResult: HitResultJson.fromJson(hitResult)),
    );
  }
}

class TabTreeRoute extends GoRouteData with $TabTreeRoute {
  final String rootTabId;

  const TabTreeRoute(this.rootTabId);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return DialogPage(builder: (_) => TabTreeDialog(rootTabId));
  }
}

class OpenSharedContentRoute extends GoRouteData with $OpenSharedContentRoute {
  final String sharedUrl;
  final String? contextId;
  final String? containerMode;

  const OpenSharedContentRoute({
    this.sharedUrl = 'about:blank',
    this.contextId,
    this.containerMode,
  });

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return BottomSheetPage(
      builder: (_) => OpenSharedContent(
        sharedUrl: Uri.tryParse(sharedUrl) ?? Uri.parse('about:blank'),
        contextId: contextId,
        containerMode: IntentContainerMode.fromWireValue(
          containerMode,
          contextId: contextId,
        ),
      ),
    );
  }
}

class TabViewRoute extends GoRouteData with $TabViewRoute {
  const TabViewRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return DialogPage(builder: (_) => const TabViewScreen());
  }
}

class SelectProfileRoute extends GoRouteData with $SelectProfileRoute {
  const SelectProfileRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return BottomSheetPage(builder: (_) => const SelectProfileDialog());
  }
}
