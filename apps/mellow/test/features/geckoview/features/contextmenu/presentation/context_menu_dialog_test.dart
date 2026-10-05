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
import 'package:mellow/features/geckoview/features/contextmenu/presentation/context_menu_dialog.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';

/// The real provider listens for the native engine to report ready, which
/// this suite never simulates: nothing under test needs a tab selected, so
/// this stands in for it rather than leaving the menu waiting out that
/// listener's real 10-second timeout on every test.
class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

/// A stand-in for the native router's channel: nothing here calls back to it,
/// but a bridge needs one to construct.
class _RecordingHost extends PointerInputHostApi {
  @override
  Future<void> reset() async {}

  @override
  Future<void> hoverTargetChanged(PointerHitTest hit) async {}
}

void main() {
  setUp(() {
    PointerInputBridge.hostApi = () => _RecordingHost();
  });

  tearDown(() => PointerInputBridge.hostApi = PointerInputHostApi.new);

  /// Registers a bridge against the test view without needing a real
  /// platform view surface, then opens the menu the same way [DialogPage]
  /// does (a `showDialog` with the safe-area wrapping `DialogRoute` gives it).
  Future<void> pumpMenu(
    WidgetTester tester, {
    Offset? hover,
    Offset? touchDown,
    HitResult? hitResult,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          generalSettingsWithDefaultsProvider.overrideWith(
            (ref) => GeneralSettings.withDefaults(),
          ),
          selectedTabProvider.overrideWith(_NoSelectedTab.new),
        ],
        child: MaterialApp(
          home: PointerInputRegistration(
            viewId: 1,
            child: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => ContextMenuDialog(
                        hitResult:
                            hitResult ??
                            UnknownHitResult(src: 'https://example.com'),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (hover != null) {
      final ratio = tester.view.devicePixelRatio;
      PointerInputBridge.instance!.hitTest(
        hover.dx * ratio,
        hover.dy * ratio,
        true,
      );
    }

    if (touchDown != null) {
      final ratio = tester.view.devicePixelRatio;
      PointerInputBridge.instance!.touchDown(
        touchDown.dx * ratio,
        touchDown.dy * ratio,
      );
    }

    await tester.tap(find.text('open'));
    // Not pumpAndSettle: LaunchExternal asks the (absent, in this suite)
    // native engine to resolve an app link, and that future is never going
    // to settle. The dialog's own 150ms open transition is all that matters
    // for what these tests check.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets(
    'still anchors through AnchoredMenu, at the screen centre, when nothing '
    'has hovered or touched down — never centred through a second, separate '
    'presentation',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpMenu(tester);

      expect(find.byType(SimpleDialog), findsNothing);
      final topLeft = tester.getTopLeft(
        find.byKey(const Key('anchoredContextMenu')),
      );
      expect(topLeft, const Offset(400, 600));
    },
  );

  testWidgets('anchors the menu at the last hover position', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpMenu(tester, hover: const Offset(100, 150));

    expect(find.byType(SimpleDialog), findsNothing);
    final topLeft = tester.getTopLeft(
      find.byKey(const Key('anchoredContextMenu')),
    );
    expect(topLeft, const Offset(100, 150));
  });

  testWidgets('anchors the menu at the touch-down position', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpMenu(tester, touchDown: const Offset(120, 170));

    expect(find.byType(SimpleDialog), findsNothing);
    final topLeft = tester.getTopLeft(
      find.byKey(const Key('anchoredContextMenu')),
    );
    expect(topLeft, const Offset(120, 170));
  });

  testWidgets(
    'anchors at the touch-down position when it is more recent than the '
    'last hover — switching between mouse and finger does the obvious thing',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpMenu(
        tester,
        hover: const Offset(100, 150),
        touchDown: const Offset(120, 170),
      );

      final topLeft = tester.getTopLeft(
        find.byKey(const Key('anchoredContextMenu')),
      );
      expect(topLeft, const Offset(120, 170));
    },
  );

  testWidgets(
    'shifts the menu back onto screen instead of letting it spill past the '
    'right or bottom edge',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Deep in the bottom-right corner: any content-sized menu anchored
      // there would otherwise run off both edges at once.
      await pumpMenu(tester, hover: const Offset(790, 1190));

      final rect = tester.getRect(find.byKey(const Key('anchoredContextMenu')));
      expect(rect.right, lessThanOrEqualTo(800));
      expect(rect.bottom, lessThanOrEqualTo(1200));
    },
  );

  testWidgets(
    'keeps the menu clear of the DeX caption bar at the top of the screen',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      // Stands in for the native caption bar DeX draws over the top of the
      // window, which the Flutter view reports as a safe-area inset.
      tester.view.padding = const FakeViewPadding(top: 40);
      addTearDown(tester.view.reset);

      // A cursor resting right under the caption bar, before this widget's
      // own SafeArea-shifted origin has been subtracted back out.
      await pumpMenu(tester, hover: const Offset(50, 5));

      final top = tester
          .getTopLeft(find.byKey(const Key('anchoredContextMenu')))
          .dy;
      expect(top, greaterThanOrEqualTo(40));
    },
  );
}
