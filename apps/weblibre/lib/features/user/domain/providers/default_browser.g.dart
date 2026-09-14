// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_browser.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether this app currently holds the system's default-browser role.
///
/// Kept alive on purpose. The menu row that offers to claim the role only
/// renders while the role is *not* held, so a fresh async read on every menu
/// open would leave the row missing for the first frames of the sheet and then
/// drop it in mid-animation. Cached, only the very first open pays for the
/// platform call.
///
/// Nothing observes the role, so the answer is refreshed by whoever could have
/// changed it: the row itself after the system dialog, and the menu sheet on
/// open, which covers the user granting the role in Android's own settings.

@ProviderFor(IsDefaultBrowser)
final isDefaultBrowserProvider = IsDefaultBrowserProvider._();

/// Whether this app currently holds the system's default-browser role.
///
/// Kept alive on purpose. The menu row that offers to claim the role only
/// renders while the role is *not* held, so a fresh async read on every menu
/// open would leave the row missing for the first frames of the sheet and then
/// drop it in mid-animation. Cached, only the very first open pays for the
/// platform call.
///
/// Nothing observes the role, so the answer is refreshed by whoever could have
/// changed it: the row itself after the system dialog, and the menu sheet on
/// open, which covers the user granting the role in Android's own settings.
final class IsDefaultBrowserProvider
    extends $AsyncNotifierProvider<IsDefaultBrowser, bool> {
  /// Whether this app currently holds the system's default-browser role.
  ///
  /// Kept alive on purpose. The menu row that offers to claim the role only
  /// renders while the role is *not* held, so a fresh async read on every menu
  /// open would leave the row missing for the first frames of the sheet and then
  /// drop it in mid-animation. Cached, only the very first open pays for the
  /// platform call.
  ///
  /// Nothing observes the role, so the answer is refreshed by whoever could have
  /// changed it: the row itself after the system dialog, and the menu sheet on
  /// open, which covers the user granting the role in Android's own settings.
  IsDefaultBrowserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isDefaultBrowserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isDefaultBrowserHash();

  @$internal
  @override
  IsDefaultBrowser create() => IsDefaultBrowser();
}

String _$isDefaultBrowserHash() => r'53dd8ddc2e95d40acf2db13c48ac9d3e7c544524';

/// Whether this app currently holds the system's default-browser role.
///
/// Kept alive on purpose. The menu row that offers to claim the role only
/// renders while the role is *not* held, so a fresh async read on every menu
/// open would leave the row missing for the first frames of the sheet and then
/// drop it in mid-animation. Cached, only the very first open pays for the
/// platform call.
///
/// Nothing observes the role, so the answer is refreshed by whoever could have
/// changed it: the row itself after the system dialog, and the menu sheet on
/// open, which covers the user granting the role in Android's own settings.

abstract class _$IsDefaultBrowser extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
