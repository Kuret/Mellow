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

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_reorderable_grid_view/widgets/custom_draggable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nullability/nullability.dart';
import 'package:weblibre/core/providers/global_drop.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/data/models/drag_data.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_list_scope.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/utils/close_tab_helper.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/utils/tab_view_reorder.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/draggable_scrollable_header.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/compact_tab_row.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/split_badge.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/tab_context_menu_draggable.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/tab_drop_target.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/tab_preview.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/tab_view_header.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/tab_view_item.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/container_filter.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_entity.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/folder.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/tab_search.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/essentials_grid.dart';
import 'package:weblibre/features/sync/domain/repositories/sync.dart';
import 'package:weblibre/presentation/widgets/reorderable_hold_drag.dart';

/// Plain list row for a [TabListFolderItem]: icon, name, child count,
/// collapse toggle and folder-depth indentation. Tap and the toggle both
/// collapse/expand; long-press opens rename/delete.
class _FolderRow extends ConsumerWidget {
  final TabListFolderItem folderItem;
  final double height;

  const _FolderRow({required this.folderItem, required this.height});

  Future<void> _showFolderMenu(BuildContext context, WidgetRef ref) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(folderItem.name.isEmpty ? 'Folder' : folderItem.name),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'rename'),
            child: const Text('Rename'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'delete'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'rename') {
      final nameController = TextEditingController(text: folderItem.name);
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Rename folder'),
          content: TextField(controller: nameController, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, nameController.text),
              child: const Text('Rename'),
            ),
          ],
        ),
      );

      if (name != null && name.isNotEmpty) {
        await ref
            .read(folderRepositoryProvider.notifier)
            .renameFolder(folderItem.folderId, name);
      }
    } else if (action == 'delete') {
      final count = await ref
          .read(folderRepositoryProvider.notifier)
          .countTabsInFolder(folderItem.folderId);

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete folder'),
          content: Text(
            "Delete '${folderItem.name.isEmpty ? 'Folder' : folderItem.name}'? "
            '$count tabs will be closed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed ?? false) {
        await ref
            .read(folderRepositoryProvider.notifier)
            .deleteFolder(folderItem.folderId);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void toggleCollapsed() {
      unawaited(
        ref
            .read(folderRepositoryProvider.notifier)
            .setCollapsed(folderItem.folderId, !folderItem.isCollapsed),
      );
    }

    return SizedBox(
      height: height,
      child: InkWell(
        onTap: toggleCollapsed,
        onLongPress: () => _showFolderMenu(context, ref),
        child: Padding(
          padding: EdgeInsets.only(left: 16.0 * folderItem.depth, right: 8.0),
          child: Row(
            children: [
              const Icon(MdiIcons.folderOutline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  folderItem.name.isEmpty ? 'Folder' : folderItem.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${folderItem.childCount}'),
              IconButton(
                icon: Icon(
                  folderItem.isCollapsed
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                ),
                onPressed: toggleCollapsed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabDraggable extends HookConsumerWidget {
  final String tabId;
  final String? sourceSearchQuery;
  final VoidCallback onClose;
  final double height;
  final int depth;

  /// Pinned-shelf rendering: a [CompactTabRow] instead of the preview card.
  final bool compact;
  final SplitMembership? split;

  const _TabDraggable({
    required this.tabId,
    required this.onClose,
    required this.height,
    this.sourceSearchQuery,
    this.depth = 0,
    this.compact = false,
    this.split,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeTab = ref.watch(selectedTabProvider);

    final dragData = ref.watch(
      willAcceptDropProvider.select((value) {
        final dragTabId = switch (value) {
          ContainerDropData() => value.tabId,
          DeleteDropData() => value.tabId,
          null => null,
        };

        return (dragTabId == tabId) ? value : null;
      }),
    );

    // Cache the tab widget to avoid rebuilding
    final tab = useMemoized(() {
      if (compact) {
        return CompactTabRow(
          key: ValueKey(tabId),
          tabId: tabId,
          isActive: tabId == activeTab,
          split: split,
          onTap: () async {
            //Close first to avoid rebuilds
            onClose();
            if (tabId != activeTab) {
              await ref.read(tabRepositoryProvider.notifier).selectTab(tabId);
            }
          },
          onClose: () => closeTabWithConfirmationAndUndo(context, ref, tabId),
        );
      }
      return SingleListTabPreview(
        key: ValueKey(tabId),
        tabId: tabId,
        activeTabId: activeTab,
        onClose: onClose,
        sourceSearchQuery: sourceSearchQuery,
        depth: depth,
        split: split,
      );
    }, [tabId, activeTab, depth, compact, split]);

    return switch (dragData) {
      ContainerDropData() => Opacity(
        opacity: 0.3,
        child: Transform.scale(
          scale: 0.9,
          child: SizedBox(
            height: height,
            width: MediaQuery.of(context).size.width,
            child: tab,
          ),
        ),
      ),
      DeleteDropData() => Opacity(
        opacity: 0.3,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(colorScheme.error, BlendMode.modulate),
          child: tab,
        ),
      ),
      null => tab,
    };
  }
}

/// One row of the sectioned tray list: a shelf header or a tab/folder row
/// (PLAN §6.4). Headers are rendered but never reordered; item rows keep
/// their index into the flat `primaryRows` the reorder logic works on.
sealed class _ShelfRow {
  const _ShelfRow();

  String get key;
}

class _ShelfHeaderRow extends _ShelfRow {
  final String title;

  /// The shelf a row dropped right below this header lands on.
  final TabShelf shelf;

  const _ShelfHeaderRow(this.title, this.shelf);

  @override
  String get key => 'shelf-header-${shelf.name}';
}

class _ShelfItemRow extends _ShelfRow {
  final TabViewItem item;
  final int primaryIndex;

  /// Whether the row sits in the pinned section and renders compact.
  final bool pinned;

  const _ShelfItemRow(this.item, this.primaryIndex, {required this.pinned});

  @override
  String get key => item.tabId;
}

class _TabListView extends HookConsumerWidget {
  final ScrollController scrollController;
  final bool tabsReorderable;
  final VoidCallback onClose;

  const _TabListView({
    required this.scrollController,
    required this.tabsReorderable,
    required this.onClose,
  });

  static const _itemHeight = 86.0;
  static const _pinnedRowHeight = CompactTabRow.defaultHeight + 4.0;
  static const _headerHeight = ShelfSectionHeader.height;

  static double _heightOf(_ShelfRow row) => switch (row) {
    _ShelfHeaderRow() => _headerHeight,
    _ShelfItemRow(:final pinned, :final item) =>
      pinned && !item.isFolder ? _pinnedRowHeight : _itemHeight,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(effectiveTabsTrayScopeProvider);

    return switch (scope) {
      TabsTrayScope.synced => _buildSyncedTabsView(context, ref),
      _ => _buildLocalTabsView(context, ref),
    };
  }

  Widget _buildSyncedTabsView(BuildContext context, WidgetRef ref) {
    final syncedTabs = ref.watch(syncedTabsForSelectedDeviceProvider);

    return syncedTabs.when(
      skipLoadingOnReload: true,
      data: (tabs) {
        if (tabs.isEmpty) {
          return const Center(child: Text('No synced tabs available'));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ListView.builder(
            controller: scrollController,
            itemCount: tabs.length,
            itemBuilder: (context, index) {
              final tab = tabs[index].tab;
              final uri = Uri.tryParse(tab.url);

              if (uri == null) {
                return const SizedBox.shrink();
              }

              return SyncedListTabPreview(
                title: tab.title.isNotEmpty ? tab.title : tab.url,
                url: uri,
                deviceName: tabs[index].deviceName,
                onTap: () async {
                  await OpenSharedContentRoute(
                    sharedUrl: uri.toString(),
                  ).push(context);
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Failed to load synced tabs: $error')),
    );
  }

  Widget _buildLocalTabsView(BuildContext context, WidgetRef ref) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final containerId = ref.watch(selectedContainerProvider);
    final spaceUuid = ref.watch(selectedSpaceProvider);
    final canManualReorder = ref.watch(canManualTabReorderProvider);
    final reorderEnabled = tabsReorderable && canManualReorder;
    final filterOptions = ref.watch(tabViewFilterControllerProvider);
    final pinnedTabIds = ref.watch(pinnedTabIdsProvider);
    // Reorder anchors: which folder (if any) each tab currently sits in, and
    // which tabs share a splitId, both derived from the same space-tabs
    // summaries the grouping provider already reads.
    final spaceTabSummaries = ref.watch(
      watchSpaceTabsDataProvider(
        spaceUuid,
      ).select((value) => value.value ?? const []),
    );
    final folderIdByTab = {
      for (final summary in spaceTabSummaries) summary.id: summary.folderId,
    };
    final splitMembers = <String, List<String>>{};
    final splitByTab = <String, SplitMembership>{};
    final membersBySplitId = <String, List<TabSummary>>{};
    for (final summary in spaceTabSummaries) {
      final splitId = summary.splitId;
      if (splitId == null) continue;
      membersBySplitId.putIfAbsent(splitId, () => []).add(summary);
    }
    for (final MapEntry(key: splitId, value: members)
        in membersBySplitId.entries) {
      members.sort((a, b) => (a.splitIndex ?? 0).compareTo(b.splitIndex ?? 0));
      final ids = [for (final member in members) member.id];
      for (final (index, id) in ids.indexed) {
        splitMembers[id] = ids;
        if (ids.length > 1) {
          splitByTab[id] = SplitMembership(
            splitId: splitId,
            index: index,
            count: ids.length,
          );
        }
      }
    }

    final hasActiveSearch = ref.watch(
      tabSearchRepositoryProvider(
        TabSearchPartition.preview,
      ).select((value) => (value.value?.query ?? '').isNotEmpty),
    );

    List<TabViewItem> primaryRows;
    if (hasActiveSearch) {
      final flat = ref.watch(
        seamlessFilteredTabEntitiesProvider(
          searchPartition: TabSearchPartition.preview,
          // ignore: document_ignores using fast equatable
          // ignore: provider_parameters
          containerFilter: ContainerFilterById(containerId: containerId),
        ),
      );
      primaryRows = [
        for (final entity in flat.value)
          TabViewItem.search(
            tabId: entity.tabId,
            sourceSearchQuery: switch (entity) {
              DefaultTabEntity _ => null,
              final SearchResultTabEntity e => e.searchQuery,
            },
          ),
      ];
    } else {
      final visibleItems = ref.watch(
        visibleTabListItemsProvider(
          spaceUuid: spaceUuid,
          scope: TabListScope.tray,
        ),
      );
      primaryRows = [
        for (final item in visibleItems.value)
          switch (item) {
            TabListTabItem(:final tabId, :final depth, :final shelf) =>
              TabViewItem.tab(tabId: tabId, depth: depth, shelf: shelf),
            final TabListFolderItem f => TabViewItem.folder(folderItem: f),
          },
      ];
    }

    // Section the list by shelf (PLAN §6.4): the pinned rows the grouping
    // provider already leads with become a compact "Pinned" section, the rest
    // the main list. Folders live in the pinned section too (their members
    // are pinned tabs). Search results are one flat list.
    final sectioned = !hasActiveSearch;
    var pinnedCount = 0;
    if (sectioned) {
      while (pinnedCount < primaryRows.length) {
        final row = primaryRows[pinnedCount];
        if (row.shelf != TabShelf.pinned && !row.isFolder) break;
        pinnedCount++;
      }
    }
    // While reordering, an empty pinned section still shows its header so a
    // row can be dragged into it.
    final showPinnedSection = sectioned && (pinnedCount > 0 || reorderEnabled);

    final displayRows = <_ShelfRow>[
      if (showPinnedSection) const _ShelfHeaderRow('Pinned', TabShelf.pinned),
      for (var i = 0; i < pinnedCount; i++)
        _ShelfItemRow(primaryRows[i], i, pinned: true),
      if (showPinnedSection) const _ShelfHeaderRow('Tabs', TabShelf.normal),
      for (var i = pinnedCount; i < primaryRows.length; i++)
        _ShelfItemRow(primaryRows[i], i, pinned: false),
    ];

    final itemCount = displayRows.length;
    final displayItemCount = itemCount;

    final activeTab = ref.watch(selectedTabProvider);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients && activeTab != null) {
          final index = displayRows.indexWhere(
            (row) => row is _ShelfItemRow && row.item.tabId == activeTab,
          );

          if (index > -1) {
            final viewportDimension =
                scrollController.position.viewportDimension;
            var tabStart = 0.0;
            for (var i = 0; i < index; i++) {
              tabStart += _heightOf(displayRows[i]);
            }
            final rowHeight = _heightOf(displayRows[index]);

            final targetOffset =
                (tabStart - viewportDimension / 2 + rowHeight / 2).clamp(
                  0.0,
                  scrollController.position.maxScrollExtent,
                );

            if (disableAnimations) {
              scrollController.jumpTo(targetOffset);
            } else {
              unawaited(
                scrollController.animateTo(
                  targetOffset,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                ),
              );
            }
          }
        }
      });

      return null;
    }, [activeTab, displayRows.length]);

    Widget buildHeader(_ShelfHeaderRow row) {
      return SizedBox(
        key: Key(row.key),
        height: _headerHeight,
        child: ShelfSectionHeader(title: row.title),
      );
    }

    Widget buildTabRow(_ShelfItemRow row) {
      final item = row.item;
      return _TabDraggable(
        tabId: item.tabId,
        onClose: onClose,
        sourceSearchQuery: item.sourceSearchQuery,
        height: _heightOf(row),
        depth: item.depth,
        compact: row.pinned,
        split: splitByTab[item.tabId],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: !reorderEnabled
          ? ListView.builder(
              padding: const EdgeInsets.only(bottom: 56),
              controller: scrollController,
              itemCount: displayItemCount,
              itemBuilder: (context, index) {
                final row = displayRows[index];
                switch (row) {
                  case _ShelfHeaderRow():
                    return buildHeader(row);
                  case _ShelfItemRow(:final item):
                    if (item.isFolder) {
                      return CustomDraggable(
                        key: Key(item.tabId),
                        child: _FolderRow(
                          folderItem: item.folderItem!,
                          height: _itemHeight,
                        ),
                      );
                    }

                    final tab = CustomDraggable(
                      key: Key(item.tabId),
                      data: TabDragData(item.tabId),
                      child: buildTabRow(row),
                    );

                    return TabDropTarget(
                      targetTabId: item.tabId,
                      child: TabContextMenuDraggable(
                        tabId: item.tabId,
                        data: tab.data! as TabDragData,
                        feedbackSize: Size(
                          MediaQuery.of(context).size.width,
                          _heightOf(row),
                        ),
                        child: tab.child,
                      ),
                    );
                }
              },
            )
          : ReorderableListView.builder(
              scrollController: scrollController,
              padding: const EdgeInsets.only(bottom: 56),
              itemCount: displayItemCount,
              // Drag handles are supplied per item so the drag arms later than
              // the long-press context menu, and so the non-reorderable
              // header rows don't get one at all.
              buildDefaultDragHandles: false,
              onReorderStart: (index) {
                ref.read(willAcceptDropProvider.notifier).clear();
              },
              onReorderItem: (oldIndex, newIndex) async {
                if (oldIndex >= displayRows.length) {
                  return;
                }
                final moving = displayRows[oldIndex];
                if (moving is! _ShelfItemRow) {
                  return;
                }

                // Display indices → the flat primary rows the reorder logic
                // walks: headers are skipped, and the shelf the drop lands on
                // is the nearest header above the slot.
                final remaining = displayRows.toList()..removeAt(oldIndex);
                final insertAt = newIndex.clamp(0, remaining.length);
                var primaryNewIndex = 0;
                TabShelf? targetShelf;
                for (var i = 0; i < insertAt; i++) {
                  switch (remaining[i]) {
                    case _ShelfItemRow():
                      primaryNewIndex++;
                    case _ShelfHeaderRow(:final shelf):
                      targetShelf = shelf;
                  }
                }

                var effectivePinnedTabIds = pinnedTabIds;
                final movingTabId = moving.item.tabId;
                if (showPinnedSection &&
                    targetShelf != null &&
                    !moving.item.isFolder &&
                    targetShelf != moving.item.shelf) {
                  // Crossing a section changes the shelf (PLAN §6.4). The row
                  // lands at the end of its new shelf; the reorder below then
                  // puts it where it was dropped.
                  final changed = await ref
                      .read(tabDataRepositoryProvider.notifier)
                      .setShelf(
                        movingTabId,
                        targetShelf,
                        activeSpaceUuid: spaceUuid,
                      );
                  if (!changed) return;
                  effectivePinnedTabIds = targetShelf == TabShelf.pinned
                      ? {...pinnedTabIds, movingTabId}
                      : ({...pinnedTabIds}..remove(movingTabId));
                }

                final result = buildTabViewReorderResult(
                  visibleItems: primaryRows,
                  pinnedTabIds: effectivePinnedTabIds,
                  oldIndex: moving.primaryIndex,
                  newIndex: primaryNewIndex,
                  sortPinnedFirst: filterOptions.sortPinnedFirst,
                  folderIdByTab: folderIdByTab,
                  splitMembers: splitMembers,
                  spaceUuid: spaceUuid,
                );

                if (result == null) return;

                await ref
                    .read(tabDataRepositoryProvider.notifier)
                    .reorderTabs(
                      movingTabIds: result.movingTabIds,
                      previousTabId: result.previousTabId,
                      nextTabId: result.nextTabId,
                      scopeChange: result.scopeChange,
                    );
              },
              itemBuilder: (context, index) {
                final row = displayRows[index];
                switch (row) {
                  case _ShelfHeaderRow():
                    return buildHeader(row);
                  case _ShelfItemRow(:final item):
                    if (item.isFolder) {
                      return CustomDraggable(
                        key: Key(item.tabId),
                        child: ReorderableHoldDragListener(
                          index: index,
                          enabled: false,
                          child: _FolderRow(
                            folderItem: item.folderItem!,
                            height: _itemHeight,
                          ),
                        ),
                      );
                    }

                    return CustomDraggable(
                      key: Key(item.tabId),
                      data: TabDragData(item.tabId),
                      child: ReorderableHoldDragListener(
                        index: index,
                        child: TabContextMenuDraggable(
                          tabId: item.tabId,
                          feedbackSize: Size.zero,
                          externalDrag: true,
                          child: buildTabRow(row),
                        ),
                      ),
                    );
                }
              },
            ),
    );
  }
}

class ViewTabListWidget extends HookConsumerWidget {
  final ScrollController scrollController;
  final DraggableScrollableController? draggableScrollableController;
  final bool showNewTabFab;
  final bool tabsReorderable;
  final VoidCallback onClose;

  static const _hideThreshold = 0.02; // 2% of sheet size change
  static const _showThreshold = 0.02;

  const ViewTabListWidget({
    required this.onClose,
    required this.scrollController,
    this.draggableScrollableController,
    required this.tabsReorderable,
    required this.showNewTabFab,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final isSyncedScope = ref.watch(
      effectiveTabsTrayScopeProvider.select(
        (scope) => scope == TabsTrayScope.synced,
      ),
    );

    final isFabVisible = useState(true);
    final lastSheetSize = useRef(0.0);
    final isInitialized = useRef(false);

    // Delay initialization to ignore initial animations
    useEffect(() {
      final timer = Timer(
        disableAnimations ? Duration.zero : const Duration(milliseconds: 500),
        () {
          isInitialized.value = true;
          // Initialize lastSheetSize with current size
          if (draggableScrollableController?.isAttached == true) {
            lastSheetSize.value = draggableScrollableController!.size;
          }
        },
      );
      return timer.cancel;
    }, [disableAnimations]);

    // Listen to DraggableScrollableController for sheet size changes
    useEffect(() {
      final controller = draggableScrollableController;
      if (controller == null) return null;

      void listener() {
        if (!isInitialized.value) return;
        if (!controller.isAttached) return;

        final currentSize = controller.size;
        final difference = currentSize - lastSheetSize.value;

        // Hide when sheet expands (dragging up / scrolling down)
        if (difference > _hideThreshold && isFabVisible.value) {
          isFabVisible.value = false;
        }
        // Show when sheet collapses (dragging down / scrolling up)
        else if (difference < -_showThreshold && !isFabVisible.value) {
          isFabVisible.value = true;
        }

        lastSheetSize.value = currentSize;
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [draggableScrollableController]);

    // Fallback: Also listen to scroll controller for fullscreen mode (no draggable sheet)
    useEffect(() {
      if (draggableScrollableController != null) return null;

      var lastOffset = 0.0;
      void listener() {
        if (!isInitialized.value) return;

        final currentOffset = scrollController.offset;
        final difference = currentOffset - lastOffset;

        if (difference > 10.0 && isFabVisible.value) {
          isFabVisible.value = false;
        } else if ((difference < -10.0 || currentOffset <= 0) &&
            !isFabVisible.value) {
          isFabVisible.value = true;
        }

        lastOffset = currentOffset;
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController, draggableScrollableController]);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        NestedScrollView(
          physics: const NeverScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child:
                  draggableScrollableController.mapNotNull(
                    (draggableScrollableController) =>
                        DraggableScrollableHeader(
                          controller: draggableScrollableController,
                          child: TabViewHeader(
                            onClose: onClose,
                            tabsViewMode: TabsViewMode.list,
                          ),
                        ),
                  ) ??
                  TabViewHeader(
                    onClose: onClose,
                    tabsViewMode: TabsViewMode.list,
                  ),
            ),
          ],
          // The Essentials shelf is pinned above the scrolling list, the way
          // Zen keeps its strip at the top of the sidebar (PLAN §6.4): its
          // own slot in the body, outside the list's scrollable, so the
          // "Pinned" and "Tabs" sections scroll under it.
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A tile the size of a list row's favicon block, not the big
              // square the strip used to stretch to.
              if (!isSyncedScope)
                EssentialsGrid(onSelected: onClose, tileSize: 40),
              Expanded(
                child: _TabListView(
                  scrollController: scrollController,
                  tabsReorderable: tabsReorderable,
                  onClose: onClose,
                ),
              ),
            ],
          ),
        ),
        if (showNewTabFab && !isSyncedScope)
          AnimatedSlide(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 200),
            offset: isFabVisible.value ? Offset.zero : const Offset(0, 2),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              opacity: isFabVisible.value ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: TabViewHeader.headerSize + 4,
                  right: 4,
                ),
                child: FloatingActionButton.small(
                  onPressed: () async {

                    await SearchRoute(
                      tabType:
                          ref.read(selectedTabTypeProvider) ??
                          TabType.regular,
                    ).push(context);

                    onClose();
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
