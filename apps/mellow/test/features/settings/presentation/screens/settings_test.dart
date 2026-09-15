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
import 'package:mellow/features/settings/presentation/screens/appearance_layout_settings.dart';
import 'package:mellow/features/settings/presentation/screens/settings.dart';
import 'package:mellow/features/settings/presentation/screens/tabs_spaces_settings.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/zen_settings.dart';

void main() {
  testWidgets('narrow viewport keeps the single-pane list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          generalSettingsWithDefaultsProvider.overrideWith(
            (ref) => GeneralSettings.withDefaults(),
          ),
          zenSettingsWithDefaultsProvider.overrideWith(
            (ref) => ZenSettings.withDefaults(),
          ),
        ],
        child: const MediaQuery(
          data: MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(home: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settingsTwoPaneDivider')), findsNothing);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.text('Appearance & Layout'), findsOneWidget);
    expect(find.byType(AppearanceLayoutSettingsScreen), findsNothing);
  });

  testWidgets('wide viewport shows a two-pane layout with no back arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          generalSettingsWithDefaultsProvider.overrideWith(
            (ref) => GeneralSettings.withDefaults(),
          ),
          zenSettingsWithDefaultsProvider.overrideWith(
            (ref) => ZenSettings.withDefaults(),
          ),
        ],
        child: const MediaQuery(
          data: MediaQueryData(size: Size(1200, 800)),
          child: MaterialApp(home: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settingsTwoPaneDivider')), findsOneWidget);
    // The default selection (first category) opens in the right pane, while
    // the left-pane list still shows every category as a tile.
    expect(
      find.widgetWithText(ListTile, 'Appearance & Layout'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ListTile, 'Tabs & Spaces'), findsOneWidget);
    expect(find.byType(AppearanceLayoutSettingsScreen), findsOneWidget);
    expect(find.byType(TabsSpacesSettingsScreen), findsNothing);
    // The right pane's nested Navigator has only one route, so its
    // SliverAppBar.large must not grow a back button that would pop
    // Settings. (Note: the pane also contains an unrelated Icons.arrow_back
    // glyph from the toolbar preview's own mock navigation buttons, so the
    // absence of a "Back" tooltip is the reliable signal here, not the
    // absence of that icon.)
    expect(find.byTooltip('Back'), findsNothing);

    // Selecting another category swaps the right pane in place.
    await tester.tap(find.widgetWithText(ListTile, 'Tabs & Spaces'));
    await tester.pumpAndSettle();

    expect(find.byType(TabsSpacesSettingsScreen), findsOneWidget);
    expect(find.byType(AppearanceLayoutSettingsScreen), findsNothing);
    // The left pane still lists every category; the tapped one now reads as
    // selected instead of navigating away.
    expect(
      find.widgetWithText(ListTile, 'Appearance & Layout'),
      findsOneWidget,
    );
    expect(find.byTooltip('Back'), findsNothing);
  });
}
