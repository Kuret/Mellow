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
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/container_colors.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/firefox_container_vocab.dart';

/// Picks one of Firefox's nine contextual-identity colour keywords.
///
/// Pops the chosen keyword (`FirefoxContainerColor.keyword`) or null when
/// cancelled. [FirefoxContainerColor.toolbar] has no colour of its own and is
/// drawn as an outlined swatch in the theme's `onSurfaceVariant`.
class FirefoxContainerColorPicker extends HookWidget {
  final String initialColorKey;

  const FirefoxContainerColorPicker({required this.initialColorKey, super.key});

  @override
  Widget build(BuildContext context) {
    final selected = useState(
      FirefoxContainerColor.fromKeyword(initialColorKey),
    );

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 8.0,
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 24.0,
      ),
      title: const Text('Select Color'),
      content: SizedBox(
        width: 320,
        child: GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: FirefoxContainerColor.values.length,
          itemBuilder: (context, index) {
            final value = FirefoxContainerColor.values[index];
            return FirefoxContainerColorSwatch(
              color: value,
              isSelected: value == selected.value,
              onTap: () => selected.value = value,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<String?>(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop<String?>(context, selected.value.keyword),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

/// One swatch of the Firefox colour vocabulary. Coloured keywords render as
/// their seeded container colour; [FirefoxContainerColor.toolbar] as an outline
/// only, because it follows the theme rather than carrying a colour.
class FirefoxContainerColorSwatch extends StatelessWidget {
  const FirefoxContainerColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final FirefoxContainerColor color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final seed = color.color;
    final palette = seed == null
        ? null
        : ContainerColors.palette(context, seed);

    return Tooltip(
      message: color.keyword,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette?.containerColor ?? Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? colorScheme.onSurface
                  : (palette == null
                        ? colorScheme.onSurfaceVariant
                        : Colors.transparent),
              width: 2,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 20,
                  color: palette?.onContainerColor ?? colorScheme.onSurface,
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}
