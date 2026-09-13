// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The engine typed queries go to unless something nearer overrides it.
///
/// Never null: an unrecognised stored id lands on [fallbackSearchProvider], so
/// every caller can search without a null check.

@ProviderFor(defaultSearchProvider)
final defaultSearchProviderProvider = DefaultSearchProviderProvider._();

/// The engine typed queries go to unless something nearer overrides it.
///
/// Never null: an unrecognised stored id lands on [fallbackSearchProvider], so
/// every caller can search without a null check.

final class DefaultSearchProviderProvider
    extends $FunctionalProvider<SearchProvider, SearchProvider, SearchProvider>
    with $Provider<SearchProvider> {
  /// The engine typed queries go to unless something nearer overrides it.
  ///
  /// Never null: an unrecognised stored id lands on [fallbackSearchProvider], so
  /// every caller can search without a null check.
  DefaultSearchProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultSearchProviderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultSearchProviderHash();

  @$internal
  @override
  $ProviderElement<SearchProvider> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchProvider create(Ref ref) {
    return defaultSearchProvider(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchProvider value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchProvider>(value),
    );
  }
}

String _$defaultSearchProviderHash() =>
    r'0a507101e5ec4b62af3ee3288d887da754223f8b';
