import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/folder.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/tab.dart';

import '../data/database/tab_db_test_helpers.dart';
import 'repository_test_support.dart';

/// PLAN §6.4: the three shelves and what each transition does to a tab's
/// space and folder.
void main() {
  group('TabDataRepository.setShelf', () {
    test(
      '→ essential clears the space and folder, keeps the container',
      () async {
        final h = openRepositoryHarness();
        await seedSpaces(h.db, ['s1']);
        await seedContainer(h.db, 'c');
        final folder = await h.container
            .read(_folderRepo)
            .createFolder('s1', name: 'F');
        await seedTab(
          h.db,
          't',
          spaceUuid: 's1',
          folderId: folder.id,
          containerId: 'c',
        );

        final ok = await h.container
            .read(tabDataRepositoryProvider.notifier)
            .setShelf('t', TabShelf.essential, activeSpaceUuid: 's1');

        expect(ok, isTrue);
        final tab = await summaryOf(h.db, 't');
        expect(tab.tabShelf, TabShelf.essential);
        expect(tab.spaceUuid, isNull);
        expect(tab.folderId, isNull);
        expect(tab.containerId, 'c');
      },
    );

    test('essential → normal lands in the active space', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['s1', 's2']);
      await seedTab(h.db, 't', shelf: TabShelf.essential);

      await h.container
          .read(tabDataRepositoryProvider.notifier)
          .setShelf('t', TabShelf.normal, activeSpaceUuid: 's2');

      final tab = await summaryOf(h.db, 't');
      expect(tab.tabShelf, TabShelf.normal);
      expect(tab.spaceUuid, 's2');
      expect(tab.folderId, isNull);
    });

    test('essential → pinned lands in the active space, pinned', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['s1', 's2']);
      await seedTab(h.db, 't', shelf: TabShelf.essential);

      await h.container
          .read(tabDataRepositoryProvider.notifier)
          .setShelf('t', TabShelf.pinned, activeSpaceUuid: 's2');

      final tab = await summaryOf(h.db, 't');
      expect(tab.tabShelf, TabShelf.pinned);
      expect(tab.spaceUuid, 's2');
    });

    test(
      'essential → normal without an active space uses the default',
      () async {
        final h = openRepositoryHarness();
        await seedSpaces(h.db, ['s1', 's2']);
        await seedTab(h.db, 't', shelf: TabShelf.essential);

        await h.container
            .read(tabDataRepositoryProvider.notifier)
            .setShelf('t', TabShelf.normal, activeSpaceUuid: null);

        expect((await summaryOf(h.db, 't')).spaceUuid, 's1');
      },
    );

    test('normal ↔ pinned keeps the tab in its own space', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['s1', 's2']);
      await seedTab(h.db, 't', spaceUuid: 's1');
      final repo = h.container.read(tabDataRepositoryProvider.notifier);

      await repo.setShelf('t', TabShelf.pinned, activeSpaceUuid: 's2');
      var tab = await summaryOf(h.db, 't');
      expect(tab.tabShelf, TabShelf.pinned);
      expect(tab.spaceUuid, 's1');

      await repo.setShelf('t', TabShelf.normal, activeSpaceUuid: 's2');
      tab = await summaryOf(h.db, 't');
      expect(tab.tabShelf, TabShelf.normal);
      expect(tab.spaceUuid, 's1');
    });

    test('normal → pinned leaves the folder behind', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['s1']);
      final folder = await h.container
          .read(_folderRepo)
          .createFolder('s1', name: 'F');
      await seedTab(h.db, 't', spaceUuid: 's1', folderId: folder.id);

      await h.container
          .read(tabDataRepositoryProvider.notifier)
          .setShelf('t', TabShelf.pinned, activeSpaceUuid: 's1');

      final tab = await summaryOf(h.db, 't');
      expect(tab.folderId, isNull);
      expect(tab.spaceUuid, 's1');
    });

    test('a private tab stays on the normal shelf', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['s1']);
      await seedTab(h.db, 'p', tabMode: TabMode.private);

      final ok = await h.container
          .read(tabDataRepositoryProvider.notifier)
          .setShelf('p', TabShelf.pinned, activeSpaceUuid: 's1');

      expect(ok, isFalse);
      expect((await summaryOf(h.db, 'p')).tabShelf, TabShelf.normal);
    });

    test('an unknown tab is refused', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['s1']);
      expect(
        await h.container
            .read(tabDataRepositoryProvider.notifier)
            .setShelf('nope', TabShelf.pinned, activeSpaceUuid: 's1'),
        isFalse,
      );
    });
  });

  group('TabDataRepository folder and space moves', () {
    test(
      'moveTabToFolder takes the folder\'s space, refuses essentials',
      () async {
        final h = openRepositoryHarness();
        await seedSpaces(h.db, ['s1', 's2']);
        final folder = await h.container
            .read(_folderRepo)
            .createFolder('s2', name: 'F');
        await seedTab(h.db, 't', spaceUuid: 's1');
        await seedTab(h.db, 'e', shelf: TabShelf.essential);
        final repo = h.container.read(tabDataRepositoryProvider.notifier);

        expect(await repo.moveTabToFolder('t', folder.id), isTrue);
        var tab = await summaryOf(h.db, 't');
        expect(tab.folderId, folder.id);
        expect(tab.spaceUuid, 's2');

        expect(await repo.moveTabToFolder('t', null), isTrue);
        tab = await summaryOf(h.db, 't');
        expect(tab.folderId, isNull);
        expect(tab.spaceUuid, 's2');

        expect(await repo.moveTabToFolder('e', folder.id), isFalse);
      },
    );

    test('moveTabToSpace keeps the shelf, drops the folder', () async {
      final h = openRepositoryHarness();
      await seedSpaces(h.db, ['s1', 's2']);
      final folder = await h.container
          .read(_folderRepo)
          .createFolder('s1', name: 'F');
      await seedTab(h.db, 't', spaceUuid: 's1', folderId: folder.id);
      await seedTab(h.db, 'p', spaceUuid: 's1', shelf: TabShelf.pinned);
      final repo = h.container.read(tabDataRepositoryProvider.notifier);

      expect(await repo.moveTabToSpace('t', 's2'), isTrue);
      final tab = await summaryOf(h.db, 't');
      expect(tab.spaceUuid, 's2');
      expect(tab.folderId, isNull);

      expect(await repo.moveTabToSpace('p', 's2'), isTrue);
      final pinned = await summaryOf(h.db, 'p');
      expect(pinned.spaceUuid, 's2');
      expect(pinned.tabShelf, TabShelf.pinned);
    });
  });
}

final _folderRepo = folderRepositoryProvider.notifier;
