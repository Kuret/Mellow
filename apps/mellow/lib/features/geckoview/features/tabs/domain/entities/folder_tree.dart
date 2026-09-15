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
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_folder_data.dart';

/// One row of a flattened folder tree, as a picker or the rail would draw it:
/// depth-first, siblings ordered by [TabFolderData.orderKey], each row
/// carrying its own nesting [depth] and the chain of ancestor names above it.
class FolderTreeRow with FastEquatable {
  final TabFolderData folder;

  /// 0 for a root folder, 1 for its direct children, and so on.
  final int depth;

  /// The names of every ancestor, root first, joined with " › ". Empty for a
  /// root folder. Two folders with the same name are only distinguishable by
  /// this path when indentation alone is not enough (off-screen, long names,
  /// a narrow picker).
  final String path;

  FolderTreeRow({
    required this.folder,
    required this.depth,
    required this.path,
  });

  @override
  List<Object?> get hashParameters => [folder, depth, path];
}

/// Turns [folders] — the flat, single-space list [watchFoldersProvider]
/// returns — into an ordered, depth-first list of [FolderTreeRow]s: the same
/// shape the rail's nesting implies, with every folder's ancestor path
/// alongside it so same-named folders under different parents are never
/// ambiguous.
///
/// A folder whose [TabFolderData.parentFolderId] does not resolve to another
/// folder in [folders] (a missing/foreign id, or a cycle) is treated as a
/// root rather than dropped, so no folder silently disappears from the
/// picker.
List<FolderTreeRow> buildFolderTree(List<TabFolderData> folders) {
  final byId = {for (final folder in folders) folder.id: folder};

  final byParent = <String?, List<TabFolderData>>{};
  for (final folder in folders) {
    final parentId = byId.containsKey(folder.parentFolderId)
        ? folder.parentFolderId
        : null;
    byParent.putIfAbsent(parentId, () => []).add(folder);
  }
  for (final siblings in byParent.values) {
    siblings.sort((a, b) => a.orderKey.compareTo(b.orderKey));
  }

  final rows = <FolderTreeRow>[];
  final visited = <String>{};

  void visit(String? parentId, int depth, String path) {
    for (final folder in byParent[parentId] ?? const <TabFolderData>[]) {
      if (!visited.add(folder.id)) {
        // A cycle in parentFolderId; stop rather than recurse forever.
        continue;
      }
      rows.add(FolderTreeRow(folder: folder, depth: depth, path: path));
      final childPath = path.isEmpty ? folder.name : '$path › ${folder.name}';
      visit(folder.id, depth + 1, childPath);
    }
  }

  visit(null, 0, '');
  return rows;
}
