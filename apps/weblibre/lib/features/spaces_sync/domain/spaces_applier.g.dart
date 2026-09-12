// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spaces_applier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(spacesApplier)
final spacesApplierProvider = SpacesApplierProvider._();

final class SpacesApplierProvider
    extends $FunctionalProvider<SpacesApplier, SpacesApplier, SpacesApplier>
    with $Provider<SpacesApplier> {
  SpacesApplierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spacesApplierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spacesApplierHash();

  @$internal
  @override
  $ProviderElement<SpacesApplier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SpacesApplier create(Ref ref) {
    return spacesApplier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpacesApplier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpacesApplier>(value),
    );
  }
}

String _$spacesApplierHash() => r'028cd71f03d35ff06ef1bf4576486e7c6837705f';
