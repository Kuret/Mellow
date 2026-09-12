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
import 'package:lexo_rank/lexo_rank.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/scope_slot.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/spaces_sync/domain/zen_ids.dart';

part 'folder.g.dart';

/// Tab folders (Zen folders, PLAN §6.3). A folder is a slot in its parent
/// scope's child sequence next to normal tabs; deleting one closes the tabs of
/// its whole subtree through the engine first (PLAN §7.3).
@Riverpod(keepAlive: true)
class FolderRepository extends _$FolderRepository {
  Future<TabFolderData> createFolder(
    String spaceUuid, {
    String? parentFolderId,
    String name = 'Folder',
  }) async {
    final dao = ref.read(tabDatabaseProvider).tabFolderDao;
    final orderKey = await dao
        .trailingSlotKey(
          TabOrderScope.normal(spaceUuid: spaceUuid, folderId: parentFolderId),
        )
        .getSingle();
    final folder = TabFolderData(
      id: ZenIds.newGroupId(),
      name: name,
      spaceUuid: spaceUuid,
      parentFolderId: parentFolderId,
      orderKey: orderKey,
    );
    await dao.insertFolder(folder);
    return folder;
  }

  Future<TabFolderData?> getFolder(String id) {
    return ref
        .read(tabDatabaseProvider)
        .tabFolderDao
        .getById(id)
        .getSingleOrNull();
  }

  Future<void> _update(
    String id,
    TabFolderData Function(TabFolderData folder) change,
  ) async {
    final dao = ref.read(tabDatabaseProvider).tabFolderDao;
    final existing = await dao.getById(id).getSingleOrNull();
    if (existing == null) {
      throw StateError('Folder $id does not exist');
    }
    await dao.updateFolder(change(existing));
  }

  Future<void> renameFolder(String id, String name) =>
      _update(id, (folder) => folder.copyWith(name: name));

  Future<void> setFolderIcon(String id, String? icon) =>
      _update(id, (folder) => folder.copyWith(icon: icon));

  Future<void> setCollapsed(String id, bool isCollapsed) {
    return ref
        .read(tabDatabaseProvider)
        .tabFolderDao
        .setCollapsed(id, isCollapsed: isCollapsed);
  }

  /// Moves the folder (and its subtree — tabs, splits, nested folders) under
  /// [parentFolderId] in [spaceUuid], right after the slot [afterId] (a tab,
  /// folder or split id in the target scope) or at the end. Returns `false`
  /// when the target lies inside the folder's own subtree.
  Future<bool> moveFolder(
    String id, {
    required String spaceUuid,
    String? parentFolderId,
    String? afterId,
  }) async {
    final db = ref.read(tabDatabaseProvider);
    final dao = db.tabFolderDao;
    final scope = TabOrderScope.normal(
      spaceUuid: spaceUuid,
      folderId: parentFolderId,
    );
    final orderKey = await _slotKeyAfter(
      spaceUuid,
      parentFolderId,
      afterId: afterId,
      excludeId: id,
      fallback: () => dao.trailingSlotKey(scope).getSingle(),
    );
    return dao.setParent(
      id,
      spaceUuid: spaceUuid,
      parentFolderId: parentFolderId,
      orderKey: orderKey,
    );
  }

  Future<String> _slotKeyAfter(
    String spaceUuid,
    String? parentFolderId, {
    required String? afterId,
    required String excludeId,
    required Future<String> Function() fallback,
  }) async {
    if (afterId == null) {
      return fallback();
    }
    final slots =
        (await ref
                .read(tabDatabaseProvider)
                .tabDao
                .scopeChildSlots(spaceUuid, parentFolderId))
            .where((slot) => slot.id != excludeId)
            .toList();
    final index = slots.indexWhere((slot) => slot.id == afterId);
    if (index < 0) {
      return fallback();
    }
    final previous = LexoRank.parse(slots[index].orderKey);
    final ScopeSlot? next = index + 1 < slots.length ? slots[index + 1] : null;
    if (next == null) {
      return previous.genNext().value;
    }
    return previous.genBetween(LexoRank.parse(next.orderKey)).value;
  }

  /// Ids of every tab inside [folderId] or a folder nested below it.
  Future<List<String>> tabIdsInFolder(String folderId) async {
    final db = ref.read(tabDatabaseProvider);
    final subtree = await db.tabFolderDao.subtreeIds(folderId);
    if (subtree.isEmpty) {
      return const [];
    }
    final query = db.selectOnly(db.tab)
      ..addColumns([db.tab.id])
      ..where(db.tab.folderId.isIn(subtree))
      ..orderBy([OrderingTerm.asc(db.tab.orderKey)]);
    return query.map((row) => row.read(db.tab.id)!).get();
  }

  /// Recursive: tabs of nested folders count too.
  Future<int> countTabsInFolder(String folderId) async {
    return (await tabIdsInFolder(folderId)).length;
  }

  /// Closes the subtree's tabs through [TabRepository.closeTabs], then deletes
  /// the folder row; nested folders cascade (PLAN §7.3).
  Future<void> deleteFolder(String id) async {
    final tabIds = await tabIdsInFolder(id);
    if (tabIds.isNotEmpty) {
      await ref.read(tabRepositoryProvider.notifier).closeTabs(tabIds);
    }
    await ref.read(tabDatabaseProvider).tabFolderDao.deleteFolder(id);
  }

  @override
  void build() {}
}
