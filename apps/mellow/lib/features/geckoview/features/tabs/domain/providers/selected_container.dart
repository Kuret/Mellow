/*
 * Copyright (c) 2024-2026 Fabian Freund.
 *
 * This file is part of WebLibre
 * (see https://weblibre.eu).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import 'dart:async';
import 'dart:convert';

import 'package:mellow/core/logger.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/container_filter.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/space_last_tab.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/tab.dart';
import 'package:mellow/features/user/data/providers.dart';
import 'package:riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_container.g.dart';

enum SetContainerResult { failed, success }

@Riverpod(keepAlive: true)
class SelectedContainer extends _$SelectedContainer {
  Future<ContainerData?> fetchData() async {
    if (state != null) {
      return await ref
          .read(containerRepositoryProvider.notifier)
          .getContainerData(state!);
    }

    return null;
  }

  Future<SetContainerResult> setContainerId(
    String id, {
    bool Function()? shouldApply,
  }) async {
    final container = await ref
        .read(containerRepositoryProvider.notifier)
        .getContainerData(id);

    bool canApply() => shouldApply?.call() ?? true;

    if (ref.mounted && container != null && canApply()) {
      state = id;
      return SetContainerResult.success;
    }

    return SetContainerResult.failed;
  }

  void clearContainer() {
    state = null;
  }

  @override
  String? build() {
    final persistCompleter = Completer();

    final persistResult = persist(
      ref.watch(riverpodDatabaseStorageProvider),
      key: 'SelectedContainer',
      options: const StorageOptions(cacheTime: StorageCacheTime.unsafe_forever),
      encode: (state) => jsonEncode([state]),
      decode: (encoded) =>
          (jsonDecode(encoded) as List<dynamic>).first as String?,
    );

    unawaited(
      (persistResult.future ?? Future.value()).whenComplete(
        () => persistCompleter.complete(),
      ),
    );

    ref.listen(
      fireImmediately: true,
      watchContainersWithCountProvider,
      (previous, next) {
        if (stateOrNull != null && next.value != null) {
          if (!next.value!.any((container) => container.id == state)) {
            clearContainer();
          }
        }
      },
      onError: (error, stackTrace) {
        logger.e(
          'Error listening to containersWithCountProvider',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    ref.listen(
      fireImmediately: true,
      selectedTabProvider,
      (previous, next) async {
        if (next != null) {
          if (!persistCompleter.isCompleted) {
            await persistCompleter.future;
          }

          final tabData = await ref
              .read(tabDataRepositoryProvider.notifier)
              .getTabDataById(next);

          if (ref.mounted &&
              tabData != null &&
              tabData.containerId != stateOrNull) {
            if (tabData.containerId != null) {
              await setContainerId(tabData.containerId!);
            } else {
              clearContainer();
            }
          }
        }
      },
      onError: (error, stackTrace) {
        logger.e(
          'Error listening to selectedTabProvider',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    return stateOrNull;
  }
}

@Riverpod()
Stream<ContainerData?> selectedContainerData(Ref ref) {
  final db = ref.watch(tabDatabaseProvider);
  final selectedContainer = ref.watch(selectedContainerProvider);

  if (selectedContainer != null) {
    return db.containerDao
        .getContainerData(selectedContainer)
        .watchSingleOrNull();
  }

  return Stream.value(null);
}

/// Forces the home surface on regardless of what is selected.
///
/// The home-target setting needs a way to say "stay on home" that survives the
/// engine auto-selecting a tab underneath — for instance when the last tab in a
/// container is closed. Keeping it as a separate flag leaves
/// [shouldShowBrowserHome] a pure predicate, and avoids pinning the selected
/// container, which [SelectedContainer]'s own tab listener would immediately
/// undo.
///
/// Cleared by [TabRepository.selectTab] and by creating a tab, i.e. by the user
/// deliberately going somewhere.
@Riverpod(keepAlive: true)
class ForceBrowserHome extends _$ForceBrowserHome {
  /// Requests the home surface, and — if a space is selected — remembers
  /// that this space was last deliberately left on home, so switching back
  /// to it later comes back to home too instead of a fallback tab.
  void request() {
    state = true;
    final spaceUuid = ref.read(selectedSpaceProvider);
    if (spaceUuid != null) {
      unawaited(ref.read(spaceLastTabProvider.notifier).recordHome(spaceUuid));
    }
  }

  void clear() => state = false;

  @override
  bool build() => false;
}

/// Whether a remembered tab is being restored for a space that was just
/// selected.
///
/// [ShouldShowBrowserHome] holds its previous answer while this is set,
/// instead of flashing home for the frame or two the restore's DB reads take
/// — see [TabRepository.restoreSpaceTab], the only writer.
@Riverpod(keepAlive: true)
class RestoringSpaceTab extends _$RestoringSpaceTab {
  void start() => state = true;
  void finish() => state = false;

  @override
  bool build() => false;
}

/// Whether the browser home screen should be displayed instead of the
/// active tab's content.
///
/// Returns `true` when any of the following hold:
/// 0. [ForceBrowserHome] is set, i.e. the home target asked to stay here.
/// 1. No tab is selected at all (app just started or all tabs closed).
/// 2. The selected tab belongs to a different space than the currently
///    selected space – this implies the user manually switched spaces after
///    selecting a tab, because tab selection automatically syncs the selected
///    space to match the tab's space. Tabs without a space (private tabs,
///    essentials) are visible from every space and never trigger this.
///
/// Condition (2) also implicitly covers the case where the selected space has
/// zero tabs: if the space has no tabs, the selected tab (if any) necessarily
/// belongs to a different space.
///
/// A [Notifier] rather than a plain function so it can hold its previous
/// answer (`stateOrNull`) while [RestoringSpaceTab] is in flight, instead of
/// flipping to home and back for the frame or two the restore's DB reads
/// take.
@Riverpod(keepAlive: true)
class ShouldShowBrowserHome extends _$ShouldShowBrowserHome {
  @override
  bool build() {
    if (ref.watch(forceBrowserHomeProvider)) return true;

    final selectedTab = ref.watch(selectedTabProvider);

    // No tab selected → always show home.
    if (selectedTab == null) return true;

    if (ref.watch(restoringSpaceTabProvider)) {
      return stateOrNull ?? false;
    }

    final selectedSpace = ref.watch(selectedSpaceProvider);
    final tabSpaceUuid = ref.watch(selectedTabSpaceUuidProvider);

    // Once we know the tab's space, compare with the selected space.
    return switch (tabSpaceUuid) {
      AsyncData(:final value) => value != null && value != selectedSpace,
      // While loading, keep the current view to avoid flashing.
      _ => false,
    };
  }
}

@Riverpod()
Future<int> selectedContainerTabCount(Ref ref) async {
  final selectedContainer = ref.watch(selectedContainerProvider);

  return ref.watch(
    watchContainerTabIdsProvider(
      // ignore: provider_parameters
      ContainerFilterById(containerId: selectedContainer),
    ).selectAsync((tabs) => tabs.length),
  );
}
