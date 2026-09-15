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
import 'package:mellow/core/logger.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/tab_view/tab_view_item.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/entities/tab_scope_change.dart';

class TabViewReorderResult {
  final List<String> movingTabIds;
  final String? previousTabId;
  final String? nextTabId;

  /// Space/folder assignment implied by the drop position — see
  /// [buildTabViewReorderResult] doc for the anchor rule.
  final TabScopeChange scopeChange;

  const TabViewReorderResult({
    required this.movingTabIds,
    required this.previousTabId,
    required this.nextTabId,
    this.scopeChange = const TabScopeChange.unchanged(),
  });
}

/// Builds the reorder/rescope request implied by dragging
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
/// tab's current folder — otherwise `TabScopeChange.unchanged()`.
TabViewReorderResult? buildTabViewReorderResult({
  required List<TabViewItem> visibleItems,
  required Set<String> pinnedTabIds,
  required int oldIndex,
  required int newIndex,
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
  // with it, in splitIndex order.
  final movingSplitSiblings = (splitMembers[movingItem.tabId] ?? const [])
      .where((tabId) => tabId != movingItem.tabId)
      .toList();

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
      pinnedTabIds: pinnedTabIds,
      movingTabId: movingItem.tabId,
      sortPinnedFirst: sortPinnedFirst,
    ),
    scopeChange: scopeChange,
  );
}

List<String> _orderedIdsForStorageAnchors(
  List<String> orderedTabIds, {
  required Set<String> pinnedTabIds,
  required String movingTabId,
  required bool sortPinnedFirst,
}) {
  if (!sortPinnedFirst || pinnedTabIds.isEmpty) {
    return orderedTabIds;
  }

  // Pinned-first is a render-only partition, so choose DB anchors only from
  // the moving tab's own partition to avoid snapping across the boundary.
  final movingPinned = pinnedTabIds.contains(movingTabId);
  return orderedTabIds
      .where((tabId) => pinnedTabIds.contains(tabId) == movingPinned)
      .toList();
}

TabViewReorderResult? _resultFromOrderedIds({
  required List<String> movingTabIds,
  required List<String> orderedTabIds,
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
