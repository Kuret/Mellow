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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/compact_rail_back_gesture.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/compact_rail_panel.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/wide_rail_move_back_gesture.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/bottom_app_bar.dart'
    show BrowserTabBar;
import 'package:weblibre/features/settings/presentation/controllers/save_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

/// Wraps the browser's content in two independent back-gesture behaviours,
/// both off by default and both gated the same way (see [_side] and
/// [_swipeToMoveRail]):
///
///  * On a narrow viewport with [ZenSettings.compactRailSide] configured,
///    the compact bar draws no horizontal chrome at all — the caller passes
///    a [child] that already omits it — and this widget slides a panel over
///    the page instead, carrying everything the wide rail would: the address
///    row, the toolbar buttons, the tab shelves and the space row. A
///    predictive back gesture (Android 13+) from the configured edge (or,
///    on [CompactRailSide.either], from either edge) drags the panel in as
///    it progresses; a plain committed back with no predictive events
///    (older Android, or 3-button navigation) opens it outright via
///    [compactRailPanelOpenProvider], which the browser screen's own
///    `BackButtonListener` fallback also writes to. Either way, while the
///    panel is open a back gesture is *not* claimed here: it falls through
///    to the browser's ordinary back, which is the point of leaving the
///    panel open — the scrim and picking a tab are how it closes.
///  * On a wide viewport with [ZenSettings.swipeToMoveRail] on, a predictive
///    back gesture from the edge opposite the docked rail flips
///    [ZenSettings.railSide] there instead of running the ordinary back; a
///    gesture from the rail's own edge is left unclaimed. There is no plain-
///    back fallback for this one: with no edge to go by there is nothing to
///    decide (see `resolveWideRailMoveBackGesture`).
///
/// Both are off by default, and default-off is asserted in tests: with
/// [ZenSettings.compactRailSide] `null` and [ZenSettings.swipeToMoveRail]
/// `false`, this widget claims nothing, so no back gesture anywhere behaves
/// differently from before either setting existed.
class CompactRailSlideOut extends ConsumerStatefulWidget {
  const CompactRailSlideOut({
    super.key,
    required this.child,
    required this.isNarrowViewport,
    required this.viewportWidth,
    required this.railWidth,
    required this.showToolbarButtons,
    this.suppressMainToolbar = false,
  });

  /// The rest of the browser screen, painted below the panel and the scrim.
  final Widget child;

  /// Whether the compact-bar (narrow) layout, rather than the wide rail, is
  /// on screen right now. The same predicate the browser screen uses to pick
  /// between them ([isWideViewport], negated).
  final bool isNarrowViewport;

  final double viewportWidth;

  /// The wide rail's configured content width; the panel reuses it (capped
  /// below), so it reads exactly like the docked rail would.
  final double railWidth;

  /// See [BrowserTabBar.showToolbarButtons]: threaded in from the caller,
  /// which resolves it once for every construction site (the horizontal
  /// bars, the wide rail, and this panel) rather than re-deriving it here.
  final bool showToolbarButtons;

  /// See [BrowserTabBar.suppressMainToolbar].
  final bool suppressMainToolbar;

  /// The panel never takes more than this share of the viewport width, so it
  /// cannot cover the entire screen on a small phone.
  static const maxViewportFraction = 0.85;

  @override
  ConsumerState<CompactRailSlideOut> createState() =>
      _CompactRailSlideOutState();
}

/// What a claimed `handleStartBackGesture` is for, decided once at the start
/// of the gesture and acted on in [_CompactRailSlideOutState.handleCommitBackGesture].
/// Explicit rather than re-resolved from the setting at commit time: a
/// predictive gesture's [PredictiveBackEvent.swipeEdge] is only available at
/// the start of the gesture, and re-deriving "which behaviour, and which
/// side" from the settings alone cannot tell the two apart.
sealed class _PendingBackGesture {}

class _PendingPanelOpen extends _PendingBackGesture {
  _PendingPanelOpen(this.side);

  final RailSide side;
}

class _PendingRailMove extends _PendingBackGesture {
  _PendingRailMove(this.to);

  final RailSide to;
}

class _CompactRailSlideOutState extends ConsumerState<CompactRailSlideOut>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  _PendingBackGesture? _pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  CompactRailSide? get _side =>
      ref.read(zenSettingsWithDefaultsProvider).compactRailSide;

  bool get _swipeToMoveRail =>
      ref.read(zenSettingsWithDefaultsProvider).swipeToMoveRail;

  RailSide get _currentRailSide =>
      ref.read(zenSettingsWithDefaultsProvider).railSide;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    // Recorded whether or not this gesture is claimed: what matters is that
    // the platform sends these at all, which is what tells the plain-back
    // fallback to stand down.
    ref.read(predictiveBackSeenProvider.notifier).record();

    final isCurrentRoute = ModalRoute.of(context)?.isCurrent == true;

    final panelSide = resolveCompactRailBackGesture(
      side: _side,
      isNarrowViewport: widget.isNarrowViewport,
      isOpen: ref.read(compactRailPanelOpenProvider),
      swipeEdge: backEvent.swipeEdge,
      isCurrentRoute: isCurrentRoute,
    );
    if (panelSide != null) {
      // Applied here, at the start of the gesture, rather than when it
      // commits: the drag animates from `handleUpdateBackGestureProgress`
      // onwards, and the panel has to already be sitting on the edge the
      // finger came from for that to look like anything. Committing the side
      // at the end instead meant the first swipe from a new edge played the
      // whole animation on the old one and only snapped across at the end —
      // so on `either` the panel looked stuck on whichever edge it had last
      // opened from.
      //
      // Safe to keep even if the gesture is cancelled: the panel is closed
      // then, and a closed panel's side only decides which edge it waits
      // off-screen on.
      ref.read(compactRailPanelSideProvider.notifier).set(panelSide);
      _pending = _PendingPanelOpen(panelSide);
      return true;
    }

    final moveTo = resolveWideRailMoveBackGesture(
      enabled: _swipeToMoveRail,
      currentSide: _currentRailSide,
      isWideViewport: !widget.isNarrowViewport,
      swipeEdge: backEvent.swipeEdge,
      isCurrentRoute: isCurrentRoute,
    );
    if (moveTo != null) {
      _pending = _PendingRailMove(moveTo);
      return true;
    }

    _pending = null;
    return false;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (_pending is _PendingPanelOpen) {
      _controller.value = backEvent.progress;
    }
  }

  @override
  void handleCommitBackGesture() {
    switch (_pending) {
      // The side is not set here: `handleStartBackGesture` already did it, so
      // the panel was on the right edge for the whole drag. (The plain-back
      // path, which has no start event, sets it in the browser screen's own
      // `BackButtonListener` before opening.)
      case _PendingPanelOpen():
        ref.read(compactRailPanelOpenProvider.notifier).open();
        unawaited(_controller.forward());
      case _PendingRailMove(:final to):
        unawaited(
          ref
              .read(saveZenSettingsControllerProvider.notifier)
              .save((currentSettings) => currentSettings.copyWith.railSide(to)),
        );
      case null:
        break;
    }
    _pending = null;
  }

  @override
  void handleCancelBackGesture() {
    if (_pending is _PendingPanelOpen) {
      unawaited(_controller.reverse());
    }
    _pending = null;
  }

  void _close() => ref.read(compactRailPanelOpenProvider.notifier).close();

  @override
  Widget build(BuildContext context) {
    final side = ref.watch(
      zenSettingsWithDefaultsProvider.select((value) => value.compactRailSide),
    );

    // The panel's open/closed state is the single source of truth for both
    // the gesture and the ordinary UI (scrim tap, tab pick); keep the
    // animation in step with it either way it changes.
    ref.listen(compactRailPanelOpenProvider, (previous, isOpen) {
      if (isOpen) {
        unawaited(_controller.forward());
      } else {
        unawaited(_controller.reverse());
      }
    });

    // Picking a tab closes the panel.
    ref.listen(selectedTabProvider, (previous, next) {
      if (next != previous && ref.read(compactRailPanelOpenProvider)) {
        _close();
      }
    });

    if (side == null || !widget.isNarrowViewport) {
      return widget.child;
    }

    // Explicit state, not re-derived from `side`: on CompactRailSide.either
    // the setting alone does not name an edge, only the last resolved
    // gesture (or its fallback) does. Before the very first gesture there is
    // nothing to read yet, so fall back the same way
    // `resolveCompactRailBackGesture` does for a plain back with no edge:
    // the configured edge, or left on `either`.
    final panelSide =
        ref.watch(compactRailPanelSideProvider) ??
        switch (side) {
          CompactRailSide.left => RailSide.left,
          CompactRailSide.right => RailSide.right,
          CompactRailSide.either => RailSide.left,
        };

    final panelWidth = widget.railWidth.clamp(
      0.0,
      widget.viewportWidth * CompactRailSlideOut.maxViewportFraction,
    );

    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.value == 0) return const SizedBox.shrink();
            return Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: ColoredBox(
                  color: Colors.black.withValues(
                    alpha: 0.35 * _controller.value,
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final closedOffset = panelSide == RailSide.left
                ? -panelWidth
                : panelWidth;
            final dx = closedOffset * (1 - _controller.value);
            return Positioned(
              top: 0,
              bottom: 0,
              left: panelSide == RailSide.left ? 0 : null,
              right: panelSide == RailSide.right ? 0 : null,
              width: panelWidth,
              child: IgnorePointer(
                ignoring: _controller.value == 0,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  // The panel carries the same blocks the wide rail does
                  // (address row, toolbar buttons, tab shelves, space row):
                  // BrowserTabBar builds exactly that skeleton whenever
                  // `railSide` is set, so it reads identically here. Insets
                  // come from SafeArea/MediaQuery — the compact bar this
                  // replaces is not drawn, so there is no toolbar height to
                  // measure against instead.
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: SafeArea(
                      left: panelSide == RailSide.left,
                      right: panelSide == RailSide.right,
                      child: BrowserTabBar(
                        showMainToolbar: true,
                        displayedSheet: null,
                        quickTabSwitcherRowCount: 0,
                        // The panel is dismissed by the scrim or picking a
                        // tab, not by swiping the bar itself, so the rail's
                        // own dismiss/tab-view swipe is not wired in here.
                        enableGestures: false,
                        suppressMainToolbar: widget.suppressMainToolbar,
                        showToolbarButtons: widget.showToolbarButtons,
                        railSide: panelSide,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
