// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_target_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resumes the last opened tab when the browser has nothing to show.
///
/// There is deliberately no choice here. Zen's synced state is the source of
/// truth for what tabs exist, so launching must never *conjure* one: the
/// browser either picks up a tab that is already in that state, or it falls
/// back to the home surface and waits. A configurable "open this address on
/// startup" would add a tab nothing upstream knows about, and sync would then
/// have to carry it back out.

@ProviderFor(HomeTargetController)
final homeTargetControllerProvider = HomeTargetControllerProvider._();

/// Resumes the last opened tab when the browser has nothing to show.
///
/// There is deliberately no choice here. Zen's synced state is the source of
/// truth for what tabs exist, so launching must never *conjure* one: the
/// browser either picks up a tab that is already in that state, or it falls
/// back to the home surface and waits. A configurable "open this address on
/// startup" would add a tab nothing upstream knows about, and sync would then
/// have to carry it back out.
final class HomeTargetControllerProvider
    extends $NotifierProvider<HomeTargetController, void> {
  /// Resumes the last opened tab when the browser has nothing to show.
  ///
  /// There is deliberately no choice here. Zen's synced state is the source of
  /// truth for what tabs exist, so launching must never *conjure* one: the
  /// browser either picks up a tab that is already in that state, or it falls
  /// back to the home surface and waits. A configurable "open this address on
  /// startup" would add a tab nothing upstream knows about, and sync would then
  /// have to carry it back out.
  HomeTargetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeTargetControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeTargetControllerHash();

  @$internal
  @override
  HomeTargetController create() => HomeTargetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$homeTargetControllerHash() =>
    r'f13865cf1d797cceed57360a826f1ef1407fd7b2';

/// Resumes the last opened tab when the browser has nothing to show.
///
/// There is deliberately no choice here. Zen's synced state is the source of
/// truth for what tabs exist, so launching must never *conjure* one: the
/// browser either picks up a tab that is already in that state, or it falls
/// back to the home surface and waits. A configurable "open this address on
/// startup" would add a tab nothing upstream knows about, and sync would then
/// have to carry it back out.

abstract class _$HomeTargetController extends $Notifier<void> {
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
