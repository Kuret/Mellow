// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intent.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every shared URL or text the app should act on, parsed from the sharing and
/// home-widget intent streams.
///
/// Consumed by `sharedContentOpener`, a keepAlive service that main.dart
/// activates for the life of the app, which is why this is kept alive too.
/// Keeping the handler out of the browser widget matters: a widget's
/// subscriptions are paused while an opaque route covers it.

@ProviderFor(EngineBoundIntentStream)
final engineBoundIntentStreamProvider = EngineBoundIntentStreamProvider._();

/// Every shared URL or text the app should act on, parsed from the sharing and
/// home-widget intent streams.
///
/// Consumed by `sharedContentOpener`, a keepAlive service that main.dart
/// activates for the life of the app, which is why this is kept alive too.
/// Keeping the handler out of the browser widget matters: a widget's
/// subscriptions are paused while an opaque route covers it.
final class EngineBoundIntentStreamProvider
    extends $StreamNotifierProvider<EngineBoundIntentStream, SharedContent> {
  /// Every shared URL or text the app should act on, parsed from the sharing and
  /// home-widget intent streams.
  ///
  /// Consumed by `sharedContentOpener`, a keepAlive service that main.dart
  /// activates for the life of the app, which is why this is kept alive too.
  /// Keeping the handler out of the browser widget matters: a widget's
  /// subscriptions are paused while an opaque route covers it.
  EngineBoundIntentStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engineBoundIntentStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engineBoundIntentStreamHash();

  @$internal
  @override
  EngineBoundIntentStream create() => EngineBoundIntentStream();
}

String _$engineBoundIntentStreamHash() =>
    r'00d8fc5da2a3fb3f9795ba97cc3f5085a92765aa';

/// Every shared URL or text the app should act on, parsed from the sharing and
/// home-widget intent streams.
///
/// Consumed by `sharedContentOpener`, a keepAlive service that main.dart
/// activates for the life of the app, which is why this is kept alive too.
/// Keeping the handler out of the browser widget matters: a widget's
/// subscriptions are paused while an opaque route covers it.

abstract class _$EngineBoundIntentStream
    extends $StreamNotifier<SharedContent> {
  Stream<SharedContent> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SharedContent>, SharedContent>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SharedContent>, SharedContent>,
              AsyncValue<SharedContent>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
