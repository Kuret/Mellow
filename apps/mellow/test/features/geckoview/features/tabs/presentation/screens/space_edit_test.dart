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
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/space.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/screens/space_edit.dart';

/// [SpaceRepository] without the database: records every write.
class _FakeSpaceRepository extends SpaceRepository {
  final created = <SpaceData>[];
  final renamed = <(String, String)>[];
  final icons = <(String, String?)>[];
  final containers = <(String, String?)>[];
  final deleted = <String>[];
  int tabCount = 3;

  @override
  void build() {}

  @override
  Future<SpaceData> createSpace({
    String name = '',
    String? containerId,
    String? icon,
  }) async {
    final space = SpaceData(
      uuid: 'new-space',
      name: name,
      icon: icon,
      containerId: containerId,
      orderIndex: created.length,
    );
    created.add(space);
    return space;
  }

  @override
  Future<void> renameSpace(String uuid, String name) async {
    renamed.add((uuid, name));
  }

  @override
  Future<void> setSpaceIcon(String uuid, String? icon) async {
    icons.add((uuid, icon));
  }

  @override
  Future<void> setSpaceContainer(String uuid, String? containerId) async {
    containers.add((uuid, containerId));
  }

  @override
  Future<int> countTabsInSpace(String uuid) async => tabCount;

  @override
  Future<void> deleteSpace(String uuid) async {
    deleted.add(uuid);
  }
}

class _TestSelectedSpace extends SelectedSpace {
  final selections = <String?>[];

  @override
  String? build() => 'space-1';

  @override
  set space(String? uuid) {
    selections.add(uuid);
    state = uuid;
  }
}

Widget _host(
  Widget screen, {
  required _FakeSpaceRepository repository,
  required List<SpaceData> spaces,
  required _TestSelectedSpace selectedSpace,
}) {
  return ProviderScope(
    overrides: [
      // ignore: scoped_providers_should_specify_dependencies
      spaceRepositoryProvider.overrideWith(() => repository),
      watchSpacesProvider.overrideWith((ref) => Stream.value(spaces)),
      watchContainersWithCountProvider.overrideWith(
        (ref) => Stream.value(<ContainerDataWithCount>[
          ContainerDataWithCount(
            id: 'work',
            name: 'Work',
            orderKey: 'a',
            tabCount: 2,
          ),
        ]),
      ),
      // ignore: scoped_providers_should_specify_dependencies
      selectedSpaceProvider.overrideWith(() => selectedSpace),
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

final _spaceOne = SpaceData(uuid: 'space-1', name: 'Personal', orderIndex: 0);
final _spaceTwo = SpaceData(
  uuid: 'space-2',
  name: 'Work',
  icon: '💼',
  containerId: 'work',
  orderIndex: 1,
);

Finder _deleteButton() =>
    find.widgetWithIcon(FilledButton, Icons.delete_outline);

void main() {
  testWidgets('saving a new space creates it and selects it', (tester) async {
    final repository = _FakeSpaceRepository();
    final selected = _TestSelectedSpace();
    await tester.pumpWidget(
      _host(
        const SpaceEditScreen.create(),
        repository: repository,
        spaces: [_spaceOne],
        selectedSpace: selected,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Space Name'),
      ' Research ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Emoji or short text'),
      '🔬',
    );
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final created = repository.created.single;
    expect(created.name, 'Research');
    expect(created.icon, '🔬');
    expect(created.containerId, 'work');
    expect(selected.selections, ['new-space']);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('editing writes only what changed', (tester) async {
    final repository = _FakeSpaceRepository();
    await tester.pumpWidget(
      _host(
        const SpaceEditScreen.edit(uuid: 'space-2'),
        repository: repository,
        spaces: [_spaceOne, _spaceTwo],
        selectedSpace: _TestSelectedSpace(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Space'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Work'), 'Office');
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(repository.renamed, [('space-2', 'Office')]);
    expect(repository.icons, isEmpty);
    expect(repository.containers, [('space-2', null)]);
    expect(repository.created, isEmpty);
  });

  testWidgets('the last space cannot be deleted', (tester) async {
    final repository = _FakeSpaceRepository();
    await tester.pumpWidget(
      _host(
        const SpaceEditScreen.edit(uuid: 'space-1'),
        repository: repository,
        spaces: [_spaceOne],
        selectedSpace: _TestSelectedSpace(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The last space cannot be deleted'), findsOneWidget);
    expect(tester.widget<FilledButton>(_deleteButton()).onPressed, isNull);
  });

  testWidgets('deleting confirms with the tab count', (tester) async {
    final repository = _FakeSpaceRepository()..tabCount = 4;
    await tester.pumpWidget(
      _host(
        const SpaceEditScreen.edit(uuid: 'space-2'),
        repository: repository,
        spaces: [_spaceOne, _spaceTwo],
        selectedSpace: _TestSelectedSpace(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_deleteButton());
    await tester.pumpAndSettle();
    expect(find.text("Delete 'Work'?"), findsOneWidget);
    expect(find.text('4 tabs will be closed.'), findsOneWidget);

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.deleted, ['space-2']);
    expect(find.text('home'), findsOneWidget);
  });
}
