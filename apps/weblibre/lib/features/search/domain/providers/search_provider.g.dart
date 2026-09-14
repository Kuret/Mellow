// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The engines the user defined, as the browser searches with them.
///
/// Derived rather than stored: `ZenSettings` keeps the name and the template,
/// and everything else about an engine — its icon host above all — follows from
/// those.

@ProviderFor(customSearchProviders)
final customSearchProvidersProvider = CustomSearchProvidersProvider._();

/// The engines the user defined, as the browser searches with them.
///
/// Derived rather than stored: `ZenSettings` keeps the name and the template,
/// and everything else about an engine — its icon host above all — follows from
/// those.

final class CustomSearchProvidersProvider
    extends
        $FunctionalProvider<
          List<SearchProvider>,
          List<SearchProvider>,
          List<SearchProvider>
        >
    with $Provider<List<SearchProvider>> {
  /// The engines the user defined, as the browser searches with them.
  ///
  /// Derived rather than stored: `ZenSettings` keeps the name and the template,
  /// and everything else about an engine — its icon host above all — follows from
  /// those.
  CustomSearchProvidersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customSearchProvidersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customSearchProvidersHash();

  @$internal
  @override
  $ProviderElement<List<SearchProvider>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SearchProvider> create(Ref ref) {
    return customSearchProviders(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SearchProvider> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SearchProvider>>(value),
    );
  }
}

String _$customSearchProvidersHash() =>
    r'220128b30ece2247de61eb38438ec7577223f8f7';

/// Every engine there is, in the order pickers show them: the built-ins first,
/// then the user's own.
///
/// Custom engines come last so the list a user has been reading for months does
/// not reshuffle the moment they add one of their own.

@ProviderFor(allSearchProviders)
final allSearchProvidersProvider = AllSearchProvidersProvider._();

/// Every engine there is, in the order pickers show them: the built-ins first,
/// then the user's own.
///
/// Custom engines come last so the list a user has been reading for months does
/// not reshuffle the moment they add one of their own.

final class AllSearchProvidersProvider
    extends
        $FunctionalProvider<
          List<SearchProvider>,
          List<SearchProvider>,
          List<SearchProvider>
        >
    with $Provider<List<SearchProvider>> {
  /// Every engine there is, in the order pickers show them: the built-ins first,
  /// then the user's own.
  ///
  /// Custom engines come last so the list a user has been reading for months does
  /// not reshuffle the moment they add one of their own.
  AllSearchProvidersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allSearchProvidersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allSearchProvidersHash();

  @$internal
  @override
  $ProviderElement<List<SearchProvider>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SearchProvider> create(Ref ref) {
    return allSearchProviders(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SearchProvider> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SearchProvider>>(value),
    );
  }
}

String _$allSearchProvidersHash() =>
    r'de78b366521510423988eb3d06881cf4ad7d4a5f';

/// The engine with [id], built-in or user-defined, or null when nothing carries
/// that id any more — a custom engine the user has since deleted, say.

@ProviderFor(searchProviderById)
final searchProviderByIdProvider = SearchProviderByIdFamily._();

/// The engine with [id], built-in or user-defined, or null when nothing carries
/// that id any more — a custom engine the user has since deleted, say.

final class SearchProviderByIdProvider
    extends
        $FunctionalProvider<SearchProvider?, SearchProvider?, SearchProvider?>
    with $Provider<SearchProvider?> {
  /// The engine with [id], built-in or user-defined, or null when nothing carries
  /// that id any more — a custom engine the user has since deleted, say.
  SearchProviderByIdProvider._({
    required SearchProviderByIdFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'searchProviderByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchProviderByIdHash();

  @override
  String toString() {
    return r'searchProviderByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<SearchProvider?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchProvider? create(Ref ref) {
    final argument = this.argument as String?;
    return searchProviderById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchProvider? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchProvider?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchProviderByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchProviderByIdHash() =>
    r'ee8635577eba005b0d0cb216c33c4c859487a678';

/// The engine with [id], built-in or user-defined, or null when nothing carries
/// that id any more — a custom engine the user has since deleted, say.

final class SearchProviderByIdFamily extends $Family
    with $FunctionalFamilyOverride<SearchProvider?, String?> {
  SearchProviderByIdFamily._()
    : super(
        retry: null,
        name: r'searchProviderByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The engine with [id], built-in or user-defined, or null when nothing carries
  /// that id any more — a custom engine the user has since deleted, say.

  SearchProviderByIdProvider call(String? id) =>
      SearchProviderByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'searchProviderByIdProvider';
}

/// The engine typed queries go to unless something nearer overrides it.
///
/// Never null: an id naming no engine we still have — a deleted custom one, or
/// a setting from a build that shipped a different catalogue — lands on
/// [fallbackSearchProvider], so deleting the engine that was the default leaves
/// the browser searchable rather than broken.

@ProviderFor(defaultSearchProvider)
final defaultSearchProviderProvider = DefaultSearchProviderProvider._();

/// The engine typed queries go to unless something nearer overrides it.
///
/// Never null: an id naming no engine we still have — a deleted custom one, or
/// a setting from a build that shipped a different catalogue — lands on
/// [fallbackSearchProvider], so deleting the engine that was the default leaves
/// the browser searchable rather than broken.

final class DefaultSearchProviderProvider
    extends $FunctionalProvider<SearchProvider, SearchProvider, SearchProvider>
    with $Provider<SearchProvider> {
  /// The engine typed queries go to unless something nearer overrides it.
  ///
  /// Never null: an id naming no engine we still have — a deleted custom one, or
  /// a setting from a build that shipped a different catalogue — lands on
  /// [fallbackSearchProvider], so deleting the engine that was the default leaves
  /// the browser searchable rather than broken.
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
    r'a07c2ec5fa07a5ee7061335da77f72edd4d3d5f1';
