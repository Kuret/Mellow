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
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';

void main() {
  /// The call the browser screen makes: the rail side from `ZenSettings`, the
  /// narrow-viewport edge from upstream's `GeneralSettings`.
  TabBarPosition edge({
    required double viewportWidth,
    RailSide railSide = RailSide.left,
    TabBarPosition tabBarPosition = TabBarPosition.bottom,
  }) => chromeEdge(
    viewportWidth: viewportWidth,
    railSide: railSide,
    narrowPosition: GeneralSettings.withDefaults(
      tabBarPosition: tabBarPosition,
    ).effectiveTabBarPosition,
  );

  group('chromeEdge', () {
    test('the same settings give the rail at 800 and the bar at 400', () {
      final wide = edge(viewportWidth: 800);
      final narrow = edge(viewportWidth: 400);

      expect(wide.isVertical, isTrue, reason: 'side rail on a wide viewport');
      expect(wide, TabBarPosition.left, reason: 'RailSide defaults to left');
      expect(narrow.isHorizontal, isTrue, reason: 'compact bar when narrow');
      expect(narrow, TabBarPosition.bottom);
    });

    test('railSide.right docks the rail on the right', () {
      expect(
        edge(viewportWidth: 800, railSide: RailSide.right),
        TabBarPosition.right,
      );
    });

    test('the rail side is ignored on a narrow viewport', () {
      expect(
        edge(
          viewportWidth: 400,
          railSide: RailSide.right,
          tabBarPosition: TabBarPosition.top,
        ),
        TabBarPosition.top,
      );
    });

    test('a stored side position reads as a bottom compact bar', () {
      for (final legacy in const [TabBarPosition.left, TabBarPosition.right]) {
        expect(
          edge(viewportWidth: 400, tabBarPosition: legacy),
          TabBarPosition.bottom,
          reason: 'stored $legacy',
        );
      }
    });

    test('switches exactly at the breakpoint', () {
      expect(
        edge(viewportWidth: narrowRailViewportBreakpoint - 1).isHorizontal,
        isTrue,
      );
      expect(
        edge(viewportWidth: narrowRailViewportBreakpoint).isVertical,
        isTrue,
      );
    });
  });
}
