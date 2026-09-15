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
import 'package:mellow/features/geckoview/features/tabs/data/database/daos/space.drift.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/spaces_sync/domain/zen_ids.dart';

/// Rows of `space` (PLAN §4, §6.1). Spaces are ordered by the dense
/// `order_index`, Zen's `position` — not by LexoRank, since the desktop
/// rewrites the whole sequence on every reorder anyway.
@DriftAccessor()
class SpaceDao extends DatabaseAccessor<TabDatabase> with $SpaceDaoMixin {
  SpaceDao(super.db);

  SpaceCompanion _companion(SpaceData space) => SpaceCompanion(
    uuid: Value(space.uuid),
    name: Value(space.name),
    icon: Value(space.icon),
    theme: Value(space.theme),
    containerId: Value(space.containerId),
    orderIndex: Value(space.orderIndex),
  );

  Future<void> insertSpace(SpaceData space) =>
      db.space.insertOne(_companion(space));

  /// Full-row replace keyed on `uuid`.
  Future<void> updateSpace(SpaceData space) =>
      db.space.replaceOne(_companion(space));

  /// Folders and splits cascade; tabs get `space_uuid = NULL` (DESIGN.md
  /// "Schema v19"). Repositories close or move the tabs first.
  Future<void> deleteSpace(String uuid) =>
      (db.space.delete()..where((s) => s.uuid.equals(uuid))).go();

  SingleOrNullSelectable<SpaceData> getByUuid(String uuid) =>
      db.space.select()..where((s) => s.uuid.equals(uuid));

  SimpleSelectStatement<Space, SpaceData> _allOrdered() =>
      db.space.select()..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]);

  Future<List<SpaceData>> getAll() => _allOrdered().get();

  Stream<List<SpaceData>> watchAll() => _allOrdered().watch();

  /// Rewrites `order_index` as 0..n-1 in the order of [uuids]. Spaces not
  /// listed keep their index; callers pass the complete list.
  Future<void> reorder(List<String> uuids) {
    return db.transaction(() async {
      await batch((batch) {
        for (var i = 0; i < uuids.length; i++) {
          batch.update(
            db.space,
            SpaceCompanion(orderIndex: Value(i)),
            where: (s) => s.uuid.equals(uuids[i]),
          );
        }
      });
    });
  }

  Future<int> count() async {
    final query = selectOnly(db.space)..addColumns([db.space.uuid.count()]);
    return (await query
            .map((row) => row.read(db.space.uuid.count()))
            .getSingle()) ??
        0;
  }

  /// The first space by `order_index`, creating an unnamed one when the table
  /// is empty. Regular tabs need a space (I2), so this is what a fresh profile
  /// and `TabDao.assignSpaceToOrphans` fall back to.
  Future<SpaceData> getOrCreateDefault() {
    return db.transaction(() async {
      final existing = await (_allOrdered()..limit(1)).getSingleOrNull();
      if (existing != null) {
        return existing;
      }
      final created = SpaceData(
        uuid: ZenIds.newSpaceUuid(),
        name: '',
        orderIndex: 0,
      );
      await insertSpace(created);
      return created;
    });
  }

  Future<void> setContainer(String uuid, String? containerId) =>
      (db.space.update()..where((s) => s.uuid.equals(uuid))).write(
        SpaceCompanion(containerId: Value(containerId)),
      );
}
