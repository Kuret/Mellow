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
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/core/providers/persisted_bool.dart';
import 'package:weblibre/domain/services/generic_website.dart';
import 'package:weblibre/features/geckoview/domain/entities/browser_icon.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/tab_list_view.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/essentials_grid.dart';
import 'package:weblibre/features/sync/domain/repositories/sync.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

import '../../../../tabs/data/database/tab_db_test_helpers.dart';

class _EmptyTabStates extends TabStates {
  @override
  Map<String, TabState> build() => const {};
}

class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

/// [SelectedContainer] without its persistence (which wants a profile).
class _TestSelectedContainer extends SelectedContainer {
  @override
  String? build() => null;
}

/// [PersistedBool] without its persistence (which wants a profile).
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
/// [normal] ordinary ones — enough rows to overflow the tray.
Future<TabDatabase> _seed({
  int essentials = 2,
  int pinned = 2,
  int normal = 12,
}) async {
  final db = openTestTabDatabase();
  await db.spaceDao.insertSpace(
    SpaceData(uuid: 'space-1', name: 'Work', orderIndex: 0),
  );
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

Future<void> _pumpTray(WidgetTester tester, {required TabDatabase db}) async {
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
        selectedContainerProvider.overrideWith(_TestSelectedContainer.new),
        selectedTabProvider.overrideWith(_NoSelectedTab.new),
        tabStatesProvider.overrideWith(_EmptyTabStates.new),
        browserRestoreCompleteProvider.overrideWith(_NotRestored.new),
        genericWebsiteServiceProvider.overrideWith(
          _NoIconGenericWebsiteService.new,
        ),
        tabViewFilterControllerProvider.overrideWith(
          _DefaultTabViewFilterController.new,
        ),
        tabListProvider.overrideWith(_EmptyTabList.new),
        // No account: the tray stays on its local scope and the header
        // leaves the synced device row out.
        syncIsAuthenticatedProvider.overrideWith((ref) => false),
        syncRemoteTabsProvider.overrideWith(
          (ref) => Future.value(const <SyncDeviceTabs>[]),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 600,
              child: ViewTabListWidget(
                onClose: () {},
                scrollController: ScrollController(),
                tabsReorderable: false,
                showNewTabFab: false,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: favicon placeholders shimmer forever.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Drift's stream cleanup timers need one more pump after the tree is gone.
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keeps the essentials in view while the tray list scrolls', (
    tester,
  ) async {
    final db = await _seed();
    addTearDown(db.close);

    await _pumpTray(tester, db: db);

    final essentials = find.byType(EssentialsGrid);
    expect(essentials, findsOneWidget);
    expect(find.byType(EssentialTile), findsNWidgets(2));

    final essentialsRect = tester.getRect(essentials);
    final list = find.byType(ListView).last;
    expect(essentialsRect.bottom, lessThanOrEqualTo(tester.getRect(list).top));
    final firstPinnedRow = find.text('pin-0');
    final pinnedRowBefore = tester.getTopLeft(firstPinnedRow).dy;

    // Past the touch slop, so the list really scrolls.
    await tester.drag(list, const Offset(0, -40));
    await tester.pump();

    // The rows moved, the strip did not.
    expect(tester.getTopLeft(firstPinnedRow).dy, lessThan(pinnedRowBefore));
    expect(tester.getRect(essentials), essentialsRect);

    await _disposeTree(tester);
  });
}
