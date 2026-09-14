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
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/compact_space_selector.dart';

final _spaces = [
  SpaceData(uuid: 'space-a', name: 'Work', orderIndex: 0),
  SpaceData(uuid: 'space-b', name: 'Personal', orderIndex: 1),
];

void main() {
  testWidgets('shows the selected space name and reports a picked uuid', (
    tester,
  ) async {
    String? chosen;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchSpacesProvider.overrideWith((ref) => Stream.value(_spaces)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CompactSpaceSelector(
              selectedSpaceUuid: 'space-a',
              onSelectionChanged: (uuid) => chosen = uuid,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Personal'), findsNothing);

    await tester.tap(find.byType(FilterChip));
    await tester.pumpAndSettle();

    expect(find.text('Personal'), findsOneWidget);
    await tester.tap(find.text('Personal'));
    await tester.pumpAndSettle();

    expect(chosen, 'space-b');
  });

  testWidgets('falls back to a neutral label when nothing is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchSpacesProvider.overrideWith((ref) => Stream.value(_spaces)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CompactSpaceSelector()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Space'), findsOneWidget);
  });
}
