// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_defaults.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileDefaultsService)
final profileDefaultsServiceProvider = ProfileDefaultsServiceProvider._();

final class ProfileDefaultsServiceProvider
    extends $NotifierProvider<ProfileDefaultsService, void> {
  ProfileDefaultsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileDefaultsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileDefaultsServiceHash();

  @$internal
  @override
  ProfileDefaultsService create() => ProfileDefaultsService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$profileDefaultsServiceHash() =>
    r'03db69bfbfe0f9bf7f9ae1971154ca1fe3f8687d';

abstract class _$ProfileDefaultsService extends $Notifier<void> {
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
