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
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart'
    show AppLinksMode;
import 'package:json_annotation/json_annotation.dart';
import 'package:weblibre/features/app_links/domain/entities/app_link_rule.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/home_target.dart';
import 'package:weblibre/features/intent_gatekeeper/domain/entities/intent_source_policy.dart';
import 'package:weblibre/features/search/domain/entities/abstract/i_search_suggestion_provider.dart';
import 'package:weblibre/features/search/domain/services/search_provider_migration.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';

part 'general_settings.g.dart';

/// Id of the engine a user who never touched the setting searches with. A
/// literal rather than `fallbackSearchProvider.id` because a const initializer
/// cannot read a field off another const object.
///
/// Deliberately *not* [fallbackSearchProvider]: that const is the last-resort
/// engine for a stored id that resolves to nothing, and Wikipedia is the right
/// answer there precisely because it is inert. A profile that never made a
/// choice wants a general-purpose engine instead, and Brave is the one this
/// fork ships as its default — it is a real web index, it does not need an
/// account, and it is the same engine [_fallbackAutocompleteProvider] queries,
/// so suggestions and results come from one place.
const _fallbackSearchProvider = 'brave';
const _fallbackAutocompleteProvider = SearchSuggestionProviders.brave;

/// Max width (logical px) of the title text on a quick tab switcher chip.
/// The default of 64 sits at the 1/3 position of the slider scale.
const defaultQuickTabSwitcherTitleWidth = 64.0;
const minQuickTabSwitcherTitleWidth = 32.0;
const maxQuickTabSwitcherTitleWidth = 128.0;
const quickTabSwitcherTitleWidthStep = 8.0;

/// What a horizontal swipe on the tab bar used to do. The bar swipe steps
/// through spaces now; kept so stored profiles still decode.
@Deprecated('Retired; the bar swipe switches spaces')
enum TabBarSwipeAction { switchLastOpened, navigateOrderedTabs }

/// Row kind the retired stacking modes rendered. Kept so stored profiles
/// still decode.
@Deprecated('Retired; the bar has one layout')
enum QuickTabSwitcherMode { lastUsedTabs, containerTabs, spaceTabs }

/// Layout of the former quick tab switcher bar. Retired: the compact bar has
/// exactly one layout (the current space's chips) and the wide rail its own,
/// so [GeneralSettings.effectiveTabBarStackingMode] always answers
/// [spaceTabs]. Kept so stored profiles still decode.
@Deprecated('Retired; the bar has one layout')
enum TabBarStackingMode {
  lastUsedTabs,
  containerTabs,
  accordion,
  twoLevel,
  disabled,
  spaceTabs,
}

enum TabIntentOpenSetting { regular, private, ask }

/// Determines what happens when a bookmark is tapped in the bookmark list.
/// [ask] shows the "open in..." sheet (today's behavior, and the default);
/// the other values open the bookmark directly with no intermediate prompt.
enum BookmarkOpenSetting { regular, private, customTab, ask }

/// Edge of the compact tab bar on narrow viewports. Only [top] and [bottom]
/// place anything today: [left] and [right] are legacy values from when the
/// position setting alone decided between a bar and a side rail, kept so
/// stored profiles still decode; [GeneralSettings.effectiveTabBarPosition]
/// reads them as [bottom]. On wide viewports the layout is the side rail
/// regardless, docked per [RailSide].
enum TabBarPosition {
  top,
  bottom,
  left,
  right;

  /// Whether this is one of the legacy side-rail values.
  bool get isVertical =>
      this == TabBarPosition.left || this == TabBarPosition.right;

  /// Whether this places the compact bar (top/bottom).
  bool get isHorizontal => !isVertical;

  /// Main axis along which the bar's content flows.
  Axis get axis => isVertical ? Axis.vertical : Axis.horizontal;
}

enum TabBarLayout { withTitle, compact }

/// Which tab chips in the quick tab switcher and the tab bar carry a close
/// button.
///
/// [activeTabOnly] is the historic behavior: the chip the user is already on
/// can be closed in place, every other chip only through its long-press menu.
/// [all] puts a button on every chip and [never] on none — the last matters
/// once the active tab is on the bar at all (container-tabs stacking), where
/// the button sits right beside the chip the user taps to go back to it.
///
/// No mode removes a way to close a tab: the chip long-press menu and the tab
/// bar swipe action are untouched throughout. The narrow vertical rail has no
/// room for a close button beside an icon-only chip and behaves as [never]
/// whatever this says.
enum TabChipCloseButtonMode {
  activeTabOnly,
  all,
  never;

  /// Whether the chip for a tab shows its close button.
  bool showsFor({required bool isActive}) => switch (this) {
    TabChipCloseButtonMode.activeTabOnly => isActive,
    TabChipCloseButtonMode.all => true,
    TabChipCloseButtonMode.never => false,
  };
}

/// Where the browser home surface offers its entry into search.
///
/// The home surface has no address field of its own, so exactly one of these
/// two has to be present: the pinned pill at the top of the home content, or
/// the tab bar's own (empty) address field — the behaviour that predates the
/// home surface. [auto] picks whichever sits on the same edge the user already
/// chose for the tab bar, so a bottom tab bar keeps the search entry within
/// thumb reach instead of moving it to the top of the screen.
enum HomeSearchBarPlacement {
  auto,
  top,
  tabBar;

  String get label => switch (this) {
    auto => 'Follow the tab bar',
    top => 'Top of the home page',
    tabBar => 'In the tab bar',
  };

  String get description => switch (this) {
    auto => 'Whichever edge the tab bar is on',
    top => 'A pinned search bar above the home sections',
    tabBar => "The tab bar's address field, with QR and voice search",
  };
}

enum DeleteBrowsingDataType {
  tabs('Open tabs'),
  history('Browsing history'),
  recentSearches('Recent searches', 'Queries shown on the search page'),
  cookies('Cookies and site data', 'You’ll be logged out of most sites'),
  cache('Cached images and files', 'Frees up storage space'),
  permissions('Site permissions'),
  downloads('Downloads');

  final String title;
  final String? description;

  const DeleteBrowsingDataType(this.title, [this.description]);
}

@CopyWith()
@JsonSerializable(includeIfNull: true, constructor: 'withDefaults')
class GeneralSettings with FastEquatable {
  final ThemeMode themeMode;
  final Set<DeleteBrowsingDataType>? deleteBrowsingDataOnQuit;
  /// Id of the [SearchProvider] typed queries are sent to.
  ///
  /// Read through [SearchProviderIdConverter], which also translates the
  /// `group::trigger` bang keys older installs stored here.
  @SearchProviderIdConverter()
  final String? defaultSearchProvider;

  final SearchSuggestionProviders defaultSearchSuggestionsProvider;
  final bool showContainerUi;

  /// What to land on when there is no tab to show at cold start.
  final HomeTarget homeTarget;

  /// Address opened when [homeTarget] is [HomeTarget.customUrl]. An unset or
  /// unparseable value falls back to the home surface.
  final String? homeTargetUrl;

  /// Where the home surface's search entry is rendered. See
  /// [HomeSearchBarPlacement] and [effectiveHomeSearchBarPlacement].
  final HomeSearchBarPlacement homeSearchBarPlacement;

  @JsonKey(unknownEnumValue: TabIntentOpenSetting.regular)
  final TabIntentOpenSetting tabIntentOpenSetting;

  /// Determines what happens when a bookmark is tapped. See
  /// [BookmarkOpenSetting] and [effectiveBookmarkOpenSetting].
  @JsonKey(unknownEnumValue: BookmarkOpenSetting.regular)
  final BookmarkOpenSetting bookmarkOpenSetting;

  final bool autoHideTabBar;
  @Deprecated('Retired; the bar swipe switches spaces')
  // ignore: deprecated_member_use_from_same_package
  final TabBarSwipeAction tabBarSwipeAction;

  final Duration historyAutoCleanInterval;
  final bool tabBarShowContextualBar;
  final TabBarPosition tabBarPosition;
  final TabBarLayout tabBarLayout;
  @Deprecated('Retired; the bar has one layout')
  // ignore: deprecated_member_use_from_same_package
  final TabBarStackingMode tabBarStackingMode;
  final Duration unassignedTabsAutoCleanInterval;
  final bool tabListShowFavicons;
  final bool quickTabSwitcherShowTitles;
  final bool quickTabSwitcherShowHistorySuggestions;

  /// Max width (logical px) for chip titles in the quick tab switcher.
  final double quickTabSwitcherTitleWidth;

  final String syncServerOverride;
  final String syncTokenServerOverride;
  final bool tabBarLongPressUrlCopy;
  final bool allowNonManifestPwaInstall;
  final bool blockExternalAppsEnabled;
  final Map<String, IntentSourcePolicy> externalAppIntentPolicies;

  /// Whether external Custom Tab intents (and URLs shared into WebLibre) open
  /// in a lightweight custom-tab activity. When false, they open as normal
  /// tabs in the main browser instead. Read natively by `IntentReceiverActivity`
  /// via the intent gatekeeper prefs bridge. Defaults to true.
  final bool customTabsEnabled;

  /// Global app-links behaviour: always open in native apps, ask each time, or
  /// never leave the browser. Defaults to [AppLinksMode.ask]. Per-site rules in
  /// [appLinkRules] and container/proxy protection can override this per-target.
  final AppLinksMode appLinksMode;

  /// Remembered per-scope app-link rules, keyed by canonical scope
  /// (`host:youtube.com` | `pkg:...`). One rule per scope, last write wins.
  /// Malformed entries are dropped on read (see [parseAppLinkRules]).
  @JsonKey(fromJson: parseAppLinkRules)
  final Map<String, PersistedAppLinkRule> appLinkRules;

  /// Whether dark mode should use pure-black ("OLED"/high-contrast) surfaces.
  /// Only takes effect when the effective brightness is dark. Defaults to false.
  final bool pureBlack;

  /// Browser-wide default desktop mode. When true, newly opened tabs request
  /// the desktop version of sites by default. The per-tab desktop-mode toggle
  /// still overrides this for an individual tab. Defaults to false.
  final bool globalDesktopMode;

  /// Hosts that should always load in desktop mode. A tab navigating to a
  /// matching host (or any of its subdomains) is switched to desktop mode,
  /// overriding [globalDesktopMode] for that visit. See `hostMatchesRule`.
  final List<String> desktopModeSites;

  /// Developer setting: when true, the GeckoView is unmounted whenever a
  /// full-cover route (settings, tab tray, search, …) is on top, freeing the
  /// engine's resources while it is occluded. On Android 12 and lower (API
  /// <= 31) this behavior is always applied to work around a native
  /// visibility bug; on Android 13+ the engine normally stays mounted to
  /// avoid reload/flicker, and this flag opts into the off-route unmounting
  /// there too. Defaults to false.
  ///
  /// It is not the answer to a stale engine surface left on top of an overlay:
  /// unmounting only hid that by destroying the platform view, and never
  /// covered the home surface, which does not unmount at all. `GeckoView`
  /// handles that wherever it happens now — see `GeckoView.isPainted` — so what
  /// is left here is the memory trade this describes.
  final bool unmountGeckoViewOffRoute;

  GeneralSettings({
    required this.themeMode,
    required this.deleteBrowsingDataOnQuit,
    required this.defaultSearchProvider,
    required this.defaultSearchSuggestionsProvider,
    required this.showContainerUi,
    required this.homeTarget,
    required this.homeTargetUrl,
    required this.homeSearchBarPlacement,
    required this.tabIntentOpenSetting,
    required this.bookmarkOpenSetting,
    required this.autoHideTabBar,
    @Deprecated('Retired; the bar swipe switches spaces')
    // ignore: deprecated_member_use_from_same_package
    required this.tabBarSwipeAction,
    required this.historyAutoCleanInterval,
    required this.tabBarShowContextualBar,
    required this.tabBarPosition,
    required this.tabBarLayout,
    @Deprecated('Retired; the bar has one layout')
    // ignore: deprecated_member_use_from_same_package
    required this.tabBarStackingMode,
    required this.unassignedTabsAutoCleanInterval,
    required this.tabListShowFavicons,
    required this.quickTabSwitcherShowTitles,
    required this.quickTabSwitcherShowHistorySuggestions,
    required this.quickTabSwitcherTitleWidth,
    required this.syncServerOverride,
    required this.syncTokenServerOverride,
    required this.tabBarLongPressUrlCopy,
    required this.allowNonManifestPwaInstall,
    required this.blockExternalAppsEnabled,
    required this.externalAppIntentPolicies,
    required this.customTabsEnabled,
    required this.appLinksMode,
    required this.appLinkRules,
    required this.pureBlack,
    required this.globalDesktopMode,
    required this.desktopModeSites,
    required this.unmountGeckoViewOffRoute,
  });

  GeneralSettings.withDefaults({
    ThemeMode? themeMode,
    this.deleteBrowsingDataOnQuit,
    String? defaultSearchProvider,
    SearchSuggestionProviders? defaultSearchSuggestionsProvider,
    bool? showContainerUi,
    HomeTarget? homeTarget,
    this.homeTargetUrl,
    HomeSearchBarPlacement? homeSearchBarPlacement,
    TabIntentOpenSetting? tabIntentOpenSetting,
    BookmarkOpenSetting? bookmarkOpenSetting,
    bool? autoHideTabBar,
    // ignore: deprecated_member_use_from_same_package
    TabBarSwipeAction? tabBarSwipeAction,
    Duration? historyAutoCleanInterval,
    bool? tabBarShowContextualBar,
    TabBarPosition? tabBarPosition,
    TabBarLayout? tabBarLayout,
    // ignore: deprecated_member_use_from_same_package
    TabBarStackingMode? tabBarStackingMode,
    Duration? unassignedTabsAutoCleanInterval,
    bool? tabListShowFavicons,
    bool? quickTabSwitcherShowTitles,
    bool? quickTabSwitcherShowHistorySuggestions,
    double? quickTabSwitcherTitleWidth,
    String? syncServerOverride,
    String? syncTokenServerOverride,
    bool? tabBarLongPressUrlCopy,
    bool? allowNonManifestPwaInstall,
    bool? blockExternalAppsEnabled,
    Map<String, IntentSourcePolicy>? externalAppIntentPolicies,
    bool? customTabsEnabled,
    AppLinksMode? appLinksMode,
    Map<String, PersistedAppLinkRule>? appLinkRules,
    bool? pureBlack,
    bool? globalDesktopMode,
    List<String>? desktopModeSites,
    bool? unmountGeckoViewOffRoute,
  }) : themeMode = themeMode ?? ThemeMode.dark,
       defaultSearchProvider = defaultSearchProvider ?? _fallbackSearchProvider,
       defaultSearchSuggestionsProvider =
           defaultSearchSuggestionsProvider ?? _fallbackAutocompleteProvider,
       showContainerUi = showContainerUi ?? true,
       // Defaults to `home`, which is exactly what the browser did before this
       // setting existed. Anything else would change startup for every user.
       homeTarget = homeTarget ?? HomeTarget.home,
       // Deliberately not a fixed edge: the placement that matches the user's
       // tab bar position is the one they can reach.
       homeSearchBarPlacement =
           homeSearchBarPlacement ?? HomeSearchBarPlacement.auto,
       tabIntentOpenSetting = tabIntentOpenSetting ?? TabIntentOpenSetting.ask,
       bookmarkOpenSetting = bookmarkOpenSetting ?? BookmarkOpenSetting.ask,
       autoHideTabBar = autoHideTabBar ?? true,
       // ignore: deprecated_member_use_from_same_package
       tabBarSwipeAction =
           // ignore: deprecated_member_use_from_same_package
           tabBarSwipeAction ?? TabBarSwipeAction.switchLastOpened,
       historyAutoCleanInterval =
           historyAutoCleanInterval ?? const Duration(days: 90),
       tabBarShowContextualBar = tabBarShowContextualBar ?? true,
       tabBarPosition = tabBarPosition ?? TabBarPosition.bottom,
       tabBarLayout = tabBarLayout ?? TabBarLayout.compact,
       // ignore: deprecated_member_use_from_same_package
       tabBarStackingMode =
           // ignore: deprecated_member_use_from_same_package
           tabBarStackingMode ?? TabBarStackingMode.accordion,
       unassignedTabsAutoCleanInterval =
           unassignedTabsAutoCleanInterval ?? Duration.zero,
       tabListShowFavicons = tabListShowFavicons ?? false,
       quickTabSwitcherShowTitles = quickTabSwitcherShowTitles ?? true,
       quickTabSwitcherShowHistorySuggestions =
           quickTabSwitcherShowHistorySuggestions ?? true,
       quickTabSwitcherTitleWidth =
           quickTabSwitcherTitleWidth ?? defaultQuickTabSwitcherTitleWidth,
       syncServerOverride = syncServerOverride ?? '',
       syncTokenServerOverride = syncTokenServerOverride ?? '',
       tabBarLongPressUrlCopy = tabBarLongPressUrlCopy ?? true,
       allowNonManifestPwaInstall = allowNonManifestPwaInstall ?? false,
       blockExternalAppsEnabled = blockExternalAppsEnabled ?? false,
       externalAppIntentPolicies = externalAppIntentPolicies ?? const {},
       customTabsEnabled = customTabsEnabled ?? true,
       appLinksMode = appLinksMode ?? AppLinksMode.ask,
       appLinkRules = appLinkRules ?? const {},
       pureBlack = pureBlack ?? false,
       globalDesktopMode = globalDesktopMode ?? false,
       desktopModeSites = desktopModeSites ?? const [],
       unmountGeckoViewOffRoute = unmountGeckoViewOffRoute ?? false;

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    // The isolated tab mode was removed; map any previously persisted
    // `isolated` values for these settings back to `regular` so old profiles
    // still decode.
    // TODO: Drop this fallback once enough releases have shipped that
    // rolling back to a version with isolated tabs is no longer a concern.
    for (final key in const ['tabIntentOpenSetting', 'bookmarkOpenSetting']) {
      if (json[key] == 'isolated') {
        json[key] = 'regular';
      }
    }

    // Migrate the legacy `tabBarShowQuickTabSwitcherBar` toggle and
    // `quickTabSwitcherMode` selection to the merged `tabBarStackingMode`.
    // The legacy mode names are a subset of the new enum's, so values map
    // verbatim.
    // TODO: Drop this fallback (and the legacy rows in the user settings DB)
    // once enough releases have shipped that rolling back to a version
    // without `tabBarStackingMode` is no longer a concern.
    final legacyShowSwitcherBar = json['tabBarShowQuickTabSwitcherBar'];
    final legacySwitcherMode = json['quickTabSwitcherMode'];
    if (json['tabBarStackingMode'] == null) {
      if (legacyShowSwitcherBar == false) {
        json['tabBarStackingMode'] = 'disabled';
      } else if (legacySwitcherMode != null) {
        json['tabBarStackingMode'] = legacySwitcherMode;
      }
    }

    return _$GeneralSettingsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$GeneralSettingsToJson(this);

  TabIntentOpenSetting get effectiveTabIntentOpenSetting =>
      tabIntentOpenSetting;

  BookmarkOpenSetting get effectiveBookmarkOpenSetting => bookmarkOpenSetting;

  /// [homeSearchBarPlacement] with [HomeSearchBarPlacement.auto] resolved
  /// against the tab bar's position, so callers never have to. Never returns
  /// [HomeSearchBarPlacement.auto].
  ///
  /// Only a bottom tab bar resolves to [HomeSearchBarPlacement.tabBar]: a top
  /// bar puts its address field next to the pill's own position anyway, and on
  /// the vertical side rail the address field is rotated 90 degrees, which is
  /// a poor search entry to hand someone as their only one.
  HomeSearchBarPlacement effectiveHomeSearchBarPlacement() =>
      switch (homeSearchBarPlacement) {
        HomeSearchBarPlacement.auto =>
          effectiveTabBarPosition == TabBarPosition.bottom
              ? HomeSearchBarPlacement.tabBar
              : HomeSearchBarPlacement.top,
        final placement => placement,
      };

  /// Where the compact bar sits on a narrow viewport: [tabBarPosition]
  /// reduced to top or bottom. The legacy side values predate the
  /// viewport-driven layout and read as [TabBarPosition.bottom].
  TabBarPosition get effectiveTabBarPosition =>
      tabBarPosition == TabBarPosition.top
      ? TabBarPosition.top
      : TabBarPosition.bottom;

  /// The bar has one layout: the current space's chips
  /// ([TabBarStackingMode.spaceTabs]), whatever the retired setting stored.
  // ignore: deprecated_member_use_from_same_package
  TabBarStackingMode effectiveTabBarStackingMode() =>
      // ignore: deprecated_member_use_from_same_package
      TabBarStackingMode.spaceTabs;

  @override
  List<Object?> get hashParameters => [
    themeMode,
    deleteBrowsingDataOnQuit,
    defaultSearchProvider,
    defaultSearchSuggestionsProvider,
    showContainerUi,
    homeTarget,
    homeTargetUrl,
    homeSearchBarPlacement,
    tabIntentOpenSetting,
    bookmarkOpenSetting,
    autoHideTabBar,
    // ignore: deprecated_member_use_from_same_package
    tabBarSwipeAction,
    historyAutoCleanInterval,
    tabBarShowContextualBar,
    tabBarPosition,
    tabBarLayout,
    // ignore: deprecated_member_use_from_same_package
    tabBarStackingMode,
    unassignedTabsAutoCleanInterval,
    tabListShowFavicons,
    quickTabSwitcherShowTitles,
    quickTabSwitcherShowHistorySuggestions,
    quickTabSwitcherTitleWidth,
    syncServerOverride,
    syncTokenServerOverride,
    tabBarLongPressUrlCopy,
    allowNonManifestPwaInstall,
    blockExternalAppsEnabled,
    externalAppIntentPolicies,
    customTabsEnabled,
    appLinksMode,
    appLinkRules,
    pureBlack,
    globalDesktopMode,
    desktopModeSites,
    unmountGeckoViewOffRoute,
  ];
}
