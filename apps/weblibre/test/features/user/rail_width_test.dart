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
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';

void main() {
  group('isWideViewport', () {
    test(
      'is false below narrowRailViewportBreakpoint (a phone in portrait)',
      () {
        expect(isWideViewport(narrowRailViewportBreakpoint - 1), isFalse);
        expect(isWideViewport(360), isFalse);
      },
    );

    test('is true at and above narrowRailViewportBreakpoint', () {
      expect(isWideViewport(narrowRailViewportBreakpoint), isTrue);
      expect(isWideViewport(1000), isTrue);
    });
  });

  group('effectiveRailWidth', () {
    test('returns railWidth inside the allowed range', () {
      expect(effectiveRailWidth(railWidth: 200), 200);
      expect(effectiveRailWidth(railWidth: minRailWidth), minRailWidth);
      expect(effectiveRailWidth(railWidth: maxRailWidth), maxRailWidth);
    });

    test(
      'clamps a stored width from the icon-only rail up to minRailWidth',
      () {
        expect(effectiveRailWidth(railWidth: 56), minRailWidth);
      },
    );

    test('clamps above maxRailWidth', () {
      expect(effectiveRailWidth(railWidth: 1000), maxRailWidth);
    });
  });

  group('GeneralSettings.railWidth', () {
    test('defaults to defaultRailWidth', () {
      expect(GeneralSettings.withDefaults().railWidth, defaultRailWidth);
      expect(defaultRailWidth, 260);
      expect(minRailWidth, 160);
    });

    test('a stored value below minRailWidth reads as minRailWidth', () {
      expect(
        GeneralSettings.withDefaults(railWidth: 56).railWidth,
        minRailWidth,
      );
      expect(
        GeneralSettings.fromJson({'railWidth': 56.0}).railWidth,
        minRailWidth,
      );
    });
  });
}
