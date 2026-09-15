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
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/compact_rail_back_gesture.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';

void main() {
  group('shouldClaimCompactRailBackGesture', () {
    test('never claims with the setting off, whatever else is true', () {
      for (final swipeEdge in [null, SwipeEdge.left, SwipeEdge.right]) {
        for (final isNarrow in [true, false]) {
          for (final isOpen in [true, false]) {
            for (final isCurrent in [true, false]) {
              expect(
                shouldClaimCompactRailBackGesture(
                  side: null,
                  isNarrowViewport: isNarrow,
                  isOpen: isOpen,
                  swipeEdge: swipeEdge,
                  isCurrentRoute: isCurrent,
                ),
                isFalse,
                reason:
                    'swipeEdge=$swipeEdge isNarrow=$isNarrow '
                    'isOpen=$isOpen isCurrent=$isCurrent',
              );
            }
          }
        }
      }
    });

    test('claims a predictive gesture from the matching edge', () {
      expect(
        shouldClaimCompactRailBackGesture(
          side: RailSide.left,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: SwipeEdge.left,
          isCurrentRoute: true,
        ),
        isTrue,
      );
      expect(
        shouldClaimCompactRailBackGesture(
          side: RailSide.right,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: SwipeEdge.right,
          isCurrentRoute: true,
        ),
        isTrue,
      );
    });

    test('never claims a predictive gesture from the other edge, so it keeps '
        'doing what it does today', () {
      expect(
        shouldClaimCompactRailBackGesture(
          side: RailSide.left,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: SwipeEdge.right,
          isCurrentRoute: true,
        ),
        isFalse,
      );
      expect(
        shouldClaimCompactRailBackGesture(
          side: RailSide.right,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: SwipeEdge.left,
          isCurrentRoute: true,
        ),
        isFalse,
      );
    });

    test('never claims on a wide viewport', () {
      for (final side in RailSide.values) {
        expect(
          shouldClaimCompactRailBackGesture(
            side: side,
            isNarrowViewport: false,
            isOpen: false,
            swipeEdge: side == RailSide.left ? SwipeEdge.left : SwipeEdge.right,
            isCurrentRoute: true,
          ),
          isFalse,
        );
      }
    });

    test('never claims while the panel is already open', () {
      for (final side in RailSide.values) {
        expect(
          shouldClaimCompactRailBackGesture(
            side: side,
            isNarrowViewport: true,
            isOpen: true,
            swipeEdge: side == RailSide.left ? SwipeEdge.left : SwipeEdge.right,
            isCurrentRoute: true,
          ),
          isFalse,
        );
      }
    });

    test(
      'never claims when the browser screen is not the current route, so a '
      'pushed screen (Settings, Bookmarks, ...) keeps its own back gesture',
      () {
        for (final side in RailSide.values) {
          expect(
            shouldClaimCompactRailBackGesture(
              side: side,
              isNarrowViewport: true,
              isOpen: false,
              swipeEdge: side == RailSide.left
                  ? SwipeEdge.left
                  : SwipeEdge.right,
              isCurrentRoute: false,
            ),
            isFalse,
          );
        }
      },
    );

    test('a plain committed back (no predictive events) claims regardless of '
        'edge, as long as everything else is right', () {
      for (final side in RailSide.values) {
        expect(
          shouldClaimCompactRailBackGesture(
            side: side,
            isNarrowViewport: true,
            isOpen: false,
            swipeEdge: null,
            isCurrentRoute: true,
          ),
          isTrue,
        );
      }
    });

    test('a plain committed back still respects narrow/open/current', () {
      expect(
        shouldClaimCompactRailBackGesture(
          side: RailSide.left,
          isNarrowViewport: false,
          isOpen: false,
          swipeEdge: null,
          isCurrentRoute: true,
        ),
        isFalse,
      );
      expect(
        shouldClaimCompactRailBackGesture(
          side: RailSide.left,
          isNarrowViewport: true,
          isOpen: true,
          swipeEdge: null,
          isCurrentRoute: true,
        ),
        isFalse,
      );
      expect(
        shouldClaimCompactRailBackGesture(
          side: RailSide.left,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: null,
          isCurrentRoute: false,
        ),
        isFalse,
      );
    });
  });
}
