// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Spaces (Zen workspaces, PLAN §6.3). Regular tabs always live in one (I2);
/// deleting a space closes its tabs through the engine first (PLAN §7.3).

@ProviderFor(SpaceRepository)
final spaceRepositoryProvider = SpaceRepositoryProvider._();

/// Spaces (Zen workspaces, PLAN §6.3). Regular tabs always live in one (I2);
/// deleting a space closes its tabs through the engine first (PLAN §7.3).
final class SpaceRepositoryProvider
    extends $NotifierProvider<SpaceRepository, void> {
  /// Spaces (Zen workspaces, PLAN §6.3). Regular tabs always live in one (I2);
  /// deleting a space closes its tabs through the engine first (PLAN §7.3).
  SpaceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spaceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spaceRepositoryHash();

  @$internal
  @override
  SpaceRepository create() => SpaceRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$spaceRepositoryHash() => r'a7909f4501d0fb0def4a75f35f1fc48e4122a6a6';

/// Spaces (Zen workspaces, PLAN §6.3). Regular tabs always live in one (I2);
/// deleting a space closes its tabs through the engine first (PLAN §7.3).

abstract class _$SpaceRepository extends $Notifier<void> {
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
