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
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/features/browser/features/menu/domain/entities/menu_layout.dart';
import 'package:mellow/features/geckoview/features/browser/features/menu/presentation/widgets/sections/profile_section.dart';
import 'package:mellow/features/user/domain/providers/default_browser.dart';

/// Opens the menu sheet the way the browser does, so the quit row runs inside a
/// modal route that is torn down the moment it is tapped.
///
/// Only [MenuItemType.quitBrowser] is rendered on purpose: a section that also
/// holds Profile or Sync calls `ref.watch` during build, which initializes the
/// lazy provider container early and hides the bug this test covers.
Future<void> _pumpMenu(
  WidgetTester tester, {
  required ExitAppCallback onExit,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => ProfileSection(
                  items: const [MenuItemType.quitBrowser],
                  onExit: onExit,
                ),
              ),
              child: const Text('open menu'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open menu'));
  await tester.pumpAndSettle();

  expect(find.byType(ProfileSection), findsOneWidget);
}

/// Stands in for the platform call behind the default-browser row.
class _FakeIsDefaultBrowser extends IsDefaultBrowser {
  _FakeIsDefaultBrowser({required this.isDefault, this.isDefaultOnRefresh});

  final bool isDefault;

  /// What every read after the first answers, when that differs — which is how
  /// a test tells whether the row asked for a fresh answer at all.
  final bool? isDefaultOnRefresh;

  bool _read = false;

  @override
  Future<bool> build() async {
    final answer = _read ? (isDefaultOnRefresh ?? isDefault) : isDefault;
    _read = true;
    return answer;
  }
}

/// Renders just the default-browser row, with the role answered by a fake.
Future<void> _pumpDefaultBrowserRow(
  WidgetTester tester, {
  required bool isDefault,
  bool? isDefaultOnRefresh,
}) async {
  final fake = _FakeIsDefaultBrowser(
    isDefault: isDefault,
    isDefaultOnRefresh: isDefaultOnRefresh,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [isDefaultBrowserProvider.overrideWith(() => fake)],
      child: const MaterialApp(
        home: Scaffold(
          body: ProfileSection(items: [MenuItemType.setDefaultBrowser]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('confirmed quit survives the sheet disposing the section', (
    tester,
  ) async {
    final containers = <ProviderContainer>[];

    await _pumpMenu(
      tester,
      onExit: (container) async => containers.add(container),
    );

    await tester.tap(find.text(MenuItemType.quitBrowser.label));
    await tester.pumpAndSettle();

    // The sheet is gone — and with it the section — while the confirmation is
    // still up. Anything the quit callback needs has to have been captured
    // before the pop.
    expect(find.byType(ProfileSection), findsNothing);
    expect(find.text('Quit Browser'), findsOneWidget);
    expect(containers, isEmpty);

    await tester.tap(find.widgetWithText(TextButton, 'Quit'));
    await tester.pumpAndSettle();

    expect(containers, hasLength(1));
    expect(containers.single, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling the confirmation does not quit', (tester) async {
    final containers = <ProviderContainer>[];

    await _pumpMenu(
      tester,
      onExit: (container) async => containers.add(container),
    );

    await tester.tap(find.text(MenuItemType.quitBrowser.label));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(containers, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long press quits without a confirmation', (tester) async {
    final containers = <ProviderContainer>[];

    await _pumpMenu(
      tester,
      onExit: (container) async => containers.add(container),
    );

    await tester.longPress(find.text(MenuItemType.quitBrowser.label));
    await tester.pumpAndSettle();

    expect(find.text('Quit Browser'), findsNothing);
    expect(containers, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers the default-browser row while the role is not held', (
    tester,
  ) async {
    await _pumpDefaultBrowserRow(tester, isDefault: false);

    expect(find.text(MenuItemType.setDefaultBrowser.label), findsOneWidget);
  });

  testWidgets('re-reads the role when the menu opens', (tester) async {
    // The role can be handed to another browser in Android's own settings,
    // where nothing tells this app about it, so a stale "not default" would go
    // on offering a row with nothing left to do.
    await _pumpDefaultBrowserRow(
      tester,
      isDefault: false,
      isDefaultOnRefresh: true,
    );

    expect(find.text(MenuItemType.setDefaultBrowser.label), findsNothing);
  });

  testWidgets('drops the default-browser row once the role is held', (
    tester,
  ) async {
    await _pumpDefaultBrowserRow(tester, isDefault: true);

    expect(find.text(MenuItemType.setDefaultBrowser.label), findsNothing);
  });
}
