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
import 'package:mellow/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';

import '../../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';

/// The one space every harness tab is filed under.
const space = 'space-ledger';

/// The engine reduced to the calls the deletion ledger cares about. List
/// changes are mirrored into the fake tab list, as the native event would.
class FakeEngine extends GeckoTabService {
  final removedTabIds = <String>[];

  /// Ids the engine no longer knows: `removeTab` records the call and then
  /// fails, the way a stale session id does.
  final removeThrowsFor = <String>{};
  int undoCalls = 0;
  void Function(List<String> tabIds)? onRemoved;
  void Function()? onUndo;

  @override
  Future<void> removeTab({required String tabId}) async {
    removedTabIds.add(tabId);
    if (removeThrowsFor.contains(tabId)) {
      throw StateError('unknown tab $tabId');
    }
    onRemoved?.call([tabId]);
  }

  /// One list change for the whole batch, as the engine reports it.
  @override
  Future<void> removeTabs({required List<String> ids}) async {
    removedTabIds.addAll(ids);
    onRemoved?.call(ids);
  }

  @override
  Future<void> undo() async {
    undoCalls++;
    onUndo?.call();
  }
}

class FakeTabList extends TabList {
  FakeTabList(this._initial);

  final List<String> _initial;

  List<String> get tabs => state.value;

  @override
  EquatableValue<List<String>> build() => EquatableValue(List.of(_initial));

  void setTabs(List<String> ids) => state = EquatableValue(List.of(ids));
}

class FakeTabStates extends TabStates {
  FakeTabStates(this._ids);

  final List<String> _ids;

  @override
  Map<String, TabState> build() => {
    for (final id in _ids) id: TabState.$default(id),
  };
}

class FakeSelectedTab extends SelectedTab {
  FakeSelectedTab(this._id);

  final String? _id;

  @override
  String? build() => _id;
}

class Restored extends BrowserRestoreComplete {
  @override
  bool build() => true;
}

class FakeSelectedSpace extends SelectedSpace {
  @override
  String? build() => space;
}

class DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

typedef Harness = ({
  ProviderContainer container,
  TabDatabase db,
  FakeEngine engine,
  FakeTabList tabList,
});

Harness openHarness({required List<String> liveTabIds, String? selectedTabId}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = openTestTabDatabase();
  final engine = FakeEngine();
  final container = ProviderContainer(
    overrides: [
      tabDatabaseProvider.overrideWithValue(db),
      geckoTabServiceProvider.overrideWithValue(engine),
      tabListProvider.overrideWith(() => FakeTabList(liveTabIds)),
      tabStatesProvider.overrideWith(() => FakeTabStates(liveTabIds)),
      selectedTabProvider.overrideWith(() => FakeSelectedTab(selectedTabId)),
      browserRestoreCompleteProvider.overrideWith(Restored.new),
      selectedSpaceProvider.overrideWith(FakeSelectedSpace.new),
      tabViewFilterControllerProvider.overrideWith(
        DefaultTabViewFilterController.new,
      ),
      generalSettingsWithDefaultsProvider.overrideWith(
        (ref) => GeneralSettings.withDefaults(),
      ),
    ],
  );
  final tabList = container.read(tabListProvider.notifier) as FakeTabList;
  engine.onRemoved = (ids) =>
      tabList.setTabs([...tabList.tabs.where((tab) => !ids.contains(tab))]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return (container: container, db: db, engine: engine, tabList: tabList);
}

Future<Map<String, String>> ledger(TabDatabase db) =>
    db.syncStateDao.pendingDeletions();

/// The listener reconciles the rows with the engine list asynchronously;
/// waits until [id] has left the database, so nothing is still in flight when
/// the test tears the container down.
Future<void> waitForRowGone(TabDatabase db, String id) =>
    waitFor(() async => !(await db.tabDao.getAllTabIds().get()).contains(id));

Future<void> waitFor(
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
