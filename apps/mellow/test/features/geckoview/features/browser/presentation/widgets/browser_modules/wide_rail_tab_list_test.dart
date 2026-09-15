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
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/domain/services/generic_website.dart';
import 'package:mellow/features/geckoview/domain/entities/browser_icon.dart';
import 'package:mellow/features/geckoview/domain/entities/states/tab.dart';
import 'package:mellow/features/geckoview/domain/providers/restore_complete.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_list.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_tab_list.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/essentials_grid.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/zen_settings.dart';

import '../../../../tabs/data/database/tab_db_test_helpers.dart';

class _EmptyTabStates extends TabStates {
  @override
  Map<String, TabState> build() => const {};
}

class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

class _FixedSelectedTab extends SelectedTab {
  _FixedSelectedTab(this.tabId);

  final String tabId;

  @override
  String? build() => tabId;
}

class _TestSelectedSpace extends SelectedSpace {
  @override
  String? build() => 'space-1';
}

/// Pre-restore path: titles come from the database rows.
class _NotRestored extends BrowserRestoreComplete {
  @override
  bool build() => false;
}

class _NoIconGenericWebsiteService extends GenericWebsiteService {
  @override
  void build() {}

  @override
  Future<BrowserIcon?> getCachedIcon(Uri url) async => null;
}

class _EmptyTabList extends TabList {
  @override
  EquatableValue<List<String>> build() => EquatableValue(const []);
}

class _DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

/// One space with [essentials] on its strip, [pinned] pinned tabs and
/// [normal] ordinary ones — enough rows to overflow the rail.
Future<TabDatabase> _seed({
  int essentials = 2,
  int pinned = 2,
  int normal = 20,
  bool folder = false,
}) async {
  final db = openTestTabDatabase();
  await db.spaceDao.insertSpace(
    SpaceData(uuid: 'space-1', name: 'Work', orderIndex: 0),
  );
  if (folder) {
    // Collapsed in storage, so its member only shows once the row is tapped.
    await db.tabFolderDao.insertFolder(
      TabFolderData(
        id: 'folder-1',
        name: 'Folder',
        spaceUuid: 'space-1',
        isCollapsed: true,
        orderKey: 'f',
      ),
    );
    await seedTab(
      db,
      'mem-0',
      spaceUuid: 'space-1',
      folderId: 'folder-1',
      shelf: TabShelf.pinned,
    );
  }
  for (var i = 0; i < essentials; i++) {
    await seedTab(db, 'ess-$i', shelf: TabShelf.essential);
  }
  for (var i = 0; i < pinned; i++) {
    await seedTab(db, 'pin-$i', spaceUuid: 'space-1', shelf: TabShelf.pinned);
  }
  for (var i = 0; i < normal; i++) {
    await seedTab(db, 'tab-$i', spaceUuid: 'space-1');
  }
  return db;
}

Future<void> _pumpRail(
  WidgetTester tester, {
  required TabDatabase db,
  String? selectedTabId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tabDatabaseProvider.overrideWith((ref) => db),
        zenSettingsWithDefaultsProvider.overrideWith(
          (ref) => ZenSettings.withDefaults(),
        ),
        generalSettingsWithDefaultsProvider.overrideWith(
          (ref) => GeneralSettings.withDefaults(),
        ),
        watchSpacesProvider.overrideWith(
          (ref) => Stream.value(<SpaceData>[
            SpaceData(uuid: 'space-1', name: 'Work', orderIndex: 0),
          ]),
        ),
        selectedSpaceProvider.overrideWith(_TestSelectedSpace.new),
        if (selectedTabId == null)
          selectedTabProvider.overrideWith(_NoSelectedTab.new)
        else
          selectedTabProvider.overrideWith(
            () => _FixedSelectedTab(selectedTabId),
          ),
        tabStatesProvider.overrideWith(_EmptyTabStates.new),
        browserRestoreCompleteProvider.overrideWith(_NotRestored.new),
        genericWebsiteServiceProvider.overrideWith(
          _NoIconGenericWebsiteService.new,
        ),
        tabViewFilterControllerProvider.overrideWith(
          _DefaultTabViewFilterController.new,
        ),
        tabListProvider.overrideWith(_EmptyTabList.new),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              height: 400,
              child: WideRailTabList(spaceUuid: 'space-1'),
            ),
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: favicon placeholders shimmer forever.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Drift's stream cleanup timers need one more pump after the tree is gone,
/// and the rail arms a 1.5s "the user is scrolling" timer on every drag.
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keeps the essentials in view while the list scrolls', (
    tester,
  ) async {
    final db = await _seed();
    addTearDown(db.close);

    await _pumpRail(tester, db: db);

    final essentials = find.byType(EssentialsGrid);
    expect(essentials, findsOneWidget);
    expect(find.byType(EssentialTile), findsNWidgets(2));

    // Essentials above the scrolling list, which opens with the "Pinned"
    // label and the pinned rows.
    final list = find.byType(ListView);
    expect(list, findsOneWidget);
    final essentialsRect = tester.getRect(essentials);
    expect(essentialsRect.bottom, lessThanOrEqualTo(tester.getRect(list).top));
    expect(
      tester.getTopLeft(find.text('Pinned')).dy,
      greaterThan(essentialsRect.bottom),
    );
    final firstPinnedRow = find.byKey(const ValueKey('tab-pin-0'));
    final pinnedRowBefore = tester.getTopLeft(firstPinnedRow).dy;

    // Past the touch slop, so the list really scrolls.
    await tester.drag(list, const Offset(0, -40));
    await tester.pump();

    // The rows moved, the strip did not.
    expect(tester.getTopLeft(firstPinnedRow).dy, lessThan(pinnedRowBefore));
    expect(tester.getTopLeft(find.text('Tabs')).dy, greaterThan(0));
    expect(tester.getRect(essentials), essentialsRect);

    await _disposeTree(tester);
  });

  testWidgets('expanding a folder leaves the scroll position alone', (
    tester,
  ) async {
    final db = await _seed(essentials: 0, pinned: 1, folder: true);
    addTearDown(db.close);

    // An active tab at the far end of the list: expanding the folder shifts
    // its index, which used to be read as "the active row moved" and scrolled
    // the rail back down to it.
    await _pumpRail(tester, db: db, selectedTabId: 'tab-19');

    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    expect(controller.offset, greaterThan(0));

    // Back to the top, where the folder row is.
    controller.jumpTo(0);
    await tester.pump();
    expect(find.text('Folder'), findsOneWidget);
    expect(find.text('mem-0'), findsNothing);

    await tester.tap(find.text('Folder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('mem-0'), findsOneWidget);
    expect(controller.offset, 0);

    await _disposeTree(tester);
  });

  testWidgets('drops the essentials slot for a space without any', (
    tester,
  ) async {
    final db = await _seed(essentials: 0);
    addTearDown(db.close);

    await _pumpRail(tester, db: db);

    expect(find.byType(EssentialTile), findsNothing);
    expect(
      tester.getRect(find.byType(ListView)),
      tester.getRect(find.byType(WideRailTabList)),
    );

    await _disposeTree(tester);
  });
}
