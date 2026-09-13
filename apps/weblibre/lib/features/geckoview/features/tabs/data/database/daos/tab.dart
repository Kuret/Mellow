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
import 'package:weblibre/features/geckoview/features/tabs/domain/entities/tab_scope_change.dart';

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
@DriftAccessor()
class TabDao extends DatabaseAccessor<TabDatabase> with $TabDaoMixin {
  final _undoHistory = <String, TabData>{};
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

  /// Live regular tabs on the normal shelf, least recently used first: the
  /// order in which [LiveTabBudget] unloads tabs back to cold rows. Pinned and
  /// essential tabs are never candidates; the caller drops the selected one.
  Selectable<TabSummary> liveDemotionCandidates() => _tabSummaries(
    (q) => q
      ..where(
        db.tab.engineTabId.isNotNull() &
            db.tab.tabMode.equalsValue(TabModeDbValue.regular) &
            db.tab.tabShelf.equalsValue(TabShelf.normal),
      )
      ..orderBy([
        OrderingTerm.asc(db.tab.timestamp),
        OrderingTerm.asc(db.tab.id),
      ]),
  );

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

  /// The tabs of [scope], in `order_key` order.
  Selectable<ScopeSiblingsResult> scopeSiblings(TabOrderScope scope) =>
      db.definitionsDrift.scopeSiblings(
        spaceUuid: scope.spaceUuid,
        folderId: scope.folderId,
        tabShelf: scope.shelf.index,
        scopeContainerId: scope.containerId,
      );

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

  /// The ordered child sequence of `(spaceUuid, folderId)`, Zen's
  /// `#childSequence`: the pinned section first — pinned tabs, folders and
  /// pinned splits interleaved by `order_key` — then normal tabs and splits
  /// by `order_key`. Split members and essentials are not slots (PLAN §6.5,
  /// §6.6).
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
          shelf: TabShelf.values[folder.shelf],
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

  // ---------------------------------------------------------------------------
  // Inserts
  // ---------------------------------------------------------------------------

  Future<String> _generateOrderKey({
    required TabOrderScope scope,
    Value<String?> afterTabId = const Value.absent(),
  }) async {
    if (afterTabId.present && afterTabId.value != null) {
      final key = await orderKeyAfterTab(
        afterTabId.value!,
        scope: scope,
      ).getSingleOrNull();
      if (key != null) {
        return key;
      }
    }

    // Everything else appends to the end of the scope's list.
    return trailingOrderKey(scope).getSingle();
  }

  /// Where a new tab ranks and which `space_uuid`/`folder_id` it gets.
  ///
  /// Private tabs have no space (I3) and essentials have neither space nor
  /// folder (I1); everything else takes the caller's values.
  /// `async` on purpose even though nothing here awaits: the two insert
  /// paths call this from inside their transaction right after the engine
  /// round-trip, and the await keeps the microtask that the engine's tab-list
  /// event schedules (`syncTabs`) running while that transaction is still
  /// open rather than after it has committed.
  Future<TabOrderScope> _resolveInsertScope({
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
  /// refinement"). [spaceUuid] is ignored for private tabs and essentials —
  /// see [_resolveInsertScope].
  Future<String> upsertTabTransactional(
    Future<String> Function() createTab, {
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
        spaceUuid: spaceUuid,
        folderId: folderId,
        containerId: containerId,
        shelf: shelf,
        tabMode: tabMode,
      );
      final currentOrderKey =
          orderKey.value ??
          await _generateOrderKey(scope: scope, afterTabId: afterTabId);
      final Value<TabModeDbValue> persistedTabMode = tabMode.present
          ? Value(tabMode.value.toDbValue())
          : const Value.absent();

      await db.tab.insertOne(
        TabCompanion.insert(
          id: tabId,
          engineTabId: Value(tabId),
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
        spaceUuid: spaceUuid,
        folderId: folderId,
        containerId: containerId,
        shelf: shelf,
        tabMode: tabMode,
      );
      final currentOrderKey =
          orderKey.value ??
          await _generateOrderKey(scope: scope, afterTabId: afterTabId);
      final Value<TabModeDbValue> persistedTabMode = tabMode.present
          ? Value(tabMode.value.toDbValue())
          : const Value.absent();

      await db.tab.insertOne(
        TabCompanion.insert(
          id: tabId,
          engineTabId: Value(tabId),
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
            containerId: containerId,
            spaceUuid: spaceUuid.present
                ? Value(scope.spaceUuid)
                : const Value.absent(),
            folderId: folderId.present
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

  /// Re-keys [movingTabIds] — one block in storage order — between
  /// [previousTabId] and [nextTabId].
  ///
  /// [scopeChange] rewrites `space_uuid`/`folder_id` for the whole block.
  Future<void> reorderTabs({
    required List<String> movingTabIds,
    required String? previousTabId,
    required String? nextTabId,
    TabScopeChange scopeChange = const TabScopeChange.unchanged(),
  }) {
    if (movingTabIds.isEmpty) {
      return Future.value();
    }

    return db.transaction(() async {
      final anchors = await _summariesById([
        if (previousTabId != null) previousTabId,
        if (nextTabId != null) nextTabId,
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

      final (spaceValue, folderValue) = switch (scopeChange) {
        TabScopeUnchanged() => (
          const Value<String?>.absent(),
          const Value<String?>.absent(),
        ),
        TabScopeToSpecific(:final spaceUuid, :final folderId) => (
          Value<String?>(spaceUuid),
          Value<String?>(folderId),
        ),
      };

      await batch((batch) {
        for (var i = 0; i < movingTabIds.length; i++) {
          batch.update(
            db.tab,
            TabCompanion(
              orderKey: Value(orderKeys[i]),
              spaceUuid: spaceValue,
              folderId: folderValue,
            ),
            where: (t) => t.id.equals(movingTabIds[i]),
          );
        }
      });
    });
  }

  /// Moves [tabId] one slot up (or down) within its ordering scope.
  ///
  /// Returns `false` when the tab is unknown or already at the relevant
  /// end of its scope's list.
  Future<bool> moveTabAmongSiblings(String tabId, {required bool down}) {
    // Transactional so the sibling-list read and the anchor lookup observe
    // the same DB snapshot. `reorderTabs` opens a nested savepoint
    // internally, which is fine.
    return db.transaction(() async {
      final tab = await getTabSummaryById(tabId).getSingleOrNull();
      if (tab == null) {
        return false;
      }
      final scope = TabOrderScope.forTab(tab);

      final siblingIds = await scopeSiblings(
        scope,
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

      await reorderTabs(
        movingTabIds: [tabId],
        previousTabId: previousIdx >= 0 ? reorderedIds[previousIdx] : null,
        nextTabId: nextIdx < reorderedIds.length ? reorderedIds[nextIdx] : null,
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

      final orderKey = await trailingOrderKey(target).getSingle();
      await _updateByIdStatement(tabId).write(
        TabCompanion(
          tabShelf: Value(shelf),
          orderKey: Value(orderKey),
          spaceUuid: Value(isEssential ? null : target.spaceUuid),
          folderId: Value(isEssential ? null : target.folderId),
          splitId: isEssential ? const Value(null) : const Value.absent(),
          splitIndex: isEssential ? const Value(null) : const Value.absent(),
          source: isEssential
              ? const Value(TabSource.manual)
              : const Value.absent(),
        ),
      );

      return true;
    });
  }

  /// Moves [rootTabIds] into [target], placing the block after [afterId] or
  /// before [beforeId] (both in [target]), or at the end when neither is
  /// given. Every tab in the block takes [target]'s shelf, `space_uuid` and
  /// `folder_id`.
  ///
  /// A tab that is a split member brings every member of that split along,
  /// and the split row moves with them (I5). An essential [target] is handled
  /// per tab by [setShelf].
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
          blockIds.addAll(await db.tabSplitDao.members(splitId));
        } else {
          blockIds.add(rootId);
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
        final anchor = await getTabSummaryById(afterId).getSingleOrNull();
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
          batch.update(
            db.tab,
            TabCompanion(
              orderKey: Value(orderKeys[i]),
              tabShelf: Value(target.shelf),
              spaceUuid: Value(target.spaceUuid),
              folderId: Value(target.folderId),
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

      await batch((batch) {
        for (final state in next.values) {
          final previousState = previous?[state.id];
          final hasContainerRepair = repairedContainerIds.containsKey(state.id);
          final hasUrlChange = previousState?.url != state.url;
          final hasTitleChange = previousState?.title != state.title;
          final hasTabModeChange = previousState?.tabMode != state.tabMode;
          final becomesPrivate =
              hasTabModeChange && state.tabMode == TabMode.private;

          if (hasUrlChange ||
              hasTitleChange ||
              hasTabModeChange ||
              hasContainerRepair) {
            batch.update(
              db.tab,
              TabCompanion(
                // A private tab has no space at all (I3).
                spaceUuid: becomesPrivate
                    ? const Value(null)
                    : const Value.absent(),
                folderId: becomesPrivate
                    ? const Value(null)
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
  /// - Live rows the engine no longer lists: private ones and the ones in
  ///   [closingTabIds] (the repository asked the engine to close them) are
  ///   deleted (kept in a short undo buffer so a re-add restores the row);
  ///   the remaining regular ones are demoted to cold (`engine_tab_id =
  ///   NULL`) and reported as [SyncTabsResult.demotedTabIds].
  /// - Engine ids without a row are inserted as live tabs on the normal shelf
  ///   of [defaultSpaceUuid], keyed before the space's first tab. A cold row
  ///   whose own id the engine lists is simply marked live again.
  Future<SyncTabsResult> syncTabs({
    required List<String> engineTabIds,
    required String? defaultSpaceUuid,
    Set<String> closingTabIds = const {},
  }) {
    return db.transaction(() async {
      final engineIds = engineTabIds.toSet();
      // A session whose row an applied sync batch already deleted is on its
      // way out; reconciling against it would re-insert the row as a brand
      // new tab and resurrect what the remote deleted.
      final queuedForClose = await pendingEngineCloseIds();
      engineIds.removeAll(queuedForClose);

      final liveQuery = selectOnly(db.tab)
        ..addColumns([db.tab.id, db.tab.engineTabId, db.tab.tabMode])
        ..where(db.tab.engineTabId.isNotNull());
      final lostClosed = <String>{};
      final lostRegular = <String>{};
      for (final row in await liveQuery.get()) {
        if (engineIds.contains(row.read(db.tab.engineTabId))) {
          continue;
        }
        final id = row.read(db.tab.id)!;
        if (closingTabIds.contains(id) ||
            row.readWithConverter(db.tab.tabMode) == TabModeDbValue.private) {
          lostClosed.add(id);
        } else {
          lostRegular.add(id);
        }
      }

      var deleted = const <TabData>[];
      if (lostClosed.isNotEmpty) {
        deleted = await (db.tab.delete()..where((t) => t.id.isIn(lostClosed)))
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

        final missing = engineIds.where((id) => !knownIds.contains(id)).toSet();
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

  // ---------------------------------------------------------------------------
  // Zen spaces sync (PLAN §8)
  // ---------------------------------------------------------------------------

  /// How many tabs the projection would emit: the denominator the upload
  /// canary measures a batch's deletions against.
  ///
  /// Mirrors `SpacesProjection._regularTabs` + `_isSyncable`: regular
  /// (non-private) tabs with a real URL, essential or filed in a space.
  Future<int> countSyncableTabs() {
    final t = db.tab;
    final count = t.id.count();
    final query = selectOnly(t)
      ..addColumns([count])
      ..where(
        t.tabMode.equalsValue(TabModeDbValue.regular) &
            t.url.isNotNull() &
            t.url.isNotValue('') &
            t.url.isNotValue('about:blank') &
            (t.tabShelf.equalsValue(TabShelf.essential) |
                t.spaceUuid.isNotNull()),
      );
    return query.map((row) => row.read(count)!).getSingle();
  }

  /// Of [tabIds], the ones the projection could ever have uploaded.
  ///
  /// A private tab never leaves the device (I3), so noting its close in the
  /// deletion ledger would only put an id on the wire that no record ever
  /// carried.
  Future<List<String>> syncableTabIdsAmong(Iterable<String> tabIds) {
    final ids = tabIds.toSet();
    if (ids.isEmpty) {
      return Future.value(const <String>[]);
    }
    final t = db.tab;
    final query = selectOnly(t)
      ..addColumns([t.id])
      ..where(t.id.isIn(ids) & t.tabMode.equalsValue(TabModeDbValue.regular));
    return query.map((row) => row.read(t.id)!).get();
  }

  /// Deletes the rows a remote Zen tombstone removed, in the caller's
  /// transaction.
  ///
  /// The applier cannot go through [TabRepository.closeTabsFromSync] any
  /// more: the whole batch commits atomically, and awaiting a platform
  /// channel inside a database transaction is not allowed. So the row goes
  /// here, and a row that still holds an engine session queues a
  /// `pending_engine_close` for the drain that runs once the transaction has
  /// committed. No `closed_tab_tombstone` is written — a remote deletion is
  /// not a local one and must not be echoed back (PLAN §8.6 item 5).
  Future<void> deleteTabsFromSync(Iterable<String> tabIds) {
    final ids = tabIds.toSet();
    if (ids.isEmpty) {
      return Future.value();
    }
    return db.transaction(() async {
      final engineIdQuery = selectOnly(db.tab)
        ..addColumns([db.tab.engineTabId])
        ..where(db.tab.id.isIn(ids) & db.tab.engineTabId.isNotNull());
      final engineTabIds = await engineIdQuery
          .map((row) => row.read(db.tab.engineTabId)!)
          .get();
      if (engineTabIds.isNotEmpty) {
        final requestedAt = DateTime.now();
        await batch((batch) {
          for (final engineTabId in engineTabIds) {
            batch.insert(
              db.pendingEngineClose,
              PendingEngineCloseCompanion.insert(
                engineTabId: engineTabId,
                requestedAt: requestedAt,
              ),
              onConflict: DoUpdate(
                (_) => PendingEngineCloseCompanion(
                  requestedAt: Value(requestedAt),
                ),
              ),
            );
          }
        });
      }

      await (db.tab.delete()..where((t) => t.id.isIn(ids))).go();
    });
  }

  /// The engine sessions an applied batch left behind, oldest first.
  Future<List<String>> pendingEngineCloseIds() async {
    final rows =
        await (db.pendingEngineClose.select()
              ..orderBy([(t) => OrderingTerm.asc(t.requestedAt)]))
            .get();
    return [for (final row in rows) row.engineTabId];
  }

  Future<void> deletePendingEngineCloses(Iterable<String> engineTabIds) {
    final ids = engineTabIds.toSet();
    if (ids.isEmpty) {
      return Future.value();
    }
    return (db.pendingEngineClose.delete()
          ..where((t) => t.engineTabId.isIn(ids)))
        .go();
  }

  /// Every `closed_tab_tombstone.tab_id`: the proof a tab was closed by the
  /// user, which is what lets the sync client project a tombstone for it.
  Selectable<String> allClosedTabTombstoneIds() {
    final query = selectOnly(db.closedTabTombstone)
      ..addColumns([db.closedTabTombstone.tabId]);
    return query.map((row) => row.read(db.closedTabTombstone.tabId)!);
  }

  TabOrderScope _scopeForSyncRow({
    required TabShelf shelf,
    required String? spaceUuid,
    required String? folderId,
    required String? containerId,
  }) => switch (shelf) {
    TabShelf.essential => TabOrderScope.essential(containerId),
    // A folder member ranks in its folder on the pinned shelf (Zen keeps
    // folders in the pinned section); a pinned tab without a folder is in
    // the space's flat pinned section. The applier resolves a space before
    // it gets here (I2), so `spaceUuid` is only nullable for the type.
    TabShelf.pinned || TabShelf.normal => TabOrderScope(
      spaceUuid: spaceUuid,
      folderId: folderId,
      shelf: shelf,
      containerId: null,
    ),
  };

  /// Inserts the row for a tab that arrived through sync: no engine session
  /// (`engine_tab_id` NULL, PLAN §7.4) and the record's identity fields.
  /// Essentials get no space or folder (I1); a pinned tab keeps its
  /// [folderId] since folder members are pinned. Without [orderKey] the tab
  /// is appended to its scope.
  Future<void> insertColdTab({
    required String id,
    required Uri? url,
    required String? title,
    required String? iconUrl,
    required String? containerId,
    required String? spaceUuid,
    required String? folderId,
    required TabShelf shelf,
    required String? staticLabel,
    required bool hasStaticIcon,
    required bool defaultContainer,
    String? orderKey,
  }) {
    return db.transaction(() async {
      final isEssential = shelf == TabShelf.essential;
      final scopeSpace = isEssential ? null : spaceUuid;
      final scopeFolder = isEssential ? null : folderId;
      final scope = _scopeForSyncRow(
        shelf: shelf,
        spaceUuid: scopeSpace,
        folderId: scopeFolder,
        containerId: containerId,
      );
      final key = orderKey ?? await trailingOrderKey(scope).getSingle();
      await db.tab.insertOne(
        TabCompanion.insert(
          id: id,
          engineTabId: const Value(null),
          source: TabSource.manual,
          containerId: Value(containerId),
          spaceUuid: Value(scopeSpace),
          folderId: Value(scopeFolder),
          tabShelf: Value(shelf),
          orderKey: key,
          url: Value(url),
          title: Value(title),
          iconUrl: Value(iconUrl),
          staticLabel: Value(staticLabel),
          hasStaticIcon: Value(hasStaticIcon),
          defaultContainer: Value(defaultContainer),
          tabMode: const Value(TabModeDbValue.regular),
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  /// Writes the identity fields a Zen `tab` record carries onto an existing
  /// row. Placement (shelf, space, folder, order) is handled by [moveToScope];
  /// the container is a plain column write here because a cookie-jar change
  /// only takes effect when the tab is next materialised.
  Future<void> updateTabFromSync(
    String id, {
    Value<Uri?> url = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> iconUrl = const Value.absent(),
    Value<String?> containerId = const Value.absent(),
    Value<String?> staticLabel = const Value.absent(),
    Value<bool> hasStaticIcon = const Value.absent(),
    Value<bool> defaultContainer = const Value.absent(),
  }) => _updateByIdStatement(id).write(
    TabCompanion(
      url: url,
      title: title,
      iconUrl: iconUrl,
      containerId: containerId,
      staticLabel: staticLabel,
      hasStaticIcon: hasStaticIcon,
      defaultContainer: defaultContainer,
    ),
  );

  /// Re-keys the slots of [scope] so [orderedIds] come first, in that order,
  /// followed by the scope's remaining slots in their current relative order.
  /// An id may name a tab, a folder or a split; ids not in the scope are
  /// ignored. Mirrors Zen's `#applyOrdering` for a space's / folder's
  /// `children` array and the layout's `essentials` lists (PLAN §6.6).
  ///
  /// For a space or folder scope this covers both the pinned and the normal
  /// shelf: they are separate ordering scopes, so one ascending key sequence
  /// across both keeps every shelf's relative order correct.
  Future<void> applyScopeOrder(TabOrderScope scope, List<String> orderedIds) {
    return db.transaction(() async {
      final List<String> current;
      if (scope.isEssential) {
        current = await essentialTabIds(scope.containerId).get();
      } else {
        final slots = await scopeChildSlots(scope.spaceUuid, scope.folderId);
        current = [for (final slot in slots) slot.id];
      }
      final inScope = current.toSet();
      final listed = <String>[];
      final seen = <String>{};
      for (final id in orderedIds) {
        if (inScope.contains(id) && seen.add(id)) {
          listed.add(id);
        }
      }
      final rest = [
        for (final id in current)
          if (!seen.contains(id)) id,
      ];
      final sequence = [...listed, ...rest];
      if (sequence.isEmpty) {
        return;
      }

      var rank = LexoRank.middle();
      await batch((batch) {
        for (final id in sequence) {
          final key = rank.value;
          rank = rank.genNext();
          batch.update(
            db.tab,
            TabCompanion(orderKey: Value(key)),
            where: (t) => t.id.equals(id),
          );
          batch.update(
            db.tabFolder,
            TabFolderCompanion(orderKey: Value(key)),
            where: (f) => f.id.equals(id),
          );
          batch.update(
            db.tabSplit,
            TabSplitCompanion(orderKey: Value(key)),
            where: (s) => s.id.equals(id),
          );
        }
      });
    });
  }
}
