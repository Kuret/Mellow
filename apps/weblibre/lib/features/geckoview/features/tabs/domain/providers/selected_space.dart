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

import 'package:riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/tab.dart';
import 'package:weblibre/features/user/data/providers.dart';

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
        final spaceUuid = tab?.spaceUuid;
        if (ref.mounted && spaceUuid != null && spaceUuid != stateOrNull) {
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
