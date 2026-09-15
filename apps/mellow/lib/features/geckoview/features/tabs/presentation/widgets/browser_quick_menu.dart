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
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_detail_state.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_session.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/space_icon.dart';

/// Opens a new tab in the current space: the same thing the main toolbar's
/// "New Tab" button ([ToolbarButtonId.addTab]) does on a plain tap.
Future<void> openNewTabFromQuickMenu(
  BuildContext context,
  WidgetRef ref,
) async {
  await SearchRoute(
    tabType: ref.read(selectedTabTypeProvider) ?? TabType.regular,
  ).push(context);

  if (context.mounted) {
    const BrowserRoute().go(context);
  }
}

/// The actions of the quick menu, in the order they are shown: Refresh,
/// Back, Forward, Tabs, Settings, then (after a divider) New Space and New
/// Tab.
enum _BrowserQuickMenuAction {
  reload,
  back,
  forward,
  tabs,
  settings,
  newSpace,
  newTab,
}

/// What choosing an entry in the quick menu resolves to: one of the fixed
/// [_BrowserQuickMenuAction]s, or — when the menu carries a spaces section
/// (see [showBrowserQuickMenu]'s `includeSpaces`) — the uuid of the space
/// that was picked.
sealed class _BrowserQuickMenuResult {
  const _BrowserQuickMenuResult();
}

class _QuickMenuAction extends _BrowserQuickMenuResult {
  final _BrowserQuickMenuAction action;

  const _QuickMenuAction(this.action);
}

class _QuickMenuSpace extends _BrowserQuickMenuResult {
  final String uuid;

  const _QuickMenuSpace(this.uuid);
}

/// The shared quick menu (PLAN §9 W1 change 5): everything the toolbar row
/// would otherwise carry, reached without it — anchored to whichever control
/// opened it (the wide rail's "+" long-press, or the compact bar's space
/// indicator, on either a tap or a long-press). Each action reuses the same
/// call the corresponding toolbar button makes (see
/// `toolbar_button_registry.dart`), rather than a second implementation of
/// "go back"/"reload"/etc.
///
/// With [includeSpaces], the menu also lists every space between two
/// dividers (New Space/New Tab move below that section) — this is how the
/// compact bar's space indicator merges what used to be a separate picker
/// sheet into the same menu; the wide rail passes `false` (its default)
/// since the rail already lists every space along its foot.
///
/// [haptic] fires a `HapticFeedback.mediumImpact()` tick before the menu is
/// built, acknowledging that a long-press was long enough; a plain tap
/// (the compact bar's indicator) passes `false` since there is nothing to
/// acknowledge.
Future<void> showBrowserQuickMenu(
  BuildContext anchorContext,
  WidgetRef ref, {
  bool includeSpaces = false,
  bool haptic = true,
}) async {
  // Fired before the menu is built: the tick is the acknowledgement that the
  // press was long enough, so it has to land when the finger is still down,
  // not when the menu finishes animating in.
  if (haptic) {
    unawaited(HapticFeedback.mediumImpact());
  }

  final button = anchorContext.findRenderObject()! as RenderBox;
  final overlay =
      Overlay.of(anchorContext).context.findRenderObject()! as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    ),
    Offset.zero & overlay.size,
  );

  final selectedTabId = ref.read(selectedTabProvider);
  final historyState = ref.read(tabHistoryStateProvider(selectedTabId));

  final spaces = includeSpaces
      ? ref.read(watchSpacesProvider.select((value) => value.value)) ??
            const <SpaceData>[]
      : const <SpaceData>[];
  final selectedSpaceUuid = includeSpaces
      ? ref.read(selectedSpaceProvider)
      : null;

  const iconTextSpacing = SizedBox(width: 12);

  final result = await showMenu<_BrowserQuickMenuResult>(
    context: anchorContext,
    position: position,
    items: [
      const PopupMenuItem(
        value: _QuickMenuAction(_BrowserQuickMenuAction.reload),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.refresh), iconTextSpacing, Text('Refresh')],
        ),
      ),
      PopupMenuItem(
        value: const _QuickMenuAction(_BrowserQuickMenuAction.back),
        enabled: historyState.canGoBack,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.arrow_back), iconTextSpacing, Text('Back')],
        ),
      ),
      PopupMenuItem(
        value: const _QuickMenuAction(_BrowserQuickMenuAction.forward),
        enabled: historyState.canGoForward,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward),
            iconTextSpacing,
            Text('Forward'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: _QuickMenuAction(_BrowserQuickMenuAction.tabs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(MdiIcons.tab), iconTextSpacing, Text('Tabs')],
        ),
      ),
      const PopupMenuItem(
        value: _QuickMenuAction(_BrowserQuickMenuAction.settings),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.settings), iconTextSpacing, Text('Settings')],
        ),
      ),
      if (includeSpaces) ...[
        const PopupMenuDivider(),
        for (final space in spaces)
          PopupMenuItem(
            value: _QuickMenuSpace(space.uuid),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpaceIcon(icon: space.icon, size: 18),
                iconTextSpacing,
                Text(space.name.isEmpty ? 'Space' : space.name),
                if (space.uuid == selectedSpaceUuid) ...[
                  iconTextSpacing,
                  const Icon(Icons.check),
                ],
              ],
            ),
          ),
      ],
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: _QuickMenuAction(_BrowserQuickMenuAction.newSpace),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.add), iconTextSpacing, Text('New Space')],
        ),
      ),
      const PopupMenuItem(
        value: _QuickMenuAction(_BrowserQuickMenuAction.newTab),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(MdiIcons.tabPlus), iconTextSpacing, Text('New Tab')],
        ),
      ),
    ],
  );

  if (result == null || !anchorContext.mounted) return;

  switch (result) {
    case _QuickMenuSpace(:final uuid):
      ref.read(selectedSpaceProvider.notifier).space = uuid;
    case _QuickMenuAction(action: _BrowserQuickMenuAction.reload):
      if (selectedTabId != null) {
        await ref
            .read(tabSessionProvider(tabId: selectedTabId).notifier)
            .reload();
      }
    case _QuickMenuAction(action: _BrowserQuickMenuAction.back):
      if (selectedTabId != null && historyState.canGoBack) {
        await ref
            .read(tabSessionProvider(tabId: selectedTabId).notifier)
            .goBack();
      }
    case _QuickMenuAction(action: _BrowserQuickMenuAction.forward):
      if (selectedTabId != null && historyState.canGoForward) {
        await ref
            .read(tabSessionProvider(tabId: selectedTabId).notifier)
            .goForward();
      }
    case _QuickMenuAction(action: _BrowserQuickMenuAction.tabs):
      if (anchorContext.mounted) {
        await const TabViewRoute().push(anchorContext);
      }
    case _QuickMenuAction(action: _BrowserQuickMenuAction.settings):
      if (anchorContext.mounted) {
        await SettingsRoute().push(anchorContext);
      }
    case _QuickMenuAction(action: _BrowserQuickMenuAction.newSpace):
      if (anchorContext.mounted) {
        await const SpaceCreateRoute().push(anchorContext);
      }
    case _QuickMenuAction(action: _BrowserQuickMenuAction.newTab):
      if (anchorContext.mounted) {
        await openNewTabFromQuickMenu(anchorContext, ref);
      }
  }
}
