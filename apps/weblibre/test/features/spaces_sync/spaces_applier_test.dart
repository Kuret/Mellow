import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/spaces_sync/data/models/zen_records.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_applier.dart';

import '../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';
import 'spaces_sync_test_support.dart';

void main() {
  test('essential:true, pinned:true decodes to the essential shelf', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1]);

    final failed = await harness.container
        .read(spacesApplierProvider)
        .applyBatch([
          record(tabRecord('e1', essential: true)),
          record(tabRecord('p1', pinned: true, workspaceUuid: space1)),
          record(tabRecord('n1', workspaceUuid: space1)),
        ], firstSync: false);
    expect(failed, isEmpty);

    final essential = await summaryOf(harness.db, 'e1');
    expect(essential.tabShelf, TabShelf.essential);
    expect(essential.spaceUuid, isNull);
    expect(essential.folderId, isNull);
    expect((await summaryOf(harness.db, 'p1')).tabShelf, TabShelf.pinned);
    expect((await summaryOf(harness.db, 'n1')).tabShelf, TabShelf.normal);
  });

  test('folder members are pinned tabs that keep their folder', () async {
    final harness = openApplierHarness();

    final failed = await harness.container
        .read(spacesApplierProvider)
        .applyBatch([
          record(
            ZenSpaceRecord(
              uuid: space1,
              name: 'S',
              icon: null,
              theme: null,
              containerGuid: null,
              children: ['t4', 't3', 'F'],
            ),
          ),
          record(
            ZenFolderRecord(
              folderId: 'F',
              name: 'F',
              icon: null,
              workspaceUuid: space1,
              parentFolderId: null,
              live: null,
              children: ['t1', 'G'],
            ),
          ),
          record(
            ZenFolderRecord(
              folderId: 'G',
              name: 'G',
              icon: null,
              workspaceUuid: space1,
              parentFolderId: 'F',
              live: null,
              children: ['t2'],
            ),
          ),
          // Zen projects folder members with `pinned: true` (folders live in
          // the pinned section).
          record(
            tabRecord('t1', pinned: true, workspaceUuid: space1, folderId: 'F'),
          ),
          record(
            tabRecord('t2', pinned: true, workspaceUuid: space1, folderId: 'G'),
          ),
          record(tabRecord('t3', workspaceUuid: space1)),
          record(tabRecord('t4', pinned: true, workspaceUuid: space1)),
        ], firstSync: true);
    expect(failed, isEmpty);

    final t1 = await summaryOf(harness.db, 't1');
    expect(t1.folderId, 'F');
    expect(t1.tabShelf, TabShelf.pinned);
    final t2 = await summaryOf(harness.db, 't2');
    expect(t2.folderId, 'G');
    expect(t2.tabShelf, TabShelf.pinned);
    final t3 = await summaryOf(harness.db, 't3');
    expect(t3.folderId, isNull);
    expect(t3.tabShelf, TabShelf.normal);
    final t4 = await summaryOf(harness.db, 't4');
    expect(t4.folderId, isNull);
    expect(t4.tabShelf, TabShelf.pinned);

    // The flat pinned section holds only root pinned tabs.
    expect(await idsInScope(harness.db, TabOrderScope.pinned(space1)), ['t4']);
    expect(
      await idsInScope(
        harness.db,
        TabOrderScope.folder(spaceUuid: space1, folderId: 'F'),
      ),
      ['t1'],
    );
    expect(
      await idsInScope(
        harness.db,
        TabOrderScope.folder(spaceUuid: space1, folderId: 'G'),
      ),
      ['t2'],
    );
  });

  test('a folder member whose folder has not landed is retried', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1]);

    final failed = await harness.container
        .read(spacesApplierProvider)
        .applyBatch([
          record(
            tabRecord(
              'orphan',
              pinned: true,
              workspaceUuid: space1,
              folderId: 'missing',
            ),
          ),
        ], firstSync: false);

    expect(failed, {'orphan'});
    expect(await tabIds(harness.db), isNot(contains('orphan')));
    expect(await harness.db.syncStateDao.getDigest('orphan'), isNull);
  });

  test('an unpinned folder member is pinned, as Zen would', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1]);

    final failed = await harness.container
        .read(spacesApplierProvider)
        .applyBatch([
          record(
            ZenFolderRecord(
              folderId: 'F',
              name: 'F',
              icon: null,
              workspaceUuid: space1,
              parentFolderId: null,
              live: null,
              children: const [],
            ),
          ),
          record(tabRecord('m', workspaceUuid: space1, folderId: 'F')),
        ], firstSync: false);
    expect(failed, isEmpty);

    final member = await summaryOf(harness.db, 'm');
    expect(member.folderId, 'F');
    expect(member.tabShelf, TabShelf.pinned);
  });

  test('an unknown container guid fails only that record', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1]);

    final failed = await harness.container
        .read(spacesApplierProvider)
        .applyBatch([
          record(
            tabRecord('bad', workspaceUuid: space1, containerGuid: 'nope-guid'),
          ),
          record(tabRecord('good', workspaceUuid: space1)),
          record(
            tabRecord(
              'builtin',
              workspaceUuid: space1,
              containerGuid: 'builtin-3',
            ),
          ),
        ], firstSync: false);

    expect(failed, {'bad'});
    expect(await tabIds(harness.db), containsAll(['good', 'builtin']));
    expect(await tabIds(harness.db), isNot(contains('bad')));
    final builtin = await harness.db.containerDao
        .getBySyncGuid('builtin-3')
        .getSingleOrNull();
    expect(builtin?.name, 'Banking');
    expect((await summaryOf(harness.db, 'builtin')).containerId, builtin!.id);
    // Not acknowledged: it is retried next sync.
    expect(await harness.db.syncStateDao.getDigest('bad'), isNull);
    expect(await harness.db.syncStateDao.getDigest('good'), isNotNull);
  });

  test('an incoming new tab is a cold row', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1]);

    await harness.container.read(spacesApplierProvider).applyBatch([
      record(tabRecord('cold', title: 'Cold', workspaceUuid: space1)),
    ], firstSync: false);

    final tab = await summaryOf(harness.db, 'cold');
    expect(tab.engineTabId, isNull);
    expect(tab.isCold, isTrue);
    expect(tab.url.toString(), 'https://cold.example/page');
    expect(tab.title, 'Cold');
  });

  test(
    'a live normal tab keeps its live url; pinned and cold retarget',
    () async {
      final harness = openApplierHarness();
      await seedSpaces(harness.db, [space1]);
      await seedTab(harness.db, 'live', spaceUuid: space1);
      await seedTab(
        harness.db,
        'pinned',
        spaceUuid: space1,
        shelf: TabShelf.pinned,
      );
      await harness.container.read(spacesApplierProvider).applyBatch([
        record(
          tabRecord('cold', url: 'https://old.example/', workspaceUuid: space1),
        ),
      ], firstSync: false);

      await harness.container.read(spacesApplierProvider).applyBatch([
        record(
          tabRecord(
            'live',
            url: 'https://remote.example/',
            title: 'R',
            workspaceUuid: space1,
          ),
        ),
        record(
          tabRecord(
            'pinned',
            url: 'https://remote.example/',
            pinned: true,
            workspaceUuid: space1,
          ),
        ),
        record(
          tabRecord('cold', url: 'https://new.example/', workspaceUuid: space1),
        ),
      ], firstSync: false);

      expect(
        (await summaryOf(harness.db, 'live')).url.toString(),
        'https://live.example/',
      );
      expect(
        (await summaryOf(harness.db, 'pinned')).url.toString(),
        'https://remote.example/',
      );
      expect(
        (await summaryOf(harness.db, 'cold')).url.toString(),
        'https://new.example/',
      );
    },
  );

  test(
    'a tab tombstone closes the row without a closed_tab_tombstone',
    () async {
      final harness = openApplierHarness();
      await seedSpaces(harness.db, [space1]);
      await seedTab(harness.db, 'gone', spaceUuid: space1);
      await harness.db.syncStateDao.putDigest('gone', 'tab', 'digest');

      final failed = await harness.container
          .read(spacesApplierProvider)
          .applyBatch([ZenIncomingTombstone('gone')], firstSync: false);

      expect(failed, isEmpty);
      expect(await tabIds(harness.db), isNot(contains('gone')));
      expect(harness.tabs.drainedEngineCloses, ['gone']);
      expect(await harness.db.tabDao.allClosedTabTombstoneIds().get(), isEmpty);
      expect(await harness.db.syncStateDao.getDigest('gone'), isNull);
    },
  );

  test('children arrays re-key the scope order', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1]);
    await seedTab(harness.db, 'a', spaceUuid: space1);
    await seedTab(harness.db, 'b', spaceUuid: space1);
    await seedTab(harness.db, 'c', spaceUuid: space1);
    await seedTab(harness.db, 'unlisted', spaceUuid: space1);

    await harness.container.read(spacesApplierProvider).applyBatch([
      record(
        ZenSpaceRecord(
          uuid: space1,
          name: 'S',
          icon: null,
          theme: null,
          containerGuid: null,
          children: ['c', 'a', 'b'],
        ),
      ),
    ], firstSync: false);

    final slots = await harness.db.tabDao.scopeChildSlots(space1, null);
    expect([for (final slot in slots) slot.id], ['c', 'a', 'b', 'unlisted']);
    expect(
      await idsInScope(harness.db, TabOrderScope.normal(spaceUuid: space1)),
      ['c', 'a', 'b', 'unlisted'],
    );
  });

  test('a folder children array orders its pinned members', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1]);
    await harness.db.tabFolderDao.insertFolder(
      TabFolderData(id: 'F', name: 'F', spaceUuid: space1, orderKey: 'f'),
    );
    for (final id in ['a', 'b', 'c']) {
      await seedTab(
        harness.db,
        id,
        spaceUuid: space1,
        folderId: 'F',
        shelf: TabShelf.pinned,
      );
    }

    final failed = await harness.container
        .read(spacesApplierProvider)
        .applyBatch([
          record(
            ZenFolderRecord(
              folderId: 'F',
              name: 'F',
              icon: null,
              workspaceUuid: space1,
              parentFolderId: null,
              live: null,
              children: ['c', 'a'],
            ),
          ),
        ], firstSync: false);
    expect(failed, isEmpty);

    expect(
      await idsInScope(
        harness.db,
        TabOrderScope.folder(spaceUuid: space1, folderId: 'F'),
      ),
      ['c', 'a', 'b'],
    );
  });

  test('the layout orders essentials and spaces', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1, space2]);
    await seedTab(harness.db, 'e1', shelf: TabShelf.essential);
    await seedTab(harness.db, 'e2', shelf: TabShelf.essential);
    await seedTab(harness.db, 'e3', shelf: TabShelf.essential);

    await harness.container.read(spacesApplierProvider).applyBatch([
      record(
        ZenLayoutRecord(
          spaces: [space2, space1],
          essentials: {
            'default': ['e3', 'e1', 'e2'],
          },
        ),
      ),
    ], firstSync: false);

    final spaces = await harness.db.spaceDao.getAll();
    expect([for (final space in spaces) space.uuid], [space2, space1]);
    expect(await harness.db.tabDao.essentialTabIds(null).get(), [
      'e3',
      'e1',
      'e2',
    ]);
  });

  test('the last space is never deleted', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1]);
    await seedTab(harness.db, 'keep', spaceUuid: space1);
    await harness.db.syncStateDao.putDigest(space1, 'space', 'digest');

    final failed = await harness.container
        .read(spacesApplierProvider)
        .applyBatch([ZenIncomingTombstone(space1)], firstSync: false);

    expect(failed, isEmpty);
    expect(
      await harness.db.spaceDao.getByUuid(space1).getSingleOrNull(),
      isNotNull,
    );
    expect(await tabIds(harness.db), ['keep']);
    // Acknowledged anyway: the local copy revives it remotely on the next
    // diff.
    expect(await harness.db.syncStateDao.getDigest(space1), isNull);
  });

  test('a space tombstone closes its tabs and drops the space', () async {
    final harness = openApplierHarness();
    await seedSpaces(harness.db, [space1, space2]);
    await seedTab(harness.db, 'in2', spaceUuid: space2);
    await seedTab(harness.db, 'in1', spaceUuid: space1);

    await harness.container.read(spacesApplierProvider).applyBatch([
      ZenIncomingTombstone(space2),
    ], firstSync: false);

    expect(
      await harness.db.spaceDao.getByUuid(space2).getSingleOrNull(),
      isNull,
    );
    expect(await tabIds(harness.db), ['in1']);
    expect(harness.tabs.drainedEngineCloses, ['in2']);
    expect(await harness.db.tabDao.allClosedTabTombstoneIds().get(), isEmpty);
    // The applier's own delete is not a user deletion to echo back.
    expect(await harness.db.syncStateDao.pendingDeletions(), isEmpty);
  });

  test('unknown kinds are kept verbatim as foreign records', () async {
    final harness = openApplierHarness();
    final unknown = ZenIncomingUnknownKind(
      id: 'x9',
      kind: 'widget',
      rawData: {'a': 1},
    );

    await harness.container.read(spacesApplierProvider).applyBatch([
      unknown,
    ], firstSync: false);

    final foreign = await harness.db.syncStateDao.allForeign();
    expect(foreign.single.id, 'x9');
    expect(foreign.single.kind, 'widget');
    expect(
      await harness.db.syncStateDao.getDigest('x9'),
      recordDigest('widget', {'a': 1}),
    );
  });
}
