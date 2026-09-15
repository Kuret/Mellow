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
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/core/design/app_theme.dart';

/// The largest gap between any two of a color's R/G/B channels. A color
/// where this stays small reads as a neutral grey (or black/white) rather
/// than carrying any hue.
int _maxChannelSpread(Color color) {
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  final maxChannel = [r, g, b].reduce((a, b) => a > b ? a : b);
  final minChannel = [r, g, b].reduce((a, b) => a < b ? a : b);
  return maxChannel - minChannel;
}

void main() {
  group('buildAppColorScheme', () {
    const accent = Color(0xFF3F80EA);

    // Every surface role a Windows-Phone-style neutral scheme must not tint
    // toward the accent's hue. `ColorScheme.fromSeed` fails this by design —
    // that's the muddy blue-grey look this scheme replaces.
    const neutralRoles = <String>[
      'surface',
      'onSurface',
      'surfaceContainerLowest',
      'surfaceContainerLow',
      'surfaceContainer',
      'surfaceContainerHigh',
      'surfaceContainerHighest',
      'onSurfaceVariant',
      'outline',
      'outlineVariant',
    ];

    Map<String, Color> rolesOf(ColorScheme scheme) => {
      'surface': scheme.surface,
      'onSurface': scheme.onSurface,
      'surfaceContainerLowest': scheme.surfaceContainerLowest,
      'surfaceContainerLow': scheme.surfaceContainerLow,
      'surfaceContainer': scheme.surfaceContainer,
      'surfaceContainerHigh': scheme.surfaceContainerHigh,
      'surfaceContainerHighest': scheme.surfaceContainerHighest,
      'onSurfaceVariant': scheme.onSurfaceVariant,
      'outline': scheme.outline,
      'outlineVariant': scheme.outlineVariant,
    };

    for (final brightness in Brightness.values) {
      test('every surface role is neutral in $brightness', () {
        final scheme = buildAppColorScheme(
          brightness: brightness,
          accent: accent,
        );
        final roles = rolesOf(scheme);

        for (final roleName in neutralRoles) {
          final color = roles[roleName]!;
          expect(
            _maxChannelSpread(color),
            lessThanOrEqualTo(10),
            reason: '$roleName ($color) is not neutral in $brightness',
          );
        }
      });
    }

    test('primary carries the accent, unlike the neutral surfaces', () {
      final scheme = buildAppColorScheme(
        brightness: Brightness.light,
        accent: accent,
      );
      expect(scheme.primary, accent);
    });

    test('onPrimary flips to white for a dark accent', () {
      final scheme = buildAppColorScheme(
        brightness: Brightness.light,
        // Near-black accent: white reads better on it than black.
        accent: const Color(0xFF1A1A2E),
      );
      expect(scheme.onPrimary, Colors.white);
    });

    test('onPrimary flips to black for a light accent', () {
      final scheme = buildAppColorScheme(
        brightness: Brightness.light,
        // Pale accent: black reads better on it than white.
        accent: const Color(0xFFF5E6A8),
      );
      expect(scheme.onPrimary, Colors.black);
    });

    test('pureBlack makes the dark surface pure black', () {
      final scheme = buildAppColorScheme(
        brightness: Brightness.dark,
        accent: accent,
        pureBlack: true,
      );
      expect(scheme.surface, const Color(0xFF000000));
    });

    test('without pureBlack the dark surface is not pure black', () {
      final scheme = buildAppColorScheme(
        brightness: Brightness.dark,
        accent: accent,
      );
      expect(scheme.surface, isNot(const Color(0xFF000000)));
    });

    test('light surface is pure white', () {
      final scheme = buildAppColorScheme(
        brightness: Brightness.light,
        accent: accent,
      );
      expect(scheme.surface, const Color(0xFFFFFFFF));
      expect(scheme.onSurface, const Color(0xFF000000));
    });
  });

  group('buildAppTheme', () {
    test('kills surface tinting on cards and app bars', () {
      final theme = buildAppTheme(
        brightness: Brightness.light,
        accent: const Color(0xFF3F80EA),
      );

      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
      expect(theme.cardTheme.elevation, 0);
    });

    test('drives switches and list-tile selection from the accent', () {
      const accent = Color(0xFF3F80EA);
      final theme = buildAppTheme(brightness: Brightness.light, accent: accent);

      expect(theme.listTileTheme.selectedColor, accent);
      expect(
        theme.switchTheme.thumbColor?.resolve({WidgetState.selected}),
        accent,
      );
    });
  });

  test('kAccentChoices offers a curated, non-empty palette', () {
    expect(kAccentChoices, isNotEmpty);
    expect(kAccentChoices.toSet().length, kAccentChoices.length);
  });
}
