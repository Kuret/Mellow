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
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';

import '../../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';
import 'tab_repository_harness.dart';

void main() {
  test('a user close is recorded in the deletion ledger', () async {
    final h = openHarness(liveTabIds: ['a', 'b']);
    await seedSpaces(h.db, [space]);
    await seedTab(h.db, 'a', spaceUuid: space);
    await seedTab(h.db, 'b', spaceUuid: space);

    await h.container.read(tabRepositoryProvider.notifier).closeTab('a');
    await waitForRowGone(h.db, 'a');

    expect(await ledger(h.db), {'a': 'tab'});
    // The undo buffer is still written; it is simply no longer the signal.
    expect(await h.db.tabDao.allClosedTabTombstoneIds().get(), ['a']);
  });

  test('a bulk close records every id', () async {
    final h = openHarness(liveTabIds: ['a', 'b', 'c']);
    await seedSpaces(h.db, [space]);
    for (final id in ['a', 'b', 'c']) {
      await seedTab(h.db, id, spaceUuid: space);
    }

    await h.container.read(tabRepositoryProvider.notifier).closeTabs([
      'a',
      'c',
    ]);
    await waitForRowGone(h.db, 'a');
    await waitForRowGone(h.db, 'c');

    expect(await ledger(h.db), {'a': 'tab', 'c': 'tab'});
  });

  test('a cold tab close is recorded too', () async {
    final h = openHarness(liveTabIds: const []);
    await seedSpaces(h.db, [space]);
    await seedTab(h.db, 'cold', spaceUuid: space);
    await h.db.tabDao.setEngineTabId('cold', null);

    await h.container.read(tabRepositoryProvider.notifier).closeTab('cold');

    expect(await ledger(h.db), {'cold': 'tab'});
    expect(await h.db.tabDao.getAllTabIds().get(), isEmpty);
    expect(h.engine.removedTabIds, isEmpty);
  });

  test('a private tab close never reaches the ledger', () async {
    final h = openHarness(liveTabIds: ['secret']);
    await seedTab(h.db, 'secret', tabMode: TabMode.private);

    await h.container.read(tabRepositoryProvider.notifier).closeTab('secret');
    await waitForRowGone(h.db, 'secret');

    expect(await ledger(h.db), isEmpty);
  });

  test('a remote deletion is not a user deletion', () async {
    final h = openHarness(liveTabIds: ['a']);
    await seedSpaces(h.db, [space]);
    await seedTab(h.db, 'a', spaceUuid: space);

    await h.container.read(tabRepositoryProvider.notifier).closeTabsFromSync([
      'a',
    ]);
    await waitForRowGone(h.db, 'a');

    expect(await ledger(h.db), isEmpty);
    expect(await h.db.tabDao.allClosedTabTombstoneIds().get(), isEmpty);
  });

  test('unloading a tab is not a deletion', () async {
    final h = openHarness(liveTabIds: ['a', 'b'], selectedTabId: 'b');
    await seedSpaces(h.db, [space]);
    await seedTab(h.db, 'a', spaceUuid: space);
    await seedTab(h.db, 'b', spaceUuid: space);

    final demoted = await h.container
        .read(tabRepositoryProvider.notifier)
        .demoteToCold('a');

    expect(demoted, isTrue);
    expect(await ledger(h.db), isEmpty);
    expect(await h.db.tabDao.allClosedTabTombstoneIds().get(), isEmpty);
  });

  test('undoing a close takes the id back out of the ledger', () async {
    final h = openHarness(liveTabIds: ['a', 'b']);
    await seedSpaces(h.db, [space]);
    await seedTab(h.db, 'a', spaceUuid: space);
    await seedTab(h.db, 'b', spaceUuid: space);
    final repo = h.container.read(tabRepositoryProvider.notifier);

    await repo.closeTab('a');
    await waitForRowGone(h.db, 'a');
    expect(await ledger(h.db), {'a': 'tab'});

    // Undo puts the session back; the tab-list emission that follows is what
    // clears the bookkeeping of the close.
    h.engine.onUndo = () => h.tabList.setTabs([...h.tabList.tabs, 'a']);
    await repo.undoClose();

    await waitFor(() async => (await ledger(h.db)).isEmpty);
    expect(await h.db.tabDao.allClosedTabTombstoneIds().get(), isEmpty);
  });
}
