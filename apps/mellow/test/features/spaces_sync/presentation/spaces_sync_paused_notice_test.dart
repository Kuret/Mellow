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
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/spaces_sync/domain/entities/spaces_sync_status.dart';
import 'package:mellow/features/spaces_sync/domain/spaces_sync_service.dart';
import 'package:mellow/features/spaces_sync/presentation/widgets/spaces_sync_paused_notice.dart';

import '../fake_spaces_sync_service.dart';

Widget _page(String label) => Scaffold(body: Text(label));

/// The browser and the sync settings screen by the app's route names, with
/// none of their screens; `SyncSettingsRoute().push` resolves by name.
GoRouter _buildRouter(Widget home) => GoRouter(
  initialLocation: '/browser',
  routes: [
    GoRoute(
      name: 'BrowserRoute',
      path: '/browser',
      builder: (context, state) => Scaffold(body: home),
    ),
    GoRoute(
      name: 'SettingsRoute',
      path: '/settings',
      builder: (context, state) => _page('settings'),
      routes: [
        GoRoute(
          name: 'SyncSettingsRoute',
          path: 'sync',
          builder: (context, state) => _page('sync settings'),
        ),
      ],
    ),
  ],
);

Future<GoRouter> _pump(
  WidgetTester tester,
  Widget home, {
  SpacesSyncBlockedBatch? blockedBatch,
}) async {
  final router = _buildRouter(home);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        spacesSyncServiceProvider.overrideWith(
          () => FakeSpacesSyncService(
            SpacesSyncStatus(blockedBatch: blockedBatch),
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

List<String?> _routeNames(GoRouter router) => router
    .routerDelegate
    .currentConfiguration
    .matches
    .map((match) => (match.route as GoRoute).name)
    .toList();

void main() {
  group('SpacesSyncPausedNotice', () {
    testWidgets('renders nothing while no batch is blocked', (tester) async {
      await _pump(tester, const SpacesSyncPausedNotice());

      expect(find.text('Sync upload paused'), findsNothing);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });

    testWidgets('names the pause and offers to review it', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        const SpacesSyncPausedNotice(),
        blockedBatch: FakeSpacesSyncService.pausedBatch(),
      );

      expect(find.text('Sync upload paused'), findsOneWidget);
      expect(find.text('Tap to review'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(
        find.bySemanticsLabel('Sync upload paused, tap to review'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('tapping it opens the sync settings', (tester) async {
      final router = await _pump(
        tester,
        const SpacesSyncPausedNotice(),
        blockedBatch: FakeSpacesSyncService.pausedBatch(),
      );

      await tester.tap(find.text('Sync upload paused'));
      await tester.pumpAndSettle();

      expect(_routeNames(router), ['BrowserRoute', 'SyncSettingsRoute']);
      expect(find.text('sync settings'), findsOneWidget);
    });
  });

  group('SpacesSyncPausedBadge', () {
    testWidgets('shows just the child while no batch is blocked', (
      tester,
    ) async {
      await _pump(
        tester,
        const SpacesSyncPausedBadge(child: Text('indicator')),
      );

      expect(find.text('indicator'), findsOneWidget);
      expect(find.byKey(SpacesSyncPausedBadge.dotKey), findsNothing);
    });

    testWidgets('overlays a dot while a batch is blocked', (tester) async {
      await _pump(
        tester,
        const SpacesSyncPausedBadge(child: Text('indicator')),
        blockedBatch: FakeSpacesSyncService.pausedBatch(),
      );

      expect(find.text('indicator'), findsOneWidget);
      final dot = find.byKey(SpacesSyncPausedBadge.dotKey);
      expect(dot, findsOneWidget);
      expect(tester.getSize(dot), const Size.square(8));
    });
  });
}
