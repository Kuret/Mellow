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
