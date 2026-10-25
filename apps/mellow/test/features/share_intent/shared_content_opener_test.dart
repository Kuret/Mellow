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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/providers/router.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/features/browser/domain/providers/intent.dart';
import 'package:mellow/features/share_intent/domain/entities/shared_content.dart';
import 'package:mellow/features/share_intent/domain/services/shared_content_opener.dart';

/// [EngineBoundIntentStream] fed by hand instead of by native intents.
class _ControlledIntentStream extends EngineBoundIntentStream {
  _ControlledIntentStream(this.controller);

  final StreamController<SharedContent> controller;

  @override
  Stream<SharedContent> build() => controller.stream;
}

Widget _page(String label) => Scaffold(body: Text(label));

/// The routes the opener navigates between, with the app's names and paths but
/// none of its screens.
GoRouter _buildRouter() => GoRouter(
  initialLocation: const BrowserRoute().location,
  routes: [
    GoRoute(
      name: BrowserRoute.name,
      path: '/browser',
      builder: (context, state) => _page('browser'),
      routes: [
        GoRoute(
          name: 'SearchRoute',
          path: 'search/:tabType/:searchText',
          builder: (context, state) => _page('search'),
        ),
        GoRoute(
          name: 'OpenSharedContentRoute',
          path: 'open_content',
          builder: (context, state) =>
              _page('open ${state.uri.queryParameters['shared-url']}'),
        ),
      ],
    ),
    GoRoute(
      name: 'SettingsRoute',
      path: '/settings',
      builder: (context, state) => _page('settings'),
    ),
  ],
);

class _Harness {
  _Harness(this.container, this.router, this.intents);

  final ProviderContainer container;
  final GoRouter router;
  final StreamController<SharedContent> intents;

  List<RouteMatchBase> get stack =>
      router.routerDelegate.currentConfiguration.matches;

  List<String?> get routeNames =>
      stack.map((match) => (match.route as GoRoute).name).toList();

  RouteMatchBase get top => stack.last;

  /// The location of the top match. A pushed route carries its own, separate
  /// from the configuration's `go` location.
  RouteMatchList get topMatches => switch (top) {
    ImperativeRouteMatch(:final matches) => matches,
    _ => router.routerDelegate.currentConfiguration,
  };

  String? get topSharedUrl => topMatches.uri.queryParameters['shared-url'];

  Future<void> share(WidgetTester tester, SharedContent content) async {
    intents.add(content);
    await tester.pumpAndSettle();
  }
}

Future<_Harness> _pump(WidgetTester tester) async {
  final intents = StreamController<SharedContent>.broadcast();
  final router = _buildRouter();
  final container = ProviderContainer(
    overrides: [
      engineBoundIntentStreamProvider.overrideWith(
        () => _ControlledIntentStream(intents),
      ),
      routerProvider.overrideWith((ref) => router),
      selectedTabTypeProvider.overrideWith((ref) => TabType.regular),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await intents.close();
    router.dispose();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  // What main.dart does: keep the service alive for the life of the app.
  container.listen(sharedContentOpenerProvider, (previous, next) {});
  await tester.pumpAndSettle();

  return _Harness(container, router, intents);
}

SharedUrl _url(String url) => SharedUrl(Uri.parse(url));

void main() {
  testWidgets('a shared URL opens the sheet over the browser', (tester) async {
    final harness = await _pump(tester);

    await harness.share(tester, _url('https://example.org/a'));

    expect(harness.routeNames, ['BrowserRoute', 'OpenSharedContentRoute']);
    expect(harness.topSharedUrl, 'https://example.org/a');
  });

  testWidgets('a second shared URL replaces the sheet that is still open', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await harness.share(tester, _url('https://example.org/a'));

    await harness.share(tester, _url('https://example.org/b'));

    expect(harness.routeNames, ['BrowserRoute', 'OpenSharedContentRoute']);
    expect(harness.topSharedUrl, 'https://example.org/b');
    expect(
      harness.stack.map((match) => match.matchedLocation),
      isNot(contains(contains('example.org%2Fa'))),
    );
  });

  testWidgets('a shared URL while on another screen returns to the browser', (
    tester,
  ) async {
    final harness = await _pump(tester);
    unawaited(harness.router.push('/settings'));
    await tester.pumpAndSettle();
    expect(harness.routeNames, ['BrowserRoute', 'SettingsRoute']);

    await harness.share(tester, _url('https://example.org/c'));

    expect(harness.routeNames, ['BrowserRoute', 'OpenSharedContentRoute']);
    expect(harness.topSharedUrl, 'https://example.org/c');
  });

  testWidgets('sharing the same URL twice opens the sheet again', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await harness.share(tester, _url('https://example.org/same'));
    final firstPageKey = harness.top.pageKey;

    await harness.share(tester, _url('https://example.org/same'));

    expect(harness.routeNames, ['BrowserRoute', 'OpenSharedContentRoute']);
    expect(harness.topSharedUrl, 'https://example.org/same');
    expect(harness.top.pageKey, isNot(firstPageKey));
  });

  testWidgets('a rebuild of the intent stream does not reopen the last link', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await harness.share(tester, _url('https://example.org/a'));
    harness.router.pop();
    await tester.pumpAndSettle();
    expect(harness.routeNames, ['BrowserRoute']);

    // Riverpod re-emits the previous value (flagged loading) while rebuilding.
    harness.container.invalidate(engineBoundIntentStreamProvider);
    await tester.pumpAndSettle();

    expect(harness.routeNames, ['BrowserRoute']);
  });

  testWidgets('shared text opens the search screen', (tester) async {
    final harness = await _pump(tester);

    await harness.share(tester, SharedText('hello world'));

    expect(harness.routeNames, ['BrowserRoute', 'SearchRoute']);
    expect(harness.topMatches.pathParameters['searchText'], 'hello world');
    expect(
      harness.topMatches.uri.queryParameters,
      containsPair('launched-from-intent', 'true'),
    );
  });
}
