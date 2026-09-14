// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'defaults.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The accent used when there is no explicit `ZenSettings.accentColor` and no
/// platform dynamic color to fall back on (`AppColors.light.seedColor` and
/// `AppColors.dark.seedColor` are the same value, so one provider covers both
/// brightnesses).

@ProviderFor(lightSeedColorFallback)
final lightSeedColorFallbackProvider = LightSeedColorFallbackProvider._();

/// The accent used when there is no explicit `ZenSettings.accentColor` and no
/// platform dynamic color to fall back on (`AppColors.light.seedColor` and
/// `AppColors.dark.seedColor` are the same value, so one provider covers both
/// brightnesses).

final class LightSeedColorFallbackProvider
    extends $FunctionalProvider<Color, Color, Color>
    with $Provider<Color> {
  /// The accent used when there is no explicit `ZenSettings.accentColor` and no
  /// platform dynamic color to fall back on (`AppColors.light.seedColor` and
  /// `AppColors.dark.seedColor` are the same value, so one provider covers both
  /// brightnesses).
  LightSeedColorFallbackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lightSeedColorFallbackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lightSeedColorFallbackHash();

  @$internal
  @override
  $ProviderElement<Color> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Color create(Ref ref) {
    return lightSeedColorFallback(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Color value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Color>(value),
    );
  }
}

String _$lightSeedColorFallbackHash() =>
    r'851efdcb11e4367ea2e54f1884a73fd4cd841d4a';

@ProviderFor(docsUri)
final docsUriProvider = DocsUriProvider._();

final class DocsUriProvider extends $FunctionalProvider<Uri, Uri, Uri>
    with $Provider<Uri> {
  DocsUriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'docsUriProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$docsUriHash();

  @$internal
  @override
  $ProviderElement<Uri> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Uri create(Ref ref) {
    return docsUri(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Uri value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Uri>(value),
    );
  }
}

String _$docsUriHash() => r'6456efcf97ddc7ee87a67e2d3380f7241e3d76ea';
