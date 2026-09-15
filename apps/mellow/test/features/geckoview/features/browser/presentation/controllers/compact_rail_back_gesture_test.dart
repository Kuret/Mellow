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
  group('resolveCompactRailBackGesture', () {
    test('never claims with the setting off, whatever else is true', () {
      for (final swipeEdge in [null, SwipeEdge.left, SwipeEdge.right]) {
        for (final isNarrow in [true, false]) {
          for (final isOpen in [true, false]) {
            for (final isCurrent in [true, false]) {
              expect(
                resolveCompactRailBackGesture(
                  side: null,
                  isNarrowViewport: isNarrow,
                  isOpen: isOpen,
                  swipeEdge: swipeEdge,
                  isCurrentRoute: isCurrent,
                ),
                isNull,
                reason:
                    'swipeEdge=$swipeEdge isNarrow=$isNarrow '
                    'isOpen=$isOpen isCurrent=$isCurrent',
              );
            }
          }
        }
      }
    });

    test('claims a predictive gesture from the matching edge, opening on it', () {
      expect(
        resolveCompactRailBackGesture(
          side: CompactRailSide.left,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: SwipeEdge.left,
          isCurrentRoute: true,
        ),
        RailSide.left,
      );
      expect(
        resolveCompactRailBackGesture(
          side: CompactRailSide.right,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: SwipeEdge.right,
          isCurrentRoute: true,
        ),
        RailSide.right,
      );
    });

    test('never claims a predictive gesture from the other edge, so it keeps '
        'doing what it does today', () {
      expect(
        resolveCompactRailBackGesture(
          side: CompactRailSide.left,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: SwipeEdge.right,
          isCurrentRoute: true,
        ),
        isNull,
      );
      expect(
        resolveCompactRailBackGesture(
          side: CompactRailSide.right,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: SwipeEdge.left,
          isCurrentRoute: true,
        ),
        isNull,
      );
    });

    test(
      'on either side, claims a predictive gesture from both edges, opening '
      'on the edge it came from',
      () {
        expect(
          resolveCompactRailBackGesture(
            side: CompactRailSide.either,
            isNarrowViewport: true,
            isOpen: false,
            swipeEdge: SwipeEdge.left,
            isCurrentRoute: true,
          ),
          RailSide.left,
        );
        expect(
          resolveCompactRailBackGesture(
            side: CompactRailSide.either,
            isNarrowViewport: true,
            isOpen: false,
            swipeEdge: SwipeEdge.right,
            isCurrentRoute: true,
          ),
          RailSide.right,
        );
      },
    );

    test('never claims on a wide viewport', () {
      for (final side in CompactRailSide.values) {
        expect(
          resolveCompactRailBackGesture(
            side: side,
            isNarrowViewport: false,
            isOpen: false,
            swipeEdge: SwipeEdge.left,
            isCurrentRoute: true,
          ),
          isNull,
        );
      }
    });

    test('never claims while the panel is already open', () {
      for (final side in CompactRailSide.values) {
        expect(
          resolveCompactRailBackGesture(
            side: side,
            isNarrowViewport: true,
            isOpen: true,
            swipeEdge: SwipeEdge.left,
            isCurrentRoute: true,
          ),
          isNull,
        );
      }
    });

    test(
      'never claims when the browser screen is not the current route, so a '
      'pushed screen (Settings, Bookmarks, ...) keeps its own back gesture',
      () {
        for (final side in CompactRailSide.values) {
          expect(
            resolveCompactRailBackGesture(
              side: side,
              isNarrowViewport: true,
              isOpen: false,
              swipeEdge: SwipeEdge.left,
              isCurrentRoute: false,
            ),
            isNull,
          );
        }
      },
    );

    test('a plain committed back (no predictive events) claims regardless of '
        'edge, opening on the configured edge', () {
      expect(
        resolveCompactRailBackGesture(
          side: CompactRailSide.left,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: null,
          isCurrentRoute: true,
        ),
        RailSide.left,
      );
      expect(
        resolveCompactRailBackGesture(
          side: CompactRailSide.right,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: null,
          isCurrentRoute: true,
        ),
        RailSide.right,
      );
    });

    test(
      'a plain committed back on either side falls back to the left edge, '
      'since there is no gesture edge to prefer one over the other with',
      () {
        expect(
          resolveCompactRailBackGesture(
            side: CompactRailSide.either,
            isNarrowViewport: true,
            isOpen: false,
            swipeEdge: null,
            isCurrentRoute: true,
          ),
          RailSide.left,
        );
      },
    );

    test('a plain committed back still respects narrow/open/current', () {
      expect(
        resolveCompactRailBackGesture(
          side: CompactRailSide.left,
          isNarrowViewport: false,
          isOpen: false,
          swipeEdge: null,
          isCurrentRoute: true,
        ),
        isNull,
      );
      expect(
        resolveCompactRailBackGesture(
          side: CompactRailSide.left,
          isNarrowViewport: true,
          isOpen: true,
          swipeEdge: null,
          isCurrentRoute: true,
        ),
        isNull,
      );
      expect(
        resolveCompactRailBackGesture(
          side: CompactRailSide.left,
          isNarrowViewport: true,
          isOpen: false,
          swipeEdge: null,
          isCurrentRoute: false,
        ),
        isNull,
      );
    });
  });
}
