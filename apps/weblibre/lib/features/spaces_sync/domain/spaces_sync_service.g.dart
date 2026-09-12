// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spaces_sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The two-way Firefox Sync client for Zen's `spaces` collection (PLAN §8,
/// W6.3). Runs on start, on resume, every minute in the foreground, three
/// seconds after the tab model last changed, and from `background_fetch`;
/// every run is serialised through one lock.

@ProviderFor(SpacesSyncService)
final spacesSyncServiceProvider = SpacesSyncServiceProvider._();

/// The two-way Firefox Sync client for Zen's `spaces` collection (PLAN §8,
/// W6.3). Runs on start, on resume, every minute in the foreground, three
/// seconds after the tab model last changed, and from `background_fetch`;
/// every run is serialised through one lock.
final class SpacesSyncServiceProvider
    extends $NotifierProvider<SpacesSyncService, SpacesSyncStatus> {
  /// The two-way Firefox Sync client for Zen's `spaces` collection (PLAN §8,
  /// W6.3). Runs on start, on resume, every minute in the foreground, three
  /// seconds after the tab model last changed, and from `background_fetch`;
  /// every run is serialised through one lock.
  SpacesSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spacesSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spacesSyncServiceHash();

  @$internal
  @override
  SpacesSyncService create() => SpacesSyncService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpacesSyncStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpacesSyncStatus>(value),
    );
  }
}

String _$spacesSyncServiceHash() => r'17bff86dcf8beaa2d5a625ea66c9c6446d89f0d5';

/// The two-way Firefox Sync client for Zen's `spaces` collection (PLAN §8,
/// W6.3). Runs on start, on resume, every minute in the foreground, three
/// seconds after the tab model last changed, and from `background_fetch`;
/// every run is serialised through one lock.

abstract class _$SpacesSyncService extends $Notifier<SpacesSyncStatus> {
  SpacesSyncStatus build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SpacesSyncStatus, SpacesSyncStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpacesSyncStatus, SpacesSyncStatus>,
              SpacesSyncStatus,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
