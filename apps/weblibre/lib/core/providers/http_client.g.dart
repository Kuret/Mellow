// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The plain HTTP client for app-originated requests.
///
/// Everything that used to go through the proxy-aware routed client now uses
/// a single unrouted `http.Client` — favicon lookups, autosuggest, account
/// handoff, feed reads and the rest have no notion of routing left to honour.

@ProviderFor(appHttpClient)
final appHttpClientProvider = AppHttpClientProvider._();

/// The plain HTTP client for app-originated requests.
///
/// Everything that used to go through the proxy-aware routed client now uses
/// a single unrouted `http.Client` — favicon lookups, autosuggest, account
/// handoff, feed reads and the rest have no notion of routing left to honour.

final class AppHttpClientProvider
    extends
        $FunctionalProvider<
          Raw<http.Client>,
          Raw<http.Client>,
          Raw<http.Client>
        >
    with $Provider<Raw<http.Client>> {
  /// The plain HTTP client for app-originated requests.
  ///
  /// Everything that used to go through the proxy-aware routed client now uses
  /// a single unrouted `http.Client` — favicon lookups, autosuggest, account
  /// handoff, feed reads and the rest have no notion of routing left to honour.
  AppHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appHttpClientHash();

  @$internal
  @override
  $ProviderElement<Raw<http.Client>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Raw<http.Client> create(Ref ref) {
    return appHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<http.Client> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<http.Client>>(value),
    );
  }
}

String _$appHttpClientHash() => r'7a31605c8f9f99c073da1ce2d579e5d3e9de751c';
