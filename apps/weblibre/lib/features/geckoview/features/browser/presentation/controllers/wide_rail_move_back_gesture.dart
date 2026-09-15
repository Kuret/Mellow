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
import 'package:weblibre/features/user/data/models/zen_settings.dart';

/// Whether a back gesture should move the wide-viewport docked side rail to
/// the opposite edge, instead of running the browser's ordinary back.
///
/// The rail is always docked on a wide viewport, so unlike the narrow
/// compact bar's slide-out panel there is nothing to slide in — a claimed
/// gesture here just flips [ZenSettings.railSide] to the edge the gesture
/// came from. Returns the new [RailSide] to move to, or `null` to leave the
/// gesture unclaimed (an ordinary back).
///
/// `null` whenever [enabled] is `false` (the setting is off — default, and
/// the only way an existing user's back gesture on a wide viewport never
/// changes), the viewport is not [isWideViewport] (the narrow compact bar
/// has its own slide-out for this), [isCurrentRoute] is false (the browser
/// stays mounted under pushed routes), or there is no [swipeEdge] to go by —
/// unlike the compact rail's slide-out, there is no sensible fallback here:
/// with no edge known, which way to move the rail cannot be decided, so the
/// gesture is left as an ordinary back.
///
/// Also `null` when [swipeEdge] names the edge the rail is already docked
/// to: a back gesture *from the rail's own edge* always still goes back,
/// which is what makes "swipe from the other edge" a promise rather than a
/// coincidence.
RailSide? resolveWideRailMoveBackGesture({
  required bool enabled,
  required RailSide currentSide,
  required bool isWideViewport,
  required SwipeEdge? swipeEdge,
  required bool isCurrentRoute,
}) {
  if (!enabled || !isWideViewport || !isCurrentRoute || swipeEdge == null) {
    return null;
  }

  final gestureSide = switch (swipeEdge) {
    SwipeEdge.left => RailSide.left,
    SwipeEdge.right => RailSide.right,
  };

  return gestureSide == currentSide ? null : gestureSide;
}
