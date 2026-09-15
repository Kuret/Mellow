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
import 'package:mellow/features/geckoview/features/tabs/data/database/daos/tab_folder.drift.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_folder_data.dart';

/// Rows of `tab_folder` (PLAN §4, §6.1). A folder occupies a slot in its
/// parent scope's child sequence, ranked by `order_key` alongside normal tabs
/// and splits (`scopeChildSlots`).
@DriftAccessor()
class TabFolderDao extends DatabaseAccessor<TabDatabase>
    with $TabFolderDaoMixin {
  TabFolderDao(super.db);

  TabFolderCompanion _companion(TabFolderData folder) => TabFolderCompanion(
    id: Value(folder.id),
    name: Value(folder.name),
    icon: Value(folder.icon),
    spaceUuid: Value(folder.spaceUuid),
    parentFolderId: Value(folder.parentFolderId),
    live: Value(folder.live),
    isCollapsed: Value(folder.isCollapsed),
    orderKey: Value(folder.orderKey),
  );

  Future<void> insertFolder(TabFolderData folder) =>
      db.tabFolder.insertOne(_companion(folder));

  /// Full-row replace keyed on `id`.
  Future<void> updateFolder(TabFolderData folder) =>
      db.tabFolder.replaceOne(_companion(folder));

  /// Nested folders cascade; tabs and splits inside get `folder_id = NULL`
  /// (PLAN §7.3). Repositories close the tabs first.
  Future<void> deleteFolder(String id) =>
      (db.tabFolder.delete()..where((f) => f.id.equals(id))).go();

  SingleOrNullSelectable<TabFolderData> getById(String id) =>
      db.tabFolder.select()..where((f) => f.id.equals(id));

  /// Direct child folders of [parentFolderId] (`null` = the space root) in
  /// `order_key` order.
  Selectable<TabFolderData> children(
    String? spaceUuid, {
    required String? parentFolderId,
  }) => db.definitionsDrift.folderChildren(
    spaceUuid: spaceUuid,
    parentFolderId: parentFolderId,
  );

  /// [folderId] and every folder nested below it, in no particular order.
  Future<Set<String>> subtreeIds(String folderId) async {
    final ids = await db.definitionsDrift
        .folderSubtreeIds(folderId: folderId)
        .get();
    return ids.toSet();
  }

  Stream<List<TabFolderData>> watchInSpace(String? spaceUuid) =>
      (db.tabFolder.select()
            ..where((f) => f.spaceUuid.equalsNullable(spaceUuid))
            ..orderBy([(f) => OrderingTerm.asc(f.orderKey)]))
          .watch();

  Future<void> setCollapsed(String folderId, {required bool isCollapsed}) =>
      (db.tabFolder.update()..where((f) => f.id.equals(folderId))).write(
        TabFolderCompanion(isCollapsed: Value(isCollapsed)),
      );

  /// Moves [folderId] under [parentFolderId] in [spaceUuid] at [orderKey].
  ///
  /// Cascades `space_uuid` through the folder subtree (I4) and through the
  /// tabs and splits that live in any of those folders — a tab's `space_uuid`
  /// is derived from its folder's, and the `tab_child_follows_parent_scope`
  /// trigger only covers the tab→tab parent link. Returns `false` when the
  /// move would nest the folder inside itself.
  Future<bool> setParent(
    String folderId, {
    required String? spaceUuid,
    required String? parentFolderId,
    required String orderKey,
  }) {
    return db.transaction(() async {
      final subtree = await subtreeIds(folderId);
      if (subtree.isEmpty) {
        return false;
      }
      if (parentFolderId != null && subtree.contains(parentFolderId)) {
        return false;
      }

      await (db.tabFolder.update()..where((f) => f.id.equals(folderId))).write(
        TabFolderCompanion(
          spaceUuid: Value(spaceUuid),
          parentFolderId: Value(parentFolderId),
          orderKey: Value(orderKey),
        ),
      );
      final nested = subtree.where((id) => id != folderId).toList();
      if (nested.isNotEmpty) {
        await (db.tabFolder.update()..where((f) => f.id.isIn(nested))).write(
          TabFolderCompanion(spaceUuid: Value(spaceUuid)),
        );
      }
      await (db.tab.update()..where((t) => t.folderId.isIn(subtree))).write(
        TabCompanion(spaceUuid: Value(spaceUuid)),
      );
      await (db.tabSplit.update()..where((s) => s.folderId.isIn(subtree)))
          .write(TabSplitCompanion(spaceUuid: Value(spaceUuid)));
      return true;
    });
  }

  /// A key after every slot (tab, folder, split) in [scope], for appending a
  /// folder or split to a scope's child sequence. Bucket 0, as tabs use.
  SingleSelectable<String> trailingSlotKey(TabOrderScope scope) =>
      db.definitionsDrift.scopeTrailingSlotKey(
        spaceUuid: scope.spaceUuid,
        folderId: scope.folderId,
        tabShelf: scope.shelf.index,
        bucket: 0,
      );

  /// A key before every slot in [scope]; see [trailingSlotKey].
  SingleSelectable<String> leadingSlotKey(TabOrderScope scope) =>
      db.definitionsDrift.scopeLeadingSlotKey(
        spaceUuid: scope.spaceUuid,
        folderId: scope.folderId,
        tabShelf: scope.shelf.index,
        bucket: 0,
      );
}
