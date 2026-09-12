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
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/quick_tab_switcher_accordion.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/cold_tab_badge.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

/// [TabStates] without the native listeners: after the restore, a tab with
/// no state and no `engine_tab_id` is a cold one.
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
  String? build() => 'space-1';
}

/// The restore window is closed, so a row without engine state is cold
/// rather than a pre-restore placeholder.
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

class _EmptyTabList extends TabList {
  @override
  EquatableValue<List<String>> build() => EquatableValue(const []);
}

class _DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

/// [TabRepository] without the engine: records which tab a tap selects.
/// Selecting a cold tab is what materialises it (PLAN §7.4 item 2), so the
/// tap reaching [selectTab] is the whole contract of the chip.
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

Future<TabDatabase> _memoryDatabaseWithOneColdTab({
  required String title,
}) async {
  final db = TabDatabase(
    NativeDatabase.memory(
      setup: (database) {
        registerLexorankFunctions(database);
        registerUrlFunctions(database);
      },
    ),
  );
  await db.spaceDao.insertSpace(SpaceData(uuid: 'space-1', orderIndex: 0));
  await db.tabDao.insertTab(
    'tab-1',
    source: TabSource.manual,
    parentId: const Value(null),
    spaceUuid: const Value('space-1'),
    url: Value(Uri.parse('https://example.com')),
    title: Value(title),
    tabMode: const Value(TabMode.regular),
  );
  await db.tabDao.setEngineTabId('tab-1', null);
  return db;
}

Future<_RecordingTabRepository> _pumpAccordion(
  WidgetTester tester, {
  required TabDatabase db,
}) async {
  final repository = _RecordingTabRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tabDatabaseProvider.overrideWith((ref) => db),
        tabRepositoryProvider.overrideWith(() => repository),
        generalSettingsWithDefaultsProvider.overrideWith(
          (ref) => GeneralSettings.withDefaults(
            tabBarPosition: TabBarPosition.left,
            railWidth: 200,
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
        browserRestoreCompleteProvider.overrideWith(_Restored.new),
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
          body: MediaQuery(
            data: MediaQueryData(size: Size(900, 800)),
            child: SizedBox(
              width: 200,
              height: 600,
              child: AccordionQuickTabSwitcher(axis: Axis.vertical),
            ),
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: the favicon placeholder shimmers forever. A few pumps
  // let the database streams and futures resolve.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return repository;
}

/// See the wide-rail test: drift's stream cleanup timers need one more pump
/// after the tree is gone.
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tabTitle = 'Cold Tab';

  testWidgets('a cold tab renders its stored title with a snowflake badge', (
    tester,
  ) async {
    final db = await _memoryDatabaseWithOneColdTab(title: tabTitle);
    addTearDown(db.close);

    await _pumpAccordion(tester, db: db);

    expect(find.text(tabTitle), findsOneWidget);
    expect(find.byType(ColdTabBadge), findsOneWidget);
    expect(find.byIcon(MdiIcons.snowflakeVariant), findsOneWidget);
    final dimmed = tester.widget<Opacity>(
      find.ancestor(of: find.text(tabTitle), matching: find.byType(Opacity)),
    );
    expect(dimmed.opacity, ColdTabBadge.opacity);

    await _disposeTree(tester);
  });

  testWidgets('tapping a cold tab selects it, which materialises it', (
    tester,
  ) async {
    final db = await _memoryDatabaseWithOneColdTab(title: tabTitle);
    addTearDown(db.close);

    final repository = await _pumpAccordion(tester, db: db);
    await tester.tap(find.text(tabTitle));
    await tester.pump();

    expect(repository.selectedTabIds, ['tab-1']);

    await _disposeTree(tester);
  });
}
