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
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_local_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/screens/container_edit.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/color_picker_dialog.dart';

/// Hosts the screen under a GoRouter with a page beneath it, so the screen's
/// `context.pop` has somewhere to go.
Widget _host(Widget screen, _FakeContainerRepository repository) {
  return ProviderScope(
    overrides: [
      // ignore: scoped_providers_should_specify_dependencies
      containerRepositoryProvider.overrideWith(() => repository),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('home')),
            routes: [
              GoRoute(path: 'edit', builder: (context, state) => screen),
            ],
          ),
        ],
      ),
    ),
  );
}

ContainerData _draft() =>
    ContainerData(id: 'draft', colorKey: 'blue', orderKey: 'a');

Finder _switchTile(String title) => find.widgetWithText(SwitchListTile, title);

/// Taps the switch tile titled [title], scrolling it into the 600 px test
/// viewport first: the lower tiles of the form sit below it.
Future<void> _tapSwitch(WidgetTester tester, String title) async {
  final tile = _switchTile(title);
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
}

bool _switchValue(WidgetTester tester, String title) =>
    tester.widget<SwitchListTile>(_switchTile(title)).value;

void main() {
  testWidgets('has no cookie isolation switch, only a note', (tester) async {
    final repository = _FakeContainerRepository();
    await tester.pumpWidget(
      _host(ContainerEditScreen.create(initialContainer: _draft()), repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cookie Isolation'), findsOneWidget);
    expect(_switchTile('Cookie Isolation'), findsNothing);
    // Clear-on-exit no longer depends on an isolation switch being on.
    expect(
      tester
          .widget<SwitchListTile>(_switchTile('Clear Data on Exit'))
          .onChanged,
      isNotNull,
    );
  });

  testWidgets('saving a new container writes the row, then its local flags', (
    tester,
  ) async {
    final repository = _FakeContainerRepository();
    await tester.pumpWidget(
      _host(ContainerEditScreen.create(initialContainer: _draft()), repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), ' Work ');
    await _tapSwitch(tester, 'Clear Data on Exit');
    await _tapSwitch(tester, 'Exclude from History');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(repository.added, hasLength(1));
    expect(repository.replaced, isEmpty);
    final saved = repository.added.single;
    expect(saved.id, 'draft');
    expect(saved.name, 'Work');
    expect(saved.colorKey, 'blue');
    expect(saved.iconKey, 'circle');

    expect(repository.locals, hasLength(1));
    final local = repository.locals.single;
    expect(local.containerId, 'draft');
    expect(local.clearDataOnExit, isTrue);
    expect(local.excludeFromHistory, isTrue);
    expect(local.excludeFromIndex, isFalse);
    expect(local.wallpaper, isNull);
    expect(repository.order, ['addContainer', 'setLocal']);

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('the colour picker stores the chosen keyword', (tester) async {
    final repository = _FakeContainerRepository();
    await tester.pumpWidget(
      _host(ContainerEditScreen.create(initialContainer: _draft()), repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Color'));
    await tester.pumpAndSettle();

    expect(find.byType(FirefoxContainerColorSwatch), findsNWidgets(9));
    await tester.tap(find.byTooltip('purple'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(repository.added.single.colorKey, 'purple');
  });

  testWidgets('editing loads the local row and replaces the container', (
    tester,
  ) async {
    final repository = _FakeContainerRepository(
      locals: [
        ContainerLocalData(
          containerId: 'existing',
          excludeFromHistory: true,
          wallpaper: '{"file":"paper.png"}',
        ),
      ],
    );
    await tester.pumpWidget(
      _host(
        ContainerEditScreen.edit(
          initialContainer: ContainerDataWithCount(
            id: 'existing',
            name: 'Banking',
            colorKey: 'green',
            iconKey: 'dollar',
            orderKey: 'a',
            tabCount: 0,
          ),
        ),
        repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(_switchValue(tester, 'Exclude from History'), isTrue);
    expect(_switchValue(tester, 'Clear Data on Exit'), isFalse);
    await _tapSwitch(tester, 'Exclude from Search Index');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(repository.added, isEmpty);
    expect(repository.replaced.single.name, 'Banking');
    expect(repository.replaced.single.iconKey, 'dollar');
    final local = repository.locals.last;
    expect(local.containerId, 'existing');
    expect(local.excludeFromIndex, isTrue);
    expect(local.excludeFromHistory, isTrue);
    // Untouched settings survive the round trip through the form.
    expect(local.wallpaper, '{"file":"paper.png"}');
  });
}

class _FakeContainerRepository extends ContainerRepository {
  _FakeContainerRepository({List<ContainerLocalData> locals = const []})
    : locals = [...locals];

  final added = <ContainerData>[];
  final replaced = <ContainerData>[];
  final List<ContainerLocalData> locals;
  final order = <String>[];

  @override
  Future<void> addContainer(ContainerData container) async {
    order.add('addContainer');
    added.add(container);
  }

  @override
  Future<void> replaceContainer(ContainerData container) async {
    order.add('replaceContainer');
    replaced.add(container);
  }

  @override
  Future<void> setContainerPinned(String id, {required bool isPinned}) async {
    order.add('setContainerPinned');
  }

  @override
  Future<ContainerLocalData> getLocal(String containerId) async {
    order.add('getLocal');
    for (final local in locals) {
      if (local.containerId == containerId) return local;
    }
    return ContainerLocalData.defaults(containerId);
  }

  @override
  Future<void> setLocal(ContainerLocalData local) async {
    order.add('setLocal');
    locals.add(local);
  }
}
