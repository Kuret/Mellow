// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compact_rail_panel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the narrow-viewport compact bar's slide-out tab rail is open.
///
/// The single source of truth both the gesture (predictive drag and the
/// plain-back fallback) and the ordinary UI (the scrim, picking a tab) drive
/// through [open] and [close], and the widget that owns the slide animation
/// listens to so a programmatic open (the fallback) animates exactly like a
/// gesture-driven one.

@ProviderFor(CompactRailPanelOpen)
final compactRailPanelOpenProvider = CompactRailPanelOpenProvider._();

/// Whether the narrow-viewport compact bar's slide-out tab rail is open.
///
/// The single source of truth both the gesture (predictive drag and the
/// plain-back fallback) and the ordinary UI (the scrim, picking a tab) drive
/// through [open] and [close], and the widget that owns the slide animation
/// listens to so a programmatic open (the fallback) animates exactly like a
/// gesture-driven one.
final class CompactRailPanelOpenProvider
    extends $NotifierProvider<CompactRailPanelOpen, bool> {
  /// Whether the narrow-viewport compact bar's slide-out tab rail is open.
  ///
  /// The single source of truth both the gesture (predictive drag and the
  /// plain-back fallback) and the ordinary UI (the scrim, picking a tab) drive
  /// through [open] and [close], and the widget that owns the slide animation
  /// listens to so a programmatic open (the fallback) animates exactly like a
  /// gesture-driven one.
  CompactRailPanelOpenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compactRailPanelOpenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compactRailPanelOpenHash();

  @$internal
  @override
  CompactRailPanelOpen create() => CompactRailPanelOpen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$compactRailPanelOpenHash() =>
    r'168a0a0d82bd5ec173724848fed06d59f69bed71';

/// Whether the narrow-viewport compact bar's slide-out tab rail is open.
///
/// The single source of truth both the gesture (predictive drag and the
/// plain-back fallback) and the ordinary UI (the scrim, picking a tab) drive
/// through [open] and [close], and the widget that owns the slide animation
/// listens to so a programmatic open (the fallback) animates exactly like a
/// gesture-driven one.

abstract class _$CompactRailPanelOpen extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Which edge the slide-out panel is open on right now.
///
/// Explicit state rather than something re-derived from
/// [ZenSettings.compactRailSide] wherever the current edge is needed: on
/// [CompactRailSide.either] the setting alone does not say which edge —
/// that is decided per gesture by `resolveCompactRailBackGesture` — so the
/// gesture handler and the plain-back fallback both write the resolved side
/// here in the same beat they call [CompactRailPanelOpen.open], and the panel
/// widget reads it back to know which edge to render on.
///
/// Stays at its last value once set, including after the panel closes: the
/// panel widget keeps its content mounted (translated off-screen) between
/// opens, and re-reads this to lay itself out correctly before the very next
/// gesture updates it.

@ProviderFor(CompactRailPanelSide)
final compactRailPanelSideProvider = CompactRailPanelSideProvider._();

/// Which edge the slide-out panel is open on right now.
///
/// Explicit state rather than something re-derived from
/// [ZenSettings.compactRailSide] wherever the current edge is needed: on
/// [CompactRailSide.either] the setting alone does not say which edge —
/// that is decided per gesture by `resolveCompactRailBackGesture` — so the
/// gesture handler and the plain-back fallback both write the resolved side
/// here in the same beat they call [CompactRailPanelOpen.open], and the panel
/// widget reads it back to know which edge to render on.
///
/// Stays at its last value once set, including after the panel closes: the
/// panel widget keeps its content mounted (translated off-screen) between
/// opens, and re-reads this to lay itself out correctly before the very next
/// gesture updates it.
final class CompactRailPanelSideProvider
    extends $NotifierProvider<CompactRailPanelSide, RailSide?> {
  /// Which edge the slide-out panel is open on right now.
  ///
  /// Explicit state rather than something re-derived from
  /// [ZenSettings.compactRailSide] wherever the current edge is needed: on
  /// [CompactRailSide.either] the setting alone does not say which edge —
  /// that is decided per gesture by `resolveCompactRailBackGesture` — so the
  /// gesture handler and the plain-back fallback both write the resolved side
  /// here in the same beat they call [CompactRailPanelOpen.open], and the panel
  /// widget reads it back to know which edge to render on.
  ///
  /// Stays at its last value once set, including after the panel closes: the
  /// panel widget keeps its content mounted (translated off-screen) between
  /// opens, and re-reads this to lay itself out correctly before the very next
  /// gesture updates it.
  CompactRailPanelSideProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compactRailPanelSideProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compactRailPanelSideHash();

  @$internal
  @override
  CompactRailPanelSide create() => CompactRailPanelSide();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RailSide? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RailSide?>(value),
    );
  }
}

String _$compactRailPanelSideHash() =>
    r'ce087792232efff6462e10b2208522626655be8a';

/// Which edge the slide-out panel is open on right now.
///
/// Explicit state rather than something re-derived from
/// [ZenSettings.compactRailSide] wherever the current edge is needed: on
/// [CompactRailSide.either] the setting alone does not say which edge —
/// that is decided per gesture by `resolveCompactRailBackGesture` — so the
/// gesture handler and the plain-back fallback both write the resolved side
/// here in the same beat they call [CompactRailPanelOpen.open], and the panel
/// widget reads it back to know which edge to render on.
///
/// Stays at its last value once set, including after the panel closes: the
/// panel widget keeps its content mounted (translated off-screen) between
/// opens, and re-reads this to lay itself out correctly before the very next
/// gesture updates it.

abstract class _$CompactRailPanelSide extends $Notifier<RailSide?> {
  RailSide? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RailSide?, RailSide?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RailSide?, RailSide?>,
              RailSide?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether this device has ever delivered a predictive back gesture to the
/// app — i.e. whether the edge a back gesture came from is knowable.
///
/// The plain-back fallback exists for platforms that never send predictive
/// events (Android 12 and below, 3-button navigation), where there is no edge
/// to match and any back opens the panel. Without this flag that fallback also
/// fires on a *predictive* gesture the observer deliberately let through —
/// a back swipe from the edge opposite the rail — because the framework then
/// runs its ordinary pop, which lands in the same `BackButtonListener`. The
/// result is the rail opening from both edges and the promise that "a back
/// swipe from the other edge still goes back" being quietly broken.
///
/// Set once, on the first `handleStartBackGesture` this app ever sees. That
/// event always precedes the committed back it belongs to, so the very first
/// gesture on a predictive-back device is already covered.

@ProviderFor(PredictiveBackSeen)
final predictiveBackSeenProvider = PredictiveBackSeenProvider._();

/// Whether this device has ever delivered a predictive back gesture to the
/// app — i.e. whether the edge a back gesture came from is knowable.
///
/// The plain-back fallback exists for platforms that never send predictive
/// events (Android 12 and below, 3-button navigation), where there is no edge
/// to match and any back opens the panel. Without this flag that fallback also
/// fires on a *predictive* gesture the observer deliberately let through —
/// a back swipe from the edge opposite the rail — because the framework then
/// runs its ordinary pop, which lands in the same `BackButtonListener`. The
/// result is the rail opening from both edges and the promise that "a back
/// swipe from the other edge still goes back" being quietly broken.
///
/// Set once, on the first `handleStartBackGesture` this app ever sees. That
/// event always precedes the committed back it belongs to, so the very first
/// gesture on a predictive-back device is already covered.
final class PredictiveBackSeenProvider
    extends $NotifierProvider<PredictiveBackSeen, bool> {
  /// Whether this device has ever delivered a predictive back gesture to the
  /// app — i.e. whether the edge a back gesture came from is knowable.
  ///
  /// The plain-back fallback exists for platforms that never send predictive
  /// events (Android 12 and below, 3-button navigation), where there is no edge
  /// to match and any back opens the panel. Without this flag that fallback also
  /// fires on a *predictive* gesture the observer deliberately let through —
  /// a back swipe from the edge opposite the rail — because the framework then
  /// runs its ordinary pop, which lands in the same `BackButtonListener`. The
  /// result is the rail opening from both edges and the promise that "a back
  /// swipe from the other edge still goes back" being quietly broken.
  ///
  /// Set once, on the first `handleStartBackGesture` this app ever sees. That
  /// event always precedes the committed back it belongs to, so the very first
  /// gesture on a predictive-back device is already covered.
  PredictiveBackSeenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'predictiveBackSeenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$predictiveBackSeenHash();

  @$internal
  @override
  PredictiveBackSeen create() => PredictiveBackSeen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$predictiveBackSeenHash() =>
    r'3c0fd81c939e066b525ff5582daab7b920378336';

/// Whether this device has ever delivered a predictive back gesture to the
/// app — i.e. whether the edge a back gesture came from is knowable.
///
/// The plain-back fallback exists for platforms that never send predictive
/// events (Android 12 and below, 3-button navigation), where there is no edge
/// to match and any back opens the panel. Without this flag that fallback also
/// fires on a *predictive* gesture the observer deliberately let through —
/// a back swipe from the edge opposite the rail — because the framework then
/// runs its ordinary pop, which lands in the same `BackButtonListener`. The
/// result is the rail opening from both edges and the promise that "a back
/// swipe from the other edge still goes back" being quietly broken.
///
/// Set once, on the first `handleStartBackGesture` this app ever sees. That
/// event always precedes the committed back it belongs to, so the very first
/// gesture on a predictive-back device is already covered.

abstract class _$PredictiveBackSeen extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
