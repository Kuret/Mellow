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

import '../../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';
import 'tab_repository_harness.dart';

void main() {
  test('a remote deletion queues the session instead of closing it', () async {
    final h = openHarness(liveTabIds: ['a', 'b']);
    await seedSpaces(h.db, [space]);
    await seedTab(h.db, 'a', spaceUuid: space);
    await seedTab(h.db, 'b', spaceUuid: space);

    // What the applier does inside its transaction: the row goes, the engine
    // is not touched, and no undo-buffer entry is written.
    await h.db.tabDao.deleteTabsFromSync(['a']);

    expect(await h.db.tabDao.getAllTabIds().get(), ['b']);
    expect(await h.db.tabDao.pendingEngineCloseIds(), ['a']);
    expect(await h.db.tabDao.allClosedTabTombstoneIds().get(), isEmpty);
    expect(await ledger(h.db), isEmpty);
    expect(h.engine.removedTabIds, isEmpty);
  });

  test('a cold row queues nothing: there is no session to close', () async {
    final h = openHarness(liveTabIds: const []);
    await seedSpaces(h.db, [space]);
    await seedTab(h.db, 'cold', spaceUuid: space);
    await h.db.tabDao.setEngineTabId('cold', null);

    await h.db.tabDao.deleteTabsFromSync(['cold']);

    expect(await h.db.tabDao.pendingEngineCloseIds(), isEmpty);
  });

  test(
    'the drain closes each queued session once and empties the queue',
    () async {
      final h = openHarness(liveTabIds: ['a', 'b']);
      await seedSpaces(h.db, [space]);
      await seedTab(h.db, 'a', spaceUuid: space);
      await seedTab(h.db, 'b', spaceUuid: space);
      await h.db.tabDao.deleteTabsFromSync(['a']);

      final repo = h.container.read(tabRepositoryProvider.notifier);
      await repo.drainPendingEngineCloses();

      expect(h.engine.removedTabIds, ['a']);
      expect(await h.db.tabDao.pendingEngineCloseIds(), isEmpty);

      // A second drain — the one that runs at the next startup — is a no-op.
      await repo.drainPendingEngineCloses();
      expect(h.engine.removedTabIds, ['a']);
      expect(await h.db.tabDao.pendingEngineCloseIds(), isEmpty);
    },
  );

  test('an id the engine has forgotten still leaves the queue', () async {
    final h = openHarness(liveTabIds: const []);
    await seedSpaces(h.db, [space]);
    await seedTab(h.db, 'a', spaceUuid: space);
    await h.db.tabDao.deleteTabsFromSync(['a']);
    h.engine.removeThrowsFor.add('a');

    await h.container
        .read(tabRepositoryProvider.notifier)
        .drainPendingEngineCloses();

    expect(h.engine.removedTabIds, ['a']);
    expect(await h.db.tabDao.pendingEngineCloseIds(), isEmpty);
  });

  test('a queued id is not re-inserted as a new tab', () async {
    final h = openHarness(liveTabIds: ['a', 'b']);
    await seedSpaces(h.db, [space]);
    await seedTab(h.db, 'a', spaceUuid: space);
    await seedTab(h.db, 'b', spaceUuid: space);
    await h.db.tabDao.deleteTabsFromSync(['a']);

    // The repository reconciles against a list that still carries the session
    // whose row the batch deleted, alongside a genuinely new one.
    h.container.read(tabRepositoryProvider.notifier);
    h.tabList.setTabs(['a', 'b', 'c']);

    // 'c' landing proves the reconcile ran; 'a' must not have come with it.
    await waitFor(
      () async => (await h.db.tabDao.getAllTabIds().get()).contains('c'),
    );
    expect(await h.db.tabDao.getAllTabIds().get(), isNot(contains('a')));
  });
}
