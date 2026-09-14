// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_index_settings_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mirrors `enableLocalSearchIndex` / `indexPrivateTabs` from user.db
/// settings into tab.db's `local_index_setting` rows. The trigger reads
/// from `local_index_setting` exclusively, so this provider is the bridge
/// keeping both in sync.
///
/// Scheduled as a `keepAlive` provider that's read at app start
/// (`main.dart`) so the listener is wired before the first tab event
/// reaches the database.

@ProviderFor(LocalIndexSettingsSync)
final localIndexSettingsSyncProvider = LocalIndexSettingsSyncProvider._();

/// Mirrors `enableLocalSearchIndex` / `indexPrivateTabs` from user.db
/// settings into tab.db's `local_index_setting` rows. The trigger reads
/// from `local_index_setting` exclusively, so this provider is the bridge
/// keeping both in sync.
///
/// Scheduled as a `keepAlive` provider that's read at app start
/// (`main.dart`) so the listener is wired before the first tab event
/// reaches the database.
final class LocalIndexSettingsSyncProvider
    extends $NotifierProvider<LocalIndexSettingsSync, void> {
  /// Mirrors `enableLocalSearchIndex` / `indexPrivateTabs` from user.db
  /// settings into tab.db's `local_index_setting` rows. The trigger reads
  /// from `local_index_setting` exclusively, so this provider is the bridge
  /// keeping both in sync.
  ///
  /// Scheduled as a `keepAlive` provider that's read at app start
  /// (`main.dart`) so the listener is wired before the first tab event
  /// reaches the database.
  LocalIndexSettingsSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localIndexSettingsSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localIndexSettingsSyncHash();

  @$internal
  @override
  LocalIndexSettingsSync create() => LocalIndexSettingsSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$localIndexSettingsSyncHash() =>
    r'f11cdbfc9825dfe7440ba6dc4188c7ab4d1e19e1';

/// Mirrors `enableLocalSearchIndex` / `indexPrivateTabs` from user.db
/// settings into tab.db's `local_index_setting` rows. The trigger reads
/// from `local_index_setting` exclusively, so this provider is the bridge
/// keeping both in sync.
///
/// Scheduled as a `keepAlive` provider that's read at app start
/// (`main.dart`) so the listener is wired before the first tab event
/// reaches the database.

abstract class _$LocalIndexSettingsSync extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
