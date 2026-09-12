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

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:nullability/nullability.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/entities/tab_container_selection.dart';
import 'package:weblibre/features/geckoview/domain/providers.dart';
import 'package:weblibre/features/geckoview/domain/providers/pending_tab_selection.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/controllers/home_target_controller.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/space.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/utils/debouncer.dart';

part 'tab.g.dart';

@visibleForTesting
/// The tab one step from [currentTabId] in [order], or `null` when there is no
/// step to take.
///
/// Kept as a pure function so the whole of sequential navigation's decision
/// making can be exercised without an engine: which tab is next is settled
/// here, and the repository only carries out the selection.
///
/// Returns `null` — never a fallback pick — in each case where the sequence
/// gives no answer:
///
/// - [currentTabId] is absent from [order]: it is out of this walk's reach
///   (another container, or a tab the engine has not reported yet), so nothing
///   in [order] is "adjacent" to it. Entering at an end instead is what made a
///   swipe jump across the strip in issue #603;
/// - the step falls off an end and [loop] is off;
/// - [order] holds fewer than two tabs, where even a wrap would land back on
///   the tab the user is already looking at, which is not a step.
@visibleForTesting
String? adjacentTabIdInOrder({
  required List<String> order,
  required String currentTabId,
  required bool selectPrevious,
  required bool loop,
}) {
  final index = order.indexOf(currentTabId);
  if (index < 0 || order.length < 2) {
    return null;
  }

  final targetIndex = selectPrevious ? index - 1 : index + 1;

  if (targetIndex < 0) {
    return loop ? order.last : null;
  }
  if (targetIndex >= order.length) {
    return loop ? order.first : null;
  }

  return order[targetIndex];
}

sealed class TabBackPromptBehavior {
  const TabBackPromptBehavior();
}

final class BackgroundAppTabBackPromptBehavior extends TabBackPromptBehavior {
  const BackgroundAppTabBackPromptBehavior();
}

final class ReturnToSearchTabBackPromptBehavior extends TabBackPromptBehavior {
  final TabType tabType;

  const ReturnToSearchTabBackPromptBehavior({required this.tabType});
}

@Riverpod(keepAlive: true)
class TabRepository extends _$TabRepository {
  final _tabsService = GeckoTabService();
  final _sessionStartedAt = DateTime.now();
  bool _didPruneTombstones = false;
  bool _reclosing = false;
  bool _suppressNextReclose = false;

  final _tabBackPromptBehavior = <String, TabBackPromptBehavior>{};
  final _closeLock = Lock();

  /// The site-assignment request currently being handled for each tab.
  ///
  /// Handling one means waiting for the tab's content state and then reading
  /// containers out of the database, and the engine can start another
  /// navigation in that tab in the meantime. The earlier request is obsolete
  /// once that happens: reopening its URL would pull the tab back to a page the
  /// engine has already left.

  TabBackPromptBehavior? backPromptBehaviorFor(String? tabId) {
    if (tabId == null) {
      return null;
    }

    return _tabBackPromptBehavior[tabId];
  }

  void clearBackPromptBehavior(String tabId) {
    _tabBackPromptBehavior.remove(tabId);
  }

  /// Validates the opener of a tab that is about to be created.
  ///
  /// The link is kept even when the new tab lands in a *different* container
  /// than its opener. Following a link into a container-assigned site reopens
  /// that site over there, and the opener is then the only way back once the
  /// reopened tab runs out of its own history — cutting the link stranded the
  /// user in the target container (#530).
  ///
  /// Only a parent that has no row (yet) is dropped: `tab.parent_id` carries a
  /// self-referential foreign key, so writing a dangling id would abort the
  /// insert transaction.
  Future<String?> _resolveParentId(String? parentId) async {
    if (parentId == null) {
      return null;
    }

    final parent = await ref
        .read(tabDatabaseProvider)
        .tabDao
        .getTabDataById(parentId)
        .getSingleOrNull();

    return parent != null ? parentId : null;
  }

  /// The container a new tab in [spaceUuid] gets when none is asked for: the
  /// space's default container, else the selected container.
  Future<ContainerData?> _defaultContainerFor(String? spaceUuid) async {
    if (spaceUuid != null) {
      final space = await ref
          .read(spaceRepositoryProvider.notifier)
          .getSpace(spaceUuid);
      final containerId = space?.containerId;
      if (containerId != null) {
        final container = await ref
            .read(containerRepositoryProvider.notifier)
            .getContainerData(containerId);
        if (container != null) {
          return container;
        }
      }
    }
    return ref.read(selectedContainerProvider.notifier).fetchData();
  }

  Future<bool> _excludeFromHistory(ContainerData? container) async {
    if (container == null) {
      return false;
    }
    final local = await ref
        .read(containerRepositoryProvider.notifier)
        .getLocal(container.id);
    return local.excludeFromHistory;
  }

  Future<String> addTab({
    required TabMode tabMode,
    Uri? url,
    required bool selectTab,
    bool startLoading = true,
    String? parentId,
    LoadUrlFlags flags = LoadUrlFlags.NONE,
    Source source = Internal.newTab,
    HistoryMetadataKey? historyMetadata,
    Map<String, String>? additionalHeaders,
    TabContainerSelection containerSelection =
        const TabContainerSelection.useSelected(),
    String? spaceUuid,
    bool launchedFromIntent = false,
    TabBackPromptBehavior? promptOnBackBehavior,
  }) async {
    final tabDao = ref.read(tabDatabaseProvider).tabDao;

    // Regular tabs always live in a space (I2); private tabs never do (I3).
    final String? effectiveSpaceUuid = tabMode is PrivateTabMode
        ? null
        : spaceUuid ??
              ref.read(selectedSpaceProvider) ??
              (await ref
                      .read(spaceRepositoryProvider.notifier)
                      .ensureDefaultSpace())
                  .uuid;

    // An explicit container wins, then the space's default container, then
    // the selected container.
    final assignedContainer = switch (containerSelection) {
      SpecificContainerTabSelection(:final container) => container,
      UnassignedContainerTabSelection() => null,
      UseSelectedContainerTabSelection() => await _defaultContainerFor(
        effectiveSpaceUuid,
      ),
    };

    final validatedParentId = await _resolveParentId(parentId);
    // A container's Gecko contextId is its id (DESIGN.md "D3 refinement").
    final effectiveContextId = assignedContainer?.id;
    final excludeFromHistory = await _excludeFromHistory(assignedContainer);

    final newTabId = await tabDao.upsertTabTransactional(
      () {
        return _tabsService.addTab(
          url: url,
          selectTab: selectTab,
          startLoading: startLoading,
          parentId: validatedParentId,
          flags: flags,
          contextId: effectiveContextId,
          source: source,
          private: tabMode is PrivateTabMode,
          historyMetadata: historyMetadata,
          additionalHeaders: additionalHeaders,
          // Carried into the engine so the exclusion is in place before the tab
          // loads; the replicated snapshot only follows once its row is written.
          excludeFromHistory: excludeFromHistory,
        );
      },
      parentId: Value(validatedParentId),
      containerId: Value(assignedContainer?.id),
      spaceUuid: Value(effectiveSpaceUuid),
      url: Value(url),
      tabMode: Value(tabMode),
    );

    if (launchedFromIntent) {
      _tabBackPromptBehavior[newTabId] =
          promptOnBackBehavior ?? const BackgroundAppTabBackPromptBehavior();
    } else if (promptOnBackBehavior != null) {
      _tabBackPromptBehavior[newTabId] = promptOnBackBehavior;
    }

    if (selectTab && ref.mounted) {
      _clearForceBrowserHome();

      final selectedContainerNotifier = ref.read(
        selectedContainerProvider.notifier,
      );
      if (assignedContainer != null) {
        await selectedContainerNotifier.setContainerId(assignedContainer.id);
      } else {
        selectedContainerNotifier.clearContainer();
      }
    }

    return newTabId;
  }

  Future<bool> _closeRestoredPrivateCaptureTabs(List<String> tabIds) async {
    if (tabIds.isEmpty) {
      return false;
    }

    final captureRows = await ref
        .read(tabDatabaseProvider)
        .captureTabDao
        .findAll();
    final tabStates = ref.read(tabStatesProvider);
    final restoredPrivateCaptureTabIds = captureRows
        .where((row) => row.createdAt.isBefore(_sessionStartedAt))
        .map((row) => row.tabId)
        .where((tabId) => tabIds.contains(tabId))
        .where((tabId) => tabStates[tabId]?.tabMode is PrivateTabMode)
        .toList(growable: false);

    if (restoredPrivateCaptureTabIds.isEmpty) {
      return false;
    }

    await _closeTabsInternal(
      restoredPrivateCaptureTabIds,
      recordTombstones: false,
    );
    return true;
  }

  Future<List<String>> addMultipleTabs({
    required List<AddTabParams> tabs,
    String? selectTabId,
    TabContainerSelection containerSelection =
        const TabContainerSelection.unassigned(),
  }) async {
    final tabDao = ref.read(tabDatabaseProvider).tabDao;
    final db = ref.read(tabDatabaseProvider);
    final defaultSpaceUuid =
        ref.read(selectedSpaceProvider) ??
        (await ref.read(spaceRepositoryProvider.notifier).ensureDefaultSpace())
            .uuid;
    final assignedContainer = switch (containerSelection) {
      UseSelectedContainerTabSelection() => await _defaultContainerFor(
        defaultSpaceUuid,
      ),
      UnassignedContainerTabSelection() => null,
      SpecificContainerTabSelection(:final container) => container,
    };
    final excludeFromHistory = await _excludeFromHistory(assignedContainer);

    final createdTabIds = await db.transaction(() async {
      final createdTabIds = await _tabsService.addMultipleTabs(
        tabs: tabs,
        selectTabId: selectTabId,
        // Carried into the engine so the exclusion is in place before these tabs
        // load; the replicated snapshot only follows once their rows are
        // written. One value for the batch — they all land in this container.
        excludeFromHistory: excludeFromHistory,
      );
      // Build sets for validation
      final creatingTabIds = createdTabIds.toSet();
      final parentIdsToValidate = tabs
          .map((tab) => tab.parentId)
          .whereType<String>()
          .where((id) => !creatingTabIds.contains(id))
          .toSet();

      // Batch validate parent IDs that aren't in the current creation batch
      final existingParentIds = await tabDao
          .getExistingTabIds(parentIdsToValidate)
          .get()
          .then((ids) => ids.toSet());

      // Upsert all tabs in the database
      for (var i = 0; i < createdTabIds.length; i++) {
        final tabId = createdTabIds[i];
        final tab = tabs[i];

        // Validate parent exists in either the batch being created or database
        String? validatedParentId;
        if (tab.parentId != null) {
          if (creatingTabIds.contains(tab.parentId) ||
              existingParentIds.contains(tab.parentId)) {
            validatedParentId = tab.parentId;
          }
        }

        await tabDao.insertTab(
          tabId,
          parentId: Value(validatedParentId),
          source: TabSource.manual,
          containerId: Value(assignedContainer?.id),
          spaceUuid: Value(tab.private ? null : defaultSpaceUuid),
          url: Value(Uri.tryParse(tab.url)),
          tabMode: Value(tab.private ? TabMode.private : TabMode.regular),
        );
      }

      return createdTabIds;
    });

    if (selectTabId != null && ref.mounted) {
      _clearForceBrowserHome();
    }

    return createdTabIds;
  }

  Future<String> duplicateTab({
    required String selectTabId,
    required ContainerData? containerData,
    required bool selectTab,
  }) async {
    final tabDao = ref.read(tabDatabaseProvider).tabDao;

    final sourceTabMode =
        await tabDao.getTabMode(selectTabId).getSingleOrNull() ??
        TabMode.regular;

    final duplicateTabMode = sourceTabMode;

    final effectiveContextId = containerData?.id;
    final excludeFromHistory = await _excludeFromHistory(containerData);

    // Place the duplicate as a sibling of the source — same parent — and
    // insert it right after the source's full subtree, so existing
    // children of the source are not split from their parent.
    final sourceData = await tabDao
        .getTabSummaryById(selectTabId)
        .getSingleOrNull();
    final sourceParentId = sourceData?.parentId;
    final anchorTabId =
        (sourceData == null
            ? null
            : await tabDao
                  .lastSubtreeTabIdByOrderKey(
                    selectTabId,
                    scope: TabOrderScope.forTab(sourceData),
                  )
                  .getSingleOrNull()) ??
        selectTabId;

    final newTabId = await tabDao.upsertTabTransactional(
      () {
        return _tabsService.duplicateTab(
          selectTabId: selectTabId,
          newContextId: effectiveContextId,
          selectNewTab: selectTab,
          excludeFromHistory: excludeFromHistory,
        );
      },
      parentId: Value(sourceParentId),
      afterTabId: Value(anchorTabId),
      containerId: Value(containerData?.id),
      spaceUuid: Value(sourceData?.spaceUuid),
      folderId: Value(sourceData?.folderId),
      tabMode: Value(duplicateTabMode),
    );

    if (selectTab && ref.mounted) {
      _clearForceBrowserHome();
    }

    return newTabId;
  }

  Future<bool> selectPreviouslyOpenedTab(String tabId) async {
    final previousTabId = await ref
        .read(tabDatabaseProvider)
        .definitionsDrift
        .previousTabByTimestamp(tabId: tabId)
        .getSingleOrNull();

    if (ref.mounted && previousTabId != null) {
      return selectTab(previousTabId);
    }

    return false;
  }

  Future<bool> resumeLatestTab({Set<String> excludedTabIds = const {}}) async {
    final latestTab = await ref
        .read(tabDatabaseProvider)
        .tabDao
        .getTabsFifo(limit: 1, excludedTabIds: excludedTabIds)
        .getSingleOrNull();

    if (!ref.mounted || latestTab == null) {
      return false;
    }

    return selectTab(latestTab.id);
  }

  Future<bool> resumeLatestSpaceTab(
    String? spaceUuid, {
    Set<String> excludedTabIds = const {},
  }) async {
    final latestTab = await ref
        .read(tabDatabaseProvider)
        .tabDao
        .getSpaceTabsFifo(
          spaceUuid,
          limit: 1,
          excludedTabIds: excludedTabIds,
        )
        .getSingleOrNull();

    if (!ref.mounted || latestTab == null) {
      return false;
    }

    return selectTab(latestTab.id);
  }

  Future<bool> selectPreviousTab(String tabId, {bool skipScopeCheck = true}) =>
      _selectAdjacentTab(
        tabId,
        skipScopeCheck: skipScopeCheck,
        selectPrevious: true,
      );

  Future<bool> selectNextTab(String tabId, {bool skipScopeCheck = true}) =>
      _selectAdjacentTab(
        tabId,
        skipScopeCheck: skipScopeCheck,
        selectPrevious: false,
      );

  /// Moves the selection one step through the tab sequence.
  ///
  /// Calls that cross ordering scopes ([skipScopeCheck]) — the tab bar swipe
  /// and the next/previous tab gestures — step through the *rendered* order
  /// ([sequentialTabNavigationOrderProvider]) so navigation matches the tabs
  /// the user sees: the same grouping and pinned-first handling the quick tab
  /// switcher and the tab bar draw, and deliberately none of the tray's own
  /// filters, collapsed groups or sort (see [TabListScope]). It is
  /// authoritative once it exists, and every outcome stays inside it:
  ///
  /// - current tab in the order: step one row, stopping at either end — or
  ///   continuing at the opposite end when `sequentialTabNavigationLoop` is on;
  /// - current tab outside it, or nothing visible at all: do nothing (#603).
  ///
  /// The storage-order walk below serves scope-bound stepping and the window
  /// before the tree data has loaded, where there is no rendered sequence.
  Future<bool> _selectAdjacentTab(
    String tabId, {
    required bool skipScopeCheck,
    required bool selectPrevious,
  }) async {
    if (skipScopeCheck) {
      final visibleOrder = ref.read(sequentialTabNavigationOrderProvider).value;
      if (visibleOrder != null) {
        final targetTabId = adjacentTabIdInOrder(
          order: visibleOrder,
          currentTabId: tabId,
          selectPrevious: selectPrevious,
          loop: ref
              .read(generalSettingsWithDefaultsProvider)
              .sequentialTabNavigationLoop,
        );
        // The rendered order is authoritative once it exists: having no step to
        // take within it is an answer, not a reason to consult storage order.
        return targetTabId != null && await selectTab(targetTabId);
      }
    }

    final adjacentTabId = await _adjacentVisibleTabByOrder(
      tabId,
      skipScopeCheck: skipScopeCheck,
      selectPrevious: selectPrevious,
    );

    if (ref.mounted && adjacentTabId != null) {
      return selectTab(adjacentTabId);
    }

    return false;
  }

  Future<bool> selectTab(String tabId) async {
    // The tab is still a pre-restore placeholder (known to the DB but not to
    // the engine yet): queue the selection until the native state arrives.
    if (!ref.read(browserRestoreCompleteProvider) &&
        !ref.read(tabStatesProvider).containsKey(tabId)) {
      ref.read(pendingTabSelectionProvider.notifier).queue(tabId);
      _clearForceBrowserHome();
      return true;
    }

    _clearForceBrowserHome();
    await _tabsService.selectTab(tabId: tabId);
    return true;
  }

  /// Cancels a pending "stay on home", because something is about to be shown.
  ///
  /// Done explicitly at each selection rather than by listening to the selected
  /// tab: the engine selects tabs on its own (restore, session recovery) and
  /// such a listener would immediately undo the flag the home target had just
  /// set. Call it only once the selection is certain — a proxy healthcheck can
  /// still refuse it, and discarding the flag then would drop the user off home
  /// without putting anything in its place.
  void _clearForceBrowserHome() {
    ref.read(forceBrowserHomeProvider.notifier).clear();
  }

  /// Selects [tabId] on behalf of the engine's own follow-up logic, i.e. not
  /// because the user asked for this particular tab.
  ///
  /// Still counts as leaving home: a neighbour is now on screen, so a
  /// "stay on home" left over from an earlier close no longer describes
  /// anything. Safe against the home target's own flag, because the branch of
  /// [_selectNextTab] that sets it is reached only when nothing was selected
  /// here.
  Future<void> _selectTabAfterClose(String tabId) async {
    _clearForceBrowserHome();
    await _tabsService.selectTab(tabId: tabId);
  }

  Future<String?> _adjacentVisibleTabByOrder(
    String tabId, {
    required bool skipScopeCheck,
    required bool selectPrevious,
  }) async {
    // Storage-order walk: neighbours by `order_key` only, so it sees neither
    // the tray's sort and filters nor its grouping. User-facing sequential
    // navigation goes through the rendered order in [_selectAdjacentTab] and
    // reaches this only as a fallback; what remains here is picking a tab
    // after a close and scope-bound stepping.
    //
    // "Previous/next" is interpreted relative to the *tab bar* direction,
    // which is the only direction this path has to go by.
    final newestFirst =
        ref.read(generalSettingsWithDefaultsProvider).tabBarDirection ==
        TabDirection.newestFirst;
    final tabDao = ref.read(tabDatabaseProvider).tabDao;
    final summary = await tabDao.getTabSummaryById(tabId).getSingleOrNull();
    if (summary == null) {
      return null;
    }
    final scope = TabOrderScope.forTab(summary);

    if (newestFirst == selectPrevious) {
      return tabDao
          .nextTabByOrderKey(
            tabId,
            scope: scope,
            skipScopeCheck: skipScopeCheck,
          )
          .getSingleOrNull();
    }

    return tabDao
        .previousTabByOrderKey(
          tabId,
          scope: scope,
          skipScopeCheck: skipScopeCheck,
        )
        .getSingleOrNull();
  }

  Future<String?> _nearestAvailableVisibleTabByOrder(
    String tabId, {
    required Set<String> excludedTabIds,
  }) async {
    Future<String?> walkDirection({required bool selectPrevious}) async {
      var candidate = await _adjacentVisibleTabByOrder(
        tabId,
        skipScopeCheck: false,
        selectPrevious: selectPrevious,
      );
      while (candidate != null) {
        if (!excludedTabIds.contains(candidate)) {
          return candidate;
        }
        candidate = await _adjacentVisibleTabByOrder(
          candidate,
          skipScopeCheck: false,
          selectPrevious: selectPrevious,
        );
      }
      return null;
    }

    return await walkDirection(selectPrevious: true) ??
        await walkDirection(selectPrevious: false);
  }

  /// Nearest still-open ancestor of [tabId], or `null` when the chain runs out.
  ///
  /// The stored chain is the authority: `tab_maintain_parent_chain_on_delete`
  /// repoints a child at its grandparent as soon as the parent row goes away,
  /// whereas the engine's `parentId` only reaches Dart with that tab's *next*
  /// content-state event and can still name a tab that is already closed. The
  /// engine value is therefore only consulted while the row itself is missing,
  /// i.e. before the insert for a freshly opened tab has landed.
  ///
  /// An ancestor in another container is a valid target: selecting it moves the
  /// tray along with it (see `SelectedContainer`), which is the way back out of
  /// a container a link pulled the user into (#530).
  Future<String?> _nearestAvailableAncestor(
    String tabId, {
    required Set<String> excludedTabIds,
  }) async {
    final tabDao = ref.read(tabDatabaseProvider).tabDao;
    final row = await tabDao.getTabDataById(tabId).getSingleOrNull();

    if (!ref.mounted) return null;

    var candidate = row != null
        ? row.parentId
        : ref.read(tabStatesProvider)[tabId]?.parentId;

    final liveTabIds = ref.read(tabListProvider).value.toSet();
    final visited = <String>{tabId};

    while (candidate != null && visited.add(candidate)) {
      if (!excludedTabIds.contains(candidate) &&
          liveTabIds.contains(candidate)) {
        return candidate;
      }

      // Closing an ancestor together with this tab (or an engine tab that never
      // materialised) is not the end of the chain — keep climbing.
      final ancestor = await tabDao.getTabDataById(candidate).getSingleOrNull();

      if (!ref.mounted) return null;

      candidate = ancestor?.parentId;
    }

    return null;
  }

  Future<void> _selectNextTab(
    String tabId, {
    Set<String> excludedTabIds = const {},
  }) async {
    final tabState = ref.read(tabStatesProvider)[tabId];
    final db = ref.read(tabDatabaseProvider);
    final summary = await db.tabDao.getTabSummaryById(tabId).getSingleOrNull();
    if (!ref.mounted) return;

    // Private tabs and essentials have no space: their "same scope" is the
    // other tabs without one.
    final currentSpaceUuid = summary?.spaceUuid;

    Future<List<String>> spaceTabIds(String? spaceUuid) async {
      final tabs = await db.tabDao.getSpaceTabsData(spaceUuid).get();
      return [
        for (final tab in tabs)
          if (tab.id != tabId && !excludedTabIds.contains(tab.id)) tab.id,
      ];
    }

    final sameSpaceTabs = await spaceTabIds(currentSpaceUuid);
    if (!ref.mounted) return;

    // Priority 1: hand the user back to whoever opened this tab, across
    // spaces if that is where the opener lives.
    final ancestorTabId = await _nearestAvailableAncestor(
      tabId,
      excludedTabIds: excludedTabIds,
    );
    if (!ref.mounted) return;
    if (ancestorTabId != null) {
      return _selectTabAfterClose(ancestorTabId);
    }

    // Priority 2: Check for previous tab by timestamp
    final previousTabId = await db.definitionsDrift
        .previousTabByTimestamp(tabId: tabId)
        .getSingleOrNull();

    if (previousTabId != null) {
      if (sameSpaceTabs.any((tab) => tab == previousTabId)) {
        return _selectTabAfterClose(previousTabId);
      }
    }

    if (!ref.mounted) return;

    final orderedNeighborTabId = await _nearestAvailableVisibleTabByOrder(
      tabId,
      excludedTabIds: excludedTabIds,
    );

    if (orderedNeighborTabId != null) {
      return _selectTabAfterClose(orderedNeighborTabId);
    }

    if (!ref.mounted) return;

    // Out of candidates in this space. By default the search widens to the
    // other spaces, which drags the user out of the space they were working
    // in; the home target keeps them here.
    if (ref
        .read(generalSettingsWithDefaultsProvider)
        .homeTargetOnLastTabClosed) {
      await ref
          .read(homeTargetControllerProvider.notifier)
          .applyTarget(
            scopeToSpace: true,
            spaceUuid: currentSpaceUuid ?? ref.read(selectedSpaceProvider),
            closingTabUrl: tabState?.url,
            // Tab rows outlive this call — they are deleted only after the next
            // selection is made — so without this the resume would pick the
            // very tab being closed, which sorts first as the active one.
            excludedTabIds: {...excludedTabIds, tabId},
          );
      return;
    }

    if (sameSpaceTabs.isNotEmpty) {
      return _selectTabAfterClose(sameSpaceTabs.first);
    }

    final spaces = await db.spaceDao.getAll();
    if (!ref.mounted) return;
    for (final space in spaces) {
      if (space.uuid == currentSpaceUuid) {
        continue;
      }
      final candidates = await spaceTabIds(space.uuid);
      if (!ref.mounted) return;
      if (candidates.isNotEmpty) {
        return _selectTabAfterClose(candidates.first);
      }
    }
  }

  Future<void> _closeTabsInternal(
    List<String> tabIds, {
    required bool recordTombstones,
  }) {
    return _closeLock.synchronized(() async {
      if (tabIds.isEmpty) {
        return;
      }

      final db = ref.read(tabDatabaseProvider);
      if (recordTombstones) {
        await db.tabDao.addClosedTabTombstones(tabIds);
      }

      for (final tabId in tabIds) {
        _tabBackPromptBehavior.remove(tabId);
      }

      final selectedTab = ref.read(selectedTabProvider);
      if (selectedTab.mapNotNull(tabIds.contains) ?? false) {
        await _selectNextTab(selectedTab!, excludedTabIds: tabIds.toSet());
      }

      await _preservePromotedChildOrderOnClose(tabIds);

      // Cold rows have no session behind them: closing one is a plain row
      // delete (PLAN §7.4 item 2). Everything else goes through the engine,
      // whose tab-list event drops the row.
      final coldIds = (await db.tabDao.coldTabIds().get()).toSet();
      final coldToClose = [
        for (final tabId in tabIds)
          if (coldIds.contains(tabId)) tabId,
      ];
      final liveToClose = [
        for (final tabId in tabIds)
          if (!coldIds.contains(tabId)) tabId,
      ];
      if (coldToClose.isNotEmpty) {
        await (db.tab.delete()..where((t) => t.id.isIn(coldToClose))).go();
      }
      if (liveToClose.length == 1) {
        await _tabsService.removeTab(tabId: liveToClose.single);
      } else if (liveToClose.isNotEmpty) {
        await _tabsService.removeTabs(ids: liveToClose);
      }
    });
  }

  Future<void> closeTab(String tabId) {
    return _closeTabsInternal([tabId], recordTombstones: true);
  }

  Future<void> closeTabs(List<String> tabIds) {
    return _closeTabsInternal(tabIds, recordTombstones: true);
  }

  Future<void> _clearTombstonesForCurrentTabs(List<String> tabIds) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .deleteClosedTabTombstones(tabIds);
  }

  Future<void> _preservePromotedChildOrderOnClose(List<String> tabIds) {
    return ref
        .read(tabDatabaseProvider)
        .tabDao
        .preservePromotedChildOrderOnClose(tabIds);
  }

  Future<void> undoClose() {
    // Suppress the next reclose pass: undo can resurrect a tab whose
    // tombstone is still on disk (from a previous session); without this
    // flag the listener would immediately re-close it.
    _suppressNextReclose = true;
    return _tabsService.undo();
  }

  Future<bool> _recloseRestoredClosedTabs(List<String> tabIds) async {
    if (_reclosing) {
      return false;
    }
    _reclosing = true;
    try {
      final tabDao = ref.read(tabDatabaseProvider).tabDao;

      if (!_didPruneTombstones) {
        await tabDao.pruneExpiredClosedTabTombstones();
        _didPruneTombstones = true;
      }

      final restoredClosedTabIds = await tabDao.getStartupRestoredClosedTabIds(
        tabIds,
        sessionStartedAt: _sessionStartedAt,
      );

      if (restoredClosedTabIds.isEmpty) {
        return false;
      }

      // recordTombstones: false — the tombstone already exists from the
      // original close; rewriting it would bump closed_at into this session
      // and disable the resurrection check on the next emission.
      await _closeTabsInternal(
        restoredClosedTabIds.toList(growable: false),
        recordTombstones: false,
      );

      return true;
    } finally {
      _reclosing = false;
    }
  }

  /// Gives a cold tab (PLAN §7.4) an engine session again. Filled in by W4.
  Future<void> materializeTab(String tabId) {
    throw UnimplementedError('W4');
  }

  /// Drops a live tab's engine session while keeping its row (no tombstone,
  /// nothing projected). Filled in by W4.
  Future<void> demoteToCold(String tabId) {
    throw UnimplementedError('W4');
  }

  @override
  void build() {
    // Hold an active listener on the rendered navigation order: swipes and
    // gestures read it synchronously, and Riverpod pauses a provider nothing is
    // listening to — a one-off read would neither keep it current nor guarantee
    // it has data when the first swipe arrives. Listened rather than watched
    // because it changes with every tab update, which must not rebuild this
    // repository; the callback is intentionally empty.
    ref.listen(
      sequentialTabNavigationOrderProvider,
      (_, _) {},
      fireImmediately: true,
    );

    final eventSerivce = ref.watch(eventServiceProvider);
    final tabContentService = ref.watch(tabContentServiceProvider);

    final db = ref.watch(tabDatabaseProvider);

    final tabAddedSub = eventSerivce.tabAddedStream.listen(
      (tabId) async {
        final containerId = ref.read(selectedContainerProvider);
        final spaceUuid = ref.read(selectedSpaceProvider);
        await db.tabDao.insertTab(
          tabId,
          parentId: const Value.absent(),
          source: TabSource.addedEvent,
          containerId: Value(containerId),
          spaceUuid: Value(spaceUuid),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        logger.e(
          'Error in tab added stream',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    final tabContentSub = tabContentService.tabContentStream.listen(
      (content) async {
        await db.tabDao.updateTabContent(
          content.tabId,
          isProbablyReaderable: content.isProbablyReaderable,
          extractedContentMarkdown: content.extractedContentMarkdown,
          extractedContentPlain: content.extractedContentPlain,
          fullContentMarkdown: content.fullContentMarkdown,
          fullContentPlain: content.fullContentPlain,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        logger.e(
          'Error in tab content stream',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    ref.listen(
      fireImmediately: true,
      selectedTabProvider,
      (previous, tabId) async {
        if (tabId != null) {
          await db.tabDao.touchTab(tabId, timestamp: DateTime.now());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        logger.e(
          'Error listening to selectedTabProvider',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    ref.listen(
      tabListProvider,
      (previous, next) async {
        if (_suppressNextReclose) {
          _suppressNextReclose = false;
          // Drop tombstones for the tabs that just came back via undo so
          // future emissions don't treat them as resurrections.
          await _clearTombstonesForCurrentTabs(next.value);
        } else if (await _recloseRestoredClosedTabs(next.value)) {
          return;
        } else if (await _closeRestoredPrivateCaptureTabs(next.value)) {
          return;
        }

        //Only sync tabs if there has been a previous value or is not empty.
        //Additionally require the native session restore to have completed:
        //a partial pre-restore list (e.g. a share-intent tab arriving first)
        //must not delete the cached rows of tabs that are still being
        //restored.
        final shouldSyncTabs =
            ref.read(browserRestoreCompleteProvider) &&
            (next.value.isNotEmpty || (previous?.value.isNotEmpty ?? false));

        if (shouldSyncTabs) {
          await db.tabDao.syncTabs(
            engineTabIds: next.value,
            defaultSpaceUuid: ref.read(selectedSpaceProvider),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        logger.e(
          'Error listening to tabListProvider',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    // Catch up on the tab list emissions skipped while the restore-complete
    // gate above was closed: reconcile the DB once against the current list.
    ref.listen(browserRestoreCompleteProvider, (
      previous,
      restoreComplete,
    ) async {
      if (restoreComplete && !(previous ?? false)) {
        final currentTabs = ref.read(tabListProvider).value;
        if (currentTabs.isNotEmpty) {
          await db.tabDao.syncTabs(
            engineTabIds: currentTabs,
            defaultSpaceUuid: ref.read(selectedSpaceProvider),
          );
        }
      }
    });

    final tabStateDebouncer = Debouncer(const Duration(seconds: 1));
    Map<String, TabState>? debounceStartValue;

    ref.listen(
      tabStatesProvider,
      (previous, next) {
        //Since state changes occure pretty often and our map always contains
        //the latest state, we cache the value before starting debouncing and
        //later diff to that, to avoid frequent database writes
        if (!tabStateDebouncer.isDebouncing) {
          debounceStartValue = previous;
        }

        tabStateDebouncer.eventOccured(() async {
          await db.tabDao.updateTabs(debounceStartValue, next);
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        logger.e(
          'Error listening to tabStatesProvider',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    ref.onDispose(() async {
      tabStateDebouncer.dispose();
      await tabAddedSub.cancel();
      await tabContentSub.cancel();
    });
  }
}
