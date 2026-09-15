// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_space.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The space the tab list shows and new regular tabs are created in.
///
/// Persisted across restarts. Always names an existing space once the space
/// list has loaded: an empty table gets a default space, a stale uuid falls
/// back to the first space by `order_index`. Follows the selected tab's space
/// the way [SelectedContainer] follows the tab's container — a tab without a
/// space (private, essential) leaves the selection alone.

@ProviderFor(SelectedSpace)
final selectedSpaceProvider = SelectedSpaceProvider._();

/// The space the tab list shows and new regular tabs are created in.
///
/// Persisted across restarts. Always names an existing space once the space
/// list has loaded: an empty table gets a default space, a stale uuid falls
/// back to the first space by `order_index`. Follows the selected tab's space
/// the way [SelectedContainer] follows the tab's container — a tab without a
/// space (private, essential) leaves the selection alone.
final class SelectedSpaceProvider
    extends $NotifierProvider<SelectedSpace, String?> {
  /// The space the tab list shows and new regular tabs are created in.
  ///
  /// Persisted across restarts. Always names an existing space once the space
  /// list has loaded: an empty table gets a default space, a stale uuid falls
  /// back to the first space by `order_index`. Follows the selected tab's space
  /// the way [SelectedContainer] follows the tab's container — a tab without a
  /// space (private, essential) leaves the selection alone.
  SelectedSpaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSpaceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSpaceHash();

  @$internal
  @override
  SelectedSpace create() => SelectedSpace();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedSpaceHash() => r'6fecea9c5a2f0a8cd89dbc434ece665322d83b3b';

/// The space the tab list shows and new regular tabs are created in.
///
/// Persisted across restarts. Always names an existing space once the space
/// list has loaded: an empty table gets a default space, a stale uuid falls
/// back to the first space by `order_index`. Follows the selected tab's space
/// the way [SelectedContainer] follows the tab's container — a tab without a
/// space (private, essential) leaves the selection alone.

abstract class _$SelectedSpace extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The selected space's row, or `null` while nothing is selected.

@ProviderFor(selectedSpaceData)
final selectedSpaceDataProvider = SelectedSpaceDataProvider._();

/// The selected space's row, or `null` while nothing is selected.

final class SelectedSpaceDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<SpaceData?>,
          SpaceData?,
          Stream<SpaceData?>
        >
    with $FutureModifier<SpaceData?>, $StreamProvider<SpaceData?> {
  /// The selected space's row, or `null` while nothing is selected.
  SelectedSpaceDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSpaceDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSpaceDataHash();

  @$internal
  @override
  $StreamProviderElement<SpaceData?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<SpaceData?> create(Ref ref) {
    return selectedSpaceData(ref);
  }
}

String _$selectedSpaceDataHash() => r'e7514e85c84797fa1e68757cba197864782e6608';

/// The selected tab's space, if it has one (private tabs and essentials do
/// not).

@ProviderFor(selectedTabSpaceUuid)
final selectedTabSpaceUuidProvider = SelectedTabSpaceUuidProvider._();

/// The selected tab's space, if it has one (private tabs and essentials do
/// not).

final class SelectedTabSpaceUuidProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// The selected tab's space, if it has one (private tabs and essentials do
  /// not).
  SelectedTabSpaceUuidProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTabSpaceUuidProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTabSpaceUuidHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return selectedTabSpaceUuid(ref);
  }
}

String _$selectedTabSpaceUuidHash() =>
    r'a09f465abf96b3ca9df0043c960ed426275e74df';

@ProviderFor(selectedSpaceTabCount)
final selectedSpaceTabCountProvider = SelectedSpaceTabCountProvider._();

final class SelectedSpaceTabCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  SelectedSpaceTabCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSpaceTabCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSpaceTabCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return selectedSpaceTabCount(ref);
  }
}

String _$selectedSpaceTabCountHash() =>
    r'beef0ad70d2fef417c1d13b742ee889e13b76fdd';
