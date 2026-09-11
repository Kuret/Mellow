// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// HttpClient used by both WebSocket (via `IOWebSocketChannel.customClient`)
/// and HTTP-based search clients.

@ProviderFor(searchHttpClient)
final searchHttpClientProvider = SearchHttpClientProvider._();

/// HttpClient used by both WebSocket (via `IOWebSocketChannel.customClient`)
/// and HTTP-based search clients.

final class SearchHttpClientProvider
    extends $FunctionalProvider<HttpClient, HttpClient, HttpClient>
    with $Provider<HttpClient> {
  /// HttpClient used by both WebSocket (via `IOWebSocketChannel.customClient`)
  /// and HTTP-based search clients.
  SearchHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHttpClientHash();

  @$internal
  @override
  $ProviderElement<HttpClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HttpClient create(Ref ref) {
    return searchHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HttpClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HttpClient>(value),
    );
  }
}

String _$searchHttpClientHash() => r'984df0e3fc6770b7de174b5a227bce77b8824efc';

/// `package:http` Client wrapping [searchHttpClientProvider]. Use for the
/// non-WebSocket parts of the search flow (token issuance, one-shot capture,
/// capture artifact downloads).

@ProviderFor(searchProxyHttpClient)
final searchProxyHttpClientProvider = SearchProxyHttpClientProvider._();

/// `package:http` Client wrapping [searchHttpClientProvider]. Use for the
/// non-WebSocket parts of the search flow (token issuance, one-shot capture,
/// capture artifact downloads).

final class SearchProxyHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// `package:http` Client wrapping [searchHttpClientProvider]. Use for the
  /// non-WebSocket parts of the search flow (token issuance, one-shot capture,
  /// capture artifact downloads).
  SearchProxyHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchProxyHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchProxyHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return searchProxyHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$searchProxyHttpClientHash() =>
    r'08acee399abc5c6960a82365219af6b5a44ba5bd';
