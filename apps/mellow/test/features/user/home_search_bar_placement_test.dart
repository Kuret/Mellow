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
  group('effectiveHomeSearchBarPlacement', () {
    GeneralSettings settingsWith({required TabBarPosition position}) =>
        GeneralSettings.withDefaults(tabBarPosition: position);

    test('follows a bottom tab bar into the tab bar', () {
      expect(
        settingsWith(
          position: TabBarPosition.bottom,
        ).effectiveHomeSearchBarPlacement(),
        HomeSearchBarPlacement.tabBar,
      );
    });

    // The side values predate the viewport-driven layout and read as bottom
    // (effectiveTabBarPosition), so they resolve the way bottom does.
    test('reads the legacy side positions as a bottom tab bar', () {
      for (final position in const [
        TabBarPosition.left,
        TabBarPosition.right,
      ]) {
        expect(
          settingsWith(position: position).effectiveHomeSearchBarPlacement(),
          HomeSearchBarPlacement.tabBar,
          reason: 'tab bar at $position',
        );
      }
    });

    test('resolves to the pill for a top tab bar', () {
      expect(
        settingsWith(
          position: TabBarPosition.top,
        ).effectiveHomeSearchBarPlacement(),
        HomeSearchBarPlacement.top,
      );
    });
  });
}
