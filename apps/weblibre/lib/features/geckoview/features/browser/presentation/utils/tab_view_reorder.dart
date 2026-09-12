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
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/tab_view_item.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/entities/tab_parent_change.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';

class TabViewReorderResult {
  final List<String> movingTabIds;
  final String? previousTabId;
  final String? nextTabId;

  /// Parent assignment implied by the drop position. `unchanged` for plain
  /// reorders; `detach` / `toParent` only emitted in hierarchical mode when
  /// the drop lands outside the moving root's current parent scope.
  final TabParentChange parentChange;

  /// Space/folder assignment implied by the drop position — see
  /// [buildTabViewReorderResult] doc for the anchor rule.
  final TabScopeChange scopeChange;

  const TabViewReorderResult({
    required this.movingTabIds,
    required this.previousTabId,
    required this.nextTabId,
    this.parentChange = const TabParentChange.unchanged(),
    this.scopeChange = const TabScopeChange.unchanged(),
  });
}

/// Builds the reorder/reparent/rescope request implied by dragging
/// `visibleItems[oldIndex]` to `newIndex`.
///
/// [folderIdByTab] and [splitMembers] are pure lookups the caller builds once
/// per build from `watchSpaceTabsDataProvider(spaceUuid)` summaries — this
/// function does no Riverpod reads of its own:
/// - [folderIdByTab]: tab id -> its current `folderId` (`null` at the space
///   root). Used to decide [TabScopeChange].
/// - [splitMembers]: tab id -> every tab id sharing that tab's `splitId`
///   (including itself), already ordered by `splitIndex`. Tabs with no split
///   should either be absent or map to `[tabId]`.
///
/// Folder rows ([FolderTabViewItem]) are never draggable: a reorder whose
/// moving item is a folder returns `null`.
///
/// Scope anchor rule (folder the moving block lands in): if the row directly
/// above the drop slot is a folder row, the block drops into that folder.
/// Otherwise, find the nearest non-folder tab neighbours above/below the drop
/// slot (skipping folder rows entirely): if both exist and share a folder,
/// drop into that folder; if only one exists, drop into its folder; if
/// neither exists, the block moves to the space root. The result is only
/// reported as a change when the resolved folder differs from the moving
/// root's current folder — otherwise `TabScopeChange.unchanged()`.
TabViewReorderResult? buildTabViewReorderResult({
  required List<TabViewItem> visibleItems,
  required List<TabsWithRootAndDepthResult> treeRows,
  required Set<String> collapsedGroups,
  required Set<String> pinnedTabIds,
  required int oldIndex,
  required int newIndex,
  required TabDirection tabListDirection,
  required bool hierarchical,
  required bool sortPinnedFirst,
  required Map<String, String?> folderIdByTab,
  required Map<String, List<String>> splitMembers,
  required String? spaceUuid,
}) {
  if (oldIndex < 0 || oldIndex >= visibleItems.length) {
    logger.t(
      'reorder refused: oldIndex $oldIndex out of range '
      '(visibleItems.length=${visibleItems.length})',
    );
    return null;
  }

  if (visibleItems[oldIndex].isFolder) {
    logger.t('reorder refused: folder rows are not draggable');
    return null;
  }

  final reordered = visibleItems.toList();
  final movingItem = reordered.removeAt(oldIndex);

  // `newIndex` is already post-removal: every reorderable surface in the app
  // (the tray list and grid, the tab bar chips) normalises Flutter's raw
  // `onReorder` index before calling here — see `onReorderItem`.
  final insertIndex = newIndex.clamp(0, reordered.length);
  reordered.insert(insertIndex, movingItem);

  // Every other tab sharing the moving tab's splitId must move as one block
  // with it, in splitIndex order, regardless of hierarchy mode.
  final movingSplitSiblings = (splitMembers[movingItem.tabId] ?? const [])
      .where((tabId) => tabId != movingItem.tabId)
      .toList();

  if (!hierarchical) {
    final withoutSplitSiblings = movingSplitSiblings.isEmpty
        ? reordered
        : [
            for (final item in reordered)
              if (!movingSplitSiblings.contains(item.tabId)) item,
          ];

    final scopeChange = _computeScopeChange(
      displayOrder: withoutSplitSiblings,
      movingTabId: movingItem.tabId,
      folderIdByTab: folderIdByTab,
      spaceUuid: spaceUuid,
    );

    final ordered = <String>[];
    for (final item in withoutSplitSiblings) {
      ordered.add(item.tabId);
      if (item.tabId == movingItem.tabId) {
        ordered.addAll(movingSplitSiblings);
      }
    }

    return _resultFromOrderedIds(
      movingTabIds: [movingItem.tabId, ...movingSplitSiblings],
      orderedTabIds: _orderedIdsForStorageAnchors(
        ordered,
        tabListDirection: tabListDirection,
        pinnedTabIds: pinnedTabIds,
        parentById: const {},
        movingPartitionRootId: movingItem.tabId,
        sortPinnedFirst: sortPinnedFirst,
      ),
      scopeChange: scopeChange,
    );
  }

  final rowsById = {for (final row in treeRows) row.id: row};
  final parentById = {for (final row in treeRows) row.id: row.parentId};
  // Build the parent → ordered-children index once and reuse for every
  // _subtreeIds call below. _subtreeIds is invoked for the moving item plus
  // every collapsed group encountered while flattening, so reusing this map
  // turns N tree walks into N cheap lookups.
  final childrenByParent = _buildChildrenByParent(rowsById, parentById);
  final treeBlock = _subtreeIds(movingItem.tabId, rowsById, childrenByParent);
  // Split siblings ride along with the moving block but are not part of its
  // tab-tree subtree, so they are appended rather than walked via
  // _subtreeIds.
  final moveBlock = [...treeBlock, ...movingSplitSiblings];
  final moveBlockIds = moveBlock.toSet();

  final withoutMovingItem = visibleItems.toList()..removeAt(oldIndex);
  final targetBeforeId = insertIndex < withoutMovingItem.length
      ? withoutMovingItem[insertIndex].tabId
      : null;
  if (targetBeforeId != null && moveBlockIds.contains(targetBeforeId)) {
    logger.t('reorder refused: drop target is inside the moving subtree');
    return null;
  }

  final remaining = [
    for (final item in visibleItems)
      if (!moveBlockIds.contains(item.tabId)) item,
  ];
  final requestedInsertIndex = targetBeforeId == null
      ? remaining.length
      : remaining.indexWhere((item) => item.tabId == targetBeforeId);
  if (requestedInsertIndex < 0) {
    logger.t(
      'reorder refused: target $targetBeforeId not present in remaining list '
      '(defensive)',
    );
    return null;
  }

  // Derive the new parent scope purely from the visual drop position. The
  // rule is "adopt the parent of the item you dropped above"; when dropped
  // past the last visible item, adopt the parent of that last item. This
  // unifies plain reorder ("same parent as the target slot") and
  // drag-to-reparent ("different parent than the moving root") behind a
  // single predicate.
  final String? newParentScope = _dropParentScopeFor(
    remaining,
    requestedInsertIndex,
  );

  // Cycle guard: the new parent must not be inside the moving subtree.
  if (newParentScope != null && moveBlockIds.contains(newParentScope)) {
    logger.t('reorder refused: new parent scope is inside moving subtree');
    return null;
  }

  final originalParentScope = _parentScope(movingItem);
  final TabParentChange parentChange = newParentScope == originalParentScope
      ? const TabParentChange.unchanged()
      : newParentScope == null
      ? const TabParentChange.detach()
      : TabParentChange.toParent(newParentScope);
  final resolvedInsertIndex = requestedInsertIndex.clamp(0, remaining.length);

  final reorderedBlocks = remaining.toList()
    ..insert(resolvedInsertIndex, movingItem);

  final scopeChange = _computeScopeChange(
    displayOrder: reorderedBlocks,
    movingTabId: movingItem.tabId,
    folderIdByTab: folderIdByTab,
    spaceUuid: spaceUuid,
  );

  final displayBlocks = <List<String>>[];
  final emitted = <String>{};
  for (final item in reorderedBlocks) {
    if (emitted.contains(item.tabId)) {
      continue;
    }

    final hasChildren =
        item.parentGroup != null || (item.childItem?.childCount ?? 0) > 0;
    final block = item.tabId == movingItem.tabId
        ? moveBlock
        : hasChildren && collapsedGroups.contains(item.tabId)
        ? _subtreeIds(item.tabId, rowsById, childrenByParent)
        : [item.tabId];

    final visibleBlock = [
      for (final tabId in block)
        if (!emitted.contains(tabId)) tabId,
    ];
    if (visibleBlock.isEmpty) {
      continue;
    }

    displayBlocks.add(visibleBlock);
    emitted.addAll(visibleBlock);
  }

  // Partition blocks (not raw ids) by their root group, preserving block
  // atomicity. The first block in each group always contains the root, since
  // visibleItems is rendered parent-before-children. Subsequent blocks are
  // siblings/descendants in display order.
  final blocksByRoot = <String, List<List<String>>>{};
  final rootOrder = <String>[];
  for (final block in displayBlocks) {
    final rootId = _rootIdFor(block.first, parentById);
    blocksByRoot
        .putIfAbsent(rootId, () {
          rootOrder.add(rootId);
          return [];
        })
        .add(block);
  }

  // For newest-first display, the rendered child order within a group is the
  // reverse of storage (orderKey-ascending) order. Convert back to storage
  // order before picking anchors so genBetween receives prev.orderKey <
  // next.orderKey. Block contents (e.g. the moving subtree from _subtreeIds)
  // are already storage-ordered internally, so we reverse blocks as units.
  if (tabListDirection == TabDirection.newestFirst) {
    for (final blocks in blocksByRoot.values) {
      if (blocks.length > 1) {
        final reversedTail = blocks.sublist(1).reversed.toList();
        blocks
          ..removeRange(1, blocks.length)
          ..addAll(reversedTail);
      }
    }
  }

  final orderedRootIds = tabListDirection == TabDirection.newestFirst
      ? rootOrder.reversed
      : rootOrder;

  final orderedTabIds = [
    for (final rootId in orderedRootIds)
      for (final block in blocksByRoot[rootId]!) ...block,
  ];

  return _resultFromOrderedIds(
    movingTabIds: moveBlock,
    orderedTabIds: _orderedIdsForStorageAnchors(
      orderedTabIds,
      tabListDirection: tabListDirection,
      pinnedTabIds: pinnedTabIds,
      parentById: parentById,
      movingPartitionRootId: _rootIdFor(movingItem.tabId, parentById),
      sortPinnedFirst: sortPinnedFirst,
    ),
    parentChange: parentChange,
    scopeChange: scopeChange,
  );
}

/// Returns the parent scope implied by dropping just before
/// `remaining[insertIndex]` (or "at the end" when `insertIndex == length`).
///
/// Rule: adopt the parent of the item you dropped above. For a tail-drop,
/// adopt the parent of the last item. The resulting scope is the
/// candidate `parent_id` for the moving subtree's root.
String? _dropParentScopeFor(List<TabViewItem> remaining, int insertIndex) {
  if (remaining.isEmpty) {
    return null;
  }
  if (insertIndex < remaining.length) {
    return _parentScope(remaining[insertIndex]);
  }
  return _parentScope(remaining.last);
}

List<String> _orderedIdsForStorageAnchors(
  List<String> orderedTabIds, {
  required TabDirection tabListDirection,
  required Set<String> pinnedTabIds,
  required Map<String, String?> parentById,
  required String movingPartitionRootId,
  required bool sortPinnedFirst,
}) {
  final storageOrderedIds = tabListDirection == TabDirection.newestFirst
      // Rendering flips root group order for newest-first; convert the
      // display order back to storage order before choosing anchors.
      ? orderedTabIds.reversed.toList()
      : orderedTabIds;

  if (!sortPinnedFirst || pinnedTabIds.isEmpty) {
    return storageOrderedIds;
  }

  // Pinned-first is a render-only partition, so choose DB anchors only from
  // the moving tab's own partition to avoid snapping across the boundary.
  final movingPinned = pinnedTabIds.contains(movingPartitionRootId);
  return storageOrderedIds.where((tabId) {
    final rootId = _rootIdFor(tabId, parentById);
    return pinnedTabIds.contains(rootId) == movingPinned;
  }).toList();
}

TabViewReorderResult? _resultFromOrderedIds({
  required List<String> movingTabIds,
  required List<String> orderedTabIds,
  TabParentChange parentChange = const TabParentChange.unchanged(),
  TabScopeChange scopeChange = const TabScopeChange.unchanged(),
}) {
  if (movingTabIds.isEmpty) {
    return null;
  }

  final movingSet = movingTabIds.toSet();
  final firstIndex = orderedTabIds.indexWhere(movingSet.contains);
  if (firstIndex < 0) {
    return null;
  }

  var lastIndex = firstIndex;
  while (lastIndex + 1 < orderedTabIds.length &&
      movingSet.contains(orderedTabIds[lastIndex + 1])) {
    lastIndex++;
  }

  return TabViewReorderResult(
    movingTabIds: movingTabIds,
    previousTabId: firstIndex > 0 ? orderedTabIds[firstIndex - 1] : null,
    nextTabId: lastIndex + 1 < orderedTabIds.length
        ? orderedTabIds[lastIndex + 1]
        : null,
    parentChange: parentChange,
    scopeChange: scopeChange,
  );
}

/// Derives the folder [TabScopeChange] implied by the drop, given the
/// display order after the moving block has been collapsed back into a
/// single [movingTabId] placeholder at its new slot. See
/// [buildTabViewReorderResult] doc for the anchor rule.
TabScopeChange _computeScopeChange({
  required List<TabViewItem> displayOrder,
  required String movingTabId,
  required Map<String, String?> folderIdByTab,
  required String? spaceUuid,
}) {
  final index = displayOrder.indexWhere((item) => item.tabId == movingTabId);
  if (index < 0) {
    return const TabScopeChange.unchanged();
  }

  TabViewItem? directlyAbove;
  for (var i = index - 1; i >= 0; i--) {
    if (displayOrder[i].tabId != movingTabId) {
      directlyAbove = displayOrder[i];
      break;
    }
  }

  String? resolvedFolder;
  final folderRowAbove = directlyAbove?.folderItem;
  if (folderRowAbove != null) {
    // Dropping right under a folder header puts the tab into that folder,
    // regardless of what the nearest tab neighbours below belong to.
    resolvedFolder = folderRowAbove.folderId;
  } else {
    TabViewItem? prevTab;
    for (var i = index - 1; i >= 0; i--) {
      final item = displayOrder[i];
      if (item.tabId != movingTabId && !item.isFolder) {
        prevTab = item;
        break;
      }
    }

    TabViewItem? nextTab;
    for (var i = index + 1; i < displayOrder.length; i++) {
      final item = displayOrder[i];
      if (item.tabId != movingTabId && !item.isFolder) {
        nextTab = item;
        break;
      }
    }

    if (prevTab != null && nextTab != null) {
      final prevFolder = folderIdByTab[prevTab.tabId];
      final nextFolder = folderIdByTab[nextTab.tabId];
      resolvedFolder = prevFolder == nextFolder ? prevFolder : null;
    } else if (prevTab != null) {
      resolvedFolder = folderIdByTab[prevTab.tabId];
    } else if (nextTab != null) {
      resolvedFolder = folderIdByTab[nextTab.tabId];
    } else {
      resolvedFolder = null;
    }
  }

  final currentFolder = folderIdByTab[movingTabId];
  if (resolvedFolder == currentFolder) {
    return const TabScopeChange.unchanged();
  }
  return TabScopeChange.toScope(spaceUuid: spaceUuid, folderId: resolvedFolder);
}

String? _parentScope(TabViewItem item) => item.childItem?.parentId;

Map<String, List<TabsWithRootAndDepthResult>> _buildChildrenByParent(
  Map<String, TabsWithRootAndDepthResult> rowsById,
  Map<String, String?> parentById,
) {
  final childrenByParent = <String, List<TabsWithRootAndDepthResult>>{};
  for (final row in rowsById.values) {
    final parentId = parentById[row.id];
    if (parentId == null) continue;
    childrenByParent.putIfAbsent(parentId, () => []).add(row);
  }
  for (final children in childrenByParent.values) {
    children.sort((a, b) => a.orderKey.compareTo(b.orderKey));
  }
  return childrenByParent;
}

List<String> _subtreeIds(
  String rootId,
  Map<String, TabsWithRootAndDepthResult> rowsById,
  Map<String, List<TabsWithRootAndDepthResult>> childrenByParent,
) {
  final root = rowsById[rootId];
  if (root == null) {
    return [rootId];
  }

  final result = <String>[];
  final visited = <String>{};

  void collect(String tabId) {
    if (!visited.add(tabId)) return;

    result.add(tabId);
    for (final child
        in childrenByParent[tabId] ?? const <TabsWithRootAndDepthResult>[]) {
      collect(child.id);
    }
  }

  collect(root.id);
  return result;
}

String _rootIdFor(String tabId, Map<String, String?> parentById) {
  var rootId = tabId;
  var parentId = parentById[rootId];
  final seen = <String>{rootId};

  while (parentId != null && parentById.containsKey(parentId)) {
    if (!seen.add(parentId)) {
      break;
    }
    rootId = parentId;
    parentId = parentById[rootId];
  }

  return rootId;
}
