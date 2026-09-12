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
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/data/database/functions/lexo_rank_functions.dart';
import 'package:weblibre/data/database/functions/url_functions.dart';
import 'package:weblibre/domain/services/generic_website.dart';
import 'package:weblibre/features/geckoview/domain/entities/browser_icon.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/quick_tab_switcher_accordion.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

/// [TabStates] without the native GeckoView event listeners, standing in for
/// the pre-restore window where no tab has reported a native state yet.
class _EmptyTabStates extends TabStates {
  @override
  Map<String, TabState> build() => const {};
}

/// [SelectedTab] without its native event listeners.
class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

/// [SelectedSpace] without its persistence and tab-selection listeners,
/// fixed to the single test space.
class _TestSelectedSpace extends SelectedSpace {
  @override
  String? build() => 'space-1';
}

/// Forces the pre-restore ("placeholder") code path: the switcher then reads
/// the tab's title straight from the database row instead of a native
/// [TabState], and skips the long-press [TabMenu] (which wants live engine
/// state this test doesn't have).
class _NotRestored extends BrowserRestoreComplete {
  @override
  bool build() => false;
}

/// [GenericWebsiteService] without disk/network favicon lookups.
class _NoIconGenericWebsiteService extends GenericWebsiteService {
  @override
  void build() {}

  @override
  Future<BrowserIcon?> getCachedIcon(Uri url) async => null;
}

/// [TabList] without the native engine-ready listener, which otherwise leaves
/// a pending Timer behind when the provider is disposed under test.
class _EmptyTabList extends TabList {
  @override
  EquatableValue<List<String>> build() => EquatableValue(const []);
}

/// [TabViewFilterController] without the persisted-settings database (which
/// needs an activated profile, unavailable in this test).
class _DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

Future<TabDatabase> _memoryDatabaseWithOneTab({required String title}) async {
  final db = TabDatabase(
    NativeDatabase.memory(
      setup: (database) {
        registerLexorankFunctions(database);
        registerUrlFunctions(database);
      },
    ),
  );
  await db.tabDao.insertTab(
    'tab-1',
    source: TabSource.manual,
    parentId: const Value(null),
    spaceUuid: const Value('space-1'),
    url: Value(Uri.parse('https://example.com')),
    title: Value(title),
    tabMode: const Value(TabMode.regular),
  );
  return db;
}

Future<void> _pumpAccordion(
  WidgetTester tester, {
  required TabDatabase db,
  required double railWidth,
  required double viewportWidth,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tabDatabaseProvider.overrideWith((ref) => db),
        generalSettingsWithDefaultsProvider.overrideWith(
          (ref) => GeneralSettings.withDefaults(
            tabBarPosition: TabBarPosition.left,
            railWidth: railWidth,
          ),
        ),
        watchSpacesProvider.overrideWith(
          (ref) => Stream.value(<SpaceData>[
            SpaceData(uuid: 'space-1', name: 'Space', orderIndex: 0),
          ]),
        ),
        selectedSpaceProvider.overrideWith(_TestSelectedSpace.new),
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
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(size: Size(viewportWidth, 800)),
            child: SizedBox(
              width: railWidth,
              height: 600,
              child: const AccordionQuickTabSwitcher(axis: Axis.vertical),
            ),
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: the chip's favicon placeholder runs a perpetual
  // shimmer animation that never settles. A handful of pumps is enough for
  // the (stubbed, synchronous-ish) database streams and futures to resolve.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Tears the provider/widget tree down before the test body returns.
///
/// Drift's stream queries schedule a zero-duration cleanup Timer when their
/// subscription is cancelled; disposing the [ProviderScope] (and its drift
/// stream subscriptions) only when `testWidgets` tears down after the test
/// body returns leaves that Timer with no further pump to run it in, which
/// flutter_test's `!timersPending` check then flags. Disposing explicitly
/// here, with one more pump still available, avoids that.
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tabTitle = 'Wide Rail Tab';

  testWidgets('shows the tab title on a wide vertical rail', (tester) async {
    final db = await _memoryDatabaseWithOneTab(title: tabTitle);
    addTearDown(db.close);

    await _pumpAccordion(tester, db: db, railWidth: 200, viewportWidth: 900);

    expect(find.text(tabTitle), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('hides the tab title on a narrow vertical rail', (tester) async {
    final db = await _memoryDatabaseWithOneTab(title: tabTitle);
    addTearDown(db.close);

    await _pumpAccordion(
      tester,
      db: db,
      railWidth: minRailWidth,
      viewportWidth: 900,
    );

    expect(find.text(tabTitle), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets(
    'hides the tab title on a wide railWidth when the viewport itself is '
    'narrow (a phone in portrait)',
    (tester) async {
      final db = await _memoryDatabaseWithOneTab(title: tabTitle);
      addTearDown(db.close);

      await _pumpAccordion(tester, db: db, railWidth: 200, viewportWidth: 360);

      expect(find.text(tabTitle), findsNothing);

      await _disposeTree(tester);
    },
  );
}
