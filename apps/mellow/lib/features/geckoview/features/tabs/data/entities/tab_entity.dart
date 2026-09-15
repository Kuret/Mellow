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
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';

sealed class TabEntity with FastEquatable {
  String get tabId;
  String get orderKey;
}

class DefaultTabEntity extends TabEntity {
  @override
  final String tabId;
  @override
  final String orderKey;
  final String? containerId;

  DefaultTabEntity({
    required this.tabId,
    required this.orderKey,
    required this.containerId,
  });

  @override
  List<Object?> get hashParameters => [tabId, orderKey, containerId];
}

class SearchResultTabEntity extends TabEntity {
  @override
  final String tabId;
  @override
  final String orderKey;
  final String? containerId;

  final String searchQuery;

  SearchResultTabEntity({
    required this.tabId,
    required this.orderKey,
    required this.searchQuery,
    required this.containerId,
  });

  @override
  List<Object?> get hashParameters => [
    tabId,
    orderKey,
    searchQuery,
    containerId,
  ];
}

/// Sealed type for items rendered in the grouped flat list/grid views.
///
/// Distinct from [TabEntity] which serves the original flat-only path. The
/// grouped variant carries enough information to render folders (PLAN §6.6)
/// while keeping a single ordered top-level list. Items are scoped by space
/// rather than container.
sealed class TabListItemEntity with FastEquatable {
  String get orderKey;
  String? get spaceUuid;

  /// Nesting depth from the space root: +1 per enclosing folder. `0` marks a
  /// row at the space root.
  int get depth;
}

/// A tab occupying a slot in its scope's child sequence (as opposed to a
/// folder).
class TabListTabItem extends TabListItemEntity {
  final String tabId;
  @override
  final String orderKey;
  @override
  final String? spaceUuid;

  /// Folder nesting depth: 0 at the space root, +1 per enclosing folder.
  @override
  final int depth;

  /// The shelf the row sits on (PLAN §6.4). Essentials never appear in a
  /// list, so this is [TabShelf.pinned] or [TabShelf.normal]; the surfaces
  /// use it to draw the pinned section apart from the main list.
  final TabShelf shelf;

  TabListTabItem({
    required this.tabId,
    required this.orderKey,
    required this.spaceUuid,
    this.depth = 0,
    this.shelf = TabShelf.normal,
  });

  @override
  List<Object?> get hashParameters => [
    tabId,
    orderKey,
    spaceUuid,
    depth,
    shelf,
  ];
}

/// A folder occupying a slot in its scope's child sequence (PLAN §6.6).
/// [depth] is the folder nesting depth from the space root; [childCount] is
/// the number of direct children (tabs, folders and splits) it holds.
class TabListFolderItem extends TabListItemEntity {
  final String folderId;
  @override
  final String orderKey;
  @override
  final String? spaceUuid;
  final String name;
  final bool isCollapsed;
  @override
  final int depth;
  final int childCount;

  TabListFolderItem({
    required this.folderId,
    required this.orderKey,
    required this.spaceUuid,
    required this.name,
    required this.isCollapsed,
    required this.depth,
    required this.childCount,
  });

  @override
  List<Object?> get hashParameters => [
    folderId,
    orderKey,
    spaceUuid,
    name,
    isCollapsed,
    depth,
    childCount,
  ];
}
