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
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_detail_state.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_session.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';

/// Opens a new tab in the current space: the same thing the main toolbar's
/// "New Tab" button ([ToolbarButtonId.addTab]) does on a plain tap.
Future<void> openNewTabFromQuickMenu(BuildContext context, WidgetRef ref) async {
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

/// The shared quick menu (PLAN §9 W1 change 5): everything the toolbar row
/// would otherwise carry, reached without it — anchored to whichever control
/// opened it (the wide rail's "+" long-press, or the compact bar's space
/// indicator long-press). Each action reuses the same call the corresponding
/// toolbar button makes (see `toolbar_button_registry.dart`), rather than a
/// second implementation of "go back"/"reload"/etc.
Future<void> showBrowserQuickMenu(
  BuildContext anchorContext,
  WidgetRef ref,
) async {
  // Fired before the menu is built: the tick is the acknowledgement that the
  // press was long enough, so it has to land when the finger is still down,
  // not when the menu finishes animating in.
  unawaited(HapticFeedback.mediumImpact());

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

  const iconTextSpacing = SizedBox(width: 12);

  final action = await showMenu<_BrowserQuickMenuAction>(
    context: anchorContext,
    position: position,
    items: [
      const PopupMenuItem(
        value: _BrowserQuickMenuAction.reload,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.refresh), iconTextSpacing, Text('Refresh')],
        ),
      ),
      PopupMenuItem(
        value: _BrowserQuickMenuAction.back,
        enabled: historyState.canGoBack,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.arrow_back), iconTextSpacing, Text('Back')],
        ),
      ),
      PopupMenuItem(
        value: _BrowserQuickMenuAction.forward,
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
        value: _BrowserQuickMenuAction.tabs,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(MdiIcons.tab), iconTextSpacing, Text('Tabs')],
        ),
      ),
      const PopupMenuItem(
        value: _BrowserQuickMenuAction.settings,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.settings), iconTextSpacing, Text('Settings')],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: _BrowserQuickMenuAction.newSpace,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.add), iconTextSpacing, Text('New Space')],
        ),
      ),
      const PopupMenuItem(
        value: _BrowserQuickMenuAction.newTab,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(MdiIcons.tabPlus), iconTextSpacing, Text('New Tab')],
        ),
      ),
    ],
  );

  if (action == null || !anchorContext.mounted) return;

  switch (action) {
    case _BrowserQuickMenuAction.reload:
      if (selectedTabId != null) {
        await ref
            .read(tabSessionProvider(tabId: selectedTabId).notifier)
            .reload();
      }
    case _BrowserQuickMenuAction.back:
      if (selectedTabId != null && historyState.canGoBack) {
        await ref
            .read(tabSessionProvider(tabId: selectedTabId).notifier)
            .goBack();
      }
    case _BrowserQuickMenuAction.forward:
      if (selectedTabId != null && historyState.canGoForward) {
        await ref
            .read(tabSessionProvider(tabId: selectedTabId).notifier)
            .goForward();
      }
    case _BrowserQuickMenuAction.tabs:
      if (anchorContext.mounted) {
        await const TabViewRoute().push(anchorContext);
      }
    case _BrowserQuickMenuAction.settings:
      if (anchorContext.mounted) {
        await SettingsRoute().push(anchorContext);
      }
    case _BrowserQuickMenuAction.newSpace:
      if (anchorContext.mounted) {
        await const SpaceCreateRoute().push(anchorContext);
      }
    case _BrowserQuickMenuAction.newTab:
      if (anchorContext.mounted) {
        await openNewTabFromQuickMenu(anchorContext, ref);
      }
  }
}
