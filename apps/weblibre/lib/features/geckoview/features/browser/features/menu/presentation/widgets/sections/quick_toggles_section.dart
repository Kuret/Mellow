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
import 'package:flutter/material.dart';
import 'package:weblibre/features/geckoview/features/browser/features/menu/domain/entities/menu_layout.dart';

/// The segmented toggle bar at the top of the sheet.
///
/// Nothing is left to put in it: Desktop is a page action now and the other
/// toggles it carried are gone. Kept as an empty section only so a stored
/// layout that still names it has somewhere to land.
class QuickTogglesSection extends StatelessWidget {
  final String selectedTabId;
  final List<MenuItemType> items;

  const QuickTogglesSection({
    super.key,
    required this.selectedTabId,
    required this.items,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
