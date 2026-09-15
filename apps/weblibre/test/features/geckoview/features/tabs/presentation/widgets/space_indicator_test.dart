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
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_indicator.dart';

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

    testWidgets('tapping still fires onTap, unaffected by onLongPress', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceIndicatorView(
              icon: null,
              name: 'Work',
              index: 0,
              count: 1,
              onTap: () => tapped = true,
              onLongPress: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SpaceIndicatorView));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
