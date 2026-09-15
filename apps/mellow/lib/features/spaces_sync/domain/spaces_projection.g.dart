// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spaces_projection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Caches the stateless [SpacesProjection] object, never a projection: each
/// `project()` call still hits the database (see the file header).

@ProviderFor(spacesProjection)
final spacesProjectionProvider = SpacesProjectionProvider._();

/// Caches the stateless [SpacesProjection] object, never a projection: each
/// `project()` call still hits the database (see the file header).

final class SpacesProjectionProvider
    extends
        $FunctionalProvider<
          SpacesProjection,
          SpacesProjection,
          SpacesProjection
        >
    with $Provider<SpacesProjection> {
  /// Caches the stateless [SpacesProjection] object, never a projection: each
  /// `project()` call still hits the database (see the file header).
  SpacesProjectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spacesProjectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spacesProjectionHash();

  @$internal
  @override
  $ProviderElement<SpacesProjection> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SpacesProjection create(Ref ref) {
    return spacesProjection(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpacesProjection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpacesProjection>(value),
    );
  }
}

String _$spacesProjectionHash() => r'd493ed8744a25ded5be0d8a69266160ffafc7d41';
