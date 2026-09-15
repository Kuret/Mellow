import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/folder.dart';

import '../data/database/tab_db_test_helpers.dart';
import 'repository_test_support.dart';

void main() {
  group('FolderRepository', () {
    test('countTabsInFolder is recursive', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['s']);
      final repo = h.container.read(folderRepositoryProvider.notifier);
      final outer = await repo.createFolder('s', name: 'Outer');
      final inner = await repo.createFolder(
        's',
        parentFolderId: outer.id,
        name: 'Inner',
      );
      await seedTab(h.db, 'o1', spaceUuid: 's', folderId: outer.id);
      await seedTab(h.db, 'i1', spaceUuid: 's', folderId: inner.id);
      await seedTab(h.db, 'i2', spaceUuid: 's', folderId: inner.id);
      await seedTab(h.db, 'root', spaceUuid: 's');

      expect(await repo.countTabsInFolder(outer.id), 3);
      expect(await repo.countTabsInFolder(inner.id), 2);
    });

    test(
      "deleteFolder closes the subtree's tabs first, then cascades",
      () async {
        final h = openRepositoryHarness();
        await seedSpaces(h.db, ['s']);
        final repo = h.container.read(folderRepositoryProvider.notifier);
        final outer = await repo.createFolder('s', name: 'Outer');
        final inner = await repo.createFolder(
          's',
          parentFolderId: outer.id,
          name: 'Inner',
        );
        await seedTab(h.db, 'o1', spaceUuid: 's', folderId: outer.id);
        await seedTab(h.db, 'i1', spaceUuid: 's', folderId: inner.id);
        await seedTab(h.db, 'root', spaceUuid: 's');
        h.tabs.watchedFolders.add(outer.id);

        await repo.deleteFolder(outer.id);

        expect(h.tabs.closedTabIds, unorderedEquals(['o1', 'i1']));
        expect(h.tabs.folderExistedAtClose[outer.id], isTrue);
        expect(await repo.getFolder(outer.id), isNull);
        expect(await repo.getFolder(inner.id), isNull);
        expect(await tabIds(h.db), ['root']);
      },
    );

    test(
      "createFolder ranks after the pinned section's slots; rename and collapse",
      () async {
        final h = openRepositoryHarness();
        await seedSpaces(h.db, ['s']);
        // Folders live in the pinned section: a new one lands after the
        // space's pinned tabs, wherever the normal tabs are keyed.
        await seedTab(h.db, 'p', spaceUuid: 's', shelf: TabShelf.pinned);
        await seedTab(h.db, 't', spaceUuid: 's');
        final repo = h.container.read(folderRepositoryProvider.notifier);

        final folder = await repo.createFolder('s');
        expect(folder.name, 'Folder');
        expect(folder.spaceUuid, 's');
        expect(
          folder.orderKey.compareTo((await summaryOf(h.db, 'p')).orderKey),
          greaterThan(0),
        );

        await repo.renameFolder(folder.id, 'Research');
        await repo.setCollapsed(folder.id, true);
        final updated = (await repo.getFolder(folder.id))!;
        expect(updated.name, 'Research');
        expect(updated.isCollapsed, isTrue);
      },
    );

    test('moveFolder refuses its own subtree and carries tabs along', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['s1', 's2']);
      final repo = h.container.read(folderRepositoryProvider.notifier);
      final outer = await repo.createFolder('s1', name: 'Outer');
      final inner = await repo.createFolder(
        's1',
        parentFolderId: outer.id,
        name: 'Inner',
      );
      await seedTab(h.db, 'i1', spaceUuid: 's1', folderId: inner.id);

      expect(
        await repo.moveFolder(
          outer.id,
          spaceUuid: 's1',
          parentFolderId: inner.id,
        ),
        isFalse,
      );

      expect(await repo.moveFolder(outer.id, spaceUuid: 's2'), isTrue);
      expect((await repo.getFolder(inner.id))!.spaceUuid, 's2');
      expect((await summaryOf(h.db, 'i1')).spaceUuid, 's2');
    });
  });
}
