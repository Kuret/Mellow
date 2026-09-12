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
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// A space's icon: Zen stores a free string (usually an emoji, sometimes a
/// short label), so this renders the text when there is one and the generic
/// space glyph otherwise.
class SpaceIcon extends StatelessWidget {
  final String? icon;
  final double size;
  final Color? color;

  const SpaceIcon({super.key, required this.icon, this.size = 18, this.color});

  @override
  Widget build(BuildContext context) {
    final text = icon?.trim();
    if (text == null || text.isEmpty) {
      return Icon(MdiIcons.viewDashboardOutline, size: size, color: color);
    }
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(fontSize: size, color: color, height: 1),
        ),
      ),
    );
  }
}

/// [SpaceIcon] on a tonal disc, for the editor header and list rows.
class SpaceIconAvatar extends StatelessWidget {
  final String? icon;
  final double radius;

  const SpaceIconAvatar({super.key, required this.icon, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      child: SpaceIcon(
        icon: icon,
        size: radius,
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}
