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
import 'package:mellow/features/geckoview/features/tabs/data/database/daos/tab_split.drift.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_split_data.dart';

/// What [TabSplitDao.removeMember] did to the split the tab was in.
class SplitRemovalResult {
  final String splitId;

  /// Fewer than two members remained, so the split row was deleted and the
  /// [survivorTabId] (if any) became a plain tab again.
  final bool dissolved;
  final String? survivorTabId;

  const SplitRemovalResult({
    required this.splitId,
    required this.dissolved,
    required this.survivorTabId,
  });
}

/// Rows of `tab_split` (PLAN §6.5). A split is a slot in its scope's child
/// sequence; its members are `tab` rows with `split_id` set and a dense
/// `split_index` 0..n-1 (I5).
@DriftAccessor()
class TabSplitDao extends DatabaseAccessor<TabDatabase> with $TabSplitDaoMixin {
  TabSplitDao(super.db);

  TabSplitCompanion _companion(TabSplitData split) => TabSplitCompanion(
    id: Value(split.id),
    gridType: Value(split.gridType),
    isPinned: Value(split.isPinned),
    spaceUuid: Value(split.spaceUuid),
    folderId: Value(split.folderId),
    orderKey: Value(split.orderKey),
  );

  Future<void> insertSplit(TabSplitData split) =>
      db.tabSplit.insertOne(_companion(split));

  /// Full-row replace keyed on `id`.
  Future<void> updateSplit(TabSplitData split) =>
      db.tabSplit.replaceOne(_companion(split));

  /// Members keep their rows; `split_id` is nulled by the FK and
  /// `split_index` is cleared here so no stale index survives.
  Future<void> deleteSplit(String id) {
    return db.transaction(() async {
      await (db.tab.update()..where((t) => t.splitId.equals(id))).write(
        const TabCompanion(splitId: Value(null), splitIndex: Value(null)),
      );
      await (db.tabSplit.delete()..where((s) => s.id.equals(id))).go();
    });
  }

  SingleOrNullSelectable<TabSplitData> getById(String id) =>
      db.tabSplit.select()..where((s) => s.id.equals(id));

  /// Member tab ids in `split_index` order.
  Future<List<String>> members(String splitId) async {
    final rows = await db.definitionsDrift.splitMembers(splitId: splitId).get();
    return [for (final row in rows) row.id];
  }

  /// Makes [tabIds] (in order) the members of [splitId]: writes `split_id`
  /// and a dense `split_index`, clears both on former members not listed, and
  /// gives every member the split's `space_uuid`/`folder_id` (I5).
  Future<void> setMembers(String splitId, List<String> tabIds) {
    return db.transaction(() async {
      final split = await getById(splitId).getSingleOrNull();
      if (split == null) {
        return;
      }
      final keep = tabIds.toSet();
      final leaving = db.tab.update()..where((t) => t.splitId.equals(splitId));
      if (keep.isNotEmpty) {
        leaving.where((t) => t.id.isNotIn(keep));
      }
      await leaving.write(
        const TabCompanion(splitId: Value(null), splitIndex: Value(null)),
      );
      await batch((batch) {
        for (var i = 0; i < tabIds.length; i++) {
          batch.update(
            db.tab,
            TabCompanion(
              splitId: Value(splitId),
              splitIndex: Value(i),
              spaceUuid: Value(split.spaceUuid),
              folderId: Value(split.folderId),
            ),
            where: (t) => t.id.equals(tabIds[i]),
          );
        }
      });
    });
  }

  /// Takes [tabId] out of its split, re-indexing the remaining members. With
  /// fewer than two left the split is dissolved: the survivor's split fields
  /// are nulled and the split row deleted. Returns `null` when [tabId] was not
  /// a split member.
  Future<SplitRemovalResult?> removeMember(String tabId) {
    return db.transaction(() async {
      final splitIdQuery = selectOnly(db.tab)
        ..addColumns([db.tab.splitId])
        ..where(db.tab.id.equals(tabId));
      final splitId = await splitIdQuery
          .map((row) => row.read(db.tab.splitId))
          .getSingleOrNull();
      if (splitId == null) {
        return null;
      }

      await (db.tab.update()..where((t) => t.id.equals(tabId))).write(
        const TabCompanion(splitId: Value(null), splitIndex: Value(null)),
      );

      final remaining = await members(splitId);
      if (remaining.length < 2) {
        final survivor = remaining.singleOrNull;
        await deleteSplit(splitId);
        // A user-driven dissolve: the sync client may tombstone the split.
        await db.syncStateDao.recordDeletion(splitId, 'split');
        return SplitRemovalResult(
          splitId: splitId,
          dissolved: true,
          survivorTabId: survivor,
        );
      }

      await batch((batch) {
        for (var i = 0; i < remaining.length; i++) {
          batch.update(
            db.tab,
            TabCompanion(splitIndex: Value(i)),
            where: (t) => t.id.equals(remaining[i]),
          );
        }
      });
      return SplitRemovalResult(
        splitId: splitId,
        dissolved: false,
        survivorTabId: null,
      );
    });
  }

  /// Splits whose slot lies in `(spaceUuid, folderId)`, in `order_key` order.
  Selectable<TabSplitData> inScope(String? spaceUuid, String? folderId) => db
      .definitionsDrift
      .splitsInScope(spaceUuid: spaceUuid, folderId: folderId);

  Stream<List<TabSplitData>> watchAllInSpace(String? spaceUuid) =>
      (db.tabSplit.select()
            ..where((s) => s.spaceUuid.equalsNullable(spaceUuid))
            ..orderBy([(s) => OrderingTerm.asc(s.orderKey)]))
          .watch();
}
