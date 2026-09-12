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
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_presence.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/cold_tab_badge.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_icon.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_menu.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

/// Zen's `zen.tabs.essentials.max`: how many essentials a strip is laid out
/// for. A layout hint only — the grid wraps and grows past it, since the
/// desktop may hold more (PLAN §6.4).
const essentialsMax = 12;

/// Columns of the essentials grid at full width: two rows of [essentialsMax].
const essentialsMaxColumns = 6;

/// The ids on the Essentials shelf the current space shows, in strip order
/// (PLAN §6.4): with `separateEssentials` on, the strip of the selected
/// space's container (`null` for a space without one — Zen's `default` key);
/// off, every strip in container order, the unassigned strip first.
///
/// `null` while the shelves are still loading.
List<String>? watchEssentialShelfTabIds(WidgetRef ref) {
  final separate = ref.watch(
    generalSettingsWithDefaultsProvider.select((s) => s.separateEssentials),
  );

  if (separate) {
    final space = ref.watch(selectedSpaceDataProvider);
    if (space.isLoading && !space.hasValue) {
      return null;
    }
    return ref
        .watch(watchEssentialTabIdsProvider(space.value?.containerId))
        .value;
  }

  final containers = ref.watch(
    watchContainersWithCountProvider.select((value) => value.value),
  );
  if (containers == null) {
    return null;
  }
  final ids = <String>[];
  for (final containerId in <String?>[
    null,
    for (final ContainerData container in containers) container.id,
  ]) {
    final strip = ref.watch(watchEssentialTabIdsProvider(containerId)).value;
    if (strip == null) {
      return null;
    }
    ids.addAll(strip);
  }
  return ids;
}

/// The Essentials shelf: an icon grid of the essential tabs the current space
/// shows (see [watchEssentialShelfTabIds]). No titles and no close buttons —
/// the chip close-button mode is `never` here whatever the setting says; the
/// long-press menu carries every shelf transition. Renders nothing when the
/// shelf is empty.
class EssentialsGrid extends ConsumerWidget {
  /// Called after a tap selected a tab (the tray closes itself with this).
  final VoidCallback? onSelected;

  /// Edge length of one cell.
  final double tileSize;

  final EdgeInsetsGeometry padding;

  /// Whether to draw the "Essentials" section header above the grid.
  final bool showHeader;

  const EssentialsGrid({
    super.key,
    this.onSelected,
    this.tileSize = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIds = watchEssentialShelfTabIds(ref) ?? const <String>[];
    if (tabIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) const ShelfSectionHeader(title: 'Essentials'),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : tileSize * essentialsMaxColumns;
              final columns = (width / tileSize).floor().clamp(
                1,
                essentialsMaxColumns,
              );
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  for (final tabId in tabIds)
                    EssentialTile(
                      key: ValueKey('essential-$tabId'),
                      tabId: tabId,
                      onSelected: onSelected,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One cell of the [EssentialsGrid]: the favicon on a tonal square, with the
/// active tab outlined and a cold tab dimmed behind the [ColdTabBadge].
class EssentialTile extends ConsumerWidget {
  final String tabId;
  final VoidCallback? onSelected;

  const EssentialTile({super.key, required this.tabId, this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tabState =
        ref.watch(
          tabStateWithFallbackProvider(tabId).select((value) => value.value),
        ) ??
        TabState.$default(tabId);
    final presence = ref.watch(tabPresenceProvider(tabId));
    final isActive = ref.watch(
      selectedTabProvider.select((selected) => selected == tabId),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = math.max(
          16.0,
          math.min(constraints.maxWidth, constraints.maxHeight) * 0.5,
        );
        final icon = TabIcon(tabState: tabState, iconSize: iconSize);
        final cell = Container(
          decoration: BoxDecoration(
            color: isActive
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: scheme.primary, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: presence == TabPresence.cold
              ? Opacity(
                  opacity: ColdTabBadge.opacity,
                  child: ColdTabBadge(size: iconSize, child: icon),
                )
              : icon,
        );

        return Tooltip(
          message: tabState.titleOrAuthority,
          child: TabMenu(
            selectedTabId: tabId,
            enableFindInPage: false,
            enableFetchFeeds: false,
            enableDesktopMode: false,
            enableReaderMode: false,
            enableReloadButton: false,
            enableNavigationButtons: false,
            enableAddToHomeScreen: false,
            enableCloseTab: true,
            builder: (context, controller, child) {
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  onSelected?.call();
                  await ref
                      .read(tabRepositoryProvider.notifier)
                      .selectTab(tabId);
                },
                onLongPress: presence == TabPresence.restoring
                    ? null
                    : () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                child: cell,
              );
            },
          ),
        );
      },
    );
  }
}

/// The small section label the tray's shelves share ("Essentials", "Pinned",
/// "Tabs"), in the codebase's small header style.
class ShelfSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const ShelfSectionHeader({super.key, required this.title, this.trailing});

  /// Height the row lays out to, so list surfaces can size its slot.
  static const height = 32.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
