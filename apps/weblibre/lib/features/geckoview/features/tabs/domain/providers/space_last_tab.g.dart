// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_last_tab.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-space memory of what the tab list was last showing there, so
/// switching back to a space lands where it was left instead of on the home
/// surface.
///
/// Keyed on space uuid, holding either a tab id or an explicit "home" marker
/// (`null`). Absent from the map means "never recorded", which callers treat
/// the same as a stale/invalid entry — fall back to the space's own tabs.
///
/// A field of its own rather than a column on `ZenSettings`: that row is read
/// on hot paths and rewritten on every navigation, and would end up being
/// persisted on every tab switch for no reason connected to its own settings.
/// Local only — never part of Zen sync — and expected to go stale under it:
/// spaces and tabs can appear or disappear on the desktop side at any time,
/// so every read is a hint for `TabRepository.restoreSpaceTab` to validate,
/// never ground truth on its own.

@ProviderFor(SpaceLastTab)
final spaceLastTabProvider = SpaceLastTabProvider._();

/// Per-space memory of what the tab list was last showing there, so
/// switching back to a space lands where it was left instead of on the home
/// surface.
///
/// Keyed on space uuid, holding either a tab id or an explicit "home" marker
/// (`null`). Absent from the map means "never recorded", which callers treat
/// the same as a stale/invalid entry — fall back to the space's own tabs.
///
/// A field of its own rather than a column on `ZenSettings`: that row is read
/// on hot paths and rewritten on every navigation, and would end up being
/// persisted on every tab switch for no reason connected to its own settings.
/// Local only — never part of Zen sync — and expected to go stale under it:
/// spaces and tabs can appear or disappear on the desktop side at any time,
/// so every read is a hint for `TabRepository.restoreSpaceTab` to validate,
/// never ground truth on its own.
final class SpaceLastTabProvider
    extends $NotifierProvider<SpaceLastTab, Map<String, String?>> {
  /// Per-space memory of what the tab list was last showing there, so
  /// switching back to a space lands where it was left instead of on the home
  /// surface.
  ///
  /// Keyed on space uuid, holding either a tab id or an explicit "home" marker
  /// (`null`). Absent from the map means "never recorded", which callers treat
  /// the same as a stale/invalid entry — fall back to the space's own tabs.
  ///
  /// A field of its own rather than a column on `ZenSettings`: that row is read
  /// on hot paths and rewritten on every navigation, and would end up being
  /// persisted on every tab switch for no reason connected to its own settings.
  /// Local only — never part of Zen sync — and expected to go stale under it:
  /// spaces and tabs can appear or disappear on the desktop side at any time,
  /// so every read is a hint for `TabRepository.restoreSpaceTab` to validate,
  /// never ground truth on its own.
  SpaceLastTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spaceLastTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spaceLastTabHash();

  @$internal
  @override
  SpaceLastTab create() => SpaceLastTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String?>>(value),
    );
  }
}

String _$spaceLastTabHash() => r'6986c9f0f34a58d187982ea606525ade8eba0ea5';

/// Per-space memory of what the tab list was last showing there, so
/// switching back to a space lands where it was left instead of on the home
/// surface.
///
/// Keyed on space uuid, holding either a tab id or an explicit "home" marker
/// (`null`). Absent from the map means "never recorded", which callers treat
/// the same as a stale/invalid entry — fall back to the space's own tabs.
///
/// A field of its own rather than a column on `ZenSettings`: that row is read
/// on hot paths and rewritten on every navigation, and would end up being
/// persisted on every tab switch for no reason connected to its own settings.
/// Local only — never part of Zen sync — and expected to go stale under it:
/// spaces and tabs can appear or disappear on the desktop side at any time,
/// so every read is a hint for `TabRepository.restoreSpaceTab` to validate,
/// never ground truth on its own.

abstract class _$SpaceLastTab extends $Notifier<Map<String, String?>> {
  Map<String, String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, String?>, Map<String, String?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, String?>, Map<String, String?>>,
              Map<String, String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
