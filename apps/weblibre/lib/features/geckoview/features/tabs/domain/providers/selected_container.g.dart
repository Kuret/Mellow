// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_container.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedContainer)
final selectedContainerProvider = SelectedContainerProvider._();

final class SelectedContainerProvider
    extends $NotifierProvider<SelectedContainer, String?> {
  SelectedContainerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedContainerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedContainerHash();

  @$internal
  @override
  SelectedContainer create() => SelectedContainer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedContainerHash() => r'523c62afc126aa037e9769d4815109e126d17808';

abstract class _$SelectedContainer extends $Notifier<String?> {
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

@ProviderFor(selectedContainerData)
final selectedContainerDataProvider = SelectedContainerDataProvider._();

final class SelectedContainerDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContainerData?>,
          ContainerData?,
          Stream<ContainerData?>
        >
    with $FutureModifier<ContainerData?>, $StreamProvider<ContainerData?> {
  SelectedContainerDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedContainerDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedContainerDataHash();

  @$internal
  @override
  $StreamProviderElement<ContainerData?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ContainerData?> create(Ref ref) {
    return selectedContainerData(ref);
  }
}

String _$selectedContainerDataHash() =>
    r'1ec86a82e1fc4823a867285f05036c903633a165';

/// Forces the home surface on regardless of what is selected.
///
/// The home-target setting needs a way to say "stay on home" that survives the
/// engine auto-selecting a tab underneath — for instance when the last tab in a
/// container is closed. Keeping it as a separate flag leaves
/// [shouldShowBrowserHome] a pure predicate, and avoids pinning the selected
/// container, which [SelectedContainer]'s own tab listener would immediately
/// undo.
///
/// Cleared by [TabRepository.selectTab] and by creating a tab, i.e. by the user
/// deliberately going somewhere.

@ProviderFor(ForceBrowserHome)
final forceBrowserHomeProvider = ForceBrowserHomeProvider._();

/// Forces the home surface on regardless of what is selected.
///
/// The home-target setting needs a way to say "stay on home" that survives the
/// engine auto-selecting a tab underneath — for instance when the last tab in a
/// container is closed. Keeping it as a separate flag leaves
/// [shouldShowBrowserHome] a pure predicate, and avoids pinning the selected
/// container, which [SelectedContainer]'s own tab listener would immediately
/// undo.
///
/// Cleared by [TabRepository.selectTab] and by creating a tab, i.e. by the user
/// deliberately going somewhere.
final class ForceBrowserHomeProvider
    extends $NotifierProvider<ForceBrowserHome, bool> {
  /// Forces the home surface on regardless of what is selected.
  ///
  /// The home-target setting needs a way to say "stay on home" that survives the
  /// engine auto-selecting a tab underneath — for instance when the last tab in a
  /// container is closed. Keeping it as a separate flag leaves
  /// [shouldShowBrowserHome] a pure predicate, and avoids pinning the selected
  /// container, which [SelectedContainer]'s own tab listener would immediately
  /// undo.
  ///
  /// Cleared by [TabRepository.selectTab] and by creating a tab, i.e. by the user
  /// deliberately going somewhere.
  ForceBrowserHomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forceBrowserHomeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forceBrowserHomeHash();

  @$internal
  @override
  ForceBrowserHome create() => ForceBrowserHome();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$forceBrowserHomeHash() => r'39bfad196c9e0a8ef90af2d84aa840d933927244';

/// Forces the home surface on regardless of what is selected.
///
/// The home-target setting needs a way to say "stay on home" that survives the
/// engine auto-selecting a tab underneath — for instance when the last tab in a
/// container is closed. Keeping it as a separate flag leaves
/// [shouldShowBrowserHome] a pure predicate, and avoids pinning the selected
/// container, which [SelectedContainer]'s own tab listener would immediately
/// undo.
///
/// Cleared by [TabRepository.selectTab] and by creating a tab, i.e. by the user
/// deliberately going somewhere.

abstract class _$ForceBrowserHome extends $Notifier<bool> {
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

/// Whether a remembered tab is being restored for a space that was just
/// selected.
///
/// [ShouldShowBrowserHome] holds its previous answer while this is set,
/// instead of flashing home for the frame or two the restore's DB reads take
/// — see [TabRepository.restoreSpaceTab], the only writer.

@ProviderFor(RestoringSpaceTab)
final restoringSpaceTabProvider = RestoringSpaceTabProvider._();

/// Whether a remembered tab is being restored for a space that was just
/// selected.
///
/// [ShouldShowBrowserHome] holds its previous answer while this is set,
/// instead of flashing home for the frame or two the restore's DB reads take
/// — see [TabRepository.restoreSpaceTab], the only writer.
final class RestoringSpaceTabProvider
    extends $NotifierProvider<RestoringSpaceTab, bool> {
  /// Whether a remembered tab is being restored for a space that was just
  /// selected.
  ///
  /// [ShouldShowBrowserHome] holds its previous answer while this is set,
  /// instead of flashing home for the frame or two the restore's DB reads take
  /// — see [TabRepository.restoreSpaceTab], the only writer.
  RestoringSpaceTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoringSpaceTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoringSpaceTabHash();

  @$internal
  @override
  RestoringSpaceTab create() => RestoringSpaceTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$restoringSpaceTabHash() => r'47041019254f67dc65f3f9039ae587c97702a7fe';

/// Whether a remembered tab is being restored for a space that was just
/// selected.
///
/// [ShouldShowBrowserHome] holds its previous answer while this is set,
/// instead of flashing home for the frame or two the restore's DB reads take
/// — see [TabRepository.restoreSpaceTab], the only writer.

abstract class _$RestoringSpaceTab extends $Notifier<bool> {
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

/// Whether the browser home screen should be displayed instead of the
/// active tab's content.
///
/// Returns `true` when any of the following hold:
/// 0. [ForceBrowserHome] is set, i.e. the home target asked to stay here.
/// 1. No tab is selected at all (app just started or all tabs closed).
/// 2. The selected tab belongs to a different space than the currently
///    selected space – this implies the user manually switched spaces after
///    selecting a tab, because tab selection automatically syncs the selected
///    space to match the tab's space. Tabs without a space (private tabs,
///    essentials) are visible from every space and never trigger this.
///
/// Condition (2) also implicitly covers the case where the selected space has
/// zero tabs: if the space has no tabs, the selected tab (if any) necessarily
/// belongs to a different space.
///
/// A [Notifier] rather than a plain function so it can hold its previous
/// answer (`stateOrNull`) while [RestoringSpaceTab] is in flight, instead of
/// flipping to home and back for the frame or two the restore's DB reads
/// take.

@ProviderFor(ShouldShowBrowserHome)
final shouldShowBrowserHomeProvider = ShouldShowBrowserHomeProvider._();

/// Whether the browser home screen should be displayed instead of the
/// active tab's content.
///
/// Returns `true` when any of the following hold:
/// 0. [ForceBrowserHome] is set, i.e. the home target asked to stay here.
/// 1. No tab is selected at all (app just started or all tabs closed).
/// 2. The selected tab belongs to a different space than the currently
///    selected space – this implies the user manually switched spaces after
///    selecting a tab, because tab selection automatically syncs the selected
///    space to match the tab's space. Tabs without a space (private tabs,
///    essentials) are visible from every space and never trigger this.
///
/// Condition (2) also implicitly covers the case where the selected space has
/// zero tabs: if the space has no tabs, the selected tab (if any) necessarily
/// belongs to a different space.
///
/// A [Notifier] rather than a plain function so it can hold its previous
/// answer (`stateOrNull`) while [RestoringSpaceTab] is in flight, instead of
/// flipping to home and back for the frame or two the restore's DB reads
/// take.
final class ShouldShowBrowserHomeProvider
    extends $NotifierProvider<ShouldShowBrowserHome, bool> {
  /// Whether the browser home screen should be displayed instead of the
  /// active tab's content.
  ///
  /// Returns `true` when any of the following hold:
  /// 0. [ForceBrowserHome] is set, i.e. the home target asked to stay here.
  /// 1. No tab is selected at all (app just started or all tabs closed).
  /// 2. The selected tab belongs to a different space than the currently
  ///    selected space – this implies the user manually switched spaces after
  ///    selecting a tab, because tab selection automatically syncs the selected
  ///    space to match the tab's space. Tabs without a space (private tabs,
  ///    essentials) are visible from every space and never trigger this.
  ///
  /// Condition (2) also implicitly covers the case where the selected space has
  /// zero tabs: if the space has no tabs, the selected tab (if any) necessarily
  /// belongs to a different space.
  ///
  /// A [Notifier] rather than a plain function so it can hold its previous
  /// answer (`stateOrNull`) while [RestoringSpaceTab] is in flight, instead of
  /// flipping to home and back for the frame or two the restore's DB reads
  /// take.
  ShouldShowBrowserHomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shouldShowBrowserHomeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shouldShowBrowserHomeHash();

  @$internal
  @override
  ShouldShowBrowserHome create() => ShouldShowBrowserHome();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$shouldShowBrowserHomeHash() =>
    r'54a6ff16eb2e7e5446ef078bcc0de5e6368948b1';

/// Whether the browser home screen should be displayed instead of the
/// active tab's content.
///
/// Returns `true` when any of the following hold:
/// 0. [ForceBrowserHome] is set, i.e. the home target asked to stay here.
/// 1. No tab is selected at all (app just started or all tabs closed).
/// 2. The selected tab belongs to a different space than the currently
///    selected space – this implies the user manually switched spaces after
///    selecting a tab, because tab selection automatically syncs the selected
///    space to match the tab's space. Tabs without a space (private tabs,
///    essentials) are visible from every space and never trigger this.
///
/// Condition (2) also implicitly covers the case where the selected space has
/// zero tabs: if the space has no tabs, the selected tab (if any) necessarily
/// belongs to a different space.
///
/// A [Notifier] rather than a plain function so it can hold its previous
/// answer (`stateOrNull`) while [RestoringSpaceTab] is in flight, instead of
/// flipping to home and back for the frame or two the restore's DB reads
/// take.

abstract class _$ShouldShowBrowserHome extends $Notifier<bool> {
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

@ProviderFor(selectedContainerTabCount)
final selectedContainerTabCountProvider = SelectedContainerTabCountProvider._();

final class SelectedContainerTabCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  SelectedContainerTabCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedContainerTabCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedContainerTabCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return selectedContainerTabCount(ref);
  }
}

String _$selectedContainerTabCountHash() =>
    r'b763f949210ac9106d4a9240c0e65bdfae2d18ec';
