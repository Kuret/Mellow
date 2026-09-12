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
  group('effectiveTabBarStackingMode', () {
    GeneralSettings settings({
      required TabBarPosition position,
      required double railWidth,
      TabBarStackingMode mode = TabBarStackingMode.twoLevel,
      bool showContainerUi = true,
    }) => GeneralSettings.withDefaults(
      tabBarPosition: position,
      railWidth: railWidth,
      tabBarStackingMode: mode,
      showContainerUi: showContainerUi,
    );

    test('keeps twoLevel on a wide vertical rail', () {
      expect(
        settings(
          position: TabBarPosition.left,
          railWidth: minWideRailWidth,
        ).effectiveTabBarStackingMode(viewportWidth: 1000),
        TabBarStackingMode.twoLevel,
      );
    });

    test('degrades twoLevel to accordion on a narrow vertical rail', () {
      expect(
        settings(
          position: TabBarPosition.right,
          railWidth: minWideRailWidth - 1,
        ).effectiveTabBarStackingMode(viewportWidth: 1000),
        TabBarStackingMode.accordion,
      );
    });

    test(
      'degrades twoLevel on a narrow viewport even with a wide railWidth',
      () {
        expect(
          settings(
            position: TabBarPosition.left,
            railWidth: maxRailWidth,
          ).effectiveTabBarStackingMode(
            viewportWidth: narrowRailViewportBreakpoint - 1,
          ),
          TabBarStackingMode.accordion,
        );
      },
    );

    test('without a viewport only railWidth decides', () {
      expect(
        settings(
          position: TabBarPosition.left,
          railWidth: minWideRailWidth,
        ).effectiveTabBarStackingMode(),
        TabBarStackingMode.twoLevel,
      );
    });

    test('keeps twoLevel on a horizontal bar', () {
      expect(
        settings(
          position: TabBarPosition.bottom,
          railWidth: minRailWidth,
        ).effectiveTabBarStackingMode(viewportWidth: 400),
        TabBarStackingMode.twoLevel,
      );
    });

    test('spaceTabs does not depend on the container UI', () {
      expect(
        settings(
          position: TabBarPosition.bottom,
          railWidth: minRailWidth,
          mode: TabBarStackingMode.spaceTabs,
          showContainerUi: false,
        ).effectiveTabBarStackingMode(),
        TabBarStackingMode.spaceTabs,
      );
    });

    test('container modes still degrade without the container UI', () {
      expect(
        settings(
          position: TabBarPosition.bottom,
          railWidth: minRailWidth,
          mode: TabBarStackingMode.containerTabs,
          showContainerUi: false,
        ).effectiveTabBarStackingMode(),
        TabBarStackingMode.lastUsedTabs,
      );
    });
  });
}
