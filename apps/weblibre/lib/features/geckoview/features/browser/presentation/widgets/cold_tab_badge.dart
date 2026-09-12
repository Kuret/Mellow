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

/// A tab favicon with a small snowflake in its bottom-right corner: the mark
/// of a cold tab, one rendered from its row because it has no engine session
/// (PLAN §7.4). Surfaces pair it with [opacity] on the whole row.
///
/// Keeps the exact [size] footprint of the bare icon so a cold chip is no
/// wider than a live one; only the badge corner bleeds.
class ColdTabBadge extends StatelessWidget {
  /// How much a cold row is dimmed.
  static const opacity = 0.6;

  final double size;
  final Widget child;

  const ColdTabBadge({super.key, required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badgeSize = (size * 0.55).clamp(12.0, 18.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          Positioned(
            right: -badgeSize / 4,
            bottom: -badgeSize / 4,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surfaceContainer, width: 1.0),
              ),
              child: Icon(
                MdiIcons.snowflakeVariant,
                size: badgeSize * 0.7,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
