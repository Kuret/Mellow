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

/// Lays [buttons] out in one horizontal row: spread evenly across the space
/// given when they all fit, or scrolling horizontally instead of overflowing
/// when they don't. The user's configured set can be anywhere from zero to a
/// couple dozen buttons, so whatever hosts this needs a row that survives
/// either end without a `RenderFlex` overflow.
///
/// Needs a bounded width — wrap it in `Flexible`/`Expanded` (or size its
/// parent) rather than handing it straight to an unconstrained `Row`.
class ToolbarButtonsRow extends StatelessWidget {
  const ToolbarButtonsRow({super.key, required this.buttons});

  final List<Widget> buttons;

  static const _minButtonWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitsEvenly =
            constraints.maxWidth >= _minButtonWidth * buttons.length;

        if (fitsEvenly) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buttons,
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: buttons
                .map(
                  (button) => SizedBox(
                    width: _minButtonWidth,
                    child: Center(child: button),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
