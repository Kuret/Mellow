// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_section_display.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-section collapse and show-all state, keyed by host as well as section.

@ProviderFor(SearchSectionDisplayStateController)
final searchSectionDisplayStateControllerProvider =
    SearchSectionDisplayStateControllerFamily._();

/// Per-section collapse and show-all state, keyed by host as well as section.
final class SearchSectionDisplayStateControllerProvider
    extends
        $NotifierProvider<
          SearchSectionDisplayStateController,
          SearchSectionDisplayState
        > {
  /// Per-section collapse and show-all state, keyed by host as well as section.
  SearchSectionDisplayStateControllerProvider._({
    required SearchSectionDisplayStateControllerFamily super.from,
    required (SearchSectionHost, SearchSection) super.argument,
  }) : super(
         retry: null,
         name: r'searchSectionDisplayStateControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$searchSectionDisplayStateControllerHash();

  @override
  String toString() {
    return r'searchSectionDisplayStateControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SearchSectionDisplayStateController create() =>
      SearchSectionDisplayStateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchSectionDisplayState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchSectionDisplayState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchSectionDisplayStateControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchSectionDisplayStateControllerHash() =>
    r'319b4dd6ba7739f5cec665c98903392412d3ef59';

/// Per-section collapse and show-all state, keyed by host as well as section.

final class SearchSectionDisplayStateControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SearchSectionDisplayStateController,
          SearchSectionDisplayState,
          SearchSectionDisplayState,
          SearchSectionDisplayState,
          (SearchSectionHost, SearchSection)
        > {
  SearchSectionDisplayStateControllerFamily._()
    : super(
        retry: null,
        name: r'searchSectionDisplayStateControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-section collapse and show-all state, keyed by host as well as section.

  SearchSectionDisplayStateControllerProvider call(
    SearchSectionHost host,
    SearchSection section,
  ) => SearchSectionDisplayStateControllerProvider._(
    argument: (host, section),
    from: this,
  );

  @override
  String toString() => r'searchSectionDisplayStateControllerProvider';
}

/// Per-section collapse and show-all state, keyed by host as well as section.

abstract class _$SearchSectionDisplayStateController
    extends $Notifier<SearchSectionDisplayState> {
  late final _$args = ref.$arg as (SearchSectionHost, SearchSection);
  SearchSectionHost get host => _$args.$1;
  SearchSection get section => _$args.$2;

  SearchSectionDisplayState build(
    SearchSectionHost host,
    SearchSection section,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<SearchSectionDisplayState, SearchSectionDisplayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchSectionDisplayState, SearchSectionDisplayState>,
              SearchSectionDisplayState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
