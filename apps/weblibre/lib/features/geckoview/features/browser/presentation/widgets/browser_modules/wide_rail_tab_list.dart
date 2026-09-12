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

import 'package:collection/collection.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_list_scope.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_presence.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/utils/close_tab_helper.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/quick_tab_switcher_chip.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/cold_tab_badge.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_icon.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/compact_tab_row.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_entity.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/folder.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/essentials_grid.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/presentation/hooks/scroll_to_active_chip.dart';
import 'package:weblibre/presentation/widgets/inline_count_badge.dart';

/// The selected space's three shelves (PLAN §6.4) as full-width rows on the
/// wide vertical rail: the Essentials icon grid, the pinned tabs as compact
/// rows, then the main list with folder headers and their members indented
/// by depth. Scrolls along the rail and keeps the active tab in view.
///
/// Reordering is left to the tab tray, which already has the drag targets;
/// the rail only switches, closes (per [TabChipCloseButtonMode]) and offers
/// the long-press tab menu.
class WideRailTabList extends HookConsumerWidget {
  const WideRailTabList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSpaceUuid = ref.watch(selectedSpaceProvider);
    final selectedTabId = ref.watch(selectedTabProvider);
    final closeButtonMode = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.quickTabSwitcherCloseButtonMode,
      ),
    );
    final items = ref
        .watch(
          visibleTabListItemsProvider(
            spaceUuid: selectedSpaceUuid,
            scope: TabListScope.presentation,
          ),
        )
        .value;
    final hasEssentials =
        (watchEssentialShelfTabIds(ref) ?? const <String>[]).isNotEmpty;

    // Tabs the shared order does not list yet (pre-restore placeholders)
    // still get a row, as they get a chip on the quick tab switcher.
    final spaceTabIds = ref
        .watch(
          selectedSpaceTabStatesWithContainerProvider.select(
            (value) =>
                EquatableValue([for (final state in value.value) state.$1.id]),
          ),
        )
        .value;

    final pinned = <_RailEntry>[];
    final normal = <_RailEntry>[];
    final seen = <String>{};
    for (final item in items) {
      switch (item) {
        case TabListFolderItem():
          normal.add(_RailFolderEntry(item));
        case TabListTabItem():
          seen.add(item.tabId);
          (item.shelf == TabShelf.pinned ? pinned : normal).add(
            _RailTabEntry(item),
          );
      }
    }
    for (final tabId in spaceTabIds) {
      if (seen.add(tabId)) {
        normal.add(
          _RailTabEntry(
            TabListStandaloneItem(
              tabId: tabId,
              orderKey: '',
              spaceUuid: selectedSpaceUuid,
            ),
          ),
        );
      }
    }
    final entries = <_RailEntry>[
      if (hasEssentials) const _RailEssentialsEntry(),
      if (pinned.isNotEmpty) const _RailLabelEntry('Pinned'),
      ...pinned,
      if (pinned.isNotEmpty || hasEssentials) const _RailLabelEntry('Tabs'),
      ...normal,
    ];

    final scrollController = useScrollController();
    final activeRowKey = useRef(GlobalKey());
    final isUserScrolling = useRef(false);
    final userScrollTimer = useRef<Timer?>(null);

    useEffect(() {
      return userScrollTimer.value?.cancel;
    }, []);

    final activeEntryId = 'tab-$selectedTabId';
    final hasActiveEntry = entries.any((entry) => entry.id == activeEntryId);

    useScrollToActiveChip<String>(
      controller: scrollController,
      activeChipKey: activeRowKey.value,
      activeId: hasActiveEntry ? activeEntryId : null,
      orderedIds: [for (final entry in entries) entry.id],
      isUserScrolling: () => isUserScrolling.value,
    );

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        userScrollTimer.value?.cancel();
        isUserScrolling.value = notification.direction != ScrollDirection.idle;
        userScrollTimer.value = Timer(const Duration(milliseconds: 1500), () {
          isUserScrolling.value = false;
        });
        return false;
      },
      child: ListView.builder(
        key: const PageStorageKey('wide_rail_tab_list'),
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final child = switch (entry) {
            _RailEssentialsEntry() => const EssentialsGrid(
              showHeader: false,
              tileSize: 40,
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
            _RailLabelEntry(:final label) => ShelfSectionHeader(title: label),
            _RailFolderEntry(:final folder) => WideRailFolderRow(
              folder: folder,
            ),
            _RailTabEntry(:final item) => _RailTabRow(
              item: item,
              isActive: item.tabId == selectedTabId,
              closeButtonMode: closeButtonMode,
            ),
          };
          return KeyedSubtree(
            key: entry.id == activeEntryId
                ? activeRowKey.value
                : ValueKey(entry.id),
            child: child,
          );
        },
      ),
    );
  }
}

sealed class _RailEntry {
  const _RailEntry();

  String get id;
}

class _RailEssentialsEntry extends _RailEntry {
  const _RailEssentialsEntry();

  @override
  String get id => 'essentials';
}

class _RailLabelEntry extends _RailEntry {
  final String label;

  const _RailLabelEntry(this.label);

  @override
  String get id => 'label-$label';
}

class _RailFolderEntry extends _RailEntry {
  final TabListFolderItem folder;

  const _RailFolderEntry(this.folder);

  @override
  String get id => 'folder-${folder.folderId}';
}

class _RailTabEntry extends _RailEntry {
  final TabListTabItem item;

  const _RailTabEntry(this.item);

  @override
  String get id => 'tab-${item.tabId}';
}

/// One tab row of the rail: the tray's [CompactTabRow] on the pinned shelf,
/// [WideRailTabRow] on the main list. Both switch on tap, close per
/// [closeButtonMode] and carry the long-press tab menu.
class _RailTabRow extends ConsumerWidget {
  final TabListTabItem item;
  final bool isActive;
  final TabChipCloseButtonMode closeButtonMode;

  const _RailTabRow({
    required this.item,
    required this.isActive,
    required this.closeButtonMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabId = item.tabId;
    final presence = ref.watch(tabPresenceProvider(tabId));
    final canClose =
        presence != TabPresence.restoring &&
        closeButtonMode.showsFor(isActive: isActive);

    Future<void> select() async {
      if (isActive) return;
      await ref.read(tabRepositoryProvider.notifier).selectTab(tabId);
    }

    void close() {
      unawaited(closeTabWithConfirmationAndUndo(context, ref, tabId));
    }

    final (depth, childCount) = switch (item) {
      TabListStandaloneItem(:final depth) => (depth, 0),
      TabListParentGroup(:final depth, :final childCount) => (
        depth,
        childCount,
      ),
      TabListChildItem(:final depth, :final childCount) => (depth, childCount),
    };

    final row = item.shelf == TabShelf.pinned
        ? CompactTabRow(
            tabId: tabId,
            isActive: isActive,
            onTap: () => unawaited(select()),
            onClose: canClose ? close : null,
          )
        : WideRailTabRow(
            tabId: tabId,
            isActive: isActive,
            depth: depth,
            childCount: childCount,
            onTap: () => unawaited(select()),
            onClose: canClose ? close : null,
          );

    return wrapQuickTabSwitcherChipWithMenu(
      itemId: tabId,
      enabled: presence != TabPresence.restoring,
      enablePinTab: true,
      child: row,
    );
  }
}

/// A main-list row on the wide rail, resolved from the tab's state.
class WideRailTabRow extends ConsumerWidget {
  final String tabId;
  final bool isActive;

  /// Folder (and tree) nesting depth, drawn as a left inset.
  final int depth;

  /// Number of tree children under this tab, shown as a badge when > 0.
  final int childCount;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const WideRailTabRow({
    super.key,
    required this.tabId,
    required this.isActive,
    this.depth = 0,
    this.childCount = 0,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The same source the quick tab switcher draws from: live states for
    // native tabs, placeholders (title from the database row) for cold and
    // restoring ones.
    final tabState =
        ref.watch(
          selectedSpaceTabStatesWithContainerProvider.select(
            (value) => value.value
                .firstWhereOrNull((state) => state.$1.id == tabId)
                ?.$1,
          ),
        ) ??
        TabState.$default(tabId);
    final isCold = ref.watch(tabPresenceProvider(tabId)) == TabPresence.cold;

    return WideRailTabRowView(
      icon: TabIcon(tabState: tabState, iconSize: WideRailTabRowView.iconSize),
      title: tabState.titleOrAuthority,
      isActive: isActive,
      isCold: isCold,
      depth: depth,
      childCount: childCount,
      onTap: onTap,
      onClose: onClose,
    );
  }
}

/// Provider-free rendering of a [WideRailTabRow]: favicon, one line of
/// title, an optional child-count badge and close button. The active row is
/// filled with the secondary container color; a cold row is dimmed behind
/// the [ColdTabBadge].
class WideRailTabRowView extends StatelessWidget {
  final Widget icon;
  final String title;
  final bool isActive;
  final bool isCold;
  final int depth;
  final int childCount;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const WideRailTabRowView({
    super.key,
    required this.icon,
    required this.title,
    required this.isActive,
    this.isCold = false,
    this.depth = 0,
    this.childCount = 0,
    this.onTap,
    this.onClose,
  });

  static const height = 40.0;
  static const iconSize = 20.0;

  /// Left inset per nesting level.
  static const indentPerLevel = 16.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final leading = isCold ? ColdTabBadge(size: iconSize, child: icon) : icon;

    const radius = BorderRadius.all(Radius.circular(10));
    Widget row = Container(
      height: height,
      margin: EdgeInsets.fromLTRB(4 + indentPerLevel * depth, 1, 4, 1),
      decoration: BoxDecoration(
        color: isActive ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: radius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isActive
                          ? scheme.onSecondaryContainer
                          : scheme.onSurface,
                      fontWeight: isActive ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (childCount > 0) ...[
                  const SizedBox(width: 6),
                  InlineCountBadge(
                    count: childCount,
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                ],
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close tab',
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (isCold) {
      row = Opacity(opacity: ColdTabBadge.opacity, child: row);
    }

    return row;
  }
}

/// Folder header row on the wide rail: icon, name, child count and the
/// collapse toggle, indented by folder depth. Its members follow it in the
/// list one level deeper. Tap and the toggle both collapse or expand.
class WideRailFolderRow extends ConsumerWidget {
  final TabListFolderItem folder;

  const WideRailFolderRow({super.key, required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void toggleCollapsed() {
      unawaited(
        ref
            .read(folderRepositoryProvider.notifier)
            .setCollapsed(folder.folderId, !folder.isCollapsed),
      );
    }

    return SizedBox(
      height: WideRailTabRowView.height,
      child: InkWell(
        onTap: toggleCollapsed,
        child: Padding(
          padding: EdgeInsets.only(
            left: 12 + WideRailTabRowView.indentPerLevel * folder.depth,
            right: 4,
          ),
          child: Row(
            children: [
              Icon(
                folder.isCollapsed
                    ? MdiIcons.folderOutline
                    : MdiIcons.folderOpenOutline,
                size: WideRailTabRowView.iconSize,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  folder.name.isEmpty ? 'Folder' : folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (folder.childCount > 0) ...[
                const SizedBox(width: 6),
                InlineCountBadge(
                  count: folder.childCount,
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer,
                ),
              ],
              IconButton(
                onPressed: toggleCollapsed,
                visualDensity: VisualDensity.compact,
                tooltip: folder.isCollapsed ? 'Expand' : 'Collapse',
                icon: Icon(
                  folder.isCollapsed
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
