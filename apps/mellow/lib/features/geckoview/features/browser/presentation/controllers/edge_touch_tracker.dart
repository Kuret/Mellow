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

/// Remembers which screen edge the last system back swipe started from, as
/// seen from the app's own touch stream.
///
/// A predictive back gesture names its edge in
/// `PredictiveBackEvent.swipeEdge`, but only when its start event arrives.
/// Some backs reach the app as a bare "back" with no start event at all —
/// One UI does this for quick flicks, and Android does it for a swipe that
/// lands while the previous back's animation is still running — and those
/// carry no edge. The touch itself still tells: with gesture navigation the
/// app receives the finger going down at the edge, and then a cancel once the
/// system recognises the swipe and takes the pointer for itself. A down in an
/// edge zone followed by a cancel (not an up) is that swipe.
///
/// Fed every pointer event from a global pointer route, so it sees touches on
/// the browser's platform view as well (hybrid composition routes them through
/// Flutter first).
class EdgeTouchTracker {
  EdgeTouchTracker({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// How long a recognised edge swipe stays usable. The back it belongs to is
  /// committed when the finger lifts, normally well inside this; anything
  /// older is a different gesture.
  static const maxAge = Duration(seconds: 5);

  /// The narrowest edge zone used when the platform reports none (or a very
  /// thin one): wide enough for a thumb landing at the edge, narrow enough
  /// that a cancelled scroll in the page is not mistaken for a swipe.
  static const minEdgeZone = 24.0;

  final DateTime Function() _clock;

  /// Logical width of the view, and how far each system gesture zone reaches
  /// in from its edge. Kept current by whoever installs the tracker.
  double viewportWidth = 0;
  double leftEdgeZone = 0;
  double rightEdgeZone = 0;

  int? _pointer;
  SwipeEdge? _downEdge;
  final Set<int> _down = <int>{};

  SwipeEdge? _swipedEdge;
  DateTime? _swipedAt;

  void handleEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;

    if (event is PointerDownEvent) {
      _down.add(event.pointer);
      // A new touch makes any earlier swipe stale, whatever this one is.
      _clearSwipe();
      if (_down.length == 1) {
        _pointer = event.pointer;
        _downEdge = _edgeAt(event.position.dx);
      } else {
        // A system back swipe is one finger; with several down, a cancel
        // means something else.
        _pointer = null;
        _downEdge = null;
      }
    } else if (event is PointerCancelEvent || event is PointerUpEvent) {
      _down.remove(event.pointer);
      if (event.pointer != _pointer) return;

      if (event is PointerCancelEvent && _downEdge != null) {
        _swipedEdge = _downEdge;
        _swipedAt = _clock();
      }
      _pointer = null;
      _downEdge = null;
    }
  }

  /// The edge of a swipe the system took over within [maxAge], consumed by
  /// the call so one swipe answers for one back only.
  SwipeEdge? takeRecentSwipeEdge() {
    final edge = _swipedEdge;
    final at = _swipedAt;
    _clearSwipe();
    if (edge == null || at == null) return null;
    return _clock().difference(at) <= maxAge ? edge : null;
  }

  /// Forgets the last swipe without reading it — for a back whose edge the
  /// platform already reported, so the swipe cannot answer for a later one.
  void forgetSwipe() => _clearSwipe();

  void _clearSwipe() {
    _swipedEdge = null;
    _swipedAt = null;
  }

  SwipeEdge? _edgeAt(double x) {
    if (viewportWidth <= 0) return null;
    final left = leftEdgeZone < minEdgeZone ? minEdgeZone : leftEdgeZone;
    final right = rightEdgeZone < minEdgeZone ? minEdgeZone : rightEdgeZone;
    if (x <= left) return SwipeEdge.left;
    if (x >= viewportWidth - right) return SwipeEdge.right;
    return null;
  }
}
