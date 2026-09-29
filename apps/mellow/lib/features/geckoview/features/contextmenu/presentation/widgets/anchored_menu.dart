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

import 'package:flutter/material.dart';

/// A compact, content-sized menu placed at the pointer, the way a desktop
/// browser's context menu behaves, rather than the centred Material dialog
/// phones get.
///
/// Shared by [ContextMenuDialog] (the hit-result menu, over a link, image or
/// media source) and the page context menu (over empty page area): both
/// anchor at a point and clamp back onto screen the same way, so that layout
/// lives once.
class AnchoredMenu extends StatelessWidget {
  const AnchoredMenu({
    super.key,
    required this.anchor,
    required this.menuKey,
    required this.items,
    this.title,
  });

  final Offset anchor;

  /// Identifies the menu's own surface, not this wrapper — tests locate the
  /// menu by this key to read its laid-out position, which [CustomSingleChildLayout]
  /// only gives to its child, not to itself.
  final Key menuKey;

  final Widget? title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    // [anchor] is measured against the raw view, but the route's SafeArea has
    // already pushed this widget's own origin clear of system chrome — the
    // DeX caption bar in particular — so the same amount is subtracted here
    // to keep the anchor in step with this widget's local coordinate space.
    final insets = MediaQuery.paddingOf(context);
    final localAnchor = anchor - Offset(insets.left, insets.top);

    return CustomSingleChildLayout(
      delegate: _AnchoredMenuLayout(localAnchor),
      child: Material(
        key: menuKey,
        type: MaterialType.card,
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title case final title?) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.titleMedium!,
                      child: title,
                    ),
                  ),
                  const Divider(height: 1),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: items,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Places the menu with its top-left at [anchor], then shifts it back onto
/// screen if that would run it off the right or bottom edge — the same way a
/// desktop context menu never lets itself be opened partly off-screen.
class _AnchoredMenuLayout extends SingleChildLayoutDelegate {
  const _AnchoredMenuLayout(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxLeft = math.max(0.0, size.width - childSize.width);
    final maxTop = math.max(0.0, size.height - childSize.height);
    return Offset(anchor.dx.clamp(0.0, maxLeft), anchor.dy.clamp(0.0, maxTop));
  }

  @override
  bool shouldRelayout(covariant _AnchoredMenuLayout oldDelegate) =>
      anchor != oldDelegate.anchor;
}
