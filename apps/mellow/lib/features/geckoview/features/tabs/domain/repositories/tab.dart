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
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/features/geckoview/domain/entities/tab_container_selection.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/entities/tab_scope_change.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/space.dart';

part 'tab.g.dart';

@Riverpod(keepAlive: true)
class TabDataRepository extends _$TabDataRepository {
  /// Moves [tabId] into [targetContainer].
  ///
  /// A container's Gecko `contextId` is its id, so a container change is
  /// always a cookie-jar change: the tab is recreated in the new context
  /// (cold tabs merely get the new `container_id`; they pick the jar up when
  /// materialised). [replacementUrl] overrides the URL the recreated tab
  /// loads; left null for manual moves, which keep the tab's current page.
  Future<void> assignContainer(
    String tabId,
    ContainerData targetContainer, {
    bool closeOldTab = true,
    Uri? replacementUrl,
  }) async {
    final selectedTabId = ref.read(selectedTabProvider);
    final tabState = ref.read(tabStatesProvider)[tabId];
    final currentContainerData = await getTabContainerData(tabId);

    // Already there: recreating would spawn a redundant tab and re-trigger
    // its load when an async assignment races a move that already landed.
    if (currentContainerData?.id == targetContainer.id) {
      return;
    }

    if (tabState == null) {
      await ref
          .read(tabDatabaseProvider)
          .tabDao
          .assignContainer(tabId, containerId: targetContainer.id);
      return;
    }

    if (closeOldTab) {
      await ref.read(tabRepositoryProvider.notifier).closeTab(tabId);
    }
    await ref
        .read(tabRepositoryProvider.notifier)
        .addTab(
          url: replacementUrl ?? tabState.url,
          tabMode: tabState.tabMode,
          containerSelection: TabContainerSelection.specific(targetContainer),
          selectTab: selectedTabId == tabState.id,
          flags: LoadUrlFlags.NONE,
        );
  }

  Future<void> unassignContainer(String tabId) async {
    final selectedTabId = ref.read(selectedTabProvider);
    final tabState = ref.read(tabStatesProvider)[tabId];
    final currentContainerData = await getTabContainerData(tabId);

    if (currentContainerData == null || tabState == null) {
      return ref
          .read(tabDatabaseProvider)
          .tabDao
          .assignContainer(tabId, containerId: null);
    }

    await ref.read(tabRepositoryProvider.notifier).closeTab(tabId);
    await ref
        .read(tabRepositoryProvider.notifier)
        .addTab(
          url: tabState.url,
          tabMode: tabState.tabMode,
          containerSelection: const TabContainerSelection.unassigned(),
          selectTab: selectedTabId == tabState.id,
        );
  }

  /// Moves [tabId] onto [shelf] with Zen's semantics (PLAN §6.4):
  ///
  /// - → essential: the tab leaves its space and folder; it ranks in the
  ///   essentials strip of its own container.
  /// - essential → pinned / normal: the tab lands in [activeSpaceUuid] (the
  ///   default space when none is selected).
  /// - pinned ↔ normal: the tab keeps its space and lands at its root. A
  ///   folder member is pinned by definition (Zen keeps folders in the pinned
  ///   section), so unpinning one leaves the folder as it does in Zen.
  ///
  /// Returns `false` for unknown tabs and for private tabs asked to leave the
  /// normal shelf.
  Future<bool> setShelf(
    String tabId,
    TabShelf shelf, {
    required String? activeSpaceUuid,
  }) async {
    final dao = ref.read(tabDatabaseProvider).tabDao;
    final tab = await dao.getTabSummaryById(tabId).getSingleOrNull();
    if (tab == null) {
      return false;
    }
    if (tab.tabShelf == shelf) {
      return true;
    }

    final TabOrderScope target;
    switch (shelf) {
      case TabShelf.essential:
        target = TabOrderScope.essential(tab.containerId);
      case TabShelf.pinned:
      case TabShelf.normal:
        final spaceUuid =
            (tab.tabShelf == TabShelf.essential ? null : tab.spaceUuid) ??
            activeSpaceUuid ??
            (await ref
                    .read(spaceRepositoryProvider.notifier)
                    .ensureDefaultSpace())
                .uuid;
        target = shelf == TabShelf.pinned
            ? TabOrderScope.pinned(spaceUuid)
            : TabOrderScope.normal(spaceUuid: spaceUuid);
    }
    return dao.setShelf(tabId, shelf, target: target);
  }

  /// Puts [tabId] (with its subtree) into [folderId], or back at the root of
  /// its space when [folderId] is null. The folder's space wins. Essentials
  /// have no folder, so they are refused.
  ///
  /// Folders live in the pinned section (Zen's `folder.addTabs` pins first),
  /// so joining a folder pins the tab and it ranks in [TabOrderScope.folder];
  /// "remove from folder" keeps it pinned, in the space's flat pinned
  /// section.
  Future<bool> moveTabToFolder(String tabId, String? folderId) async {
    final db = ref.read(tabDatabaseProvider);
    final tab = await db.tabDao.getTabSummaryById(tabId).getSingleOrNull();
    if (tab == null ||
        tab.tabShelf == TabShelf.essential ||
        tab.tabMode == TabModeDbValue.private) {
      return false;
    }
    final TabOrderScope target;
    if (folderId != null) {
      final folder = await db.tabFolderDao.getById(folderId).getSingleOrNull();
      if (folder == null) {
        return false;
      }
      target = TabOrderScope.folder(
        spaceUuid: folder.spaceUuid,
        folderId: folderId,
      );
    } else {
      target = TabOrderScope(
        spaceUuid: tab.spaceUuid,
        folderId: null,
        shelf: tab.tabShelf,
        containerId: null,
      );
    }
    await db.tabDao.moveToScope([tabId], target);
    return true;
  }

  /// Moves [tabId] (with its subtree) to the root of [spaceUuid], keeping the
  /// pinned/normal shelf; a folder member leaves its folder. Essentials have
  /// no space, so they are refused.
  Future<bool> moveTabToSpace(String tabId, String spaceUuid) async {
    final dao = ref.read(tabDatabaseProvider).tabDao;
    final tab = await dao.getTabSummaryById(tabId).getSingleOrNull();
    if (tab == null ||
        tab.tabShelf == TabShelf.essential ||
        tab.tabMode == TabModeDbValue.private) {
      return false;
    }
    await dao.moveToScope(
      [tabId],
      tab.tabShelf == TabShelf.pinned
          ? TabOrderScope.pinned(spaceUuid)
          : TabOrderScope.normal(spaceUuid: spaceUuid),
    );
    return true;
  }

  Future<void> reorderTabs({
    required List<String> movingTabIds,
    required String? previousTabId,
    required String? nextTabId,
    TabScopeChange scopeChange = const TabScopeChange.unchanged(),
  }) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .reorderTabs(
          movingTabIds: movingTabIds,
          previousTabId: previousTabId,
          nextTabId: nextTabId,
          scopeChange: scopeChange,
        );
  }

  /// Moves [rootTabIds] into [target]; a split member among them brings its
  /// whole split along.
  Future<void> moveToScope(
    List<String> rootTabIds,
    TabOrderScope target, {
    String? afterId,
    String? beforeId,
  }) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .moveToScope(rootTabIds, target, afterId: afterId, beforeId: beforeId);
  }

  Future<bool> moveTabAmongSiblings(String tabId, {required bool down}) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .moveTabAmongSiblings(tabId, down: down);
  }

  /// How many private tabs are open across every container.
  ///
  /// The same set `exitApp` closes on the way out, asked ahead of time so a
  /// confirmation can say what leaving costs instead of finding out afterwards.
  Future<int> countPrivateTabs() async {
    final tabIds = await ref
        .read(tabDatabaseProvider)
        .containerDao
        .getAllTabIds(includeRegular: false)
        .get();
    return tabIds.length;
  }

  Future<int> closeAllTabs({
    bool includeRegular = true,
    bool includePrivate = true,
  }) async {
    final tabIds = await ref
        .read(tabDatabaseProvider)
        .containerDao
        .getAllTabIds(
          includeRegular: includeRegular,
          includePrivate: includePrivate,
        )
        .get();

    if (tabIds.isNotEmpty) {
      await ref.read(tabRepositoryProvider.notifier).closeTabs(tabIds);
    }

    return tabIds.length;
  }

  Future<List<String>> closeContainerTabs(
    String? containerId, {
    bool includeRegular = true,
    bool includePrivate = true,
  }) async {
    final tabIds = await ref
        .read(tabDatabaseProvider)
        .containerDao
        .getContainerTabIds(
          containerId,
          includeRegular: includeRegular,
          includePrivate: includePrivate,
        )
        .get();

    if (tabIds.isNotEmpty) {
      await ref.read(tabRepositoryProvider.notifier).closeTabs(tabIds);
    }

    return tabIds;
  }

  /// Closes every tab of [spaceUuid] (all shelves in the space, folders
  /// included) through the engine.
  Future<List<String>> closeSpaceTabs(String? spaceUuid) async {
    final tabs = await getSpaceTabsData(spaceUuid);
    final tabIds = [for (final tab in tabs) tab.id];
    if (tabIds.isNotEmpty) {
      await ref.read(tabRepositoryProvider.notifier).closeTabs(tabIds);
    }
    return tabIds;
  }

  /// Closes the tabs of [spaceUuid] whose URL host is [host].
  Future<int> closeAllTabsByHost(String? spaceUuid, String host) async {
    final tabs = await getSpaceTabsData(spaceUuid);
    final filtered = tabs
        .where((tab) => tab.url?.host == host)
        .map((tab) => tab.id)
        .toList();

    if (filtered.isNotEmpty) {
      await ref.read(tabRepositoryProvider.notifier).closeTabs(filtered);
    }

    return filtered.length;
  }

  Future<TabData?> getTabDataById(String tabId) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .getTabDataById(tabId)
        .getSingleOrNull();
  }

  Future<TabSummary?> getTabSummaryById(String tabId) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .getTabSummaryById(tabId)
        .getSingleOrNull();
  }

  Future<List<TabSummary>> getContainerTabsData(String? containerId) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .getContainerTabsData(containerId)
        .get();
  }

  /// Every tab of one space, pinned shelf first, then by `order_key`. A null
  /// [spaceUuid] yields the tabs without a space (private tabs, essentials).
  Future<List<TabSummary>> getSpaceTabsData(String? spaceUuid) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .getSpaceTabsData(spaceUuid)
        .get();
  }

  Future<String?> getTabContainerId(String tabId) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .getTabContainerId(tabId)
        .getSingleOrNull();
  }

  Future<ContainerData?> getTabContainerData(String tabId) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .getTabContainerData(tabId)
        .getSingleOrNull();
  }

  Future<Map<String, String?>> getTabsContainerId(Iterable<String> tabIds) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .getTabsContainerId(tabIds)
        .get()
        .then(Map.fromEntries);
  }

  /// The tabs of [containerId] that pass the tray's active filter. Cold tabs
  /// count: they close and move as plain rows.
  Future<List<String>> getFilteredTabIds(String? containerId) async {
    final db = ref.read(tabDatabaseProvider);
    final filterOptions = ref.read(tabViewFilterControllerProvider);
    final tabStates = ref.read(tabStatesProvider);

    final tabs = await db.containerDao.getContainerTabsData(containerId).get();
    if (tabs.isEmpty) return const [];
    if (!filterOptions.hasActiveFilter) {
      return [for (final tab in tabs) tab.id];
    }

    return tabs
        .where((tab) {
          final state = tabStates[tab.id];
          return filterOptions.matchesTab(
            state?.tabMode ?? TabMode.fromDbValue(tab.tabMode),
            tab.timestamp,
          );
        })
        .map((tab) => tab.id)
        .toList();
  }

  Future<int> deleteUnassignedTabsOlderThan(DateTime threshold) async {
    final tabIds = await ref
        .read(tabDatabaseProvider)
        .tabDao
        .getUnassignedRegularTabsOlderThan(threshold);

    if (tabIds.isNotEmpty) {
      await ref.read(tabRepositoryProvider.notifier).closeTabs(tabIds);
    }

    return tabIds.length;
  }

  @override
  void build() {}
}
