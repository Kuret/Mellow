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
import 'dart:math' as math;

import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/domain/providers/restore_complete.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/browser/domain/entities/tab_list_scope.dart';
import 'package:mellow/features/geckoview/features/browser/domain/entities/tab_presence.dart';
import 'package:mellow/features/geckoview/features/browser/domain/providers.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/controllers/compact_bar_expanded_folders.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/utils/close_tab_helper.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/browser_modules/quick_tab_switcher_chip.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_entity.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_summary.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/entities/container_cycle.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/essentials_grid.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/space_indicator.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/space_swipe.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/zen_settings.dart';
import 'package:mellow/presentation/hooks/scroll_to_active_chip.dart';
import 'package:mellow/presentation/widgets/inline_count_badge.dart';

/// The narrow-viewport tab bar: one [height] row for the current space. The
/// fixed [SpaceIndicator] sits at one edge — the leading edge by default, the
/// trailing one when [ZenSettings.spaceIndicatorSide] is
/// [SpaceIndicatorSide.right], for a right-handed grip; the rest of the row,
/// scrolling horizontally, is the Essentials as icon chips, a thin divider,
/// then the pinned tabs, folders and normal tabs as chips in `order_key`
/// order — a folder as a chip that shows its contents inline while it is
/// expanded ([compactBarExpandedFoldersProvider]): its tabs and a chip per
/// subfolder, which opens the same way. The selected tab is highlighted and
/// kept in view.
///
/// Spaces are switched by swiping the indicator, by overscrolling the chip
/// strip past either end, or from the quick menu a tap on the indicator
/// opens — all independent of which side of the row the indicator sits on.
class CompactTabBar extends ConsumerWidget {
  const CompactTabBar({super.key});

  /// Height of the bar; the quick tab switcher row it replaces was 48 too.
  static const height = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceUuid = ref.watch(selectedSpaceProvider);
    final spaceIndicatorSide = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.spaceIndicatorSide),
    );

    const indicator = SpaceIndicator();
    final chipStrip = Expanded(
      child: SpaceSlide(
        spaceUuid: spaceUuid,
        child: _CompactChipStrip(spaceUuid: spaceUuid),
      ),
    );

    return SizedBox(
      height: height,
      child: Row(
        children: switch (spaceIndicatorSide) {
          SpaceIndicatorSide.left => [indicator, chipStrip],
          SpaceIndicatorSide.right => [chipStrip, indicator],
        },
      ),
    );
  }
}

/// Edge length of an Essentials icon chip on the bar.
const compactEssentialSize = 32.0;

sealed class _Entry {
  const _Entry();

  String get id;
}

class _EssentialEntry extends _Entry {
  final String tabId;

  const _EssentialEntry(this.tabId);

  @override
  String get id => 'essential-$tabId';
}

class _DividerEntry extends _Entry {
  const _DividerEntry();

  @override
  String get id => 'divider';
}

class _FolderEntry extends _Entry {
  final TabListFolderItem folder;
  final bool expanded;

  /// How many expanded folder chips the strip is inside of: `0` for a folder
  /// of the space itself, `1` for a subfolder of an expanded folder, and so
  /// on. A single row has no room to indent, so the chip wears the depth as
  /// leading chevrons instead.
  final int depth;

  const _FolderEntry(this.folder, {required this.expanded, this.depth = 0});

  @override
  String get id => 'folder-${folder.folderId}';
}

class _TabEntry extends _Entry {
  final QuickTabSwitcherItem item;

  /// How many expanded folders this tab sits inside; `0` for a tab of the
  /// space itself. Drives the band the strip draws behind a folder's
  /// contents — on one row there is nowhere to indent, so the band is the
  /// only thing that says where a folder ends and the space resumes.
  final int depth;

  const _TabEntry(this.item, {this.depth = 0});

  @override
  String get id => 'tab-${item.id}';
}

/// A folder the strip is currently inside of while walking the grouped
/// order, and whether its members are shown.
typedef _OpenFolder = ({String id, int depth, bool visible});

class _CompactChipStrip extends HookConsumerWidget {
  final String? spaceUuid;

  const _CompactChipStrip({required this.spaceUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(generalSettingsWithDefaultsProvider);
    final titleMaxWidth = settings.quickTabSwitcherTitleWidth;
    const closeButtonMode = TabChipCloseButtonMode.activeTabOnly;

    final selectedTabId = ref.watch(selectedTabProvider);
    final essentialIds = watchEssentialShelfTabIds(ref) ?? const <String>[];
    // Storage order, like the desktop sidebar and the wide rail: the chips
    // mirror the space, they do not reorder by recency.
    final items = ref
        .watch(
          groupedTabListItemsProvider(
            spaceUuid: spaceUuid,
            scope: TabListScope.presentation,
          ),
        )
        .value;
    final stateById = {
      for (final state
          in ref.watch(spaceTabStatesWithContainerProvider(spaceUuid)).value)
        state.$1.id: state,
    };
    // Members of a folder collapsed in storage are absent from the grouped
    // order — its subfolders with them — so the bar reads both from the
    // space's own rows when it expands one.
    final spaceTabs =
        ref.watch(
          watchSpaceTabsDataProvider(spaceUuid).select((value) => value.value),
        ) ??
        const <TabSummary>[];
    final spaceFolders =
        ref.watch(
          watchFoldersProvider(spaceUuid).select((value) => value.value),
        ) ??
        const <TabFolderData>[];
    final expandedFolders = ref.watch(compactBarExpandedFoldersProvider);

    final pinnedTabIds = ref.watch(pinnedTabIdsProvider);
    final restoreComplete = ref.watch(browserRestoreCompleteProvider);
    final nativeTabIds = ref
        .watch(
          tabStatesProvider.select(
            (states) => EquatableValue(states.keys.toSet()),
          ),
        )
        .value;
    final coldTabIds =
        ref
            .watch(watchColdTabIdsProvider.select((value) => value.value))
            ?.value ??
        const <String>{};
    _TabEntry? tabEntry(String tabId, {int depth = 0}) {
      final state = stateById[tabId];
      if (state == null) {
        return null;
      }
      return _TabEntry(
        QuickTabSwitcherItem.tab(
          state,
          selectedTabId: selectedTabId,
          pinnedTabIds: pinnedTabIds,
          presence: nativeTabIds.contains(tabId)
              ? TabPresence.live
              : coldTabIds.contains(tabId) || restoreComplete
              ? TabPresence.cold
              : TabPresence.restoring,
        ),
        depth: depth,
      );
    }

    final entries = <_Entry>[
      for (final tabId in essentialIds) _EssentialEntry(tabId),
    ];
    final tabEntries = <_Entry>[];

    // Everything the strip needs about a folder that the grouped order does
    // not carry, straight off the space's rows.
    List<TabSummary> tabsDirectlyIn(String folderId) => [
      for (final tab in spaceTabs)
        if (tab.folderId == folderId) tab,
    ];
    List<TabFolderData> subfoldersOf(String folderId) => [
      for (final folder in spaceFolders)
        if (folder.parentFolderId == folderId) folder,
    ];
    int tabsInFolder(String folderId, [Set<String>? seen]) {
      final visited = seen ?? <String>{};
      if (!visited.add(folderId)) {
        return 0;
      }
      var count = tabsDirectlyIn(folderId).length;
      for (final child in subfoldersOf(folderId)) {
        count += tabsInFolder(child.id, visited);
      }
      return count;
    }

    List<String> descendantFolderIds(String folderId, [Set<String>? seen]) {
      final visited = seen ?? <String>{folderId};
      final ids = <String>[];
      for (final child in subfoldersOf(folderId)) {
        if (!visited.add(child.id)) {
          continue;
        }
        ids
          ..add(child.id)
          ..addAll(descendantFolderIds(child.id, visited));
      }
      return ids;
    }

    // The contents of a folder the grouped order left out: its tabs and its
    // subfolders in one `order_key` sequence, each subfolder opening the
    // same way under its own id.
    void addFolderContents(String folderId, int depth, Set<String> seen) {
      if (!seen.add(folderId)) {
        return;
      }
      final slots =
          <({String orderKey, TabSummary? tab, TabFolderData? folder})>[
            for (final tab in tabsDirectlyIn(folderId))
              (orderKey: tab.orderKey, tab: tab, folder: null),
            for (final folder in subfoldersOf(folderId))
              (orderKey: folder.orderKey, tab: null, folder: folder),
          ]..sort((a, b) => a.orderKey.compareTo(b.orderKey));
      for (final slot in slots) {
        final folder = slot.folder;
        if (folder == null) {
          final entry = tabEntry(slot.tab!.id, depth: depth);
          if (entry != null) {
            tabEntries.add(entry);
          }
          continue;
        }
        final expanded = expandedFolders.contains(folder.id);
        tabEntries.add(
          _FolderEntry(
            TabListFolderItem(
              folderId: folder.id,
              orderKey: folder.orderKey,
              spaceUuid: spaceUuid,
              name: folder.name,
              isCollapsed: folder.isCollapsed,
              depth: depth,
              childCount: tabsInFolder(folder.id),
            ),
            expanded: expanded,
            depth: depth,
          ),
        );
        if (expanded) {
          addFolderContents(folder.id, depth + 1, seen);
        }
      }
    }

    // The grouped order nests folder members under their folder by depth;
    // the strip walks it with a stack of the folders it is inside of, and
    // skips the members of any that is not expanded here.
    final openFolders = <_OpenFolder>[];
    for (final item in items) {
      while (openFolders.isNotEmpty && openFolders.last.depth >= item.depth) {
        openFolders.removeLast();
      }
      final hidden = openFolders.any((folder) => !folder.visible);
      switch (item) {
        case TabListFolderItem():
          final expanded = expandedFolders.contains(item.folderId);
          final chipDepth = openFolders.length;
          if (!hidden) {
            tabEntries.add(
              _FolderEntry(item, expanded: expanded, depth: chipDepth),
            );
          }
          openFolders.add((
            id: item.folderId,
            depth: item.depth,
            visible: !hidden && expanded,
          ));
          // A folder collapsed in storage brought nothing with it: the strip
          // fills in its tabs and subfolders itself.
          if (!hidden && expanded && item.isCollapsed) {
            addFolderContents(item.folderId, chipDepth + 1, <String>{});
          }
        case TabListTabItem():
          if (hidden) {
            continue;
          }
          final entry = tabEntry(item.tabId, depth: openFolders.length);
          if (entry != null) {
            tabEntries.add(entry);
          }
      }
    }
    if (entries.isNotEmpty && tabEntries.isNotEmpty) {
      entries.add(const _DividerEntry());
    }
    entries.addAll(tabEntries);

    final scrollController = useScrollController();
    final activeChipKey = useRef(GlobalKey());
    // Expanding a folder inserts its contents to the right of the chip,
    // usually past the edge of the strip: without this the bar looks like it
    // did nothing until you scroll. The opened folder is pulled to the
    // leading edge so its contents fill the view.
    final openedFolderId = useState<String?>(null);
    // Expanding a folder shifts the selected tab's index, which is a change
    // `useScrollToActiveChip` reads as "the active chip moved, re-centre it"
    // — snapping the strip away from the folder the user just tapped. A
    // toggle is the user driving the strip, so it counts as user scrolling
    // for as long as it takes to settle.
    final folderToggleGuard = useRef(false);
    // One stable key per folder, never swapped in and out: a key that
    // appeared only while a folder was pending re-created the chip's
    // element, and an in-flight tap died with it.
    final folderKeys = useRef(<String, GlobalKey>{});
    final isUserScrolling = useRef(false);
    final userScrollTimer = useRef<Timer?>(null);
    final overscrollDistance = useRef(0.0);

    useEffect(() {
      return userScrollTimer.value?.cancel;
    }, []);

    final activeEntryId = 'tab-$selectedTabId';
    final hasActiveEntry = entries.any((entry) => entry.id == activeEntryId);

    useEffect(() {
      final folderId = openedFolderId.value;
      if (folderId == null) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = folderKeys.value[folderId]?.currentContext;
        final box = context?.findRenderObject();
        if (box is RenderBox && scrollController.hasClients) {
          // The strip stays where it is: a tap on a folder is not a request
          // to go somewhere else. The one exception is a folder sitting so
          // far right that its contents open past the edge — then it moves
          // just far enough to make room for them, never flush against the
          // edge (a chip exactly on the boundary stops taking taps).
          const inset = 12.0;
          const roomForContents = 96.0;
          final position = scrollController.position;
          final viewport = RenderAbstractViewport.of(box);
          final reveal = viewport.getOffsetToReveal(box, 0.0).offset;
          final chipEnd =
              viewport.getOffsetToReveal(box, 1.0).offset +
              position.viewportDimension;
          final roomAfterChip =
              position.pixels + position.viewportDimension - chipEnd;
          final target = (reveal - inset).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          );
          if (roomAfterChip < roomForContents &&
              (target - position.pixels).abs() > 1.0) {
            unawaited(
              scrollController.animateTo(
                target,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              ),
            );
          }
        }
        folderToggleGuard.value = false;
        openedFolderId.value = null;
      });
      return null;
    }, [openedFolderId.value]);

    useScrollToActiveChip<String>(
      controller: scrollController,
      activeChipKey: activeChipKey.value,
      activeId: hasActiveEntry ? activeEntryId : null,
      orderedIds: [for (final entry in entries) entry.id],
      isUserScrolling: () => isUserScrolling.value || folderToggleGuard.value,
    );

    final decoration = buildQuickTabSwitcherChipDecoration(context);

    Widget buildTabChip(QuickTabSwitcherItem item) {
      final canClose =
          !item.isRestoring &&
          closeButtonMode.showsFor(isActive: item.isActive);
      final chip = QuickTabSwitcherChip(
        item: item,
        isSelected: item.isActive,
        selectedBorderColor: Theme.of(context).colorScheme.primary,
        decoration: decoration,
        label: buildQuickTabSwitcherChipLabel(
          context,
          item,
          isSelected: item.isActive,
          titleMaxWidth: titleMaxWidth,
        ),
        padding: const EdgeInsets.only(right: 8.0),
        onTap: () async {
          if (item.isActive) {
            return;
          }
          await ref.read(tabRepositoryProvider.notifier).selectTab(item.id);
        },
        onDelete: canClose
            ? () => closeTabWithConfirmationAndUndo(context, ref, item.id)
            : null,
      );
      return wrapQuickTabSwitcherChipWithMenu(
        itemId: item.id,
        enabled: !item.isRestoring,
        enablePinTab: true,
        child: chip,
      );
    }

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No tabs in this space',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        switch (notification) {
          case UserScrollNotification(:final direction):
            userScrollTimer.value?.cancel();
            isUserScrolling.value = direction != ScrollDirection.idle;
            userScrollTimer.value = Timer(
              const Duration(milliseconds: 1500),
              () => isUserScrolling.value = false,
            );
          case ScrollStartNotification():
            overscrollDistance.value = 0.0;
          // Only a finger dragging past the edge counts; a fling that hits
          // the end settles without a drag and should not change spaces.
          case OverscrollNotification(dragDetails: != null, :final overscroll):
            overscrollDistance.value += overscroll;
          case ScrollEndNotification():
            final distance = overscrollDistance.value;
            overscrollDistance.value = 0.0;
            if (distance.abs() >= spaceSwipeCommitDistance) {
              // Past the trailing end (positive) the next space is over
              // there; past the leading end the previous one.
              cycleSelectedSpace(
                ref,
                distance > 0
                    ? ContainerCycleDirection.next
                    : ContainerCycleDirection.previous,
              );
            }
          default:
            break;
        }
        return false;
      },
      // A folder's contents get a tinted band behind them, rounded at both
      // ends. The row has nowhere to indent, so without it an expanded
      // folder's tabs run straight into the space's own and there is nothing
      // to say where the folder stopped.
      child: ListView.builder(
        key: PageStorageKey('compact_tab_bar_$spaceUuid'),
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        // Always draggable, so a space with a handful of chips still
        // reports the overscroll that switches spaces.
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        scrollCacheExtent: const ScrollCacheExtent.pixels(500),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          Key entryKey(_Entry entry) => entry.id == activeEntryId
              ? activeChipKey.value
              : entry is _FolderEntry
              ? folderKeys.value.putIfAbsent(
                  entry.folder.folderId,
                  GlobalKey.new,
                )
              : ValueKey(entry.id);
          final child = switch (entry) {
            _EssentialEntry(:final tabId) => Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Center(
                child: SizedBox.square(
                  dimension: compactEssentialSize,
                  child: EssentialTile(tabId: tabId),
                ),
              ),
            ),
            _DividerEntry() => const Padding(
              padding: EdgeInsets.only(left: 2.0, right: 6.0),
              child: VerticalDivider(width: 1, indent: 12, endIndent: 12),
            ),
            _FolderEntry(:final folder, :final expanded, :final depth) =>
              Center(
                child: CompactFolderChip(
                  name: folder.name,
                  childCount: folder.childCount,
                  expanded: expanded,
                  depth: depth,
                  onTap: () {
                    ref
                        .read(compactBarExpandedFoldersProvider.notifier)
                        .toggle(
                          folder.folderId,
                          // Collapsing takes its open subfolders with it.
                          descendants: descendantFolderIds(folder.folderId),
                        );
                    folderToggleGuard.value = true;
                    // Only on the way open: collapsing leaves the strip
                    // where the user left it.
                    openedFolderId.value = expanded ? null : folder.folderId;
                    if (expanded) {
                      // Nothing pending to settle, so lift the guard after
                      // this frame's effects have run.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        folderToggleGuard.value = false;
                      });
                    }
                  },
                ),
              ),
            _TabEntry(:final item) => Center(child: buildTabChip(item)),
          };

          // How deep inside expanded folders this entry sits. An expanded
          // folder chip opens the band its members continue.
          int bandDepth(int i) {
            if (i < 0 || i >= entries.length) return 0;
            return switch (entries[i]) {
              _FolderEntry(:final expanded, :final depth) =>
                expanded ? depth + 1 : depth,
              _TabEntry(:final depth) => depth,
              _ => 0,
            };
          }

          final depth = bandDepth(index);
          if (depth > 0) {
            final scheme = Theme.of(context).colorScheme;
            const radius = Radius.circular(14.0);
            final opensHere = bandDepth(index - 1) < depth;
            final closesHere = bandDepth(index + 1) < depth;
            // The chips are neutral greys, so a grey band disappears behind
            // them. The band takes the accent hue instead — faint enough to
            // stay a background, different enough in hue to read at a
            // glance — and the group is capped at both ends by a solid
            // accent bar, which is what actually says "the folder stops
            // here". A folder inside a folder deepens the same hue rather
            // than introducing a second one.
            final accent = scheme.primary;
            final band = accent.withValues(alpha: depth > 1 ? 0.26 : 0.16);
            // A solid bar at each end of the group: the band says these
            // chips belong together, the bars say exactly where it stops.
            Widget cap() => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 6.0,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(2.0),
                ),
                child: const SizedBox(width: 3.0),
              ),
            );
            return KeyedSubtree(
              key: entryKey(entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: band,
                    borderRadius: BorderRadius.horizontal(
                      left: opensHere ? radius : Radius.zero,
                      right: closesHere ? radius : Radius.zero,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (opensHere) cap(),
                      child,
                      if (closesHere) cap(),
                    ],
                  ),
                ),
              ),
            );
          }
          return KeyedSubtree(key: entryKey(entry), child: child);
        },
      ),
    );
  }
}

/// A folder on the compact bar: the folder glyph (open while [expanded]),
/// its name and how many tabs it holds. Tapping shows or hides its contents,
/// which follow it inline — tab chips and a chip per subfolder, in
/// `order_key` order.
///
/// A single row cannot indent, so a subfolder wears its [depth] as leading
/// chevrons ("› Child", "›› Grandchild"): the chip reads as belonging to the
/// expanded folder chip in front of it.
class CompactFolderChip extends StatelessWidget {
  final String name;
  final int childCount;
  final bool expanded;

  /// Folder nesting below the strip's own root, drawn as leading chevrons.
  final int depth;

  final VoidCallback? onTap;

  /// Chevrons a chip shows at most, however deep the folder sits.
  static const maxDepthGlyphs = 3;

  const CompactFolderChip({
    super.key,
    required this.name,
    required this.childCount,
    required this.expanded,
    this.depth = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        avatar: Icon(
          expanded ? MdiIcons.folderOpenOutline : MdiIcons.folderOutline,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (depth > 0)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Text(
                  '\u203a' * math.min(depth, maxDepthGlyphs),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            Flexible(
              child: Text(
                name.isEmpty ? 'Folder' : name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (childCount > 0) ...[
              const SizedBox(width: 6),
              InlineCountBadge(
                count: childCount,
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
              ),
            ],
          ],
        ),
        selected: expanded,
        showCheckmark: false,
        tooltip: expanded ? 'Hide folder contents' : 'Show folder contents',
        onSelected: onTap == null ? null : (_) => onTap!(),
      ),
    );
  }
}
