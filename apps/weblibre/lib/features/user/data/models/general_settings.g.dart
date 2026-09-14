// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'general_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GeneralSettingsCWProxy {
  GeneralSettings themeMode(ThemeMode themeMode);

  GeneralSettings deleteBrowsingDataOnQuit(
    Set<DeleteBrowsingDataType>? deleteBrowsingDataOnQuit,
  );

  GeneralSettings screenshotProtectionEnabled(bool screenshotProtectionEnabled);

  GeneralSettings allowPrivateTabScreenshots(bool allowPrivateTabScreenshots);

  GeneralSettings defaultSearchProvider(String? defaultSearchProvider);

  GeneralSettings defaultSearchSuggestionsProvider(
    SearchSuggestionProviders defaultSearchSuggestionsProvider,
  );

  GeneralSettings showContainerUi(bool showContainerUi);

  GeneralSettings homeTarget(HomeTarget homeTarget);

  GeneralSettings homeTargetUrl(String? homeTargetUrl);

  GeneralSettings homeTargetOnLastTabClosed(bool homeTargetOnLastTabClosed);

  GeneralSettings homeSearchBarPlacement(
    HomeSearchBarPlacement homeSearchBarPlacement,
  );

  GeneralSettings tabIntentOpenSetting(
    TabIntentOpenSetting tabIntentOpenSetting,
  );

  GeneralSettings bookmarkOpenSetting(BookmarkOpenSetting bookmarkOpenSetting);

  GeneralSettings autoHideTabBar(bool autoHideTabBar);

  GeneralSettings tabBarSwipeAction(
    @Deprecated('Retired; the bar swipe switches spaces')
    TabBarSwipeAction tabBarSwipeAction,
  );

  GeneralSettings historyAutoCleanInterval(Duration historyAutoCleanInterval);

  GeneralSettings tabBarShowContextualBar(bool tabBarShowContextualBar);

  GeneralSettings tabBarPosition(TabBarPosition tabBarPosition);

  GeneralSettings tabBarLayout(TabBarLayout tabBarLayout);

  GeneralSettings tabBarStackingMode(
    @Deprecated('Retired; the bar has one layout')
    TabBarStackingMode tabBarStackingMode,
  );

  GeneralSettings unassignedTabsAutoCleanInterval(
    Duration unassignedTabsAutoCleanInterval,
  );

  GeneralSettings maxSearchHistoryEntries(int maxSearchHistoryEntries);

  GeneralSettings allowClipboardAccess(bool allowClipboardAccess);

  GeneralSettings tabListShowFavicons(bool tabListShowFavicons);

  GeneralSettings quickTabSwitcherShowTitles(bool quickTabSwitcherShowTitles);

  GeneralSettings quickTabSwitcherShowHistorySuggestions(
    bool quickTabSwitcherShowHistorySuggestions,
  );

  GeneralSettings quickTabSwitcherTitleWidth(double quickTabSwitcherTitleWidth);

  GeneralSettings syncServerOverride(String syncServerOverride);

  GeneralSettings syncTokenServerOverride(String syncTokenServerOverride);

  GeneralSettings tabBarLongPressUrlCopy(bool tabBarLongPressUrlCopy);

  GeneralSettings allowNonManifestPwaInstall(bool allowNonManifestPwaInstall);

  GeneralSettings blockExternalAppsEnabled(bool blockExternalAppsEnabled);

  GeneralSettings externalAppIntentPolicies(
    Map<String, IntentSourcePolicy> externalAppIntentPolicies,
  );

  GeneralSettings customTabsEnabled(bool customTabsEnabled);

  GeneralSettings appLinksMode(AppLinksMode appLinksMode);

  GeneralSettings appLinkRules(Map<String, PersistedAppLinkRule> appLinkRules);

  GeneralSettings enableLocalSearchIndex(bool enableLocalSearchIndex);

  GeneralSettings indexPrivateTabs(bool indexPrivateTabs);

  GeneralSettings acceptSuggestionOnSubmit(bool acceptSuggestionOnSubmit);

  GeneralSettings pureBlack(bool pureBlack);

  GeneralSettings globalDesktopMode(bool globalDesktopMode);

  GeneralSettings desktopModeSites(List<String> desktopModeSites);

  GeneralSettings unmountGeckoViewOffRoute(bool unmountGeckoViewOffRoute);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GeneralSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GeneralSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  GeneralSettings call({
    ThemeMode themeMode,
    Set<DeleteBrowsingDataType>? deleteBrowsingDataOnQuit,
    bool screenshotProtectionEnabled,
    bool allowPrivateTabScreenshots,
    String? defaultSearchProvider,
    SearchSuggestionProviders defaultSearchSuggestionsProvider,
    bool showContainerUi,
    HomeTarget homeTarget,
    String? homeTargetUrl,
    bool homeTargetOnLastTabClosed,
    HomeSearchBarPlacement homeSearchBarPlacement,
    TabIntentOpenSetting tabIntentOpenSetting,
    BookmarkOpenSetting bookmarkOpenSetting,
    bool autoHideTabBar,
    @Deprecated('Retired; the bar swipe switches spaces')
    TabBarSwipeAction tabBarSwipeAction,
    Duration historyAutoCleanInterval,
    bool tabBarShowContextualBar,
    TabBarPosition tabBarPosition,
    TabBarLayout tabBarLayout,
    @Deprecated('Retired; the bar has one layout')
    TabBarStackingMode tabBarStackingMode,
    Duration unassignedTabsAutoCleanInterval,
    int maxSearchHistoryEntries,
    bool allowClipboardAccess,
    bool tabListShowFavicons,
    bool quickTabSwitcherShowTitles,
    bool quickTabSwitcherShowHistorySuggestions,
    double quickTabSwitcherTitleWidth,
    String syncServerOverride,
    String syncTokenServerOverride,
    bool tabBarLongPressUrlCopy,
    bool allowNonManifestPwaInstall,
    bool blockExternalAppsEnabled,
    Map<String, IntentSourcePolicy> externalAppIntentPolicies,
    bool customTabsEnabled,
    AppLinksMode appLinksMode,
    Map<String, PersistedAppLinkRule> appLinkRules,
    bool enableLocalSearchIndex,
    bool indexPrivateTabs,
    bool acceptSuggestionOnSubmit,
    bool pureBlack,
    bool globalDesktopMode,
    List<String> desktopModeSites,
    bool unmountGeckoViewOffRoute,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGeneralSettings.copyWith(...)` or call `instanceOfGeneralSettings.copyWith.fieldName(value)` for a single field.
class _$GeneralSettingsCWProxyImpl implements _$GeneralSettingsCWProxy {
  const _$GeneralSettingsCWProxyImpl(this._value);

  final GeneralSettings _value;

  @override
  GeneralSettings themeMode(ThemeMode themeMode) => call(themeMode: themeMode);

  @override
  GeneralSettings deleteBrowsingDataOnQuit(
    Set<DeleteBrowsingDataType>? deleteBrowsingDataOnQuit,
  ) => call(deleteBrowsingDataOnQuit: deleteBrowsingDataOnQuit);

  @override
  GeneralSettings screenshotProtectionEnabled(
    bool screenshotProtectionEnabled,
  ) => call(screenshotProtectionEnabled: screenshotProtectionEnabled);

  @override
  GeneralSettings allowPrivateTabScreenshots(bool allowPrivateTabScreenshots) =>
      call(allowPrivateTabScreenshots: allowPrivateTabScreenshots);

  @override
  GeneralSettings defaultSearchProvider(String? defaultSearchProvider) =>
      call(defaultSearchProvider: defaultSearchProvider);

  @override
  GeneralSettings defaultSearchSuggestionsProvider(
    SearchSuggestionProviders defaultSearchSuggestionsProvider,
  ) => call(defaultSearchSuggestionsProvider: defaultSearchSuggestionsProvider);

  @override
  GeneralSettings showContainerUi(bool showContainerUi) =>
      call(showContainerUi: showContainerUi);

  @override
  GeneralSettings homeTarget(HomeTarget homeTarget) =>
      call(homeTarget: homeTarget);

  @override
  GeneralSettings homeTargetUrl(String? homeTargetUrl) =>
      call(homeTargetUrl: homeTargetUrl);

  @override
  GeneralSettings homeTargetOnLastTabClosed(bool homeTargetOnLastTabClosed) =>
      call(homeTargetOnLastTabClosed: homeTargetOnLastTabClosed);

  @override
  GeneralSettings homeSearchBarPlacement(
    HomeSearchBarPlacement homeSearchBarPlacement,
  ) => call(homeSearchBarPlacement: homeSearchBarPlacement);

  @override
  GeneralSettings tabIntentOpenSetting(
    TabIntentOpenSetting tabIntentOpenSetting,
  ) => call(tabIntentOpenSetting: tabIntentOpenSetting);

  @override
  GeneralSettings bookmarkOpenSetting(
    BookmarkOpenSetting bookmarkOpenSetting,
  ) => call(bookmarkOpenSetting: bookmarkOpenSetting);

  @override
  GeneralSettings autoHideTabBar(bool autoHideTabBar) =>
      call(autoHideTabBar: autoHideTabBar);

  @override
  GeneralSettings tabBarSwipeAction(
    @Deprecated('Retired; the bar swipe switches spaces')
    TabBarSwipeAction tabBarSwipeAction,
  ) => call(tabBarSwipeAction: tabBarSwipeAction);

  @override
  GeneralSettings historyAutoCleanInterval(Duration historyAutoCleanInterval) =>
      call(historyAutoCleanInterval: historyAutoCleanInterval);

  @override
  GeneralSettings tabBarShowContextualBar(bool tabBarShowContextualBar) =>
      call(tabBarShowContextualBar: tabBarShowContextualBar);

  @override
  GeneralSettings tabBarPosition(TabBarPosition tabBarPosition) =>
      call(tabBarPosition: tabBarPosition);

  @override
  GeneralSettings tabBarLayout(TabBarLayout tabBarLayout) =>
      call(tabBarLayout: tabBarLayout);

  @override
  GeneralSettings tabBarStackingMode(
    @Deprecated('Retired; the bar has one layout')
    TabBarStackingMode tabBarStackingMode,
  ) => call(tabBarStackingMode: tabBarStackingMode);

  @override
  GeneralSettings unassignedTabsAutoCleanInterval(
    Duration unassignedTabsAutoCleanInterval,
  ) => call(unassignedTabsAutoCleanInterval: unassignedTabsAutoCleanInterval);

  @override
  GeneralSettings maxSearchHistoryEntries(int maxSearchHistoryEntries) =>
      call(maxSearchHistoryEntries: maxSearchHistoryEntries);

  @override
  GeneralSettings allowClipboardAccess(bool allowClipboardAccess) =>
      call(allowClipboardAccess: allowClipboardAccess);

  @override
  GeneralSettings tabListShowFavicons(bool tabListShowFavicons) =>
      call(tabListShowFavicons: tabListShowFavicons);

  @override
  GeneralSettings quickTabSwitcherShowTitles(bool quickTabSwitcherShowTitles) =>
      call(quickTabSwitcherShowTitles: quickTabSwitcherShowTitles);

  @override
  GeneralSettings quickTabSwitcherShowHistorySuggestions(
    bool quickTabSwitcherShowHistorySuggestions,
  ) => call(
    quickTabSwitcherShowHistorySuggestions:
        quickTabSwitcherShowHistorySuggestions,
  );

  @override
  GeneralSettings quickTabSwitcherTitleWidth(
    double quickTabSwitcherTitleWidth,
  ) => call(quickTabSwitcherTitleWidth: quickTabSwitcherTitleWidth);

  @override
  GeneralSettings syncServerOverride(String syncServerOverride) =>
      call(syncServerOverride: syncServerOverride);

  @override
  GeneralSettings syncTokenServerOverride(String syncTokenServerOverride) =>
      call(syncTokenServerOverride: syncTokenServerOverride);

  @override
  GeneralSettings tabBarLongPressUrlCopy(bool tabBarLongPressUrlCopy) =>
      call(tabBarLongPressUrlCopy: tabBarLongPressUrlCopy);

  @override
  GeneralSettings allowNonManifestPwaInstall(bool allowNonManifestPwaInstall) =>
      call(allowNonManifestPwaInstall: allowNonManifestPwaInstall);

  @override
  GeneralSettings blockExternalAppsEnabled(bool blockExternalAppsEnabled) =>
      call(blockExternalAppsEnabled: blockExternalAppsEnabled);

  @override
  GeneralSettings externalAppIntentPolicies(
    Map<String, IntentSourcePolicy> externalAppIntentPolicies,
  ) => call(externalAppIntentPolicies: externalAppIntentPolicies);

  @override
  GeneralSettings customTabsEnabled(bool customTabsEnabled) =>
      call(customTabsEnabled: customTabsEnabled);

  @override
  GeneralSettings appLinksMode(AppLinksMode appLinksMode) =>
      call(appLinksMode: appLinksMode);

  @override
  GeneralSettings appLinkRules(
    Map<String, PersistedAppLinkRule> appLinkRules,
  ) => call(appLinkRules: appLinkRules);

  @override
  GeneralSettings enableLocalSearchIndex(bool enableLocalSearchIndex) =>
      call(enableLocalSearchIndex: enableLocalSearchIndex);

  @override
  GeneralSettings indexPrivateTabs(bool indexPrivateTabs) =>
      call(indexPrivateTabs: indexPrivateTabs);

  @override
  GeneralSettings acceptSuggestionOnSubmit(bool acceptSuggestionOnSubmit) =>
      call(acceptSuggestionOnSubmit: acceptSuggestionOnSubmit);

  @override
  GeneralSettings pureBlack(bool pureBlack) => call(pureBlack: pureBlack);

  @override
  GeneralSettings globalDesktopMode(bool globalDesktopMode) =>
      call(globalDesktopMode: globalDesktopMode);

  @override
  GeneralSettings desktopModeSites(List<String> desktopModeSites) =>
      call(desktopModeSites: desktopModeSites);

  @override
  GeneralSettings unmountGeckoViewOffRoute(bool unmountGeckoViewOffRoute) =>
      call(unmountGeckoViewOffRoute: unmountGeckoViewOffRoute);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GeneralSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GeneralSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GeneralSettings call({
    Object? themeMode = const $CopyWithPlaceholder(),
    Object? deleteBrowsingDataOnQuit = const $CopyWithPlaceholder(),
    Object? screenshotProtectionEnabled = const $CopyWithPlaceholder(),
    Object? allowPrivateTabScreenshots = const $CopyWithPlaceholder(),
    Object? defaultSearchProvider = const $CopyWithPlaceholder(),
    Object? defaultSearchSuggestionsProvider = const $CopyWithPlaceholder(),
    Object? showContainerUi = const $CopyWithPlaceholder(),
    Object? homeTarget = const $CopyWithPlaceholder(),
    Object? homeTargetUrl = const $CopyWithPlaceholder(),
    Object? homeTargetOnLastTabClosed = const $CopyWithPlaceholder(),
    Object? homeSearchBarPlacement = const $CopyWithPlaceholder(),
    Object? tabIntentOpenSetting = const $CopyWithPlaceholder(),
    Object? bookmarkOpenSetting = const $CopyWithPlaceholder(),
    Object? autoHideTabBar = const $CopyWithPlaceholder(),
    @Deprecated('Retired; the bar swipe switches spaces')
    Object? tabBarSwipeAction = const $CopyWithPlaceholder(),
    Object? historyAutoCleanInterval = const $CopyWithPlaceholder(),
    Object? tabBarShowContextualBar = const $CopyWithPlaceholder(),
    Object? tabBarPosition = const $CopyWithPlaceholder(),
    Object? tabBarLayout = const $CopyWithPlaceholder(),
    @Deprecated('Retired; the bar has one layout')
    Object? tabBarStackingMode = const $CopyWithPlaceholder(),
    Object? unassignedTabsAutoCleanInterval = const $CopyWithPlaceholder(),
    Object? maxSearchHistoryEntries = const $CopyWithPlaceholder(),
    Object? allowClipboardAccess = const $CopyWithPlaceholder(),
    Object? tabListShowFavicons = const $CopyWithPlaceholder(),
    Object? quickTabSwitcherShowTitles = const $CopyWithPlaceholder(),
    Object? quickTabSwitcherShowHistorySuggestions =
        const $CopyWithPlaceholder(),
    Object? quickTabSwitcherTitleWidth = const $CopyWithPlaceholder(),
    Object? syncServerOverride = const $CopyWithPlaceholder(),
    Object? syncTokenServerOverride = const $CopyWithPlaceholder(),
    Object? tabBarLongPressUrlCopy = const $CopyWithPlaceholder(),
    Object? allowNonManifestPwaInstall = const $CopyWithPlaceholder(),
    Object? blockExternalAppsEnabled = const $CopyWithPlaceholder(),
    Object? externalAppIntentPolicies = const $CopyWithPlaceholder(),
    Object? customTabsEnabled = const $CopyWithPlaceholder(),
    Object? appLinksMode = const $CopyWithPlaceholder(),
    Object? appLinkRules = const $CopyWithPlaceholder(),
    Object? enableLocalSearchIndex = const $CopyWithPlaceholder(),
    Object? indexPrivateTabs = const $CopyWithPlaceholder(),
    Object? acceptSuggestionOnSubmit = const $CopyWithPlaceholder(),
    Object? pureBlack = const $CopyWithPlaceholder(),
    Object? globalDesktopMode = const $CopyWithPlaceholder(),
    Object? desktopModeSites = const $CopyWithPlaceholder(),
    Object? unmountGeckoViewOffRoute = const $CopyWithPlaceholder(),
  }) {
    return GeneralSettings(
      themeMode: themeMode == const $CopyWithPlaceholder() || themeMode == null
          ? _value.themeMode
          // ignore: cast_nullable_to_non_nullable
          : themeMode as ThemeMode,
      deleteBrowsingDataOnQuit:
          deleteBrowsingDataOnQuit == const $CopyWithPlaceholder()
          ? _value.deleteBrowsingDataOnQuit
          // ignore: cast_nullable_to_non_nullable
          : deleteBrowsingDataOnQuit as Set<DeleteBrowsingDataType>?,
      screenshotProtectionEnabled:
          screenshotProtectionEnabled == const $CopyWithPlaceholder() ||
              screenshotProtectionEnabled == null
          ? _value.screenshotProtectionEnabled
          // ignore: cast_nullable_to_non_nullable
          : screenshotProtectionEnabled as bool,
      allowPrivateTabScreenshots:
          allowPrivateTabScreenshots == const $CopyWithPlaceholder() ||
              allowPrivateTabScreenshots == null
          ? _value.allowPrivateTabScreenshots
          // ignore: cast_nullable_to_non_nullable
          : allowPrivateTabScreenshots as bool,
      defaultSearchProvider:
          defaultSearchProvider == const $CopyWithPlaceholder()
          ? _value.defaultSearchProvider
          // ignore: cast_nullable_to_non_nullable
          : defaultSearchProvider as String?,
      defaultSearchSuggestionsProvider:
          defaultSearchSuggestionsProvider == const $CopyWithPlaceholder() ||
              defaultSearchSuggestionsProvider == null
          ? _value.defaultSearchSuggestionsProvider
          // ignore: cast_nullable_to_non_nullable
          : defaultSearchSuggestionsProvider as SearchSuggestionProviders,
      showContainerUi:
          showContainerUi == const $CopyWithPlaceholder() ||
              showContainerUi == null
          ? _value.showContainerUi
          // ignore: cast_nullable_to_non_nullable
          : showContainerUi as bool,
      homeTarget:
          homeTarget == const $CopyWithPlaceholder() || homeTarget == null
          ? _value.homeTarget
          // ignore: cast_nullable_to_non_nullable
          : homeTarget as HomeTarget,
      homeTargetUrl: homeTargetUrl == const $CopyWithPlaceholder()
          ? _value.homeTargetUrl
          // ignore: cast_nullable_to_non_nullable
          : homeTargetUrl as String?,
      homeTargetOnLastTabClosed:
          homeTargetOnLastTabClosed == const $CopyWithPlaceholder() ||
              homeTargetOnLastTabClosed == null
          ? _value.homeTargetOnLastTabClosed
          // ignore: cast_nullable_to_non_nullable
          : homeTargetOnLastTabClosed as bool,
      homeSearchBarPlacement:
          homeSearchBarPlacement == const $CopyWithPlaceholder() ||
              homeSearchBarPlacement == null
          ? _value.homeSearchBarPlacement
          // ignore: cast_nullable_to_non_nullable
          : homeSearchBarPlacement as HomeSearchBarPlacement,
      tabIntentOpenSetting:
          tabIntentOpenSetting == const $CopyWithPlaceholder() ||
              tabIntentOpenSetting == null
          ? _value.tabIntentOpenSetting
          // ignore: cast_nullable_to_non_nullable
          : tabIntentOpenSetting as TabIntentOpenSetting,
      bookmarkOpenSetting:
          bookmarkOpenSetting == const $CopyWithPlaceholder() ||
              bookmarkOpenSetting == null
          ? _value.bookmarkOpenSetting
          // ignore: cast_nullable_to_non_nullable
          : bookmarkOpenSetting as BookmarkOpenSetting,
      autoHideTabBar:
          autoHideTabBar == const $CopyWithPlaceholder() ||
              autoHideTabBar == null
          ? _value.autoHideTabBar
          // ignore: cast_nullable_to_non_nullable
          : autoHideTabBar as bool,
      tabBarSwipeAction:
          tabBarSwipeAction == const $CopyWithPlaceholder() ||
              tabBarSwipeAction == null
          ? _value.tabBarSwipeAction
          // ignore: cast_nullable_to_non_nullable
          : tabBarSwipeAction as TabBarSwipeAction,
      historyAutoCleanInterval:
          historyAutoCleanInterval == const $CopyWithPlaceholder() ||
              historyAutoCleanInterval == null
          ? _value.historyAutoCleanInterval
          // ignore: cast_nullable_to_non_nullable
          : historyAutoCleanInterval as Duration,
      tabBarShowContextualBar:
          tabBarShowContextualBar == const $CopyWithPlaceholder() ||
              tabBarShowContextualBar == null
          ? _value.tabBarShowContextualBar
          // ignore: cast_nullable_to_non_nullable
          : tabBarShowContextualBar as bool,
      tabBarPosition:
          tabBarPosition == const $CopyWithPlaceholder() ||
              tabBarPosition == null
          ? _value.tabBarPosition
          // ignore: cast_nullable_to_non_nullable
          : tabBarPosition as TabBarPosition,
      tabBarLayout:
          tabBarLayout == const $CopyWithPlaceholder() || tabBarLayout == null
          ? _value.tabBarLayout
          // ignore: cast_nullable_to_non_nullable
          : tabBarLayout as TabBarLayout,
      tabBarStackingMode:
          tabBarStackingMode == const $CopyWithPlaceholder() ||
              tabBarStackingMode == null
          ? _value.tabBarStackingMode
          // ignore: cast_nullable_to_non_nullable
          : tabBarStackingMode as TabBarStackingMode,
      unassignedTabsAutoCleanInterval:
          unassignedTabsAutoCleanInterval == const $CopyWithPlaceholder() ||
              unassignedTabsAutoCleanInterval == null
          ? _value.unassignedTabsAutoCleanInterval
          // ignore: cast_nullable_to_non_nullable
          : unassignedTabsAutoCleanInterval as Duration,
      maxSearchHistoryEntries:
          maxSearchHistoryEntries == const $CopyWithPlaceholder() ||
              maxSearchHistoryEntries == null
          ? _value.maxSearchHistoryEntries
          // ignore: cast_nullable_to_non_nullable
          : maxSearchHistoryEntries as int,
      allowClipboardAccess:
          allowClipboardAccess == const $CopyWithPlaceholder() ||
              allowClipboardAccess == null
          ? _value.allowClipboardAccess
          // ignore: cast_nullable_to_non_nullable
          : allowClipboardAccess as bool,
      tabListShowFavicons:
          tabListShowFavicons == const $CopyWithPlaceholder() ||
              tabListShowFavicons == null
          ? _value.tabListShowFavicons
          // ignore: cast_nullable_to_non_nullable
          : tabListShowFavicons as bool,
      quickTabSwitcherShowTitles:
          quickTabSwitcherShowTitles == const $CopyWithPlaceholder() ||
              quickTabSwitcherShowTitles == null
          ? _value.quickTabSwitcherShowTitles
          // ignore: cast_nullable_to_non_nullable
          : quickTabSwitcherShowTitles as bool,
      quickTabSwitcherShowHistorySuggestions:
          quickTabSwitcherShowHistorySuggestions ==
                  const $CopyWithPlaceholder() ||
              quickTabSwitcherShowHistorySuggestions == null
          ? _value.quickTabSwitcherShowHistorySuggestions
          // ignore: cast_nullable_to_non_nullable
          : quickTabSwitcherShowHistorySuggestions as bool,
      quickTabSwitcherTitleWidth:
          quickTabSwitcherTitleWidth == const $CopyWithPlaceholder() ||
              quickTabSwitcherTitleWidth == null
          ? _value.quickTabSwitcherTitleWidth
          // ignore: cast_nullable_to_non_nullable
          : quickTabSwitcherTitleWidth as double,
      syncServerOverride:
          syncServerOverride == const $CopyWithPlaceholder() ||
              syncServerOverride == null
          ? _value.syncServerOverride
          // ignore: cast_nullable_to_non_nullable
          : syncServerOverride as String,
      syncTokenServerOverride:
          syncTokenServerOverride == const $CopyWithPlaceholder() ||
              syncTokenServerOverride == null
          ? _value.syncTokenServerOverride
          // ignore: cast_nullable_to_non_nullable
          : syncTokenServerOverride as String,
      tabBarLongPressUrlCopy:
          tabBarLongPressUrlCopy == const $CopyWithPlaceholder() ||
              tabBarLongPressUrlCopy == null
          ? _value.tabBarLongPressUrlCopy
          // ignore: cast_nullable_to_non_nullable
          : tabBarLongPressUrlCopy as bool,
      allowNonManifestPwaInstall:
          allowNonManifestPwaInstall == const $CopyWithPlaceholder() ||
              allowNonManifestPwaInstall == null
          ? _value.allowNonManifestPwaInstall
          // ignore: cast_nullable_to_non_nullable
          : allowNonManifestPwaInstall as bool,
      blockExternalAppsEnabled:
          blockExternalAppsEnabled == const $CopyWithPlaceholder() ||
              blockExternalAppsEnabled == null
          ? _value.blockExternalAppsEnabled
          // ignore: cast_nullable_to_non_nullable
          : blockExternalAppsEnabled as bool,
      externalAppIntentPolicies:
          externalAppIntentPolicies == const $CopyWithPlaceholder() ||
              externalAppIntentPolicies == null
          ? _value.externalAppIntentPolicies
          // ignore: cast_nullable_to_non_nullable
          : externalAppIntentPolicies as Map<String, IntentSourcePolicy>,
      customTabsEnabled:
          customTabsEnabled == const $CopyWithPlaceholder() ||
              customTabsEnabled == null
          ? _value.customTabsEnabled
          // ignore: cast_nullable_to_non_nullable
          : customTabsEnabled as bool,
      appLinksMode:
          appLinksMode == const $CopyWithPlaceholder() || appLinksMode == null
          ? _value.appLinksMode
          // ignore: cast_nullable_to_non_nullable
          : appLinksMode as AppLinksMode,
      appLinkRules:
          appLinkRules == const $CopyWithPlaceholder() || appLinkRules == null
          ? _value.appLinkRules
          // ignore: cast_nullable_to_non_nullable
          : appLinkRules as Map<String, PersistedAppLinkRule>,
      enableLocalSearchIndex:
          enableLocalSearchIndex == const $CopyWithPlaceholder() ||
              enableLocalSearchIndex == null
          ? _value.enableLocalSearchIndex
          // ignore: cast_nullable_to_non_nullable
          : enableLocalSearchIndex as bool,
      indexPrivateTabs:
          indexPrivateTabs == const $CopyWithPlaceholder() ||
              indexPrivateTabs == null
          ? _value.indexPrivateTabs
          // ignore: cast_nullable_to_non_nullable
          : indexPrivateTabs as bool,
      acceptSuggestionOnSubmit:
          acceptSuggestionOnSubmit == const $CopyWithPlaceholder() ||
              acceptSuggestionOnSubmit == null
          ? _value.acceptSuggestionOnSubmit
          // ignore: cast_nullable_to_non_nullable
          : acceptSuggestionOnSubmit as bool,
      pureBlack: pureBlack == const $CopyWithPlaceholder() || pureBlack == null
          ? _value.pureBlack
          // ignore: cast_nullable_to_non_nullable
          : pureBlack as bool,
      globalDesktopMode:
          globalDesktopMode == const $CopyWithPlaceholder() ||
              globalDesktopMode == null
          ? _value.globalDesktopMode
          // ignore: cast_nullable_to_non_nullable
          : globalDesktopMode as bool,
      desktopModeSites:
          desktopModeSites == const $CopyWithPlaceholder() ||
              desktopModeSites == null
          ? _value.desktopModeSites
          // ignore: cast_nullable_to_non_nullable
          : desktopModeSites as List<String>,
      unmountGeckoViewOffRoute:
          unmountGeckoViewOffRoute == const $CopyWithPlaceholder() ||
              unmountGeckoViewOffRoute == null
          ? _value.unmountGeckoViewOffRoute
          // ignore: cast_nullable_to_non_nullable
          : unmountGeckoViewOffRoute as bool,
    );
  }
}

extension $GeneralSettingsCopyWith on GeneralSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGeneralSettings.copyWith(...)` or `instanceOfGeneralSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GeneralSettingsCWProxy get copyWith => _$GeneralSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneralSettings _$GeneralSettingsFromJson(
  Map<String, dynamic> json,
) => GeneralSettings.withDefaults(
  themeMode: $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']),
  deleteBrowsingDataOnQuit: (json['deleteBrowsingDataOnQuit'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$DeleteBrowsingDataTypeEnumMap, e))
      .toSet(),
  screenshotProtectionEnabled: json['screenshotProtectionEnabled'] as bool?,
  allowPrivateTabScreenshots: json['allowPrivateTabScreenshots'] as bool?,
  defaultSearchProvider: const SearchProviderIdConverter().fromJson(
    json['defaultSearchProvider'] as String?,
  ),
  defaultSearchSuggestionsProvider: $enumDecodeNullable(
    _$SearchSuggestionProvidersEnumMap,
    json['defaultSearchSuggestionsProvider'],
  ),
  showContainerUi: json['showContainerUi'] as bool?,
  homeTarget: $enumDecodeNullable(_$HomeTargetEnumMap, json['homeTarget']),
  homeTargetUrl: json['homeTargetUrl'] as String?,
  homeTargetOnLastTabClosed: json['homeTargetOnLastTabClosed'] as bool?,
  homeSearchBarPlacement: $enumDecodeNullable(
    _$HomeSearchBarPlacementEnumMap,
    json['homeSearchBarPlacement'],
  ),
  tabIntentOpenSetting: $enumDecodeNullable(
    _$TabIntentOpenSettingEnumMap,
    json['tabIntentOpenSetting'],
    unknownValue: TabIntentOpenSetting.regular,
  ),
  bookmarkOpenSetting: $enumDecodeNullable(
    _$BookmarkOpenSettingEnumMap,
    json['bookmarkOpenSetting'],
    unknownValue: BookmarkOpenSetting.regular,
  ),
  autoHideTabBar: json['autoHideTabBar'] as bool?,
  tabBarSwipeAction: $enumDecodeNullable(
    _$TabBarSwipeActionEnumMap,
    json['tabBarSwipeAction'],
  ),
  historyAutoCleanInterval: json['historyAutoCleanInterval'] == null
      ? null
      : Duration(
          microseconds: (json['historyAutoCleanInterval'] as num).toInt(),
        ),
  tabBarShowContextualBar: json['tabBarShowContextualBar'] as bool?,
  tabBarPosition: $enumDecodeNullable(
    _$TabBarPositionEnumMap,
    json['tabBarPosition'],
  ),
  tabBarLayout: $enumDecodeNullable(
    _$TabBarLayoutEnumMap,
    json['tabBarLayout'],
  ),
  tabBarStackingMode: $enumDecodeNullable(
    _$TabBarStackingModeEnumMap,
    json['tabBarStackingMode'],
  ),
  unassignedTabsAutoCleanInterval:
      json['unassignedTabsAutoCleanInterval'] == null
      ? null
      : Duration(
          microseconds: (json['unassignedTabsAutoCleanInterval'] as num)
              .toInt(),
        ),
  maxSearchHistoryEntries: (json['maxSearchHistoryEntries'] as num?)?.toInt(),
  allowClipboardAccess: json['allowClipboardAccess'] as bool?,
  tabListShowFavicons: json['tabListShowFavicons'] as bool?,
  quickTabSwitcherShowTitles: json['quickTabSwitcherShowTitles'] as bool?,
  quickTabSwitcherShowHistorySuggestions:
      json['quickTabSwitcherShowHistorySuggestions'] as bool?,
  quickTabSwitcherTitleWidth: (json['quickTabSwitcherTitleWidth'] as num?)
      ?.toDouble(),
  syncServerOverride: json['syncServerOverride'] as String?,
  syncTokenServerOverride: json['syncTokenServerOverride'] as String?,
  tabBarLongPressUrlCopy: json['tabBarLongPressUrlCopy'] as bool?,
  allowNonManifestPwaInstall: json['allowNonManifestPwaInstall'] as bool?,
  blockExternalAppsEnabled: json['blockExternalAppsEnabled'] as bool?,
  externalAppIntentPolicies:
      (json['externalAppIntentPolicies'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, $enumDecode(_$IntentSourcePolicyEnumMap, e)),
      ),
  customTabsEnabled: json['customTabsEnabled'] as bool?,
  appLinksMode: $enumDecodeNullable(
    _$AppLinksModeEnumMap,
    json['appLinksMode'],
  ),
  appLinkRules: parseAppLinkRules(
    json['appLinkRules'] as Map<String, dynamic>?,
  ),
  enableLocalSearchIndex: json['enableLocalSearchIndex'] as bool?,
  indexPrivateTabs: json['indexPrivateTabs'] as bool?,
  acceptSuggestionOnSubmit: json['acceptSuggestionOnSubmit'] as bool?,
  pureBlack: json['pureBlack'] as bool?,
  globalDesktopMode: json['globalDesktopMode'] as bool?,
  desktopModeSites: (json['desktopModeSites'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  unmountGeckoViewOffRoute: json['unmountGeckoViewOffRoute'] as bool?,
);

Map<String, dynamic> _$GeneralSettingsToJson(
  GeneralSettings instance,
) => <String, dynamic>{
  'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
  'deleteBrowsingDataOnQuit': instance.deleteBrowsingDataOnQuit
      ?.map((e) => _$DeleteBrowsingDataTypeEnumMap[e]!)
      .toList(),
  'screenshotProtectionEnabled': instance.screenshotProtectionEnabled,
  'allowPrivateTabScreenshots': instance.allowPrivateTabScreenshots,
  'defaultSearchProvider': const SearchProviderIdConverter().toJson(
    instance.defaultSearchProvider,
  ),
  'defaultSearchSuggestionsProvider':
      _$SearchSuggestionProvidersEnumMap[instance
          .defaultSearchSuggestionsProvider]!,
  'showContainerUi': instance.showContainerUi,
  'homeTarget': _$HomeTargetEnumMap[instance.homeTarget]!,
  'homeTargetUrl': instance.homeTargetUrl,
  'homeTargetOnLastTabClosed': instance.homeTargetOnLastTabClosed,
  'homeSearchBarPlacement':
      _$HomeSearchBarPlacementEnumMap[instance.homeSearchBarPlacement]!,
  'tabIntentOpenSetting':
      _$TabIntentOpenSettingEnumMap[instance.tabIntentOpenSetting]!,
  'bookmarkOpenSetting':
      _$BookmarkOpenSettingEnumMap[instance.bookmarkOpenSetting]!,
  'autoHideTabBar': instance.autoHideTabBar,
  'tabBarSwipeAction': _$TabBarSwipeActionEnumMap[instance.tabBarSwipeAction]!,
  'historyAutoCleanInterval': instance.historyAutoCleanInterval.inMicroseconds,
  'tabBarShowContextualBar': instance.tabBarShowContextualBar,
  'tabBarPosition': _$TabBarPositionEnumMap[instance.tabBarPosition]!,
  'tabBarLayout': _$TabBarLayoutEnumMap[instance.tabBarLayout]!,
  'tabBarStackingMode':
      _$TabBarStackingModeEnumMap[instance.tabBarStackingMode]!,
  'unassignedTabsAutoCleanInterval':
      instance.unassignedTabsAutoCleanInterval.inMicroseconds,
  'maxSearchHistoryEntries': instance.maxSearchHistoryEntries,
  'allowClipboardAccess': instance.allowClipboardAccess,
  'tabListShowFavicons': instance.tabListShowFavicons,
  'quickTabSwitcherShowTitles': instance.quickTabSwitcherShowTitles,
  'quickTabSwitcherShowHistorySuggestions':
      instance.quickTabSwitcherShowHistorySuggestions,
  'quickTabSwitcherTitleWidth': instance.quickTabSwitcherTitleWidth,
  'syncServerOverride': instance.syncServerOverride,
  'syncTokenServerOverride': instance.syncTokenServerOverride,
  'tabBarLongPressUrlCopy': instance.tabBarLongPressUrlCopy,
  'allowNonManifestPwaInstall': instance.allowNonManifestPwaInstall,
  'blockExternalAppsEnabled': instance.blockExternalAppsEnabled,
  'externalAppIntentPolicies': instance.externalAppIntentPolicies.map(
    (k, e) => MapEntry(k, _$IntentSourcePolicyEnumMap[e]!),
  ),
  'customTabsEnabled': instance.customTabsEnabled,
  'appLinksMode': _$AppLinksModeEnumMap[instance.appLinksMode]!,
  'appLinkRules': instance.appLinkRules.map((k, e) => MapEntry(k, e.toJson())),
  'enableLocalSearchIndex': instance.enableLocalSearchIndex,
  'indexPrivateTabs': instance.indexPrivateTabs,
  'acceptSuggestionOnSubmit': instance.acceptSuggestionOnSubmit,
  'pureBlack': instance.pureBlack,
  'globalDesktopMode': instance.globalDesktopMode,
  'desktopModeSites': instance.desktopModeSites,
  'unmountGeckoViewOffRoute': instance.unmountGeckoViewOffRoute,
};

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$DeleteBrowsingDataTypeEnumMap = {
  DeleteBrowsingDataType.tabs: 'tabs',
  DeleteBrowsingDataType.history: 'history',
  DeleteBrowsingDataType.recentSearches: 'recentSearches',
  DeleteBrowsingDataType.cookies: 'cookies',
  DeleteBrowsingDataType.cache: 'cache',
  DeleteBrowsingDataType.permissions: 'permissions',
  DeleteBrowsingDataType.downloads: 'downloads',
};

const _$SearchSuggestionProvidersEnumMap = {
  SearchSuggestionProviders.none: 'none',
  SearchSuggestionProviders.brave: 'brave',
  SearchSuggestionProviders.ddg: 'ddg',
  SearchSuggestionProviders.kagi: 'kagi',
  SearchSuggestionProviders.qwant: 'qwant',
};

const _$HomeTargetEnumMap = {
  HomeTarget.home: 'home',
  HomeTarget.resumeLastTab: 'resumeLastTab',
  HomeTarget.customUrl: 'customUrl',
};

const _$HomeSearchBarPlacementEnumMap = {
  HomeSearchBarPlacement.auto: 'auto',
  HomeSearchBarPlacement.top: 'top',
  HomeSearchBarPlacement.tabBar: 'tabBar',
};

const _$TabIntentOpenSettingEnumMap = {
  TabIntentOpenSetting.regular: 'regular',
  TabIntentOpenSetting.private: 'private',
  TabIntentOpenSetting.ask: 'ask',
};

const _$BookmarkOpenSettingEnumMap = {
  BookmarkOpenSetting.regular: 'regular',
  BookmarkOpenSetting.private: 'private',
  BookmarkOpenSetting.customTab: 'customTab',
  BookmarkOpenSetting.ask: 'ask',
};

const _$TabBarSwipeActionEnumMap = {
  TabBarSwipeAction.switchLastOpened: 'switchLastOpened',
  TabBarSwipeAction.navigateOrderedTabs: 'navigateOrderedTabs',
};

const _$TabBarPositionEnumMap = {
  TabBarPosition.top: 'top',
  TabBarPosition.bottom: 'bottom',
  TabBarPosition.left: 'left',
  TabBarPosition.right: 'right',
};

const _$TabBarLayoutEnumMap = {
  TabBarLayout.withTitle: 'withTitle',
  TabBarLayout.compact: 'compact',
};

const _$TabBarStackingModeEnumMap = {
  TabBarStackingMode.lastUsedTabs: 'lastUsedTabs',
  TabBarStackingMode.containerTabs: 'containerTabs',
  TabBarStackingMode.accordion: 'accordion',
  TabBarStackingMode.twoLevel: 'twoLevel',
  TabBarStackingMode.disabled: 'disabled',
  TabBarStackingMode.spaceTabs: 'spaceTabs',
};

const _$IntentSourcePolicyEnumMap = {
  IntentSourcePolicy.allow: 'allow',
  IntentSourcePolicy.block: 'block',
};

const _$AppLinksModeEnumMap = {
  AppLinksMode.always: 'always',
  AppLinksMode.ask: 'ask',
  AppLinksMode.never: 'never',
};
