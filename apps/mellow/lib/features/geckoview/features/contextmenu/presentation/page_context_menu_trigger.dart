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

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/features/contextmenu/domain/providers/context_menu_shown_at.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/page_context_menu_dialog.dart';

/// Bridges [PointerInputBridge.onSecondaryButtonDown] to [PageContextMenuDialog].
///
/// A right click over empty page area reaches [PointerInputBridge] the same
/// way one over a link does — Gecko has nothing to hit-test either way, and
/// the native side reports the button press regardless. The two cases are
/// indistinguishable at the moment the button goes down, so this waits out a
/// grace period for the hit-result context menu to have opened before
/// assuming it hasn't: without it, a right click on a link would raise both
/// menus at once.
///
/// Renders nothing; placed once, anywhere under the [Navigator] that should
/// host the menu.
class PageContextMenuTrigger extends HookConsumerWidget {
  const PageContextMenuTrigger({super.key});

  /// How long a right click waits for [ContextMenuDialog] to have opened for
  /// the same click before this raises its own menu instead.
  @visibleForTesting
  static const gracePeriod = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Timer? graceTimer;

      PointerInputBridge.onSecondaryButtonDown = (position) {
        final pressedAt = DateTime.now();
        graceTimer?.cancel();
        graceTimer = Timer(gracePeriod, () {
          final hitResultMenuShownAt = ref.read(contextMenuShownAtProvider);
          if (hitResultMenuShownAt != null &&
              hitResultMenuShownAt.isAfter(pressedAt)) {
            return;
          }
          if (!context.mounted) {
            return;
          }
          unawaited(
            showDialog<void>(
              context: context,
              builder: (_) => PageContextMenuDialog(anchor: position),
            ),
          );
        });
      };

      return () {
        graceTimer?.cancel();
        PointerInputBridge.onSecondaryButtonDown = null;
      };
    }, const []);

    return const SizedBox.shrink();
  }
}
