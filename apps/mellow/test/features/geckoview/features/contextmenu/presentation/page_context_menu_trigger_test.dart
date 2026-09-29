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
import 'package:flutter/material.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/features/contextmenu/domain/providers/context_menu_shown_at.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/page_context_menu_dialog.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/page_context_menu_trigger.dart';

/// The real provider listens for the native engine to report ready, which
/// this suite never simulates: nothing under test needs a tab selected, so
/// this stands in for it rather than leaving the menu waiting out that
/// listener's real 10-second timeout on every test.
class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

void main() {
  tearDown(() {
    // The trigger's useEffect leaves this pointing at its own closure over a
    // now-disposed widget tree; nothing calls it again until the next test's
    // own trigger remounts, but nothing should rely on that.
    PointerInputBridge.onSecondaryButtonDown = null;
  });

  /// Mounts the trigger alone, the way it is placed once under the
  /// [Navigator] that should host the menu — nothing else about the tree
  /// matters to what these tests check.
  Future<void> pumpTrigger(
    WidgetTester tester, {
    required ProviderContainer container,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: PageContextMenuTrigger()),
        ),
      ),
    );
  }

  testWidgets(
    'raises its own menu once the grace period passes with no hit-result '
    'menu having opened — the case Gecko had nothing to hit-test',
    (tester) async {
      final container = ProviderContainer(
        overrides: [selectedTabProvider.overrideWith(_NoSelectedTab.new)],
      );
      addTearDown(container.dispose);

      await pumpTrigger(tester, container: container);

      PointerInputBridge.onSecondaryButtonDown!(const Offset(50, 60));
      expect(find.byType(PageContextMenuDialog), findsNothing);

      await tester.pump(PageContextMenuTrigger.gracePeriod);
      // The dialog's own 150ms open transition.
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(PageContextMenuDialog), findsOneWidget);
    },
  );

  testWidgets(
    'stays away when the hit-result menu opened for the same click — the '
    'whole reason for the grace period, since without it every right click '
    'on a link would raise both menus at once',
    (tester) async {
      final container = ProviderContainer(
        overrides: [selectedTabProvider.overrideWith(_NoSelectedTab.new)],
      );
      addTearDown(container.dispose);

      await pumpTrigger(tester, container: container);

      PointerInputBridge.onSecondaryButtonDown!(const Offset(50, 60));

      // Still inside the grace period: this is what ContextMenuDialog does
      // on build when Gecko did hand back a hit result for the same click.
      await tester.pump(const Duration(milliseconds: 50));
      container.read(contextMenuShownAtProvider.notifier).markShown();

      await tester.pump(PageContextMenuTrigger.gracePeriod);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(PageContextMenuDialog), findsNothing);
    },
  );
}
