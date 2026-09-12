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
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:lexo_rank/lexo_rank.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/tab.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/projections/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/scope_slot.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/sync_tabs_result.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_query_result.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/entities/tab_parent_change.dart';

/// Rows of `tab`.
///
/// Ordering is per [TabOrderScope] (PLAN §6.6): a tab's `order_key` only
/// means something against the other tabs of its `(space_uuid, folder_id,
/// tab_shelf)` — or, for essentials, its container strip. Every method that
/// generates or compares keys takes the scope explicitly; nothing here infers
/// it from `container_id` any more.
///
/// Invariants this DAO maintains (DESIGN.md "Schema v19"):
/// - I1 essential ⇒ `space_uuid`, `folder_id`, `split_id` are NULL.
/// - I3 private ⇒ `space_uuid` NULL, shelf normal.
/// - F1 a child tab shares its parent's `space_uuid` and `folder_id`. The
///   `tab_child_follows_parent_scope` trigger covers direct children on
///   update; the reparenting paths here cascade the rest explicitly.
@DriftAccessor()
class TabDao extends DatabaseAccessor<TabDatabase> with $TabDaoMixin {
  final _undoHistory = <String, TabData>{};
  final _pendingParentIds = <String, String>{};
  Timer? _clearHistoryTimer;

  static const closedTabTombstoneTtl = Duration(hours: 24);

  /// Soft cap for stored extracted/full content bytes (UTF-16 code units).
  /// The trigram FTS index expansion is roughly 5–10x the source size, so an
  /// uncapped multi-MB page DOM blows up the shadow tables disproportionately.
  /// Anything above the cap is truncated at write time; the tail is rarely
  /// useful for in-page text search anyway.
  static const _contentSizeCap = 256 * 1024;

  static String? _capContent(String? value) {
    if (value == null) return null;
    if (value.length <= _contentSizeCap) return value;
    return value.substring(0, _contentSizeCap);
  }

  TabDao(super.db);

  UpdateStatement<Tab, TabData> _updateByIdStatement(String id) =>
      db.tab.update()..where((t) => t.id.equals(id));

  /// The full row, page text included. Only for the one caller that renders
  /// stored content ([showContentSelectionDialog]); everything that lists or
  /// watches tabs wants [TabSummary] instead — see that class for why.
  SingleOrNullSelectable<TabData> getTabDataById(String id) =>
      db.tab.select()..where((t) => t.id.equals(id));

  /// A `selectOnly` over [tabSummaryColumns], mapped to [TabSummary].
  ///
  /// [refine] adds the `where`/`orderBy`/`limit` — a callback rather than a
  /// cascade on the return value, because mapping has to come last.
  JoinedSelectStatement<Tab, TabData> _tabSummaryQuery(
    void Function(JoinedSelectStatement<Tab, TabData> query) refine,
  ) {
    final query = selectTabSummaries(this, db.tab);
    refine(query);
    return query;
  }

  Selectable<TabSummary> _tabSummaries(
    void Function(JoinedSelectStatement<Tab, TabData> query) refine,
  ) => _tabSummaryQuery(refine).map((row) => readTabSummary(row, db.tab));

  /// [getTabDataById] without the content columns.
  SingleOrNullSelectable<TabSummary> getTabSummaryById(String id) =>
      _tabSummaryQuery(
        (q) => q..where(db.tab.id.equals(id)),
      ).map((row) => readTabSummary(row, db.tab));

  Future<Map<String, TabSummary>> _summariesById(Iterable<String> ids) async {
    final unique = ids.toSet();
    if (unique.isEmpty) {
      return const {};
    }
    final rows = await _tabSummaries(
      (q) => q..where(db.tab.id.isIn(unique)),
    ).get();
    return {for (final row in rows) row.id: row};
  }

  /// The `WHERE` half of the scoped predicate every ordering query in
  /// `definitions.drift` uses, for the few ad-hoc queries built in Dart.
  Expression<bool> _scopePredicate(TabOrderScope scope) {
    var predicate =
        db.tab.spaceUuid.equalsNullable(scope.spaceUuid) &
        db.tab.folderId.equalsNullable(scope.folderId) &
        db.tab.tabShelf.equalsValue(scope.shelf);
    if (scope.isEssential) {
      predicate =
          predicate & db.tab.containerId.equalsNullable(scope.containerId);
    }
    return predicate;
  }

  // ---------------------------------------------------------------------------
  // Plain reads
  // ---------------------------------------------------------------------------

  SingleOrNullSelectable<TabMode> getTabMode(String tabId) {
    final query = selectOnly(db.tab)
      ..addColumns([db.tab.tabMode])
      ..where(db.tab.id.equals(tabId));

    return query.map(
      (row) => TabMode.fromDbValue(row.readWithConverter(db.tab.tabMode)!),
    );
  }

  Selectable<String> getAllTabIds() {
    final query = selectOnly(db.tab)
      ..addColumns([db.tab.id])
      ..orderBy([OrderingTerm.asc(db.tab.orderKey)]);

    return query.map((row) => row.read(db.tab.id)!);
  }

  /// Validates multiple tab IDs and returns only those that exist in the database.
  Selectable<String> getExistingTabIds(Iterable<String> tabIds) {
    final query = selectOnly(db.tab)
      ..addColumns([db.tab.id])
      ..where(db.tab.id.isIn(tabIds));

    return query.map((row) => row.read(db.tab.id)!);
  }

  /// Most recently used tabs first.
  ///
  /// [excludedTabIds] skips tabs that are on their way out: tab rows are only
  /// deleted after the next selection has been made, so a tab being closed is
  /// still present here — and, having just been active, sorts first.
  Selectable<TabSummary> getTabsFifo({
    int limit = 25,
    Set<String> excludedTabIds = const {},
  }) {
    return _tabSummaries((query) {
      query
        ..limit(limit)
        ..orderBy([
          OrderingTerm.desc(db.tab.timestamp),
          // Total order, and the reason is in `idx_tab_timestamp`: timestamps
          // have one-second resolution, so ties are ordinary.
          OrderingTerm.desc(db.tab.id),
        ]);

      if (excludedTabIds.isNotEmpty) {
        query.where(db.tab.id.isNotIn(excludedTabIds));
      }
    });
  }

  /// As [getTabsFifo], restricted to one space. A null [spaceUuid] matches the
  /// tabs without a space — private tabs and essentials — not "any space".
  Selectable<TabSummary> getSpaceTabsFifo(
    String? spaceUuid, {
    int limit = 25,
    Set<String> excludedTabIds = const {},
  }) {
    return _tabSummaries((query) {
      query
        ..where(db.tab.spaceUuid.equalsNullable(spaceUuid))
        ..limit(limit)
        ..orderBy([
          OrderingTerm.desc(db.tab.timestamp),
          OrderingTerm.desc(db.tab.id),
        ]);

      if (excludedTabIds.isNotEmpty) {
        query.where(db.tab.id.isNotIn(excludedTabIds));
      }
    });
  }

  /// Every tab of one space, pinned shelf first, then in `order_key` order.
  Selectable<TabSummary> getSpaceTabsData(String? spaceUuid) {
    return _tabSummaries(
      (q) => q
        ..where(db.tab.spaceUuid.equalsNullable(spaceUuid))
        ..orderBy([
          OrderingTerm.desc(db.tab.tabShelf),
          OrderingTerm.asc(db.tab.orderKey),
        ]),
    );
  }

  SingleOrNullSelectable<String?> getTabContainerId(String tabId) {
    final query = selectOnly(db.tab)
      ..addColumns([db.tab.containerId])
      ..where(db.tab.id.equals(tabId));

    return query.map((row) => row.read(db.tab.containerId));
  }

  /// Only the container is read, so only the container's columns are selected —
  /// driving this off `select(db.tab)` would pull the tab's page text along with
  /// it for nothing.
  SingleOrNullSelectable<ContainerData?> getTabContainerData(String tabId) {
    final query = selectOnly(db.tab)
      ..addColumns(db.container.$columns)
      ..join([
        innerJoin(db.container, db.container.id.equalsExp(db.tab.containerId)),
      ])
      ..where(db.tab.id.equals(tabId));

    return query.map((row) => row.readTableOrNull(db.container));
  }

  Selectable<MapEntry<String, String?>> getTabsContainerId(
    Iterable<String> tabIds,
  ) {
    final query = selectOnly(db.tab)
      ..addColumns([db.tab.id, db.tab.containerId])
      ..where(db.tab.id.isIn(tabIds));

    return query.map(
      (row) => MapEntry(row.read(db.tab.id)!, row.read(db.tab.containerId)),
    );
  }

  Selectable<MapEntry<String, String>> getTabOrderKeys() {
    final query = selectOnly(db.tab)..addColumns([db.tab.id, db.tab.orderKey]);

    return query.map(
      (row) => MapEntry(row.read(db.tab.id)!, row.read(db.tab.orderKey)!),
    );
  }

  Selectable<MapEntry<String, DateTime>> getTabTimestamps() {
    final query = selectOnly(db.tab)..addColumns([db.tab.id, db.tab.timestamp]);

    return query.map(
      (row) => MapEntry(row.read(db.tab.id)!, row.read(db.tab.timestamp)!),
    );
  }

  /// `tab.id → tab_shelf` for every tab; the pinned/essential sets fall out of
  /// it. Replaces the old `is_pinned` id list.
  Stream<Map<String, TabShelf>> watchShelves() {
    final query = selectOnly(db.tab)..addColumns([db.tab.id, db.tab.tabShelf]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.read(db.tab.id)!: row.readWithConverter(db.tab.tabShelf)!,
      },
    );
  }

  /// The essential strip of one container (`null` = the unassigned strip), in
  /// `order_key` order.
  Selectable<String> essentialTabIds(String? containerId) =>
      db.definitionsDrift.essentialTabIds(containerId: containerId);

  // ---------------------------------------------------------------------------
  // Liveness (PLAN §7.4, DESIGN.md "Cold tabs")
  // ---------------------------------------------------------------------------

  SingleOrNullSelectable<TabData> getTabByEngineId(String engineTabId) =>
      db.definitionsDrift.tabByEngineId(engineTabId: engineTabId);

  /// Regular tabs without a live engine session.
  Selectable<String> coldTabIds() => db.definitionsDrift.coldTabIds();

  SingleSelectable<int> liveTabCount() => db.definitionsDrift.liveTabCount();

  /// Materialise (`engineTabId` = the tab's own id) or demote (`null`).
  Future<void> setEngineTabId(String tabId, String? engineTabId) =>
      _updateByIdStatement(
        tabId,
      ).write(TabCompanion(engineTabId: Value(engineTabId)));

  // ---------------------------------------------------------------------------
  // Scoped ordering queries (PLAN §6.6)
  // ---------------------------------------------------------------------------

  /// A key before the first tab of [scope]. [bucket] is the LexoRank
  /// rebalancing bucket, not a shelf selector.
  SingleSelectable<String> leadingOrderKey(
    TabOrderScope scope, {
    int bucket = 0,
  }) => db.definitionsDrift.leadingOrderKey(
    bucket: bucket,
    spaceUuid: scope.spaceUuid,
    folderId: scope.folderId,
    tabShelf: scope.shelf.index,
    scopeContainerId: scope.containerId,
  );

  /// A key after the last tab of [scope].
  SingleSelectable<String> trailingOrderKey(
    TabOrderScope scope, {
    int bucket = 0,
  }) => db.definitionsDrift.trailingOrderKey(
    bucket: bucket,
    spaceUuid: scope.spaceUuid,
    folderId: scope.folderId,
    tabShelf: scope.shelf.index,
    scopeContainerId: scope.containerId,
  );

  /// The last (by `order_key`) direct child of [parentId] inside [scope].
  SingleOrNullSelectable<String> lastChildTabId(
    String parentId, {
    required TabOrderScope scope,
  }) => db.definitionsDrift.lastChildTabId(
    parentId: parentId,
    spaceUuid: scope.spaceUuid,
    folderId: scope.folderId,
    tabShelf: scope.shelf.index,
    scopeContainerId: scope.containerId,
  );

  /// A key between [tabId] and its successor in [scope]; `null` when [tabId]
  /// is not in [scope].
  SingleOrNullSelectable<String> orderKeyAfterTab(
    String tabId, {
    required TabOrderScope scope,
  }) => db.definitionsDrift.orderKeyAfterTab(
    tabId: tabId,
    spaceUuid: scope.spaceUuid,
    folderId: scope.folderId,
    tabShelf: scope.shelf.index,
    scopeContainerId: scope.containerId,
  );

  /// A key between [tabId] and its predecessor in [scope]; `null` when
  /// [tabId] is not in [scope].
  SingleOrNullSelectable<String> orderKeyBeforeTab(
    String tabId, {
    required TabOrderScope scope,
  }) => db.definitionsDrift.orderKeyBeforeTab(
    tabId: tabId,
    spaceUuid: scope.spaceUuid,
    folderId: scope.folderId,
    tabShelf: scope.shelf.index,
    scopeContainerId: scope.containerId,
  );

  /// The largest-keyed tab of [tabId]'s subtree within [scope]; the anchor for
  /// inserting after the whole subtree. See the contiguity note on the query.
  SingleOrNullSelectable<String> lastSubtreeTabIdByOrderKey(
    String tabId, {
    required TabOrderScope scope,
  }) => db.definitionsDrift.lastSubtreeTabIdByOrderKey(
    tabId: tabId,
    spaceUuid: scope.spaceUuid,
    folderId: scope.folderId,
    tabShelf: scope.shelf.index,
    scopeContainerId: scope.containerId,
  );

  /// The tabs that render as siblings under [parentId] (`null` = the scope's
  /// roots) inside [scope], in `order_key` order. A tab whose stored parent
  /// lives in another space or folder counts as a root here.
  Selectable<ScopeSiblingsResult> scopeSiblings(
    TabOrderScope scope, {
    required String? parentId,
  }) => db.definitionsDrift.scopeSiblings(
    spaceUuid: scope.spaceUuid,
    folderId: scope.folderId,
    tabShelf: scope.shelf.index,
    scopeContainerId: scope.containerId,
    parentId: parentId,
  );

  /// [tabId] and every descendant, wherever it lives.
  Selectable<UnorderedTabDescendantsResult> unorderedTabDescendants(
    String tabId,
  ) => db.definitionsDrift.unorderedTabDescendants(tabId: tabId);

  /// [tabId] and the descendants that share its space and folder.
  Selectable<UnorderedScopeTabDescendantsResult> unorderedScopeTabDescendants(
    String tabId,
  ) => db.definitionsDrift.unorderedScopeTabDescendants(tabId: tabId);

  Selectable<String?> previousTabByOrderKey(
    String tabId, {
    required TabOrderScope scope,
    bool skipScopeCheck = false,
  }) => db.definitionsDrift.previousTabByOrderKey(
    tabId: tabId,
    spaceUuid: scope.spaceUuid,
    folderId: scope.folderId,
    tabShelf: scope.shelf.index,
    scopeContainerId: scope.containerId,
    skipScopeCheck: skipScopeCheck,
  );

  Selectable<String?> nextTabByOrderKey(
    String tabId, {
    required TabOrderScope scope,
    bool skipScopeCheck = false,
  }) => db.definitionsDrift.nextTabByOrderKey(
    tabId: tabId,
    spaceUuid: scope.spaceUuid,
    folderId: scope.folderId,
    tabShelf: scope.shelf.index,
    scopeContainerId: scope.containerId,
    skipScopeCheck: skipScopeCheck,
  );

  Selectable<String?> previousTabByTimestamp(String tabId) =>
      db.definitionsDrift.previousTabByTimestamp(tabId: tabId);

  /// Every tab of [spaceUuid] with its rendered root and depth.
  Selectable<TabsWithRootAndDepthResult> tabsWithRootAndDepth(
    String? spaceUuid,
  ) => db.definitionsDrift.tabsWithRootAndDepth(spaceUuid: spaceUuid);

  /// Trees rooted in [spaceUuid], or across every space with [skipSpaceCheck].
  Selectable<TabTreesResult> tabTrees(
    String? spaceUuid, {
    bool skipSpaceCheck = false,
  }) => db.definitionsDrift.tabTrees(
    spaceUuid: spaceUuid,
    skipSpaceCheck: skipSpaceCheck,
  );

  /// The ordered child sequence of `(spaceUuid, folderId)`: pinned slots
  /// first, then folders, splits and normal tabs interleaved by `order_key`.
  /// Split members and essentials are not slots (PLAN §6.5, §6.6).
  Future<List<ScopeSlot>> scopeChildSlots(
    String? spaceUuid,
    String? folderId,
  ) async {
    final tabs = await db.definitionsDrift
        .scopeSlotTabs(spaceUuid: spaceUuid, folderId: folderId)
        .get();
    final folders = await db.definitionsDrift
        .scopeSlotFolders(spaceUuid: spaceUuid, folderId: folderId)
        .get();
    final splits = await db.definitionsDrift
        .scopeSlotSplits(spaceUuid: spaceUuid, folderId: folderId)
        .get();

    final slots = <ScopeSlot>[
      for (final tab in tabs)
        ScopeSlot(
          id: tab.id,
          kind: ScopeSlotKind.tab,
          orderKey: tab.orderKey,
          shelf: tab.shelf,
        ),
      for (final folder in folders)
        ScopeSlot(
          id: folder.id,
          kind: ScopeSlotKind.folder,
          orderKey: folder.orderKey,
          shelf: TabShelf.normal,
        ),
      for (final split in splits)
        ScopeSlot(
          id: split.id,
          kind: ScopeSlotKind.split,
          orderKey: split.orderKey,
          shelf: split.isPinned ? TabShelf.pinned : TabShelf.normal,
        ),
    ];
    slots.sort((a, b) {
      final byShelf = b.shelf.index.compareTo(a.shelf.index);
      if (byShelf != 0) return byShelf;
      return a.orderKey.compareTo(b.orderKey);
    });
    return slots;
  }

  // ---------------------------------------------------------------------------
  // Engine-seeded hierarchy
  // ---------------------------------------------------------------------------

  Future<void> _resolvePendingParents() async {
    if (_pendingParentIds.isEmpty) return;

    final pendingChildren = selectOnly(db.tab)
      ..addColumns([db.tab.id])
      ..where(
        db.tab.id.isIn(_pendingParentIds.keys) &
            db.tab.parentId.isNull() &
            db.tab.source.isNotValue(TabSource.manual.index),
      );
    final pendingChildIds = {
      for (final row in await pendingChildren.get()) row.read(db.tab.id)!,
    };

    if (pendingChildIds.isEmpty) {
      _pendingParentIds.clear();
      return;
    }

    final parentIds = pendingChildIds
        .map((childId) => _pendingParentIds[childId]!)
        .toSet();
    // Existence is the only requirement: a parent_id pointing at a row that is
    // not there yet would abort the batch on the self-referential FK.
    final parents = await _summariesById(parentIds);

    await batch((batch) {
      for (final childId in pendingChildIds) {
        final parent = parents[_pendingParentIds[childId]];
        if (parent == null) {
          continue;
        }

        batch.update(
          db.tab,
          TabCompanion(
            parentId: Value(parent.id),
            source: const Value(TabSource.manual),
            // F1: the child joins its parent's space and folder.
            spaceUuid: Value(parent.spaceUuid),
            folderId: Value(parent.folderId),
          ),
          where: (t) => t.id.equals(childId),
        );
      }
    });

    _pendingParentIds.removeWhere(
      (childId, parentId) =>
          !pendingChildIds.contains(childId) || parents.containsKey(parentId),
    );
  }

  /// Which of [containerIds] name an existing container. A tab's engine
  /// `contextId` is its container id (DESIGN.md "D3 refinement"), so this is
  /// the whole check before adopting one from engine state.
  Future<Set<String>> _existingContainerIds(
    Iterable<String> containerIds,
  ) async {
    final unique = containerIds.toSet();
    if (unique.isEmpty) {
      return const {};
    }
    final query = selectOnly(db.container)
      ..addColumns([db.container.id])
      ..where(db.container.id.isIn(unique));
    final rows = await query.map((row) => row.read(db.container.id)!).get();
    return rows.toSet();
  }

  Future<bool> seedParentFromEngineState({
    required String childId,
    required String? parentId,
    required String? contextId,
  }) {
    return db.transaction(() async {
      if (parentId == null || parentId == childId) {
        // A null or self-referential engine parent can never seed a hierarchy
        // link (the latter would create a cycle), so drop any pending retry.
        _pendingParentIds.remove(childId);
        return false;
      }

      final child = await getTabSummaryById(childId).getSingleOrNull();
      if (child == null) {
        _pendingParentIds[childId] = parentId;
        return false;
      }
      if (child.parentId != null || child.source == TabSource.manual) {
        _pendingParentIds.remove(childId);
        return false;
      }

      final parent = await getTabSummaryById(parentId).getSingleOrNull();
      if (parent == null) {
        _pendingParentIds[childId] = parentId;
        return false;
      }

      final repairedContainerId =
          child.containerId == null &&
              contextId != null &&
              (await _existingContainerIds({contextId})).contains(contextId)
          ? contextId
          : null;

      // The link is kept even across containers — a link followed into a
      // container-assigned site is reopened in that container, and the opener
      // is the only way back once the reopened tab runs out of history. The
      // child does adopt the parent's space and folder (F1); its order_key is
      // left alone, the grouped views place it under its parent regardless.
      await _updateByIdStatement(childId).write(
        TabCompanion(
          parentId: Value(parentId),
          source: const Value(TabSource.manual),
          spaceUuid: Value(parent.spaceUuid),
          folderId: Value(parent.folderId),
          containerId: repairedContainerId == null
              ? const Value.absent()
              : Value(repairedContainerId),
        ),
      );
      _pendingParentIds.remove(childId);
      return true;
    });
  }

  // ---------------------------------------------------------------------------
  // Inserts
  // ---------------------------------------------------------------------------

  Future<String> _generateOrderKey({
    required Value<String?> parentId,
    required TabOrderScope scope,
    Value<String?> afterTabId = const Value.absent(),
  }) async {
    // Explicit "place after this tab" wins regardless of parent.
    if (afterTabId.present && afterTabId.value != null) {
      final key = await orderKeyAfterTab(
        afterTabId.value!,
        scope: scope,
      ).getSingleOrNull();
      if (key != null) {
        return key;
      }
    }

    if (parentId.present && parentId.value != null) {
      // Place new child after the last existing sibling, falling back to
      // immediately after the parent if there are none yet.
      final lastChildId = await lastChildTabId(
        parentId.value!,
        scope: scope,
      ).getSingleOrNull();

      final lastChildSubtreeId = lastChildId == null
          ? null
          : await lastSubtreeTabIdByOrderKey(
              lastChildId,
              scope: scope,
            ).getSingleOrNull();

      final anchorTabId = lastChildSubtreeId ?? lastChildId ?? parentId.value!;

      final key = await orderKeyAfterTab(
        anchorTabId,
        scope: scope,
      ).getSingleOrNull();
      if (key != null) {
        return key;
      }
      // Defensive fallback: covers "parent row not present" and a parent that
      // lives in another scope than `scope` (then both lookups above yield
      // null because they filter on the new scope). Either way append.
    }

    // Root tabs (or unresolved parent) always append to the end of the list.
    // Display direction is applied at render time via TabListDirection /
    // TabBarDirection settings, so we never need to insert at the front.
    return trailingOrderKey(scope).getSingle();
  }

  /// Where a new tab ranks and which `space_uuid`/`folder_id` it gets.
  ///
  /// Private tabs have no space (I3), essentials have neither space nor
  /// folder (I1), and a child takes its parent's space and folder (F1) —
  /// unless the parent is itself essential or private, in which case the
  /// caller's values stand and the child renders as a local root.
  Future<TabOrderScope> _resolveInsertScope({
    required Value<String?> parentId,
    required Value<String?> spaceUuid,
    required Value<String?> folderId,
    required Value<String?> containerId,
    required TabShelf shelf,
    required Value<TabMode> tabMode,
  }) async {
    if (tabMode.present && tabMode.value == TabMode.private) {
      return TabOrderScope.private();
    }
    if (shelf == TabShelf.essential) {
      return TabOrderScope.essential(containerId.value);
    }
    if (parentId.present && parentId.value != null) {
      final parent = await getTabSummaryById(parentId.value!).getSingleOrNull();
      if (parent != null &&
          parent.tabShelf != TabShelf.essential &&
          parent.tabMode != TabModeDbValue.private) {
        return TabOrderScope(
          spaceUuid: parent.spaceUuid,
          folderId: parent.folderId,
          shelf: shelf,
          containerId: null,
        );
      }
    }
    return TabOrderScope(
      spaceUuid: spaceUuid.value,
      folderId: folderId.value,
      shelf: shelf,
      containerId: null,
    );
  }

  /// Creates the engine tab via [createTab] and its row in one transaction.
  ///
  /// The row is live on creation: `engine_tab_id = tab.id` (DESIGN.md "D2
  /// refinement"). [spaceUuid] is ignored for private tabs and essentials and
  /// overridden by the parent's space for children — see [_resolveInsertScope].
  Future<String> upsertTabTransactional(
    Future<String> Function() createTab, {
    required Value<String?> parentId,
    Value<String?> containerId = const Value.absent(),
    Value<String?> spaceUuid = const Value.absent(),
    Value<String?> folderId = const Value.absent(),
    TabShelf shelf = TabShelf.normal,
    Value<String?> orderKey = const Value.absent(),
    Value<String?> afterTabId = const Value.absent(),
    Value<Uri?> url = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<TabMode> tabMode = const Value.absent(),
  }) {
    return db.transaction(() async {
      final tabId = await createTab();
      final scope = await _resolveInsertScope(
        parentId: parentId,
        spaceUuid: spaceUuid,
        folderId: folderId,
        containerId: containerId,
        shelf: shelf,
        tabMode: tabMode,
      );
      final currentOrderKey =
          orderKey.value ??
          await _generateOrderKey(
            parentId: parentId,
            scope: scope,
            afterTabId: afterTabId,
          );
      final Value<TabModeDbValue> persistedTabMode = tabMode.present
          ? Value(tabMode.value.toDbValue())
          : const Value.absent();

      await db.tab.insertOne(
        TabCompanion.insert(
          id: tabId,
          engineTabId: Value(tabId),
          parentId: parentId,
          source: TabSource.manual,
          timestamp: DateTime.now(),
          containerId: containerId,
          spaceUuid: Value(scope.spaceUuid),
          folderId: Value(scope.folderId),
          tabShelf: Value(shelf),
          url: url,
          title: title,
          orderKey: currentOrderKey,
          tabMode: persistedTabMode,
        ),
        onConflict: DoUpdate(
          (old) => TabCompanion(
            engineTabId: Value(tabId),
            source: const Value(TabSource.manual),
            parentId: parentId,
            containerId: containerId,
            spaceUuid: Value(scope.spaceUuid),
            folderId: Value(scope.folderId),
            url: url,
            title: title,
            orderKey: Value.absentIfNull(orderKey.value),
            tabMode: persistedTabMode,
          ),
        ),
      );

      return tabId;
    });
  }

  /// Inserts a row for an engine tab that already exists (tab-list events),
  /// or upgrades an existing row's [source]. The row is live
  /// (`engine_tab_id = tabId`). The shelf is only written on insert — a
  /// re-added engine tab must not un-pin its row.
  Future<String> insertTab(
    String tabId, {
    required TabSource source,
    required Value<String?> parentId,
    Value<String?> containerId = const Value.absent(),
    Value<String?> spaceUuid = const Value.absent(),
    Value<String?> folderId = const Value.absent(),
    TabShelf shelf = TabShelf.normal,
    Value<String?> orderKey = const Value.absent(),
    Value<String?> afterTabId = const Value.absent(),
    Value<Uri?> url = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<TabMode> tabMode = const Value.absent(),
  }) {
    return db.transaction(() async {
      final scope = await _resolveInsertScope(
        parentId: parentId,
        spaceUuid: spaceUuid,
        folderId: folderId,
        containerId: containerId,
        shelf: shelf,
        tabMode: tabMode,
      );
      final currentOrderKey =
          orderKey.value ??
          await _generateOrderKey(
            parentId: parentId,
            scope: scope,
            afterTabId: afterTabId,
          );
      final Value<TabModeDbValue> persistedTabMode = tabMode.present
          ? Value(tabMode.value.toDbValue())
          : const Value.absent();

      await db.tab.insertOne(
        TabCompanion.insert(
          id: tabId,
          engineTabId: Value(tabId),
          parentId: parentId,
          source: source,
          timestamp: DateTime.now(),
          containerId: containerId,
          spaceUuid: Value(scope.spaceUuid),
          folderId: Value(scope.folderId),
          tabShelf: Value(shelf),
          orderKey: currentOrderKey,
          url: url,
          title: title,
          tabMode: persistedTabMode,
        ),
        onConflict: DoUpdate(
          (old) => TabCompanion(
            engineTabId: Value(tabId),
            source: Value(source),
            parentId: parentId,
            containerId: containerId,
            spaceUuid: spaceUuid.present || parentId.value != null
                ? Value(scope.spaceUuid)
                : const Value.absent(),
            folderId: folderId.present || parentId.value != null
                ? Value(scope.folderId)
                : const Value.absent(),
            url: url,
            title: title,
            orderKey: Value.absentIfNull(orderKey.value),
            tabMode: persistedTabMode,
          ),
          where: (old) => old.source.isSmallerThanValue(source.index),
        ),
      );

      return tabId;
    });
  }

  Future<void> assignContainer(String id, {required String? containerId}) {
    final statement = _updateByIdStatement(id);
    return statement.write(TabCompanion(containerId: Value(containerId)));
  }

  /// Regular tabs that lost their space (a deleted space, or rows predating
  /// spaces) join [spaceUuid]. Essentials have no space by design (I1) and are
  /// skipped. Returns the number of rows moved.
  Future<int> assignSpaceToOrphans(String spaceUuid) {
    return (db.tab.update()..where(
          (t) =>
              t.spaceUuid.isNull() &
              t.tabMode.equalsValue(TabModeDbValue.regular) &
              t.tabShelf.isNotValue(TabShelf.essential.index),
        ))
        .write(TabCompanion(spaceUuid: Value(spaceUuid)));
  }

  /// The Zen-only fields carried for a faithful round-trip (PLAN §6.3).
  Future<void> updateSyncFields(
    String tabId, {
    Value<String?> iconUrl = const Value.absent(),
    Value<String?> staticLabel = const Value.absent(),
    Value<bool> hasStaticIcon = const Value.absent(),
    Value<bool> defaultContainer = const Value.absent(),
  }) => _updateByIdStatement(tabId).write(
    TabCompanion(
      iconUrl: iconUrl,
      staticLabel: staticLabel,
      hasStaticIcon: hasStaticIcon,
      defaultContainer: defaultContainer,
    ),
  );

  // ---------------------------------------------------------------------------
  // Closed-tab tombstones
  // ---------------------------------------------------------------------------

  Future<void> addClosedTabTombstones(
    Iterable<String> tabIds, {
    DateTime? closedAt,
  }) async {
    final uniqueIds = tabIds.toSet();
    if (uniqueIds.isEmpty) {
      return;
    }

    final effectiveClosedAt = closedAt ?? DateTime.now();

    await batch((batch) {
      for (final tabId in uniqueIds) {
        batch.insert(
          db.closedTabTombstone,
          ClosedTabTombstoneCompanion.insert(
            tabId: tabId,
            closedAt: effectiveClosedAt,
          ),
          onConflict: DoUpdate(
            (_) =>
                ClosedTabTombstoneCompanion(closedAt: Value(effectiveClosedAt)),
          ),
        );
      }
    });
  }

  Future<void> deleteClosedTabTombstones(Iterable<String> tabIds) {
    final uniqueIds = tabIds.toSet();
    if (uniqueIds.isEmpty) {
      return Future.value();
    }

    return (db.closedTabTombstone.delete()
          ..where((t) => t.tabId.isIn(uniqueIds)))
        .go();
  }

  Future<void> pruneExpiredClosedTabTombstones({
    Duration ttl = closedTabTombstoneTtl,
    DateTime? now,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(ttl);

    return (db.closedTabTombstone.delete()
          ..where((t) => t.closedAt.isSmallerOrEqualValue(cutoff)))
        .go();
  }

  Future<Set<String>> getStartupRestoredClosedTabIds(
    Iterable<String> tabIds, {
    required DateTime sessionStartedAt,
    Duration ttl = closedTabTombstoneTtl,
    DateTime? now,
  }) async {
    final uniqueIds = tabIds.toSet();
    if (uniqueIds.isEmpty) {
      return const <String>{};
    }

    final freshnessCutoff = (now ?? DateTime.now()).subtract(ttl);
    final query = selectOnly(db.closedTabTombstone)
      ..addColumns([db.closedTabTombstone.tabId])
      ..where(
        db.closedTabTombstone.tabId.isIn(uniqueIds) &
            db.closedTabTombstone.closedAt.isSmallerThanValue(
              sessionStartedAt,
            ) &
            db.closedTabTombstone.closedAt.isBiggerOrEqualValue(
              freshnessCutoff,
            ),
      );

    return query
        .map((row) => row.read(db.closedTabTombstone.tabId)!)
        .get()
        .then((rows) => rows.toSet());
  }

  // ---------------------------------------------------------------------------
  // Reordering and reparenting
  // ---------------------------------------------------------------------------

  /// Re-keys [movingTabIds] — a root followed by its subtree in storage
  /// order — between [previousTabId] and [nextTabId].
  ///
  /// [parentChange] applies to the root only; descendants keep their
  /// `parent_id`. [scopeChange] rewrites `space_uuid`/`folder_id` for the
  /// whole block. Attaching to a parent overrides [scopeChange] with the
  /// parent's space and folder (F1); moving the block to another scope while
  /// leaving the parent alone detaches the root when its parent stays behind,
  /// so F1 holds afterwards.
  Future<void> reorderTabs({
    required List<String> movingTabIds,
    required String? previousTabId,
    required String? nextTabId,
    TabParentChange parentChange = const TabParentChange.unchanged(),
    TabScopeChange scopeChange = const TabScopeChange.unchanged(),
  }) {
    if (movingTabIds.isEmpty) {
      return Future.value();
    }

    return db.transaction(() async {
      final anchors = await _summariesById([
        if (previousTabId != null) previousTabId,
        if (nextTabId != null) nextTabId,
        movingTabIds.first,
      ]);

      final previousTab = previousTabId == null ? null : anchors[previousTabId];
      final nextTab = nextTabId == null ? null : anchors[nextTabId];
      final previousRank = previousTab == null
          ? null
          : LexoRank.parse(previousTab.orderKey);
      final nextRank = nextTab == null
          ? null
          : LexoRank.parse(nextTab.orderKey);

      final orderKeys = _generateOrderKeysBetween(
        count: movingTabIds.length,
        previousRank: previousRank,
        nextRank: nextRank,
      );

      // Resolve the parent_id / space / folder companion values once.
      //
      // For a `TabParentToSpecific` whose target row is missing, fall back
      // to "unchanged" so we don't issue a parent_id FK violation — the
      // caller passed a stale id, but the order_key change is still
      // useful. The scope cascade fires whenever the parent_id is being
      // assigned to a concrete tab, since `tabsWithRootAndDepth` is
      // space-scoped and a divergent child would vanish from hierarchical
      // views (F1).
      Value<String?> parentValue = const Value.absent();
      Value<String?> spaceValue = const Value.absent();
      Value<String?> folderValue = const Value.absent();
      Value<TabSource> rootSource = const Value.absent();
      switch (parentChange) {
        case TabParentUnchanged():
          break;
        case TabParentDetach():
          parentValue = const Value(null);
          rootSource = const Value(TabSource.manual);
        case TabParentToSpecific(:final parentTabId):
          final parent =
              anchors[parentTabId] ??
              await getTabSummaryById(parentTabId).getSingleOrNull();
          if (parent != null) {
            parentValue = Value(parentTabId);
            spaceValue = Value(parent.spaceUuid);
            folderValue = Value(parent.folderId);
            rootSource = const Value(TabSource.manual);
          }
      }

      if (!spaceValue.present) {
        switch (scopeChange) {
          case TabScopeUnchanged():
            break;
          case TabScopeToSpecific(:final spaceUuid, :final folderId):
            spaceValue = Value(spaceUuid);
            folderValue = Value(folderId);
            if (parentChange is TabParentUnchanged) {
              final root = anchors[movingTabIds.first];
              final rootParentId = root?.parentId;
              if (rootParentId != null &&
                  !movingTabIds.contains(rootParentId)) {
                final rootParent = await getTabSummaryById(
                  rootParentId,
                ).getSingleOrNull();
                if (rootParent == null ||
                    rootParent.spaceUuid != spaceUuid ||
                    rootParent.folderId != folderId) {
                  parentValue = const Value(null);
                  rootSource = const Value(TabSource.manual);
                }
              }
            }
        }
      }

      await batch((batch) {
        for (var i = 0; i < movingTabIds.length; i++) {
          final isRoot = i == 0;
          batch.update(
            db.tab,
            TabCompanion(
              source: isRoot ? rootSource : const Value.absent(),
              orderKey: Value(orderKeys[i]),
              // parent_id change applies only to the moving root;
              // descendants keep their existing parent_id pointers.
              parentId: isRoot ? parentValue : const Value.absent(),
              // Scope cascade applies to the whole subtree.
              spaceUuid: spaceValue,
              folderId: folderValue,
            ),
            where: (t) => t.id.equals(movingTabIds[i]),
          );
        }
      });
    });
  }

  /// Returns the recursive set of [tabId] and its descendants across every
  /// space and folder. Use this for hierarchy validation, not scope-local
  /// moves.
  Future<Set<String>> _collectSubtreeIds(String tabId) async {
    final rows = await unorderedTabDescendants(tabId).get();
    return {for (final r in rows) r.id};
  }

  /// Returns [tabId] and the descendants connected to it within its space and
  /// folder.
  Future<Set<String>> _collectScopeSubtreeIds(String tabId) async {
    final rows = await unorderedScopeTabDescendants(tabId).get();
    return {for (final r in rows) r.id};
  }

  /// Re-parents [tabId] to [newParentId] (or detaches when null).
  ///
  /// Returns `true` on success, `false` when the move was rejected
  /// (cycle, unknown tab, essential on either side, or no-op).
  ///
  /// - Cycle-safe: rejects when [newParentId] is the moving tab itself or
  ///   any of its descendants.
  /// - When attaching to a non-null parent, the scope-local moving subtree
  ///   adopts the new parent's `space_uuid` and `folder_id` (F1). A moving
  ///   tab that was a split member leaves its split — splits are bound to one
  ///   scope (I5).
  /// - Slots the scope-local moving subtree immediately after the new
  ///   parent's last existing child (or after the parent itself if it has
  ///   none), as an atomic order_key block. When detaching, order_keys are left
  ///   untouched — the tab simply becomes a root in its current slot.
  Future<bool> setTabParent({
    required String tabId,
    required String? newParentId,
  }) {
    if (tabId == newParentId) {
      return Future.value(false);
    }

    return db.transaction(() async {
      final movingTab = await getTabSummaryById(tabId).getSingleOrNull();
      if (movingTab == null) {
        return false;
      }
      if (movingTab.parentId == newParentId) {
        return false;
      }
      if (movingTab.tabShelf == TabShelf.essential) {
        // Essentials carry no tree (PLAN §6.4).
        return false;
      }

      // Parent links may cross scopes transiently, so cycle detection must
      // see the global hierarchy even though the moving order block is local.
      final descendantIds = await _collectSubtreeIds(tabId);

      final TabOrderScope targetScope;
      if (newParentId != null) {
        if (descendantIds.contains(newParentId)) {
          return false;
        }
        final newParent = await getTabSummaryById(
          newParentId,
        ).getSingleOrNull();
        if (newParent == null || newParent.tabShelf == TabShelf.essential) {
          return false;
        }
        // A child ranks in its parent's space and folder; it keeps its own
        // shelf, which only matters for where it renders, not whether.
        targetScope = TabOrderScope.forTab(
          newParent,
        ).withShelf(movingTab.tabShelf);
      } else {
        targetScope = TabOrderScope.forTab(movingTab);
      }

      // Resolve this before changing any scope columns. Crossing a boundary
      // must not pull descendants that currently render as roots elsewhere.
      final movingSubtreeIds = await _collectScopeSubtreeIds(tabId);

      final scopeChanges = !targetScope.sameSpaceAndFolder(
        TabOrderScope.forTab(movingTab),
      );
      if (scopeChanges) {
        if (movingTab.splitId != null) {
          await db.tabSplitDao.removeMember(tabId);
        }
        // Cascade scope updates only through the rendered local subtree.
        await (update(db.tab)..where((t) => t.id.isIn(movingSubtreeIds))).write(
          TabCompanion(
            spaceUuid: Value(targetScope.spaceUuid),
            folderId: Value(targetScope.folderId),
          ),
        );
      }

      if (newParentId == null) {
        // Detach: keep existing order_keys. The row becomes a root in its
        // current slot and the subtree under it stays intact.
        await _updateByIdStatement(tabId).write(
          const TabCompanion(
            source: Value(TabSource.manual),
            parentId: Value(null),
          ),
        );
        return true;
      }

      // Pull the (now scope-adjusted) subtree rows so we can re-rank them as
      // an atomic block. We must compute anchors BEFORE writing the new
      // parent_id, otherwise `lastChildTabId(newParentId)` would pick up the
      // moving root itself as a sibling.
      final subtreeRows = await _tabSummaries(
        (q) => q
          ..where(db.tab.id.isIn(movingSubtreeIds))
          ..orderBy([OrderingTerm.asc(db.tab.orderKey)]),
      ).get();
      final orderedIds = subtreeRows.map((r) => r.id).toList();
      if (orderedIds.isEmpty) {
        return true;
      }

      final lastSiblingId = await lastChildTabId(
        newParentId,
        scope: targetScope,
      ).getSingleOrNull();
      final lastSiblingSubtreeId = lastSiblingId == null
          ? null
          : await lastSubtreeTabIdByOrderKey(
              lastSiblingId,
              scope: targetScope,
            ).getSingleOrNull();
      final anchorId = lastSiblingSubtreeId ?? lastSiblingId ?? newParentId;

      final anchorRow = await getTabSummaryById(anchorId).getSingleOrNull();
      if (anchorRow == null) {
        return false;
      }
      final previousRank = LexoRank.parse(anchorRow.orderKey);

      // Next-rank = first non-subtree tab in the destination scope with
      // order_key strictly greater than the anchor. Skipping subtree members
      // keeps the moved block compact even when the subtree's old keys
      // sat near the anchor in storage.
      final nextRow = await _tabSummaries((q) {
        q
          ..where(
            _scopePredicate(targetScope) &
                db.tab.orderKey.isBiggerThanValue(anchorRow.orderKey) &
                db.tab.id.isNotIn(movingSubtreeIds),
          )
          ..orderBy([OrderingTerm.asc(db.tab.orderKey)])
          ..limit(1);
      }).getSingleOrNull();
      final nextRank = nextRow == null
          ? null
          : LexoRank.parse(nextRow.orderKey);

      final orderKeys = _generateOrderKeysBetween(
        count: orderedIds.length,
        previousRank: previousRank,
        nextRank: nextRank,
      );

      await batch((batch) {
        // parent_id change is applied on the moving root only; subtree
        // descendants keep their existing parent_id pointers.
        batch.update(
          db.tab,
          TabCompanion(
            source: const Value(TabSource.manual),
            parentId: Value(newParentId),
            orderKey: Value(orderKeys[0]),
          ),
          where: (t) => t.id.equals(orderedIds[0]),
        );
        for (var i = 1; i < orderedIds.length; i++) {
          batch.update(
            db.tab,
            TabCompanion(orderKey: Value(orderKeys[i])),
            where: (t) => t.id.equals(orderedIds[i]),
          );
        }
      });

      return true;
    });
  }

  /// Swaps a direct child with its parent: the child takes the parent's
  /// slot in the tree (parent_id + order_key), and the parent becomes a
  /// child of the (formerly) child, placed after its existing siblings.
  ///
  /// Returns `false` when [childId] has no parent or the tabs are in
  /// different ordering scopes (which would imply data corruption).
  Future<bool> promoteChildToParent(String childId) {
    return db.transaction(() async {
      final child = await getTabSummaryById(childId).getSingleOrNull();
      if (child == null || child.parentId == null) {
        return false;
      }
      final parentId = child.parentId!;
      final parent = await getTabSummaryById(parentId).getSingleOrNull();
      if (parent == null) {
        return false;
      }
      final scope = TabOrderScope.forTab(child);
      if (TabOrderScope.forTab(parent) != scope) {
        return false;
      }

      // The (about-to-be-demoted) parent gets placed after the new
      // parent's (= former child's) existing other children. We read the
      // anchor's order_key BEFORE any writes — `orderKeyAfterTab` reads from
      // storage, so the captured key reflects pre-swap state.
      final lastChildOfChild = await lastChildTabId(
        childId,
        scope: scope,
      ).getSingleOrNull();
      final lastChildSubtreeId = lastChildOfChild == null
          ? null
          : await lastSubtreeTabIdByOrderKey(
              lastChildOfChild,
              scope: scope,
            ).getSingleOrNull();
      final anchorId = lastChildSubtreeId ?? lastChildOfChild ?? childId;
      final newParentOrderKey = await orderKeyAfterTab(
        anchorId,
        scope: scope,
      ).getSingleOrNull();
      if (newParentOrderKey == null) {
        return false;
      }

      await batch((batch) {
        batch.update(
          db.tab,
          TabCompanion(
            source: const Value(TabSource.manual),
            parentId: Value(parent.parentId),
            orderKey: Value(parent.orderKey),
          ),
          where: (t) => t.id.equals(childId),
        );
        batch.update(
          db.tab,
          TabCompanion(
            source: const Value(TabSource.manual),
            parentId: Value(childId),
            orderKey: Value(newParentOrderKey),
          ),
          where: (t) => t.id.equals(parentId),
        );
      });

      return true;
    });
  }

  /// Moves [tabId] one sibling slot up (or down) within its parent scope,
  /// carrying its whole subtree as an atomic block.
  ///
  /// Returns `false` when the tab is unknown or already at the relevant
  /// end of its sibling list.
  Future<bool> moveTabAmongSiblings(String tabId, {required bool down}) {
    // Transactional so the sibling-list read, subtree resolution, and the
    // anchor lookup all observe the same DB snapshot. `reorderTabs` opens
    // a nested savepoint internally, which is fine.
    return db.transaction(() async {
      final tab = await getTabSummaryById(tabId).getSingleOrNull();
      if (tab == null) {
        return false;
      }
      final scope = TabOrderScope.forTab(tab);

      final parent = tab.parentId == null
          ? null
          : await getTabSummaryById(tab.parentId!).getSingleOrNull();
      final renderedParentId =
          parent != null &&
              parent.spaceUuid == tab.spaceUuid &&
              parent.folderId == tab.folderId
          ? parent.id
          : null;
      final siblingIds = await scopeSiblings(
        scope,
        parentId: renderedParentId,
      ).get().then((siblings) => siblings.map((s) => s.id).toList());

      final idx = siblingIds.indexOf(tabId);
      if (idx < 0) {
        return false;
      }
      final newIdx = down ? idx + 1 : idx - 1;
      if (newIdx < 0 || newIdx >= siblingIds.length) {
        return false;
      }

      final reorderedIds = siblingIds..removeAt(idx);
      reorderedIds.insert(newIdx, tabId);

      final previousIdx = newIdx - 1;
      final nextIdx = newIdx + 1;
      final previousSiblingId = previousIdx >= 0
          ? reorderedIds[previousIdx]
          : null;
      final previousTabId = previousSiblingId == null
          ? null
          : await lastSubtreeTabIdByOrderKey(
                  previousSiblingId,
                  scope: scope,
                ).getSingleOrNull() ??
                previousSiblingId;
      final nextTabId = nextIdx < reorderedIds.length
          ? reorderedIds[nextIdx]
          : null;

      final subtreeIds = await _collectScopeSubtreeIds(tabId);
      final subtreeRows = await _tabSummaries(
        (q) => q
          ..where(db.tab.id.isIn(subtreeIds))
          ..orderBy([OrderingTerm.asc(db.tab.orderKey)]),
      ).get();
      final movingTabIds = subtreeRows.map((r) => r.id).toList();

      await reorderTabs(
        movingTabIds: movingTabIds,
        previousTabId: previousTabId,
        nextTabId: nextTabId,
      );
      return true;
    });
  }

  List<String> _generateOrderKeysBetween({
    required int count,
    required LexoRank? previousRank,
    required LexoRank? nextRank,
  }) {
    if (count <= 0) {
      return const [];
    }

    if (previousRank == null && nextRank == null) {
      var rank = LexoRank.middle();
      return [
        for (var i = 0; i < count; i++)
          () {
            final value = rank.value;
            rank = rank.genNext();
            return value;
          }(),
      ];
    }

    if (nextRank == null) {
      var rank = previousRank!.genNext();
      return [
        for (var i = 0; i < count; i++)
          () {
            final value = rank.value;
            rank = rank.genNext();
            return value;
          }(),
      ];
    }

    if (previousRank == null) {
      var rank = nextRank;
      final reversed = <String>[];
      for (var i = 0; i < count; i++) {
        rank = rank.genPrev();
        reversed.add(rank.value);
      }
      return reversed.reversed.toList();
    }

    var upperBound = nextRank;
    final reversed = <String>[];
    for (var i = 0; i < count; i++) {
      upperBound = previousRank.genBetween(upperBound);
      reversed.add(upperBound.value);
    }
    return reversed.reversed.toList();
  }

  /// [count] consecutive keys starting at [first].
  List<String> _keysFrom(String first, int count) {
    var rank = LexoRank.parse(first);
    return [
      for (var i = 0; i < count; i++)
        () {
          final value = rank.value;
          rank = rank.genNext();
          return value;
        }(),
    ];
  }

  // ---------------------------------------------------------------------------
  // Shelves and scope moves (PLAN §6.4, §6.6)
  // ---------------------------------------------------------------------------

  /// Moves [tabId] to [shelf], appending it to [target] (whose shelf must be
  /// [shelf]).
  ///
  /// - essential: `space_uuid`, `folder_id`, `split_id` and `split_index`
  ///   become NULL (I1); the key ranks in the container strip
  ///   `target.containerId`. Essentials carry no tree, so the tab is detached
  ///   from its parent and its direct children are handed to its parent —
  ///   otherwise the F1 trigger would drag them out of their space.
  /// - pinned / normal: `space_uuid`/`folder_id` come from [target]. Children
  ///   follow through the F1 trigger (direct) and the DAO cascade (deeper).
  /// - A split member leaves its split first (I5).
  ///
  /// Returns `false` for an unknown tab or a private tab (I3: private tabs
  /// stay on the normal shelf).
  Future<bool> setShelf(
    String tabId,
    TabShelf shelf, {
    required TabOrderScope target,
  }) {
    assert(target.shelf == shelf, 'target scope must be on the $shelf shelf');
    return db.transaction(() async {
      final tab = await getTabSummaryById(tabId).getSingleOrNull();
      if (tab == null) {
        return false;
      }
      if (tab.tabMode == TabModeDbValue.private && shelf != TabShelf.normal) {
        return false;
      }

      if (tab.splitId != null) {
        await db.tabSplitDao.removeMember(tabId);
      }

      final isEssential = shelf == TabShelf.essential;
      if (isEssential) {
        await (update(db.tab)..where((t) => t.parentId.equals(tabId))).write(
          TabCompanion(
            parentId: Value(tab.parentId),
            source: const Value(TabSource.manual),
          ),
        );
      }

      final orderKey = await trailingOrderKey(target).getSingle();
      await _updateByIdStatement(tabId).write(
        TabCompanion(
          tabShelf: Value(shelf),
          orderKey: Value(orderKey),
          spaceUuid: Value(isEssential ? null : target.spaceUuid),
          folderId: Value(isEssential ? null : target.folderId),
          splitId: isEssential ? const Value(null) : const Value.absent(),
          splitIndex: isEssential ? const Value(null) : const Value.absent(),
          parentId: isEssential ? const Value(null) : const Value.absent(),
          source: isEssential
              ? const Value(TabSource.manual)
              : const Value.absent(),
        ),
      );

      // Deeper descendants: the trigger only reaches direct children.
      if (!isEssential) {
        final subtree = await _collectScopeSubtreeIds(tabId);
        subtree.remove(tabId);
        if (subtree.isNotEmpty) {
          await (update(db.tab)..where((t) => t.id.isIn(subtree))).write(
            TabCompanion(
              spaceUuid: Value(target.spaceUuid),
              folderId: Value(target.folderId),
            ),
          );
        }
      }
      return true;
    });
  }

  /// Moves the subtrees rooted at [rootTabIds] into [target], placing the
  /// block after [afterId] or before [beforeId] (both in [target]), or at the
  /// end when neither is given. Every tab in the block takes [target]'s
  /// shelf, `space_uuid` and `folder_id`.
  ///
  /// A root that is a split member brings every member of that split along,
  /// and the split row moves with them (I5). A root whose parent stays behind
  /// is detached so F1 holds. An essential [target] is handled per root by
  /// [setShelf].
  Future<void> moveToScope(
    List<String> rootTabIds,
    TabOrderScope target, {
    String? afterId,
    String? beforeId,
  }) {
    if (rootTabIds.isEmpty) {
      return Future.value();
    }
    assert(
      afterId == null || beforeId == null,
      'pass at most one of afterId / beforeId',
    );

    return db.transaction(() async {
      if (target.isEssential) {
        for (final rootId in rootTabIds) {
          await setShelf(rootId, TabShelf.essential, target: target);
        }
        return;
      }

      final roots = await _summariesById(rootTabIds);
      final blockIds = <String>{};
      final movingSplitIds = <String>{};
      for (final rootId in rootTabIds) {
        final root = roots[rootId];
        if (root == null) {
          continue;
        }
        final splitId = root.splitId;
        if (splitId != null) {
          if (!movingSplitIds.add(splitId)) {
            continue;
          }
          for (final memberId in await db.tabSplitDao.members(splitId)) {
            blockIds.addAll(await _collectScopeSubtreeIds(memberId));
          }
        } else {
          blockIds.addAll(await _collectScopeSubtreeIds(rootId));
        }
      }
      if (blockIds.isEmpty) {
        return;
      }

      final block = await _tabSummaries(
        (q) => q
          ..where(db.tab.id.isIn(blockIds))
          ..orderBy([OrderingTerm.asc(db.tab.orderKey)]),
      ).get();

      final List<String> orderKeys;
      if (afterId != null) {
        final anchorId =
            await lastSubtreeTabIdByOrderKey(
              afterId,
              scope: target,
            ).getSingleOrNull() ??
            afterId;
        final anchor = await getTabSummaryById(anchorId).getSingleOrNull();
        if (anchor == null) {
          orderKeys = _keysFrom(
            await trailingOrderKey(target).getSingle(),
            block.length,
          );
        } else {
          final next = await _tabSummaries(
            (q) => q
              ..where(
                _scopePredicate(target) &
                    db.tab.orderKey.isBiggerThanValue(anchor.orderKey) &
                    db.tab.id.isNotIn(blockIds),
              )
              ..orderBy([OrderingTerm.asc(db.tab.orderKey)])
              ..limit(1),
          ).getSingleOrNull();
          orderKeys = _generateOrderKeysBetween(
            count: block.length,
            previousRank: LexoRank.parse(anchor.orderKey),
            nextRank: next == null ? null : LexoRank.parse(next.orderKey),
          );
        }
      } else if (beforeId != null) {
        final anchor = await getTabSummaryById(beforeId).getSingleOrNull();
        if (anchor == null) {
          orderKeys = _keysFrom(
            await trailingOrderKey(target).getSingle(),
            block.length,
          );
        } else {
          final previous = await _tabSummaries(
            (q) => q
              ..where(
                _scopePredicate(target) &
                    db.tab.orderKey.isSmallerThanValue(anchor.orderKey) &
                    db.tab.id.isNotIn(blockIds),
              )
              ..orderBy([OrderingTerm.desc(db.tab.orderKey)])
              ..limit(1),
          ).getSingleOrNull();
          orderKeys = _generateOrderKeysBetween(
            count: block.length,
            previousRank: previous == null
                ? null
                : LexoRank.parse(previous.orderKey),
            nextRank: LexoRank.parse(anchor.orderKey),
          );
        }
      } else {
        orderKeys = _keysFrom(
          await trailingOrderKey(target).getSingle(),
          block.length,
        );
      }

      await batch((batch) {
        for (var i = 0; i < block.length; i++) {
          final tab = block[i];
          final detach =
              tab.parentId != null && !blockIds.contains(tab.parentId);
          batch.update(
            db.tab,
            TabCompanion(
              orderKey: Value(orderKeys[i]),
              tabShelf: Value(target.shelf),
              spaceUuid: Value(target.spaceUuid),
              folderId: Value(target.folderId),
              parentId: detach ? const Value(null) : const Value.absent(),
              source: detach
                  ? const Value(TabSource.manual)
                  : const Value.absent(),
            ),
            where: (t) => t.id.equals(tab.id),
          );
        }
        for (final splitId in movingSplitIds) {
          final firstMemberIndex = block.indexWhere(
            (tab) => tab.splitId == splitId,
          );
          batch.update(
            db.tabSplit,
            TabSplitCompanion(
              spaceUuid: Value(target.spaceUuid),
              folderId: Value(target.folderId),
              isPinned: Value(target.shelf == TabShelf.pinned),
              orderKey: firstMemberIndex < 0
                  ? const Value.absent()
                  : Value(orderKeys[firstMemberIndex]),
            ),
            where: (s) => s.id.equals(splitId),
          );
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Closing
  // ---------------------------------------------------------------------------

  /// Reassigns `order_key` for grandchildren whose parent is being closed so
  /// they slot into the closing scope at the position previously occupied by
  /// their (closing) parent. Run *before* the close itself.
  ///
  /// Edge cases worth knowing about:
  ///
  /// - When the first batch of pending grandchildren has no surviving sibling
  ///   strictly before them, [previousRank] is `null` (rather than a tab in
  ///   the parent of the scope's parent). The assigned keys are correct
  ///   relative to siblings in this scope, but in a flat-by-order_key view
  ///   (e.g. the tab bar) the promoted children may now sort before unrelated
  ///   tabs from other scopes that originally sat before the closing tab in
  ///   storage. Hierarchical views mask this via `tabsWithRootAndDepth`.
  ///
  /// - Within a scope, grandchildren are emitted in DFS order through the
  ///   closing chain (`childrenByParent[closingId]` recursively), not by raw
  ///   storage order. If a user manually reordered a grandchild to sit after
  ///   one of its uncles in storage and the uncle is also closing, the DFS
  ///   walk will re-emit them in tree order — silently overriding the manual
  ///   key. This is treated as "rebuild the scope on close".
  ///
  /// - Only `order_key` is rewritten. `parent_id` is left untouched and is
  ///   normalised lazily by the `tab_maintain_parent_chain_on_delete` trigger
  ///   when the close itself runs.
  ///
  /// - Children in a *different* ordering scope than the closing tab (another
  ///   space, folder or shelf — see [TabOrderScope]) are skipped entirely.
  ///   `order_key` is only meaningful within one scope, so slotting such a
  ///   child into the closing scope would drop a foreign rank into its list;
  ///   it is already a local root over there and keeps its place. F1 makes
  ///   this rare, but a pinned child of a normal parent is one such case.
  ///
  /// - A scope is the set of tabs *rendered* as siblings, which is not the same
  ///   as sharing a `parent_id` now that a parent may live in another space or
  ///   folder (see `scopeSiblings`). A closing tab with such a parent holds a
  ///   slot among its own scope's roots, and is grouped and anchored there.
  ///   Matching `parent_id` raw would give it a scope with no other members, so
  ///   its promoted children would rank against nothing and land at
  ///   `LexoRank.middle()` instead of in the slot it vacated.
  Future<void> preservePromotedChildOrderOnClose(Iterable<String> tabIds) {
    final closingIds = tabIds.toSet();
    if (closingIds.isEmpty) {
      return Future.value();
    }

    return db.transaction(() async {
      final closingTabs = await _tabSummaries(
        (q) => q..where(db.tab.id.isIn(closingIds)),
      ).get();

      if (closingTabs.isEmpty) {
        return;
      }

      final directChildren = await _tabSummaries(
        (q) => q
          ..where(db.tab.parentId.isIn(closingIds))
          ..orderBy([OrderingTerm.asc(db.tab.orderKey)]),
      ).get();

      final closingTabById = {for (final tab in closingTabs) tab.id: tab};
      final childrenByParent = <String, List<TabSummary>>{};
      for (final child in directChildren) {
        final parentId = child.parentId;
        if (parentId == null) continue;
        childrenByParent.putIfAbsent(parentId, () => []).add(child);
      }

      final promotedBoundaryCache = <String, List<TabSummary>>{};
      List<TabSummary> promotedBoundaryChildren(String closingTabId) {
        return promotedBoundaryCache.putIfAbsent(closingTabId, () {
          final result = <TabSummary>[];
          for (final child
              in childrenByParent[closingTabId] ?? const <TabSummary>[]) {
            if (closingIds.contains(child.id)) {
              result.addAll(promotedBoundaryChildren(child.id));
            } else {
              result.add(child);
            }
          }
          return result;
        });
      }

      // A stored parent only groups its child when both live in the same
      // space and folder. Otherwise `tabsWithRootAndDepth` draws the child as
      // a local root, and that root scope — not a scope of its own under an
      // out-of-scope parent — is the one it holds a slot in.
      final closingParentIds = {
        for (final tab in closingTabs)
          if (tab.parentId case final parentId?) parentId,
      };
      final closingParents = await _summariesById(closingParentIds);

      String? renderedParentId(TabSummary tab) {
        final parentId = tab.parentId;
        if (parentId == null) {
          return null;
        }
        final parent = closingParents[parentId];
        return parent != null &&
                parent.spaceUuid == tab.spaceUuid &&
                parent.folderId == tab.folderId
            ? parentId
            : null;
      }

      // Absorbed into the parent's pass only when that parent re-ranks this
      // tab's scope at all — a closing parent elsewhere has its promoted
      // children filtered down to its own scope, so this tab has to stand in
      // for its own scope instead of silently losing its pass.
      final representativeClosingTabs = closingTabs.where((tab) {
        final closingParent = closingTabById[tab.parentId];
        return closingParent == null ||
            TabOrderScope.forTab(closingParent) != TabOrderScope.forTab(tab);
      });

      final closingTabsByScope = groupBy(
        representativeClosingTabs,
        (TabSummary tab) =>
            (scope: TabOrderScope.forTab(tab), parentId: renderedParentId(tab)),
      );

      for (final entry in closingTabsByScope.entries) {
        final scope = entry.key;
        final scopedClosingTabs = entry.value.sorted(
          (a, b) => a.orderKey.compareTo(b.orderKey),
        );

        // Survivors are matched on the scope they *render* in, so a sibling
        // whose parent sits in another space or folder still anchors the root
        // scope it is drawn in rather than dropping out of the pass.
        final sameScopeTabs =
            await scopeSiblings(
              scope.scope,
              parentId: scope.parentId,
            ).get().then(
              (tabs) =>
                  tabs.where((tab) => !closingIds.contains(tab.id)).toList(),
            );

        var closingIndex = 0;
        var survivorIndex = 0;
        LexoRank? previousRank;
        final pendingChildren = <TabSummary>[];

        Future<void> assignPendingChildren(LexoRank? nextRank) async {
          if (pendingChildren.isEmpty) {
            return;
          }

          final orderKeys = _generateOrderKeysBetween(
            count: pendingChildren.length,
            previousRank: previousRank,
            nextRank: nextRank,
          );

          for (var i = 0; i < pendingChildren.length; i++) {
            await _updateByIdStatement(
              pendingChildren[i].id,
            ).write(TabCompanion(orderKey: Value(orderKeys[i])));
          }

          pendingChildren.clear();
        }

        while (closingIndex < scopedClosingTabs.length ||
            survivorIndex < sameScopeTabs.length) {
          final nextClosing = closingIndex < scopedClosingTabs.length
              ? scopedClosingTabs[closingIndex]
              : null;
          final nextSurvivor = survivorIndex < sameScopeTabs.length
              ? sameScopeTabs[survivorIndex]
              : null;

          final takeClosing =
              nextClosing != null &&
              (nextSurvivor == null ||
                  nextClosing.orderKey.compareTo(nextSurvivor.orderKey) < 0);

          if (takeClosing) {
            pendingChildren.addAll(
              promotedBoundaryChildren(
                nextClosing.id,
              ).where((child) => TabOrderScope.forTab(child) == scope.scope),
            );
            closingIndex++;
            continue;
          }

          final survivor = nextSurvivor!;
          final survivorRank = LexoRank.parse(survivor.orderKey);
          await assignPendingChildren(survivorRank);
          previousRank = survivorRank;
          survivorIndex++;
        }

        await assignPendingChildren(null);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Engine state mirroring
  // ---------------------------------------------------------------------------

  Future<void> touchTab(String id, {required DateTime timestamp}) {
    final statement = _updateByIdStatement(id);
    return statement.write(TabCompanion(timestamp: Value(timestamp)));
  }

  Future<void> updateTabContent(
    String id, {
    required bool isProbablyReaderable,
    required String? extractedContentMarkdown,
    required String? extractedContentPlain,
    required String? fullContentMarkdown,
    required String? fullContentPlain,
  }) async {
    final statement = _updateByIdStatement(id);

    await statement.write(
      TabCompanion(
        isProbablyReaderable: Value(isProbablyReaderable),
        extractedContentMarkdown: Value(_capContent(extractedContentMarkdown)),
        extractedContentPlain: Value(_capContent(extractedContentPlain)),
        fullContentMarkdown: Value(_capContent(fullContentMarkdown)),
        fullContentPlain: Value(_capContent(fullContentPlain)),
      ),
    );
  }

  /// Mirrors engine tab state into the rows. States are keyed by engine id,
  /// which is the row id for every live tab (DESIGN.md "D2 refinement").
  Future<void> updateTabs(
    Map<String, TabState>? previous,
    Map<String, TabState> next,
  ) {
    return db.transaction(() async {
      // Gecko exposes a parentId in content-state events, but local DB tab
      // hierarchy becomes authoritative once a row has a DB parent or has
      // been manually created/reparented. Only use Gecko parent data to seed
      // engine-event rows that have not been claimed by local hierarchy yet.
      // Keep retrying while the row remains unclaimed so out-of-order tab-list
      // inserts can seed the parent later without needing another parentId
      // change from Gecko.
      final parentSyncEligibleIds = next.isEmpty
          ? const <String>{}
          : await (() async {
              final query = selectOnly(db.tab)
                ..addColumns([db.tab.id, db.tab.source])
                ..where(db.tab.id.isIn(next.keys) & db.tab.parentId.isNull());
              return {
                for (final row in await query.get())
                  if (row.readWithConverter(db.tab.source) != TabSource.manual)
                    row.read(db.tab.id)!,
              };
            })();

      // Validate every candidate parent against the database — a parentId
      // present in `next` is not proof the row has been persisted yet (e.g.
      // engine state snapshot arriving before the matching tab-list insert).
      // Without the DB check we could write a parent_id pointing at a row
      // that does not exist, triggering the self-referential FK violation
      // and aborting the whole batch.
      final parentIdsToValidate = <String>{
        for (final state in next.values)
          if (parentSyncEligibleIds.contains(state.id) &&
              state.parentId != null)
            state.parentId!,
      };
      final existingParents = await _summariesById(parentIdsToValidate);
      final validatedParents = <String, TabSummary>{};

      // A tab's engine contextId is its container id (D3). Rows without a
      // container adopt the one the engine reports, if such a container exists.
      final containerRepairCandidates = {
        for (final state in next.values)
          if (state.contextId != null &&
              (previous?[state.id]?.contextId != state.contextId ||
                  previous?[state.id] == null))
            state.id: state.contextId!,
      };
      final currentContainerIds = containerRepairCandidates.isEmpty
          ? const <String, String?>{}
          : await getTabsContainerId(
              containerRepairCandidates.keys,
            ).get().then(Map.fromEntries);
      final knownContainerIds = await _existingContainerIds(
        containerRepairCandidates.entries
            .where((entry) => currentContainerIds[entry.key] == null)
            .map((entry) => entry.value),
      );
      final repairedContainerIds = <String, String>{
        for (final entry in containerRepairCandidates.entries)
          if (currentContainerIds[entry.key] == null &&
              knownContainerIds.contains(entry.value))
            entry.key: entry.value,
      };

      for (final state in next.values) {
        if (!parentSyncEligibleIds.contains(state.id)) {
          _pendingParentIds.remove(state.id);
          continue;
        }

        if (state.parentId == null) {
          _pendingParentIds.remove(state.id);
          continue;
        }

        final parentId = state.parentId!;
        if (parentId == state.id) {
          // A self-referential engine parent would create a hierarchy cycle.
          _pendingParentIds.remove(state.id);
          continue;
        }
        // Existence is the only gate — the parent's container is not compared
        // against the child's, see [seedParentFromEngineState].
        final parent = existingParents[parentId];
        if (parent != null) {
          validatedParents[state.id] = parent;
          _pendingParentIds.remove(state.id);
        } else {
          _pendingParentIds[state.id] = parentId;
        }
      }

      await batch((batch) {
        for (final state in next.values) {
          final previousState = previous?[state.id];
          final validatedParent = validatedParents[state.id];
          final hasContainerRepair = repairedContainerIds.containsKey(state.id);
          final hasUrlChange = previousState?.url != state.url;
          final hasTitleChange = previousState?.title != state.title;
          final hasTabModeChange = previousState?.tabMode != state.tabMode;
          final becomesPrivate =
              hasTabModeChange && state.tabMode == TabMode.private;

          if (hasUrlChange ||
              hasTitleChange ||
              hasTabModeChange ||
              validatedParent != null ||
              hasContainerRepair) {
            batch.update(
              db.tab,
              TabCompanion(
                parentId: validatedParent != null
                    ? Value(validatedParent.id)
                    : const Value.absent(),
                source: validatedParent != null
                    ? const Value(TabSource.manual)
                    : const Value.absent(),
                // F1: a seeded child joins its parent's space and folder. A
                // private tab has no space at all (I3).
                spaceUuid: becomesPrivate
                    ? const Value(null)
                    : validatedParent != null
                    ? Value(validatedParent.spaceUuid)
                    : const Value.absent(),
                folderId: becomesPrivate
                    ? const Value(null)
                    : validatedParent != null
                    ? Value(validatedParent.folderId)
                    : const Value.absent(),
                tabShelf: becomesPrivate
                    ? const Value(TabShelf.normal)
                    : const Value.absent(),
                containerId: hasContainerRepair
                    ? Value(repairedContainerIds[state.id])
                    : const Value.absent(),
                url: hasUrlChange ? Value(state.url) : const Value.absent(),
                title: hasTitleChange
                    ? Value(state.title)
                    : const Value.absent(),
                tabMode: hasTabModeChange
                    ? Value(state.tabMode.toDbValue())
                    : const Value.absent(),
              ),
              where: (t) => t.id.equals(state.id),
            );
          }
        }
      });
    });
  }

  /// Reconciles the rows with the engine's tab list after a restore or a
  /// tab-list event (PLAN §7.4 item 4, DESIGN.md "Cold tabs").
  ///
  /// - Rows with `engine_tab_id IS NULL` (cold) are never touched.
  /// - Live rows the engine no longer lists: private ones are deleted (kept in
  ///   a short undo buffer so a re-add restores the row), regular ones are
  ///   demoted to cold (`engine_tab_id = NULL`).
  /// - Engine ids without a row are inserted as live tabs on the normal shelf
  ///   of [defaultSpaceUuid], keyed before the space's first tab. A cold row
  ///   whose own id the engine lists is simply marked live again.
  Future<SyncTabsResult> syncTabs({
    required List<String> engineTabIds,
    required String? defaultSpaceUuid,
  }) {
    return db.transaction(() async {
      final engineIds = engineTabIds.toSet();

      final liveQuery = selectOnly(db.tab)
        ..addColumns([db.tab.id, db.tab.engineTabId, db.tab.tabMode])
        ..where(db.tab.engineTabId.isNotNull());
      final lostPrivate = <String>{};
      final lostRegular = <String>{};
      for (final row in await liveQuery.get()) {
        if (engineIds.contains(row.read(db.tab.engineTabId))) {
          continue;
        }
        final id = row.read(db.tab.id)!;
        if (row.readWithConverter(db.tab.tabMode) == TabModeDbValue.private) {
          lostPrivate.add(id);
        } else {
          lostRegular.add(id);
        }
      }

      var deleted = const <TabData>[];
      if (lostPrivate.isNotEmpty) {
        deleted = await (db.tab.delete()..where((t) => t.id.isIn(lostPrivate)))
            .goAndReturn();
      }
      if (deleted.isNotEmpty) {
        _clearHistoryTimer?.cancel();

        _undoHistory.addAll({for (final tab in deleted) tab.id: tab});

        _clearHistoryTimer = Timer(const Duration(seconds: 5), () {
          //Dont keep things in memory
          _undoHistory.clear();
        });
      }

      if (lostRegular.isNotEmpty) {
        await (db.tab.update()..where((t) => t.id.isIn(lostRegular))).write(
          const TabCompanion(engineTabId: Value(null)),
        );
      }

      _pendingParentIds.removeWhere(
        (childId, parentId) =>
            !engineIds.contains(childId) || !engineIds.contains(parentId),
      );

      final insertedIds = <String>{};
      if (engineIds.isNotEmpty) {
        final knownQuery = selectOnly(db.tab)
          ..addColumns([db.tab.id, db.tab.engineTabId])
          ..where(db.tab.id.isIn(engineIds));
        final knownIds = <String>{};
        final coldButListed = <String>{};
        for (final row in await knownQuery.get()) {
          final id = row.read(db.tab.id)!;
          knownIds.add(id);
          if (row.read(db.tab.engineTabId) == null) {
            coldButListed.add(id);
          }
        }
        if (coldButListed.isNotEmpty) {
          await batch((batch) {
            for (final id in coldButListed) {
              batch.update(
                db.tab,
                TabCompanion(engineTabId: Value(id)),
                where: (t) => t.id.equals(id),
              );
            }
          });
        }

        final missing = engineTabIds
            .where((id) => !knownIds.contains(id))
            .toSet();
        if (missing.isNotEmpty) {
          insertedIds.addAll(missing);
          var currentOrderKey = await leadingOrderKey(
            TabOrderScope.normal(spaceUuid: defaultSpaceUuid),
          ).getSingle();

          await db.tab.insertAll(
            missing.map((id) {
              final insertable =
                  _undoHistory[id] ??
                  TabCompanion.insert(
                    id: id,
                    engineTabId: Value(id),
                    source: TabSource.syncEvent,
                    spaceUuid: Value(defaultSpaceUuid),
                    orderKey: currentOrderKey,
                    timestamp: DateTime.now(),
                  );

              currentOrderKey = LexoRank.parse(currentOrderKey).genPrev().value;

              return insertable;
            }),
            onConflict: DoNothing(),
          );
        }
      }

      await _resolvePendingParents();

      return SyncTabsResult(
        deletedTabIds: {for (final tab in deleted) tab.id},
        demotedTabIds: lostRegular,
        insertedTabIds: insertedIds,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Search and misc
  // ---------------------------------------------------------------------------

  Selectable<TabQueryResult> queryTabs({
    required String matchPrefix,
    required String matchSuffix,
    required String ellipsis,
    required int snippetLength,
    required String searchString,
    int limit = 25,
  }) {
    final ftsQuery = db.buildFtsQuery(searchString);

    if (ftsQuery.isNotEmpty) {
      return db.definitionsDrift.queryTabsFullContent(
        query: ftsQuery,
        snippetLength: snippetLength,
        beforeMatch: matchPrefix,
        afterMatch: matchSuffix,
        ellipsis: ellipsis,
        limit: limit,
      );
    } else {
      return db.definitionsDrift.queryTabsBasic(
        query: db.buildLikeQuery(searchString),
        limit: limit,
      );
    }
  }

  /// Live tabs only — see the note on the query.
  Selectable<HistoryExclusionTabsResult> historyExclusionTabs() {
    return db.definitionsDrift.historyExclusionTabs();
  }

  Future<List<String>> getUnassignedRegularTabsOlderThan(DateTime threshold) {
    final query = selectOnly(db.tab)
      ..addColumns([db.tab.id])
      ..where(
        db.tab.containerId.isNull() &
            db.tab.timestamp.isSmallerThanValue(threshold) &
            db.tab.tabMode.equalsValue(TabModeDbValue.regular),
      );

    return query.map((row) => row.read(db.tab.id)!).get();
  }
}
