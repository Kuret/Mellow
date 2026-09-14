// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zen_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ZenSettingsRepository)
final zenSettingsRepositoryProvider = ZenSettingsRepositoryProvider._();

final class ZenSettingsRepositoryProvider
    extends $StreamNotifierProvider<ZenSettingsRepository, ZenSettings> {
  ZenSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'zenSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$zenSettingsRepositoryHash();

  @$internal
  @override
  ZenSettingsRepository create() => ZenSettingsRepository();
}

String _$zenSettingsRepositoryHash() =>
    r'efbe78a35c094f86cba05c7690c01800f0a50c80';

abstract class _$ZenSettingsRepository extends $StreamNotifier<ZenSettings> {
  Stream<ZenSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ZenSettings>, ZenSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ZenSettings>, ZenSettings>,
              AsyncValue<ZenSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(zenSettingsWithDefaults)
final zenSettingsWithDefaultsProvider = ZenSettingsWithDefaultsProvider._();

final class ZenSettingsWithDefaultsProvider
    extends $FunctionalProvider<ZenSettings, ZenSettings, ZenSettings>
    with $Provider<ZenSettings> {
  ZenSettingsWithDefaultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'zenSettingsWithDefaultsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$zenSettingsWithDefaultsHash();

  @$internal
  @override
  $ProviderElement<ZenSettings> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ZenSettings create(Ref ref) {
    return zenSettingsWithDefaults(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ZenSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ZenSettings>(value),
    );
  }
}

String _$zenSettingsWithDefaultsHash() =>
    r'1daf6cdc8d76c1325edf6310fb4da6e2e63aa57c';
