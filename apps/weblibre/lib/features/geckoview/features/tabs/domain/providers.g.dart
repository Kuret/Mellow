// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchContainersWithCount)
final watchContainersWithCountProvider = WatchContainersWithCountProvider._();

final class WatchContainersWithCountProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ContainerDataWithCount>>,
          List<ContainerDataWithCount>,
          Stream<List<ContainerDataWithCount>>
        >
    with
        $FutureModifier<List<ContainerDataWithCount>>,
        $StreamProvider<List<ContainerDataWithCount>> {
  WatchContainersWithCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchContainersWithCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchContainersWithCountHash();

  @$internal
  @override
  $StreamProviderElement<List<ContainerDataWithCount>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ContainerDataWithCount>> create(Ref ref) {
    return watchContainersWithCount(ref);
  }
}

String _$watchContainersWithCountHash() =>
    r'50d8e9b39cb589b0b5f50d79cbe20b8d10d7a504';

/// The destinations a container-cycling gesture steps through, in the order
/// the container chips render them: the unassigned pseudo-container (`null`)
/// first, then the containers themselves.

@ProviderFor(containerCycleOrder)
final containerCycleOrderProvider = ContainerCycleOrderProvider._();

/// The destinations a container-cycling gesture steps through, in the order
/// the container chips render them: the unassigned pseudo-container (`null`)
/// first, then the containers themselves.

final class ContainerCycleOrderProvider
    extends
        $FunctionalProvider<
          List<ContainerData?>,
          List<ContainerData?>,
          List<ContainerData?>
        >
    with $Provider<List<ContainerData?>> {
  /// The destinations a container-cycling gesture steps through, in the order
  /// the container chips render them: the unassigned pseudo-container (`null`)
  /// first, then the containers themselves.
  ContainerCycleOrderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'containerCycleOrderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$containerCycleOrderHash();

  @$internal
  @override
  $ProviderElement<List<ContainerData?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ContainerData?> create(Ref ref) {
    return containerCycleOrder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ContainerData?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ContainerData?>>(value),
    );
  }
}

String _$containerCycleOrderHash() =>
    r'dd732a8717b1ebe7055776d2b7800e587f552438';

@ProviderFor(matchSortedContainersWithCount)
final matchSortedContainersWithCountProvider =
    MatchSortedContainersWithCountFamily._();

final class MatchSortedContainersWithCountProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ContainerDataWithCount>>,
          AsyncValue<List<ContainerDataWithCount>>,
          AsyncValue<List<ContainerDataWithCount>>
        >
    with $Provider<AsyncValue<List<ContainerDataWithCount>>> {
  MatchSortedContainersWithCountProvider._({
    required MatchSortedContainersWithCountFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'matchSortedContainersWithCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchSortedContainersWithCountHash();

  @override
  String toString() {
    return r'matchSortedContainersWithCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<ContainerDataWithCount>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<ContainerDataWithCount>> create(Ref ref) {
    final argument = this.argument as String?;
    return matchSortedContainersWithCount(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<ContainerDataWithCount>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<ContainerDataWithCount>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MatchSortedContainersWithCountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchSortedContainersWithCountHash() =>
    r'e66ca1d96a735155f582975ae05a90503e615882';

final class MatchSortedContainersWithCountFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<List<ContainerDataWithCount>>,
          String?
        > {
  MatchSortedContainersWithCountFamily._()
    : super(
        retry: null,
        name: r'matchSortedContainersWithCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MatchSortedContainersWithCountProvider call(String? searchText) =>
      MatchSortedContainersWithCountProvider._(
        argument: searchText,
        from: this,
      );

  @override
  String toString() => r'matchSortedContainersWithCountProvider';
}

@ProviderFor(watchContainerTabIds)
final watchContainerTabIdsProvider = WatchContainerTabIdsFamily._();

final class WatchContainerTabIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  WatchContainerTabIdsProvider._({
    required WatchContainerTabIdsFamily super.from,
    required ContainerFilter super.argument,
  }) : super(
         retry: null,
         name: r'watchContainerTabIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchContainerTabIdsHash();

  @override
  String toString() {
    return r'watchContainerTabIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    final argument = this.argument as ContainerFilter;
    return watchContainerTabIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchContainerTabIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchContainerTabIdsHash() =>
    r'25f73fe16fad7ec0121b2bee99ecbd8b6bf47791';

final class WatchContainerTabIdsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<String>>, ContainerFilter> {
  WatchContainerTabIdsFamily._()
    : super(
        retry: null,
        name: r'watchContainerTabIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchContainerTabIdsProvider call(ContainerFilter containerFilter) =>
      WatchContainerTabIdsProvider._(argument: containerFilter, from: this);

  @override
  String toString() => r'watchContainerTabIdsProvider';
}

@ProviderFor(containerTabCount)
final containerTabCountProvider = ContainerTabCountFamily._();

final class ContainerTabCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  ContainerTabCountProvider._({
    required ContainerTabCountFamily super.from,
    required ContainerFilter super.argument,
  }) : super(
         retry: null,
         name: r'containerTabCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$containerTabCountHash();

  @override
  String toString() {
    return r'containerTabCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as ContainerFilter;
    return containerTabCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContainerTabCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$containerTabCountHash() => r'df4008a9c589936c8a0699b082ab23087ae9b85f';

final class ContainerTabCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, ContainerFilter> {
  ContainerTabCountFamily._()
    : super(
        retry: null,
        name: r'containerTabCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContainerTabCountProvider call(ContainerFilter containerFilter) =>
      ContainerTabCountProvider._(argument: containerFilter, from: this);

  @override
  String toString() => r'containerTabCountProvider';
}

/// Every space by `order_index`.

@ProviderFor(watchSpaces)
final watchSpacesProvider = WatchSpacesProvider._();

/// Every space by `order_index`.

final class WatchSpacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SpaceData>>,
          List<SpaceData>,
          Stream<List<SpaceData>>
        >
    with $FutureModifier<List<SpaceData>>, $StreamProvider<List<SpaceData>> {
  /// Every space by `order_index`.
  WatchSpacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchSpacesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchSpacesHash();

  @$internal
  @override
  $StreamProviderElement<List<SpaceData>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SpaceData>> create(Ref ref) {
    return watchSpaces(ref);
  }
}

String _$watchSpacesHash() => r'12b45a2c4a79162f08320df28d351f1ffee36611';

/// The folders of one space, all nesting levels, by `order_key`.

@ProviderFor(watchFolders)
final watchFoldersProvider = WatchFoldersFamily._();

/// The folders of one space, all nesting levels, by `order_key`.

final class WatchFoldersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TabFolderData>>,
          List<TabFolderData>,
          Stream<List<TabFolderData>>
        >
    with
        $FutureModifier<List<TabFolderData>>,
        $StreamProvider<List<TabFolderData>> {
  /// The folders of one space, all nesting levels, by `order_key`.
  WatchFoldersProvider._({
    required WatchFoldersFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'watchFoldersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchFoldersHash();

  @override
  String toString() {
    return r'watchFoldersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TabFolderData>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TabFolderData>> create(Ref ref) {
    final argument = this.argument as String?;
    return watchFolders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchFoldersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchFoldersHash() => r'd212116a3dc33a99e6bcb296dda507ad59d3eb0b';

/// The folders of one space, all nesting levels, by `order_key`.

final class WatchFoldersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TabFolderData>>, String?> {
  WatchFoldersFamily._()
    : super(
        retry: null,
        name: r'watchFoldersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The folders of one space, all nesting levels, by `order_key`.

  WatchFoldersProvider call(String? spaceUuid) =>
      WatchFoldersProvider._(argument: spaceUuid, from: this);

  @override
  String toString() => r'watchFoldersProvider';
}

/// Every tab of one space (pinned shelf first, then `order_key`), folders
/// included. A null [spaceUuid] is the tabs without a space.

@ProviderFor(watchSpaceTabsData)
final watchSpaceTabsDataProvider = WatchSpaceTabsDataFamily._();

/// Every tab of one space (pinned shelf first, then `order_key`), folders
/// included. A null [spaceUuid] is the tabs without a space.

final class WatchSpaceTabsDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TabSummary>>,
          List<TabSummary>,
          Stream<List<TabSummary>>
        >
    with $FutureModifier<List<TabSummary>>, $StreamProvider<List<TabSummary>> {
  /// Every tab of one space (pinned shelf first, then `order_key`), folders
  /// included. A null [spaceUuid] is the tabs without a space.
  WatchSpaceTabsDataProvider._({
    required WatchSpaceTabsDataFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'watchSpaceTabsDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchSpaceTabsDataHash();

  @override
  String toString() {
    return r'watchSpaceTabsDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TabSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TabSummary>> create(Ref ref) {
    final argument = this.argument as String?;
    return watchSpaceTabsData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchSpaceTabsDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchSpaceTabsDataHash() =>
    r'5ba2136765dc5ecd39a136ffe2f1ae05073bd4ca';

/// Every tab of one space (pinned shelf first, then `order_key`), folders
/// included. A null [spaceUuid] is the tabs without a space.

final class WatchSpaceTabsDataFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TabSummary>>, String?> {
  WatchSpaceTabsDataFamily._()
    : super(
        retry: null,
        name: r'watchSpaceTabsDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every tab of one space (pinned shelf first, then `order_key`), folders
  /// included. A null [spaceUuid] is the tabs without a space.

  WatchSpaceTabsDataProvider call(String? spaceUuid) =>
      WatchSpaceTabsDataProvider._(argument: spaceUuid, from: this);

  @override
  String toString() => r'watchSpaceTabsDataProvider';
}

@ProviderFor(watchSpaceTabIds)
final watchSpaceTabIdsProvider = WatchSpaceTabIdsFamily._();

final class WatchSpaceTabIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  WatchSpaceTabIdsProvider._({
    required WatchSpaceTabIdsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'watchSpaceTabIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchSpaceTabIdsHash();

  @override
  String toString() {
    return r'watchSpaceTabIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    final argument = this.argument as String?;
    return watchSpaceTabIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchSpaceTabIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchSpaceTabIdsHash() => r'7bc7fd5f799e49772f84d91bca0a941d65b40e7f';

final class WatchSpaceTabIdsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<String>>, String?> {
  WatchSpaceTabIdsFamily._()
    : super(
        retry: null,
        name: r'watchSpaceTabIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchSpaceTabIdsProvider call(String? spaceUuid) =>
      WatchSpaceTabIdsProvider._(argument: spaceUuid, from: this);

  @override
  String toString() => r'watchSpaceTabIdsProvider';
}

@ProviderFor(spaceTabCount)
final spaceTabCountProvider = SpaceTabCountFamily._();

final class SpaceTabCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  SpaceTabCountProvider._({
    required SpaceTabCountFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'spaceTabCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$spaceTabCountHash();

  @override
  String toString() {
    return r'spaceTabCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String?;
    return spaceTabCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SpaceTabCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$spaceTabCountHash() => r'7dfd0852e8c4168b6e6265cedb6fd42fbaa2ba4e';

final class SpaceTabCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String?> {
  SpaceTabCountFamily._()
    : super(
        retry: null,
        name: r'spaceTabCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SpaceTabCountProvider call(String? spaceUuid) =>
      SpaceTabCountProvider._(argument: spaceUuid, from: this);

  @override
  String toString() => r'spaceTabCountProvider';
}

@ProviderFor(watchTabsFifo)
final watchTabsFifoProvider = WatchTabsFifoProvider._();

final class WatchTabsFifoProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TabSummary>>,
          List<TabSummary>,
          Stream<List<TabSummary>>
        >
    with $FutureModifier<List<TabSummary>>, $StreamProvider<List<TabSummary>> {
  WatchTabsFifoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTabsFifoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTabsFifoHash();

  @$internal
  @override
  $StreamProviderElement<List<TabSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TabSummary>> create(Ref ref) {
    return watchTabsFifo(ref);
  }
}

String _$watchTabsFifoHash() => r'ce84a120f37fe08a1cc193c561e64acd44c949cd';

/// Tab trees of one space; with [allSpaces] the space boundary is ignored and
/// every tree is returned.

@ProviderFor(watchTabTrees)
final watchTabTreesProvider = WatchTabTreesFamily._();

/// Tab trees of one space; with [allSpaces] the space boundary is ignored and
/// every tree is returned.

final class WatchTabTreesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TabTreesResult>>,
          List<TabTreesResult>,
          Stream<List<TabTreesResult>>
        >
    with
        $FutureModifier<List<TabTreesResult>>,
        $StreamProvider<List<TabTreesResult>> {
  /// Tab trees of one space; with [allSpaces] the space boundary is ignored and
  /// every tree is returned.
  WatchTabTreesProvider._({
    required WatchTabTreesFamily super.from,
    required (String?, {bool allSpaces}) super.argument,
  }) : super(
         retry: null,
         name: r'watchTabTreesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchTabTreesHash();

  @override
  String toString() {
    return r'watchTabTreesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<TabTreesResult>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TabTreesResult>> create(Ref ref) {
    final argument = this.argument as (String?, {bool allSpaces});
    return watchTabTrees(ref, argument.$1, allSpaces: argument.allSpaces);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchTabTreesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchTabTreesHash() => r'ba42e8a1172a4fb8d84fee7dc059766f14c336a6';

/// Tab trees of one space; with [allSpaces] the space boundary is ignored and
/// every tree is returned.

final class WatchTabTreesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<TabTreesResult>>,
          (String?, {bool allSpaces})
        > {
  WatchTabTreesFamily._()
    : super(
        retry: null,
        name: r'watchTabTreesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tab trees of one space; with [allSpaces] the space boundary is ignored and
  /// every tree is returned.

  WatchTabTreesProvider call(String? spaceUuid, {bool allSpaces = false}) =>
      WatchTabTreesProvider._(
        argument: (spaceUuid, allSpaces: allSpaces),
        from: this,
      );

  @override
  String toString() => r'watchTabTreesProvider';
}

@ProviderFor(watchTabsWithRootAndDepth)
final watchTabsWithRootAndDepthProvider = WatchTabsWithRootAndDepthFamily._();

final class WatchTabsWithRootAndDepthProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TabsWithRootAndDepthResult>>,
          List<TabsWithRootAndDepthResult>,
          Stream<List<TabsWithRootAndDepthResult>>
        >
    with
        $FutureModifier<List<TabsWithRootAndDepthResult>>,
        $StreamProvider<List<TabsWithRootAndDepthResult>> {
  WatchTabsWithRootAndDepthProvider._({
    required WatchTabsWithRootAndDepthFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'watchTabsWithRootAndDepthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchTabsWithRootAndDepthHash();

  @override
  String toString() {
    return r'watchTabsWithRootAndDepthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TabsWithRootAndDepthResult>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TabsWithRootAndDepthResult>> create(Ref ref) {
    final argument = this.argument as String?;
    return watchTabsWithRootAndDepth(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchTabsWithRootAndDepthProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchTabsWithRootAndDepthHash() =>
    r'8cf183ea7124e30797b9b6ac52b0c289aae2561c';

final class WatchTabsWithRootAndDepthFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<TabsWithRootAndDepthResult>>,
          String?
        > {
  WatchTabsWithRootAndDepthFamily._()
    : super(
        retry: null,
        name: r'watchTabsWithRootAndDepthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchTabsWithRootAndDepthProvider call(String? spaceUuid) =>
      WatchTabsWithRootAndDepthProvider._(argument: spaceUuid, from: this);

  @override
  String toString() => r'watchTabsWithRootAndDepthProvider';
}

/// One tab's row, watched — without its page text.
///
/// A [TabSummary]: this is a `.watch()`, so it re-runs on every write to `tab`
/// for as long as the tab menu or the parent picker is open, and both consumers
/// read only `parentId` and `containerId`. The wide row would drag that tab's
/// stored content (and the `content_hash` UDF) through on every tick.

@ProviderFor(watchTabDbData)
final watchTabDbDataProvider = WatchTabDbDataFamily._();

/// One tab's row, watched — without its page text.
///
/// A [TabSummary]: this is a `.watch()`, so it re-runs on every write to `tab`
/// for as long as the tab menu or the parent picker is open, and both consumers
/// read only `parentId` and `containerId`. The wide row would drag that tab's
/// stored content (and the `content_hash` UDF) through on every tick.

final class WatchTabDbDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<TabSummary?>,
          TabSummary?,
          Stream<TabSummary?>
        >
    with $FutureModifier<TabSummary?>, $StreamProvider<TabSummary?> {
  /// One tab's row, watched — without its page text.
  ///
  /// A [TabSummary]: this is a `.watch()`, so it re-runs on every write to `tab`
  /// for as long as the tab menu or the parent picker is open, and both consumers
  /// read only `parentId` and `containerId`. The wide row would drag that tab's
  /// stored content (and the `content_hash` UDF) through on every tick.
  WatchTabDbDataProvider._({
    required WatchTabDbDataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchTabDbDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchTabDbDataHash();

  @override
  String toString() {
    return r'watchTabDbDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<TabSummary?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TabSummary?> create(Ref ref) {
    final argument = this.argument as String;
    return watchTabDbData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchTabDbDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchTabDbDataHash() => r'3e3c7221b4ef73616f995c362f823128e88984e2';

/// One tab's row, watched — without its page text.
///
/// A [TabSummary]: this is a `.watch()`, so it re-runs on every write to `tab`
/// for as long as the tab menu or the parent picker is open, and both consumers
/// read only `parentId` and `containerId`. The wide row would drag that tab's
/// stored content (and the `content_hash` UDF) through on every tick.

final class WatchTabDbDataFamily extends $Family
    with $FunctionalFamilyOverride<Stream<TabSummary?>, String> {
  WatchTabDbDataFamily._()
    : super(
        retry: null,
        name: r'watchTabDbDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One tab's row, watched — without its page text.
  ///
  /// A [TabSummary]: this is a `.watch()`, so it re-runs on every write to `tab`
  /// for as long as the tab menu or the parent picker is open, and both consumers
  /// read only `parentId` and `containerId`. The wide row would drag that tab's
  /// stored content (and the `content_hash` UDF) through on every tick.

  WatchTabDbDataProvider call(String tabId) =>
      WatchTabDbDataProvider._(argument: tabId, from: this);

  @override
  String toString() => r'watchTabDbDataProvider';
}

@ProviderFor(watchTabDescendants)
final watchTabDescendantsProvider = WatchTabDescendantsFamily._();

final class WatchTabDescendantsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String?>>,
          Map<String, String?>,
          Stream<Map<String, String?>>
        >
    with
        $FutureModifier<Map<String, String?>>,
        $StreamProvider<Map<String, String?>> {
  WatchTabDescendantsProvider._({
    required WatchTabDescendantsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchTabDescendantsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchTabDescendantsHash();

  @override
  String toString() {
    return r'watchTabDescendantsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, String?>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, String?>> create(Ref ref) {
    final argument = this.argument as String;
    return watchTabDescendants(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchTabDescendantsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchTabDescendantsHash() =>
    r'8b20353888a851191d835784e24d7d4a6e898b72';

final class WatchTabDescendantsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, String?>>, String> {
  WatchTabDescendantsFamily._()
    : super(
        retry: null,
        name: r'watchTabDescendantsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchTabDescendantsProvider call(String tabId) =>
      WatchTabDescendantsProvider._(argument: tabId, from: this);

  @override
  String toString() => r'watchTabDescendantsProvider';
}

@ProviderFor(watchContainerTabsData)
final watchContainerTabsDataProvider = WatchContainerTabsDataFamily._();

final class WatchContainerTabsDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TabSummary>>,
          List<TabSummary>,
          Stream<List<TabSummary>>
        >
    with $FutureModifier<List<TabSummary>>, $StreamProvider<List<TabSummary>> {
  WatchContainerTabsDataProvider._({
    required WatchContainerTabsDataFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'watchContainerTabsDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchContainerTabsDataHash();

  @override
  String toString() {
    return r'watchContainerTabsDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TabSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TabSummary>> create(Ref ref) {
    final argument = this.argument as String?;
    return watchContainerTabsData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchContainerTabsDataProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchContainerTabsDataHash() =>
    r'23f2867b1805333256176f42f9af37071593c3d2';

final class WatchContainerTabsDataFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TabSummary>>, String?> {
  WatchContainerTabsDataFamily._()
    : super(
        retry: null,
        name: r'watchContainerTabsDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchContainerTabsDataProvider call(String? containerId) =>
      WatchContainerTabsDataProvider._(argument: containerId, from: this);

  @override
  String toString() => r'watchContainerTabsDataProvider';
}

/// `tab.id → tab_shelf` for every tab.

@ProviderFor(watchTabShelves)
final watchTabShelvesProvider = WatchTabShelvesProvider._();

/// `tab.id → tab_shelf` for every tab.

final class WatchTabShelvesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, TabShelf>>,
          Map<String, TabShelf>,
          Stream<Map<String, TabShelf>>
        >
    with
        $FutureModifier<Map<String, TabShelf>>,
        $StreamProvider<Map<String, TabShelf>> {
  /// `tab.id → tab_shelf` for every tab.
  WatchTabShelvesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTabShelvesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTabShelvesHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, TabShelf>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, TabShelf>> create(Ref ref) {
    return watchTabShelves(ref);
  }
}

String _$watchTabShelvesHash() => r'bf52b714c0869e117220af317a95ac5e67fb71b9';

/// Ids of the tabs on the pinned shelf; empty until the shelves have loaded.

@ProviderFor(pinnedTabIds)
final pinnedTabIdsProvider = PinnedTabIdsProvider._();

/// Ids of the tabs on the pinned shelf; empty until the shelves have loaded.

final class PinnedTabIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// Ids of the tabs on the pinned shelf; empty until the shelves have loaded.
  PinnedTabIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinnedTabIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinnedTabIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return pinnedTabIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$pinnedTabIdsHash() => r'b5f668df2a94b59661011a4e06c2c55fca96cd90';

/// Ids of the tabs on the essential shelf; empty until the shelves have loaded.

@ProviderFor(essentialTabIds)
final essentialTabIdsProvider = EssentialTabIdsProvider._();

/// Ids of the tabs on the essential shelf; empty until the shelves have loaded.

final class EssentialTabIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// Ids of the tabs on the essential shelf; empty until the shelves have loaded.
  EssentialTabIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'essentialTabIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$essentialTabIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return essentialTabIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$essentialTabIdsHash() => r'a67c6caa776a9de0ede8ba4f6989a6ca11790477';

/// The essentials strip of one container (`null` = the unassigned strip), in
/// `order_key` order.

@ProviderFor(watchEssentialTabIds)
final watchEssentialTabIdsProvider = WatchEssentialTabIdsFamily._();

/// The essentials strip of one container (`null` = the unassigned strip), in
/// `order_key` order.

final class WatchEssentialTabIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  /// The essentials strip of one container (`null` = the unassigned strip), in
  /// `order_key` order.
  WatchEssentialTabIdsProvider._({
    required WatchEssentialTabIdsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'watchEssentialTabIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchEssentialTabIdsHash();

  @override
  String toString() {
    return r'watchEssentialTabIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    final argument = this.argument as String?;
    return watchEssentialTabIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchEssentialTabIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchEssentialTabIdsHash() =>
    r'73c291426e15153160ba0841b907803f449fd10b';

/// The essentials strip of one container (`null` = the unassigned strip), in
/// `order_key` order.

final class WatchEssentialTabIdsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<String>>, String?> {
  WatchEssentialTabIdsFamily._()
    : super(
        retry: null,
        name: r'watchEssentialTabIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The essentials strip of one container (`null` = the unassigned strip), in
  /// `order_key` order.

  WatchEssentialTabIdsProvider call(String? containerId) =>
      WatchEssentialTabIdsProvider._(argument: containerId, from: this);

  @override
  String toString() => r'watchEssentialTabIdsProvider';
}

@ProviderFor(watchTabTimestamps)
final watchTabTimestampsProvider = WatchTabTimestampsProvider._();

final class WatchTabTimestampsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, DateTime>>,
          Map<String, DateTime>,
          Stream<Map<String, DateTime>>
        >
    with
        $FutureModifier<Map<String, DateTime>>,
        $StreamProvider<Map<String, DateTime>> {
  WatchTabTimestampsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTabTimestampsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTabTimestampsHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, DateTime>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, DateTime>> create(Ref ref) {
    return watchTabTimestamps(ref);
  }
}

String _$watchTabTimestampsHash() =>
    r'8b3eea3dded71795f80c607117978bbec1de7cff';

@ProviderFor(watchTabOrderKeys)
final watchTabOrderKeysProvider = WatchTabOrderKeysProvider._();

final class WatchTabOrderKeysProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          Stream<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $StreamProvider<Map<String, String>> {
  WatchTabOrderKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTabOrderKeysProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTabOrderKeysHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, String>> create(Ref ref) {
    return watchTabOrderKeys(ref);
  }
}

String _$watchTabOrderKeysHash() => r'675ef0d1b1c5445face8d6ab727507ca1a5e2c44';

@ProviderFor(watchContainerData)
final watchContainerDataProvider = WatchContainerDataFamily._();

final class WatchContainerDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContainerData?>,
          ContainerData?,
          Stream<ContainerData?>
        >
    with $FutureModifier<ContainerData?>, $StreamProvider<ContainerData?> {
  WatchContainerDataProvider._({
    required WatchContainerDataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchContainerDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchContainerDataHash();

  @override
  String toString() {
    return r'watchContainerDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ContainerData?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ContainerData?> create(Ref ref) {
    final argument = this.argument as String;
    return watchContainerData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchContainerDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchContainerDataHash() =>
    r'abd0e964a6444ed9be5da649a0f6a77bbbb54042';

final class WatchContainerDataFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ContainerData?>, String> {
  WatchContainerDataFamily._()
    : super(
        retry: null,
        name: r'watchContainerDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchContainerDataProvider call(String containerId) =>
      WatchContainerDataProvider._(argument: containerId, from: this);

  @override
  String toString() => r'watchContainerDataProvider';
}

/// The per-device settings of one container; defaults while it has no
/// `container_local` row.

@ProviderFor(watchContainerLocal)
final watchContainerLocalProvider = WatchContainerLocalFamily._();

/// The per-device settings of one container; defaults while it has no
/// `container_local` row.

final class WatchContainerLocalProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContainerLocalData>,
          ContainerLocalData,
          Stream<ContainerLocalData>
        >
    with
        $FutureModifier<ContainerLocalData>,
        $StreamProvider<ContainerLocalData> {
  /// The per-device settings of one container; defaults while it has no
  /// `container_local` row.
  WatchContainerLocalProvider._({
    required WatchContainerLocalFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchContainerLocalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchContainerLocalHash();

  @override
  String toString() {
    return r'watchContainerLocalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ContainerLocalData> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ContainerLocalData> create(Ref ref) {
    final argument = this.argument as String;
    return watchContainerLocal(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchContainerLocalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchContainerLocalHash() =>
    r'dcef5e4560b0f6f486047cf11fb3b7b894e48a9f';

/// The per-device settings of one container; defaults while it has no
/// `container_local` row.

final class WatchContainerLocalFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ContainerLocalData>, String> {
  WatchContainerLocalFamily._()
    : super(
        retry: null,
        name: r'watchContainerLocalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The per-device settings of one container; defaults while it has no
  /// `container_local` row.

  WatchContainerLocalProvider call(String containerId) =>
      WatchContainerLocalProvider._(argument: containerId, from: this);

  @override
  String toString() => r'watchContainerLocalProvider';
}

@ProviderFor(watchContainerTabId)
final watchContainerTabIdProvider = WatchContainerTabIdFamily._();

final class WatchContainerTabIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  WatchContainerTabIdProvider._({
    required WatchContainerTabIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchContainerTabIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchContainerTabIdHash();

  @override
  String toString() {
    return r'watchContainerTabIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    final argument = this.argument as String;
    return watchContainerTabId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchContainerTabIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchContainerTabIdHash() =>
    r'c2cb263d4633fae436e7b3b216ab46d93ef49d4f';

final class WatchContainerTabIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String?>, String> {
  WatchContainerTabIdFamily._()
    : super(
        retry: null,
        name: r'watchContainerTabIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchContainerTabIdProvider call(String tabId) =>
      WatchContainerTabIdProvider._(argument: tabId, from: this);

  @override
  String toString() => r'watchContainerTabIdProvider';
}

@ProviderFor(watchTabContainerData)
final watchTabContainerDataProvider = WatchTabContainerDataFamily._();

final class WatchTabContainerDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContainerData?>,
          ContainerData?,
          Stream<ContainerData?>
        >
    with $FutureModifier<ContainerData?>, $StreamProvider<ContainerData?> {
  WatchTabContainerDataProvider._({
    required WatchTabContainerDataFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'watchTabContainerDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchTabContainerDataHash();

  @override
  String toString() {
    return r'watchTabContainerDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ContainerData?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ContainerData?> create(Ref ref) {
    final argument = this.argument as String?;
    return watchTabContainerData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchTabContainerDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchTabContainerDataHash() =>
    r'7fe7d139555f6bbf3165ac67a3641bec9b1af966';

final class WatchTabContainerDataFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ContainerData?>, String?> {
  WatchTabContainerDataFamily._()
    : super(
        retry: null,
        name: r'watchTabContainerDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchTabContainerDataProvider call(String? tabId) =>
      WatchTabContainerDataProvider._(argument: tabId, from: this);

  @override
  String toString() => r'watchTabContainerDataProvider';
}

@ProviderFor(watchTabsContainerId)
final watchTabsContainerIdProvider = WatchTabsContainerIdFamily._();

final class WatchTabsContainerIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String?>>,
          Map<String, String?>,
          Stream<Map<String, String?>>
        >
    with
        $FutureModifier<Map<String, String?>>,
        $StreamProvider<Map<String, String?>> {
  WatchTabsContainerIdProvider._({
    required WatchTabsContainerIdFamily super.from,
    required EquatableValue<List<String>> super.argument,
  }) : super(
         retry: null,
         name: r'watchTabsContainerIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchTabsContainerIdHash();

  @override
  String toString() {
    return r'watchTabsContainerIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, String?>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, String?>> create(Ref ref) {
    final argument = this.argument as EquatableValue<List<String>>;
    return watchTabsContainerId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchTabsContainerIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchTabsContainerIdHash() =>
    r'75a915a0fd93cbb33a32f0aa521dbd61f1814c75';

final class WatchTabsContainerIdFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<String, String?>>,
          EquatableValue<List<String>>
        > {
  WatchTabsContainerIdFamily._()
    : super(
        retry: null,
        name: r'watchTabsContainerIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchTabsContainerIdProvider call(EquatableValue<List<String>> tabIds) =>
      WatchTabsContainerIdProvider._(argument: tabIds, from: this);

  @override
  String toString() => r'watchTabsContainerIdProvider';
}
