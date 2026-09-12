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
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_entity.dart';

/// Render-time descriptor for one item in the local tabs list/grid.
///
/// Unifies the search/flat path and the grouped path so list and grid can
/// share reorder semantics.
///
/// Folder rows are represented as a [TabViewItem] variant too
/// ([FolderTabViewItem]) rather than out-of-band, so list/grid/reorder code
/// can walk a single flat `List<TabViewItem>`. Folders have no engine tab
/// behind them, so [tabId] is deliberately repurposed to return the
/// folder's id (see [isFolder]) instead of making the base [tabId] nullable,
/// which would force every existing (non-folder) call site to null-check.
/// Callers that need a real tab id must check [isFolder] first and use
/// [folderItem] for folder-specific data.
sealed class TabViewItem {
  String get tabId;
  String? get sourceSearchQuery;
  TabListParentGroup? get parentGroup;
  TabListChildItem? get childItem;
  TabListFolderItem? get folderItem;

  bool get isFolder => folderItem != null;

  /// Folder nesting depth for indentation. Standalone/parent rows carry the
  /// folder depth (0 at the space root); child rows already fold the folder
  /// depth into their own tree depth; folder rows carry their own depth.
  int get depth => 0;

  const TabViewItem._();

  const factory TabViewItem.search({
    required String tabId,
    required String? sourceSearchQuery,
  }) = SearchTabViewItem;

  const factory TabViewItem.standalone({required String tabId, int depth}) =
      StandaloneTabViewItem;

  const factory TabViewItem.parent({
    required String tabId,
    required TabListParentGroup parentGroup,
  }) = ParentTabViewItem;

  const factory TabViewItem.child({
    required String tabId,
    required TabListChildItem childItem,
  }) = ChildTabViewItem;

  const factory TabViewItem.folder({required TabListFolderItem folderItem}) =
      FolderTabViewItem;
}

class SearchTabViewItem extends TabViewItem {
  @override
  final String tabId;
  @override
  final String? sourceSearchQuery;

  @override
  TabListParentGroup? get parentGroup => null;

  @override
  TabListChildItem? get childItem => null;

  @override
  TabListFolderItem? get folderItem => null;

  const SearchTabViewItem({
    required this.tabId,
    required this.sourceSearchQuery,
  }) : super._();
}

class StandaloneTabViewItem extends TabViewItem {
  @override
  final String tabId;
  @override
  final int depth;

  @override
  String? get sourceSearchQuery => null;

  @override
  TabListParentGroup? get parentGroup => null;

  @override
  TabListChildItem? get childItem => null;

  @override
  TabListFolderItem? get folderItem => null;

  const StandaloneTabViewItem({required this.tabId, this.depth = 0})
    : super._();
}

class ParentTabViewItem extends TabViewItem {
  @override
  final String tabId;
  @override
  final TabListParentGroup parentGroup;

  @override
  String? get sourceSearchQuery => null;

  @override
  TabListChildItem? get childItem => null;

  @override
  TabListFolderItem? get folderItem => null;

  @override
  int get depth => parentGroup.depth;

  const ParentTabViewItem({required this.tabId, required this.parentGroup})
    : super._();
}

class ChildTabViewItem extends TabViewItem {
  @override
  final String tabId;
  @override
  final TabListChildItem childItem;

  @override
  String? get sourceSearchQuery => null;

  @override
  TabListParentGroup? get parentGroup => null;

  @override
  TabListFolderItem? get folderItem => null;

  @override
  int get depth => childItem.depth;

  const ChildTabViewItem({required this.tabId, required this.childItem})
    : super._();
}

class FolderTabViewItem extends TabViewItem {
  @override
  final TabListFolderItem folderItem;

  @override
  String get tabId => folderItem.folderId;

  @override
  String? get sourceSearchQuery => null;

  @override
  TabListParentGroup? get parentGroup => null;

  @override
  TabListChildItem? get childItem => null;

  @override
  int get depth => folderItem.depth;

  const FolderTabViewItem({required this.folderItem}) : super._();
}
