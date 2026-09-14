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

import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:nullability/nullability.dart';
import 'package:weblibre/core/design/app_colors.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_presence.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/cold_tab_badge.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_icon.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_menu.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/container_colors.dart';
import 'package:weblibre/presentation/widgets/selectable_chips.dart';
import 'package:weblibre/presentation/widgets/url_icon.dart';

class QuickTabSwitcherItem with FastEquatable {
  final Color? color;
  final bool useCustomColor;
  final String id;
  final bool isActive;
  final TabMode tabMode;
  final bool isHistory;
  final bool isPinned;
  final String title;
  final Uri url;
  final Widget avatar;

  /// Whether the tab has an engine session behind it. A [TabPresence.restoring]
  /// tab cannot be closed or reordered yet; a [TabPresence.cold] one renders
  /// dimmed with a snowflake badge and materialises when tapped (PLAN §7.4).
  final TabPresence presence;

  bool get isRestoring => presence == TabPresence.restoring;
  bool get isCold => presence == TabPresence.cold;

  QuickTabSwitcherItem({
    required this.color,
    required this.id,
    required this.isActive,
    required this.tabMode,
    required this.isHistory,
    required this.isPinned,
    required this.title,
    required this.url,
    required this.avatar,
    this.useCustomColor = false,
    this.presence = TabPresence.live,
  });

  /// Builds a switcher entry for an open tab.
  factory QuickTabSwitcherItem.tab(
    TabStateWithContainer state, {
    required String? selectedTabId,
    required Set<String> pinnedTabIds,
    TabPresence presence = TabPresence.live,
  }) {
    final (tab, container) = state;

    return QuickTabSwitcherItem(
      color: container?.color.color,
      id: tab.id,
      isActive: tab.id == selectedTabId,
      title: tab.titleOrAuthority,
      tabMode: tab.tabMode,
      isHistory: false,
      isPinned: pinnedTabIds.contains(tab.id),
      url: tab.url,
      avatar: TabIcon(tabState: tab, iconSize: 20),
      presence: presence,
    );
  }

  /// Builds a switcher entry for a history suggestion (shown only when there
  /// are no open tabs in the active mode).
  factory QuickTabSwitcherItem.history({
    required String url,
    required String? title,
  }) {
    final parsedUrl = Uri.parse(url);

    return QuickTabSwitcherItem(
      color: null,
      id: url,
      isActive: false,
      title: title ?? parsedUrl.authority,
      tabMode: TabMode.regular,
      isHistory: true,
      isPinned: false,
      url: parsedUrl,
      avatar: UrlIcon([parsedUrl], iconSize: 20),
    );
  }

  @override
  List<Object?> get hashParameters => [
    color,
    useCustomColor,
    id,
    isActive,
    tabMode,
    isHistory,
    isPinned,
    title,
    url,
    avatar,
    presence,
  ];
}

/// Visual contract shared by every quick tab switcher render path
/// ([SelectableChips], the reorderable list, and the accordion view).
SelectableChipDecoration<QuickTabSwitcherItem>
buildQuickTabSwitcherChipDecoration(
  BuildContext context, {
  required bool showTitles,
  // On the vertical rail nesting is shown as a corner badge on the favicon (not
  // a leading pill), so a nested chip carries no extra inline width and can use
  // the same zero label padding as a leaf chip instead of overflowing.
  bool isVertical = false,
  bool Function(QuickTabSwitcherItem item)? canDelete,
  // When true, the selected item gets a thicker border in its container's
  // outline color (instead of the usual transparent selected border). The
  // accordion uses this so the active tab stays visible against its
  // container-colored tray while matching the unselected chips' border color.
  bool thickContainerSelectedBorder = false,
}) {
  return SelectableChipDecoration(
    color: (item, isSelected) => switch (item.color) {
      final color? when isSelected => ContainerColors.palette(
        context,
        color,
        useCustomColor: item.useCustomColor,
      ).selectedBackgroundColor,
      final color? => ContainerColors.palette(
        context,
        color,
        useCustomColor: item.useCustomColor,
      ).backgroundColor,
      null => null,
    },
    side: (item, isSelected) => switch (item.color) {
      final color? when isSelected =>
        thickContainerSelectedBorder
            ? BorderSide(
                color: ContainerColors.palette(
                  context,
                  color,
                  useCustomColor: item.useCustomColor,
                ).outlineColor,
                width: 2.0,
              )
            : ContainerColors.palette(
                context,
                color,
                useCustomColor: item.useCustomColor,
              ).selectedBorderSide,
      final color? => ContainerColors.palette(
        context,
        color,
        useCustomColor: item.useCustomColor,
      ).borderSide,
      null => null,
    },
    labelPadding: (item) =>
        (!showTitles &&
            !item.isHistory &&
            !item.isPinned &&
            item.tabMode is! PrivateTabMode)
        ? EdgeInsets.zero
        : null,
    canDelete: canDelete,
    deleteIcon: (_) => const Icon(Icons.close, size: 18),
  );
}

Widget buildQuickTabSwitcherChipLabel(
  BuildContext context,
  QuickTabSwitcherItem item, {
  required bool isSelected,
  required bool showTitles,
  required double titleMaxWidth,
  bool isVertical = false,
}) {
  final appColors = AppColors.of(context);
  final hasTitle = item.isHistory || showTitles;
  final avatar = item.isCold
      ? ColdTabBadge(size: 20, child: item.avatar)
      : item.avatar;
  final labelRow = Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: EdgeInsets.only(right: hasTitle ? 6.0 : 0.0),
        child: avatar,
      ),
      if (hasTitle)
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: titleMaxWidth),
          child: Text(item.title),
        ),
      if (item.tabMode is PrivateTabMode)
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(
            MdiIcons.dominoMask,
            color: appColors.privateTabPurple,
            size: 20,
          ),
        ),
      if (item.isPinned)
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(
            MdiIcons.pin,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
      if (item.isHistory)
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Icon(MdiIcons.history, size: 20),
        ),
    ],
  );

  // A cold tab is dimmed: no session behind it until it is tapped.
  final row = item.isCold
      ? Opacity(opacity: ColdTabBadge.opacity, child: labelRow)
      : labelRow;
  return item.color.mapNotNull(
        (color) => DefaultTextStyle.merge(
          style: TextStyle(
            color: isSelected
                ? ContainerColors.palette(
                    context,
                    color,
                    useCustomColor: item.useCustomColor,
                  ).selectedForegroundColor
                : ContainerColors.palette(
                    context,
                    color,
                    useCustomColor: item.useCustomColor,
                  ).foregroundColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          child: row,
        ),
      ) ??
      row;
}

/// FilterChip matching [SelectableChips]' visual contract, used by render
/// paths that can't go through [SelectableChips] itself (the reorderable
/// list and the accordion view). Stateless wrapper so a parent
/// `ReorderableListView` can attach its drag-handle gesture recognizer.
class QuickTabSwitcherChip extends StatelessWidget {
  final QuickTabSwitcherItem item;
  final bool isSelected;
  final Color selectedBorderColor;
  final SelectableChipDecoration<QuickTabSwitcherItem> decoration;
  final Widget label;
  final Future<void> Function() onTap;
  final Future<void> Function()? onDelete;

  /// Outer spacing around the chip. Defaults to the standard inter-chip gap;
  /// render paths that manage their own spacing (e.g. the accordion tray)
  /// pass [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  const QuickTabSwitcherChip({
    super.key,
    required this.item,
    required this.isSelected,
    required this.selectedBorderColor,
    required this.decoration,
    required this.label,
    required this.onTap,
    this.onDelete,
    this.padding = const EdgeInsets.only(right: 8.0, top: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = decoration.color?.call(item, isSelected);
    final side =
        decoration.side?.call(item, isSelected) ??
        (isSelected
            ? BorderSide(color: selectedBorderColor, width: 2.0)
            : null);
    final labelPadding = decoration.labelPadding?.call(item);

    return Padding(
      padding: padding,
      child: FilterChip(
        color: itemColor != null ? WidgetStatePropertyAll(itemColor) : null,
        selected: false,
        showCheckmark: false,
        labelPadding: labelPadding,
        onSelected: (_) {
          unawaited(onTap());
        },
        deleteIcon: decoration.deleteIcon?.call(item),
        onDeleted: onDelete != null
            ? () {
                unawaited(onDelete!());
              }
            : null,
        label: label,
        side: side,
      ),
    );
  }
}

/// Wraps a tab chip in the long-press [TabMenu] used across switcher views.
Widget wrapQuickTabSwitcherChipWithMenu({
  required String itemId,
  required bool enabled,
  required bool enablePinTab,
  required Widget child,
}) {
  if (!enabled) {
    return child;
  }

  return TabMenu(
    selectedTabId: itemId,
    enableFindInPage: false,
    enableDesktopMode: false,
    enableReloadButton: false,
    enableNavigationButtons: false,
    enableAddToHomeScreen: false,
    enablePinTab: enablePinTab,
    builder: (context, controller, _) {
      return InkWell(
        onLongPress: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        child: child,
      );
    },
  );
}
