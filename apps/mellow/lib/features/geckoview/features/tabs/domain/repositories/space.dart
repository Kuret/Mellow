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
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/spaces_sync/domain/zen_ids.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'space.g.dart';

/// Spaces (Zen workspaces, PLAN §6.3). Regular tabs always live in one (I2);
/// deleting a space closes its tabs through the engine first (PLAN §7.3).
@Riverpod(keepAlive: true)
class SpaceRepository extends _$SpaceRepository {
  Future<SpaceData> createSpace({
    String name = '',
    String? containerId,
    String? icon,
  }) async {
    final dao = ref.read(tabDatabaseProvider).spaceDao;
    final space = SpaceData(
      uuid: ZenIds.newSpaceUuid(),
      name: name,
      icon: icon,
      containerId: containerId,
      orderIndex: await dao.count(),
    );
    await dao.insertSpace(space);
    return space;
  }

  Future<SpaceData?> getSpace(String uuid) {
    return ref
        .read(tabDatabaseProvider)
        .spaceDao
        .getByUuid(uuid)
        .getSingleOrNull();
  }

  Future<List<SpaceData>> getAllSpaces() {
    return ref.read(tabDatabaseProvider).spaceDao.getAll();
  }

  Future<void> _update(
    String uuid,
    SpaceData Function(SpaceData space) change,
  ) async {
    final dao = ref.read(tabDatabaseProvider).spaceDao;
    final existing = await dao.getByUuid(uuid).getSingleOrNull();
    if (existing == null) {
      throw StateError('Space $uuid does not exist');
    }
    await dao.updateSpace(change(existing));
  }

  Future<void> renameSpace(String uuid, String name) =>
      _update(uuid, (space) => space.copyWith(name: name));

  Future<void> setSpaceIcon(String uuid, String? icon) =>
      _update(uuid, (space) => space.copyWith(icon: icon));

  Future<void> setSpaceContainer(String uuid, String? containerId) {
    return ref
        .read(tabDatabaseProvider)
        .spaceDao
        .setContainer(uuid, containerId);
  }

  /// [uuids] is the complete new order; `order_index` becomes 0..n-1.
  Future<void> reorderSpaces(List<String> uuids) {
    return ref.read(tabDatabaseProvider).spaceDao.reorder(uuids);
  }

  /// Tabs on the pinned and normal shelves of [uuid], folders included.
  /// Essentials have no space, so they never count.
  Future<int> countTabsInSpace(String uuid) async {
    final tabs = await ref
        .read(tabDatabaseProvider)
        .tabDao
        .getSpaceTabsData(uuid)
        .get();
    return tabs.length;
  }

  /// Refuses (with a [StateError]) to delete the last space. Closes the
  /// space's tabs through [TabRepository.closeTabs] before the row goes —
  /// never via the FK (PLAN §7.3); folders and splits then cascade.
  Future<void> deleteSpace(String uuid) async {
    final db = ref.read(tabDatabaseProvider);
    if (await db.spaceDao.count() <= 1) {
      throw StateError('The last space cannot be deleted');
    }
    final tabs = await db.tabDao.getSpaceTabsData(uuid).get();
    final tabIds = [for (final tab in tabs) tab.id];
    if (tabIds.isNotEmpty) {
      await ref.read(tabRepositoryProvider.notifier).closeTabs(tabIds);
    }
    await db.spaceDao.deleteSpace(uuid);
    await db.syncStateDao.recordDeletion(uuid, 'space');
  }

  /// The first space, created when none exists; regular tabs without a space
  /// are then adopted into it.
  Future<SpaceData> ensureDefaultSpace() async {
    final db = ref.read(tabDatabaseProvider);
    final space = await db.spaceDao.getOrCreateDefault();
    await db.tabDao.assignSpaceToOrphans(space.uuid);
    return space;
  }

  @override
  void build() {}
}
