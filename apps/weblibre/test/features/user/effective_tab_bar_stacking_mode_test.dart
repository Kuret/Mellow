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
// The stacking modes are retired; these tests pin down that a stored value
// still decodes and resolves to the one layout the bar has.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';

void main() {
  group('effectiveTabBarStackingMode', () {
    test('answers spaceTabs whatever mode a profile stored', () {
      for (final mode in TabBarStackingMode.values) {
        for (final position in TabBarPosition.values) {
          for (final showContainerUi in [true, false]) {
            expect(
              GeneralSettings.withDefaults(
                tabBarStackingMode: mode,
                tabBarPosition: position,
                showContainerUi: showContainerUi,
              ).effectiveTabBarStackingMode(),
              TabBarStackingMode.spaceTabs,
              reason: '$mode at $position, containers: $showContainerUi',
            );
          }
        }
      }
    });

    test('a stored stacking mode still decodes', () {
      final settings = GeneralSettings.fromJson({
        'tabBarStackingMode': 'twoLevel',
        'tabBarSwipeAction': 'navigateOrderedTabs',
      });
      expect(settings.tabBarStackingMode, TabBarStackingMode.twoLevel);
      expect(settings.tabBarSwipeAction, TabBarSwipeAction.navigateOrderedTabs);
    });
  });
}
