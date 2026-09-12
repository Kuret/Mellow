// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'container.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Containers are Firefox contextual identities (PLAN §6.2). A container's
/// Gecko `contextId` is its `id` (DESIGN.md "D3 refinement"); the per-device
/// settings live in `container_local` and are reached via [getLocal] /
/// [setLocal] / [watchLocal].

@ProviderFor(ContainerRepository)
final containerRepositoryProvider = ContainerRepositoryProvider._();

/// Containers are Firefox contextual identities (PLAN §6.2). A container's
/// Gecko `contextId` is its `id` (DESIGN.md "D3 refinement"); the per-device
/// settings live in `container_local` and are reached via [getLocal] /
/// [setLocal] / [watchLocal].
final class ContainerRepositoryProvider
    extends $NotifierProvider<ContainerRepository, void> {
  /// Containers are Firefox contextual identities (PLAN §6.2). A container's
  /// Gecko `contextId` is its `id` (DESIGN.md "D3 refinement"); the per-device
  /// settings live in `container_local` and are reached via [getLocal] /
  /// [setLocal] / [watchLocal].
  ContainerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'containerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$containerRepositoryHash();

  @$internal
  @override
  ContainerRepository create() => ContainerRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$containerRepositoryHash() =>
    r'c1d56f5da741df8bdd8798e8940244350d9f0787';

/// Containers are Firefox contextual identities (PLAN §6.2). A container's
/// Gecko `contextId` is its `id` (DESIGN.md "D3 refinement"); the per-device
/// settings live in `container_local` and are reached via [getLocal] /
/// [setLocal] / [watchLocal].

abstract class _$ContainerRepository extends $Notifier<void> {
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
