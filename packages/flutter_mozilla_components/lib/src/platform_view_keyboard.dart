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
import 'package:flutter/widgets.dart';

/// Hands the hardware keyboard to an embedded native view while it has focus.
///
/// Flutter sees every key before a native view does: the platform view is a
/// child of the Flutter view, so a key is offered to the framework first and
/// only re-dispatched to the native side if nothing in Flutter claims it.
/// Letters come through because Flutter binds nothing to them. Arrows, Tab and
/// the page keys do not — the app's default shortcuts turn them into focus
/// traversal and scrolling, and Space and Enter into activating whichever
/// chrome widget holds focus — so a web page never saw them.
///
/// Wrap the `PlatformViewLink` in this. While the native view holds focus,
/// every key bubbles through here and is answered with
/// [KeyEventResult.skipRemainingHandlers]: Flutter's shortcuts above never see
/// it, and it goes to the native view, which is where the user is typing. It
/// only applies inside this subtree, so the address bar and the rest of the
/// chrome keep their keyboard behaviour when they have focus.
///
/// This only works if Flutter learns when the native view takes focus — pass
/// `onFocus: () => params.onFocusChanged(true)` when creating the view's
/// controller. Without it Flutter's focus stays on whatever chrome widget had
/// it last, and keys never reach this widget at all.
class PlatformViewKeyboard extends StatelessWidget {
  const PlatformViewKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      // Never focused itself and never a tab stop: it exists only to sit in
      // the focus path above the platform view's own node.
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, _) => KeyEventResult.skipRemainingHandlers,
      child: child,
    );
  }
}
