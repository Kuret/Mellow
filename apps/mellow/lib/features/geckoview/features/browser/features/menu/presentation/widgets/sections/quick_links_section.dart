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
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/geckoview/features/browser/features/menu/domain/entities/menu_layout.dart';
import 'package:mellow/features/geckoview/features/browser/features/menu/presentation/widgets/menu_card.dart';

/// Rows linking to the browser's other screens.
class QuickLinksSection extends ConsumerWidget {
  final List<MenuItemType> items;

  const QuickLinksSection({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = [
      for (final item in items)
        if (_destinations.contains(item)) item,
    ];

    // Rows, like every other section of this menu. These used to be a grid of
    // square tiles, which made sense when there were six of them; the ones that
    // filled the grid out are gone and three squares among a column of rows
    // only read as a different kind of thing than they are.
    return buildMenuCard(
      context,
      children: [
        for (final link in links)
          ListTile(
            leading: Icon(link.icon),
            title: Text(link.label),
            onTap: () => _open(context, link),
          ),
      ],
    );
  }

  /// The rows this section knows how to open. Their icons and labels come from
  /// [MenuItemType] itself, so the menu and the arrangement UI cannot drift.
  static const _destinations = {
    MenuItemType.history,
    MenuItemType.bookmarks,
    MenuItemType.downloads,
  };

  Future<void> _open(BuildContext context, MenuItemType item) async {
    switch (item) {
      case MenuItemType.history:
        Navigator.pop(context);
        await const HistoryRoute().push(context);
      case MenuItemType.bookmarks:
        Navigator.pop(context);
        await BookmarkListRoute(entryGuid: BookmarkRoot.root.id).push(context);
      case MenuItemType.downloads:
        Navigator.pop(context);
        await const HistoryDownloadsRoute().push(context);
      default:
        break;
    }
  }
}
