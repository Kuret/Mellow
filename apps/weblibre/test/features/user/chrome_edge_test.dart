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
import 'package:weblibre/features/user/data/models/zen_settings.dart';

void main() {
  group('chromeEdge', () {
    test('the same settings give the rail at 800 and the bar at 400', () {
      final settings = GeneralSettings.withDefaults();
      final wide = settings.chromeEdge(viewportWidth: 800);
      final narrow = settings.chromeEdge(viewportWidth: 400);

      expect(wide.isVertical, isTrue, reason: 'side rail on a wide viewport');
      expect(wide, TabBarPosition.left, reason: 'RailSide defaults to left');
      expect(narrow.isHorizontal, isTrue, reason: 'compact bar when narrow');
      expect(narrow, TabBarPosition.bottom);
    });

    test('railSide.right docks the rail on the right', () {
      expect(
        GeneralSettings.withDefaults(
          railSide: RailSide.right,
        ).chromeEdge(viewportWidth: 800),
        TabBarPosition.right,
      );
    });

    test('the rail side is ignored on a narrow viewport', () {
      expect(
        GeneralSettings.withDefaults(
          railSide: RailSide.right,
          tabBarPosition: TabBarPosition.top,
        ).chromeEdge(viewportWidth: 400),
        TabBarPosition.top,
      );
    });

    test('a stored side position reads as a bottom compact bar', () {
      for (final legacy in const [TabBarPosition.left, TabBarPosition.right]) {
        expect(
          GeneralSettings.withDefaults(
            tabBarPosition: legacy,
          ).chromeEdge(viewportWidth: 400),
          TabBarPosition.bottom,
          reason: 'stored $legacy',
        );
      }
    });

    test('switches exactly at the breakpoint', () {
      final settings = GeneralSettings.withDefaults();
      expect(
        settings
            .chromeEdge(viewportWidth: narrowRailViewportBreakpoint - 1)
            .isHorizontal,
        isTrue,
      );
      expect(
        settings
            .chromeEdge(viewportWidth: narrowRailViewportBreakpoint)
            .isVertical,
        isTrue,
      );
    });
  });
}
