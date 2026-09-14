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

@TypedGoRoute<SettingsRoute>(
  name: 'SettingsRoute',
  path: '/settings',
  routes: [
    TypedGoRoute<GeneralSettingsRoute>(
      name: 'GeneralSettingsRoute',
      path: 'general',
    ),
    TypedGoRoute<SettingsTransferRoute>(
      name: 'SettingsTransferRoute',
      path: 'transfer',
    ),
    TypedGoRoute<BrowsingSettingsRoute>(
      name: 'BrowsingSettingsRoute',
      path: 'browsing',
    ),
    TypedGoRoute<PrivacySecuritySettingsRoute>(
      name: 'PrivacySecuritySettingsRoute',
      path: 'privacy_security',
    ),
    TypedGoRoute<AppearanceLayoutSettingsRoute>(
      name: 'AppearanceLayoutSettingsRoute',
      path: 'appearance_layout',
    ),
    TypedGoRoute<SearchSettingsRoute>(
      name: 'SearchSettingsRoute',
      path: 'search',
    ),
    TypedGoRoute<ExtensionsSettingsRoute>(
      name: 'ExtensionsSettingsRoute',
      path: 'extensions',
    ),
    TypedGoRoute<AdvancedSettingsRoute>(
      name: 'AdvancedSettingsRoute',
      path: 'advanced',
    ),
    TypedGoRoute<WebEngineHardeningRoute>(
      name: 'WebEngineHardeningRoute',
      path: 'hardening',
      routes: [
        TypedGoRoute<WebEngineHardeningGroupRoute>(
          name: 'WebEngineHardeningGroupRoute',
          path: 'group/:group',
        ),
      ],
    ),
    TypedGoRoute<DohSettingsRoute>(name: 'DohSettingsRoute', path: 'doh'),
    TypedGoRoute<AddonCollectionRoute>(
      name: 'AddonCollectionRoute',
      path: 'addon_collection',
    ),
    TypedGoRoute<UBlockFilterListsRoute>(
      name: 'UBlockFilterListsRoute',
      path: 'ublock_filter_lists',
    ),
    TypedGoRoute<TrackingProtectionExceptionsRoute>(
      name: 'TrackingProtectionExceptionsRoute',
      path: 'tracking_protection_exceptions',
    ),
    TypedGoRoute<ErrorLogsRoute>(name: 'ErrorLogsRoute', path: 'error_logs'),
    TypedGoRoute<SyncSettingsRoute>(name: 'SyncSettingsRoute', path: 'sync'),
    TypedGoRoute<ContextualToolbarSettingsRoute>(
      name: 'ContextualToolbarSettingsRoute',
      path: 'contextual_toolbar',
    ),
    TypedGoRoute<MenuLayoutSettingsRoute>(
      name: 'MenuLayoutSettingsRoute',
      path: 'menu_layout',
    ),
    TypedGoRoute<QuickSwitcherToolbarSettingsRoute>(
      name: 'QuickSwitcherToolbarSettingsRoute',
      path: 'quick_switcher_toolbar',
    ),
    TypedGoRoute<DesktopModeSitesRoute>(
      name: 'DesktopModeSitesRoute',
      path: 'desktop_mode_sites',
    ),
  ],
)
class SettingsRoute extends GoRouteData with $SettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}

class GeneralSettingsRoute extends GoRouteData with $GeneralSettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const GeneralSettingsScreen();
  }
}

class SettingsTransferRoute extends GoRouteData with $SettingsTransferRoute {
  const SettingsTransferRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsTransferScreen();
  }
}

class BrowsingSettingsRoute extends GoRouteData with $BrowsingSettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const BrowsingSettingsScreen();
  }
}

class PrivacySecuritySettingsRoute extends GoRouteData
    with $PrivacySecuritySettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PrivacySecuritySettingsScreen();
  }
}

class AppearanceLayoutSettingsRoute extends GoRouteData
    with $AppearanceLayoutSettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AppearanceLayoutSettingsScreen();
  }
}

class SearchSettingsRoute extends GoRouteData with $SearchSettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SearchSettingsScreen();
  }
}

class ExtensionsSettingsRoute extends GoRouteData
    with $ExtensionsSettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ExtensionsSettingsScreen();
  }
}

class AdvancedSettingsRoute extends GoRouteData with $AdvancedSettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdvancedSettingsScreen();
  }
}

class DohSettingsRoute extends GoRouteData with $DohSettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DohSettingsScreen();
  }
}

class AddonCollectionRoute extends GoRouteData with $AddonCollectionRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AddonCollectionScreen();
  }
}

class UBlockFilterListsRoute extends GoRouteData with $UBlockFilterListsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UBlockFilterListsScreen();
  }
}

class WebEngineHardeningRoute extends GoRouteData
    with $WebEngineHardeningRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const WebEngineHardeningScreen();
  }
}

class WebEngineHardeningGroupRoute extends GoRouteData
    with $WebEngineHardeningGroupRoute {
  final String group;

  const WebEngineHardeningGroupRoute({required this.group});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return WebEngineHardeningGroupScreen(groupName: group);
  }
}

class TrackingProtectionExceptionsRoute extends GoRouteData
    with $TrackingProtectionExceptionsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TrackingProtectionExceptionsScreen();
  }
}

class ErrorLogsRoute extends GoRouteData with $ErrorLogsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ErrorLogsScreen();
  }
}

class SyncSettingsRoute extends GoRouteData with $SyncSettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SyncSettingsScreen();
  }
}

class ContextualToolbarSettingsRoute extends GoRouteData
    with $ContextualToolbarSettingsRoute {
  const ContextualToolbarSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ContextualToolbarSettingsScreen();
  }
}

class MenuLayoutSettingsRoute extends GoRouteData
    with $MenuLayoutSettingsRoute {
  const MenuLayoutSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MenuLayoutSettingsScreen();
  }
}

class QuickSwitcherToolbarSettingsRoute extends GoRouteData
    with $QuickSwitcherToolbarSettingsRoute {
  const QuickSwitcherToolbarSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ContextualToolbarSettingsScreen(
      location: ToolbarConfigLocation.quickSwitcher,
      title: 'Customize Switcher Buttons',
    );
  }
}

class DesktopModeSitesRoute extends GoRouteData with $DesktopModeSitesRoute {
  const DesktopModeSitesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DesktopModeSitesScreen();
  }
}
