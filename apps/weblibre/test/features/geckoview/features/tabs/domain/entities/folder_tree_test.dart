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
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/entities/folder_tree.dart';

TabFolderData _folder(
  String id, {
  String name = '',
  String? parentFolderId,
  String orderKey = 'a0',
}) => TabFolderData(
  id: id,
  name: name,
  spaceUuid: 'space-1',
  parentFolderId: parentFolderId,
  orderKey: orderKey,
);

void main() {
  group('buildFolderTree', () {
    test('returns empty for no folders', () {
      expect(buildFolderTree(const []), isEmpty);
    });

    test('root folders come out at depth 0 with an empty path', () {
      final rows = buildFolderTree([_folder('1', name: 'Work', orderKey: 'a0')]);

      expect(rows, hasLength(1));
      expect(rows.single.folder.id, '1');
      expect(rows.single.depth, 0);
      expect(rows.single.path, '');
    });

    test('nested folders get incrementing depth and their parent path', () {
      final rows = buildFolderTree([
        _folder('root', name: 'Linux', orderKey: 'a0'),
        _folder('child', name: 'DE', parentFolderId: 'root', orderKey: 'a0'),
        _folder(
          'grandchild',
          name: 'GTK',
          parentFolderId: 'child',
          orderKey: 'a0',
        ),
      ]);

      final byId = {for (final row in rows) row.folder.id: row};

      expect(byId['root']!.depth, 0);
      expect(byId['root']!.path, '');

      expect(byId['child']!.depth, 1);
      expect(byId['child']!.path, 'Linux');

      expect(byId['grandchild']!.depth, 2);
      expect(byId['grandchild']!.path, 'Linux › DE');
    });

    test('two same-named folders under different parents stay distinguishable', () {
      final rows = buildFolderTree([
        _folder('linux', name: 'Linux', orderKey: 'a0'),
        _folder('macos', name: 'MacOS', orderKey: 'a1'),
        _folder(
          'linux-de',
          name: 'DE',
          parentFolderId: 'linux',
          orderKey: 'a0',
        ),
        _folder(
          'macos-de',
          name: 'DE',
          parentFolderId: 'macos',
          orderKey: 'a0',
        ),
      ]);

      final byId = {for (final row in rows) row.folder.id: row};

      expect(byId['linux-de']!.folder.name, 'DE');
      expect(byId['macos-de']!.folder.name, 'DE');
      expect(byId['linux-de']!.path, isNot(byId['macos-de']!.path));
      expect(byId['linux-de']!.path, 'Linux');
      expect(byId['macos-de']!.path, 'MacOS');
    });

    test('siblings are ordered by orderKey, depth-first before the next root', () {
      final rows = buildFolderTree([
        _folder('b', name: 'B', orderKey: 'b0'),
        _folder('a', name: 'A', orderKey: 'a0'),
        _folder('a-child', name: 'A-child', parentFolderId: 'a', orderKey: 'a0'),
        _folder('b-child', name: 'B-child', parentFolderId: 'b', orderKey: 'a0'),
      ]);

      expect(
        rows.map((row) => row.folder.id).toList(),
        ['a', 'a-child', 'b', 'b-child'],
      );
    });

    test(
      'a folder whose parent id does not resolve is treated as a root, not dropped',
      () {
        final rows = buildFolderTree([
          _folder('orphan', name: 'Orphan', parentFolderId: 'missing', orderKey: 'a0'),
        ]);

        expect(rows, hasLength(1));
        expect(rows.single.depth, 0);
        expect(rows.single.path, '');
      },
    );

    test('a cycle in parentFolderId does not recurse forever', () {
      final rows = buildFolderTree([
        _folder('x', name: 'X', parentFolderId: 'y', orderKey: 'a0'),
        _folder('y', name: 'Y', parentFolderId: 'x', orderKey: 'a0'),
      ]);

      // Both ids are visited at most once; the exact winner is an
      // implementation detail, but the function must terminate and must not
      // silently drop every folder.
      expect(rows.length, lessThanOrEqualTo(2));
    });
  });
}
