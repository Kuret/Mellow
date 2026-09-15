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
import 'dart:async';

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/entities/container_cycle.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';

/// Travel that commits a space swipe on release when the fling was too slow.
/// Same figures as the tray's two-finger swipe (`tab_tray_gestures.dart`).
const spaceSwipeCommitDistance = 72.0;

/// Fling speed (px/s) that commits a shorter space swipe.
const spaceSwipeCommitVelocity = 400.0;

/// Whether a horizontal drag of [distance] (end minus start, so a leftward
/// swipe is negative) released at [velocity] px/s switches spaces, and to
/// which neighbour. Dragging left brings the next space in from the right,
/// the direction the space order runs.
ContainerCycleDirection? spaceSwipeDirection({
  required double distance,
  required double velocity,
}) {
  final committed =
      distance.abs() >= spaceSwipeCommitDistance ||
      (distance.abs() >= kTouchSlop &&
          velocity.abs() >= spaceSwipeCommitVelocity &&
          velocity.sign == distance.sign);
  if (!committed) {
    return null;
  }
  return distance < 0
      ? ContainerCycleDirection.next
      : ContainerCycleDirection.previous;
}

/// Steps [selectedSpaceProvider] one space in [direction], with a light
/// haptic when it moved.
bool cycleSelectedSpace(WidgetRef ref, ContainerCycleDirection direction) {
  final moved = ref.read(selectedSpaceProvider.notifier).cycle(direction);
  if (moved) {
    unawaited(HapticFeedback.lightImpact());
  }
  return moved;
}

/// A horizontal swipe over [child] switches to the previous or next space.
///
/// A plain single-finger horizontal drag: only put this over surfaces whose
/// own gestures do not run horizontally — the wide rail's vertical tab list,
/// the compact bar's space indicator. A horizontally scrolling chip strip
/// wins the arena for horizontal drags and this would never fire there; the
/// strip switches spaces on overscroll instead.
class SpaceSwipeDetector extends HookConsumerWidget {
  final Widget child;
  final HitTestBehavior behavior;

  const SpaceSwipeDetector({
    super.key,
    required this.child,
    this.behavior = HitTestBehavior.translucent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = useRef<Offset?>(null);
    final last = useRef<Offset?>(null);

    return GestureDetector(
      behavior: behavior,
      onHorizontalDragStart: (details) {
        start.value = details.globalPosition;
        last.value = details.globalPosition;
      },
      onHorizontalDragUpdate: (details) {
        last.value = details.globalPosition;
      },
      onHorizontalDragCancel: () {
        start.value = null;
        last.value = null;
      },
      onHorizontalDragEnd: (details) {
        final from = start.value;
        final to = last.value;
        start.value = null;
        last.value = null;
        if (from == null || to == null) {
          return;
        }
        final direction = spaceSwipeDirection(
          distance: to.dx - from.dx,
          velocity:
              details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx,
        );
        if (direction != null) {
          cycleSelectedSpace(ref, direction);
        }
      },
      child: child,
    );
  }
}

/// Slides [child] sideways when [spaceUuid] changes: the new space's content
/// comes in from the side it sits on in the space order (the next space from
/// the right, the previous from the left, wrapping at the ends) while the old
/// one leaves the other way. [child] should be keyed by nothing in
/// particular — the switcher keys it on [spaceUuid] itself.
class SpaceSlide extends HookConsumerWidget {
  final String? spaceUuid;
  final Widget child;

  const SpaceSlide({super.key, required this.spaceUuid, required this.child});

  static const duration = Duration(milliseconds: 220);

  /// Fraction of the width the content travels; a nudge, not a page turn.
  static const travel = 0.25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(
      watchSpacesProvider.select(
        (value) => [
          for (final space in value.value ?? const <SpaceData>[]) space.uuid,
        ],
      ),
    );
    final previous = usePrevious(spaceUuid);
    // Latched: the switcher keeps animating after the build that changed the
    // space, and the direction has to hold for that whole run.
    final forward = useRef(true);
    final current = spaceUuid;
    if (previous != null && current != null && previous != current) {
      final from = ids.indexOf(previous);
      final to = ids.indexOf(current);
      if (from >= 0 && to >= 0) {
        final last = ids.length - 1;
        // Wrapping from the last space to the first still reads as going
        // forward, and the reverse as going back.
        final wrapsForward = from == last && to == 0;
        final wrapsBack = from == 0 && to == last;
        forward.value = wrapsForward || (!wrapsBack && to > from);
      }
    }
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final currentKey = ValueKey(spaceUuid);

    return AnimatedSwitcher(
      duration: disableAnimations ? Duration.zero : duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final incoming = child.key == currentKey;
        // The outgoing child's animation runs backwards, so its tween ends
        // where it should leave: the side opposite the incoming one.
        final side = incoming ? travel : -travel;
        final begin = Offset(forward.value ? side : -side, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.passthrough,
        children: [...previousChildren, ?currentChild],
      ),
      child: KeyedSubtree(key: currentKey, child: child),
    );
  }
}
