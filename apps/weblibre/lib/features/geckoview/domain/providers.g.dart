// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(selectionActionService)
final selectionActionServiceProvider = SelectionActionServiceProvider._();

final class SelectionActionServiceProvider
    extends
        $FunctionalProvider<
          GeckoSelectionActionService,
          GeckoSelectionActionService,
          GeckoSelectionActionService
        >
    with $Provider<GeckoSelectionActionService> {
  SelectionActionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionActionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionActionServiceHash();

  @$internal
  @override
  $ProviderElement<GeckoSelectionActionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeckoSelectionActionService create(Ref ref) {
    return selectionActionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeckoSelectionActionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeckoSelectionActionService>(value),
    );
  }
}

String _$selectionActionServiceHash() =>
    r'3b3a51df179f88aa7eed53ca8b68081a8dcf25f2';

/// The engine's tab API. A provider rather than a bare constructor so tests
/// can stand in a fake engine for [TabRepository].

@ProviderFor(geckoTabService)
final geckoTabServiceProvider = GeckoTabServiceProvider._();

/// The engine's tab API. A provider rather than a bare constructor so tests
/// can stand in a fake engine for [TabRepository].

final class GeckoTabServiceProvider
    extends
        $FunctionalProvider<GeckoTabService, GeckoTabService, GeckoTabService>
    with $Provider<GeckoTabService> {
  /// The engine's tab API. A provider rather than a bare constructor so tests
  /// can stand in a fake engine for [TabRepository].
  GeckoTabServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geckoTabServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geckoTabServiceHash();

  @$internal
  @override
  $ProviderElement<GeckoTabService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeckoTabService create(Ref ref) {
    return geckoTabService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeckoTabService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeckoTabService>(value),
    );
  }
}

String _$geckoTabServiceHash() => r'4345489a15b4595062e2003ab3d848502a4f92da';

@ProviderFor(eventService)
final eventServiceProvider = EventServiceProvider._();

final class EventServiceProvider
    extends
        $FunctionalProvider<
          GeckoEventService,
          GeckoEventService,
          GeckoEventService
        >
    with $Provider<GeckoEventService> {
  EventServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventServiceHash();

  @$internal
  @override
  $ProviderElement<GeckoEventService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeckoEventService create(Ref ref) {
    return eventService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeckoEventService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeckoEventService>(value),
    );
  }
}

String _$eventServiceHash() => r'3a297348fadda05dc60433d7ce8f662b2ff62c26';

@ProviderFor(addonService)
final addonServiceProvider = AddonServiceProvider._();

final class AddonServiceProvider
    extends
        $FunctionalProvider<
          GeckoAddonService,
          GeckoAddonService,
          GeckoAddonService
        >
    with $Provider<GeckoAddonService> {
  AddonServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addonServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addonServiceHash();

  @$internal
  @override
  $ProviderElement<GeckoAddonService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeckoAddonService create(Ref ref) {
    return addonService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeckoAddonService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeckoAddonService>(value),
    );
  }
}

String _$addonServiceHash() => r'30fedb35c68943159246df79b5f1b62a25767fa0';

@ProviderFor(tabContentService)
final tabContentServiceProvider = TabContentServiceProvider._();

final class TabContentServiceProvider
    extends
        $FunctionalProvider<
          GeckoTabContentService,
          GeckoTabContentService,
          GeckoTabContentService
        >
    with $Provider<GeckoTabContentService> {
  TabContentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tabContentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tabContentServiceHash();

  @$internal
  @override
  $ProviderElement<GeckoTabContentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeckoTabContentService create(Ref ref) {
    return tabContentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeckoTabContentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeckoTabContentService>(value),
    );
  }
}

String _$tabContentServiceHash() => r'12d8322c37ded4ad3344af327d884bbf7f089594';

@ProviderFor(engineSuggestionsService)
final engineSuggestionsServiceProvider = EngineSuggestionsServiceProvider._();

final class EngineSuggestionsServiceProvider
    extends
        $FunctionalProvider<
          GeckoSuggestionsService,
          GeckoSuggestionsService,
          GeckoSuggestionsService
        >
    with $Provider<GeckoSuggestionsService> {
  EngineSuggestionsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engineSuggestionsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engineSuggestionsServiceHash();

  @$internal
  @override
  $ProviderElement<GeckoSuggestionsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeckoSuggestionsService create(Ref ref) {
    return engineSuggestionsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeckoSuggestionsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeckoSuggestionsService>(value),
    );
  }
}

String _$engineSuggestionsServiceHash() =>
    r'1ec1192f0c5c86cecc7ad448ee2b039f7a48e32b';

@ProviderFor(viewportService)
final viewportServiceProvider = ViewportServiceProvider._();

final class ViewportServiceProvider
    extends
        $FunctionalProvider<
          GeckoViewportService,
          GeckoViewportService,
          GeckoViewportService
        >
    with $Provider<GeckoViewportService> {
  ViewportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewportServiceHash();

  @$internal
  @override
  $ProviderElement<GeckoViewportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeckoViewportService create(Ref ref) {
    return viewportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeckoViewportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeckoViewportService>(value),
    );
  }
}

String _$viewportServiceHash() => r'bab39db3180bb6a1cf8c055966b7f5910b41b424';

/// Whether native has reported that the engine and its components are up.
///
/// Native reports this once `GeckoBrowserApi.initialize` has built the
/// components, and again whenever a Flutter view attaches (a restarted Dart
/// half has lost the first report). It says nothing about tabs: the pull-based
/// `syncEvents` catch-ups that gate on it need the engine, not a session.
///
/// It used to be inferred from a reader-view action, which AC only dispatches
/// once a tab is selected — so a start that landed on the home surface never
/// reported ready and every catch-up sat out the timeout below instead.

@ProviderFor(EngineReadyState)
final engineReadyStateProvider = EngineReadyStateProvider._();

/// Whether native has reported that the engine and its components are up.
///
/// Native reports this once `GeckoBrowserApi.initialize` has built the
/// components, and again whenever a Flutter view attaches (a restarted Dart
/// half has lost the first report). It says nothing about tabs: the pull-based
/// `syncEvents` catch-ups that gate on it need the engine, not a session.
///
/// It used to be inferred from a reader-view action, which AC only dispatches
/// once a tab is selected — so a start that landed on the home surface never
/// reported ready and every catch-up sat out the timeout below instead.
final class EngineReadyStateProvider
    extends $NotifierProvider<EngineReadyState, bool> {
  /// Whether native has reported that the engine and its components are up.
  ///
  /// Native reports this once `GeckoBrowserApi.initialize` has built the
  /// components, and again whenever a Flutter view attaches (a restarted Dart
  /// half has lost the first report). It says nothing about tabs: the pull-based
  /// `syncEvents` catch-ups that gate on it need the engine, not a session.
  ///
  /// It used to be inferred from a reader-view action, which AC only dispatches
  /// once a tab is selected — so a start that landed on the home surface never
  /// reported ready and every catch-up sat out the timeout below instead.
  EngineReadyStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engineReadyStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engineReadyStateHash();

  @$internal
  @override
  EngineReadyState create() => EngineReadyState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$engineReadyStateHash() => r'a2e27024215df2b00167192365cb9b2581ef41fd';

/// Whether native has reported that the engine and its components are up.
///
/// Native reports this once `GeckoBrowserApi.initialize` has built the
/// components, and again whenever a Flutter view attaches (a restarted Dart
/// half has lost the first report). It says nothing about tabs: the pull-based
/// `syncEvents` catch-ups that gate on it need the engine, not a session.
///
/// It used to be inferred from a reader-view action, which AC only dispatches
/// once a tab is selected — so a start that landed on the home surface never
/// reported ready and every catch-up sat out the timeout below instead.

abstract class _$EngineReadyState extends $Notifier<bool> {
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
