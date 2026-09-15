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
import 'package:mellow/features/user/data/models/zen_settings.dart';

/// Whether a back gesture should open the narrow-viewport compact bar's
/// slide-out tab rail instead of running the browser's ordinary back, and —
/// since [CompactRailSide.either] does not fix a single edge — which
/// [RailSide] the panel should open on. `null` means "do not claim this
/// gesture"; any other result both claims it and says where the panel goes.
///
/// Covers both callers this decides for:
///  * A predictive back gesture (API 33+), which knows [swipeEdge] — on
///    [CompactRailSide.left]/[CompactRailSide.right] the panel opens only
///    when the gesture came from that edge; on [CompactRailSide.either] a
///    gesture from *either* edge is claimed, and opens the panel on the edge
///    it came from.
///  * A plain, already-committed back with no predictive events at all
///    (API < 33, or 3-button navigation) — there [swipeEdge] is `null`, and
///    there is no edge to go by: any back claims, opening the panel on the
///    configured edge, or — on [CompactRailSide.either], which does not name
///    one — the left edge. (An arbitrary but fixed choice: without a
///    predictive event there is nothing gesture-side to prefer one edge
///    over the other.)
///
/// `null` whenever [side] is `null` (the setting is off — default, and the
/// only way an existing user's back gesture never changes), the viewport is
/// not [isNarrowViewport] (the wide rail is docked already; there is nothing
/// to slide out), the panel [isOpen] already (a back gesture then performs
/// the browser's own back, which is the point of leaving the panel open),
/// or the browser screen is not [isCurrentRoute] (it stays mounted under
/// pushed routes such as Settings or Bookmarks, and must not steal their
/// back gesture).
RailSide? resolveCompactRailBackGesture({
  required CompactRailSide? side,
  required bool isNarrowViewport,
  required bool isOpen,
  required SwipeEdge? swipeEdge,
  required bool isCurrentRoute,
}) {
  if (side == null || !isNarrowViewport || isOpen || !isCurrentRoute) {
    return null;
  }

  if (swipeEdge == null) {
    // No predictive events at all: nothing to match the edge against, and
    // for `either` nothing to prefer one edge over the other with — pick
    // left, arbitrarily but consistently.
    return switch (side) {
      CompactRailSide.left => RailSide.left,
      CompactRailSide.right => RailSide.right,
      CompactRailSide.either => RailSide.left,
    };
  }

  final gestureSide = switch (swipeEdge) {
    SwipeEdge.left => RailSide.left,
    SwipeEdge.right => RailSide.right,
  };

  return switch (side) {
    CompactRailSide.left => gestureSide == RailSide.left ? RailSide.left : null,
    CompactRailSide.right =>
      gestureSide == RailSide.right ? RailSide.right : null,
    // Either edge opens the panel — on the edge it came from.
    CompactRailSide.either => gestureSide,
  };
}
