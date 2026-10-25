// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_content_opener.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Turns every [SharedContent] that reaches the app into the route that acts
/// on it: the "Open link" sheet for a URL, the search screen for text.
///
/// A link that arrives from outside never lands in a tab on its own: it opens
/// the custom tab, and the sheet pushed here is the only way to promote it into
/// one — which is also where its space is chosen.
///
/// This is a service rather than a listener in the browser widget because
/// flutter_riverpod pauses a widget's subscriptions while its `TickerMode` is
/// off, which is the case whenever an opaque route (settings, say) sits over
/// the browser. A share that arrived in the meantime was then held and delivered
/// only once the user came back, by which time it looked like a stale link
/// re-opening by itself. A keepAlive provider is never paused.
///
/// Two more things used to make an old link reappear, and are handled here:
///
/// * A sheet that the user left open (switched apps without dismissing it) got
///   the next sheet stacked on top, and showed again when that one popped. A
///   new share now replaces a sheet that is already on top.
/// * A rebuild of the intent stream re-emits its last value as
///   `AsyncData(previous, isLoading: true)`. The same instance is ignored; a
///   genuine repeat share is a new [SharedContent] and still opens.

@ProviderFor(sharedContentOpener)
final sharedContentOpenerProvider = SharedContentOpenerProvider._();

/// Turns every [SharedContent] that reaches the app into the route that acts
/// on it: the "Open link" sheet for a URL, the search screen for text.
///
/// A link that arrives from outside never lands in a tab on its own: it opens
/// the custom tab, and the sheet pushed here is the only way to promote it into
/// one — which is also where its space is chosen.
///
/// This is a service rather than a listener in the browser widget because
/// flutter_riverpod pauses a widget's subscriptions while its `TickerMode` is
/// off, which is the case whenever an opaque route (settings, say) sits over
/// the browser. A share that arrived in the meantime was then held and delivered
/// only once the user came back, by which time it looked like a stale link
/// re-opening by itself. A keepAlive provider is never paused.
///
/// Two more things used to make an old link reappear, and are handled here:
///
/// * A sheet that the user left open (switched apps without dismissing it) got
///   the next sheet stacked on top, and showed again when that one popped. A
///   new share now replaces a sheet that is already on top.
/// * A rebuild of the intent stream re-emits its last value as
///   `AsyncData(previous, isLoading: true)`. The same instance is ignored; a
///   genuine repeat share is a new [SharedContent] and still opens.

final class SharedContentOpenerProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Turns every [SharedContent] that reaches the app into the route that acts
  /// on it: the "Open link" sheet for a URL, the search screen for text.
  ///
  /// A link that arrives from outside never lands in a tab on its own: it opens
  /// the custom tab, and the sheet pushed here is the only way to promote it into
  /// one — which is also where its space is chosen.
  ///
  /// This is a service rather than a listener in the browser widget because
  /// flutter_riverpod pauses a widget's subscriptions while its `TickerMode` is
  /// off, which is the case whenever an opaque route (settings, say) sits over
  /// the browser. A share that arrived in the meantime was then held and delivered
  /// only once the user came back, by which time it looked like a stale link
  /// re-opening by itself. A keepAlive provider is never paused.
  ///
  /// Two more things used to make an old link reappear, and are handled here:
  ///
  /// * A sheet that the user left open (switched apps without dismissing it) got
  ///   the next sheet stacked on top, and showed again when that one popped. A
  ///   new share now replaces a sheet that is already on top.
  /// * A rebuild of the intent stream re-emits its last value as
  ///   `AsyncData(previous, isLoading: true)`. The same instance is ignored; a
  ///   genuine repeat share is a new [SharedContent] and still opens.
  SharedContentOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedContentOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedContentOpenerHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return sharedContentOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$sharedContentOpenerHash() =>
    r'6466ae2b20c9f2217280981eda2abfb8b334b333';
