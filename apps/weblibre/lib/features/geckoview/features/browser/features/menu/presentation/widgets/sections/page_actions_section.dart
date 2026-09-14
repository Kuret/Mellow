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
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/domain/controllers/bottom_sheet.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/features/menu/domain/entities/menu_layout.dart';
import 'package:weblibre/features/geckoview/features/browser/features/menu/presentation/widgets/menu_card.dart';
import 'package:weblibre/features/geckoview/features/find_in_page/presentation/controllers/find_in_page.dart';
import 'package:weblibre/features/geckoview/features/pwa/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/pwa/presentation/widgets/pwa_install_button.dart';
import 'package:weblibre/features/geckoview/features/web_inspector/domain/providers/web_inspector.dart';
import 'package:weblibre/presentation/hooks/cached_future.dart';

/// Actions on the page in front of the user.
///
/// Whether a row applies is decided here rather than inside the row, because
/// the card draws the dividers between its rows: a row that hides itself would
/// otherwise leave the separator it was sitting under behind.
class PageActionsSection extends HookConsumerWidget {
  final String selectedTabId;
  final List<MenuItemType> items;

  static final _appLinksService = GeckoAppLinksService();

  const PageActionsSection({
    super.key,
    required this.selectedTabId,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolving an app link is a native round trip, so it is only started when
    // the row that shows the result is actually part of the layout. The hook
    // itself stays unconditional; it is the work it schedules that is skipped.
    final appLinkUrl = items.contains(MenuItemType.openInApp)
        ? ref.watch(tabStateProvider(selectedTabId).select((s) => s?.url))
        : null;
    final appLink = useCachedFuture(
      () => appLinkUrl != null
          ? _appLinksService.resolveAppLink(appLinkUrl)
          : Future<AppLinkTarget?>.value(null),
      [appLinkUrl],
    );

    final tiles = <MenuItemType, Widget>{};

    for (final item in items) {
      switch (item) {
        case MenuItemType.addBookmark:
          tiles[item] = ListTile(
            leading: const Icon(MdiIcons.bookmarkPlus),
            title: Text(item.label),
            onTap: () async {
              final tabState = ref.read(tabStateProvider(selectedTabId))!;
              final bookmarkUrl = tabState.url;
              Navigator.pop(context);
              await BookmarkEntryAddRoute(
                bookmarkInfo: jsonEncode(
                  BookmarkInfo(
                    title: tabState.titleOrAuthority,
                    url: bookmarkUrl.toString(),
                  ).encode(),
                ),
              ).push(context);
            },
          );

        case MenuItemType.findInPage:
          tiles[item] = ListTile(
            leading: const Icon(Icons.search),
            title: Text(item.label),
            onTap: () {
              ref.read(bottomSheetControllerProvider.notifier).requestDismiss();
              ref
                  .read(findInPageControllerProvider(selectedTabId).notifier)
                  .show();
              Navigator.pop(context);
            },
          );

        case MenuItemType.inspectElement:
          tiles[item] = ListTile(
            leading: const Icon(MdiIcons.selectSearch),
            title: Text(item.label),
            onTap: () {
              ref.read(bottomSheetControllerProvider.notifier).requestDismiss();
              unawaited(
                ref
                    .read(webInspectorServiceProvider(tabId: selectedTabId))
                    .pickElement(),
              );
              Navigator.pop(context);
            },
          );

        case MenuItemType.addToHomeScreen:
          final isInstallable = ref.watch(isCurrentTabInstallableProvider);
          final isShortcutable = ref.watch(isCurrentTabShortcutableProvider);

          if (!isInstallable && !isShortcutable) continue;

          tiles[item] = ListTile(
            leading: const Icon(Icons.add_to_home_screen),
            title: Text(item.label),
            onTap: () async {
              if (isInstallable) {
                // Site has a valid manifest — use the PWA install flow.
                await showPwaInstallDialog(context, ref);
              } else {
                // No manifest — offer a plain shortcut instead.
                await showShortcutInstallDialog(context, ref);
              }
              if (context.mounted) Navigator.pop(context);
            },
          );

        case MenuItemType.openInApp:
          final target = appLink.data;
          if (target == null || appLinkUrl == null) continue;

          final appName = target.appName;
          tiles[item] = ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(appName != null ? 'Open in $appName' : item.label),
            onTap: () async {
              final success = await _appLinksService.launchAppLink(appLinkUrl);
              if (success && context.mounted) Navigator.pop(context);
            },
          );

        default:
          continue;
      }
    }

    return buildMenuCard(
      context,
      children: [
        for (final item in items)
          if (tiles[item] case final tile?) tile,
      ],
    );
  }
}
