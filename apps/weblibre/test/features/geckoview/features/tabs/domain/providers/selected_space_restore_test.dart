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
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/experimental/persist.dart';
import 'package:riverpod/riverpod.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/space_last_tab.dart';
import 'package:weblibre/features/user/data/providers.dart';

import '../../data/database/tab_db_test_helpers.dart';

const _spaceA = 'space-a';
const _spaceB = 'space-b';

/// [SelectedTab] a test can move around with [select], the way a native
/// selected-tab event would (or, in production, [TabRepository.selectTab]
/// materialising and the engine confirming it).
class _MutableSelectedTab extends SelectedTab {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties
  void select(String? id) => state = id;
}

/// [TabRepository] with the engine and cold-tab machinery removed: records
/// which space [SelectedSpace] asked it to restore, so the restore *trigger*
/// can be tested here independently of restore *mechanics*, which
/// `restore_space_tab_test.dart` covers directly against the real
/// implementation.
class _SpyTabRepository extends TabRepository {
  final restoredSpaces = <String>[];

  @override
  void build() {}

  @override
  Future<void> restoreSpaceTab(String spaceUuid) async {
    restoredSpaces.add(spaceUuid);
  }
}

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late TabDatabase db;
  late ProviderContainer container;
  late _SpyTabRepository tabs;
  late _MutableSelectedTab selectedTab;

  setUp(() async {
    db = openTestTabDatabase();
    await db.spaceDao.insertSpace(SpaceData(uuid: _spaceA, orderIndex: 0));
    await db.spaceDao.insertSpace(SpaceData(uuid: _spaceB, orderIndex: 1));
    await seedTab(db, 'a-1', spaceUuid: _spaceA);
    await seedTab(db, 'b-1', spaceUuid: _spaceB);

    tabs = _SpyTabRepository();
    selectedTab = _MutableSelectedTab();
    container = ProviderContainer(
      overrides: [
        tabDatabaseProvider.overrideWithValue(db),
        riverpodDatabaseStorageProvider.overrideWithValue(
          Storage<String, String>.inMemory(),
        ),
        selectedTabProvider.overrideWith(() => selectedTab),
        tabRepositoryProvider.overrideWith(() => tabs),
      ],
    );
    // Loads the space list and settles the initial space (spaces.first).
    container.listen(selectedSpaceProvider, (_, _) {});
    await _pump();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test("selecting a tab records it as its space's last tab", () async {
    selectedTab.select('a-1');
    await _pump();

    final entry = await container
        .read(spaceLastTabProvider.notifier)
        .entryFor(_spaceA);
    expect(entry, isA<SpaceLastTabTab>());
    expect((entry! as SpaceLastTabTab).tabId, 'a-1');
  });

  test(
    'switching back to a space asks TabRepository to restore what it '
    'remembers, once the selected tab no longer belongs to it',
    () async {
      selectedTab.select('a-1');
      await _pump();
      selectedTab.select('b-1');
      await _pump();
      // Selecting 'b-1' followed the selected space to space B; both spaces
      // now have a remembered tab.
      expect(container.read(selectedSpaceProvider), _spaceB);

      tabs.restoredSpaces.clear();
      container.read(selectedSpaceProvider.notifier).space = _spaceA;
      await _pump();

      expect(tabs.restoredSpaces, [_spaceA]);
    },
  );

  test(
    'switching space does not ask for a restore when the selected tab '
    'already belongs to it (the forward sync is not a switch)',
    () async {
      selectedTab.select('a-1');
      await _pump();
      tabs.restoredSpaces.clear();

      // Re-affirming the same space explicitly — nothing changed.
      container.read(selectedSpaceProvider.notifier).space = _spaceA;
      await _pump();

      expect(tabs.restoredSpaces, isEmpty);
    },
  );

  test(
    'forcing the home surface records the selected space as last on home',
    () async {
      selectedTab.select('a-1');
      await _pump();

      container.read(forceBrowserHomeProvider.notifier).request();
      await _pump();

      final entry = await container
          .read(spaceLastTabProvider.notifier)
          .entryFor(_spaceA);
      expect(entry, isA<SpaceLastTabHome>());
    },
  );

  test("a deleted space's remembered tab is pruned", () async {
    selectedTab.select('b-1');
    await _pump();
    expect(
      await container.read(spaceLastTabProvider.notifier).entryFor(_spaceB),
      isNotNull,
    );

    await db.spaceDao.deleteSpace(_spaceB);
    await _pump();

    expect(
      await container.read(spaceLastTabProvider.notifier).entryFor(_spaceB),
      isNull,
    );
  });
}
