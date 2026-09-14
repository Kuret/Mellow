// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_intent_space.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The space a shared link should open in without asking, or `null` for "no
/// opinion".
///
/// `null` is deliberate output, not a missing case: [TabRepository.addTab]
/// already falls back to the selected space (and, failing that,
/// [SpaceRepository.ensureDefaultSpace]) when it is handed no `spaceUuid`.
/// Resolving that fallback here too would just be a second, competing
/// definition of "default space" to keep in sync with the first — better to
/// have exactly one place that decides it.
///
/// [ShareIntentSpaceMode.fixed] only wins when the space it names still
/// exists: `shareIntentSpaceUuid` is advisory, because the space it points at
/// can be deleted long after the setting was chosen.
///
/// A provider rather than a bare function so both call sites — a widget's
/// `WidgetRef` and a provider's `Ref` — reach it the same way, through
/// `ref.read(...future)`.

@ProviderFor(resolveShareIntentSpaceUuid)
final resolveShareIntentSpaceUuidProvider =
    ResolveShareIntentSpaceUuidProvider._();

/// The space a shared link should open in without asking, or `null` for "no
/// opinion".
///
/// `null` is deliberate output, not a missing case: [TabRepository.addTab]
/// already falls back to the selected space (and, failing that,
/// [SpaceRepository.ensureDefaultSpace]) when it is handed no `spaceUuid`.
/// Resolving that fallback here too would just be a second, competing
/// definition of "default space" to keep in sync with the first — better to
/// have exactly one place that decides it.
///
/// [ShareIntentSpaceMode.fixed] only wins when the space it names still
/// exists: `shareIntentSpaceUuid` is advisory, because the space it points at
/// can be deleted long after the setting was chosen.
///
/// A provider rather than a bare function so both call sites — a widget's
/// `WidgetRef` and a provider's `Ref` — reach it the same way, through
/// `ref.read(...future)`.

final class ResolveShareIntentSpaceUuidProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The space a shared link should open in without asking, or `null` for "no
  /// opinion".
  ///
  /// `null` is deliberate output, not a missing case: [TabRepository.addTab]
  /// already falls back to the selected space (and, failing that,
  /// [SpaceRepository.ensureDefaultSpace]) when it is handed no `spaceUuid`.
  /// Resolving that fallback here too would just be a second, competing
  /// definition of "default space" to keep in sync with the first — better to
  /// have exactly one place that decides it.
  ///
  /// [ShareIntentSpaceMode.fixed] only wins when the space it names still
  /// exists: `shareIntentSpaceUuid` is advisory, because the space it points at
  /// can be deleted long after the setting was chosen.
  ///
  /// A provider rather than a bare function so both call sites — a widget's
  /// `WidgetRef` and a provider's `Ref` — reach it the same way, through
  /// `ref.read(...future)`.
  ResolveShareIntentSpaceUuidProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resolveShareIntentSpaceUuidProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resolveShareIntentSpaceUuidHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return resolveShareIntentSpaceUuid(ref);
  }
}

String _$resolveShareIntentSpaceUuidHash() =>
    r'1d18e391f2415208ff56b13b4bb997d081927cad';
