// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compact_bar_expanded_folders.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The folders the compact tab bar currently shows the members of, by folder
/// id. Local to the bar and never persisted: a folder's stored collapse state
/// belongs to the tray and the desktop sidebar, while the bar only has room
/// for one folder's members at a time and forgets them on restart.

@ProviderFor(CompactBarExpandedFolders)
final compactBarExpandedFoldersProvider = CompactBarExpandedFoldersProvider._();

/// The folders the compact tab bar currently shows the members of, by folder
/// id. Local to the bar and never persisted: a folder's stored collapse state
/// belongs to the tray and the desktop sidebar, while the bar only has room
/// for one folder's members at a time and forgets them on restart.
final class CompactBarExpandedFoldersProvider
    extends $NotifierProvider<CompactBarExpandedFolders, Set<String>> {
  /// The folders the compact tab bar currently shows the members of, by folder
  /// id. Local to the bar and never persisted: a folder's stored collapse state
  /// belongs to the tray and the desktop sidebar, while the bar only has room
  /// for one folder's members at a time and forgets them on restart.
  CompactBarExpandedFoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compactBarExpandedFoldersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compactBarExpandedFoldersHash();

  @$internal
  @override
  CompactBarExpandedFolders create() => CompactBarExpandedFolders();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$compactBarExpandedFoldersHash() =>
    r'1a8c0b525791bb0a22f2a99c398d385bfe529a3a';

/// The folders the compact tab bar currently shows the members of, by folder
/// id. Local to the bar and never persisted: a folder's stored collapse state
/// belongs to the tray and the desktop sidebar, while the bar only has room
/// for one folder's members at a time and forgets them on restart.

abstract class _$CompactBarExpandedFolders extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
