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
import 'package:fast_equatable/fast_equatable.dart';
import 'package:nullability/nullability.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/container_filter.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_local_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/search/util/tokenized_filter.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<ContainerDataWithCount>> watchContainersWithCount(Ref ref) {
  final db = ref.watch(tabDatabaseProvider);
  return db.definitionsDrift.containersWithCount().watch();
}

/// The destinations a container-cycling gesture steps through, in the order
/// the container chips render them: the unassigned pseudo-container (`null`)
/// first, then the containers themselves.
@Riverpod()
List<ContainerData?> containerCycleOrder(Ref ref) {
  final containers = ref.watch(
    watchContainersWithCountProvider.select((value) => value.value),
  );

  return [null, ...?containers];
}

@Riverpod()
AsyncValue<List<ContainerDataWithCount>> matchSortedContainersWithCount(
  Ref ref,
  String? searchText,
) {
  return ref.watch(
    watchContainersWithCountProvider.select((value) {
      if (searchText.isEmpty) {
        return value;
      }

      return value.whenData(
        (cb) => TokenizedFilter.sort(
          items: cb,
          toString: (item) => item.name,
          query: searchText!,
        ).filtered,
      );
    }),
  );
}

@Riverpod()
Stream<List<String>> watchContainerTabIds(
  Ref ref,
  ContainerFilter containerFilter,
) {
  final db = ref.watch(tabDatabaseProvider);
  switch (containerFilter) {
    case ContainerFilterById(:final containerId):
      return db.containerDao.getContainerTabIds(containerId).watch();
    case ContainerFilterDisabled():
      return db.tabDao.getAllTabIds().watch();
  }
}

@Riverpod()
Future<int> containerTabCount(Ref ref, ContainerFilter containerFilter) {
  return ref.watch(
    watchContainerTabIdsProvider(
      containerFilter,
    ).selectAsync((tabs) => tabs.length),
  );
}

// --- spaces / folders ------------------------------------------------------

/// Every space by `order_index`.
@Riverpod(keepAlive: true)
Stream<List<SpaceData>> watchSpaces(Ref ref) {
  final db = ref.watch(tabDatabaseProvider);
  return db.spaceDao.watchAll();
}

/// The folders of one space, all nesting levels, by `order_key`.
@Riverpod()
Stream<List<TabFolderData>> watchFolders(Ref ref, String? spaceUuid) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabFolderDao.watchInSpace(spaceUuid);
}

/// Every tab of one space (pinned shelf first, then `order_key`), folders
/// included. A null [spaceUuid] is the tabs without a space.
@Riverpod()
Stream<List<TabSummary>> watchSpaceTabsData(Ref ref, String? spaceUuid) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.getSpaceTabsData(spaceUuid).watch();
}

@Riverpod()
Stream<List<String>> watchSpaceTabIds(Ref ref, String? spaceUuid) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao
      .getSpaceTabsData(spaceUuid)
      .watch()
      .map((tabs) => [for (final tab in tabs) tab.id]);
}

@Riverpod()
Future<int> spaceTabCount(Ref ref, String? spaceUuid) {
  return ref.watch(
    watchSpaceTabsDataProvider(spaceUuid).selectAsync((tabs) => tabs.length),
  );
}

// --- FIFO --------------------------------------------------------------------

@Riverpod(keepAlive: true)
Stream<List<TabSummary>> watchTabsFifo(Ref ref) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.getTabsFifo().watch();
}

// --- liveness ----------------------------------------------------------------

/// Ids of the regular tabs without an engine session (PLAN §7.4). Watched by
/// the surfaces that draw rows from engine state, to tell a cold row from one
/// still restoring.
@Riverpod(keepAlive: true)
Stream<EquatableValue<Set<String>>> watchColdTabIds(Ref ref) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.coldTabIds().watch().map(
    (ids) => EquatableValue(ids.toSet()),
  );
}

// --- trees ---------------------------------------------------------------------

/// Tab trees of one space; with [allSpaces] the space boundary is ignored and
/// every tree is returned.
@Riverpod()
Stream<List<TabTreesResult>> watchTabTrees(
  Ref ref,
  String? spaceUuid, {
  bool allSpaces = false,
}) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao
      .tabTrees(allSpaces ? null : spaceUuid, skipSpaceCheck: allSpaces)
      .watch();
}

@Riverpod()
Stream<List<TabsWithRootAndDepthResult>> watchTabsWithRootAndDepth(
  Ref ref,
  String? spaceUuid,
) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.tabsWithRootAndDepth(spaceUuid).watch();
}

/// One tab's row, watched — without its page text.
///
/// A [TabSummary]: this is a `.watch()`, so it re-runs on every write to `tab`
/// for as long as the tab menu or the parent picker is open, and both consumers
/// read only `parentId` and `containerId`. The wide row would drag that tab's
/// stored content (and the `content_hash` UDF) through on every tick.
@Riverpod()
Stream<TabSummary?> watchTabDbData(Ref ref, String tabId) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.getTabSummaryById(tabId).watchSingleOrNull();
}

@Riverpod()
Stream<Map<String, String?>> watchTabDescendants(Ref ref, String tabId) {
  final db = ref.watch(tabDatabaseProvider);
  return db.definitionsDrift.unorderedTabDescendants(tabId: tabId).watch().map((
    results,
  ) {
    return Map.fromEntries(
      results.map((pair) => MapEntry(pair.id, pair.parentId)),
    );
  });
}

@Riverpod()
Stream<List<TabSummary>> watchContainerTabsData(Ref ref, String? containerId) {
  final db = ref.watch(tabDatabaseProvider);
  return db.containerDao.getContainerTabsData(containerId).watch();
}

// --- shelves -------------------------------------------------------------------

/// `tab.id → tab_shelf` for every tab.
@Riverpod(keepAlive: true)
Stream<Map<String, TabShelf>> watchTabShelves(Ref ref) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.watchShelves();
}

/// Ids of the tabs on the pinned shelf; empty until the shelves have loaded.
@Riverpod(keepAlive: true)
Set<String> pinnedTabIds(Ref ref) {
  final shelves = ref.watch(
    watchTabShelvesProvider.select((value) => value.value),
  );
  if (shelves == null) {
    return const {};
  }
  return {
    for (final entry in shelves.entries)
      if (entry.value == TabShelf.pinned) entry.key,
  };
}

/// Ids of the tabs on the essential shelf; empty until the shelves have loaded.
@Riverpod(keepAlive: true)
Set<String> essentialTabIds(Ref ref) {
  final shelves = ref.watch(
    watchTabShelvesProvider.select((value) => value.value),
  );
  if (shelves == null) {
    return const {};
  }
  return {
    for (final entry in shelves.entries)
      if (entry.value == TabShelf.essential) entry.key,
  };
}

/// The essentials strip of one container (`null` = the unassigned strip), in
/// `order_key` order.
@Riverpod()
Stream<List<String>> watchEssentialTabIds(Ref ref, String? containerId) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.essentialTabIds(containerId).watch();
}

@Riverpod()
Stream<Map<String, DateTime>> watchTabTimestamps(Ref ref) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.getTabTimestamps().watch().map(Map.fromEntries);
}

@Riverpod(keepAlive: true)
Stream<Map<String, String>> watchTabOrderKeys(Ref ref) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.getTabOrderKeys().watch().map(Map.fromEntries);
}

// --- containers ----------------------------------------------------------------

@Riverpod()
Stream<ContainerData?> watchContainerData(Ref ref, String containerId) {
  final db = ref.watch(tabDatabaseProvider);
  return db.containerDao.getContainerData(containerId).watchSingleOrNull();
}

/// The per-device settings of one container; defaults while it has no
/// `container_local` row.
@Riverpod()
Stream<ContainerLocalData> watchContainerLocal(Ref ref, String containerId) {
  final db = ref.watch(tabDatabaseProvider);
  return db.containerDao.watchLocal(containerId);
}

@Riverpod()
Stream<String?> watchContainerTabId(Ref ref, String tabId) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.getTabContainerId(tabId).watchSingleOrNull();
}

@Riverpod()
Stream<ContainerData?> watchTabContainerData(Ref ref, String? tabId) {
  if (tabId == null) {
    return const Stream.empty();
  }

  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao.getTabContainerData(tabId).watchSingleOrNull();
}

@Riverpod()
Stream<Map<String, String?>> watchTabsContainerId(
  Ref ref,
  EquatableValue<List<String>> tabIds,
) {
  final db = ref.watch(tabDatabaseProvider);
  return db.tabDao
      .getTabsContainerId(tabIds.value)
      .watch()
      .map(Map.fromEntries);
}
