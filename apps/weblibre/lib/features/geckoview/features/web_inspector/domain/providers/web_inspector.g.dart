// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_inspector.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-device web inspector for [tabId], or for the selected tab when
/// [tabId] is null.
///
/// Stateless by design: the inspector's own visibility lives in the content
/// process, so there is nothing here to keep in sync with it.

@ProviderFor(webInspectorService)
final webInspectorServiceProvider = WebInspectorServiceFamily._();

/// The on-device web inspector for [tabId], or for the selected tab when
/// [tabId] is null.
///
/// Stateless by design: the inspector's own visibility lives in the content
/// process, so there is nothing here to keep in sync with it.

final class WebInspectorServiceProvider
    extends
        $FunctionalProvider<
          GeckoWebInspectorService,
          GeckoWebInspectorService,
          GeckoWebInspectorService
        >
    with $Provider<GeckoWebInspectorService> {
  /// The on-device web inspector for [tabId], or for the selected tab when
  /// [tabId] is null.
  ///
  /// Stateless by design: the inspector's own visibility lives in the content
  /// process, so there is nothing here to keep in sync with it.
  WebInspectorServiceProvider._({
    required WebInspectorServiceFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'webInspectorServiceProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$webInspectorServiceHash();

  @override
  String toString() {
    return r'webInspectorServiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<GeckoWebInspectorService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeckoWebInspectorService create(Ref ref) {
    final argument = this.argument as String?;
    return webInspectorService(ref, tabId: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeckoWebInspectorService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeckoWebInspectorService>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WebInspectorServiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$webInspectorServiceHash() =>
    r'388966fcc813c239450ae39149007c23582fedea';

/// The on-device web inspector for [tabId], or for the selected tab when
/// [tabId] is null.
///
/// Stateless by design: the inspector's own visibility lives in the content
/// process, so there is nothing here to keep in sync with it.

final class WebInspectorServiceFamily extends $Family
    with $FunctionalFamilyOverride<GeckoWebInspectorService, String?> {
  WebInspectorServiceFamily._()
    : super(
        retry: null,
        name: r'webInspectorServiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The on-device web inspector for [tabId], or for the selected tab when
  /// [tabId] is null.
  ///
  /// Stateless by design: the inspector's own visibility lives in the content
  /// process, so there is nothing here to keep in sync with it.

  WebInspectorServiceProvider call({String? tabId}) =>
      WebInspectorServiceProvider._(argument: tabId, from: this);

  @override
  String toString() => r'webInspectorServiceProvider';
}
