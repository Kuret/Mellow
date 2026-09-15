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
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/core/uuid.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_local_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/firefox_container_vocab.dart';
import 'package:weblibre/features/spaces_sync/domain/zen_ids.dart';

part 'container.g.dart';

/// Containers are Firefox contextual identities (PLAN §6.2). A container's
/// Gecko `contextId` is its `id` (DESIGN.md "D3 refinement"); the per-device
/// settings live in `container_local` and are reached via [getLocal] /
/// [setLocal] / [watchLocal].
@Riverpod(keepAlive: true)
class ContainerRepository extends _$ContainerRepository {
  /// The Gecko cookie-jar id handed to the engine for tabs of [container].
  static String contextIdFor(ContainerData container) => container.id;

  Future<void> addContainer(ContainerData container) {
    if (container.orderKey.isEmpty) {
      throw ArgumentError.value(
        container.orderKey,
        'container.orderKey',
        'Containers require an explicit order key',
      );
    }
    return ref.read(tabDatabaseProvider).containerDao.addContainer(container);
  }

  Future<List<ContainerDataWithCount>> getAllContainersWithCount() {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .containersWithCount()
        .get();
  }

  Future<void> replaceContainer(ContainerData container) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .replaceContainer(container);
  }

  Future<void> assignContainerOrderKey(String id, {required String orderKey}) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .assignOrderKey(id, orderKey: orderKey);
  }

  Future<void> setContainerPinned(String id, {required bool isPinned}) async {
    final orderKey = await getTrailingContainerOrderKey(isPinned: isPinned);
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .assignPinned(id, isPinned: isPinned, orderKey: orderKey);
  }

  Future<ContainerData?> getContainerData(String id) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .getContainerData(id)
        .getSingleOrNull();
  }

  /// A container's Gecko `contextId` is its id (DESIGN.md "D3 refinement"),
  /// so this is [getContainerData] under the name the intent and share paths
  /// know it by.
  Future<ContainerData?> getContainerByContextualIdentity(String contextId) =>
      getContainerData(contextId);

  /// Always null: per-site container assignment was removed along with
  /// container strict mode. Kept as the seam callers already null-check
  /// rather than editing every call site's fallback path.
  Future<String?> siteAssignedContainerId(Uri uri) async => null;

  Future<ContainerData?> getBySyncGuid(String syncGuid) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .getBySyncGuid(syncGuid)
        .getSingleOrNull();
  }

  /// The local container mirroring one of Firefox's four built-in identities
  /// (`builtin-1..4`), created on first sight with the enum's name, icon and
  /// colour (DESIGN.md "D3 refinement: Built-ins").
  Future<ContainerData> getOrCreateBuiltin(String guid) async {
    final builtin = FirefoxBuiltinContainer.fromSyncGuid(guid);
    if (builtin == null) {
      throw ArgumentError.value(guid, 'guid', 'Not a builtin container guid');
    }
    final existing = await getBySyncGuid(guid);
    if (existing != null) {
      return existing;
    }
    final orderKey = await getTrailingContainerOrderKey(isPinned: false);
    final created = ContainerData(
      id: uuid.v7(),
      syncGuid: guid,
      name: builtin.name,
      iconKey: builtin.icon.keyword,
      colorKey: builtin.color.keyword,
      orderKey: orderKey,
    );
    await addContainer(created);
    return created;
  }

  /// The container's Zen guid, minted once on first projection (PLAN §6.2)
  /// and kept for good.
  Future<String> ensureSyncGuid(String id) async {
    final container = await getContainerData(id);
    if (container == null) {
      throw StateError('Container $id does not exist');
    }
    final existing = container.syncGuid;
    if (existing != null) {
      return existing;
    }
    final guid = ZenIds.newContainerGuid();
    await ref.read(tabDatabaseProvider).containerDao.setSyncGuid(id, guid);
    return guid;
  }

  Future<List<String>> getContainerTabIds(String? id) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .getContainerTabIds(id)
        .get();
  }

  /// Closes the container's tabs through the engine first (PLAN §7.3), then
  /// drops the row; `container_local` cascades, and spaces pointing at it get
  /// `container_id = NULL`.
  Future<void> deleteContainer(String id) async {
    final db = ref.read(tabDatabaseProvider);
    final syncGuid = (await getContainerData(id))?.syncGuid;
    await ref.read(tabDataRepositoryProvider.notifier).closeContainerTabs(id);
    await db.containerDao.deleteContainer(id);
    // Built-ins are never projected as container records, so there is
    // nothing to tombstone for them.
    if (syncGuid != null && !ZenIds.isBuiltinContainerGuid(syncGuid)) {
      await db.syncStateDao.recordDeletion(syncGuid, 'container');
    }
  }

  // --- container_local -----------------------------------------------------

  /// Defaults when the container has no `container_local` row yet.
  Future<ContainerLocalData> getLocal(String containerId) {
    return ref.read(tabDatabaseProvider).containerDao.getLocal(containerId);
  }

  Future<void> setLocal(ContainerLocalData local) {
    return ref.read(tabDatabaseProvider).containerDao.upsertLocal(local);
  }

  Stream<ContainerLocalData> watchLocal(String containerId) {
    return ref.read(tabDatabaseProvider).containerDao.watchLocal(containerId);
  }

  // --- container ordering --------------------------------------------------

  Future<String> getLeadingContainerOrderKey({required bool isPinned}) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .generateLeadingContainerOrderKey(isPinned: isPinned)
        .getSingle();
  }

  Future<String> getTrailingContainerOrderKey({required bool isPinned}) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .generateTrailingContainerOrderKey(isPinned: isPinned)
        .getSingle();
  }

  Future<String?> getOrderKeyAfterContainer(
    String containerId, {
    required bool isPinned,
  }) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .generateOrderKeyAfterContainerId(containerId, isPinned: isPinned)
        .getSingleOrNull();
  }

  Future<String> getOrderKeyBeforeContainer(
    String containerId, {
    required bool isPinned,
  }) {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .generateOrderKeyBeforeContainerId(containerId, isPinned: isPinned)
        .getSingle();
  }

  Future<void> reorderContainer(
    List<ContainerData> containers,
    int oldIndex,
    int newIndex,
  ) async {
    if (containers.isEmpty || oldIndex == newIndex) return;

    final targetIndex = newIndex.clamp(0, containers.length - 1);
    if (targetIndex == oldIndex) return;

    final movingContainer = containers[oldIndex];
    final scopedContainers = containers
        .where((container) => container.isPinned == movingContainer.isPinned)
        .toList();
    final scopedOldIndex = scopedContainers.indexWhere(
      (container) => container.id == movingContainer.id,
    );
    if (scopedOldIndex < 0) return;

    final containersWithoutMoving = containers.toList()..removeAt(oldIndex);
    final scopedTargetIndex = containersWithoutMoving
        .take(targetIndex)
        .where((container) => container.isPinned == movingContainer.isPinned)
        .length
        .clamp(0, scopedContainers.length - 1);
    if (scopedTargetIndex == scopedOldIndex) return;

    // Generate a new order key and assign it in the same transaction so a
    // crash between the two cannot leave the moving container with a stale
    // key that no longer matches the surrounding rows.
    final db = ref.read(tabDatabaseProvider);
    await db.transaction(() async {
      final orderKey = await _orderKeyForReorder(
        scopedContainers,
        scopedOldIndex,
        scopedTargetIndex,
        movingContainer.isPinned,
      );
      await db.containerDao.assignOrderKey(
        movingContainer.id,
        orderKey: orderKey,
      );
    });
  }

  Future<String> _orderKeyForReorder(
    List<ContainerData> containers,
    int oldIndex,
    int targetIndex,
    bool isPinned,
  ) async {
    if (targetIndex <= 0) {
      return getLeadingContainerOrderKey(isPinned: isPinned);
    }
    if (targetIndex >= containers.length - 1) {
      return getTrailingContainerOrderKey(isPinned: isPinned);
    }
    if (targetIndex < oldIndex) {
      return await getOrderKeyAfterContainer(
            containers[targetIndex - 1].id,
            isPinned: isPinned,
          ) ??
          await getLeadingContainerOrderKey(isPinned: isPinned);
    }
    return getOrderKeyBeforeContainer(
      containers[targetIndex + 1].id,
      isPinned: isPinned,
    );
  }

  /// A fresh, unsaved container with a colour not yet in use where possible.
  Future<ContainerData> createNewContainer() async {
    final used = (await getAllContainersWithCount())
        .map((container) => container.color)
        .toSet();
    const pool = FirefoxContainerColor.values;
    final candidates = pool
        .where((color) => color != FirefoxContainerColor.toolbar)
        .toList();
    final unused = candidates.where((color) => !used.contains(color)).toList();
    final choice = (unused.isNotEmpty ? unused : candidates).first;
    final orderKey = await getTrailingContainerOrderKey(isPinned: false);
    return ContainerData(
      id: uuid.v7(),
      colorKey: choice.keyword,
      orderKey: orderKey,
    );
  }

  /// Ids of the containers whose browsing data is wiped on exit. Each id is
  /// the Gecko `contextId` to clear.
  Future<List<String>> getContainersToClearOnExit() {
    return ref
        .read(tabDatabaseProvider)
        .containerDao
        .clearDataOnExitContainerIds()
        .get();
  }

  @override
  void build() {}
}
