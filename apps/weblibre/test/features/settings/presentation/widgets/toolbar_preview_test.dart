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
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_layout.dart';
import 'package:weblibre/features/settings/presentation/widgets/toolbar_preview.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';

Future<void> _pumpPreview(
  WidgetTester tester,
  GeneralSettings settings, {
  required bool compact,
  ZenSettings? zenSettings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TabBarPreviewCard(
            settings: settings,
            zenSettings: zenSettings ?? ZenSettings.withDefaults(),
            compact: compact,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The wide preview's page-content box: the one drawn inside the scaled
/// canvas, next to the rail.
Finder _widePageContent() => find.descendant(
  of: find.byType(FittedBox),
  matching: find.text('Page Content'),
);

void main() {
  for (final compact in [true, false]) {
    group(compact ? 'compact' : 'stacked', () {
      testWidgets('shows both layouts, labelled', (tester) async {
        await _pumpPreview(
          tester,
          GeneralSettings.withDefaults(),
          compact: compact,
        );

        expect(find.text(TabBarPreviewCard.wideScreensLabel), findsOneWidget);
        expect(find.text(TabBarPreviewCard.narrowScreensLabel), findsOneWidget);
        expect(find.byType(WideRailLayout), findsOneWidget);
        expect(find.text('Page Content'), findsNWidgets(2));
      });

      testWidgets('docks the rail on the configured side', (tester) async {
        await _pumpPreview(
          tester,
          GeneralSettings.withDefaults(),
          zenSettings: ZenSettings.withDefaults(railSide: RailSide.left),
          compact: compact,
        );
        expect(
          tester.getCenter(find.byType(WideRailLayout)).dx,
          lessThan(tester.getCenter(_widePageContent()).dx),
        );

        await _pumpPreview(
          tester,
          GeneralSettings.withDefaults(),
          zenSettings: ZenSettings.withDefaults(railSide: RailSide.right),
          compact: compact,
        );
        expect(
          tester.getCenter(find.byType(WideRailLayout)).dx,
          greaterThan(tester.getCenter(_widePageContent()).dx),
        );
      });

      testWidgets('puts the compact bar at the configured edge', (
        tester,
      ) async {
        Finder narrowPage() => find.text('Page Content').hitTestable().first;

        await _pumpPreview(
          tester,
          GeneralSettings.withDefaults(tabBarPosition: TabBarPosition.bottom),
          compact: compact,
        );
        final barBelow = tester.getTopLeft(find.text('News').first).dy;
        expect(barBelow, greaterThan(tester.getTopLeft(narrowPage()).dy));

        await _pumpPreview(
          tester,
          GeneralSettings.withDefaults(tabBarPosition: TabBarPosition.top),
          compact: compact,
        );
        // The address row moves above the page; the chips stay below it.
        expect(
          tester.getTopLeft(find.text('weblibre.eu').first).dy,
          lessThan(tester.getTopLeft(narrowPage()).dy),
        );
      });
    });
  }
}
