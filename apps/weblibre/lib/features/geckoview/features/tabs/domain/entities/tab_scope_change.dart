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

/// How a reorder should affect the moving block's `(space_uuid, folder_id)`
/// (PLAN §6.6). [TabScopeChange.unchanged] keeps the current values; a
/// [TabScopeChange.toScope] rewrites them for every tab in the moving block.
sealed class TabScopeChange {
  const TabScopeChange();

  const factory TabScopeChange.unchanged() = TabScopeUnchanged;

  const factory TabScopeChange.toScope({
    required String? spaceUuid,
    required String? folderId,
  }) = TabScopeToSpecific;
}

final class TabScopeUnchanged extends TabScopeChange {
  const TabScopeUnchanged();
}

final class TabScopeToSpecific extends TabScopeChange {
  final String? spaceUuid;
  final String? folderId;

  const TabScopeToSpecific({required this.spaceUuid, required this.folderId});
}
