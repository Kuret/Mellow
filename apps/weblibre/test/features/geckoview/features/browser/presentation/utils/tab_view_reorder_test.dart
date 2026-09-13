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
import 'package:weblibre/features/geckoview/features/browser/presentation/utils/tab_view_reorder.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/tab_view/tab_view_item.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_entity.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/entities/tab_parent_change.dart';

// [TabScopeToSpecific] has no value equality, so a direct `==` comparison
// against a runtime-constructed instance (as opposed to the same `const`
// literal) always fails on identity. Compare the fields instead.
Matcher scopedTo({required String? spaceUuid, required String? folderId}) =>
    isA<TabScopeToSpecific>()
        .having((change) => change.spaceUuid, 'spaceUuid', spaceUuid)
        .having((change) => change.folderId, 'folderId', folderId);

void main() {
  TabViewReorderResult? build({
    required List<TabViewItem> visibleItems,
    required int oldIndex,
    required int newIndex,
    bool hierarchical = false,
    Map<String, String?> folderIdByTab = const {},
    Map<String, List<String>> splitMembers = const {},
    Set<String> pinnedTabIds = const {},
    Set<String> collapsedGroups = const {},
    String? spaceUuid,
  }) {
    return buildTabViewReorderResult(
      visibleItems: visibleItems,
      treeRows: const [],
      collapsedGroups: collapsedGroups,
      pinnedTabIds: pinnedTabIds,
      oldIndex: oldIndex,
      newIndex: newIndex,
      hierarchical: hierarchical,
      sortPinnedFirst: false,
      folderIdByTab: folderIdByTab,
      splitMembers: splitMembers,
      spaceUuid: spaceUuid,
    );
  }

  // `newIndex` follows the app's reorderable surfaces: it is the slot in the
  // list *after* the moving item has been taken out (post-removal), so moving
  // the first of three items to the end is `oldIndex: 0, newIndex: 2` and
  // placing it between the other two is `newIndex: 1`.
  group('buildTabViewReorderResult (flat)', () {
    test('plain reorder moves a single tab between its new neighbours', () {
      final items = [
        const TabViewItem.standalone(tabId: 'a'),
        const TabViewItem.standalone(tabId: 'b'),
        const TabViewItem.standalone(tabId: 'c'),
      ];

      final result = build(visibleItems: items, oldIndex: 0, newIndex: 1);

      expect(result, isNotNull);
      expect(result!.movingTabIds, ['a']);
      expect(result.previousTabId, 'b');
      expect(result.nextTabId, 'c');
      expect(result.scopeChange, const TabScopeChange.unchanged());
    });

    test('refuses to move a folder row', () {
      final items = [
        TabViewItem.folder(
          folderItem: TabListFolderItem(
            folderId: 'f1',
            orderKey: 'a',
            spaceUuid: 'space',
            name: 'Folder',
            isCollapsed: false,
            depth: 0,
            childCount: 0,
          ),
        ),
        const TabViewItem.standalone(tabId: 'a'),
      ];

      final result = build(visibleItems: items, oldIndex: 0, newIndex: 1);

      expect(result, isNull);
    });

    test('dropping a tab between two tabs of the same folder scopes to it', () {
      final items = [
        const TabViewItem.standalone(tabId: 'x'),
        const TabViewItem.standalone(tabId: 'a'),
        const TabViewItem.standalone(tabId: 'b'),
      ];

      final result = build(
        visibleItems: items,
        oldIndex: 0,
        newIndex: 2,
        folderIdByTab: const {'a': 'f1', 'b': 'f1', 'x': null},
        spaceUuid: 'space-1',
      );

      expect(result, isNotNull);
      expect(
        result!.scopeChange,
        scopedTo(spaceUuid: 'space-1', folderId: 'f1'),
      );
    });

    test('dropping directly under a folder row scopes into that folder', () {
      final folderItem = TabListFolderItem(
        folderId: 'f1',
        orderKey: 'a',
        spaceUuid: 'space-1',
        name: 'Folder',
        isCollapsed: false,
        depth: 0,
        childCount: 0,
      );
      final items = [
        TabViewItem.folder(folderItem: folderItem),
        const TabViewItem.standalone(tabId: 'x'),
      ];

      final result = build(
        visibleItems: items,
        oldIndex: 1,
        newIndex: 1,
        folderIdByTab: const {'x': null},
        spaceUuid: 'space-1',
      );

      expect(result, isNotNull);
      expect(
        result!.scopeChange,
        scopedTo(spaceUuid: 'space-1', folderId: 'f1'),
      );
    });

    test('dropping back at the root reports a scope change away from a '
        'folder', () {
      final items = [
        const TabViewItem.standalone(tabId: 'a'),
        const TabViewItem.standalone(tabId: 'x'),
      ];

      final result = build(
        visibleItems: items,
        oldIndex: 1,
        newIndex: 0,
        folderIdByTab: const {'x': 'f1', 'a': null},
        spaceUuid: 'space-1',
      );

      expect(result, isNotNull);
      expect(
        result!.scopeChange,
        scopedTo(spaceUuid: 'space-1', folderId: null),
      );
    });

    test('dragging a split member brings its siblings along in order', () {
      final items = [
        const TabViewItem.standalone(tabId: 'a'),
        const TabViewItem.standalone(tabId: 'b'),
        const TabViewItem.standalone(tabId: 'split-1'),
        const TabViewItem.standalone(tabId: 'split-2'),
        const TabViewItem.standalone(tabId: 'c'),
      ];

      final result = build(
        visibleItems: items,
        oldIndex: 0,
        newIndex: 3,
        splitMembers: const {
          'split-1': ['split-1', 'split-2'],
          'split-2': ['split-1', 'split-2'],
        },
      );

      expect(result, isNotNull);
      expect(result!.movingTabIds, ['a']);
      // 'a' has no split partners, so only itself moves.
      expect(result.previousTabId, 'split-2');
      expect(result.nextTabId, 'c');
    });

    test('dragging the primary split member moves every sibling with it', () {
      final items = [
        const TabViewItem.standalone(tabId: 'split-1'),
        const TabViewItem.standalone(tabId: 'split-2'),
        const TabViewItem.standalone(tabId: 'a'),
        const TabViewItem.standalone(tabId: 'b'),
      ];

      final result = build(
        visibleItems: items,
        oldIndex: 0,
        newIndex: 2,
        splitMembers: const {
          'split-1': ['split-1', 'split-2'],
          'split-2': ['split-1', 'split-2'],
        },
      );

      expect(result, isNotNull);
      expect(result!.movingTabIds, ['split-1', 'split-2']);
      expect(result.previousTabId, 'a');
      expect(result.nextTabId, 'b');
    });
  });

  group('buildTabViewReorderResult (hierarchical)', () {
    test('drop-into-folder scope change also applies with hierarchy on', () {
      final items = [
        const TabViewItem.standalone(tabId: 'x'),
        const TabViewItem.standalone(tabId: 'a'),
        const TabViewItem.standalone(tabId: 'b'),
      ];

      final result = build(
        visibleItems: items,
        oldIndex: 0,
        newIndex: 2,
        hierarchical: true,
        folderIdByTab: const {'a': 'f1', 'b': 'f1', 'x': null},
        spaceUuid: 'space-1',
      );

      expect(result, isNotNull);
      expect(result!.parentChange, const TabParentChange.unchanged());
      expect(
        result.scopeChange,
        scopedTo(spaceUuid: 'space-1', folderId: 'f1'),
      );
    });

    test('split siblings ride along with a hierarchical drag too', () {
      final items = [
        const TabViewItem.standalone(tabId: 'split-1'),
        const TabViewItem.standalone(tabId: 'split-2'),
        const TabViewItem.standalone(tabId: 'a'),
        const TabViewItem.standalone(tabId: 'b'),
      ];

      final result = build(
        visibleItems: items,
        oldIndex: 0,
        newIndex: 2,
        hierarchical: true,
        splitMembers: const {
          'split-1': ['split-1', 'split-2'],
          'split-2': ['split-1', 'split-2'],
        },
      );

      expect(result, isNotNull);
      expect(result!.movingTabIds, ['split-1', 'split-2']);
      expect(result.previousTabId, 'a');
      expect(result.nextTabId, 'b');
    });
  });
}
