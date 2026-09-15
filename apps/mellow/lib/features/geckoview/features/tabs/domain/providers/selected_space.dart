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
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/entities/container_cycle.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/space_last_tab.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/space.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/tab.dart';
import 'package:mellow/features/user/data/providers.dart';
import 'package:riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_space.g.dart';

/// The space the tab list shows and new regular tabs are created in.
///
/// Persisted across restarts. Always names an existing space once the space
/// list has loaded: an empty table gets a default space, a stale uuid falls
/// back to the first space by `order_index`. Follows the selected tab's space
/// the way [SelectedContainer] follows the tab's container — a tab without a
/// space (private, essential) leaves the selection alone.
@Riverpod(keepAlive: true)
class SelectedSpace extends _$SelectedSpace {
  Future<SpaceData?> fetchData() async {
    final uuid = stateOrNull;
    if (uuid == null) {
      return null;
    }
    return ref.read(spaceRepositoryProvider.notifier).getSpace(uuid);
  }

  /// The selected space's uuid; `null` while none is selected yet.
  String? get space => state;

  set space(String? uuid) {
    state = uuid;
  }

  /// Selects the space one step [direction] from the selected one in
  /// `order_index` order, wrapping around at both ends — the bar and rail
  /// swipes, and the tray's two-finger swipe, all step through the same
  /// cycle. Returns false when there is nowhere to go: fewer than two spaces,
  /// or the list not loaded yet.
  bool cycle(ContainerCycleDirection direction) {
    final spaces = ref.read(watchSpacesProvider).value ?? const <SpaceData>[];
    final index = adjacentContainerIndex(
      [for (final space in spaces) space.uuid],
      state,
      direction,
    );
    if (index == null) {
      return false;
    }
    state = spaces[index].uuid;
    return true;
  }

  @override
  String? build() {
    final persistCompleter = Completer<void>();
    final persistResult = persist(
      ref.watch(riverpodDatabaseStorageProvider),
      key: 'SelectedSpace',
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

    var ensuringDefault = false;
    ref.listen(
      fireImmediately: true,
      watchSpacesProvider,
      (previous, next) async {
        final spaces = next.value;
        if (spaces == null) {
          return;
        }
        if (spaces.isEmpty) {
          if (ensuringDefault) {
            return;
          }
          ensuringDefault = true;
          try {
            await ref
                .read(spaceRepositoryProvider.notifier)
                .ensureDefaultSpace();
          } finally {
            ensuringDefault = false;
          }
          return;
        }
        if (!persistCompleter.isCompleted) {
          await persistCompleter.future;
        }
        if (!ref.mounted) {
          return;
        }
        final current = stateOrNull;
        if (current == null || !spaces.any((space) => space.uuid == current)) {
          state = spaces.first.uuid;
        }
        // Drop the memory a deleted space would otherwise leave behind
        // forever — the map is keyed on space uuid and nothing else prunes
        // it.
        unawaited(
          ref.read(spaceLastTabProvider.notifier).pruneToSpaces({
            for (final space in spaces) space.uuid,
          }),
        );
      },
      onError: (error, stackTrace) {
        logger.e(
          'Error listening to watchSpacesProvider',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    ref.listen(
      fireImmediately: true,
      selectedTabProvider,
      (previous, next) async {
        if (next == null) {
          return;
        }
        if (!persistCompleter.isCompleted) {
          await persistCompleter.future;
        }
        final tab = await ref
            .read(tabDataRepositoryProvider.notifier)
            .getTabSummaryById(next);
        if (!ref.mounted) {
          return;
        }
        final spaceUuid = tab?.spaceUuid;
        if (spaceUuid == null) {
          // Private tabs and essentials have no space: they neither move the
          // selected space nor overwrite any space's remembered tab.
          return;
        }
        // Remember this as the space's tab regardless of whether it also
        // moves the selected space — every regular-tab selection updates
        // what "coming back to this space" restores, the way it updates
        // engine history.
        unawaited(
          ref.read(spaceLastTabProvider.notifier).recordTab(spaceUuid, next),
        );
        if (spaceUuid != stateOrNull) {
          state = spaceUuid;
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

    // The reverse of the listener above: once the selected space itself
    // changes — a swipe, a rail tap, a stale uuid falling back to the first
    // space — restore what that space was last showing, so the tab list does
    // not land on the tab a *different* space happens to have selected. Only
    // reacts to an actual change (never the first build, where there is
    // nothing to restore from yet): [TabRepository.restoreSpaceTab] itself
    // checks whether the selected tab already belongs to the new space, which
    // is what keeps this from fighting the listener above — selecting a tab
    // syncs the space back to it, a no-op here since it is already the
    // current space.
    listenSelf((previous, next) {
      if (previous == null || next == null || previous == next) {
        return;
      }
      unawaited(ref.read(tabRepositoryProvider.notifier).restoreSpaceTab(next));
    });

    return stateOrNull;
  }
}

/// The selected space's row, or `null` while nothing is selected.
@Riverpod()
Stream<SpaceData?> selectedSpaceData(Ref ref) {
  final db = ref.watch(tabDatabaseProvider);
  final selected = ref.watch(selectedSpaceProvider);
  if (selected == null) {
    return Stream.value(null);
  }
  return db.spaceDao.getByUuid(selected).watchSingleOrNull();
}

/// The selected tab's space, if it has one (private tabs and essentials do
/// not).
@Riverpod()
Stream<String?> selectedTabSpaceUuid(Ref ref) {
  final selectedTab = ref.watch(selectedTabProvider);
  if (selectedTab == null) {
    return Stream.value(null);
  }
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao
      .getTabSummaryById(selectedTab)
      .watchSingleOrNull()
      .map((tab) => tab?.spaceUuid);
}

@Riverpod()
Future<int> selectedSpaceTabCount(Ref ref) {
  final selected = ref.watch(selectedSpaceProvider);
  return ref.watch(
    // ignore: provider_parameters
    spaceTabCountProvider(selected).future,
  );
}
