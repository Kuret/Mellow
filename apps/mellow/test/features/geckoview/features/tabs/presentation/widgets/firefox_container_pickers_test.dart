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
 */
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/color_picker_dialog.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/container_icon_picker_sheet.dart';
import 'package:mellow/features/geckoview/features/tabs/utils/firefox_container_vocab.dart';
import 'package:mellow/presentation/widgets/sheet_drag_handle.dart';

void main() {
  group('FirefoxContainerColorPicker', () {
    testWidgets('offers the nine Firefox colours and returns a keyword', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await showDialog<String?>(
                  context: context,
                  builder: (_) => const FirefoxContainerColorPicker(
                    initialColorKey: 'blue',
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(FirefoxContainerColorSwatch), findsNWidgets(9));
      for (final color in FirefoxContainerColor.values) {
        expect(find.byTooltip(color.keyword), findsOneWidget);
      }

      await tester.tap(find.byTooltip('toolbar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      expect(picked, 'toolbar');
    });

    testWidgets('cancelling returns nothing', (tester) async {
      String? picked = 'unset';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await showDialog<String?>(
                  context: context,
                  builder: (_) =>
                      const FirefoxContainerColorPicker(initialColorKey: 'red'),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(picked, isNull);
    });
  });

  group('FirefoxContainerIconPicker', () {
    testWidgets('offers the thirteen Firefox icons and returns a keyword', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FirefoxContainerIconPicker(
              accentColor: Colors.blue,
              selectedIconKey: 'circle',
              onSelected: (key) => selected = key,
            ),
          ),
        ),
      );

      expect(find.byType(SheetDragHandle), findsOneWidget);
      for (final icon in FirefoxContainerIcon.values) {
        expect(find.byTooltip(icon.keyword), findsOneWidget);
      }
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Tooltip),
        ),
        findsNWidgets(13),
      );

      await tester.tap(find.byTooltip('briefcase'));
      expect(selected, 'briefcase');
      expect(tester.takeException(), isNull);
    });
  });
}
