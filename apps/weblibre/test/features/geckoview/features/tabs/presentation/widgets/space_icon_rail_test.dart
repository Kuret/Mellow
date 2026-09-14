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
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_icon_rail.dart';

class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

class _NoSelectedSpace extends SelectedSpace {
  @override
  String? build() => null;
}

void main() {
  group('SpaceIconRailView', () {
    testWidgets('tapping "+" fires the new-tab callback, not a space editor', (
      tester,
    ) async {
      var newTabTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceIconRailView(
              entries: const [],
              onNewTab: () => newTabTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(newTabTapped, isTrue);
    });

    testWidgets('long-pressing "+" fires onAddLongPress with a context', (
      tester,
    ) async {
      BuildContext? received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceIconRailView(
              entries: const [],
              onAddLongPress: (context) => received = context,
            ),
          ),
        ),
      );

      await tester.longPress(find.byIcon(Icons.add));
      await tester.pump();

      expect(received, isNotNull);
    });
  });

  group('SpaceIconRail', () {
    testWidgets(
      'long-pressing "+" opens a menu with all eight entries in order',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchSpacesProvider.overrideWith((ref) => Stream.value(const [])),
              selectedSpaceProvider.overrideWith(_NoSelectedSpace.new),
              selectedTabProvider.overrideWith(_NoSelectedTab.new),
            ],
            child: const MaterialApp(
              home: Scaffold(body: SpaceIconRail()),
            ),
          ),
        );
        await tester.pump();

        await tester.longPress(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        const expectedOrder = [
          'Refresh',
          'Back',
          'Forward',
          'Tabs',
          'Settings',
          'New Space',
          'New Tab',
        ];

        for (final label in expectedOrder) {
          expect(find.text(label), findsOneWidget);
        }
        expect(find.byType(PopupMenuDivider), findsOneWidget);

        // The divider must sit strictly between "Settings" and "New Space",
        // and every label must appear in the order the brief specifies.
        final positions = [
          for (final label in expectedOrder)
            tester.getTopLeft(find.text(label)).dy,
        ];
        for (var i = 1; i < positions.length; i++) {
          expect(
            positions[i],
            greaterThan(positions[i - 1]),
            reason: 'expected $expectedOrder in order, got $positions',
          );
        }

        final dividerY = tester.getTopLeft(find.byType(PopupMenuDivider)).dy;
        final settingsY = tester.getTopLeft(find.text('Settings')).dy;
        final newSpaceY = tester.getTopLeft(find.text('New Space')).dy;
        expect(dividerY, greaterThan(settingsY));
        expect(dividerY, lessThan(newSpaceY));
      },
    );
  });
}
