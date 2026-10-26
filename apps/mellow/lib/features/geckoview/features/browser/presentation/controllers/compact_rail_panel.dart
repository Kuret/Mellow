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
import 'package:mellow/features/geckoview/features/browser/presentation/controllers/edge_touch_tracker.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compact_rail_panel.g.dart';

/// Whether the narrow-viewport compact bar's slide-out tab rail is open.
///
/// The single source of truth both the gesture (predictive drag and the
/// plain-back fallback) and the ordinary UI (the scrim, picking a tab) drive
/// through [open] and [close], and the widget that owns the slide animation
/// listens to so a programmatic open (the fallback) animates exactly like a
/// gesture-driven one.
@riverpod
class CompactRailPanelOpen extends _$CompactRailPanelOpen {
  @override
  bool build() => false;

  void open() => state = true;

  void close() => state = false;
}

/// Which edge the slide-out panel is open on right now.
///
/// Explicit state rather than something re-derived from
/// [ZenSettings.compactRailSide] wherever the current edge is needed: on
/// [CompactRailSide.either] the setting alone does not say which edge —
/// that is decided per gesture by `resolveCompactRailBackGesture` — so the
/// gesture handler and the plain-back fallback both write the resolved side
/// here in the same beat they call [CompactRailPanelOpen.open], and the panel
/// widget reads it back to know which edge to render on.
///
/// Stays at its last value once set, including after the panel closes: the
/// panel widget keeps its content mounted (translated off-screen) between
/// opens, and re-reads this to lay itself out correctly before the very next
/// gesture updates it.
@riverpod
class CompactRailPanelSide extends _$CompactRailPanelSide {
  @override
  RailSide? build() => null;

  // ignore: use_setters_to_change_properties
  void set(RailSide side) => state = side;
}

/// Whether this device has ever delivered a predictive back gesture to the
/// app — i.e. whether the edge a back gesture came from is knowable.
///
/// The plain-back fallback exists for platforms that never send predictive
/// events (Android 12 and below, 3-button navigation), where there is no edge
/// to match and any back opens the panel. Without this flag that fallback also
/// fires on a *predictive* gesture the observer deliberately let through —
/// a back swipe from the edge opposite the rail — because the framework then
/// runs its ordinary pop, which lands in the same `BackButtonListener`. The
/// result is the rail opening from both edges and the promise that "a back
/// swipe from the other edge still goes back" being quietly broken.
///
/// Set once, on the first `handleStartBackGesture` this app ever sees. That
/// event always precedes the committed back it belongs to, so the very first
/// gesture on a predictive-back device is already covered.
@Riverpod(keepAlive: true)
class PredictiveBackSeen extends _$PredictiveBackSeen {
  @override
  bool build() => false;

  void record() {
    if (!state) state = true;
  }
}

/// The app-wide [EdgeTouchTracker]: fed by the slide-out panel's global
/// pointer route, read by the browser screen's `BackButtonListener` when a
/// back arrives without a predictive start event to name its edge.
@Riverpod(keepAlive: true)
EdgeTouchTracker edgeTouchTracker(Ref ref) => EdgeTouchTracker();

/// Marks the back about to reach the browser screen's `BackButtonListener` as
/// one the slide-out panel already looked at and passed on — a predictive
/// gesture it claimed (so that it sees the whole gesture) but that was not
/// meant to open the panel. The listener performs it as an ordinary back.
///
/// Without the mark the listener could not tell that back from one that came
/// with no predictive events at all, which it has to treat as a possible
/// swipe toward the panel.
@Riverpod(keepAlive: true)
class CompactRailPassedOnBack extends _$CompactRailPassedOnBack {
  @override
  bool build() => false;

  void mark() => state = true;

  /// Whether the current back was passed on; clears the mark either way.
  bool take() {
    final passedOn = state;
    if (passedOn) state = false;
    return passedOn;
  }
}
