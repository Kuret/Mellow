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
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart'
    show HistoryMetadataKey, Internal, LoadUrlFlags, Source;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/domain/entities/tab_container_selection.dart';
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/open_shared_content.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:mellow/features/user/domain/repositories/zen_settings.dart';

/// One recorded [TabRepository.addTab] call.
typedef _AddedTab = ({
  Uri? url,
  TabMode tabMode,
  String? spaceUuid,
  TabContainerSelection containerSelection,
});

/// [TabRepository] without the database: records what the sheet asks for.
class _RecordingTabRepository extends TabRepository {
  final added = <_AddedTab>[];

  @override
  void build() {}

  @override
  Future<String> addTab({
    required TabMode tabMode,
    Uri? url,
    required bool selectTab,
    bool startLoading = true,
    LoadUrlFlags flags = LoadUrlFlags.NONE,
    Source source = Internal.newTab,
    HistoryMetadataKey? historyMetadata,
    Map<String, String>? additionalHeaders,
    TabContainerSelection containerSelection =
        const TabContainerSelection.useSelected(),
    String? spaceUuid,
    bool launchedFromIntent = false,
    TabBackPromptBehavior? promptOnBackBehavior,
  }) async {
    added.add((
      url: url,
      tabMode: tabMode,
      spaceUuid: spaceUuid,
      containerSelection: containerSelection,
    ));
    return 'tab-${added.length}';
  }
}

/// [ContainerRepository] without the database: no site assignments.
class _NoContainerRepository extends ContainerRepository {
  @override
  void build() {}

  @override
  Future<String?> siteAssignedContainerId(Uri uri) async => null;

  @override
  Future<ContainerData?> getContainerData(String id) async => null;

  @override
  Future<ContainerData?> getContainerByContextualIdentity(
    String contextId,
  ) async => null;
}

class _TestSelectedSpace extends SelectedSpace {
  @override
  String? build() => 'space-2';
}

final _spaces = [
  SpaceData(uuid: 'space-1', name: 'Home', icon: '🏠', orderIndex: 0),
  SpaceData(uuid: 'space-2', name: 'Dev', icon: '💻', orderIndex: 1),
  SpaceData(uuid: 'space-3', name: 'Gaming', icon: '🎮', orderIndex: 2),
];

Future<void> _pumpSheet(
  WidgetTester tester,
  _RecordingTabRepository repository, {
  Uri? sharedUrl,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // ignore: scoped_providers_should_specify_dependencies
        watchSpacesProvider.overrideWith((ref) => Stream.value(_spaces)),
        // ignore: scoped_providers_should_specify_dependencies
        tabRepositoryProvider.overrideWith(() => repository),
        // ignore: scoped_providers_should_specify_dependencies
        containerRepositoryProvider.overrideWith(_NoContainerRepository.new),
        // ignore: scoped_providers_should_specify_dependencies
        selectedContainerDataProvider.overrideWith((ref) => Stream.value(null)),
        // ignore: scoped_providers_should_specify_dependencies
        selectedSpaceProvider.overrideWith(_TestSelectedSpace.new),
        // ignore: scoped_providers_should_specify_dependencies
        zenSettingsWithDefaultsProvider.overrideWith(
          (ref) => ZenSettings.withDefaults(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/open',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: Text('home')),
              routes: [
                GoRoute(
                  path: 'open',
                  builder: (context, state) => Scaffold(
                    body: OpenSharedContent(
                      sharedUrl:
                          sharedUrl ?? Uri.parse('https://example.com/article'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every space in order, with private last', (tester) async {
    await _pumpSheet(tester, _RecordingTabRepository());

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title as Text?)?.data)
        .toList();

    expect(titles, ['Home', 'Dev', 'Gaming', 'Private']);
  });

  testWidgets('tapping a space row opens the link in that space', (
    tester,
  ) async {
    final repository = _RecordingTabRepository();
    await _pumpSheet(tester, repository);

    await tester.tap(find.byKey(const ValueKey('open-shared-space-space-3')));
    await tester.pumpAndSettle();

    expect(repository.added, hasLength(1));
    final added = repository.added.single;
    expect(added.spaceUuid, 'space-3');
    expect(added.tabMode, TabMode.regular);
    expect(added.url, Uri.parse('https://example.com/article'));
    expect(added.containerSelection, isA<UnassignedContainerTabSelection>());
  });

  testWidgets('tapping the private row opens a tab in no space', (
    tester,
  ) async {
    final repository = _RecordingTabRepository();
    await _pumpSheet(tester, repository);

    await tester.tap(find.byKey(const ValueKey('open-shared-private')));
    await tester.pumpAndSettle();

    expect(repository.added, hasLength(1));
    expect(repository.added.single.tabMode, TabMode.private);
    expect(repository.added.single.spaceUuid, isNull);
  });

  testWidgets('a space row opens the edited URL, not the shared one', (
    tester,
  ) async {
    final repository = _RecordingTabRepository();
    await _pumpSheet(tester, repository);

    await tester.enterText(
      find.byType(TextFormField),
      'https://example.com/corrected',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-shared-space-space-1')));
    await tester.pumpAndSettle();

    expect(
      repository.added.single.url,
      Uri.parse('https://example.com/corrected'),
    );
  });
}
