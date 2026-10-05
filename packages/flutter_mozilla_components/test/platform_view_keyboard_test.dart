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
import 'package:flutter/services.dart';
import 'package:flutter_mozilla_components/src/platform_view_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Stands in for the platform view: a focusable node inside the wrapper, the
  // way PlatformViewLink's own Focus node sits inside it in the app.
  late FocusNode page;
  // Stands in for the browser chrome: a button outside the wrapper.
  late FocusNode chrome;
  late int chromeActivations;

  setUp(() {
    page = FocusNode(debugLabel: 'page');
    chrome = FocusNode(debugLabel: 'chrome');
    chromeActivations = 0;
  });

  tearDown(() {
    page.dispose();
    chrome.dispose();
  });

  // MaterialApp, not a bare widget: the bug only exists because the app's
  // default shortcuts bind arrows, Tab, Space and Enter, so the test needs
  // them present to prove they no longer get the key.
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Column(
        children: [
          TextButton(
            focusNode: chrome,
            onPressed: () => chromeActivations++,
            child: const Text('chrome'),
          ),
          PlatformViewKeyboard(
            child: Focus(
              focusNode: page,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ],
      ),
    ),
  );

  for (final key in [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.tab,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.pageDown,
    LogicalKeyboardKey.home,
  ]) {
    testWidgets('leaves ${key.keyLabel} to the native view while it has focus, '
        'instead of moving focus or activating chrome', (tester) async {
      await pump(tester);
      page.requestFocus();
      await tester.pump();

      final handled = await tester.sendKeyEvent(key);
      await tester.pump();

      // Unhandled is the point: the engine re-dispatches an unhandled key
      // to the natively focused view, which is the web page.
      expect(handled, isFalse);
      expect(page.hasPrimaryFocus, isTrue);
      expect(chromeActivations, 0);
    });
  }

  testWidgets(
    'keeps the chrome keyboard-operable when the chrome has focus — the '
    'handover is scoped to the native view, not the whole app',
    (tester) async {
      await pump(tester);
      chrome.requestFocus();
      await tester.pump();

      final handled = await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(handled, isTrue);
      expect(chromeActivations, 1);
    },
  );

  testWidgets('is never a tab stop or a focus target of its own', (
    tester,
  ) async {
    await pump(tester);

    final wrapper = Focus.of(tester.element(find.byType(SizedBox)));
    expect(wrapper, same(page));
    expect(page.parent?.canRequestFocus, isFalse);
    expect(page.parent?.skipTraversal, isTrue);
  });
}
