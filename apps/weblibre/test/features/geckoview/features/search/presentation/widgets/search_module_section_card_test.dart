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
import 'package:sliver_tools/sliver_tools.dart';
import 'package:weblibre/features/geckoview/features/search/domain/providers/search_section_display.dart';
import 'package:weblibre/features/geckoview/features/search/presentation/widgets/search_modules/search_module_section.dart';

void main() {
  Future<void> pumpHarness(WidgetTester tester, {required bool card}) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SearchModuleSection(
                  title: 'History',
                  section: SearchSection.history,
                  totalCount: 0,
                  showPagination: false,
                  card: card,
                  // Without a SearchSectionScope the section behaves like the
                  // search panel, which is the host that pins its headers.
                  host: SearchSectionHost.panel,
                  headerLeading: const Icon(Icons.history),
                  contentSliverBuilder:
                      ({required isCollapsed, required visibleCount}) => [
                        if (!isCollapsed)
                          const SliverToBoxAdapter(child: Text('body')),
                      ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a card never pins its header', (tester) async {
    await pumpHarness(tester, card: true);

    expect(find.byType(DecoratedSliver), findsOneWidget);
    // A pinned header would detach from the decoration painted across the
    // section's own extent and float over whatever follows.
    expect(find.byType(SliverPinnedHeader), findsNothing);
  });

  testWidgets('a plain section still pins on a pinning surface', (
    tester,
  ) async {
    await pumpHarness(tester, card: false);

    expect(find.byType(SliverPinnedHeader), findsOneWidget);
    expect(find.byType(DecoratedSliver), findsNothing);
  });

  testWidgets('a card keeps the title, the mark and the body', (tester) async {
    await pumpHarness(tester, card: true);

    // Sentence case, not the list surfaces' uppercase micro-label.
    expect(find.text('History'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('a card still collapses from its header', (tester) async {
    await pumpHarness(tester, card: true);

    expect(find.text('body'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('body'), findsNothing);
    // The card itself survives so there is something to expand again.
    expect(find.byType(DecoratedSliver), findsOneWidget);
  });
}
