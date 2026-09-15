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
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/move_tab_sheet.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/tab.dart';

/// One recorded [TabDataRepository.moveTabToFolder] call.
typedef _FolderMove = ({String tabId, String? folderId});

/// One recorded [TabDataRepository.moveToScope] call.
typedef _ScopeMove = ({List<String> tabIds, TabOrderScope target});

/// One recorded [TabDataRepository.moveTabToSpace] call.
typedef _SpaceMove = ({String tabId, String spaceUuid});

/// [TabDataRepository] without the database: records what the sheet asks for.
class _RecordingTabDataRepository extends TabDataRepository {
  final folderMoves = <_FolderMove>[];
  final scopeMoves = <_ScopeMove>[];
  final spaceMoves = <_SpaceMove>[];

  @override
  void build() {}

  @override
  Future<bool> moveTabToFolder(String tabId, String? folderId) async {
    folderMoves.add((tabId: tabId, folderId: folderId));
    return true;
  }

  @override
  Future<void> moveToScope(
    List<String> rootTabIds,
    TabOrderScope target, {
    String? afterId,
    String? beforeId,
  }) async {
    scopeMoves.add((tabIds: rootTabIds, target: target));
  }

  @override
  Future<bool> setShelf(
    String tabId,
    TabShelf shelf, {
    required String? activeSpaceUuid,
  }) async {
    return true;
  }

  @override
  Future<bool> moveTabToSpace(String tabId, String spaceUuid) async {
    spaceMoves.add((tabId: tabId, spaceUuid: spaceUuid));
    return true;
  }
}

const _spaceA = 'space-a';
const _spaceB = 'space-b';
const _tabId = 'tab-1';

final _spaceAFolders = [
  TabFolderData(id: 'linux', name: 'Linux', spaceUuid: _spaceA, orderKey: 'a0'),
  TabFolderData(
    id: 'linux-de',
    name: 'DE',
    spaceUuid: _spaceA,
    parentFolderId: 'linux',
    orderKey: 'a0',
  ),
];

final _spaceBFolders = [
  TabFolderData(id: 'macos', name: 'MacOS', spaceUuid: _spaceB, orderKey: 'a0'),
  TabFolderData(
    id: 'macos-de',
    name: 'DE',
    spaceUuid: _spaceB,
    parentFolderId: 'macos',
    orderKey: 'a0',
  ),
];

void main() {
  late _RecordingTabDataRepository repository;

  Future<void> pumpSheet(WidgetTester tester) async {
    repository = _RecordingTabDataRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchSpacesProvider.overrideWith(
            (ref) => Stream.value([
              SpaceData(uuid: _spaceA, name: 'Space A', orderIndex: 0),
              SpaceData(uuid: _spaceB, name: 'Space B', orderIndex: 1),
            ]),
          ),
          watchFoldersProvider(
            _spaceA,
          ).overrideWith((ref) => Stream.value(_spaceAFolders)),
          watchFoldersProvider(
            _spaceB,
          ).overrideWith((ref) => Stream.value(_spaceBFolders)),
          tabDataRepositoryProvider.overrideWith(() => repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showMoveTabSheet(
                  context,
                  tabId: _tabId,
                  currentSpaceUuid: _spaceA,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows This space first, other spaces below with labels', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.text('This space'), findsOneWidget);
    expect(find.text('Space B'), findsOneWidget);
    // Space A is "this space", so it is not repeated as an "other" section.
    expect(find.text('Space A'), findsNothing);

    final thisSpaceTop = tester.getTopLeft(find.text('This space')).dy;
    final spaceBTop = tester.getTopLeft(find.text('Space B')).dy;
    expect(thisSpaceTop, lessThan(spaceBTop));
  });

  testWidgets('shows nested folders with their ancestor path', (tester) async {
    await pumpSheet(tester);

    // Both "DE" folders (Linux/DE in this space, MacOS/DE in the other
    // space) are shown, each distinguishable by its ancestor path — which
    // is why "Linux" and "MacOS" each appear twice: once as a folder title,
    // once as the path subtitle under its "DE" child.
    expect(find.text('DE'), findsNWidgets(2));
    expect(find.text('Linux'), findsNWidgets(2));
    expect(find.text('MacOS'), findsNWidgets(2));
  });

  testWidgets('has a Pin tab row in every space section', (tester) async {
    await pumpSheet(tester);

    expect(find.widgetWithText(ListTile, 'Pin tab'), findsNWidgets(2));
  });

  testWidgets('picking a folder in another space moves the tab there', (
    tester,
  ) async {
    await pumpSheet(tester);

    final macosFolder = find.byKey(const ValueKey('move-tab-folder-macos'));
    await tester.ensureVisible(macosFolder);
    await tester.tap(macosFolder);
    await tester.pumpAndSettle();

    expect(repository.folderMoves, hasLength(1));
    expect(repository.folderMoves.single.tabId, _tabId);
    // The folder itself carries the target space (macos belongs to
    // spaceB), so a single moveTabToFolder call is the whole move.
    expect(repository.folderMoves.single.folderId, 'macos');
  });

  testWidgets(
    'picking a nested folder in another space passes that folder, not its parent',
    (tester) async {
      await pumpSheet(tester);

      final macosDe = find.byKey(const ValueKey('move-tab-folder-macos-de'));
      await tester.ensureVisible(macosDe);
      await tester.tap(macosDe);
      await tester.pumpAndSettle();

      expect(repository.folderMoves, hasLength(1));
      expect(repository.folderMoves.single.folderId, 'macos-de');
    },
  );

  testWidgets("Pin tab in another space pins at that space's root", (
    tester,
  ) async {
    await pumpSheet(tester);

    final pinInSpaceB = find.byKey(const ValueKey('move-tab-pin-space-b'));
    await tester.ensureVisible(pinInSpaceB);
    await tester.tap(pinInSpaceB);
    await tester.pumpAndSettle();

    expect(repository.scopeMoves, hasLength(1));
    expect(repository.scopeMoves.single.tabIds, [_tabId]);
    expect(repository.scopeMoves.single.target.spaceUuid, _spaceB);
    expect(repository.scopeMoves.single.target.folderId, isNull);
    expect(repository.scopeMoves.single.target.shelf, TabShelf.pinned);
  });

  testWidgets('offers a plain move into another space, without pinning', (
    tester,
  ) async {
    await pumpSheet(tester);

    // The picker replaced a "Move to space…" item that could leave a normal
    // tab normal in its new space; filing every cross-space move into a
    // folder or the pinned strip would have taken that away.
    final moveToSpaceB = find.byKey(const ValueKey('move-tab-move-space-b'));
    await tester.ensureVisible(moveToSpaceB);
    await tester.tap(moveToSpaceB);
    await tester.pumpAndSettle();

    expect(repository.spaceMoves, hasLength(1));
    expect(repository.spaceMoves.single.tabId, _tabId);
    expect(repository.spaceMoves.single.spaceUuid, _spaceB);
    expect(repository.scopeMoves, isEmpty);
    expect(repository.folderMoves, isEmpty);
  });

  testWidgets("does not offer a plain move for the tab's own space", (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byKey(const ValueKey('move-tab-move-$_spaceA')), findsNothing);
  });
}
