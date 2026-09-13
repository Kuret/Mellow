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
import 'package:collection/collection.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:nullability/nullability.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/core/sort_field.dart';
import 'package:weblibre/features/bangs/data/models/bang_data.dart';
import 'package:weblibre/features/bangs/data/models/bang_key.dart';
import 'package:weblibre/features/bangs/domain/repositories/data.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_list_scope.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_presence.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/search/domain/entities/tab_preview.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/container_filter.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_entity.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/gecko_inference.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/tab_search.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

part 'providers.g.dart';

typedef TabStateWithContainer = (TabState, ContainerData?);

@Riverpod()
bool canManualTabReorder(Ref ref) {
  final filterOptions = ref.watch(tabViewFilterControllerProvider);

  final hasActiveSearch = ref.watch(
    tabSearchRepositoryProvider(
      TabSearchPartition.preview,
    ).select((value) => (value.value?.query ?? '').isNotEmpty),
  );

  return !filterOptions.hasActiveFilter && !hasActiveSearch;
}

@Riverpod(keepAlive: true)
class SelectedBangTrigger extends _$SelectedBangTrigger {
  // ignore: document_ignores api decision
  // ignore: use_setters_to_change_properties
  void setTrigger(BangKey trigger) {
    state = trigger;
  }

  void clearTrigger() {
    state = null;
  }

  @override
  BangKey? build({String? domain}) {
    return null;
  }
}

@Riverpod()
class SelectedBangData extends _$SelectedBangData {
  @override
  BangData? build({String? domain}) {
    final repository = ref.watch(bangDataRepositoryProvider.notifier);
    final selectedBangTrigger = ref.watch(
      selectedBangTriggerProvider(domain: domain),
    );

    final subscription = repository.watchBang(selectedBangTrigger).listen((
      value,
    ) {
      if (ref.mounted) {
        state = value;
      }
    });

    ref.onDispose(() async {
      await subscription.cancel();
    });

    return null;
  }
}

@Riverpod()
EquatableValue<List<DefaultTabEntity>> containerTabEntities(
  Ref ref,
  ContainerFilter containerFilter,
) {
  final containerTabs = ref.watch(
    watchContainerTabIdsProvider(
      containerFilter,
    ).select((value) => value.value),
  );
  final tabList = ref.watch(tabListProvider);
  final orderKeys = ref.watch(
    watchTabOrderKeysProvider.select((value) => value.value),
  );

  final availableTabs =
      containerTabs?.where((tabId) => tabList.value.contains(tabId)).toList() ??
      [];

  switch (containerFilter) {
    case ContainerFilterById():
      return EquatableValue(
        availableTabs
            .map(
              (t) => DefaultTabEntity(
                tabId: t,
                orderKey: orderKeys?[t] ?? '',
                containerId: containerFilter.containerId,
              ),
            )
            .toList(),
      );
    case ContainerFilterDisabled():
      return ref.watch(
        watchTabsContainerIdProvider(EquatableValue(availableTabs)).select(
          (value) => EquatableValue(
            value.value?.entries
                    .map(
                      (e) => DefaultTabEntity(
                        tabId: e.key,
                        orderKey: orderKeys?[e.key] ?? '',
                        containerId: e.value,
                      ),
                    )
                    .toList() ??
                [],
          ),
        ),
      );
  }
}

@Riverpod()
EquatableValue<Map<String, TabState>> containerTabStates(
  Ref ref,
  ContainerFilter containerFilter,
) {
  final availableTabs = ref.watch(
    containerTabEntitiesProvider(containerFilter),
  );
  final tabStates = ref.watch(tabStatesProvider);

  return EquatableValue({
    for (final tabEntity in availableTabs.value)
      if (tabStates.containsKey(tabEntity.tabId))
        tabEntity.tabId: tabStates[tabEntity.tabId]!,
  });
}

/// Synthesizes a placeholder [TabState] from a cached DB row for tabs without
/// engine state: cold tabs (PLAN §7.4) and, before the session restore has
/// completed, tabs whose native state has not arrived yet. `TabIcon` falls
/// back to the URL-cached favicon when [TabState.icon] is null, so placeholder
/// chips still render with proper icons and titles.
TabState _placeholderTabState(TabSummary tab) {
  return TabState.$default(tab.id).copyWith(
    url: tab.url ?? TabState.defaultUrl,
    title: tab.staticLabel ?? tab.title ?? '',
    parentId: tab.parentId,
    tabMode: TabMode.fromDbValue(tab.tabMode),
  );
}

/// Whether [tab] may be shown as a placeholder. Private tabs are never
/// session-restored and never cold, so their rows must not produce dangling
/// chips.
bool _canShowAsPlaceholder(TabSummary tab) =>
    tab.tabMode != TabModeDbValue.private;

/// Whether [tab] renders from its row rather than from engine state: cold, or
/// still restoring.
bool _showsAsPlaceholder(TabSummary tab, {required bool restoreComplete}) =>
    _canShowAsPlaceholder(tab) && (tab.isCold || !restoreComplete);

/// Whether a tab row has an engine session behind it — see [TabPresence].
///
/// Live as soon as the engine reports state; cold when the row says so
/// (`engine_tab_id IS NULL`); restoring in between.
@Riverpod()
TabPresence tabPresence(Ref ref, String tabId) {
  final hasState = ref.watch(
    tabStatesProvider.select((states) => states.containsKey(tabId)),
  );
  if (hasState) {
    return TabPresence.live;
  }
  final isCold = ref.watch(
    watchTabDbDataProvider(tabId).select((value) => value.value?.isCold),
  );
  if (isCold ?? false) {
    return TabPresence.cold;
  }
  return TabPresence.restoring;
}

/// Ids of DB-cached live tabs whose native state hasn't arrived yet. Empty
/// once the session restore completed (afterwards a live row without native
/// state is on its way to being demoted, not pending). Cold rows are not
/// pending either: they render as placeholders for good — see
/// [tabPresenceProvider].
@Riverpod()
EquatableValue<Set<String>> pendingRestoreTabIds(Ref ref) {
  final restoreComplete = ref.watch(browserRestoreCompleteProvider);
  if (restoreComplete) {
    return EquatableValue(const {});
  }

  final nativeTabIds = ref.watch(
    tabStatesProvider.select((states) => EquatableValue(states.keys.toSet())),
  );
  final dbTabs =
      ref.watch(watchTabsFifoProvider.select((value) => value.value)) ??
      const <TabSummary>[];

  return EquatableValue({
    for (final tab in dbTabs)
      if (_canShowAsPlaceholder(tab) &&
          !tab.isCold &&
          !nativeTabIds.value.contains(tab.id))
        tab.id,
  });
}

@Riverpod(keepAlive: true)
EquatableValue<List<TabStateWithContainer>> fifoTabStates(Ref ref) {
  final containerData = ref
      .watch(watchContainersWithCountProvider.select((value) => value.value))
      .mapNotNull(
        (value) => Map.fromEntries(value.map((c) => MapEntry(c.id, c))),
      );

  final sortedTabs = ref.watch(
    watchTabsFifoProvider.select((value) => value.value),
  );
  final tabStates = ref.watch(tabStatesProvider);
  final restoreComplete = ref.watch(browserRestoreCompleteProvider);

  TabState? stateFor(TabSummary tab) =>
      tabStates[tab.id] ??
      (_showsAsPlaceholder(tab, restoreComplete: restoreComplete)
          ? _placeholderTabState(tab)
          : null);

  return EquatableValue([
    if (sortedTabs != null)
      for (final tab in sortedTabs)
        if (stateFor(tab) case final state?)
          (
            state,
            tab.containerId.mapNotNull(
              (containerId) => containerData?[containerId],
            ),
          ),
  ]);
}

/// The selected space's tabs (pinned and normal shelves) with their
/// containers, in the order the quick tab switcher and the tab bar draw them.
/// Cold and restoring rows render as placeholders.
@Riverpod()
EquatableValue<List<TabStateWithContainer>> selectedSpaceTabStatesWithContainer(
  Ref ref,
) => ref.watch(
  spaceTabStatesWithContainerProvider(ref.watch(selectedSpaceProvider)),
);

/// [selectedSpaceTabStatesWithContainerProvider] for any one space. The bar
/// and the rail slide between spaces, and the outgoing space keeps rendering
/// its own tabs while it leaves.
@Riverpod()
EquatableValue<List<TabStateWithContainer>> spaceTabStatesWithContainer(
  Ref ref,
  String? spaceUuid,
) {
  final containerData = ref
      .watch(watchContainersWithCountProvider.select((value) => value.value))
      .mapNotNull(
        (value) => Map.fromEntries(value.map((c) => MapEntry(c.id, c))),
      );

  final tabStates = ref.watch(tabStatesProvider);
  final restoreComplete = ref.watch(browserRestoreCompleteProvider);

  final spaceTabs =
      ref.watch(
        watchSpaceTabsDataProvider(spaceUuid).select((value) => value.value),
      ) ??
      const <TabSummary>[];

  TabState? stateFor(TabSummary tab) =>
      tabStates[tab.id] ??
      (_showsAsPlaceholder(tab, restoreComplete: restoreComplete)
          ? _placeholderTabState(tab)
          : null);

  // The single order every non-tray surface shares. It already carries the tab
  // bar direction, hierarchy grouping and pinned-first handling, so none of
  // that is redone here — and because the presentation scope drops no rows,
  // every tab this switcher renders has an index in it.
  final orderedItems = ref
      .watch(
        visibleTabListItemsProvider(
          spaceUuid: spaceUuid,
          scope: TabListScope.presentation,
        ),
      )
      .value;
  final groupedOrder = <String, int>{};
  for (var i = 0; i < orderedItems.length; i++) {
    if (orderedItems[i] case TabListTabItem(:final tabId)) {
      groupedOrder[tabId] = i;
    }
  }

  final orderKeyById = {for (final tab in spaceTabs) tab.id: tab.orderKey};

  var items = [
    for (final tab in spaceTabs)
      if (tab.tabShelf != TabShelf.essential)
        if (stateFor(tab) case final state?)
          (
            state,
            tab.containerId.mapNotNull(
              (containerId) => containerData?[containerId],
            ),
          ),
  ];

  items.sort((a, b) {
    final aIndex = groupedOrder[a.$1.id];
    final bIndex = groupedOrder[b.$1.id];
    if (aIndex != null && bIndex != null) {
      return aIndex.compareTo(bIndex);
    }
    if (aIndex != null) return -1;
    if (bIndex != null) return 1;
    return (orderKeyById[a.$1.id] ?? '').compareTo(orderKeyById[b.$1.id] ?? '');
  });

  // Flat pinned-first, for the pre-restore window only: until the engine
  // reports its tab list the shared order is empty, so every chip here is a
  // placeholder ordered by `order_key` alone and would otherwise show pinned
  // tabs out of place until restore completes. Once the shared order exists it
  // has already partitioned them, and re-partitioning a partitioned list is a
  // no-op — so this can never pull the switcher away from it.
  final pinnedTabIds = ref.watch(pinnedTabIdsProvider);
  final sortPinnedFirst = ref.watch(
    tabViewFilterControllerProvider.select((v) => v.sortPinnedFirst),
  );
  if (sortPinnedFirst && pinnedTabIds.isNotEmpty) {
    final pinned = items.where((i) => pinnedTabIds.contains(i.$1.id)).toList();
    final unpinned = items
        .where((i) => !pinnedTabIds.contains(i.$1.id))
        .toList();
    items = [...pinned, ...unpinned];
  }

  return EquatableValue(items);
}

@Riverpod()
EquatableValue<List<TabEntity>> suggestedTabEntities(
  Ref ref,
  String? containerId,
) {
  final enableAiFeatures = ref.watch(
    generalSettingsWithDefaultsProvider.select(
      (settings) => settings.enableLocalAiFeatures,
    ),
  );

  if (!enableAiFeatures) {
    return EquatableValue([]);
  }

  final excludedTabIds = ref.watch(
    watchContainerTabIdsProvider(
      // ignore: provider_parameters
      ContainerFilterById(containerId: containerId),
    ).select((value) => EquatableValue(value.value)),
  );

  final orderKeys = ref.watch(
    watchTabOrderKeysProvider.select((value) => value.value),
  );

  final suggestions = ref.watch(
    containerTabSuggestionsProvider(containerId).select(
      (value) => EquatableValue(
        value.value.mapNotNull(
              (result) => result
                  .whereNot(
                    (tabId) => excludedTabIds.value?.contains(tabId) ?? false,
                  )
                  .map(
                    (tabId) => DefaultTabEntity(
                      tabId: tabId,
                      orderKey: orderKeys?[tabId] ?? '',
                      containerId: containerId,
                    ),
                  )
                  .toList(),
            ) ??
            const [],
      ),
    ),
  );

  return suggestions;
}

List<TabEntity> _applyTabFiltersAndSort(
  List<TabEntity> entities,
  TabViewFilterOptions filterOptions,
  Map<String, TabState> tabStates,
  Set<String> pinnedTabIds,
  Map<String, DateTime>? tabTimestamps,
) {
  final sortField = filterOptions.sortType.sortField;
  final filteredRows = <_TabFilterRow>[];
  var hasPinned = false;

  for (final entity in entities) {
    final tabState = tabStates[entity.tabId];
    final timestamp = tabTimestamps?[entity.tabId];

    if (!filterOptions.matchesTab(tabState?.tabMode, timestamp)) {
      continue;
    }

    final isPinned = pinnedTabIds.contains(entity.tabId);
    hasPinned = hasPinned || isPinned;

    filteredRows.add(
      _TabFilterRow(
        entity: entity,
        isPinned: isPinned,
        titleKey:
            sortField == SortField.titleAsc || sortField == SortField.titleDesc
            ? (tabState?.titleOrAuthority ?? '').toLowerCase()
            : null,
        urlKey: sortField == SortField.urlAsc || sortField == SortField.urlDesc
            ? (tabState?.url.toString() ?? '')
            : null,
        dateKey:
            sortField == SortField.dateAsc || sortField == SortField.dateDesc
            ? (timestamp ?? DateTime(0))
            : null,
      ),
    );
  }

  if (sortField != null) {
    filteredRows.sort((a, b) {
      if (filterOptions.sortPinnedFirst && a.isPinned != b.isPinned) {
        return b.isPinned ? 1 : -1;
      }

      final cmp = switch (sortField) {
        SortField.titleAsc => a.titleKey!.compareTo(b.titleKey!),
        SortField.titleDesc => b.titleKey!.compareTo(a.titleKey!),
        SortField.urlAsc => a.urlKey!.compareTo(b.urlKey!),
        SortField.urlDesc => b.urlKey!.compareTo(a.urlKey!),
        SortField.dateAsc => a.dateKey!.compareTo(b.dateKey!),
        SortField.dateDesc => b.dateKey!.compareTo(a.dateKey!),
      };

      if (cmp == 0) return a.entity.orderKey.compareTo(b.entity.orderKey);

      return cmp;
    });

    return filteredRows.map((row) => row.entity).toList();
  }

  if (!hasPinned || !filterOptions.sortPinnedFirst) {
    return filteredRows.map((row) => row.entity).toList();
  }

  final pinned = <TabEntity>[];
  final unpinned = <TabEntity>[];
  for (final row in filteredRows) {
    if (row.isPinned) {
      pinned.add(row.entity);
    } else {
      unpinned.add(row.entity);
    }
  }

  return [...pinned, ...unpinned];
}

class _TabFilterRow {
  final TabEntity entity;
  final bool isPinned;
  final String? titleKey;
  final String? urlKey;
  final DateTime? dateKey;

  const _TabFilterRow({
    required this.entity,
    required this.isPinned,
    required this.titleKey,
    required this.urlKey,
    required this.dateKey,
  });
}

@Riverpod()
EquatableValue<List<TabEntity>> seamlessFilteredTabEntities(
  Ref ref, {
  required TabSearchPartition searchPartition,
  required ContainerFilter containerFilter,
  required bool groupTrees,
}) {
  final orderKeys = ref.watch(
    watchTabOrderKeysProvider.select((value) => value.value),
  );

  final tabSearchResults = ref
      .watch(
        tabSearchRepositoryProvider(searchPartition).select(
          (value) => EquatableValue(
            value.value.mapNotNull(
              (result) => result.results
                  .map(
                    (tab) => SearchResultTabEntity(
                      tabId: tab.id,
                      orderKey: orderKeys?[tab.id] ?? '',
                      containerId: tab.containerId,
                      searchQuery: result.query,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      )
      .value;

  final availableTabs = ref.watch(
    containerTabEntitiesProvider(containerFilter),
  );

  // Tree mode: no filtering/sorting, return as-is
  if (groupTrees && tabSearchResults == null) {
    // Trees are space-scoped; a container filter narrows the selected
    // space's trees, no filter spans every space.
    final treesSpaceUuid = containerFilter is ContainerFilterDisabled
        ? null
        : ref.watch(selectedSpaceProvider);
    final trees = ref.watch(
      watchTabTreesProvider(
        treesSpaceUuid,
        allSpaces: containerFilter is ContainerFilterDisabled,
      ).select(
        (value) => EquatableValue(
          value.value?.map((tree) {
                // Find the container ID for the latest tab
                final containerForTab = availableTabs.value
                    .where((t) => t.tabId == tree.latestTabId)
                    .firstOrNull
                    ?.containerId;

                return TabTreeEntity(
                  tabId: tree.latestTabId,
                  orderKey: orderKeys?[tree.latestTabId] ?? '',
                  containerId: containerForTab,
                  rootId: tree.rootTabId,
                  totalTabs: tree.totalTabs,
                );
              }).toList() ??
              [],
        ),
      ),
    );

    return EquatableValue(
      trees.value
          .where(
            (tree) => availableTabs.value.any(
              (available) => available.tabId == tree.tabId,
            ),
          )
          .toList(),
    );
  }

  final tabStates = ref.watch(tabStatesProvider);

  final filterOptions = ref.watch(tabViewFilterControllerProvider);

  final pinnedTabIds = ref.watch(pinnedTabIdsProvider);

  // Only pull timestamps from DB when date filtering/sorting is active
  final needsTimestamps =
      filterOptions.effectiveDateRange != null ||
      filterOptions.sortType.sortField == SortField.dateAsc ||
      filterOptions.sortType.sortField == SortField.dateDesc;
  final tabTimestamps = needsTimestamps
      ? ref.watch(watchTabTimestampsProvider.select((value) => value.value))
      : null;

  final tabListDirection = ref.watch(
    generalSettingsWithDefaultsProvider.select((s) => s.tabListDirection),
  );

  // Root tabs are always inserted with a trailing LexoRank key, so the
  // database order (ascending order_key) is oldest-first. Flip to
  // newest-first when the user selects that direction.
  List<TabEntity> applyDirection(List<TabEntity> entities) {
    return tabListDirection == TabDirection.newestFirst
        ? entities.reversed.toList()
        : entities;
  }

  if (tabSearchResults == null) {
    if (filterOptions.hasActiveFilter || pinnedTabIds.isNotEmpty) {
      return EquatableValue(
        _applyTabFiltersAndSort(
          applyDirection(availableTabs.value),
          filterOptions,
          tabStates,
          pinnedTabIds,
          tabTimestamps,
        ),
      );
    }

    return EquatableValue(applyDirection(availableTabs.value));
  }

  final searchFiltered = tabSearchResults
      .where(
        (tab) => availableTabs.value.any(
          (available) => available.tabId == tab.tabId,
        ),
      )
      .toList();

  if (filterOptions.hasActiveFilter || pinnedTabIds.isNotEmpty) {
    return EquatableValue(
      _applyTabFiltersAndSort(
        searchFiltered,
        filterOptions,
        tabStates,
        pinnedTabIds,
        tabTimestamps,
      ),
    );
  }

  return EquatableValue(searchFiltered);
  // Search results retain the search-relevance ordering — no direction flip.
}

@Riverpod()
EquatableValue<List<TabPreview>> filteredTabPreviews(
  Ref ref,
  TabSearchPartition searchPartition,
  ContainerFilter containerFilter,
) {
  final tabSearchResults = ref
      .watch(
        tabSearchRepositoryProvider(
          searchPartition,
        ).select((value) => EquatableValue(value.value)),
      )
      .value;

  final availableTabStates = ref.watch(
    containerTabStatesProvider(containerFilter),
  );

  if (tabSearchResults == null) {
    return EquatableValue([]);
  }

  return EquatableValue(
    tabSearchResults.results
        .where((tab) => availableTabStates.value.containsKey(tab.id))
        .map((tab) {
          final tabState = availableTabStates.value[tab.id]!;
          return TabPreview(
            id: tab.id,
            containerId: tab.containerId,
            title: tab.title ?? tabState.title,
            icon: tabState.icon,
            url: tab.cleanUrl ?? tabState.url,
            highlightedUrl: tab.url,
            extractedContent: tab.extractedContent,
            fullContent: tab.fullContent,
            sourceSearchQuery: tabSearchResults.query,
          );
        })
        .whereType<TabPreview>()
        .toList(),
  );
}

/// Grouped flat-list rendering shared by every surface that lays tabs out in
/// one ordered sequence.
///
/// Parent rows always render before their descendants. [TabDirection]
/// applies both to root group ordering and to sibling ordering below each
/// parent, so parent-child pairs stay together while child order still follows
/// the configured direction.
///
/// [scope] decides which of the tray's controls take part and which direction
/// setting applies — see [TabListScope]. Both scopes run the same grouping,
/// so a tab's place relative to its parent never depends on who is asking.
///
/// [ignoreDirection] renders storage order (`order_key` ascending, the order
/// the desktop sidebar shows) whatever the direction setting says; the wide
/// rail mirrors the desktop and asks for it.
///
/// Returns `null` when the input data is not yet available (loading).
@Riverpod()
EquatableValue<List<TabListItemEntity>> groupedTabListItems(
  Ref ref, {
  required String? spaceUuid,
  required TabListScope scope,
  bool ignoreDirection = false,
}) {
  final tabsWithRoot = ref.watch(
    watchTabsWithRootAndDepthProvider(spaceUuid).select((value) => value.value),
  );
  if (tabsWithRoot == null) {
    return EquatableValue(const []);
  }

  // The rows' shelf, folder, split and liveness — the tree CTE carries only
  // the hierarchy.
  final summaries = ref.watch(
    watchSpaceTabsDataProvider(spaceUuid).select((value) => value.value),
  );
  if (summaries == null) {
    return EquatableValue(const []);
  }
  final summaryById = {for (final tab in summaries) tab.id: tab};

  final folders = spaceUuid == null
      ? const <TabFolderData>[]
      : ref.watch(
              watchFoldersProvider(spaceUuid).select((value) => value.value),
            ) ??
            const <TabFolderData>[];

  final tabList = ref.watch(tabListProvider);

  // Narrow projection instead of the whole `Map<String, TabState>`: this
  // provider does a graph walk plus several sorts, and it feeds the always
  // visible quick tab switcher's depth map. It only reads the tab mode (for
  // filtering) and the title/url (for sorting) — none of which change more
  // often than once per navigation.
  final tabSortKeys = ref.watch(tabSortKeysProvider).value;

  // Reduced before it is compared, so the presentation scope does not rebuild
  // when the user changes a tray control that cannot affect it.
  final filterOptions = ref.watch(
    tabViewFilterControllerProvider.select(
      (options) => scope.isTray ? options : options.toPresentationScope(),
    ),
  );
  final pinnedTabIds = ref.watch(pinnedTabIdsProvider);
  final direction = ignoreDirection
      ? TabDirection.oldestFirst
      : ref.watch(
          generalSettingsWithDefaultsProvider.select(
            (s) => scope.isTray ? s.tabListDirection : s.tabBarDirection,
          ),
        );
  // Collapsing is a tray gesture on tray rows: outside it there is nothing to
  // expand a hidden row back open with, so folded descendants would be
  // unreachable rather than merely tucked away.
  final collapsedGroups = scope.isTray
      ? ref.watch(collapsedGroupsProvider)
      : const <String>{};

  final needsTimestamps =
      filterOptions.effectiveDateRange != null ||
      filterOptions.sortType.sortField == SortField.dateAsc ||
      filterOptions.sortType.sortField == SortField.dateDesc;
  final tabTimestamps = needsTimestamps
      ? ref.watch(watchTabTimestampsProvider.select((value) => value.value))
      : null;

  // Index every row from the CTE — we need the full graph to walk ancestor
  // chains even when intermediate ancestors fail the filter.
  final byId = {for (final row in tabsWithRoot) row.id: row};

  // Keep the rows the engine lists, the cold ones (no session, rendered from
  // the row — PLAN §7.4) and, until the session restore has completed, the
  // restoring ones (a session id the engine has not reported yet — the
  // pre-restore placeholder, see `pendingRestoreTabIds`). Never essentials
  // (they have their own strip), and only rows that pass the tab-type /
  // date-range filter. Filtering is applied to *individual* tabs. After the
  // restore a live row the engine does not list is transient: `syncTabs`
  // demotes or deletes it on the next emission.
  final restoreComplete = ref.watch(browserRestoreCompleteProvider);
  final available = tabsWithRoot.where((row) {
    final summary = summaryById[row.id];
    if (summary == null || summary.tabShelf == TabShelf.essential) {
      return false;
    }
    if (!summary.isCold && !tabList.value.contains(row.id)) {
      final restoring =
          !restoreComplete && summary.tabMode != TabModeDbValue.private;
      if (!restoring) {
        return false;
      }
    }
    return filterOptions.matchesTab(
      tabSortKeys[row.id]?.tabMode ?? TabMode.fromDbValue(summary.tabMode),
      tabTimestamps?[row.id],
    );
  }).toList();

  if (available.isEmpty) {
    return EquatableValue(const []);
  }

  final visibleIds = {for (final row in available) row.id};

  // Map every visible row to the closest visible ancestor (its effective
  // root). When the original root is filtered out we walk up the chain via
  // parent_id until we either find a visible ancestor or fall off the top —
  // in the latter case the row becomes its own root. This keeps subtrees
  // grouped under whichever ancestor remains visible.
  String effectiveRootFor(TabsWithRootAndDepthResult row) {
    var effectiveRoot = row;
    var current = row;
    while (true) {
      final parentId = current.parentId;
      if (parentId == null) return effectiveRoot.id;
      final parent = byId[parentId];
      if (parent == null) return effectiveRoot.id;
      if (visibleIds.contains(parent.id)) {
        // Climb to the topmost visible ancestor so siblings collapse into a
        // single group rather than fragmenting.
        effectiveRoot = parent;
        current = parent;
        continue;
      }
      // Skip filtered-out ancestor and keep climbing.
      current = parent;
    }
  }

  // Recompute depth relative to the effective root (so indentation stays
  // sensible after filtered-out ancestors collapse out).
  int depthFromRoot(TabsWithRootAndDepthResult row, String rootId) {
    var depth = 0;
    var current = row;
    while (current.id != rootId) {
      final parentId = current.parentId;
      if (parentId == null) return depth;
      final parent = byId[parentId];
      if (parent == null) return depth;
      if (visibleIds.contains(parent.id)) {
        depth++;
      }
      current = parent;
    }
    return depth;
  }

  final byRoot = <String, List<_GroupedRow>>{};
  for (final row in available) {
    final rootId = effectiveRootFor(row);
    byRoot
        .putIfAbsent(rootId, () => [])
        .add(_GroupedRow(row: row, depth: depthFromRoot(row, rootId)));
  }

  // Build a list of group records to sort across.
  final sortField = filterOptions.sortType.sortField;
  final groupRecords = <_TabGroupRecord>[];
  for (final entry in byRoot.entries) {
    final rootMember = entry.value.firstWhere((r) => r.row.id == entry.key);
    final root = rootMember.row;
    final summary = summaryById[root.id]!;
    final sortKeys = tabSortKeys[root.id];
    final timestamp = tabTimestamps?[root.id];
    groupRecords.add(
      _TabGroupRecord(
        rootId: root.id,
        rootOrderKey: root.orderKey,
        root: rootMember,
        members: entry.value,
        shelf: summary.tabShelf,
        folderId: summary.folderId,
        splitId: summary.splitId,
        splitIndex: summary.splitIndex ?? 0,
        titleKey:
            sortField == SortField.titleAsc || sortField == SortField.titleDesc
            ? (sortKeys?.titleOrAuthority ??
                      summary.staticLabel ??
                      summary.title ??
                      '')
                  .toLowerCase()
            : null,
        urlKey: sortField == SortField.urlAsc || sortField == SortField.urlDesc
            ? (sortKeys?.url ?? summary.url?.toString() ?? '')
            : null,
        dateKey:
            sortField == SortField.dateAsc || sortField == SortField.dateDesc
            ? (timestamp ?? DateTime(0))
            : null,
      ),
    );
  }

  // Split members occupy one slot (PLAN §6.5): rank every member at the
  // split's first member and let `splitIndex` order them within it.
  final firstKeyBySplit = <String, String>{};
  for (final group in groupRecords) {
    final splitId = group.splitId;
    if (splitId == null) continue;
    final current = firstKeyBySplit[splitId];
    if (current == null || group.rootOrderKey.compareTo(current) < 0) {
      firstKeyBySplit[splitId] = group.rootOrderKey;
    }
  }
  for (final group in groupRecords) {
    final splitId = group.splitId;
    if (splitId != null) {
      group.slotKey = firstKeyBySplit[splitId]!;
    }
  }

  int compareStorage(_TabGroupRecord a, _TabGroupRecord b) {
    final cmp = a.slotKey.compareTo(b.slotKey);
    if (cmp != 0) return cmp;
    final splitCmp = a.splitIndex.compareTo(b.splitIndex);
    if (splitCmp != 0) return splitCmp;
    return a.rootOrderKey.compareTo(b.rootOrderKey);
  }

  int compareGroups(_TabGroupRecord a, _TabGroupRecord b) {
    if (sortField != null) {
      final cmp = switch (sortField) {
        SortField.titleAsc => a.titleKey!.compareTo(b.titleKey!),
        SortField.titleDesc => b.titleKey!.compareTo(a.titleKey!),
        SortField.urlAsc => a.urlKey!.compareTo(b.urlKey!),
        SortField.urlDesc => b.urlKey!.compareTo(a.urlKey!),
        SortField.dateAsc => a.dateKey!.compareTo(b.dateKey!),
        SortField.dateDesc => b.dateKey!.compareTo(a.dateKey!),
      };
      if (cmp != 0) return cmp;
    }
    return compareStorage(a, b);
  }

  // Direction applies to the order of slots within a scope. When no explicit
  // sortField is active, oldest-first is the natural order_key ASC and
  // newest-first reverses the sequence — except that split members keep their
  // `splitIndex` order, so a reversed run of members is put back.
  List<_ScopeSlot> applyDirection(List<_ScopeSlot> slots) {
    if (sortField != null || direction != TabDirection.newestFirst) {
      return slots;
    }
    final reversed = slots.reversed.toList();
    var runStart = 0;
    while (runStart < reversed.length) {
      final splitId = reversed[runStart].splitId;
      var runEnd = runStart + 1;
      if (splitId != null) {
        while (runEnd < reversed.length &&
            reversed[runEnd].splitId == splitId) {
          runEnd++;
        }
        if (runEnd - runStart > 1) {
          final run = reversed.sublist(runStart, runEnd)
            ..sort((a, b) => a.splitIndex.compareTo(b.splitIndex));
          reversed.replaceRange(runStart, runEnd, run);
        }
      }
      runStart = runEnd;
    }
    return reversed;
  }

  // Flatten according to expansion state.
  final result = <TabListItemEntity>[];

  // A row's own shelf, for the surfaces that section the list; a child that
  // the tree query lists under a pinned root still reports its own row.
  TabShelf shelfOf(String tabId) =>
      summaryById[tabId]?.tabShelf ?? TabShelf.normal;

  void emitGroup(_TabGroupRecord group, int folderDepth) {
    if (group.members.length == 1) {
      final only = group.root.row;
      result.add(
        TabListStandaloneItem(
          tabId: only.id,
          orderKey: only.orderKey,
          spaceUuid: spaceUuid,
          depth: folderDepth,
          shelf: group.shelf,
        ),
      );
      return;
    }

    final root = group.root.row;
    result.add(
      TabListParentGroup(
        tabId: root.id,
        orderKey: root.orderKey,
        spaceUuid: spaceUuid,
        childCount: group.members.length - 1,
        depth: folderDepth,
        shelf: group.shelf,
      ),
    );

    if (collapsedGroups.contains(root.id)) {
      return;
    }

    final childrenByVisibleParent = <String, List<_GroupedRow>>{};
    for (final member in group.members) {
      if (member.row.id == root.id) {
        continue;
      }
      final visibleParentId = _nearestVisibleParentId(
        member.row,
        root.id,
        byId,
        visibleIds,
      );
      childrenByVisibleParent
          .putIfAbsent(visibleParentId, () => [])
          .add(member);
    }

    // Children are sorted by storage `order_key` (optionally reversed for
    // newest-first) — even when an explicit `sortField` is active. The
    // explicit sort applies only to root groups; descendants remain in
    // insertion order. When `sortPinnedFirst` is true, pinned children are
    // sorted before unpinned siblings within each parent group.
    for (final children in childrenByVisibleParent.values) {
      int cmp(_GroupedRow a, _GroupedRow b) =>
          a.row.orderKey.compareTo(b.row.orderKey);
      final directionCmp = direction == TabDirection.newestFirst
          ? (_GroupedRow a, _GroupedRow b) => -cmp(a, b)
          : cmp;
      if (filterOptions.sortPinnedFirst) {
        final pinned = children
            .where((c) => pinnedTabIds.contains(c.row.id))
            .toList();
        final unpinned = children
            .where((c) => !pinnedTabIds.contains(c.row.id))
            .toList();
        pinned.sort(directionCmp);
        unpinned.sort(directionCmp);
        children
          ..clear()
          ..addAll(pinned)
          ..addAll(unpinned);
      } else {
        children.sort(directionCmp);
      }
    }

    void addChildren(String parentId) {
      for (final member
          in childrenByVisibleParent[parentId] ?? const <_GroupedRow>[]) {
        final child = member.row;
        final grandchildren =
            childrenByVisibleParent[child.id] ?? const <_GroupedRow>[];
        result.add(
          TabListChildItem(
            tabId: child.id,
            orderKey: child.orderKey,
            spaceUuid: spaceUuid,
            parentId: parentId,
            rootId: root.id,
            depth: member.depth + folderDepth,
            childCount: grandchildren.length,
            shelf: shelfOf(child.id),
          ),
        );
        // Respect per-node collapse: collapsing an intermediate child hides
        // its descendants while keeping siblings of the parent visible.
        if (!collapsedGroups.contains(child.id)) {
          addChildren(child.id);
        }
      }
    }

    addChildren(root.id);
  }

  // Folder membership comes before the shelf (PLAN §6.4): Zen keeps folders
  // in the pinned section, so every folder member is a pinned tab with a
  // `folder_id`. A space's "Pinned" section is therefore its root pinned
  // tabs and its root folders — each folder followed by its contents —
  // interleaved by `order_key` exactly as on the desktop strip
  // (`#childSequence`); the normal section holds the root normal tabs only.
  final folderById = {for (final folder in folders) folder.id: folder};
  String? folderOf(_TabGroupRecord group) =>
      folderById.containsKey(group.folderId) ? group.folderId : null;

  final rootPinnedGroups = groupRecords
      .where((g) => g.shelf == TabShelf.pinned && folderOf(g) == null)
      .toList();
  final otherGroups = groupRecords
      .where((g) => g.shelf != TabShelf.pinned || folderOf(g) != null)
      .toList();

  if (sortField != null) {
    // An explicit title/URL/date sort is a flat list: folders have no
    // position in it, so their tabs are listed at the root, after the
    // root pinned tabs.
    rootPinnedGroups.sort(compareGroups);
    otherGroups.sort(compareGroups);
    for (final group in rootPinnedGroups.followedBy(otherGroups)) {
      emitGroup(group, 0);
    }
    return EquatableValue(result);
  }

  // Inside a folder its members (either shelf) and sub-folders form one
  // `order_key` sequence, indented below the folder row.
  final groupsByFolder = <String?, List<_TabGroupRecord>>{};
  for (final group in otherGroups) {
    groupsByFolder.putIfAbsent(folderOf(group), () => []).add(group);
  }
  final foldersByParent = <String?, List<TabFolderData>>{};
  for (final folder in folders) {
    final parentId = folderById.containsKey(folder.parentFolderId)
        ? folder.parentFolderId
        : null;
    foldersByParent.putIfAbsent(parentId, () => []).add(folder);
  }

  int countTabsIn(String folderId) {
    var count = 0;
    for (final group in groupsByFolder[folderId] ?? const <_TabGroupRecord>[]) {
      count += group.members.length;
    }
    for (final child in foldersByParent[folderId] ?? const <TabFolderData>[]) {
      count += countTabsIn(child.id);
    }
    return count;
  }

  final emittedFolders = <String>{};
  List<_ScopeSlot> folderSlots(String? parentId) => [
    for (final folder in foldersByParent[parentId] ?? const <TabFolderData>[])
      if (emittedFolders.add(folder.id)) _ScopeSlot.ofFolder(folder),
  ];
  List<_ScopeSlot> groupSlots(Iterable<_TabGroupRecord> groups) => [
    for (final group in groups) _ScopeSlot.ofGroup(group),
  ];

  void emitSlots(List<_ScopeSlot> slots, int depth) {
    slots.sort((a, b) {
      final cmp = a.orderKey.compareTo(b.orderKey);
      if (cmp != 0) return cmp;
      return a.splitIndex.compareTo(b.splitIndex);
    });
    for (final slot in applyDirection(slots)) {
      final group = slot.group;
      if (group != null) {
        emitGroup(group, depth);
        continue;
      }
      final folder = slot.folder!;
      result.add(
        TabListFolderItem(
          folderId: folder.id,
          orderKey: folder.orderKey,
          spaceUuid: spaceUuid,
          name: folder.name,
          isCollapsed: folder.isCollapsed,
          depth: depth,
          childCount: countTabsIn(folder.id),
        ),
      );
      if (!folder.isCollapsed) {
        emitSlots([
          ...groupSlots(groupsByFolder[folder.id] ?? const []),
          ...folderSlots(folder.id),
        ], depth + 1);
      }
    }
  }

  // The pinned section: root pinned tabs and root folders.
  emitSlots([...groupSlots(rootPinnedGroups), ...folderSlots(null)], 0);
  // The normal section: root normal tabs.
  emitSlots(groupSlots(groupsByFolder[null] ?? const []), 0);

  return EquatableValue(result);
}

/// The final row order a surface renders, i.e. [groupedTabListItemsProvider]
/// plus the flat post-processing: where there are no visible groups to keep
/// together, pinned tabs move ahead of unpinned ones across the whole list.
///
/// That flattening applies to the tray only with hierarchy display turned off,
/// but always in [TabListScope.presentation] — the quick tab switcher and the
/// tab bar are single strips of chips that draw hierarchy as an indent glyph
/// rather than as position, so a pinned tab belongs at the front there whether
/// or not it happens to sit under a parent. Folder members are the exception:
/// they are pinned tabs by construction (PLAN §6.4) but stay under their
/// folder row, which is where the eye looks for them; only the space's root
/// pinned tabs float.
///
/// This is the single order every non-tray surface reads: the switcher, the tab
/// bar and sequential tab navigation all take the presentation scope, so
/// "the tab after this one" cannot mean one thing to the eye and another to a
/// swipe.
@Riverpod()
EquatableValue<List<TabListItemEntity>> visibleTabListItems(
  Ref ref, {
  required String? spaceUuid,
  required TabListScope scope,
  bool ignoreDirection = false,
}) {
  final groupedItems = ref
      .watch(
        groupedTabListItemsProvider(
          spaceUuid: spaceUuid,
          scope: scope,
          ignoreDirection: ignoreDirection,
        ),
      )
      .value;
  final filterOptions = ref.watch(tabViewFilterControllerProvider);
  final flattenPinned =
      filterOptions.sortPinnedFirst &&
      (!scope.isTray || !filterOptions.showHierarchicalTabs);
  if (!flattenPinned) {
    return EquatableValue(groupedItems);
  }

  final pinnedTabIds = ref.watch(pinnedTabIdsProvider);
  // A root folder row (depth 0) opens a folder; the next root row of any kind
  // closes it. Rows in between are the folder's contents and never float.
  final floating = <TabListItemEntity>[];
  final rest = <TabListItemEntity>[];
  var insideFolder = false;
  for (final item in groupedItems) {
    if (item.depth == 0) {
      insideFolder = item is TabListFolderItem;
    }
    final floats =
        !insideFolder &&
        item is TabListTabItem &&
        pinnedTabIds.contains(item.tabId);
    (floats ? floating : rest).add(item);
  }
  return EquatableValue([...floating, ...rest]);
}

/// Flat tab id order used by sequential tab navigation: the tab bar swipe
/// action and the next/previous tab gestures.
///
/// Navigation follows the rendered order instead of the raw storage
/// `order_key`, so it carries tree grouping and pinned-first handling — stepping
/// to the tab the user sees next to the current one rather than to an unrelated
/// `order_key` neighbour.
///
/// The order it follows is [TabListScope.presentation], the one the quick tab
/// switcher and the tab bar draw, *not* the tray's. Both gestures are only
/// reachable with the tray closed, so the tray's filters, collapsed groups and
/// title/URL/date sort describe a list nobody is looking at while they fire;
/// letting them through made the swipe skip chips that were plainly on screen
/// and, when they hid the current tab outright, jump to the far end of the
/// strip (issue #603). Sharing one provider with those surfaces is what keeps
/// the two from drifting apart again.
///
/// With `sequentialTabNavigationCrossContainers` on (the default) it spans
/// **all** containers, keeping the boundary-crossing reach the storage-order
/// walk had: each container contributes the rows its switcher would render, and
/// the containers follow one another in the order the quick tab switcher lays
/// them out — the unassigned bucket first, then containers by pinned/`order_key`.
/// Stepping off the end of one container therefore continues into the next, and
/// selecting that tab moves the selected container along with it. Named
/// containers holding no tabs are skipped so their tree query never runs.
///
/// With the setting off the order holds only the selected container's rows, so
/// navigation stays inside the container the user is looking at and stops at its
/// edge — the containers themselves are then only switched deliberately.
///
/// "Previous" is a step towards the top of that order and "next" a step
/// towards its end, so direction follows `tabBarDirection` (baked into the
/// order) rather than `tabListDirection` — the bar is what the step is read
/// against, and the two only disagree when the user sets them apart.
///
/// The tray's own search results are deliberately not part of this: the swipe
/// and the gestures are only reachable with the tray closed.
///
/// `null` means the underlying tree data has not arrived yet — the only state
/// in which the caller may fall back to storage order. An empty list is a real
/// answer ("this container holds nothing to move to") and must not be mistaken
/// for a missing one.
///
/// Kept alive and actively listened to by [TabRepository]: it is consumed by a
/// synchronous `ref.read` at the moment of the swipe/gesture, from outside the
/// widget tree. Without a listener Riverpod pauses the chain when nothing is on
/// screen watching it, so the order could go stale — or be created empty on the
/// read, with its tree stream still loading, and silently drop navigation back
/// to storage order. The selected container's chain is alive anyway whenever the
/// quick tab switcher or the tray is on screen; the price of crossing container
/// boundaries is that the other populated containers' tree queries are kept
/// alive too.
@Riverpod(keepAlive: true)
EquatableValue<List<String>?> sequentialTabNavigationOrder(Ref ref) {
  final crossSpaces = ref.watch(
    generalSettingsWithDefaultsProvider.select(
      (settings) => settings.effectiveSequentialTabNavigationCrossContainers,
    ),
  );

  final List<String?> spaceUuids;
  if (crossSpaces) {
    final spaces = ref.watch(
      watchSpacesProvider.select((value) => value.value),
    );
    if (spaces == null) {
      return EquatableValue(null);
    }
    // The space-less bucket (private tabs) first, then the spaces in order.
    spaceUuids = <String?>[null, for (final space in spaces) space.uuid];
  } else {
    spaceUuids = <String?>[ref.watch(selectedSpaceProvider)];
  }

  final order = <String>[];
  for (final spaceUuid in spaceUuids) {
    // Holding these auto-disposed per-space queries open is the documented
    // price of a cross-space order that must answer a synchronous read at
    // the moment of the swipe (see above).
    // ignore: riverpod_lint/only_use_keep_alive_inside_keep_alive
    final hasTreeData = ref.watch(
      watchTabsWithRootAndDepthProvider(
        spaceUuid,
      ).select((value) => value.hasValue),
    );
    if (!hasTreeData) {
      return EquatableValue(null);
    }
    // ignore: riverpod_lint/only_use_keep_alive_inside_keep_alive
    final visibleItems = ref
        .watch(
          visibleTabListItemsProvider(
            spaceUuid: spaceUuid,
            scope: TabListScope.presentation,
          ),
        )
        .value;
    order.addAll(visibleItems.whereType<TabListTabItem>().map((i) => i.tabId));
  }

  return EquatableValue(order);
}

String _nearestVisibleParentId(
  TabsWithRootAndDepthResult row,
  String rootId,
  Map<String, TabsWithRootAndDepthResult> byId,
  Set<String> visibleIds,
) {
  var current = row;
  final seen = <String>{row.id};

  while (true) {
    final parentId = current.parentId;
    if (parentId == null) {
      return rootId;
    }
    if (parentId == rootId) {
      return rootId;
    }

    final parent = byId[parentId];
    if (parent == null || !seen.add(parent.id)) {
      return rootId;
    }
    if (visibleIds.contains(parent.id)) {
      return parent.id;
    }

    current = parent;
  }
}

class _GroupedRow {
  final TabsWithRootAndDepthResult row;
  final int depth;

  _GroupedRow({required this.row, required this.depth});
}

class _TabGroupRecord {
  final String rootId;
  final String rootOrderKey;
  final _GroupedRow root;
  final List<_GroupedRow> members;
  final TabShelf shelf;
  final String? folderId;
  final String? splitId;
  final int splitIndex;
  final String? titleKey;
  final String? urlKey;
  final DateTime? dateKey;

  /// Storage rank of the group's slot: its root's `order_key`, or — for a
  /// split member — the split's first member's key, so members stay adjacent.
  String slotKey;

  _TabGroupRecord({
    required this.rootId,
    required this.rootOrderKey,
    required this.root,
    required this.members,
    required this.shelf,
    required this.folderId,
    required this.splitId,
    required this.splitIndex,
    required this.titleKey,
    required this.urlKey,
    required this.dateKey,
  }) : slotKey = rootOrderKey;

  bool get isPinned => shelf == TabShelf.pinned;
}

/// One entry of a scope's child sequence: a tab group or a folder.
class _ScopeSlot {
  final String orderKey;
  final int splitIndex;
  final _TabGroupRecord? group;
  final TabFolderData? folder;

  _ScopeSlot.ofGroup(_TabGroupRecord this.group)
    : orderKey = group.slotKey,
      splitIndex = group.splitIndex,
      folder = null;

  _ScopeSlot.ofFolder(TabFolderData this.folder)
    : orderKey = folder.orderKey,
      splitIndex = 0,
      group = null;

  String? get splitId => group?.splitId;
}
