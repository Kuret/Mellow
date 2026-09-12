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
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/entities/tab_container_selection.dart';
import 'package:weblibre/features/geckoview/domain/providers.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/domain/services/live_tab_budget.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_list_scope.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

import '../../features/tabs/data/database/tab_db_test_helpers.dart';

const _space = 'space-1';

/// The engine, reduced to what cold tabs need of it: it records the ids it
/// is asked to create, remove and select, creates tabs under the id it is
/// handed (DESIGN.md "D2 refinement"), and reports list changes through
/// [onAdded] / [onRemoved] so the harness can mirror them into the fake tab
/// list, like the native tab-list event would.
class FakeGeckoTabService extends GeckoTabService {
  final addedTabIds = <String?>[];
  final removedTabIds = <String>[];
  final selectedTabIds = <String>[];
  void Function(String tabId)? onAdded;
  void Function(String tabId)? onRemoved;
  var _generated = 0;

  @override
  Future<String> addTab({
    Uri? url,
    bool selectTab = true,
    bool startLoading = true,
    String? parentId,
    LoadUrlFlags flags = LoadUrlFlags.NONE,
    String? contextId,
    Source source = Internal.newTab,
    bool private = false,
    HistoryMetadataKey? historyMetadata,
    Map<String, String>? additionalHeaders,
    bool excludeFromHistory = false,
    String? tabId,
  }) async {
    addedTabIds.add(tabId);
    final id = tabId ?? 'engine-${_generated++}';
    onAdded?.call(id);
    return id;
  }

  @override
  Future<void> removeTab({required String tabId}) async {
    removedTabIds.add(tabId);
    onRemoved?.call(tabId);
  }

  @override
  Future<void> removeTabs({required List<String> ids}) async {
    for (final id in ids) {
      await removeTab(tabId: id);
    }
  }

  @override
  Future<void> selectTab({required String tabId}) async {
    selectedTabIds.add(tabId);
  }
}

/// [TabList] fed by the harness instead of native events.
class _FakeTabList extends TabList {
  _FakeTabList(this._initial);

  final List<String> _initial;

  List<String> get tabs => state.value;

  @override
  EquatableValue<List<String>> build() => EquatableValue(List.of(_initial));

  void setTabs(List<String> ids) {
    state = EquatableValue(List.of(ids));
  }
}

/// [TabStates] with a bare state per live tab and no native listeners.
class _FakeTabStates extends TabStates {
  _FakeTabStates(this._ids);

  final List<String> _ids;

  @override
  Map<String, TabState> build() => {
    for (final id in _ids) id: TabState.$default(id),
  };
}

class _FakeSelectedTab extends SelectedTab {
  _FakeSelectedTab(this._id);

  final String? _id;

  @override
  String? build() => _id;
}

class _RestoreComplete extends BrowserRestoreComplete {
  @override
  bool build() => true;
}

class _FakeSelectedSpace extends SelectedSpace {
  @override
  String? build() => _space;
}

class _DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

typedef _Harness = ({
  ProviderContainer container,
  TabDatabase db,
  FakeGeckoTabService engine,
  _FakeTabList tabList,
});

/// A container around an in-memory [TabDatabase], a [FakeGeckoTabService]
/// and a tab list that mirrors what the fake engine does, with the restore
/// window closed.
_Harness _openHarness({
  required List<String> liveTabIds,
  String? selectedTabId,
  GeneralSettings? settings,
}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = openTestTabDatabase();
  final engine = FakeGeckoTabService();
  final container = ProviderContainer(
    overrides: [
      tabDatabaseProvider.overrideWithValue(db),
      geckoTabServiceProvider.overrideWithValue(engine),
      tabListProvider.overrideWith(() => _FakeTabList(liveTabIds)),
      tabStatesProvider.overrideWith(() => _FakeTabStates(liveTabIds)),
      selectedTabProvider.overrideWith(() => _FakeSelectedTab(selectedTabId)),
      browserRestoreCompleteProvider.overrideWith(_RestoreComplete.new),
      selectedSpaceProvider.overrideWith(_FakeSelectedSpace.new),
      tabViewFilterControllerProvider.overrideWith(
        _DefaultTabViewFilterController.new,
      ),
      generalSettingsWithDefaultsProvider.overrideWith(
        (ref) => settings ?? GeneralSettings.withDefaults(),
      ),
    ],
  );
  final tabList = container.read(tabListProvider.notifier) as _FakeTabList;
  engine.onAdded = (id) => tabList.setTabs([...tabList.tabs, id]);
  engine.onRemoved = (id) =>
      tabList.setTabs([...tabList.tabs.where((tab) => tab != id)]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return (container: container, db: db, engine: engine, tabList: tabList);
}

/// Seeds [_space] with [cold] cold rows (`cold-000`…) and [live] live rows
/// (`live-00`…). Live rows get ascending timestamps, so the lower the index
/// the longer since it was used.
Future<void> _seed(
  TabDatabase db, {
  required int cold,
  required int live,
  Set<int> pinnedLive = const {},
  Set<int> essentialLive = const {},
}) async {
  await db.spaceDao.insertSpace(SpaceData(uuid: _space, orderIndex: 0));
  await db.transaction(() async {
    for (var i = 0; i < cold; i++) {
      final id = 'cold-${i.toString().padLeft(3, '0')}';
      await seedTab(db, id, spaceUuid: _space);
      await db.tabDao.setEngineTabId(id, null);
    }
    for (var i = 0; i < live; i++) {
      final id = 'live-${i.toString().padLeft(2, '0')}';
      final essential = essentialLive.contains(i);
      await seedTab(
        db,
        id,
        spaceUuid: essential ? null : _space,
        shelf: essential
            ? TabShelf.essential
            : pinnedLive.contains(i)
            ? TabShelf.pinned
            : TabShelf.normal,
      );
      await db.tabDao.touchTab(
        id,
        timestamp: DateTime(2024).add(Duration(minutes: i)),
      );
    }
  });
}

List<String> _liveIds(int count) => [
  for (var i = 0; i < count; i++) 'live-${i.toString().padLeft(2, '0')}',
];

/// Polls [condition] until it holds or [timeout] passes; the repository
/// reacts to the tab list asynchronously and the DB streams settle in their
/// own time.
Future<void> _waitFor(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<int> _tombstoneCount(TabDatabase db) async =>
    (await db.select(db.closedTabTombstone).get()).length;

void main() {
  group('cold tabs (PLAN §7.4)', () {
    test('groupedTabListItems lists cold rows next to the live ones', () async {
      final h = _openHarness(liveTabIds: _liveIds(10));
      await _seed(h.db, cold: 300, live: 10);

      final provider = groupedTabListItemsProvider(
        spaceUuid: _space,
        scope: TabListScope.tray,
      );
      final sub = h.container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      await _waitFor(() async => sub.read().value.length == 310);
      expect(sub.read().value, hasLength(310));
    });

    test(
      'materializeTab asks the engine for the row id once and marks it live',
      () async {
        final h = _openHarness(liveTabIds: _liveIds(10));
        await _seed(h.db, cold: 300, live: 10);
        final repo = h.container.read(tabRepositoryProvider.notifier);

        expect(await repo.materializeTab('cold-005'), isTrue);

        expect(h.engine.addedTabIds, ['cold-005']);
        expect((await summaryOf(h.db, 'cold-005')).engineTabId, 'cold-005');
        expect(h.tabList.tabs, contains('cold-005'));

        // Now live: the second call selects instead of creating again.
        expect(await repo.materializeTab('cold-005'), isTrue);
        expect(h.engine.addedTabIds, ['cold-005']);
        expect(h.engine.selectedTabIds, ['cold-005']);
      },
    );

    test('selectTab on a cold row materialises it', () async {
      final h = _openHarness(liveTabIds: _liveIds(10));
      await _seed(h.db, cold: 300, live: 10);
      final repo = h.container.read(tabRepositoryProvider.notifier);

      expect(await repo.selectTab('cold-007'), isTrue);

      expect(h.engine.addedTabIds, ['cold-007']);
      // The engine selected it while creating it; no separate select call.
      expect(h.engine.selectedTabIds, isEmpty);
      expect((await summaryOf(h.db, 'cold-007')).engineTabId, 'cold-007');
    });

    test('demoteToCold clears engine_tab_id, keeps the row and writes no '
        'tombstone', () async {
      final h = _openHarness(
        liveTabIds: _liveIds(10),
        selectedTabId: 'live-00',
      );
      await _seed(h.db, cold: 300, live: 10, pinnedLive: {1});
      final repo = h.container.read(tabRepositoryProvider.notifier);

      expect(await repo.demoteToCold('live-03'), isTrue);

      expect(h.engine.removedTabIds, ['live-03']);
      final row = await summaryOf(h.db, 'live-03');
      expect(row.engineTabId, isNull);
      expect(row.title, 'live-03');
      expect(await _tombstoneCount(h.db), 0);

      // The tab-list emission that follows the removal must not turn the
      // demotion into a close.
      await _waitFor(() async => !h.tabList.tabs.contains('live-03'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect((await summaryOf(h.db, 'live-03')).engineTabId, isNull);
      expect(await _tombstoneCount(h.db), 0);

      // Refused for the selected tab, pinned tabs and cold rows.
      expect(await repo.demoteToCold('live-00'), isFalse);
      expect(await repo.demoteToCold('live-01'), isFalse);
      expect(await repo.demoteToCold('cold-000'), isFalse);
      expect(h.engine.removedTabIds, ['live-03']);
    });

    test(
      'closing a live tab still deletes its row and tombstones it',
      () async {
        final h = _openHarness(liveTabIds: _liveIds(10));
        await _seed(h.db, cold: 300, live: 10);
        final repo = h.container.read(tabRepositoryProvider.notifier);

        await repo.closeTab('live-02');

        expect(h.engine.removedTabIds, ['live-02']);
        expect(await _tombstoneCount(h.db), 1);
        await _waitFor(
          () async =>
              await h.db.tabDao
                  .getTabSummaryById('live-02')
                  .getSingleOrNull() ==
              null,
        );
        expect(await h.db.tabDao.coldTabIds().get(), hasLength(300));
      },
    );

    test('closing a cold tab deletes the row without an engine call', () async {
      final h = _openHarness(liveTabIds: _liveIds(10));
      await _seed(h.db, cold: 300, live: 10);
      final repo = h.container.read(tabRepositoryProvider.notifier);

      await repo.closeTab('cold-042');

      expect(h.engine.removedTabIds, isEmpty);
      expect(
        await h.db.tabDao.getTabSummaryById('cold-042').getSingleOrNull(),
        isNull,
      );
      expect(await _tombstoneCount(h.db), 1);
    });

    test('syncTabs with the live engine ids keeps every cold row', () async {
      final h = _openHarness(liveTabIds: _liveIds(10));
      await _seed(h.db, cold: 300, live: 10);

      final result = await h.db.tabDao.syncTabs(
        engineTabIds: _liveIds(10),
        defaultSpaceUuid: _space,
      );

      expect(result.deletedTabIds, isEmpty);
      expect(result.demotedTabIds, isEmpty);
      expect(result.insertedTabIds, isEmpty);
      expect(await h.db.tabDao.coldTabIds().get(), hasLength(300));
      expect(await h.db.tabDao.liveTabCount().getSingle(), 10);
    });

    test('addTab mints a Zen-format id and hands it to the engine', () async {
      final h = _openHarness(liveTabIds: _liveIds(10));
      await _seed(h.db, cold: 0, live: 10);
      final repo = h.container.read(tabRepositoryProvider.notifier);

      final id = await repo.addTab(
        tabMode: TabMode.regular,
        url: Uri.parse('https://new.example/'),
        selectTab: false,
        spaceUuid: _space,
        containerSelection: const TabContainerSelection.unassigned(),
      );

      expect(id, matches(RegExp(r'^\d{13}-\d{1,3}$')));
      expect(h.engine.addedTabIds, [id]);
      final row = await summaryOf(h.db, id);
      expect(row.engineTabId, id);
      expect(row.spaceUuid, _space);
    });

    test('the live tab budget unloads the least recently used tabs past the '
        'budget and spares the selected, pinned and essential ones', () async {
      final h = _openHarness(
        liveTabIds: _liveIds(30),
        selectedTabId: 'live-00',
        settings: GeneralSettings.withDefaults(maxLiveTabs: 25),
      );
      await _seed(h.db, cold: 0, live: 30, pinnedLive: {1}, essentialLive: {2});

      final sub = h.container.listen(liveTabBudgetProvider, (_, _) {});
      addTearDown(sub.close);

      await _waitFor(() async => h.engine.removedTabIds.length == 5);
      // One more gap's worth of time: nothing beyond the budget goes.
      await Future<void>.delayed(LiveTabBudget.demoteGap * 2);

      expect(
        h.engine.removedTabIds,
        unorderedEquals([
          'live-03',
          'live-04',
          'live-05',
          'live-06',
          'live-07',
        ]),
      );
      expect(h.tabList.tabs, hasLength(25));
      expect(await h.db.tabDao.liveTabCount().getSingle(), 25);
      expect(await _tombstoneCount(h.db), 0);
      for (final id in ['live-00', 'live-01', 'live-02']) {
        expect((await summaryOf(h.db, id)).engineTabId, id);
      }
    });
  });
}
