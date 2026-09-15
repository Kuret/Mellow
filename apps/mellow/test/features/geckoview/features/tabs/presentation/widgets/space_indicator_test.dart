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
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/space_indicator.dart';

class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

class _SelectedSpaceOverride extends SelectedSpace {
  final String? uuid;

  _SelectedSpaceOverride(this.uuid);

  @override
  String? build() => uuid;
}

void main() {
  group('SpaceIndicatorView', () {
    testWidgets('long-pressing fires onLongPress with a context', (
      tester,
    ) async {
      BuildContext? received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceIndicatorView(
              icon: null,
              name: 'Work',
              index: 0,
              count: 1,
              onLongPress: (context) => received = context,
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(SpaceIndicatorView));
      await tester.pump();

      expect(received, isNotNull);
    });

    testWidgets('tapping fires onTap with a context', (tester) async {
      BuildContext? received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceIndicatorView(
              icon: null,
              name: 'Work',
              index: 0,
              count: 1,
              onTap: (context) => received = context,
              onLongPress: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SpaceIndicatorView));
      await tester.pump();

      expect(received, isNotNull);
    });
  });

  group('SpaceIndicator', () {
    final spaces = [
      SpaceData(uuid: 'space-1', name: 'Work', icon: '💼', orderIndex: 0),
      SpaceData(uuid: 'space-2', name: 'Home', icon: '🏠', orderIndex: 1),
    ];

    Future<void> pumpIndicator(WidgetTester tester, {String? selected}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchSpacesProvider.overrideWith((ref) => Stream.value(spaces)),
            selectedSpaceProvider.overrideWith(
              () => _SelectedSpaceOverride(selected),
            ),
            selectedTabProvider.overrideWith(_NoSelectedTab.new),
          ],
          child: const MaterialApp(home: Scaffold(body: SpaceIndicator())),
        ),
      );
      await tester.pump();
    }

    testWidgets('tapping opens the quick menu', (tester) async {
      await pumpIndicator(tester, selected: 'space-1');

      await tester.tap(find.byType(SpaceIndicator));
      await tester.pumpAndSettle();

      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('New Space'), findsOneWidget);
      expect(find.text('New Tab'), findsOneWidget);
    });

    testWidgets(
      'the menu lists one row per space, in provider order, between the two '
      'dividers, with the current one marked',
      (tester) async {
        await pumpIndicator(tester, selected: 'space-2');

        await tester.tap(find.byType(SpaceIndicator));
        await tester.pumpAndSettle();

        expect(find.byType(PopupMenuDivider), findsNWidgets(2));

        const order = ['Settings', 'Work', 'Home', 'New Space'];
        final positions = [
          for (final label in order) tester.getTopLeft(find.text(label)).dy,
        ];
        for (var i = 1; i < positions.length; i++) {
          expect(
            positions[i],
            greaterThan(positions[i - 1]),
            reason: 'expected $order in order, got $positions',
          );
        }

        // Both dividers must sit strictly between "Settings" and the first
        // space, and between the last space and "New Space".
        final firstDividerY = tester
            .getTopLeft(find.byType(PopupMenuDivider).at(0))
            .dy;
        final secondDividerY = tester
            .getTopLeft(find.byType(PopupMenuDivider).at(1))
            .dy;
        final settingsY = tester.getTopLeft(find.text('Settings')).dy;
        final workY = tester.getTopLeft(find.text('Work')).dy;
        final homeY = tester.getTopLeft(find.text('Home')).dy;
        final newSpaceY = tester.getTopLeft(find.text('New Space')).dy;
        expect(firstDividerY, greaterThan(settingsY));
        expect(firstDividerY, lessThan(workY));
        expect(secondDividerY, greaterThan(homeY));
        expect(secondDividerY, lessThan(newSpaceY));

        // "Home" (space-2) is the selected one: it must carry a check, "Work"
        // must not.
        final homeRow = tester.widget<Row>(
          find.ancestor(of: find.text('Home'), matching: find.byType(Row)),
        );
        expect(
          homeRow.children.any(
            (child) => child is Icon && child.icon == Icons.check,
          ),
          isTrue,
        );
        final workRow = tester.widget<Row>(
          find.ancestor(of: find.text('Work'), matching: find.byType(Row)),
        );
        expect(
          workRow.children.any(
            (child) => child is Icon && child.icon == Icons.check,
          ),
          isFalse,
        );
      },
    );

    testWidgets('choosing a space switches the selected space', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchSpacesProvider.overrideWith((ref) => Stream.value(spaces)),
            selectedSpaceProvider.overrideWith(
              () => _SelectedSpaceOverride('space-1'),
            ),
            selectedTabProvider.overrideWith(_NoSelectedTab.new),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(home: Scaffold(body: SpaceIndicator()));
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SpaceIndicator));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(container.read(selectedSpaceProvider), 'space-2');
    });
  });
}
