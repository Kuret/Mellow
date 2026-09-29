// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_menu_shown_at.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// When the hit-result context menu (over a link, image or media source)
/// last opened.
///
/// A right click always reaches the native router, whether or not it lands on
/// something Gecko can hit-test, and the router reports it to Flutter either
/// way. The page context menu — raised for the case it doesn't — reads this
/// to tell "a hit-result menu just opened for this same click" from "nothing
/// did", rather than the two menus coordinating directly.

@ProviderFor(ContextMenuShownAt)
final contextMenuShownAtProvider = ContextMenuShownAtProvider._();

/// When the hit-result context menu (over a link, image or media source)
/// last opened.
///
/// A right click always reaches the native router, whether or not it lands on
/// something Gecko can hit-test, and the router reports it to Flutter either
/// way. The page context menu — raised for the case it doesn't — reads this
/// to tell "a hit-result menu just opened for this same click" from "nothing
/// did", rather than the two menus coordinating directly.
final class ContextMenuShownAtProvider
    extends $NotifierProvider<ContextMenuShownAt, DateTime?> {
  /// When the hit-result context menu (over a link, image or media source)
  /// last opened.
  ///
  /// A right click always reaches the native router, whether or not it lands on
  /// something Gecko can hit-test, and the router reports it to Flutter either
  /// way. The page context menu — raised for the case it doesn't — reads this
  /// to tell "a hit-result menu just opened for this same click" from "nothing
  /// did", rather than the two menus coordinating directly.
  ContextMenuShownAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contextMenuShownAtProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contextMenuShownAtHash();

  @$internal
  @override
  ContextMenuShownAt create() => ContextMenuShownAt();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$contextMenuShownAtHash() =>
    r'8fa19fad1cf6bddbdd3561ba210204b3c3065768';

/// When the hit-result context menu (over a link, image or media source)
/// last opened.
///
/// A right click always reaches the native router, whether or not it lands on
/// something Gecko can hit-test, and the router reports it to Flutter either
/// way. The page context menu — raised for the case it doesn't — reads this
/// to tell "a hit-result menu just opened for this same click" from "nothing
/// did", rather than the two menus coordinating directly.

abstract class _$ContextMenuShownAt extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
