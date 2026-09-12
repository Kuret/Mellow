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
import 'package:fast_equatable/fast_equatable.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';

/// The set of tabs a tab's `order_key` is ranked against (PLAN §6.6,
/// DESIGN.md "Ordering scope").
///
/// - normal / pinned: `(space_uuid, folder_id, shelf)`; [containerId] unused.
/// - essential: `(NULL, NULL, essential, container_id)` — the per-container
///   strip (PLAN §6.4).
/// - private: `(NULL, NULL, normal)`; private tabs never have a space.
///
/// Every scoped SQL query in `definitions.drift` takes these four values and
/// uses the predicate
/// `space_uuid IS :space AND folder_id IS :folder AND tab_shelf = :shelf AND
/// (:shelf != 2 OR container_id IS :container)`.
class TabOrderScope with FastEquatable {
  final String? spaceUuid;
  final String? folderId;
  final TabShelf shelf;

  /// Only meaningful for [TabShelf.essential]; `null` otherwise.
  final String? containerId;

  // Not `const`: the FastEquatable mixin carries a mutable cached-hash field.
  TabOrderScope({
    required this.spaceUuid,
    required this.folderId,
    required this.shelf,
    required this.containerId,
  });

  TabOrderScope.normal({required this.spaceUuid, this.folderId})
    : shelf = TabShelf.normal,
      containerId = null;

  TabOrderScope.pinned(String this.spaceUuid)
    : folderId = null,
      shelf = TabShelf.pinned,
      containerId = null;

  TabOrderScope.essential(this.containerId)
    : spaceUuid = null,
      folderId = null,
      shelf = TabShelf.essential;

  TabOrderScope.private()
    : spaceUuid = null,
      folderId = null,
      shelf = TabShelf.normal,
      containerId = null;

  /// The scope [tab] currently ranks in.
  factory TabOrderScope.forTab(TabSummary tab) {
    if (tab.tabShelf == TabShelf.essential) {
      return TabOrderScope.essential(tab.containerId);
    }
    if (tab.tabMode == TabModeDbValue.private) {
      return TabOrderScope.private();
    }
    return TabOrderScope(
      spaceUuid: tab.spaceUuid,
      folderId: tab.folderId,
      shelf: tab.tabShelf,
      containerId: null,
    );
  }

  bool get isEssential => shelf == TabShelf.essential;

  /// The same `(space_uuid, folder_id)` slot sequence with another shelf.
  TabOrderScope withShelf(TabShelf shelf) => TabOrderScope(
    spaceUuid: spaceUuid,
    folderId: folderId,
    shelf: shelf,
    containerId: containerId,
  );

  /// Whether [other] shares this scope's `(space_uuid, folder_id)` — the
  /// F1 boundary (PLAN §6.6), which ignores the shelf.
  bool sameSpaceAndFolder(TabOrderScope other) =>
      spaceUuid == other.spaceUuid && folderId == other.folderId;

  @override
  List<Object?> get hashParameters => [spaceUuid, folderId, shelf, containerId];

  @override
  String toString() =>
      'TabOrderScope(space: $spaceUuid, folder: $folderId, shelf: ${shelf.name}'
      '${isEssential ? ', container: $containerId' : ''})';
}
