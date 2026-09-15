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
import 'package:drift/drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/container.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/projections/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_local_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';

/// Rows of `container` — a Firefox contextual identity mirrored from Zen's
/// `container` record (PLAN §6.2) — and of `container_local`, the per-container
/// settings that never sync. A container's Gecko `contextId` is its `id`
/// (DESIGN.md "D3 refinement"), so there is no separate identity mapping here.
@DriftAccessor()
class ContainerDao extends DatabaseAccessor<TabDatabase>
    with $ContainerDaoMixin {
  ContainerDao(super.db);

  Future<void> addContainer(ContainerData container) {
    return db.container.insertOne(
      ContainerCompanion.insert(
        id: container.id,
        syncGuid: Value(container.syncGuid),
        name: Value(container.name),
        iconKey: Value(container.iconKey),
        colorKey: Value(container.colorKey),
        orderKey: container.orderKey,
        isPinned: Value(container.isPinned),
      ),
    );
  }

  Future<void> replaceContainer(ContainerData container) {
    return db.container.replaceOne(
      ContainerCompanion(
        id: Value(container.id),
        syncGuid: Value(container.syncGuid),
        name: Value(container.name),
        iconKey: Value(container.iconKey),
        colorKey: Value(container.colorKey),
        orderKey: Value(container.orderKey),
        isPinned: Value(container.isPinned),
      ),
    );
  }

  Future<void> assignOrderKey(String id, {required String orderKey}) {
    return (update(db.container)..where((c) => c.id.equals(id))).write(
      ContainerCompanion(orderKey: Value(orderKey)),
    );
  }

  Future<void> assignPinned(
    String id, {
    required bool isPinned,
    required String orderKey,
  }) {
    return (update(db.container)..where((c) => c.id.equals(id))).write(
      ContainerCompanion(isPinned: Value(isPinned), orderKey: Value(orderKey)),
    );
  }

  /// `container_local` cascades; tabs get `container_id = NULL` and spaces
  /// `container_id = NULL`. Repositories close the tabs first (PLAN §7.3).
  Future<void> deleteContainer(String id) {
    return db.container.deleteOne(ContainerCompanion(id: Value(id)));
  }

  SingleOrNullSelectable<ContainerData> getContainerData(String id) {
    return select(db.container)..where((t) => t.id.equals(id));
  }

  SingleOrNullSelectable<ContainerData> getBySyncGuid(String syncGuid) {
    return select(db.container)..where((t) => t.syncGuid.equals(syncGuid));
  }

  /// Minted on first projection (PLAN §6.2), or set when the desktop's record
  /// is matched to a local container.
  Future<void> setSyncGuid(String id, String? syncGuid) {
    return (update(db.container)..where((c) => c.id.equals(id))).write(
      ContainerCompanion(syncGuid: Value(syncGuid)),
    );
  }

  Selectable<ContainerDataWithCount> containersWithCount() =>
      db.definitionsDrift.containersWithCount();

  Selectable<String> containerIdsByLastUpdated() =>
      db.definitionsDrift.containerIdsByLastUpdated();

  // --- container_local -----------------------------------------------------

  Future<void> upsertLocal(ContainerLocalData local) {
    return db.containerLocal.insertOne(
      ContainerLocalCompanion.insert(
        containerId: local.containerId,
        excludeFromIndex: Value(local.excludeFromIndex),
        excludeFromHistory: Value(local.excludeFromHistory),
        clearDataOnExit: Value(local.clearDataOnExit),
        wallpaper: Value(local.wallpaper),
      ),
      onConflict: DoUpdate(
        (_) => ContainerLocalCompanion(
          excludeFromIndex: Value(local.excludeFromIndex),
          excludeFromHistory: Value(local.excludeFromHistory),
          clearDataOnExit: Value(local.clearDataOnExit),
          wallpaper: Value(local.wallpaper),
        ),
      ),
    );
  }

  SimpleSelectStatement<ContainerLocal, ContainerLocalData> _localById(
    String containerId,
  ) =>
      select(db.containerLocal)
        ..where((l) => l.containerId.equals(containerId));

  /// A container may go a while without a `container_local` row; absent rows
  /// read as [ContainerLocalData.defaults].
  Future<ContainerLocalData> getLocal(String containerId) async {
    return await _localById(containerId).getSingleOrNull() ??
        ContainerLocalData.defaults(containerId);
  }

  Stream<ContainerLocalData> watchLocal(String containerId) {
    return _localById(containerId).watchSingleOrNull().map(
      (row) => row ?? ContainerLocalData.defaults(containerId),
    );
  }

  /// Only containers that have a row; see [getLocal] for the rest.
  Stream<List<ContainerLocalData>> watchAllLocal() =>
      select(db.containerLocal).watch();

  // --- tabs by container ---------------------------------------------------

  Selectable<String> getAllTabIds({
    bool includeRegular = true,
    bool includePrivate = true,
  }) {
    final query = selectOnly(db.tab)..addColumns([db.tab.id]);

    final excludedModes = <TabModeDbValue>[];
    if (!includeRegular) excludedModes.add(TabModeDbValue.regular);
    if (!includePrivate) excludedModes.add(TabModeDbValue.private);

    if (excludedModes.isNotEmpty) {
      query.where(db.tab.tabMode.isNotInValues(excludedModes));
    }

    return query.map((row) => row.read(db.tab.id)!);
  }

  /// Ids of every tab in [containerId] (`null` = unassigned), in `order_key`
  /// order — the same rows as `tabsInContainer`, without pulling the content
  /// columns a `SELECT *` would.
  Selectable<String> getContainerTabIds(
    String? containerId, {
    bool includeRegular = true,
    bool includePrivate = true,
  }) {
    final query = selectOnly(db.tab)
      ..addColumns([db.tab.id])
      ..where(db.tab.containerId.equalsNullable(containerId))
      ..orderBy([OrderingTerm.asc(db.tab.orderKey)]);

    final excludedModes = <TabModeDbValue>[];
    if (!includeRegular) excludedModes.add(TabModeDbValue.regular);
    if (!includePrivate) excludedModes.add(TabModeDbValue.private);

    if (excludedModes.isNotEmpty) {
      query.where(db.tab.tabMode.isNotInValues(excludedModes));
    }

    return query.map((row) => row.read(db.tab.id)!);
  }

  /// Every tab of one container, in `order_key` order.
  ///
  /// A [TabSummary] rather than a `TabData`: this is watched as a stream, so it
  /// re-runs on every write to `tab`, and no consumer reads a content column.
  Selectable<TabSummary> getContainerTabsData(String? containerId) {
    final query = selectTabSummaries(this, db.tab)
      ..where(db.tab.containerId.equalsNullable(containerId))
      ..orderBy([OrderingTerm.asc(db.tab.orderKey)]);

    return query.map((row) => readTabSummary(row, db.tab));
  }

  // --- container ordering --------------------------------------------------

  SingleSelectable<String> generateLeadingContainerOrderKey({
    required bool isPinned,
    int bucket = 0,
  }) {
    return db.definitionsDrift.leadingContainerOrderKey(
      isPinned: isPinned,
      bucket: bucket,
    );
  }

  SingleSelectable<String> generateTrailingContainerOrderKey({
    required bool isPinned,
    int bucket = 0,
  }) {
    return db.definitionsDrift.trailingContainerOrderKey(
      isPinned: isPinned,
      bucket: bucket,
    );
  }

  SingleOrNullSelectable<String> generateOrderKeyAfterContainerId(
    String containerId, {
    required bool isPinned,
  }) {
    return db.definitionsDrift.containerOrderKeyAfter(
      containerId: containerId,
      isPinned: isPinned,
    );
  }

  SingleSelectable<String> generateOrderKeyBeforeContainerId(
    String containerId, {
    required bool isPinned,
  }) {
    return db.definitionsDrift.containerOrderKeyBefore(
      containerId: containerId,
      isPinned: isPinned,
    );
  }

  // --- history / data clearing gates --------------------------------------

  /// Containers whose browsing data is wiped when the app exits. The ids are
  /// the Gecko `contextId`s to clear.
  Selectable<String> clearDataOnExitContainerIds() {
    return db.definitionsDrift.containersToClearOnExit();
  }

  /// Containers excluded from history; native's fallback before the first
  /// tab snapshot arrives.
  Selectable<String> excludedHistoryContextIds() {
    return db.definitionsDrift.excludedHistoryContextIds();
  }
}
