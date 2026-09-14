// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toolbar_button_config_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(toolbarConfigRepository)
final toolbarConfigRepositoryProvider = ToolbarConfigRepositoryProvider._();

final class ToolbarConfigRepositoryProvider
    extends
        $FunctionalProvider<
          ToolbarButtonConfigRepository,
          ToolbarButtonConfigRepository,
          ToolbarButtonConfigRepository
        >
    with $Provider<ToolbarButtonConfigRepository> {
  ToolbarConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolbarConfigRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolbarConfigRepositoryHash();

  @$internal
  @override
  $ProviderElement<ToolbarButtonConfigRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ToolbarButtonConfigRepository create(Ref ref) {
    return toolbarConfigRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToolbarButtonConfigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToolbarButtonConfigRepository>(
        value,
      ),
    );
  }
}

String _$toolbarConfigRepositoryHash() =>
    r'c6d6b5e12eb1b02560ae0735670281f1de492320';
