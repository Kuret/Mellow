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
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/bottom_app_bar.dart'
    show RailSpaceTabs;
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_layout.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_icon_rail.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

/// Wraps the browser's content in a slide-out tab rail for the
/// narrow-viewport compact bar (PLAN/DESIGN: the compact bar has no docked
/// rail, so this is how it offers the same shelves).
///
/// Off by default ([ZenSettings.compactRailSide] is `null`): [child] is
/// returned untouched, nothing is even built, and the [WidgetsBindingObserver]
/// this owns exists but can never claim a back gesture (see
/// [shouldClaimCompactRailBackGesture]).
///
/// When a [RailSide] is configured and the viewport is narrow, a predictive
/// back gesture from that edge (Android 13+) drags the panel in as it
/// drags — [handleUpdateBackGestureProgress] seeks the animation directly —
/// and a plain committed back with no predictive events (older Android, or
/// 3-button navigation) opens it outright, through
/// [compactRailPanelOpenProvider], which the browser screen's own
/// `BackButtonListener` fallback also writes to. Either way, while the panel
/// is open a back gesture is *not* claimed here: it falls through to the
/// browser's ordinary back, which is the point of leaving the panel open —
/// the scrim and picking a tab are how it closes.
class CompactRailSlideOut extends ConsumerStatefulWidget {
  const CompactRailSlideOut({
    super.key,
    required this.child,
    required this.isNarrowViewport,
    required this.viewportWidth,
    required this.railWidth,
    this.topInset = 0,
    this.bottomInset = 0,
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

  /// Vertical space the compact bar itself occupies at the top or bottom of
  /// the screen, kept clear so the panel never covers it.
  final double topInset;
  final double bottomInset;

  /// The panel never takes more than this share of the viewport width, so it
  /// cannot cover the entire screen on a small phone.
  static const maxViewportFraction = 0.85;

  @override
  ConsumerState<CompactRailSlideOut> createState() =>
      _CompactRailSlideOutState();
}

class _CompactRailSlideOutState extends ConsumerState<CompactRailSlideOut>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

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

  RailSide? get _side =>
      ref.read(zenSettingsWithDefaultsProvider).compactRailSide;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    return shouldClaimCompactRailBackGesture(
      side: _side,
      isNarrowViewport: widget.isNarrowViewport,
      isOpen: ref.read(compactRailPanelOpenProvider),
      swipeEdge: backEvent.swipeEdge,
      isCurrentRoute: ModalRoute.of(context)?.isCurrent == true,
    );
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    _controller.value = backEvent.progress;
  }

  @override
  void handleCommitBackGesture() {
    ref.read(compactRailPanelOpenProvider.notifier).open();
    unawaited(_controller.forward());
  }

  @override
  void handleCancelBackGesture() {
    unawaited(_controller.reverse());
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
            return Positioned(
              top: widget.topInset,
              bottom: widget.bottomInset,
              left: 0,
              right: 0,
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
            final closedOffset = side == RailSide.left
                ? -panelWidth
                : panelWidth;
            final dx = closedOffset * (1 - _controller.value);
            return Positioned(
              top: widget.topInset,
              bottom: widget.bottomInset,
              left: side == RailSide.left ? 0 : null,
              right: side == RailSide.right ? 0 : null,
              width: panelWidth,
              child: IgnorePointer(
                ignoring: _controller.value == 0,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: const WideRailLayout(
                    urlRow: SizedBox.shrink(),
                    toolbar: SizedBox.shrink(),
                    showUrlRow: false,
                    showToolbar: false,
                    tabs: RailSpaceTabs(),
                    spaces: SpaceIconRail(),
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
