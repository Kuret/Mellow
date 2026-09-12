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
/// Outcome of `TabDao.syncTabs` (DESIGN.md "Cold tabs").
class SyncTabsResult {
  /// Private rows whose engine session is gone; the rows were deleted.
  final Set<String> deletedTabIds;

  /// Regular rows whose engine session is gone; `engine_tab_id` was cleared
  /// and the rows stay as cold tabs.
  final Set<String> demotedTabIds;

  /// Engine tabs that had no row yet; rows were created for them.
  final Set<String> insertedTabIds;

  const SyncTabsResult({
    required this.deletedTabIds,
    required this.demotedTabIds,
    required this.insertedTabIds,
  });

  static const empty = SyncTabsResult(
    deletedTabIds: {},
    demotedTabIds: {},
    insertedTabIds: {},
  );
}
