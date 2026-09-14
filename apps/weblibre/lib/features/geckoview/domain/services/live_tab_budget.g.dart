// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_tab_budget.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the number of live engine sessions within
/// [ZenSettings.maxLiveTabs] (PLAN §7.4 item 5).
///
/// Whenever the engine's tab list or the budget changes, and once the list
/// has been quiet for [settleDelay], the least recently used regular tabs
/// (by `tab.timestamp`) are unloaded back to cold rows through
/// [TabRepository.demoteToCold], one every [demoteGap], until the count is
/// within budget. The selected tab, pinned and essential tabs and private
/// tabs are never unloaded. Memory pressure from the OS trims harder, down to
/// half the budget. Nothing is unloaded while the session restore is still
/// running: a partial tab list would read as "over budget" for nothing.
///
/// Long-lived: activate it with `_activateService` in `main.dart` (PLAN §3.6).

@ProviderFor(LiveTabBudget)
final liveTabBudgetProvider = LiveTabBudgetProvider._();

/// Keeps the number of live engine sessions within
/// [ZenSettings.maxLiveTabs] (PLAN §7.4 item 5).
///
/// Whenever the engine's tab list or the budget changes, and once the list
/// has been quiet for [settleDelay], the least recently used regular tabs
/// (by `tab.timestamp`) are unloaded back to cold rows through
/// [TabRepository.demoteToCold], one every [demoteGap], until the count is
/// within budget. The selected tab, pinned and essential tabs and private
/// tabs are never unloaded. Memory pressure from the OS trims harder, down to
/// half the budget. Nothing is unloaded while the session restore is still
/// running: a partial tab list would read as "over budget" for nothing.
///
/// Long-lived: activate it with `_activateService` in `main.dart` (PLAN §3.6).
final class LiveTabBudgetProvider
    extends $NotifierProvider<LiveTabBudget, void> {
  /// Keeps the number of live engine sessions within
  /// [ZenSettings.maxLiveTabs] (PLAN §7.4 item 5).
  ///
  /// Whenever the engine's tab list or the budget changes, and once the list
  /// has been quiet for [settleDelay], the least recently used regular tabs
  /// (by `tab.timestamp`) are unloaded back to cold rows through
  /// [TabRepository.demoteToCold], one every [demoteGap], until the count is
  /// within budget. The selected tab, pinned and essential tabs and private
  /// tabs are never unloaded. Memory pressure from the OS trims harder, down to
  /// half the budget. Nothing is unloaded while the session restore is still
  /// running: a partial tab list would read as "over budget" for nothing.
  ///
  /// Long-lived: activate it with `_activateService` in `main.dart` (PLAN §3.6).
  LiveTabBudgetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveTabBudgetProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveTabBudgetHash();

  @$internal
  @override
  LiveTabBudget create() => LiveTabBudget();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$liveTabBudgetHash() => r'8cdea8e8b9493afbf4da372f655abef69ff16766';

/// Keeps the number of live engine sessions within
/// [ZenSettings.maxLiveTabs] (PLAN §7.4 item 5).
///
/// Whenever the engine's tab list or the budget changes, and once the list
/// has been quiet for [settleDelay], the least recently used regular tabs
/// (by `tab.timestamp`) are unloaded back to cold rows through
/// [TabRepository.demoteToCold], one every [demoteGap], until the count is
/// within budget. The selected tab, pinned and essential tabs and private
/// tabs are never unloaded. Memory pressure from the OS trims harder, down to
/// half the budget. Nothing is unloaded while the session restore is still
/// running: a partial tab list would read as "over budget" for nothing.
///
/// Long-lived: activate it with `_activateService` in `main.dart` (PLAN §3.6).

abstract class _$LiveTabBudget extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
