// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tab folders (Zen folders, PLAN §6.3). A folder is a slot in its parent
/// scope's child sequence next to normal tabs; deleting one closes the tabs of
/// its whole subtree through the engine first (PLAN §7.3).

@ProviderFor(FolderRepository)
final folderRepositoryProvider = FolderRepositoryProvider._();

/// Tab folders (Zen folders, PLAN §6.3). A folder is a slot in its parent
/// scope's child sequence next to normal tabs; deleting one closes the tabs of
/// its whole subtree through the engine first (PLAN §7.3).
final class FolderRepositoryProvider
    extends $NotifierProvider<FolderRepository, void> {
  /// Tab folders (Zen folders, PLAN §6.3). A folder is a slot in its parent
  /// scope's child sequence next to normal tabs; deleting one closes the tabs of
  /// its whole subtree through the engine first (PLAN §7.3).
  FolderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderRepositoryHash();

  @$internal
  @override
  FolderRepository create() => FolderRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$folderRepositoryHash() => r'd7bec2cfdb7214b1bcdfb21d9e171340abe9d23d';

/// Tab folders (Zen folders, PLAN §6.3). A folder is a slot in its parent
/// scope's child sequence next to normal tabs; deleting one closes the tabs of
/// its whole subtree through the engine first (PLAN §7.3).

abstract class _$FolderRepository extends $Notifier<void> {
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
