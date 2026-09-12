import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexo_rank/lexo_rank.dart';
import 'package:weblibre/data/database/functions/lexo_rank_functions.dart';
import 'package:weblibre/data/database/functions/url_functions.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';

void main() {
  late TabDatabase db;

  setUp(() {
    db = TabDatabase(
      NativeDatabase.memory(
        setup: (database) {
          registerLexorankFunctions(database);
          registerUrlFunctions(database);
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('setTabParent appends after the existing last child subtree', () async {
    await _insertTabs(db, const [
      _TabFixture('parent'),
      _TabFixture('existing-child', parentId: 'parent'),
      _TabFixture('existing-grandchild', parentId: 'existing-child'),
      _TabFixture('moving'),
      _TabFixture('moving-child', parentId: 'moving'),
    ]);

    final moved = await db.tabDao.setTabParent(
      tabId: 'moving',
      newParentId: 'parent',
    );

    expect(moved, isTrue);
    expect(await _orderedTabIds(db), [
      'parent',
      'existing-child',
      'existing-grandchild',
      'moving',
      'moving-child',
    ]);
  });

  test('setTabParent leaves cross-space descendants in place', () async {
    await _insertSpaces(db, const ['home', 'work']);
    await _insertTabs(db, const [
      _TabFixture('parent', spaceUuid: 'home'),
      _TabFixture('moving', spaceUuid: 'home'),
      _TabFixture('moving-child', parentId: 'moving', spaceUuid: 'home'),
      _TabFixture('foreign-child', spaceUuid: 'work'),
      _TabFixture('work-root', spaceUuid: 'work'),
    ]);
    // insertTab/reorderTabs both enforce F1 (a child always adopts its
    // parent's space), so only a direct write can put 'foreign-child' under
    // 'moving' while it stays in another space.
    await db.customStatement(
      "UPDATE tab SET parent_id = 'moving' WHERE id = 'foreign-child'",
    );
    final foreignOrderKey = await _orderKeyOf(db, 'foreign-child');

    final moved = await db.tabDao.setTabParent(
      tabId: 'moving',
      newParentId: 'parent',
    );

    expect(moved, isTrue);
    expect(await _orderedTabIdsInSpace(db, 'home'), [
      'parent',
      'moving',
      'moving-child',
    ]);
    final foreignChild = await db.tabDao
        .getTabDataById('foreign-child')
        .getSingleOrNull();
    expect(foreignChild, isNotNull);
    expect(foreignChild!.parentId, 'moving');
    expect(foreignChild.spaceUuid, 'work');
    expect(foreignChild.orderKey, foreignOrderKey);
  });

  test('setTabParent detects cycles through another container', () async {
    await _insertContainers(db, const [
      _ContainerFixture('home'),
      _ContainerFixture('work'),
    ]);
    await _insertTabs(db, const [
      _TabFixture('moving', containerId: 'home'),
      _TabFixture('foreign-child', parentId: 'moving', containerId: 'work'),
    ]);

    final moved = await db.tabDao.setTabParent(
      tabId: 'moving',
      newParentId: 'foreign-child',
    );

    expect(moved, isFalse);
    final moving = await db.tabDao.getTabDataById('moving').getSingleOrNull();
    expect(moving, isNotNull);
    expect(moving!.parentId, isNull);
    expect(moving.containerId, 'home');
  });

  test(
    'promoteChildToParent demotes after the promoted child subtree',
    () async {
      await _insertTabs(db, const [
        _TabFixture('parent'),
        _TabFixture('child', parentId: 'parent'),
        _TabFixture('grandchild', parentId: 'child'),
        _TabFixture('great-grandchild', parentId: 'grandchild'),
      ]);

      final promoted = await db.tabDao.promoteChildToParent('child');

      expect(promoted, isTrue);
      expect(await _orderedTabIds(db), [
        'child',
        'grandchild',
        'great-grandchild',
        'parent',
      ]);
    },
  );

  test(
    'moveTabAmongSiblings moves down after the target sibling subtree',
    () async {
      await _insertTabs(db, const [
        _TabFixture('parent'),
        _TabFixture('first', parentId: 'parent'),
        _TabFixture('first-child', parentId: 'first'),
        _TabFixture('second', parentId: 'parent'),
        _TabFixture('second-child', parentId: 'second'),
      ]);

      final moved = await db.tabDao.moveTabAmongSiblings('first', down: true);

      expect(moved, isTrue);
      expect(await _orderedTabIds(db), [
        'parent',
        'second',
        'second-child',
        'first',
        'first-child',
      ]);
    },
  );

  test(
    'moveTabAmongSiblings uses the rendered cross-space root scope',
    () async {
      await _insertSpaces(db, const ['home', 'work']);
      await _insertTabs(db, const [
        _TabFixture('opener', spaceUuid: 'home'),
        _TabFixture('work-first', spaceUuid: 'work'),
        _TabFixture('reopened', spaceUuid: 'work'),
        _TabFixture('reopened-child', parentId: 'reopened', spaceUuid: 'work'),
        _TabFixture('work-last', spaceUuid: 'work'),
        _TabFixture('foreign-child', spaceUuid: 'home'),
      ]);
      // 'reopened' stores a parent in 'home' but is drawn as a root of
      // 'work' — F1 is enforced on every DAO path, so only a direct write can
      // create that shape.
      await db.customStatement(
        "UPDATE tab SET parent_id = 'opener' WHERE id = 'reopened'",
      );
      await db.customStatement(
        "UPDATE tab SET parent_id = 'reopened' WHERE id = 'foreign-child'",
      );
      final foreignOrderKey = await _orderKeyOf(db, 'foreign-child');

      final moved = await db.tabDao.moveTabAmongSiblings(
        'reopened',
        down: true,
      );

      expect(moved, isTrue);
      expect(await _orderedTabIdsInSpace(db, 'work'), [
        'work-first',
        'work-last',
        'reopened',
        'reopened-child',
      ]);
      expect(await _orderKeyOf(db, 'foreign-child'), foreignOrderKey);
    },
  );

  test('content-state sync seeds parent for an unclaimed engine row', () async {
    await _insertTabs(db, const [
      _TabFixture('gecko-parent', source: TabSource.addedEvent),
      _TabFixture('child', source: TabSource.addedEvent),
    ]);

    await db.tabDao.updateTabs(null, {
      'child': _tabState('child', parentId: 'gecko-parent'),
    });

    final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
    expect(child, isNotNull);
    expect(child!.parentId, 'gecko-parent');
    expect(child.source, TabSource.manual);
  });

  test('engine parent seeding immediately claims an unclaimed row', () async {
    await _insertTabs(db, const [
      _TabFixture('gecko-parent', source: TabSource.addedEvent),
      _TabFixture('child', source: TabSource.addedEvent),
    ]);

    final seeded = await db.tabDao.seedParentFromEngineState(
      childId: 'child',
      parentId: 'gecko-parent',
      contextId: null,
    );

    final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
    expect(seeded, isTrue);
    expect(child, isNotNull);
    expect(child!.parentId, 'gecko-parent');
    expect(child.source, TabSource.manual);
  });

  test('engine parent seeding rejects a self-referential parent', () async {
    await _insertTabs(db, const [
      _TabFixture('tab', source: TabSource.addedEvent),
    ]);

    final seeded = await db.tabDao.seedParentFromEngineState(
      childId: 'tab',
      parentId: 'tab',
      contextId: null,
    );

    final tab = await db.tabDao.getTabDataById('tab').getSingleOrNull();
    expect(seeded, isFalse);
    expect(tab, isNotNull);
    expect(tab!.parentId, isNull);
    expect(tab.source, TabSource.addedEvent);
  });

  test('engine parent seeding keeps cross-container parents', () async {
    await _insertContainers(db, const [
      _ContainerFixture('parent-container'),
      _ContainerFixture('child-container'),
    ]);
    await _insertTabs(db, const [
      _TabFixture(
        'gecko-parent',
        source: TabSource.addedEvent,
        containerId: 'parent-container',
      ),
      _TabFixture(
        'child',
        source: TabSource.addedEvent,
        containerId: 'child-container',
      ),
    ]);

    final seeded = await db.tabDao.seedParentFromEngineState(
      childId: 'child',
      parentId: 'gecko-parent',
      contextId: 'child-container',
    );

    final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
    expect(seeded, isTrue);
    expect(child, isNotNull);
    expect(child!.parentId, 'gecko-parent');
    expect(child.containerId, 'child-container');
    expect(child.source, TabSource.manual);
  });

  test('content-state sync keeps cross-container parents', () async {
    await _insertContainers(db, const [
      _ContainerFixture('parent-container'),
      _ContainerFixture('child-container'),
    ]);
    await _insertTabs(db, const [
      _TabFixture(
        'gecko-parent',
        source: TabSource.addedEvent,
        containerId: 'parent-container',
      ),
      _TabFixture(
        'child',
        source: TabSource.addedEvent,
        containerId: 'child-container',
      ),
    ]);

    await db.tabDao.updateTabs(null, {
      'child': _tabState(
        'child',
        parentId: 'gecko-parent',
        contextId: 'child-container',
      ),
    });

    final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
    expect(child, isNotNull);
    expect(child!.parentId, 'gecko-parent');
    expect(child.containerId, 'child-container');
    expect(child.source, TabSource.manual);
  });

  test('a cross-space child is a local root in its own space view', () async {
    // Ordering is now scoped by space, not container (PLAN §6.6), so a
    // child stored under another space is the shape hierarchical views
    // must treat as a local root there. `insertTab`/`reorderTabs` both
    // enforce F1 (a child always adopts its parent's space), so the only
    // way to model such a row is a direct write — the same shape a stale
    // migration or engine takeover could otherwise leave behind.
    await _insertSpaces(db, const ['parent-space', 'child-space']);
    await _insertTabs(db, const [
      _TabFixture('opener', spaceUuid: 'parent-space'),
      _TabFixture('reopened', spaceUuid: 'child-space'),
    ]);
    await db.customStatement(
      "UPDATE tab SET parent_id = 'opener' WHERE id = 'reopened'",
    );

    final childSpaceRows = await db.tabDao
        .tabsWithRootAndDepth('child-space')
        .get();

    expect(childSpaceRows.map((row) => row.id), ['reopened']);
    expect(childSpaceRows.single.rootId, 'reopened');
    expect(childSpaceRows.single.depth, 0);

    // The opener's own space keeps its tree — the tab that was pulled
    // into another space neither joins it nor takes it over.
    final openerTrees = await db.tabDao
        .tabTrees('parent-space', skipSpaceCheck: false)
        .get();

    expect(openerTrees.map((tree) => tree.rootTabId), ['opener']);
    expect(openerTrees.single.latestTabId, 'opener');
    expect(openerTrees.single.totalTabs, 1);

    final reopenedTrees = await db.tabDao
        .tabTrees('child-space', skipSpaceCheck: false)
        .get();

    expect(reopenedTrees.map((tree) => tree.rootTabId), ['reopened']);
    expect(reopenedTrees.single.totalTabs, 1);
  });

  test('unscoped tab trees still span every space', () async {
    await _insertSpaces(db, const ['parent-space', 'child-space']);
    await _insertTabs(db, const [
      _TabFixture('opener', spaceUuid: 'parent-space'),
      _TabFixture('reopened', spaceUuid: 'child-space'),
    ]);
    await db.customStatement(
      "UPDATE tab SET parent_id = 'opener' WHERE id = 'reopened'",
    );

    final trees = await db.tabDao.tabTrees(null, skipSpaceCheck: true).get();

    expect(trees.map((tree) => tree.rootTabId).toSet(), {'opener'});
    expect(trees.map((tree) => tree.totalTabs).toSet(), {2});
  });

  test(
    'content-state sync validates parent against same-batch container repairs',
    () async {
      await _insertContainers(db, const [_ContainerFixture('container')]);
      await _insertTabs(db, const [
        _TabFixture('gecko-parent', source: TabSource.addedEvent),
        _TabFixture('child', source: TabSource.addedEvent),
      ]);

      await db.tabDao.updateTabs(null, {
        'gecko-parent': _tabState('gecko-parent', contextId: 'container'),
        'child': _tabState(
          'child',
          parentId: 'gecko-parent',
          contextId: 'container',
        ),
      });

      final parent = await db.tabDao
          .getTabDataById('gecko-parent')
          .getSingleOrNull();
      final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
      expect(parent, isNotNull);
      expect(parent!.containerId, 'container');
      expect(child, isNotNull);
      expect(child!.containerId, 'container');
      expect(child.parentId, 'gecko-parent');
      expect(child.source, TabSource.manual);
    },
  );

  test(
    'content-state sync retries an unresolved engine parent when the row arrives later',
    () async {
      await _insertTabs(db, const [
        _TabFixture('child', source: TabSource.addedEvent),
      ]);

      final initialState = {
        'child': _tabState('child', parentId: 'late-parent'),
      };

      await db.tabDao.updateTabs(null, initialState);

      final unresolvedChild = await db.tabDao
          .getTabDataById('child')
          .getSingleOrNull();
      expect(unresolvedChild, isNotNull);
      expect(unresolvedChild!.parentId, isNull);
      expect(unresolvedChild.source, TabSource.addedEvent);

      await _insertTabs(db, const [
        _TabFixture('late-parent', source: TabSource.addedEvent),
      ]);

      await db.tabDao.updateTabs(initialState, {
        'child': _tabState('child', parentId: 'late-parent'),
        'late-parent': _tabState('late-parent'),
      });

      final resolvedChild = await db.tabDao
          .getTabDataById('child')
          .getSingleOrNull();
      expect(resolvedChild, isNotNull);
      expect(resolvedChild!.parentId, 'late-parent');
      expect(resolvedChild.source, TabSource.manual);
    },
  );

  test(
    'tab-list sync resolves an unresolved engine parent after inserting the parent row',
    () async {
      await _insertTabs(db, const [
        _TabFixture('child', source: TabSource.addedEvent),
      ]);

      await db.tabDao.updateTabs(null, {
        'child': _tabState('child', parentId: 'late-parent'),
      });

      final unresolvedChild = await db.tabDao
          .getTabDataById('child')
          .getSingleOrNull();
      expect(unresolvedChild, isNotNull);
      expect(unresolvedChild!.parentId, isNull);
      expect(unresolvedChild.source, TabSource.addedEvent);

      await db.tabDao.syncTabs(
        engineTabIds: const ['late-parent', 'child'],
        defaultSpaceUuid: null,
      );

      final resolvedChild = await db.tabDao
          .getTabDataById('child')
          .getSingleOrNull();
      expect(resolvedChild, isNotNull);
      expect(resolvedChild!.parentId, 'late-parent');
      expect(resolvedChild.source, TabSource.manual);
    },
  );

  test(
    'content-state sync ignores parent-only changes with unresolved parents',
    () async {
      await _insertTabs(db, const [
        _TabFixture('child', source: TabSource.addedEvent),
      ]);

      final previousState = _tabState('child');

      await db.tabDao.updateTabs(
        {'child': previousState},
        {'child': previousState.copyWith(parentId: 'missing-parent')},
      );

      final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
      expect(child, isNotNull);
      expect(child!.parentId, isNull);
      expect(child.source, TabSource.addedEvent);
    },
  );

  test(
    'content-state sync does not overwrite a locally managed parent',
    () async {
      await _insertTabs(db, const [
        _TabFixture('local-parent'),
        _TabFixture('gecko-parent', source: TabSource.addedEvent),
        _TabFixture('child', parentId: 'local-parent'),
      ]);

      await db.tabDao.updateTabs(null, {
        'child': _tabState('child', parentId: 'gecko-parent'),
      });

      final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
      expect(child, isNotNull);
      expect(child!.parentId, 'local-parent');
      expect(child.source, TabSource.manual);
    },
  );

  test(
    'content-state sync ignores parent-only changes for locally managed rows',
    () async {
      await _insertTabs(db, const [
        _TabFixture('local-parent'),
        _TabFixture('gecko-parent', source: TabSource.addedEvent),
        _TabFixture('child', parentId: 'local-parent'),
      ]);

      final previousState = _tabState('child', parentId: 'local-parent');

      await db.tabDao.updateTabs(
        {'child': previousState},
        {'child': previousState.copyWith(parentId: 'gecko-parent')},
      );

      final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
      expect(child, isNotNull);
      expect(child!.parentId, 'local-parent');
      expect(child.source, TabSource.manual);
    },
  );

  test(
    'content-state sync preserves an existing parent on engine rows',
    () async {
      await _insertTabs(db, const [
        _TabFixture('existing-parent', source: TabSource.addedEvent),
        _TabFixture('gecko-parent', source: TabSource.addedEvent),
        _TabFixture(
          'child',
          parentId: 'existing-parent',
          source: TabSource.addedEvent,
        ),
      ]);

      await db.tabDao.updateTabs(null, {
        'child': _tabState('child', parentId: 'gecko-parent'),
      });

      final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
      expect(child, isNotNull);
      expect(child!.parentId, 'existing-parent');
      expect(child.source, TabSource.addedEvent);
    },
  );

  test('reorder-only moves do not claim manual hierarchy authority', () async {
    await _insertTabs(db, const [
      _TabFixture('other'),
      _TabFixture('child', source: TabSource.addedEvent),
      _TabFixture('gecko-parent', source: TabSource.addedEvent),
    ]);

    await db.tabDao.reorderTabs(
      movingTabIds: const ['child'],
      previousTabId: null,
      nextTabId: 'other',
    );

    final reorderedChild = await db.tabDao
        .getTabDataById('child')
        .getSingleOrNull();
    expect(reorderedChild, isNotNull);
    expect(reorderedChild!.source, TabSource.addedEvent);
    expect(reorderedChild.parentId, isNull);

    await db.tabDao.updateTabs(null, {
      'child': _tabState('child', parentId: 'gecko-parent'),
    });

    final seededChild = await db.tabDao
        .getTabDataById('child')
        .getSingleOrNull();
    expect(seededChild, isNotNull);
    expect(seededChild!.parentId, 'gecko-parent');
    expect(seededChild.source, TabSource.manual);
  });

  test('tab-list sync preserves an existing local parent', () async {
    await _insertTabs(db, const [
      _TabFixture('parent'),
      _TabFixture('child', parentId: 'parent'),
    ]);

    await db.tabDao.syncTabs(
      engineTabIds: const ['parent', 'child'],
      defaultSpaceUuid: null,
    );

    final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
    expect(child, isNotNull);
    expect(child!.parentId, 'parent');
  });

  test('deleting a parent rewires children to the grandparent', () async {
    await _insertTabs(db, const [
      _TabFixture('grandparent'),
      _TabFixture('parent', parentId: 'grandparent'),
      _TabFixture('child', parentId: 'parent'),
    ]);

    await db.customStatement("DELETE FROM tab WHERE id = 'parent'");

    final child = await db.tabDao.getTabDataById('child').getSingleOrNull();
    expect(child, isNotNull);
    expect(child!.parentId, 'grandparent');
  });

  test(
    'deleting the throwaway tab of a container hand-off keeps the opener reachable',
    () async {
      await _insertContainers(db, const [
        _ContainerFixture('parent-container'),
        _ContainerFixture('child-container'),
      ]);
      // The shape the site-assignment listener produces: a link is followed
      // into a container-assigned site, the blocked tab is thrown away and the
      // site is reopened in its own container.
      await _insertTabs(db, const [
        _TabFixture('opener', containerId: 'parent-container'),
        _TabFixture(
          'blocked',
          parentId: 'opener',
          containerId: 'parent-container',
        ),
        _TabFixture(
          'reopened',
          parentId: 'blocked',
          containerId: 'child-container',
        ),
      ]);

      await db.customStatement("DELETE FROM tab WHERE id = 'blocked'");

      final reopened = await db.tabDao
          .getTabDataById('reopened')
          .getSingleOrNull();
      expect(reopened, isNotNull);
      expect(reopened!.parentId, 'opener');
      expect(reopened.containerId, 'child-container');
    },
  );

  test('subtree collection stops at the space boundary', () async {
    await _insertSpaces(db, const ['parent-space', 'child-space']);
    await _insertTabs(db, const [
      _TabFixture('opener', spaceUuid: 'parent-space'),
      _TabFixture('local-child', parentId: 'opener', spaceUuid: 'parent-space'),
      _TabFixture('reopened', spaceUuid: 'child-space'),
      _TabFixture(
        'reopened-child',
        parentId: 'reopened',
        spaceUuid: 'child-space',
      ),
    ]);
    // Only a direct write can put 'reopened' under 'opener' while keeping it
    // in another space — insertTab/reorderTabs both enforce F1.
    await db.customStatement(
      "UPDATE tab SET parent_id = 'opener' WHERE id = 'reopened'",
    );

    final scoped = await db.tabDao.unorderedScopeTabDescendants('opener').get();

    expect(scoped.map((row) => row.id).toSet(), {'opener', 'local-child'});

    // The seed's own space is what bounds the walk, so starting at the
    // reopened tab still yields its whole subtree over there.
    final scopedFromReopened = await db.tabDao
        .unorderedScopeTabDescendants('reopened')
        .get();

    expect(scopedFromReopened.map((row) => row.id).toSet(), {
      'reopened',
      'reopened-child',
    });

    // Cycle detection and the hierarchy pickers still see everything.
    final unscoped = await db.definitionsDrift
        .unorderedTabDescendants(tabId: 'opener')
        .get();

    expect(unscoped.map((row) => row.id).toSet(), {
      'opener',
      'local-child',
      'reopened',
      'reopened-child',
    });
  });

  test(
    'closing a parent leaves a cross-space child in its own order',
    () async {
      await _insertSpaces(db, const ['parent-space', 'child-space']);
      await _insertTabs(db, const [
        _TabFixture('closing', spaceUuid: 'parent-space'),
        _TabFixture('foreign-child', spaceUuid: 'child-space'),
        _TabFixture('foreign-sibling', spaceUuid: 'child-space'),
      ]);
      await db.customStatement(
        "UPDATE tab SET parent_id = 'closing' WHERE id = 'foreign-child'",
      );

      final orderKeyBefore = await _orderKeyOf(db, 'foreign-child');

      await db.tabDao.preservePromotedChildOrderOnClose(const ['closing']);

      // `order_key` only orders tabs within one space; re-slotting the child
      // into the closing tab's list would drop a foreign rank into it.
      expect(await _orderKeyOf(db, 'foreign-child'), orderKeyBefore);
    },
  );

  test(
    'closing a tab with an out-of-space parent hands its slot to its child',
    () async {
      await _insertSpaces(db, const ['home', 'work']);
      // `reopened` stores a parent in `home` but is drawn as a root of `work`,
      // between the two plain roots — that rendered scope is the slot its
      // promoted child has to inherit.
      await _insertTabs(db, const [
        _TabFixture('opener', spaceUuid: 'home'),
        _TabFixture('work-first', spaceUuid: 'work'),
        _TabFixture('reopened', spaceUuid: 'work'),
        _TabFixture('reopened-child', parentId: 'reopened', spaceUuid: 'work'),
        _TabFixture('work-last', spaceUuid: 'work'),
      ]);
      await db.customStatement(
        "UPDATE tab SET parent_id = 'opener' WHERE id = 'reopened'",
      );

      await db.tabDao.preservePromotedChildOrderOnClose(const ['reopened']);
      await db.customStatement("DELETE FROM tab WHERE id = 'reopened'");

      expect(await _orderedTabIdsInSpace(db, 'work'), [
        'work-first',
        'reopened-child',
        'work-last',
      ]);
    },
  );

  test(
    'a closing parent in another space does not swallow the local pass',
    () async {
      await _insertSpaces(db, const ['home', 'work']);
      // The child trails `work-last` in storage, so only an actual re-ranking
      // pass over `work` can put it back into the slot `reopened` vacates.
      await _insertTabs(db, const [
        _TabFixture('opener', spaceUuid: 'home'),
        _TabFixture('work-first', spaceUuid: 'work'),
        _TabFixture('reopened', spaceUuid: 'work'),
        _TabFixture('work-last', spaceUuid: 'work'),
        _TabFixture('reopened-child', parentId: 'reopened', spaceUuid: 'work'),
      ]);
      await db.customStatement(
        "UPDATE tab SET parent_id = 'opener' WHERE id = 'reopened'",
      );

      // The opener closes too. Its pass only re-ranks `home`, so `reopened`
      // still has to stand in for its own scope rather than be absorbed.
      await db.tabDao.preservePromotedChildOrderOnClose(const [
        'opener',
        'reopened',
      ]);
      await db.customStatement(
        "DELETE FROM tab WHERE id IN ('opener', 'reopened')",
      );

      expect(await _orderedTabIdsInSpace(db, 'work'), [
        'work-first',
        'reopened-child',
        'work-last',
      ]);
    },
  );
}

Future<String> _orderKeyOf(TabDatabase db, String tabId) async {
  final tab = await db.tabDao.getTabDataById(tabId).getSingleOrNull();
  return tab!.orderKey;
}

Future<List<String>> _orderedTabIdsInSpace(
  TabDatabase db,
  String? spaceUuid,
) async {
  final tabs = await db.tabDao.getSpaceTabsData(spaceUuid).get();

  return (tabs.toList()..sort((a, b) => a.orderKey.compareTo(b.orderKey)))
      .map((tab) => tab.id)
      .toList();
}

Future<void> _insertTabs(TabDatabase db, List<_TabFixture> tabs) async {
  final orderKeys = _spacedOrderKeys(tabs.length);

  for (final (index, tab) in tabs.indexed) {
    await db.tabDao.insertTab(
      tab.id,
      source: tab.source,
      parentId: Value(tab.parentId),
      containerId: Value(tab.containerId),
      spaceUuid: Value(tab.spaceUuid),
      orderKey: Value(orderKeys[index]),
    );
  }
}

Future<void> _insertSpaces(TabDatabase db, List<String> uuids) async {
  for (final (index, uuid) in uuids.indexed) {
    await db.spaceDao.insertSpace(
      SpaceData(uuid: uuid, name: uuid, orderIndex: index),
    );
  }
}

Future<void> _insertContainers(
  TabDatabase db,
  List<_ContainerFixture> containers,
) async {
  for (final container in containers) {
    await db.containerDao.addContainer(
      ContainerData(
        id: container.id,
        name: container.id,
        orderKey: container.id,
      ),
    );
  }
}

Future<List<String>> _orderedTabIds(TabDatabase db) {
  return db.tabDao.getAllTabIds().get();
}

List<String> _spacedOrderKeys(int count) {
  var rank = LexoRank.middle();
  final orderKeys = <String>[];

  for (var i = 0; i < count; i++) {
    orderKeys.add(rank.value);
    for (var gap = 0; gap < 4; gap++) {
      rank = rank.genNext();
    }
  }

  return orderKeys;
}

class _TabFixture {
  final String id;
  final String? parentId;
  final String? containerId;
  final String? spaceUuid;
  final TabSource source;

  const _TabFixture(
    this.id, {
    this.parentId,
    this.containerId,
    this.spaceUuid,
    this.source = TabSource.manual,
  });
}

class _ContainerFixture {
  final String id;

  const _ContainerFixture(this.id);
}

TabState _tabState(String id, {String? parentId, String? contextId}) {
  return TabState.$default(id).copyWith(
    parentId: parentId,
    contextId: contextId,
    url: Uri.parse('https://$id.example/'),
    title: id,
  );
}
