import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/space.dart';

import '../data/database/tab_db_test_helpers.dart';
import 'repository_test_support.dart';

void main() {
  group('SpaceRepository', () {
    test('createSpace appends with the next orderIndex', () async {
      final h = openRepositoryHarness();
      final repo = h.container.read(spaceRepositoryProvider.notifier);

      final first = await repo.createSpace(name: 'One');
      final second = await repo.createSpace(name: 'Two', containerId: null);

      expect(first.orderIndex, 0);
      expect(second.orderIndex, 1);
      expect(first.uuid, startsWith('{'));
      expect((await repo.getAllSpaces()).map((s) => s.name), ['One', 'Two']);
    });

    test('deleteSpace refuses the last space', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['only']);

      await expectLater(
        h.container.read(spaceRepositoryProvider.notifier).deleteSpace('only'),
        throwsStateError,
      );
      expect(await h.db.spaceDao.count(), 1);
    });

    test('deleteSpace closes the tabs through TabRepository first', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['keep', 'gone']);
      await seedTab(h.db, 'a', spaceUuid: 'gone');
      await seedTab(h.db, 'b', spaceUuid: 'gone', parentId: 'a');
      await seedTab(h.db, 'k', spaceUuid: 'keep');
      h.tabs.watchedSpaces.add('gone');

      await h.container
          .read(spaceRepositoryProvider.notifier)
          .deleteSpace('gone');

      expect(h.tabs.closedTabIds, unorderedEquals(['a', 'b']));
      // The row was still there when the tabs were closed (PLAN §7.3).
      expect(h.tabs.spaceExistedAtClose['gone'], isTrue);
      expect(await h.db.spaceDao.getByUuid('gone').getSingleOrNull(), isNull);
      expect(await tabIds(h.db), ['k']);
    });

    test(
      'countTabsInSpace counts pinned and folder tabs, not essentials',
      () async {
        final h = openRepositoryHarness();
        await seedSpaces(h.db, ['s']);
        await seedTab(h.db, 'n', spaceUuid: 's');
        await seedTab(h.db, 'p', spaceUuid: 's', shelf: TabShelf.pinned);
        await seedTab(h.db, 'e', shelf: TabShelf.essential);

        expect(
          await h.container
              .read(spaceRepositoryProvider.notifier)
              .countTabsInSpace('s'),
          2,
        );
      },
    );

    test('ensureDefaultSpace creates one and adopts orphans', () async {
      final h = openRepositoryHarness();
      await seedTab(h.db, 'orphan');

      final space = await h.container
          .read(spaceRepositoryProvider.notifier)
          .ensureDefaultSpace();

      expect(await h.db.spaceDao.count(), 1);
      expect((await summaryOf(h.db, 'orphan')).spaceUuid, space.uuid);
    });

    test('rename, icon, container and reorder', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['a', 'b']);
      await seedContainer(h.db, 'c');
      final repo = h.container.read(spaceRepositoryProvider.notifier);

      await repo.renameSpace('a', 'Work');
      await repo.setSpaceIcon('a', '💼');
      await repo.setSpaceContainer('a', 'c');
      await repo.reorderSpaces(['b', 'a']);

      final a = (await repo.getSpace('a'))!;
      expect(a.name, 'Work');
      expect(a.icon, '💼');
      expect(a.containerId, 'c');
      expect((await repo.getAllSpaces()).map((s) => s.uuid), ['b', 'a']);
    });
  });
}
