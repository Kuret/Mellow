// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The HTTP client the Sync 1.5 requests go through. Tests override it with
/// an `http.testing.MockClient`.

@ProviderFor(spacesSyncHttpClient)
final spacesSyncHttpClientProvider = SpacesSyncHttpClientProvider._();

/// The HTTP client the Sync 1.5 requests go through. Tests override it with
/// an `http.testing.MockClient`.

final class SpacesSyncHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// The HTTP client the Sync 1.5 requests go through. Tests override it with
  /// an `http.testing.MockClient`.
  SpacesSyncHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spacesSyncHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spacesSyncHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return spacesSyncHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$spacesSyncHttpClientHash() =>
    r'e8cb8d219c8ed0c2e78d7bdc15f124229c9458dd';

@ProviderFor(spacesSyncCredentials)
final spacesSyncCredentialsProvider = SpacesSyncCredentialsProvider._();

final class SpacesSyncCredentialsProvider
    extends
        $FunctionalProvider<
          SyncCredentialsSource,
          SyncCredentialsSource,
          SyncCredentialsSource
        >
    with $Provider<SyncCredentialsSource> {
  SpacesSyncCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spacesSyncCredentialsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spacesSyncCredentialsHash();

  @$internal
  @override
  $ProviderElement<SyncCredentialsSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncCredentialsSource create(Ref ref) {
    return spacesSyncCredentials(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncCredentialsSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncCredentialsSource>(value),
    );
  }
}

String _$spacesSyncCredentialsHash() =>
    r'47e396d4463397346f7c0883b44475ee22e12293';

/// Where the collection snapshots and the failed-id list live:
/// `<profile>/spaces_sync/`.

@ProviderFor(spacesSyncSnapshotStore)
final spacesSyncSnapshotStoreProvider = SpacesSyncSnapshotStoreProvider._();

/// Where the collection snapshots and the failed-id list live:
/// `<profile>/spaces_sync/`.

final class SpacesSyncSnapshotStoreProvider
    extends $FunctionalProvider<SnapshotStore, SnapshotStore, SnapshotStore>
    with $Provider<SnapshotStore> {
  /// Where the collection snapshots and the failed-id list live:
  /// `<profile>/spaces_sync/`.
  SpacesSyncSnapshotStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spacesSyncSnapshotStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spacesSyncSnapshotStoreHash();

  @$internal
  @override
  $ProviderElement<SnapshotStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SnapshotStore create(Ref ref) {
    return spacesSyncSnapshotStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SnapshotStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SnapshotStore>(value),
    );
  }
}

String _$spacesSyncSnapshotStoreHash() =>
    r'18ae19f2b9497e044e4a0b11c9b1ddc5d6517963';
