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
  group('isWideRail', () {
    test('is false on a horizontal tab bar regardless of railWidth', () {
      expect(
        isWideRail(isVertical: false, railWidth: 320, viewportWidth: 1000),
        isFalse,
      );
    });

    test('is false when railWidth is below minWideRailWidth', () {
      expect(
        isWideRail(
          isVertical: true,
          railWidth: minWideRailWidth - 1,
          viewportWidth: 1000,
        ),
        isFalse,
      );
    });

    test('is true at exactly minWideRailWidth on a wide viewport', () {
      expect(
        isWideRail(
          isVertical: true,
          railWidth: minWideRailWidth,
          viewportWidth: 1000,
        ),
        isTrue,
      );
    });

    test(
      'is false below narrowRailViewportBreakpoint even with a wide railWidth '
      '(a phone in portrait always collapses)',
      () {
        expect(
          isWideRail(
            isVertical: true,
            railWidth: maxRailWidth,
            viewportWidth: narrowRailViewportBreakpoint - 1,
          ),
          isFalse,
        );
      },
    );

    test('is true at exactly narrowRailViewportBreakpoint', () {
      expect(
        isWideRail(
          isVertical: true,
          railWidth: minWideRailWidth,
          viewportWidth: narrowRailViewportBreakpoint,
        ),
        isTrue,
      );
    });
  });

  group('effectiveRailWidth', () {
    test('returns railWidth when isWideRail holds', () {
      expect(
        effectiveRailWidth(
          isVertical: true,
          railWidth: 200,
          viewportWidth: 1000,
        ),
        200,
      );
    });

    test('falls back to defaultRailWidth on a horizontal tab bar', () {
      expect(
        effectiveRailWidth(
          isVertical: false,
          railWidth: 200,
          viewportWidth: 1000,
        ),
        defaultRailWidth,
      );
    });

    test('falls back to defaultRailWidth on a narrow viewport', () {
      expect(
        effectiveRailWidth(
          isVertical: true,
          railWidth: 200,
          viewportWidth: 360,
        ),
        defaultRailWidth,
      );
    });

    test('falls back to defaultRailWidth when railWidth is too small', () {
      expect(
        effectiveRailWidth(
          isVertical: true,
          railWidth: 56,
          viewportWidth: 1000,
        ),
        defaultRailWidth,
      );
    });
  });

  group('GeneralSettings.railWidth', () {
    test('defaults to kToolbarHeight (defaultRailWidth)', () {
      expect(GeneralSettings.withDefaults().railWidth, defaultRailWidth);
    });

    test('is clamped to [minRailWidth, maxRailWidth] on construction', () {
      expect(
        GeneralSettings.withDefaults(railWidth: 1000).railWidth,
        maxRailWidth,
      );
      expect(
        GeneralSettings.withDefaults(railWidth: 0).railWidth,
        minRailWidth,
      );
    });
  });
}
