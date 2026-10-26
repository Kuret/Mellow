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
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show SwipeEdge;
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/controllers/edge_touch_tracker.dart';

void main() {
  late DateTime now;
  late EdgeTouchTracker tracker;

  setUp(() {
    now = DateTime(2026, 10, 26, 12);
    tracker = EdgeTouchTracker(clock: () => now)
      ..viewportWidth = 400
      ..leftEdgeZone = 30
      ..rightEdgeZone = 30;
  });

  PointerDownEvent down(double x, {int pointer = 1}) =>
      PointerDownEvent(pointer: pointer, position: Offset(x, 300));
  PointerCancelEvent cancel({int pointer = 1}) =>
      PointerCancelEvent(pointer: pointer);
  PointerUpEvent up({int pointer = 1}) => PointerUpEvent(pointer: pointer);

  test('a touch at the left edge the system takes over is a left swipe', () {
    tracker
      ..handleEvent(down(10))
      ..handleEvent(cancel());

    expect(tracker.takeRecentSwipeEdge(), SwipeEdge.left);
  });

  test('a touch at the right edge the system takes over is a right swipe', () {
    tracker
      ..handleEvent(down(390))
      ..handleEvent(cancel());

    expect(tracker.takeRecentSwipeEdge(), SwipeEdge.right);
  });

  test('a swipe answers for one back only', () {
    tracker
      ..handleEvent(down(10))
      ..handleEvent(cancel());

    expect(tracker.takeRecentSwipeEdge(), SwipeEdge.left);
    expect(tracker.takeRecentSwipeEdge(), isNull);
  });

  test('an edge touch that lifts normally is not a swipe', () {
    tracker
      ..handleEvent(down(10))
      ..handleEvent(up());

    expect(tracker.takeRecentSwipeEdge(), isNull);
  });

  test('a cancelled touch away from the edges is not a swipe', () {
    tracker
      ..handleEvent(down(200))
      ..handleEvent(cancel());

    expect(tracker.takeRecentSwipeEdge(), isNull);
  });

  test('a later touch makes an earlier swipe stale', () {
    tracker
      ..handleEvent(down(10))
      ..handleEvent(cancel())
      ..handleEvent(down(200))
      ..handleEvent(up());

    expect(tracker.takeRecentSwipeEdge(), isNull);
  });

  test('an old swipe does not answer for a back', () {
    tracker
      ..handleEvent(down(10))
      ..handleEvent(cancel());
    now = now.add(EdgeTouchTracker.maxAge + const Duration(seconds: 1));

    expect(tracker.takeRecentSwipeEdge(), isNull);
  });

  test('a cancel with several fingers down is not a swipe', () {
    tracker
      ..handleEvent(down(10))
      ..handleEvent(down(200, pointer: 2))
      ..handleEvent(cancel())
      ..handleEvent(cancel(pointer: 2));

    expect(tracker.takeRecentSwipeEdge(), isNull);
  });

  test('a swipe already accounted for is forgotten', () {
    tracker
      ..handleEvent(down(10))
      ..handleEvent(cancel())
      ..forgetSwipe();

    expect(tracker.takeRecentSwipeEdge(), isNull);
  });

  test('an unreported gesture zone falls back to a minimum width', () {
    tracker
      ..leftEdgeZone = 0
      ..handleEvent(down(EdgeTouchTracker.minEdgeZone - 1))
      ..handleEvent(cancel());

    expect(tracker.takeRecentSwipeEdge(), SwipeEdge.left);
  });

  test('mouse and stylus events are ignored', () {
    tracker
      ..handleEvent(
        const PointerDownEvent(
          pointer: 1,
          kind: PointerDeviceKind.mouse,
          position: Offset(10, 300),
        ),
      )
      ..handleEvent(
        const PointerCancelEvent(pointer: 1, kind: PointerDeviceKind.mouse),
      );

    expect(tracker.takeRecentSwipeEdge(), isNull);
  });
}
