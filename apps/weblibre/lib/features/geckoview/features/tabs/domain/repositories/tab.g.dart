// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tab.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TabDataRepository)
final tabDataRepositoryProvider = TabDataRepositoryProvider._();

final class TabDataRepositoryProvider
    extends $NotifierProvider<TabDataRepository, void> {
  TabDataRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tabDataRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tabDataRepositoryHash();

  @$internal
  @override
  TabDataRepository create() => TabDataRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$tabDataRepositoryHash() => r'ccd2c2e5127e3a6f0105387ac03ddb708d2fcf6b';

abstract class _$TabDataRepository extends $Notifier<void> {
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
