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
import 'package:mellow/features/geckoview/domain/entities/states/tab.dart';
import 'package:mellow/features/geckoview/domain/providers.dart';
import 'package:mellow/features/geckoview/domain/providers/restore_complete.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_list.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/space_last_tab.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/zen_settings.dart';

import '../../features/tabs/data/database/tab_db_test_helpers.dart';

const _spaceA = 'space-a';
const _spaceB = 'space-b';

/// The engine, reduced to what selection/materialisation need of it.
class _FakeGeckoTabService extends GeckoTabService {
  final addedTabIds = <String?>[];
  final selectedTabIds = <String>[];
  void Function(String tabId)? onAdded;
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
  Future<void> removeTab({required String tabId}) async {}

  @override
  Future<void> removeTabs({required List<String> ids}) async {}

  @override
  Future<void> selectTab({required String tabId}) async {
    selectedTabIds.add(tabId);
  }
}

class _FakeTabList extends TabList {
  _FakeTabList(this._initial);

  final List<String> _initial;

  List<String> get tabs => state.value;

  @override
  EquatableValue<List<String>> build() => EquatableValue(List.of(_initial));

  void setTabs(List<String> ids) => state = EquatableValue(List.of(ids));
}

class _FakeTabStates extends TabStates {
  _FakeTabStates(this._ids);

  final List<String> _ids;

  @override
  Map<String, TabState> build() => {
    for (final id in _ids) id: TabState.$default(id),
  };
}

/// [SelectedTab] fixed to whatever the test needs "currently selected" to be.
class _MutableSelectedTab extends SelectedTab {
  _MutableSelectedTab([this._initial]);

  final String? _initial;

  @override
  String? build() => _initial;
}

class _RestoreComplete extends BrowserRestoreComplete {
  @override
  bool build() => true;
}

/// [SelectedSpace] fixed to whatever the test needs "currently selected" to
/// be — [TabRepository.restoreSpaceTab] takes the target space as a plain
/// argument, but [ForceBrowserHome.request] reads this to know which space's
/// memory to update.
class _FakeSelectedSpace extends SelectedSpace {
  _FakeSelectedSpace(this._value);

  final String? _value;

  @override
  String? build() => _value;
}

class _DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

/// [SpaceLastTab] without persistence, seeded directly and readable back for
/// assertions.
class _FakeSpaceLastTab extends SpaceLastTab {
  _FakeSpaceLastTab([Map<String, String?> initial = const {}])
    : _initial = initial;

  final Map<String, String?> _initial;

  @override
  Map<String, String?> build() => Map.of(_initial);

  @override
  Future<SpaceLastTabEntry?> entryFor(String spaceUuid) async {
    if (!state.containsKey(spaceUuid)) return null;
    final tabId = state[spaceUuid];
    return tabId == null ? const SpaceLastTabHome() : SpaceLastTabTab(tabId);
  }

  @override
  Future<void> recordTab(String spaceUuid, String tabId) async {
    state = {...state, spaceUuid: tabId};
  }

  @override
  Future<void> recordHome(String spaceUuid) async {
    state = {...state, spaceUuid: null};
  }

  @override
  Future<void> pruneToSpaces(Set<String> validSpaceUuids) async {
    state = {
      for (final entry in state.entries)
        if (validSpaceUuids.contains(entry.key)) entry.key: entry.value,
    };
  }
}

typedef _Harness = ({
  ProviderContainer container,
  TabDatabase db,
  _FakeGeckoTabService engine,
  _FakeTabList tabList,
  _MutableSelectedTab selectedTab,
  _FakeSpaceLastTab spaceLastTab,
});

_Harness _openHarness({
  required List<String> liveTabIds,
  String? selectedTabId,
  String? currentSelectedSpace,
  Map<String, String?> lastTabEntries = const {},
}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = openTestTabDatabase();
  final engine = _FakeGeckoTabService();
  final selectedTab = _MutableSelectedTab(selectedTabId);
  final spaceLastTab = _FakeSpaceLastTab(lastTabEntries);
  final container = ProviderContainer(
    overrides: [
      tabDatabaseProvider.overrideWithValue(db),
      geckoTabServiceProvider.overrideWithValue(engine),
      tabListProvider.overrideWith(() => _FakeTabList(liveTabIds)),
      tabStatesProvider.overrideWith(() => _FakeTabStates(liveTabIds)),
      selectedTabProvider.overrideWith(() => selectedTab),
      browserRestoreCompleteProvider.overrideWith(_RestoreComplete.new),
      selectedSpaceProvider.overrideWith(
        () => _FakeSelectedSpace(currentSelectedSpace),
      ),
      spaceLastTabProvider.overrideWith(() => spaceLastTab),
      tabViewFilterControllerProvider.overrideWith(
        _DefaultTabViewFilterController.new,
      ),
      generalSettingsWithDefaultsProvider.overrideWith(
        (ref) => GeneralSettings.withDefaults(),
      ),
      zenSettingsWithDefaultsProvider.overrideWith(
        (ref) => ZenSettings.withDefaults(),
      ),
    ],
  );
  final tabList = container.read(tabListProvider.notifier) as _FakeTabList;
  engine.onAdded = (id) => tabList.setTabs([...tabList.tabs, id]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return (
    container: container,
    db: db,
    engine: engine,
    tabList: tabList,
    selectedTab: selectedTab,
    spaceLastTab: spaceLastTab,
  );
}

Future<void> _seedSpaces(TabDatabase db) async {
  await db.spaceDao.insertSpace(SpaceData(uuid: _spaceA, orderIndex: 0));
  await db.spaceDao.insertSpace(SpaceData(uuid: _spaceB, orderIndex: 1));
}

void main() {
  group('TabRepository.restoreSpaceTab', () {
    test('selects the remembered live tab for the space', () async {
      final h = _openHarness(
        liveTabIds: ['a-1', 'a-2'],
        selectedTabId: 'other',
        currentSelectedSpace: _spaceA,
        lastTabEntries: {_spaceA: 'a-2'},
      );
      await _seedSpaces(h.db);
      await seedTab(h.db, 'a-1', spaceUuid: _spaceA);
      await seedTab(h.db, 'a-2', spaceUuid: _spaceA);

      await h.container
          .read(tabRepositoryProvider.notifier)
          .restoreSpaceTab(_spaceA);

      expect(h.engine.selectedTabIds, ['a-2']);
    });

    test('materialises a remembered tab that is cold', () async {
      final h = _openHarness(
        liveTabIds: const [],
        selectedTabId: 'other',
        currentSelectedSpace: _spaceA,
        lastTabEntries: {_spaceA: 'a-cold'},
      );
      await _seedSpaces(h.db);
      await seedTab(h.db, 'a-cold', spaceUuid: _spaceA);
      await h.db.tabDao.setEngineTabId('a-cold', null);

      await h.container
          .read(tabRepositoryProvider.notifier)
          .restoreSpaceTab(_spaceA);

      expect(h.engine.addedTabIds, ['a-cold']);
      expect((await summaryOf(h.db, 'a-cold')).engineTabId, 'a-cold');
    });

    test('a remembered tab that was closed falls back to the most recently '
        'used tab in the space', () async {
      final h = _openHarness(
        liveTabIds: ['a-1', 'a-2'],
        selectedTabId: 'other',
        currentSelectedSpace: _spaceA,
        lastTabEntries: {_spaceA: 'a-gone'},
      );
      await _seedSpaces(h.db);
      await h.db.transaction(() async {
        await seedTab(h.db, 'a-1', spaceUuid: _spaceA);
        await h.db.tabDao.touchTab('a-1', timestamp: DateTime(2024));
        await seedTab(h.db, 'a-2', spaceUuid: _spaceA);
        await h.db.tabDao.touchTab('a-2', timestamp: DateTime(2025));
      });

      await h.container
          .read(tabRepositoryProvider.notifier)
          .restoreSpaceTab(_spaceA);

      // 'a-gone' was never seeded, so its remembered id does not exist;
      // the most recently touched tab in the space is selected instead.
      expect(h.engine.selectedTabIds, ['a-2']);
    });

    test('a remembered tab moved to another space is not restored into the '
        'wrong one, and falls back within the target space instead', () async {
      final h = _openHarness(
        liveTabIds: ['a-1', 'b-1'],
        selectedTabId: 'other',
        currentSelectedSpace: _spaceA,
        // Recorded while 'moved' was still in space A; it has since been
        // moved to space B (e.g. by the desktop, through Zen sync).
        lastTabEntries: {_spaceA: 'moved'},
      );
      await _seedSpaces(h.db);
      await seedTab(h.db, 'a-1', spaceUuid: _spaceA);
      await seedTab(h.db, 'b-1', spaceUuid: _spaceB);
      await seedTab(h.db, 'moved', spaceUuid: _spaceB);

      await h.container
          .read(tabRepositoryProvider.notifier)
          .restoreSpaceTab(_spaceA);

      expect(h.engine.selectedTabIds, ['a-1']);
      expect(h.engine.selectedTabIds, isNot(contains('moved')));
    });

    test('a space whose last state was the home surface requests home instead '
        'of selecting a tab', () async {
      final h = _openHarness(
        liveTabIds: ['a-1'],
        selectedTabId: 'other',
        currentSelectedSpace: _spaceA,
        lastTabEntries: {_spaceA: null},
      );
      await _seedSpaces(h.db);
      await seedTab(h.db, 'a-1', spaceUuid: _spaceA);

      await h.container
          .read(tabRepositoryProvider.notifier)
          .restoreSpaceTab(_spaceA);

      expect(h.engine.selectedTabIds, isEmpty);
      expect(h.container.read(forceBrowserHomeProvider), isTrue);
    });

    test('does nothing when the currently selected tab already belongs to the '
        'space (the forward sync loop is a no-op here)', () async {
      final h = _openHarness(
        liveTabIds: ['a-1', 'a-2'],
        selectedTabId: 'a-1',
        currentSelectedSpace: _spaceA,
        lastTabEntries: {_spaceA: 'a-2'},
      );
      await _seedSpaces(h.db);
      await seedTab(h.db, 'a-1', spaceUuid: _spaceA);
      await seedTab(h.db, 'a-2', spaceUuid: _spaceA);

      await h.container
          .read(tabRepositoryProvider.notifier)
          .restoreSpaceTab(_spaceA);

      expect(h.engine.selectedTabIds, isEmpty);
    });

    test('leaves nothing selected for a space with no tabs at all', () async {
      final h = _openHarness(
        liveTabIds: const [],
        selectedTabId: 'other',
        currentSelectedSpace: _spaceA,
      );
      await _seedSpaces(h.db);

      await h.container
          .read(tabRepositoryProvider.notifier)
          .restoreSpaceTab(_spaceA);

      expect(h.engine.selectedTabIds, isEmpty);
      expect(h.engine.addedTabIds, isEmpty);
    });

    test('clears the restoring flag once the restore settles', () async {
      final h = _openHarness(
        liveTabIds: ['a-1'],
        selectedTabId: 'other',
        currentSelectedSpace: _spaceA,
        lastTabEntries: {_spaceA: 'a-1'},
      );
      await _seedSpaces(h.db);
      await seedTab(h.db, 'a-1', spaceUuid: _spaceA);

      await h.container
          .read(tabRepositoryProvider.notifier)
          .restoreSpaceTab(_spaceA);

      expect(h.container.read(restoringSpaceTabProvider), isFalse);
    });
  });
}
