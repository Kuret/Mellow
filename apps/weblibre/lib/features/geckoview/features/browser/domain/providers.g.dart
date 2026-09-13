// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(canManualTabReorder)
final canManualTabReorderProvider = CanManualTabReorderProvider._();

final class CanManualTabReorderProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  CanManualTabReorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canManualTabReorderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canManualTabReorderHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return canManualTabReorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$canManualTabReorderHash() =>
    r'ba5d961933464b6e005d7945802908a9a4ae034b';

/// The engine the user picked for the search they are composing, overriding
/// their standing default.
///
/// Keyed by [domain] so a choice made while editing a site's address stays
/// with that site: the unkeyed instance is the global one. Null means "no
/// override", not "no engine" — the caller falls back to
/// `defaultSearchProviderProvider`, which always answers.

@ProviderFor(SelectedSearchProvider)
final selectedSearchProviderProvider = SelectedSearchProviderFamily._();

/// The engine the user picked for the search they are composing, overriding
/// their standing default.
///
/// Keyed by [domain] so a choice made while editing a site's address stays
/// with that site: the unkeyed instance is the global one. Null means "no
/// override", not "no engine" — the caller falls back to
/// `defaultSearchProviderProvider`, which always answers.
final class SelectedSearchProviderProvider
    extends $NotifierProvider<SelectedSearchProvider, SearchProvider?> {
  /// The engine the user picked for the search they are composing, overriding
  /// their standing default.
  ///
  /// Keyed by [domain] so a choice made while editing a site's address stays
  /// with that site: the unkeyed instance is the global one. Null means "no
  /// override", not "no engine" — the caller falls back to
  /// `defaultSearchProviderProvider`, which always answers.
  SelectedSearchProviderProvider._({
    required SelectedSearchProviderFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'selectedSearchProviderProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectedSearchProviderHash();

  @override
  String toString() {
    return r'selectedSearchProviderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SelectedSearchProvider create() => SelectedSearchProvider();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchProvider? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchProvider?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectedSearchProviderProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectedSearchProviderHash() =>
    r'f3db57c2359c9018371fa6cf0184396e2472d9cd';

/// The engine the user picked for the search they are composing, overriding
/// their standing default.
///
/// Keyed by [domain] so a choice made while editing a site's address stays
/// with that site: the unkeyed instance is the global one. Null means "no
/// override", not "no engine" — the caller falls back to
/// `defaultSearchProviderProvider`, which always answers.

final class SelectedSearchProviderFamily extends $Family
    with
        $ClassFamilyOverride<
          SelectedSearchProvider,
          SearchProvider?,
          SearchProvider?,
          SearchProvider?,
          String?
        > {
  SelectedSearchProviderFamily._()
    : super(
        retry: null,
        name: r'selectedSearchProviderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The engine the user picked for the search they are composing, overriding
  /// their standing default.
  ///
  /// Keyed by [domain] so a choice made while editing a site's address stays
  /// with that site: the unkeyed instance is the global one. Null means "no
  /// override", not "no engine" — the caller falls back to
  /// `defaultSearchProviderProvider`, which always answers.

  SelectedSearchProviderProvider call({String? domain}) =>
      SelectedSearchProviderProvider._(argument: domain, from: this);

  @override
  String toString() => r'selectedSearchProviderProvider';
}

/// The engine the user picked for the search they are composing, overriding
/// their standing default.
///
/// Keyed by [domain] so a choice made while editing a site's address stays
/// with that site: the unkeyed instance is the global one. Null means "no
/// override", not "no engine" — the caller falls back to
/// `defaultSearchProviderProvider`, which always answers.

abstract class _$SelectedSearchProvider extends $Notifier<SearchProvider?> {
  late final _$args = ref.$arg as String?;
  String? get domain => _$args;

  SearchProvider? build({String? domain});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchProvider?, SearchProvider?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchProvider?, SearchProvider?>,
              SearchProvider?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(domain: _$args));
  }
}

@ProviderFor(containerTabEntities)
final containerTabEntitiesProvider = ContainerTabEntitiesFamily._();

final class ContainerTabEntitiesProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<DefaultTabEntity>>,
          EquatableValue<List<DefaultTabEntity>>,
          EquatableValue<List<DefaultTabEntity>>
        >
    with $Provider<EquatableValue<List<DefaultTabEntity>>> {
  ContainerTabEntitiesProvider._({
    required ContainerTabEntitiesFamily super.from,
    required ContainerFilter super.argument,
  }) : super(
         retry: null,
         name: r'containerTabEntitiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$containerTabEntitiesHash();

  @override
  String toString() {
    return r'containerTabEntitiesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<EquatableValue<List<DefaultTabEntity>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<DefaultTabEntity>> create(Ref ref) {
    final argument = this.argument as ContainerFilter;
    return containerTabEntities(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<List<DefaultTabEntity>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<EquatableValue<List<DefaultTabEntity>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ContainerTabEntitiesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$containerTabEntitiesHash() =>
    r'bcd932968bae46fb5e27a60819ea7aad7a8e41e7';

final class ContainerTabEntitiesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          EquatableValue<List<DefaultTabEntity>>,
          ContainerFilter
        > {
  ContainerTabEntitiesFamily._()
    : super(
        retry: null,
        name: r'containerTabEntitiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContainerTabEntitiesProvider call(ContainerFilter containerFilter) =>
      ContainerTabEntitiesProvider._(argument: containerFilter, from: this);

  @override
  String toString() => r'containerTabEntitiesProvider';
}

@ProviderFor(containerTabStates)
final containerTabStatesProvider = ContainerTabStatesFamily._();

final class ContainerTabStatesProvider
    extends
        $FunctionalProvider<
          EquatableValue<Map<String, TabState>>,
          EquatableValue<Map<String, TabState>>,
          EquatableValue<Map<String, TabState>>
        >
    with $Provider<EquatableValue<Map<String, TabState>>> {
  ContainerTabStatesProvider._({
    required ContainerTabStatesFamily super.from,
    required ContainerFilter super.argument,
  }) : super(
         retry: null,
         name: r'containerTabStatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$containerTabStatesHash();

  @override
  String toString() {
    return r'containerTabStatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<EquatableValue<Map<String, TabState>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<Map<String, TabState>> create(Ref ref) {
    final argument = this.argument as ContainerFilter;
    return containerTabStates(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<Map<String, TabState>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<EquatableValue<Map<String, TabState>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ContainerTabStatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$containerTabStatesHash() =>
    r'320f35a2605b53ab57b299caafd9b71804b67c6c';

final class ContainerTabStatesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          EquatableValue<Map<String, TabState>>,
          ContainerFilter
        > {
  ContainerTabStatesFamily._()
    : super(
        retry: null,
        name: r'containerTabStatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContainerTabStatesProvider call(ContainerFilter containerFilter) =>
      ContainerTabStatesProvider._(argument: containerFilter, from: this);

  @override
  String toString() => r'containerTabStatesProvider';
}

/// Whether a tab row has an engine session behind it — see [TabPresence].
///
/// Live as soon as the engine reports state; cold when the row says so
/// (`engine_tab_id IS NULL`); restoring in between.

@ProviderFor(tabPresence)
final tabPresenceProvider = TabPresenceFamily._();

/// Whether a tab row has an engine session behind it — see [TabPresence].
///
/// Live as soon as the engine reports state; cold when the row says so
/// (`engine_tab_id IS NULL`); restoring in between.

final class TabPresenceProvider
    extends $FunctionalProvider<TabPresence, TabPresence, TabPresence>
    with $Provider<TabPresence> {
  /// Whether a tab row has an engine session behind it — see [TabPresence].
  ///
  /// Live as soon as the engine reports state; cold when the row says so
  /// (`engine_tab_id IS NULL`); restoring in between.
  TabPresenceProvider._({
    required TabPresenceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tabPresenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tabPresenceHash();

  @override
  String toString() {
    return r'tabPresenceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TabPresence> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TabPresence create(Ref ref) {
    final argument = this.argument as String;
    return tabPresence(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TabPresence value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TabPresence>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TabPresenceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tabPresenceHash() => r'046e32ee98b94b166872285ab3ce2df47c86ca33';

/// Whether a tab row has an engine session behind it — see [TabPresence].
///
/// Live as soon as the engine reports state; cold when the row says so
/// (`engine_tab_id IS NULL`); restoring in between.

final class TabPresenceFamily extends $Family
    with $FunctionalFamilyOverride<TabPresence, String> {
  TabPresenceFamily._()
    : super(
        retry: null,
        name: r'tabPresenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether a tab row has an engine session behind it — see [TabPresence].
  ///
  /// Live as soon as the engine reports state; cold when the row says so
  /// (`engine_tab_id IS NULL`); restoring in between.

  TabPresenceProvider call(String tabId) =>
      TabPresenceProvider._(argument: tabId, from: this);

  @override
  String toString() => r'tabPresenceProvider';
}

/// Ids of DB-cached live tabs whose native state hasn't arrived yet. Empty
/// once the session restore completed (afterwards a live row without native
/// state is on its way to being demoted, not pending). Cold rows are not
/// pending either: they render as placeholders for good — see
/// [tabPresenceProvider].

@ProviderFor(pendingRestoreTabIds)
final pendingRestoreTabIdsProvider = PendingRestoreTabIdsProvider._();

/// Ids of DB-cached live tabs whose native state hasn't arrived yet. Empty
/// once the session restore completed (afterwards a live row without native
/// state is on its way to being demoted, not pending). Cold rows are not
/// pending either: they render as placeholders for good — see
/// [tabPresenceProvider].

final class PendingRestoreTabIdsProvider
    extends
        $FunctionalProvider<
          EquatableValue<Set<String>>,
          EquatableValue<Set<String>>,
          EquatableValue<Set<String>>
        >
    with $Provider<EquatableValue<Set<String>>> {
  /// Ids of DB-cached live tabs whose native state hasn't arrived yet. Empty
  /// once the session restore completed (afterwards a live row without native
  /// state is on its way to being demoted, not pending). Cold rows are not
  /// pending either: they render as placeholders for good — see
  /// [tabPresenceProvider].
  PendingRestoreTabIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingRestoreTabIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingRestoreTabIdsHash();

  @$internal
  @override
  $ProviderElement<EquatableValue<Set<String>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<Set<String>> create(Ref ref) {
    return pendingRestoreTabIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<Set<String>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EquatableValue<Set<String>>>(value),
    );
  }
}

String _$pendingRestoreTabIdsHash() =>
    r'94ae740b08dbdf592df4f8502f8988a4e2888c56';

@ProviderFor(fifoTabStates)
final fifoTabStatesProvider = FifoTabStatesProvider._();

final class FifoTabStatesProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<TabStateWithContainer>>,
          EquatableValue<List<TabStateWithContainer>>,
          EquatableValue<List<TabStateWithContainer>>
        >
    with $Provider<EquatableValue<List<TabStateWithContainer>>> {
  FifoTabStatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fifoTabStatesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fifoTabStatesHash();

  @$internal
  @override
  $ProviderElement<EquatableValue<List<TabStateWithContainer>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<TabStateWithContainer>> create(Ref ref) {
    return fifoTabStates(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    EquatableValue<List<TabStateWithContainer>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<EquatableValue<List<TabStateWithContainer>>>(
            value,
          ),
    );
  }
}

String _$fifoTabStatesHash() => r'8d5f507f144ba9672e33f951d56969bc8db11bcf';

/// The selected space's tabs (pinned and normal shelves) with their
/// containers, in the order the quick tab switcher and the tab bar draw them.
/// Cold and restoring rows render as placeholders.

@ProviderFor(selectedSpaceTabStatesWithContainer)
final selectedSpaceTabStatesWithContainerProvider =
    SelectedSpaceTabStatesWithContainerProvider._();

/// The selected space's tabs (pinned and normal shelves) with their
/// containers, in the order the quick tab switcher and the tab bar draw them.
/// Cold and restoring rows render as placeholders.

final class SelectedSpaceTabStatesWithContainerProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<TabStateWithContainer>>,
          EquatableValue<List<TabStateWithContainer>>,
          EquatableValue<List<TabStateWithContainer>>
        >
    with $Provider<EquatableValue<List<TabStateWithContainer>>> {
  /// The selected space's tabs (pinned and normal shelves) with their
  /// containers, in the order the quick tab switcher and the tab bar draw them.
  /// Cold and restoring rows render as placeholders.
  SelectedSpaceTabStatesWithContainerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSpaceTabStatesWithContainerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$selectedSpaceTabStatesWithContainerHash();

  @$internal
  @override
  $ProviderElement<EquatableValue<List<TabStateWithContainer>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<TabStateWithContainer>> create(Ref ref) {
    return selectedSpaceTabStatesWithContainer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    EquatableValue<List<TabStateWithContainer>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<EquatableValue<List<TabStateWithContainer>>>(
            value,
          ),
    );
  }
}

String _$selectedSpaceTabStatesWithContainerHash() =>
    r'46272edca7ca84e4933425fc98ca49f53d115af2';

/// [selectedSpaceTabStatesWithContainerProvider] for any one space. The bar
/// and the rail slide between spaces, and the outgoing space keeps rendering
/// its own tabs while it leaves.

@ProviderFor(spaceTabStatesWithContainer)
final spaceTabStatesWithContainerProvider =
    SpaceTabStatesWithContainerFamily._();

/// [selectedSpaceTabStatesWithContainerProvider] for any one space. The bar
/// and the rail slide between spaces, and the outgoing space keeps rendering
/// its own tabs while it leaves.

final class SpaceTabStatesWithContainerProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<TabStateWithContainer>>,
          EquatableValue<List<TabStateWithContainer>>,
          EquatableValue<List<TabStateWithContainer>>
        >
    with $Provider<EquatableValue<List<TabStateWithContainer>>> {
  /// [selectedSpaceTabStatesWithContainerProvider] for any one space. The bar
  /// and the rail slide between spaces, and the outgoing space keeps rendering
  /// its own tabs while it leaves.
  SpaceTabStatesWithContainerProvider._({
    required SpaceTabStatesWithContainerFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'spaceTabStatesWithContainerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$spaceTabStatesWithContainerHash();

  @override
  String toString() {
    return r'spaceTabStatesWithContainerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<EquatableValue<List<TabStateWithContainer>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<TabStateWithContainer>> create(Ref ref) {
    final argument = this.argument as String?;
    return spaceTabStatesWithContainer(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    EquatableValue<List<TabStateWithContainer>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<EquatableValue<List<TabStateWithContainer>>>(
            value,
          ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpaceTabStatesWithContainerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$spaceTabStatesWithContainerHash() =>
    r'75e34225494a657b143d103360023e054af959aa';

/// [selectedSpaceTabStatesWithContainerProvider] for any one space. The bar
/// and the rail slide between spaces, and the outgoing space keeps rendering
/// its own tabs while it leaves.

final class SpaceTabStatesWithContainerFamily extends $Family
    with
        $FunctionalFamilyOverride<
          EquatableValue<List<TabStateWithContainer>>,
          String?
        > {
  SpaceTabStatesWithContainerFamily._()
    : super(
        retry: null,
        name: r'spaceTabStatesWithContainerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [selectedSpaceTabStatesWithContainerProvider] for any one space. The bar
  /// and the rail slide between spaces, and the outgoing space keeps rendering
  /// its own tabs while it leaves.

  SpaceTabStatesWithContainerProvider call(String? spaceUuid) =>
      SpaceTabStatesWithContainerProvider._(argument: spaceUuid, from: this);

  @override
  String toString() => r'spaceTabStatesWithContainerProvider';
}

@ProviderFor(suggestedTabEntities)
final suggestedTabEntitiesProvider = SuggestedTabEntitiesFamily._();

final class SuggestedTabEntitiesProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<TabEntity>>,
          EquatableValue<List<TabEntity>>,
          EquatableValue<List<TabEntity>>
        >
    with $Provider<EquatableValue<List<TabEntity>>> {
  SuggestedTabEntitiesProvider._({
    required SuggestedTabEntitiesFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'suggestedTabEntitiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$suggestedTabEntitiesHash();

  @override
  String toString() {
    return r'suggestedTabEntitiesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<EquatableValue<List<TabEntity>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<TabEntity>> create(Ref ref) {
    final argument = this.argument as String?;
    return suggestedTabEntities(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<List<TabEntity>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EquatableValue<List<TabEntity>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SuggestedTabEntitiesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$suggestedTabEntitiesHash() =>
    r'b140a1d0badad3d976b91ab9154300873a8bd4e9';

final class SuggestedTabEntitiesFamily extends $Family
    with $FunctionalFamilyOverride<EquatableValue<List<TabEntity>>, String?> {
  SuggestedTabEntitiesFamily._()
    : super(
        retry: null,
        name: r'suggestedTabEntitiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SuggestedTabEntitiesProvider call(String? containerId) =>
      SuggestedTabEntitiesProvider._(argument: containerId, from: this);

  @override
  String toString() => r'suggestedTabEntitiesProvider';
}

@ProviderFor(seamlessFilteredTabEntities)
final seamlessFilteredTabEntitiesProvider =
    SeamlessFilteredTabEntitiesFamily._();

final class SeamlessFilteredTabEntitiesProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<TabEntity>>,
          EquatableValue<List<TabEntity>>,
          EquatableValue<List<TabEntity>>
        >
    with $Provider<EquatableValue<List<TabEntity>>> {
  SeamlessFilteredTabEntitiesProvider._({
    required SeamlessFilteredTabEntitiesFamily super.from,
    required ({
      TabSearchPartition searchPartition,
      ContainerFilter containerFilter,
      bool groupTrees,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'seamlessFilteredTabEntitiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$seamlessFilteredTabEntitiesHash();

  @override
  String toString() {
    return r'seamlessFilteredTabEntitiesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<EquatableValue<List<TabEntity>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<TabEntity>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              TabSearchPartition searchPartition,
              ContainerFilter containerFilter,
              bool groupTrees,
            });
    return seamlessFilteredTabEntities(
      ref,
      searchPartition: argument.searchPartition,
      containerFilter: argument.containerFilter,
      groupTrees: argument.groupTrees,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<List<TabEntity>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EquatableValue<List<TabEntity>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SeamlessFilteredTabEntitiesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seamlessFilteredTabEntitiesHash() =>
    r'e2dcbff7c67bf11bbc7ba683388b8f1c4484b7ef';

final class SeamlessFilteredTabEntitiesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          EquatableValue<List<TabEntity>>,
          ({
            TabSearchPartition searchPartition,
            ContainerFilter containerFilter,
            bool groupTrees,
          })
        > {
  SeamlessFilteredTabEntitiesFamily._()
    : super(
        retry: null,
        name: r'seamlessFilteredTabEntitiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SeamlessFilteredTabEntitiesProvider call({
    required TabSearchPartition searchPartition,
    required ContainerFilter containerFilter,
    required bool groupTrees,
  }) => SeamlessFilteredTabEntitiesProvider._(
    argument: (
      searchPartition: searchPartition,
      containerFilter: containerFilter,
      groupTrees: groupTrees,
    ),
    from: this,
  );

  @override
  String toString() => r'seamlessFilteredTabEntitiesProvider';
}

@ProviderFor(filteredTabPreviews)
final filteredTabPreviewsProvider = FilteredTabPreviewsFamily._();

final class FilteredTabPreviewsProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<TabPreview>>,
          EquatableValue<List<TabPreview>>,
          EquatableValue<List<TabPreview>>
        >
    with $Provider<EquatableValue<List<TabPreview>>> {
  FilteredTabPreviewsProvider._({
    required FilteredTabPreviewsFamily super.from,
    required (TabSearchPartition, ContainerFilter) super.argument,
  }) : super(
         retry: null,
         name: r'filteredTabPreviewsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredTabPreviewsHash();

  @override
  String toString() {
    return r'filteredTabPreviewsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<EquatableValue<List<TabPreview>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<TabPreview>> create(Ref ref) {
    final argument = this.argument as (TabSearchPartition, ContainerFilter);
    return filteredTabPreviews(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<List<TabPreview>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EquatableValue<List<TabPreview>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredTabPreviewsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredTabPreviewsHash() =>
    r'2327ad86650b3baa6b9339e280abfc7463c72cf9';

final class FilteredTabPreviewsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          EquatableValue<List<TabPreview>>,
          (TabSearchPartition, ContainerFilter)
        > {
  FilteredTabPreviewsFamily._()
    : super(
        retry: null,
        name: r'filteredTabPreviewsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredTabPreviewsProvider call(
    TabSearchPartition searchPartition,
    ContainerFilter containerFilter,
  ) => FilteredTabPreviewsProvider._(
    argument: (searchPartition, containerFilter),
    from: this,
  );

  @override
  String toString() => r'filteredTabPreviewsProvider';
}

/// Grouped flat-list rendering shared by every surface that lays tabs out in
/// one ordered sequence.
///
/// Parent rows always render before their descendants. [TabDirection]
/// applies both to root group ordering and to sibling ordering below each
/// parent, so parent-child pairs stay together while child order still follows
/// the configured direction.
///
/// [scope] decides which of the tray's controls take part and which direction
/// setting applies — see [TabListScope]. Both scopes run the same grouping,
/// so a tab's place relative to its parent never depends on who is asking.
///
/// [ignoreDirection] renders storage order (`order_key` ascending, the order
/// the desktop sidebar shows) whatever the direction setting says; the wide
/// rail mirrors the desktop and asks for it.
///
/// Returns `null` when the input data is not yet available (loading).

@ProviderFor(groupedTabListItems)
final groupedTabListItemsProvider = GroupedTabListItemsFamily._();

/// Grouped flat-list rendering shared by every surface that lays tabs out in
/// one ordered sequence.
///
/// Parent rows always render before their descendants. [TabDirection]
/// applies both to root group ordering and to sibling ordering below each
/// parent, so parent-child pairs stay together while child order still follows
/// the configured direction.
///
/// [scope] decides which of the tray's controls take part and which direction
/// setting applies — see [TabListScope]. Both scopes run the same grouping,
/// so a tab's place relative to its parent never depends on who is asking.
///
/// [ignoreDirection] renders storage order (`order_key` ascending, the order
/// the desktop sidebar shows) whatever the direction setting says; the wide
/// rail mirrors the desktop and asks for it.
///
/// Returns `null` when the input data is not yet available (loading).

final class GroupedTabListItemsProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<TabListItemEntity>>,
          EquatableValue<List<TabListItemEntity>>,
          EquatableValue<List<TabListItemEntity>>
        >
    with $Provider<EquatableValue<List<TabListItemEntity>>> {
  /// Grouped flat-list rendering shared by every surface that lays tabs out in
  /// one ordered sequence.
  ///
  /// Parent rows always render before their descendants. [TabDirection]
  /// applies both to root group ordering and to sibling ordering below each
  /// parent, so parent-child pairs stay together while child order still follows
  /// the configured direction.
  ///
  /// [scope] decides which of the tray's controls take part and which direction
  /// setting applies — see [TabListScope]. Both scopes run the same grouping,
  /// so a tab's place relative to its parent never depends on who is asking.
  ///
  /// [ignoreDirection] renders storage order (`order_key` ascending, the order
  /// the desktop sidebar shows) whatever the direction setting says; the wide
  /// rail mirrors the desktop and asks for it.
  ///
  /// Returns `null` when the input data is not yet available (loading).
  GroupedTabListItemsProvider._({
    required GroupedTabListItemsFamily super.from,
    required ({String? spaceUuid, TabListScope scope, bool ignoreDirection})
    super.argument,
  }) : super(
         retry: null,
         name: r'groupedTabListItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupedTabListItemsHash();

  @override
  String toString() {
    return r'groupedTabListItemsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<EquatableValue<List<TabListItemEntity>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<TabListItemEntity>> create(Ref ref) {
    final argument =
        this.argument
            as ({String? spaceUuid, TabListScope scope, bool ignoreDirection});
    return groupedTabListItems(
      ref,
      spaceUuid: argument.spaceUuid,
      scope: argument.scope,
      ignoreDirection: argument.ignoreDirection,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<List<TabListItemEntity>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<EquatableValue<List<TabListItemEntity>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GroupedTabListItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupedTabListItemsHash() =>
    r'43c81c1995e3efc01e395ef07ea723a1bc33416c';

/// Grouped flat-list rendering shared by every surface that lays tabs out in
/// one ordered sequence.
///
/// Parent rows always render before their descendants. [TabDirection]
/// applies both to root group ordering and to sibling ordering below each
/// parent, so parent-child pairs stay together while child order still follows
/// the configured direction.
///
/// [scope] decides which of the tray's controls take part and which direction
/// setting applies — see [TabListScope]. Both scopes run the same grouping,
/// so a tab's place relative to its parent never depends on who is asking.
///
/// [ignoreDirection] renders storage order (`order_key` ascending, the order
/// the desktop sidebar shows) whatever the direction setting says; the wide
/// rail mirrors the desktop and asks for it.
///
/// Returns `null` when the input data is not yet available (loading).

final class GroupedTabListItemsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          EquatableValue<List<TabListItemEntity>>,
          ({String? spaceUuid, TabListScope scope, bool ignoreDirection})
        > {
  GroupedTabListItemsFamily._()
    : super(
        retry: null,
        name: r'groupedTabListItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Grouped flat-list rendering shared by every surface that lays tabs out in
  /// one ordered sequence.
  ///
  /// Parent rows always render before their descendants. [TabDirection]
  /// applies both to root group ordering and to sibling ordering below each
  /// parent, so parent-child pairs stay together while child order still follows
  /// the configured direction.
  ///
  /// [scope] decides which of the tray's controls take part and which direction
  /// setting applies — see [TabListScope]. Both scopes run the same grouping,
  /// so a tab's place relative to its parent never depends on who is asking.
  ///
  /// [ignoreDirection] renders storage order (`order_key` ascending, the order
  /// the desktop sidebar shows) whatever the direction setting says; the wide
  /// rail mirrors the desktop and asks for it.
  ///
  /// Returns `null` when the input data is not yet available (loading).

  GroupedTabListItemsProvider call({
    required String? spaceUuid,
    required TabListScope scope,
    bool ignoreDirection = false,
  }) => GroupedTabListItemsProvider._(
    argument: (
      spaceUuid: spaceUuid,
      scope: scope,
      ignoreDirection: ignoreDirection,
    ),
    from: this,
  );

  @override
  String toString() => r'groupedTabListItemsProvider';
}

/// The final row order a surface renders, i.e. [groupedTabListItemsProvider]
/// plus the flat post-processing: where there are no visible groups to keep
/// together, pinned tabs move ahead of unpinned ones across the whole list.
///
/// That flattening applies to the tray only with hierarchy display turned off,
/// but always in [TabListScope.presentation] — the quick tab switcher and the
/// tab bar are single strips of chips that draw hierarchy as an indent glyph
/// rather than as position, so a pinned tab belongs at the front there whether
/// or not it happens to sit under a parent. Folder members are the exception:
/// they are pinned tabs by construction (PLAN §6.4) but stay under their
/// folder row, which is where the eye looks for them; only the space's root
/// pinned tabs float.
///
/// This is the single order every non-tray surface reads: the switcher, the tab
/// bar and sequential tab navigation all take the presentation scope, so
/// "the tab after this one" cannot mean one thing to the eye and another to a
/// swipe.

@ProviderFor(visibleTabListItems)
final visibleTabListItemsProvider = VisibleTabListItemsFamily._();

/// The final row order a surface renders, i.e. [groupedTabListItemsProvider]
/// plus the flat post-processing: where there are no visible groups to keep
/// together, pinned tabs move ahead of unpinned ones across the whole list.
///
/// That flattening applies to the tray only with hierarchy display turned off,
/// but always in [TabListScope.presentation] — the quick tab switcher and the
/// tab bar are single strips of chips that draw hierarchy as an indent glyph
/// rather than as position, so a pinned tab belongs at the front there whether
/// or not it happens to sit under a parent. Folder members are the exception:
/// they are pinned tabs by construction (PLAN §6.4) but stay under their
/// folder row, which is where the eye looks for them; only the space's root
/// pinned tabs float.
///
/// This is the single order every non-tray surface reads: the switcher, the tab
/// bar and sequential tab navigation all take the presentation scope, so
/// "the tab after this one" cannot mean one thing to the eye and another to a
/// swipe.

final class VisibleTabListItemsProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<TabListItemEntity>>,
          EquatableValue<List<TabListItemEntity>>,
          EquatableValue<List<TabListItemEntity>>
        >
    with $Provider<EquatableValue<List<TabListItemEntity>>> {
  /// The final row order a surface renders, i.e. [groupedTabListItemsProvider]
  /// plus the flat post-processing: where there are no visible groups to keep
  /// together, pinned tabs move ahead of unpinned ones across the whole list.
  ///
  /// That flattening applies to the tray only with hierarchy display turned off,
  /// but always in [TabListScope.presentation] — the quick tab switcher and the
  /// tab bar are single strips of chips that draw hierarchy as an indent glyph
  /// rather than as position, so a pinned tab belongs at the front there whether
  /// or not it happens to sit under a parent. Folder members are the exception:
  /// they are pinned tabs by construction (PLAN §6.4) but stay under their
  /// folder row, which is where the eye looks for them; only the space's root
  /// pinned tabs float.
  ///
  /// This is the single order every non-tray surface reads: the switcher, the tab
  /// bar and sequential tab navigation all take the presentation scope, so
  /// "the tab after this one" cannot mean one thing to the eye and another to a
  /// swipe.
  VisibleTabListItemsProvider._({
    required VisibleTabListItemsFamily super.from,
    required ({String? spaceUuid, TabListScope scope, bool ignoreDirection})
    super.argument,
  }) : super(
         retry: null,
         name: r'visibleTabListItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$visibleTabListItemsHash();

  @override
  String toString() {
    return r'visibleTabListItemsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<EquatableValue<List<TabListItemEntity>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<TabListItemEntity>> create(Ref ref) {
    final argument =
        this.argument
            as ({String? spaceUuid, TabListScope scope, bool ignoreDirection});
    return visibleTabListItems(
      ref,
      spaceUuid: argument.spaceUuid,
      scope: argument.scope,
      ignoreDirection: argument.ignoreDirection,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<List<TabListItemEntity>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<EquatableValue<List<TabListItemEntity>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VisibleTabListItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$visibleTabListItemsHash() =>
    r'468e8f51b2ec1c511912f582260b04a9838b3629';

/// The final row order a surface renders, i.e. [groupedTabListItemsProvider]
/// plus the flat post-processing: where there are no visible groups to keep
/// together, pinned tabs move ahead of unpinned ones across the whole list.
///
/// That flattening applies to the tray only with hierarchy display turned off,
/// but always in [TabListScope.presentation] — the quick tab switcher and the
/// tab bar are single strips of chips that draw hierarchy as an indent glyph
/// rather than as position, so a pinned tab belongs at the front there whether
/// or not it happens to sit under a parent. Folder members are the exception:
/// they are pinned tabs by construction (PLAN §6.4) but stay under their
/// folder row, which is where the eye looks for them; only the space's root
/// pinned tabs float.
///
/// This is the single order every non-tray surface reads: the switcher, the tab
/// bar and sequential tab navigation all take the presentation scope, so
/// "the tab after this one" cannot mean one thing to the eye and another to a
/// swipe.

final class VisibleTabListItemsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          EquatableValue<List<TabListItemEntity>>,
          ({String? spaceUuid, TabListScope scope, bool ignoreDirection})
        > {
  VisibleTabListItemsFamily._()
    : super(
        retry: null,
        name: r'visibleTabListItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The final row order a surface renders, i.e. [groupedTabListItemsProvider]
  /// plus the flat post-processing: where there are no visible groups to keep
  /// together, pinned tabs move ahead of unpinned ones across the whole list.
  ///
  /// That flattening applies to the tray only with hierarchy display turned off,
  /// but always in [TabListScope.presentation] — the quick tab switcher and the
  /// tab bar are single strips of chips that draw hierarchy as an indent glyph
  /// rather than as position, so a pinned tab belongs at the front there whether
  /// or not it happens to sit under a parent. Folder members are the exception:
  /// they are pinned tabs by construction (PLAN §6.4) but stay under their
  /// folder row, which is where the eye looks for them; only the space's root
  /// pinned tabs float.
  ///
  /// This is the single order every non-tray surface reads: the switcher, the tab
  /// bar and sequential tab navigation all take the presentation scope, so
  /// "the tab after this one" cannot mean one thing to the eye and another to a
  /// swipe.

  VisibleTabListItemsProvider call({
    required String? spaceUuid,
    required TabListScope scope,
    bool ignoreDirection = false,
  }) => VisibleTabListItemsProvider._(
    argument: (
      spaceUuid: spaceUuid,
      scope: scope,
      ignoreDirection: ignoreDirection,
    ),
    from: this,
  );

  @override
  String toString() => r'visibleTabListItemsProvider';
}

/// Flat tab id order used by sequential tab navigation: the tab bar swipe
/// action and the next/previous tab gestures.
///
/// Navigation follows the rendered order instead of the raw storage
/// `order_key`, so it carries tree grouping and pinned-first handling — stepping
/// to the tab the user sees next to the current one rather than to an unrelated
/// `order_key` neighbour.
///
/// The order it follows is [TabListScope.presentation], the one the quick tab
/// switcher and the tab bar draw, *not* the tray's. Both gestures are only
/// reachable with the tray closed, so the tray's filters, collapsed groups and
/// title/URL/date sort describe a list nobody is looking at while they fire;
/// letting them through made the swipe skip chips that were plainly on screen
/// and, when they hid the current tab outright, jump to the far end of the
/// strip (issue #603). Sharing one provider with those surfaces is what keeps
/// the two from drifting apart again.
///
/// With `sequentialTabNavigationCrossContainers` on (the default) it spans
/// **all** containers, keeping the boundary-crossing reach the storage-order
/// walk had: each container contributes the rows its switcher would render, and
/// the containers follow one another in the order the quick tab switcher lays
/// them out — the unassigned bucket first, then containers by pinned/`order_key`.
/// Stepping off the end of one container therefore continues into the next, and
/// selecting that tab moves the selected container along with it. Named
/// containers holding no tabs are skipped so their tree query never runs.
///
/// With the setting off the order holds only the selected container's rows, so
/// navigation stays inside the container the user is looking at and stops at its
/// edge — the containers themselves are then only switched deliberately.
///
/// "Previous" is a step towards the top of that order and "next" a step
/// towards its end, so direction follows `tabBarDirection` (baked into the
/// order) rather than `tabListDirection` — the bar is what the step is read
/// against, and the two only disagree when the user sets them apart.
///
/// The tray's own search results are deliberately not part of this: the swipe
/// and the gestures are only reachable with the tray closed.
///
/// `null` means the underlying tree data has not arrived yet — the only state
/// in which the caller may fall back to storage order. An empty list is a real
/// answer ("this container holds nothing to move to") and must not be mistaken
/// for a missing one.
///
/// Kept alive and actively listened to by [TabRepository]: it is consumed by a
/// synchronous `ref.read` at the moment of the swipe/gesture, from outside the
/// widget tree. Without a listener Riverpod pauses the chain when nothing is on
/// screen watching it, so the order could go stale — or be created empty on the
/// read, with its tree stream still loading, and silently drop navigation back
/// to storage order. The selected container's chain is alive anyway whenever the
/// quick tab switcher or the tray is on screen; the price of crossing container
/// boundaries is that the other populated containers' tree queries are kept
/// alive too.

@ProviderFor(sequentialTabNavigationOrder)
final sequentialTabNavigationOrderProvider =
    SequentialTabNavigationOrderProvider._();

/// Flat tab id order used by sequential tab navigation: the tab bar swipe
/// action and the next/previous tab gestures.
///
/// Navigation follows the rendered order instead of the raw storage
/// `order_key`, so it carries tree grouping and pinned-first handling — stepping
/// to the tab the user sees next to the current one rather than to an unrelated
/// `order_key` neighbour.
///
/// The order it follows is [TabListScope.presentation], the one the quick tab
/// switcher and the tab bar draw, *not* the tray's. Both gestures are only
/// reachable with the tray closed, so the tray's filters, collapsed groups and
/// title/URL/date sort describe a list nobody is looking at while they fire;
/// letting them through made the swipe skip chips that were plainly on screen
/// and, when they hid the current tab outright, jump to the far end of the
/// strip (issue #603). Sharing one provider with those surfaces is what keeps
/// the two from drifting apart again.
///
/// With `sequentialTabNavigationCrossContainers` on (the default) it spans
/// **all** containers, keeping the boundary-crossing reach the storage-order
/// walk had: each container contributes the rows its switcher would render, and
/// the containers follow one another in the order the quick tab switcher lays
/// them out — the unassigned bucket first, then containers by pinned/`order_key`.
/// Stepping off the end of one container therefore continues into the next, and
/// selecting that tab moves the selected container along with it. Named
/// containers holding no tabs are skipped so their tree query never runs.
///
/// With the setting off the order holds only the selected container's rows, so
/// navigation stays inside the container the user is looking at and stops at its
/// edge — the containers themselves are then only switched deliberately.
///
/// "Previous" is a step towards the top of that order and "next" a step
/// towards its end, so direction follows `tabBarDirection` (baked into the
/// order) rather than `tabListDirection` — the bar is what the step is read
/// against, and the two only disagree when the user sets them apart.
///
/// The tray's own search results are deliberately not part of this: the swipe
/// and the gestures are only reachable with the tray closed.
///
/// `null` means the underlying tree data has not arrived yet — the only state
/// in which the caller may fall back to storage order. An empty list is a real
/// answer ("this container holds nothing to move to") and must not be mistaken
/// for a missing one.
///
/// Kept alive and actively listened to by [TabRepository]: it is consumed by a
/// synchronous `ref.read` at the moment of the swipe/gesture, from outside the
/// widget tree. Without a listener Riverpod pauses the chain when nothing is on
/// screen watching it, so the order could go stale — or be created empty on the
/// read, with its tree stream still loading, and silently drop navigation back
/// to storage order. The selected container's chain is alive anyway whenever the
/// quick tab switcher or the tray is on screen; the price of crossing container
/// boundaries is that the other populated containers' tree queries are kept
/// alive too.

final class SequentialTabNavigationOrderProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<String>?>,
          EquatableValue<List<String>?>,
          EquatableValue<List<String>?>
        >
    with $Provider<EquatableValue<List<String>?>> {
  /// Flat tab id order used by sequential tab navigation: the tab bar swipe
  /// action and the next/previous tab gestures.
  ///
  /// Navigation follows the rendered order instead of the raw storage
  /// `order_key`, so it carries tree grouping and pinned-first handling — stepping
  /// to the tab the user sees next to the current one rather than to an unrelated
  /// `order_key` neighbour.
  ///
  /// The order it follows is [TabListScope.presentation], the one the quick tab
  /// switcher and the tab bar draw, *not* the tray's. Both gestures are only
  /// reachable with the tray closed, so the tray's filters, collapsed groups and
  /// title/URL/date sort describe a list nobody is looking at while they fire;
  /// letting them through made the swipe skip chips that were plainly on screen
  /// and, when they hid the current tab outright, jump to the far end of the
  /// strip (issue #603). Sharing one provider with those surfaces is what keeps
  /// the two from drifting apart again.
  ///
  /// With `sequentialTabNavigationCrossContainers` on (the default) it spans
  /// **all** containers, keeping the boundary-crossing reach the storage-order
  /// walk had: each container contributes the rows its switcher would render, and
  /// the containers follow one another in the order the quick tab switcher lays
  /// them out — the unassigned bucket first, then containers by pinned/`order_key`.
  /// Stepping off the end of one container therefore continues into the next, and
  /// selecting that tab moves the selected container along with it. Named
  /// containers holding no tabs are skipped so their tree query never runs.
  ///
  /// With the setting off the order holds only the selected container's rows, so
  /// navigation stays inside the container the user is looking at and stops at its
  /// edge — the containers themselves are then only switched deliberately.
  ///
  /// "Previous" is a step towards the top of that order and "next" a step
  /// towards its end, so direction follows `tabBarDirection` (baked into the
  /// order) rather than `tabListDirection` — the bar is what the step is read
  /// against, and the two only disagree when the user sets them apart.
  ///
  /// The tray's own search results are deliberately not part of this: the swipe
  /// and the gestures are only reachable with the tray closed.
  ///
  /// `null` means the underlying tree data has not arrived yet — the only state
  /// in which the caller may fall back to storage order. An empty list is a real
  /// answer ("this container holds nothing to move to") and must not be mistaken
  /// for a missing one.
  ///
  /// Kept alive and actively listened to by [TabRepository]: it is consumed by a
  /// synchronous `ref.read` at the moment of the swipe/gesture, from outside the
  /// widget tree. Without a listener Riverpod pauses the chain when nothing is on
  /// screen watching it, so the order could go stale — or be created empty on the
  /// read, with its tree stream still loading, and silently drop navigation back
  /// to storage order. The selected container's chain is alive anyway whenever the
  /// quick tab switcher or the tray is on screen; the price of crossing container
  /// boundaries is that the other populated containers' tree queries are kept
  /// alive too.
  SequentialTabNavigationOrderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sequentialTabNavigationOrderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sequentialTabNavigationOrderHash();

  @$internal
  @override
  $ProviderElement<EquatableValue<List<String>?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<String>?> create(Ref ref) {
    return sequentialTabNavigationOrder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<List<String>?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EquatableValue<List<String>?>>(
        value,
      ),
    );
  }
}

String _$sequentialTabNavigationOrderHash() =>
    r'bac0dd53a3a27d7db81cb2e72bf9cbc31133d585';
