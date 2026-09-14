// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toolbar_button_configs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(toolbarButtonConfigs)
final toolbarButtonConfigsProvider = ToolbarButtonConfigsProvider._();

final class ToolbarButtonConfigsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ToolbarButtonConfig>>,
          List<ToolbarButtonConfig>,
          Stream<List<ToolbarButtonConfig>>
        >
    with
        $FutureModifier<List<ToolbarButtonConfig>>,
        $StreamProvider<List<ToolbarButtonConfig>> {
  ToolbarButtonConfigsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolbarButtonConfigsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolbarButtonConfigsHash();

  @$internal
  @override
  $StreamProviderElement<List<ToolbarButtonConfig>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ToolbarButtonConfig>> create(Ref ref) {
    return toolbarButtonConfigs(ref);
  }
}

String _$toolbarButtonConfigsHash() =>
    r'0ec3b6e30ace10f8b03fbd08ba743d822068c3b2';

@ProviderFor(effectiveToolbarButtonConfigs)
final effectiveToolbarButtonConfigsProvider =
    EffectiveToolbarButtonConfigsProvider._();

final class EffectiveToolbarButtonConfigsProvider
    extends
        $FunctionalProvider<
          EquatableValue<List<ToolbarButtonConfig>>,
          EquatableValue<List<ToolbarButtonConfig>>,
          EquatableValue<List<ToolbarButtonConfig>>
        >
    with $Provider<EquatableValue<List<ToolbarButtonConfig>>> {
  EffectiveToolbarButtonConfigsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveToolbarButtonConfigsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveToolbarButtonConfigsHash();

  @$internal
  @override
  $ProviderElement<EquatableValue<List<ToolbarButtonConfig>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EquatableValue<List<ToolbarButtonConfig>> create(Ref ref) {
    return effectiveToolbarButtonConfigs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EquatableValue<List<ToolbarButtonConfig>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<EquatableValue<List<ToolbarButtonConfig>>>(value),
    );
  }
}

String _$effectiveToolbarButtonConfigsHash() =>
    r'74ba70752ba2f4a0273becd3cf4fc31d2832820c';
