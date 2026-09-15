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
import 'package:go_router/go_router.dart';
import 'package:weblibre/features/geckoview/features/search/presentation/widgets/search_panel.dart';

const _fieldKey = ValueKey('panel-field');

/// Stands in for [SearchScreen] in panel mode: a pinned field at the top of a
/// shrink-wrapping scroll view with a suggestion row per match, which is the
/// shape the screen builds through [SearchPanelBody].
class _PanelContent extends StatefulWidget {
  const _PanelContent({required this.maxHeight, this.initialRows = 0});

  final double maxHeight;
  final int initialRows;

  @override
  State<_PanelContent> createState() => _PanelContentState();
}

class _PanelContentState extends State<_PanelContent> {
  late final TextEditingController _controller = TextEditingController();
  late int _rows = widget.initialRows;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchPanelBody(
      maxHeight: widget.maxHeight,
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: SizedBox(
              height: 56,
              child: TextField(
                key: _fieldKey,
                controller: _controller,
                // One suggestion per character keeps the growth predictable.
                onChanged: (value) => setState(() => _rows = value.length * 3),
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: _rows,
          itemBuilder: (context, index) =>
              SizedBox(height: 48, child: Text('suggestion $index')),
        ),
      ],
    );
  }
}

Widget _panelApp({int initialRows = 0}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/panel'),
              child: const Text('page behind'),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'panel',
            pageBuilder: (context, state) => searchPanelPage<void>(
              key: state.pageKey,
              child: SearchPanel(
                builder: (context, metrics) => _PanelContent(
                  maxHeight: metrics.maxHeight,
                  initialRows: initialRows,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void _sizeView(WidgetTester tester, Size size, {double keyboard = 0}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.view.padding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);
}

void main() {
  group('SearchPanelMetrics', () {
    test('anchors the card towards the top rather than centring it', () {
      const mediaQuery = MediaQueryData(size: Size(400, 900));

      final metrics = SearchPanelMetrics.resolve(mediaQuery);

      expect(metrics.top, closeTo(900 * kSearchPanelTopFraction, 0.01));
      expect(metrics.top, lessThan(900 / 2));
    });

    test('caps the card width so a wide viewport gets a panel, not a band', () {
      const mediaQuery = MediaQueryData(size: Size(2448, 1200));

      final metrics = SearchPanelMetrics.resolve(mediaQuery);

      expect(metrics.maxWidth, kSearchPanelMaxWidth);
    });

    test('leaves phone gutters when the viewport is narrower than the cap', () {
      const mediaQuery = MediaQueryData(size: Size(400, 900));

      final metrics = SearchPanelMetrics.resolve(mediaQuery);

      expect(metrics.maxWidth, 400 - 2 * kSearchPanelGutter);
    });

    test('caps the suggestion list at the shorter of 420 and 55%', () {
      final tall = SearchPanelMetrics.resolve(
        const MediaQueryData(size: Size(400, 1200)),
      );
      final short = SearchPanelMetrics.resolve(
        const MediaQueryData(size: Size(400, 600)),
      );

      expect(tall.listMaxHeight, kSearchPanelListMaxHeight);
      expect(short.listMaxHeight, 600 * kSearchPanelListHeightFraction);
    });

    test('shrinks the height budget by the keyboard inset', () {
      const size = Size(400, 800);
      final withoutKeyboard = SearchPanelMetrics.resolve(
        const MediaQueryData(size: size),
      );
      final withKeyboard = SearchPanelMetrics.resolve(
        const MediaQueryData(
          size: size,
          viewInsets: EdgeInsets.only(bottom: 400),
        ),
      );

      expect(withKeyboard.maxHeight, lessThan(withoutKeyboard.maxHeight));
      expect(
        withKeyboard.top + withKeyboard.maxHeight,
        lessThanOrEqualTo(800 - 400),
      );
    });
  });

  group('SearchPanelBody', () {
    Future<void> pumpBody(
      WidgetTester tester, {
      required double maxHeight,
      required int rows,
    }) async {
      _sizeView(tester, const Size(400, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: _PanelContent(maxHeight: maxHeight, initialRows: rows),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shrink-wraps to its content when there is little of it', (
      tester,
    ) async {
      await pumpBody(tester, maxHeight: 500, rows: 0);

      final height = tester.getRect(find.byType(SearchPanelBody)).height;

      expect(height, lessThan(200));
    });

    testWidgets('stops growing at the cap and scrolls from there', (
      tester,
    ) async {
      await pumpBody(tester, maxHeight: 300, rows: 40);

      expect(tester.getRect(find.byType(SearchPanelBody)).height, 300);
      expect(find.byType(Scrollable), findsWidgets);
    });
  });

  group('search panel route', () {
    testWidgets('floats over the page instead of replacing it', (tester) async {
      _sizeView(tester, const Size(400, 800));
      await tester.pumpWidget(_panelApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('page behind'));
      await tester.pumpAndSettle();

      expect(find.byKey(kSearchPanelCardKey), findsOneWidget);

      final route = ModalRoute.of(
        tester.element(find.byKey(kSearchPanelCardKey)),
      );
      expect(route, isNotNull);
      expect(route!.opaque, isFalse);

      // The route below keeps painting, which is what the backdrop blurs.
      expect(find.text('page behind'), findsOneWidget);
    });

    testWidgets('dismisses when the scrim is tapped', (tester) async {
      _sizeView(tester, const Size(400, 800));
      await tester.pumpWidget(_panelApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('page behind'));
      await tester.pumpAndSettle();
      expect(find.byKey(kSearchPanelCardKey), findsOneWidget);

      // Above the card, which is anchored well down the viewport.
      await tester.tapAt(const Offset(20, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(kSearchPanelCardKey), findsNothing);
      expect(find.text('page behind'), findsOneWidget);
    });

    testWidgets('grows as suggestions arrive but stays within the cap', (
      tester,
    ) async {
      _sizeView(tester, const Size(400, 600));
      await tester.pumpWidget(_panelApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('page behind'));
      await tester.pumpAndSettle();

      final emptyHeight = tester
          .getRect(find.byKey(kSearchPanelCardKey))
          .height;
      expect(find.text('suggestion 0'), findsNothing);

      await tester.enterText(find.byKey(_fieldKey), 'we');
      await tester.pumpAndSettle();

      final typedHeight = tester
          .getRect(find.byKey(kSearchPanelCardKey))
          .height;
      expect(find.text('suggestion 0'), findsOneWidget);
      expect(typedHeight, greaterThan(emptyHeight));

      await tester.enterText(find.byKey(_fieldKey), 'weblibre browser search');
      await tester.pumpAndSettle();

      final metrics = SearchPanelMetrics.resolve(
        const MediaQueryData(size: Size(400, 600)),
      );
      expect(
        tester.getRect(find.byKey(kSearchPanelCardKey)).height,
        lessThanOrEqualTo(metrics.maxHeight),
      );
    });

    testWidgets('keeps the field above the keyboard', (tester) async {
      _sizeView(tester, const Size(400, 800), keyboard: 400);
      await tester.pumpWidget(_panelApp(initialRows: 40));
      await tester.pumpAndSettle();

      await tester.tap(find.text('page behind'));
      await tester.pumpAndSettle();

      final card = tester.getRect(find.byKey(kSearchPanelCardKey));
      final field = tester.getRect(find.byKey(_fieldKey));

      expect(field.bottom, lessThanOrEqualTo(800 - 400));
      expect(card.bottom, lessThanOrEqualTo(800 - 400));
    });
  });
}
