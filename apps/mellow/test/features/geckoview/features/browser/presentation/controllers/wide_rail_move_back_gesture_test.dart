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
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
import 'package:flutter/services.dart' show SwipeEdge;
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/controllers/wide_rail_move_back_gesture.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';

void main() {
  group('resolveWideRailMoveBackGesture', () {
    test('never claims with the setting off, whatever else is true', () {
      for (final currentSide in RailSide.values) {
        for (final swipeEdge in [null, SwipeEdge.left, SwipeEdge.right]) {
          for (final isWide in [true, false]) {
            for (final isCurrent in [true, false]) {
              expect(
                resolveWideRailMoveBackGesture(
                  enabled: false,
                  currentSide: currentSide,
                  isWideViewport: isWide,
                  swipeEdge: swipeEdge,
                  isCurrentRoute: isCurrent,
                ),
                isNull,
                reason:
                    'currentSide=$currentSide swipeEdge=$swipeEdge '
                    'isWide=$isWide isCurrent=$isCurrent',
              );
            }
          }
        }
      }
    });

    test(
      'claims a gesture from the edge opposite the rail, moving it there',
      () {
        expect(
          resolveWideRailMoveBackGesture(
            enabled: true,
            currentSide: RailSide.left,
            isWideViewport: true,
            swipeEdge: SwipeEdge.right,
            isCurrentRoute: true,
          ),
          RailSide.right,
        );
        expect(
          resolveWideRailMoveBackGesture(
            enabled: true,
            currentSide: RailSide.right,
            isWideViewport: true,
            swipeEdge: SwipeEdge.left,
            isCurrentRoute: true,
          ),
          RailSide.left,
        );
      },
    );

    test("never claims a gesture from the rail's own edge, so that edge "
        'still goes back', () {
      expect(
        resolveWideRailMoveBackGesture(
          enabled: true,
          currentSide: RailSide.left,
          isWideViewport: true,
          swipeEdge: SwipeEdge.left,
          isCurrentRoute: true,
        ),
        isNull,
      );
      expect(
        resolveWideRailMoveBackGesture(
          enabled: true,
          currentSide: RailSide.right,
          isWideViewport: true,
          swipeEdge: SwipeEdge.right,
          isCurrentRoute: true,
        ),
        isNull,
      );
    });

    test('never claims on a narrow viewport', () {
      expect(
        resolveWideRailMoveBackGesture(
          enabled: true,
          currentSide: RailSide.left,
          isWideViewport: false,
          swipeEdge: SwipeEdge.right,
          isCurrentRoute: true,
        ),
        isNull,
      );
    });

    test('never claims when the browser screen is not the current route', () {
      expect(
        resolveWideRailMoveBackGesture(
          enabled: true,
          currentSide: RailSide.left,
          isWideViewport: true,
          swipeEdge: SwipeEdge.right,
          isCurrentRoute: false,
        ),
        isNull,
      );
    });

    test('never claims a plain committed back with no predictive events: there '
        'is no edge to decide the direction from', () {
      expect(
        resolveWideRailMoveBackGesture(
          enabled: true,
          currentSide: RailSide.left,
          isWideViewport: true,
          swipeEdge: null,
          isCurrentRoute: true,
        ),
        isNull,
      );
    });
  });
}
