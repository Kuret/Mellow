// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_history.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Address-bar search history. Rehomed from the bangs database so it outlives
/// the bangs feature; the engine a search ran through was never surfaced
/// anywhere, so only the query text and its timestamp made the move.

@ProviderFor(SearchHistoryRepository)
final searchHistoryRepositoryProvider = SearchHistoryRepositoryProvider._();

/// Address-bar search history. Rehomed from the bangs database so it outlives
/// the bangs feature; the engine a search ran through was never surfaced
/// anywhere, so only the query text and its timestamp made the move.
final class SearchHistoryRepositoryProvider
    extends $NotifierProvider<SearchHistoryRepository, void> {
  /// Address-bar search history. Rehomed from the bangs database so it outlives
  /// the bangs feature; the engine a search ran through was never surfaced
  /// anywhere, so only the query text and its timestamp made the move.
  SearchHistoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchHistoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHistoryRepositoryHash();

  @$internal
  @override
  SearchHistoryRepository create() => SearchHistoryRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$searchHistoryRepositoryHash() =>
    r'c152a9e423c794e827b9fef3c1fe75deb2ec14e8';

/// Address-bar search history. Rehomed from the bangs database so it outlives
/// the bangs feature; the engine a search ran through was never surfaced
/// anywhere, so only the query text and its timestamp made the move.

abstract class _$SearchHistoryRepository extends $Notifier<void> {
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

@ProviderFor(searchHistory)
final searchHistoryProvider = SearchHistoryProvider._();

final class SearchHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SearchHistoryData>>,
          List<SearchHistoryData>,
          Stream<List<SearchHistoryData>>
        >
    with
        $FutureModifier<List<SearchHistoryData>>,
        $StreamProvider<List<SearchHistoryData>> {
  SearchHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<SearchHistoryData>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SearchHistoryData>> create(Ref ref) {
    return searchHistory(ref);
  }
}

String _$searchHistoryHash() => r'f25ff90fcdc8377aa815cbffb83c664fd6b00d2b';
