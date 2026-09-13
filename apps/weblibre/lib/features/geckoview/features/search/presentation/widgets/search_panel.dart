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
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widest the card is ever allowed to get. On a desktop-class viewport the
/// browser behind it can be 2000dp across; a command panel that wide is a
/// banner, not a panel.
const double kSearchPanelMaxWidth = 720.0;

/// Gutter between the card and the edges of the viewport.
const double kSearchPanelGutter = 16.0;

/// How far down the visible viewport the card is anchored. Centring it
/// vertically reads as a dialog; sitting it high reads as an address bar that
/// lifted off the page.
const double kSearchPanelTopFraction = 0.12;
const double kSearchPanelMinTop = 12.0;
const double kSearchPanelMaxTop = 120.0;

const double kSearchPanelRadius = 20.0;

/// A light touch of blur, with most of the separation coming from the dim
/// below. A heavier blur smears the page into something unreadable behind a
/// panel that is only meant to sit in front of it for a moment.
const double kSearchPanelBlurSigma = 4.0;
const double kSearchPanelScrimOpacity = 0.52;

/// Cap on the suggestion list. Past this the list scrolls inside the card
/// instead of the card growing into a full-screen page by another name.
const double kSearchPanelListMaxHeight = 420.0;
const double kSearchPanelListHeightFraction = 0.55;

/// Room reserved above the list for the tab-type switcher row and the field
/// itself, which live in the same scroll view.
const double kSearchPanelFieldAllowance = 132.0;

/// Floor for the card so a tiny viewport still shows the field.
const double kSearchPanelMinHeight = 120.0;

const Duration kSearchPanelTransitionDuration = Duration(milliseconds: 180);

/// Distance the card rises over the course of the entrance.
const double kSearchPanelRise = 10.0;
const double kSearchPanelInitialScale = 0.98;

/// Identifies the dismiss target for tests and for hit testing.
const ValueKey<String> kSearchPanelScrimKey = ValueKey('search-panel-scrim');
const ValueKey<String> kSearchPanelCardKey = ValueKey('search-panel-card');

/// Where the floating search card sits and how much room it may take.
///
/// Derived entirely from the viewport, so the keyboard coming up shrinks the
/// budget rather than pushing the field off the bottom.
@immutable
class SearchPanelMetrics {
  /// Offset of the card's top edge from the top of the viewport.
  final double top;

  final double maxWidth;

  /// Height budget while the card is showing the field and suggestions.
  final double maxHeight;

  /// Height budget once the card is showing dispatched web-search results,
  /// which are a page's worth of content rather than a suggestion list.
  final double expandedMaxHeight;

  /// The suggestion cap this budget was built from, kept for callers that
  /// want to reason about the list alone.
  final double listMaxHeight;

  const SearchPanelMetrics({
    required this.top,
    required this.maxWidth,
    required this.maxHeight,
    required this.expandedMaxHeight,
    required this.listMaxHeight,
  });

  factory SearchPanelMetrics.resolve(MediaQueryData mediaQuery) {
    final size = mediaQuery.size;
    final bottomInset = mediaQuery.viewInsets.bottom;
    final safeTop = mediaQuery.padding.top;
    final safeBottom = mediaQuery.padding.bottom;

    final visibleHeight = math.max(
      0.0,
      size.height - bottomInset - safeTop - safeBottom,
    );
    final top =
        safeTop +
        (visibleHeight * kSearchPanelTopFraction).clamp(
          kSearchPanelMinTop,
          kSearchPanelMaxTop,
        );

    // With the keyboard up its inset already covers the gesture area, so the
    // bottom safe-area padding would be counted twice.
    final bottomGutter =
        kSearchPanelGutter + (bottomInset > 0 ? 0.0 : safeBottom);
    final available = math.max(
      kSearchPanelMinHeight,
      size.height - bottomInset - top - bottomGutter,
    );

    final listMaxHeight = math.min(
      kSearchPanelListMaxHeight,
      size.height * kSearchPanelListHeightFraction,
    );

    return SearchPanelMetrics(
      top: top,
      maxWidth: math.min(
        kSearchPanelMaxWidth,
        math.max(240.0, size.width - 2 * kSearchPanelGutter),
      ),
      maxHeight: math.min(
        listMaxHeight + kSearchPanelFieldAllowance,
        available,
      ),
      expandedMaxHeight: available,
      listMaxHeight: listMaxHeight,
    );
  }
}

/// The scroll view inside the card: it measures its slivers instead of
/// filling a box, so an empty query is a field and a short list rather than a
/// tall empty card, and it stops growing at [maxHeight] and scrolls from
/// there.
class SearchPanelBody extends StatelessWidget {
  const SearchPanelBody({
    super.key,
    required this.maxHeight,
    required this.slivers,
    this.controller,
  });

  final double maxHeight;
  final List<Widget> slivers;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: CustomScrollView(
        controller: controller,
        shrinkWrap: true,
        slivers: slivers,
      ),
    );
  }
}

/// The Arc/Zen-style floating command panel: the page stays on screen, blurred
/// and dimmed, with a rounded card of search content floating over it.
///
/// The panel owns the backdrop and the card; [builder] supplies the content
/// and is handed the height budget it has to live within.
class SearchPanel extends StatelessWidget {
  const SearchPanel({super.key, required this.builder, this.onDismiss});

  final Widget Function(BuildContext context, SearchPanelMetrics metrics)
  builder;

  /// Defaults to popping the enclosing route.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final metrics = SearchPanelMetrics.resolve(mediaQuery);
    final colorScheme = Theme.of(context).colorScheme;

    void dismiss() {
      final onDismiss = this.onDismiss;
      if (onDismiss != null) {
        onDismiss();
        return;
      }
      if (context.canPop()) {
        context.pop();
      }
    }

    final card = Material(
      key: kSearchPanelCardKey,
      color: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      elevation: 12,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(kSearchPanelRadius),
      child: builder(context, metrics),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            label: 'Dismiss search',
            button: true,
            child: GestureDetector(
              key: kSearchPanelScrimKey,
              behavior: HitTestBehavior.opaque,
              onTap: dismiss,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: kSearchPanelBlurSigma,
                  sigmaY: kSearchPanelBlurSigma,
                ),
                child: ColoredBox(
                  color: Colors.black.withValues(
                    alpha: kSearchPanelScrimOpacity,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: metrics.top,
          left: kSearchPanelGutter,
          right: kSearchPanelGutter,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: metrics.maxWidth),
              child: _SearchPanelEntrance(child: card),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rise and scale the card in step with the route transition. The backdrop
/// only fades (see [searchPanelPage]) — scaling a full-bleed scrim would show
/// its edges.
class _SearchPanelEntrance extends StatelessWidget {
  const _SearchPanelEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final animation =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        return Transform.translate(
          offset: Offset(0, (1 - t) * kSearchPanelRise),
          child: Transform.scale(
            scale: ui.lerpDouble(kSearchPanelInitialScale, 1.0, t),
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: child,
    );
  }
}

/// A transparent page for the floating panel: the route below keeps painting,
/// so the browser is still there to blur.
Page<T> searchPanelPage<T>({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<T>(
    key: key,
    opaque: false,
    barrierDismissible: true,
    // The scrim is painted inside the panel so the blur and the dim fade as
    // one; a route barrier on top of that would only double the dim.
    barrierColor: Colors.transparent,
    transitionDuration: kSearchPanelTransitionDuration,
    reverseTransitionDuration: kSearchPanelTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }

      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        child: child,
      );
    },
    child: child,
  );
}
