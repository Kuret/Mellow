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
import 'package:weblibre/domain/services/generic_website.dart';
import 'package:weblibre/features/geckoview/domain/entities/browser_icon.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/essentials_grid.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

import '../../data/database/tab_db_test_helpers.dart';

class _EmptyTabStates extends TabStates {
  @override
  Map<String, TabState> build() => const {};
}

class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

class _TestSelectedSpace extends SelectedSpace {
  @override
  String? build() => 'space-c';
}

class _Restored extends BrowserRestoreComplete {
  @override
  bool build() => true;
}

class _NoIconGenericWebsiteService extends GenericWebsiteService {
  @override
  void build() {}

  @override
  Future<BrowserIcon?> getCachedIcon(Uri url) async => null;
}

/// Records which tab a tap selects; selecting is the whole contract of a
/// tile (essentials are cold until tapped, PLAN §7.4).
class _RecordingTabRepository extends TabRepository {
  final selectedTabIds = <String>[];

  @override
  void build() {}

  @override
  Future<bool> selectTab(String tabId) async {
    selectedTabIds.add(tabId);
    return true;
  }
}

const _containerC = 'container-c';
const _containerD = 'container-d';

/// One space on container C; 13 essentials on C's strip (one over Zen's
/// `zen.tabs.essentials.max`), two on D's and one on the unassigned strip.
Future<TabDatabase> _seed() async {
  final db = openTestTabDatabase();
  await seedContainer(db, _containerC);
  await seedContainer(db, _containerD);
  await db.spaceDao.insertSpace(
    SpaceData(
      uuid: 'space-c',
      name: 'C',
      containerId: _containerC,
      orderIndex: 0,
    ),
  );
  for (var i = 0; i < 13; i++) {
    await seedTab(
      db,
      'c-$i',
      containerId: _containerC,
      shelf: TabShelf.essential,
    );
  }
  for (var i = 0; i < 2; i++) {
    await seedTab(
      db,
      'd-$i',
      containerId: _containerD,
      shelf: TabShelf.essential,
    );
  }
  await seedTab(db, 'u-0', shelf: TabShelf.essential);
  await seedTab(db, 'normal', spaceUuid: 'space-c', containerId: _containerC);
  return db;
}

Future<_RecordingTabRepository> _pump(
  WidgetTester tester, {
  required TabDatabase db,
  required bool separateEssentials,
}) async {
  final repository = _RecordingTabRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tabDatabaseProvider.overrideWith((ref) => db),
        tabRepositoryProvider.overrideWith(() => repository),
        generalSettingsWithDefaultsProvider.overrideWith(
          (ref) => GeneralSettings.withDefaults(
            separateEssentials: separateEssentials,
          ),
        ),
        selectedSpaceProvider.overrideWith(_TestSelectedSpace.new),
        selectedTabProvider.overrideWith(_NoSelectedTab.new),
        tabStatesProvider.overrideWith(_EmptyTabStates.new),
        browserRestoreCompleteProvider.overrideWith(_Restored.new),
        genericWebsiteServiceProvider.overrideWith(
          _NoIconGenericWebsiteService.new,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 6 * 52.0,
            child: SingleChildScrollView(child: EssentialsGrid()),
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: the favicon placeholder shimmers forever.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return repository;
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shows the space container strip only, wrapping past twelve, with no '
    'titles and no close buttons',
    (tester) async {
      final db = await _seed();
      addTearDown(db.close);

      await _pump(tester, db: db, separateEssentials: true);

      expect(find.text('Essentials'), findsOneWidget);
      final tiles = find.byType(EssentialTile);
      expect(tiles, findsNWidgets(13));
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.text('c-0'), findsNothing);

      // Six per row: 13 tiles take three rows.
      final rowTops = {
        for (final element in tiles.evaluate())
          tester.getTopLeft(find.byWidget(element.widget)).dy,
      };
      expect(rowTops, hasLength(3));

      await _disposeTree(tester);
    },
  );

  testWidgets('caps the grid at two rows and scrolls the rest inside it', (
    tester,
  ) async {
    // 14 essentials on the space's strip: three rows at six columns.
    final db = openTestTabDatabase();
    addTearDown(db.close);
    await seedContainer(db, _containerC);
    await db.spaceDao.insertSpace(
      SpaceData(
        uuid: 'space-c',
        name: 'C',
        containerId: _containerC,
        orderIndex: 0,
      ),
    );
    for (var i = 0; i < 14; i++) {
      await seedTab(
        db,
        'c-$i',
        containerId: _containerC,
        shelf: TabShelf.essential,
      );
    }

    await _pump(tester, db: db, separateEssentials: true);

    final tiles = find.byType(EssentialTile);
    expect(tiles, findsNWidgets(14));

    // Two rows of cells tall, not three.
    final viewport = find.byKey(EssentialsGrid.viewportKey);
    final viewportHeight = tester.getSize(viewport).height;
    final cellHeight = tester
        .getSize(find.byKey(const ValueKey('essential-c-0')))
        .height;
    expect(viewportHeight, closeTo(2 * cellHeight + 4, 0.01));

    // Three rows of cells are laid out inside it, so the last row starts
    // below its bottom edge...
    final rowTops = {
      for (final element in tiles.evaluate())
        tester.getTopLeft(find.byWidget(element.widget)).dy,
    };
    expect(rowTops, hasLength(3));
    final lastRow = find.byKey(const ValueKey('essential-c-12'));
    final before = tester.getTopLeft(lastRow).dy;
    expect(before, greaterThan(tester.getBottomLeft(viewport).dy));

    // ...and a drag inside the grid brings it up.
    await tester.drag(viewport, const Offset(0, -60));
    await tester.pump();

    expect(tester.getTopLeft(lastRow).dy, lessThan(before));

    await _disposeTree(tester);
  });

  testWidgets('tapping a tile selects the tab', (tester) async {
    final db = await _seed();
    addTearDown(db.close);

    final repository = await _pump(tester, db: db, separateEssentials: true);
    await tester.tap(find.byKey(const ValueKey('essential-c-3')));
    await tester.pump();

    expect(repository.selectedTabIds, ['c-3']);

    await _disposeTree(tester);
  });

  testWidgets(
    'with separateEssentials off every strip shows, unassigned first then '
    'by container',
    (tester) async {
      final db = await _seed();
      addTearDown(db.close);

      await _pump(tester, db: db, separateEssentials: false);

      final tiles = find.byType(EssentialTile);
      expect(tiles, findsNWidgets(16));
      final ids = [
        for (final element in tiles.evaluate())
          (element.widget as EssentialTile).tabId,
      ];
      expect(ids.first, 'u-0');
      expect(ids.indexOf('c-0'), lessThan(ids.indexOf('d-0')));

      await _disposeTree(tester);
    },
  );
}
