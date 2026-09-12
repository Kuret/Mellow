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

import 'package:fading_scroll/fading_scroll.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_list_scope.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/utils/close_tab_helper.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/quick_tab_switcher_chip.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_entity.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/web_search/domain/controllers/sandbox_capture_controller.dart';
import 'package:weblibre/presentation/hooks/scroll_to_active_chip.dart';
import 'package:weblibre/presentation/widgets/inline_count_badge.dart';

/// Accordion stacking mode for the quick tab switcher bar: every available
/// space renders as a header chip and the selected space is
/// "expanded" — its tabs appear inline right after its header. Tapping
/// another header selects that space, collapsing the previous group.
class AccordionQuickTabSwitcher extends HookConsumerWidget {
  const AccordionQuickTabSwitcher({super.key, this.axis = Axis.horizontal});

  /// Direction the accordion flows. Vertical for the side rail.
  final Axis axis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVertical = axis == Axis.vertical;
    final scrollController = useScrollController();
    final activeChipKey = useRef(GlobalKey());
    final isUserScrolling = useRef(false);
    final userScrollTimer = useRef<Timer?>(null);

    useEffect(() {
      return userScrollTimer.value?.cancel;
    }, []);

    final showTitlesSetting = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.quickTabSwitcherShowTitles,
      ),
    );
    final railWidth = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.railWidth),
    );
    // Titles can't fit the narrow vertical rail; force icon-only chips there
    // unless the rail has been widened enough to show them (isWideRail).
    final wideRail = isWideRail(
      isVertical: isVertical,
      railWidth: railWidth,
      viewportWidth: MediaQuery.sizeOf(context).width,
    );
    final showTitles = (!isVertical || wideRail) && showTitlesSetting;
    final hierarchyGlyphs = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.quickTabSwitcherHierarchyGlyphs,
      ),
    );
    final titleMaxWidthSetting = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.quickTabSwitcherTitleWidth,
      ),
    );
    // On a wide rail the title has to additionally fit beside the favicon
    // inside railWidth, or it overflows the rail itself.
    final titleMaxWidth = wideRail
        ? titleMaxWidthSetting.clamp(
            0.0,
            (railWidth - railChipChromeWidth).clamp(0.0, double.infinity),
          )
        : titleMaxWidthSetting;
    final closeButtonMode = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.quickTabSwitcherCloseButtonMode,
      ),
    );

    final spaces =
        ref.watch(watchSpacesProvider.select((value) => value.value)) ??
        const <SpaceData>[];
    final selectedSpaceUuid = ref.watch(selectedSpaceProvider);
    final selectedTabId = ref.watch(selectedTabProvider);

    final expandedTabStates = ref.watch(
      selectedSpaceTabStatesWithContainerProvider,
    );
    final pinnedTabIds = ref.watch(pinnedTabIdsProvider);
    final sandboxCaptureMap =
        ref.watch(sandboxCaptureMapProvider).value ?? const {};
    final restoreComplete = ref.watch(browserRestoreCompleteProvider);
    final nativeTabIds = ref
        .watch(
          tabStatesProvider.select(
            (states) => EquatableValue(states.keys.toSet()),
          ),
        )
        .value;
    final tabDepthById = ref
        .watch(
          groupedTabListItemsProvider(
            spaceUuid: selectedSpaceUuid,
            scope: TabListScope.presentation,
          ).select((value) {
            return EquatableValue(<String, int>{
              if (hierarchyGlyphs > 0)
                for (final item in value.value)
                  if (item is TabListChildItem) item.tabId: item.depth,
            });
          }),
        )
        .value;

    final expandedItems = expandedTabStates.value
        .map(
          (state) => QuickTabSwitcherItem.tab(
            state,
            selectedTabId: selectedTabId,
            pinnedTabIds: pinnedTabIds,
            tabDepthById: tabDepthById,
            sandboxSourceUri: parseSandboxSource(
              sandboxCaptureMap[state.$1.id],
            ),
            isPlaceholder:
                !restoreComplete && !nativeTabIds.contains(state.$1.id),
          ),
        )
        .toList();

    final decoration = buildQuickTabSwitcherChipDecoration(
      context,
      showTitles: showTitles,
      hierarchyGlyphs: hierarchyGlyphs,
      isVertical: isVertical,
      // The tray is painted in the container color, so the active tab's normal
      // (transparent) selected border would blend in; give it a thicker border
      // in the container's outline color instead.
      thickContainerSelectedBorder: true,
    );

    void selectSpace(String spaceUuid) {
      ref.read(selectedSpaceProvider.notifier).setSpace(spaceUuid);
    }

    Widget buildTabChip(QuickTabSwitcherItem item) {
      final isSelected = item.isActive;
      // The narrow rail can't fit a close button beside the icon-only chip; it
      // overflows (and the active tab's thick border makes it worse). Closing
      // stays available via the long-press menu.
      final canClose =
          !isVertical &&
          !item.isPlaceholder &&
          closeButtonMode.showsFor(isActive: item.isActive);

      final chip = QuickTabSwitcherChip(
        item: item,
        isSelected: isSelected,
        selectedBorderColor: Theme.of(context).colorScheme.primary,
        decoration: decoration,
        label: buildQuickTabSwitcherChipLabel(
          context,
          item,
          isSelected: isSelected,
          showTitles: showTitles,
          hierarchyGlyphs: hierarchyGlyphs,
          titleMaxWidth: titleMaxWidth,
          isVertical: isVertical,
        ),
        // Spacing inside the expanded group is owned by the surrounding tray
        // slice so the slices abut into one continuous background.
        padding: EdgeInsets.zero,
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
        enabled: !item.isPlaceholder,
        enablePinTab: true,
        child: chip,
      );
    }

    final entries = <_AccordionEntry>[
      for (final space in spaces) ...[
        _AccordionEntry.header(
          space: space,
          tabCount: ref.watch(spaceTabCountProvider(space.uuid)).value ?? 0,
          isExpanded: space.uuid == selectedSpaceUuid,
        ),
        if (space.uuid == selectedSpaceUuid)
          ...expandedItems.map(_AccordionEntry.tab),
      ],
    ];

    // The expanded container header plus its tabs form one contiguous run that
    // is wrapped in a shared "tray" background so the group reads as a unit and
    // its members are visually distinct from the standalone container headers.
    // Each entry only knows which slice of that tray it paints; the slices abut
    // into one continuous rounded surface.
    final trayPositions = <_TrayPosition>[
      for (var i = 0; i < entries.length; i++)
        switch (entries[i]) {
          _AccordionHeaderEntry(:final isExpanded) =>
            !isExpanded
                ? _TrayPosition.none
                : (i + 1 < entries.length &&
                          entries[i + 1] is _AccordionTabEntry
                      ? _TrayPosition.start
                      : _TrayPosition.solo),
          _AccordionTabEntry() =>
            (i + 1 >= entries.length || entries[i + 1] is _AccordionHeaderEntry)
                ? _TrayPosition.end
                : _TrayPosition.middle,
        },
    ];

    // The expanded group's tray uses a plain neutral surface — spaces have no
    // per-item color of their own (unlike the old container tray fill).
    final scheme = Theme.of(context).colorScheme;
    final trayFill = scheme.surfaceContainerHigh;

    // The chip to keep centered: the active tab when it is part of the
    // expanded group, otherwise the expanded space header as a fallback.
    final activeTabEntryId = 'tab-$selectedTabId';
    final hasActiveTab = entries.any((entry) => entry.id == activeTabEntryId);
    String? expandedHeaderId;
    for (final entry in entries) {
      if (entry is _AccordionHeaderEntry && entry.isExpanded) {
        expandedHeaderId = entry.id;
        break;
      }
    }
    final activeEntryId = hasActiveTab ? activeTabEntryId : expandedHeaderId;

    // Keep the active chip (or expanded header fallback) centered when the
    // selection or ordering changes, unless the user is scrolling themselves.
    useScrollToActiveChip<String>(
      controller: scrollController,
      activeChipKey: activeChipKey.value,
      activeId: activeEntryId,
      orderedIds: [for (final entry in entries) entry.id],
      isUserScrolling: () => isUserScrolling.value,
    );

    if (entries.isEmpty) {
      // Hold the 48px slot; the bar visibility is decided upstream by
      // quickTabSwitcherRowCountProvider.
      return isVertical
          ? const SizedBox(width: 48)
          : const SizedBox(height: 48);
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        userScrollTimer.value?.cancel();
        isUserScrolling.value = true;
        userScrollTimer.value = Timer(const Duration(milliseconds: 1500), () {
          isUserScrolling.value = false;
        });
        return false;
      },
      child: Padding(
        padding: isVertical
            ? const EdgeInsets.symmetric(vertical: 4.0)
            : const EdgeInsets.symmetric(horizontal: 4.0),
        child: SizedBox(
          height: isVertical ? double.maxFinite : 48,
          width: isVertical ? 48 : double.maxFinite,
          child: FadingScroll(
            controller: scrollController,
            fadingSize: 15,
            builder: (context, controller) {
              return ListView.builder(
                key: const PageStorageKey('quick_tab_switcher_accordion'),
                controller: controller,
                scrollDirection: axis,
                scrollCacheExtent: const ScrollCacheExtent.pixels(500),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final child = switch (entry) {
                    // Space header rows are plain switch chips; renaming,
                    // setting a container or deleting a space happens via
                    // SpaceChips in the tab tray header, not here.
                    _AccordionHeaderEntry() => _AccordionHeaderChip(
                      entry: entry,
                      // The narrow rail can't fit the space title; show the
                      // icon avatar + count badge only.
                      showTitle: !isVertical,
                      onSelected: () => selectSpace(entry.space.uuid),
                    ),
                    _AccordionTabEntry(:final item) => buildTabChip(item),
                  };

                  return KeyedSubtree(
                    key: entry.id == activeEntryId
                        ? activeChipKey.value
                        : ValueKey(entry.id),
                    child: _TraySlice(
                      position: trayPositions[index],
                      fill: trayFill,
                      axis: axis,
                      child: child,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

sealed class _AccordionEntry {
  const _AccordionEntry();

  factory _AccordionEntry.header({
    required SpaceData space,
    required int tabCount,
    required bool isExpanded,
  }) = _AccordionHeaderEntry;

  factory _AccordionEntry.tab(QuickTabSwitcherItem item) = _AccordionTabEntry;

  String get id;
}

/// A space group header chip.
class _AccordionHeaderEntry extends _AccordionEntry {
  final SpaceData space;
  final int tabCount;
  final bool isExpanded;

  const _AccordionHeaderEntry({
    required this.space,
    required this.tabCount,
    required this.isExpanded,
  });

  @override
  String get id => 'space-${space.uuid}';
}

class _AccordionTabEntry extends _AccordionEntry {
  final QuickTabSwitcherItem item;

  const _AccordionTabEntry(this.item);

  @override
  String get id => 'tab-${item.id}';
}

/// Space group header, rendered as a plain neutral chip. The fill is the
/// same whether the space is selected (expanded) or not — selection only
/// adds the surrounding tray and the inline tabs, it never recolors the
/// header chip itself.
class _AccordionHeaderChip extends StatelessWidget {
  final _AccordionHeaderEntry entry;
  final VoidCallback onSelected;

  /// When false (e.g. the narrow vertical rail) the space title is hidden
  /// and only the icon avatar + count badge are shown, so the chip fits.
  final bool showTitle;

  const _AccordionHeaderChip({
    required this.entry,
    required this.onSelected,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final space = entry.space;

    final fill = scheme.surfaceContainerHigh;
    final foreground = scheme.onSurfaceVariant;
    final badgeBackground = scheme.secondaryContainer;
    final badgeForeground = scheme.onSecondaryContainer;

    final countBadge = entry.tabCount > 0
        ? InlineCountBadge(
            count: entry.tabCount,
            backgroundColor: badgeBackground,
            foregroundColor: badgeForeground,
          )
        : null;

    final iconAvatar = Icon(MdiIcons.viewDashboardOutline, color: foreground);

    final side = BorderSide(width: 2, color: fill);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
      side: side,
    );

    final displayName = space.name.isEmpty ? 'Space' : space.name;

    if (!showTitle) {
      // Narrow rail: no room for the avatar slot + title + trailing badge side
      // by side (the badge gets clipped). Stack the space icon over the
      // count badge inside the label instead, dropping the avatar slot.
      return FilterChip(
        labelPadding: EdgeInsets.zero,
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconAvatar,
            if (countBadge != null) ...[
              const SizedBox(height: 4),
              // Multi-digit counts can exceed the narrow rail's fixed 48px chip
              // width; scale the badge down to fit instead of overflowing.
              FittedBox(fit: BoxFit.scaleDown, child: countBadge),
            ],
          ],
        ),
        color: WidgetStatePropertyAll(fill),
        selected: false,
        showCheckmark: false,
        onSelected: (value) {
          if (value) {
            onSelected();
          }
        },
        side: side,
        shape: shape,
      );
    }

    return FilterChip(
      avatar: iconAvatar,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayName, style: TextStyle(color: foreground)),
          if (countBadge != null) ...[const SizedBox(width: 6), countBadge],
        ],
      ),
      color: WidgetStatePropertyAll(fill),
      selected: false,
      showCheckmark: false,
      onSelected: (value) {
        if (value) {
          onSelected();
        }
      },
      side: side,
      shape: shape,
    );
  }
}

/// Where a chip sits within the expanded container's tray, controlling which
/// rounded corners and edge padding its [_TraySlice] paints. [none] is a
/// standalone (collapsed) header that carries no tray.
enum _TrayPosition { none, solo, start, middle, end }

/// One slice of the shared tray behind an expanded group's chips. Adjacent
/// slices abut with matching height and seam padding so their fill merges into
/// a single continuous rounded, container-colored surface spanning the header
/// and its tabs.
class _TraySlice extends StatelessWidget {
  final _TrayPosition position;
  final Color fill;
  final Widget child;
  final Axis axis;

  const _TraySlice({
    required this.position,
    required this.fill,
    required this.child,
    this.axis = Axis.horizontal,
  });

  /// Corner radius of the chips, matched by the tray so it hugs the first and
  /// last chip's edges exactly.
  static const Radius _radius = Radius.circular(8.0);

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;

    if (position == _TrayPosition.none) {
      // Standalone container header: regular inter-chip spacing, centered
      // on the cross axis to line up with the tray slices.
      return Padding(
        padding: isVertical
            ? const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0)
            : const EdgeInsets.fromLTRB(0.0, 2.0, 8.0, 2.0),
        child: child,
      );
    }

    final borderRadius = switch ((position, isVertical)) {
      (_TrayPosition.solo, _) => const BorderRadius.all(_radius),
      (_TrayPosition.start, false) => const BorderRadius.horizontal(
        left: _radius,
      ),
      (_TrayPosition.end, false) => const BorderRadius.horizontal(
        right: _radius,
      ),
      (_TrayPosition.start, true) => const BorderRadius.vertical(top: _radius),
      (_TrayPosition.end, true) => const BorderRadius.vertical(bottom: _radius),
      (_TrayPosition.middle, _) || (_TrayPosition.none, _) => BorderRadius.zero,
    };

    final isTrailingEdge =
        position == _TrayPosition.end || position == _TrayPosition.solo;

    return Padding(
      // Transparent gap after the tray so a following standalone header
      // doesn't butt up against the rounded trailing edge.
      padding: isVertical
          ? EdgeInsets.only(
              left: 2.0,
              right: 2.0,
              bottom: isTrailingEdge ? 8.0 : 0.0,
            )
          : EdgeInsets.only(
              top: 2.0,
              bottom: 2.0,
              right: isTrailingEdge ? 8.0 : 0.0,
            ),
      child: SizedBox(
        height: isVertical ? null : 44.0,
        width: isVertical ? 44.0 : null,
        child: Container(
          decoration: BoxDecoration(color: fill, borderRadius: borderRadius),
          // A small inset so the first/last chip get the same breathing room
          // from the tray edge as the inter-chip seam gaps.
          padding: isVertical
              ? const EdgeInsets.symmetric(vertical: 4.0)
              : const EdgeInsets.symmetric(horizontal: 4.0),
          child: Center(child: child),
        ),
      ),
    );
  }
}
