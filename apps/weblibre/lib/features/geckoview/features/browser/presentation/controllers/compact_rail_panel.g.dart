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
