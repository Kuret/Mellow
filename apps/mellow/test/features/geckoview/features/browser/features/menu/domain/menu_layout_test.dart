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
import 'package:mellow/features/geckoview/features/browser/features/menu/domain/entities/menu_layout.dart';

MenuSectionEntry _section(
  MenuSectionType type, {
  bool visible = true,
  List<MenuItemEntry> items = const [],
}) => MenuSectionEntry(type: type, visible: visible, items: items);

MenuItemEntry _item(MenuItemType type, {bool visible = true}) =>
    MenuItemEntry(type: type, visible: visible);

List<MenuSectionType> _sectionTypes(List<MenuSectionEntry> entries) =>
    entries.map((entry) => entry.type).toList();

List<MenuItemType> _itemTypes(
  List<MenuSectionEntry> entries,
  MenuSectionType section,
) => entries
    .firstWhere((entry) => entry.type == section)
    .items
    .map((item) => item.type)
    .toList();

void main() {
  group('menuLayoutDefaults', () {
    test('offers every section exactly once', () {
      final offered = menuLayoutDefaults
          .map((section) => section.type)
          .toList();

      expect(offered.toSet(), MenuSectionType.values.toSet());
      expect(offered.length, MenuSectionType.values.length);
    });

    test('places every item in exactly one section', () {
      List<MenuItemType> flatten(List<MenuItemDefault> items) => [
        for (final item in items) ...[item.type, ...flatten(item.items)],
      ];

      final placed = [
        for (final section in menuLayoutDefaults) ...flatten(section.items),
      ];

      // A [MenuItemType] that no section claims can never be rendered, and one
      // claimed twice would be arrangeable in two places at once.
      expect(placed.toSet(), MenuItemType.values.toSet());
      expect(placed.length, MenuItemType.values.length);
    });

    test('starts every section and item switched on', () {
      // The shipped menu is the layout users see before they touch anything,
      // so nothing may default to hidden without the sheet changing too.
      bool allOn(List<MenuItemDefault> items) =>
          items.every((item) => item.visible && allOn(item.items));

      expect(menuLayoutDefaults.every((section) => section.visible), isTrue);
      expect(
        menuLayoutDefaults.every((section) => allOn(section.items)),
        isTrue,
      );
    });
  });

  group('mergeMenuLayoutWithDefaults', () {
    test('uses the defaults verbatim when nothing is persisted', () {
      final merged = mergeMenuLayoutWithDefaults(null);

      expect(
        _sectionTypes(merged),
        menuLayoutDefaults.map((section) => section.type).toList(),
      );
      expect(
        _itemTypes(merged, MenuSectionType.tabActions),
        menuLayoutDefaults
            .firstWhere((section) => section.type == MenuSectionType.tabActions)
            .items
            .map((item) => item.type)
            .toList(),
      );
    });

    test('preserves a reordered section list and its visibility', () {
      const defaults = <MenuSectionDefault>[
        MenuSectionDefault(MenuSectionType.pageActions),
        MenuSectionDefault(MenuSectionType.quickLinks),
        MenuSectionDefault(MenuSectionType.profile),
      ];
      final persisted = [
        _section(MenuSectionType.quickLinks),
        _section(MenuSectionType.profile, visible: false),
        _section(MenuSectionType.pageActions),
      ];

      final merged = mergeMenuLayoutWithDefaults(persisted, defaults);

      expect(_sectionTypes(merged), _sectionTypes(persisted));
      expect(
        merged.firstWhere((s) => s.type == MenuSectionType.profile).visible,
        isFalse,
      );
    });

    test('preserves a reordered item list inside a section', () {
      const defaults = <MenuSectionDefault>[
        MenuSectionDefault(
          MenuSectionType.quickLinks,
          items: [
            MenuItemDefault(MenuItemType.history),
            MenuItemDefault(MenuItemType.bookmarks),
            MenuItemDefault(MenuItemType.downloads),
          ],
        ),
      ];
      final persisted = [
        _section(
          MenuSectionType.quickLinks,
          items: [
            _item(MenuItemType.downloads),
            _item(MenuItemType.history),
            _item(MenuItemType.bookmarks, visible: false),
          ],
        ),
      ];

      final merged = mergeMenuLayoutWithDefaults(persisted, defaults);

      expect(_itemTypes(merged, MenuSectionType.quickLinks), [
        MenuItemType.downloads,
        MenuItemType.history,
        MenuItemType.bookmarks,
      ]);
      expect(merged.single.visibleItemTypes, [
        MenuItemType.downloads,
        MenuItemType.history,
      ]);
    });

    test('drops sections and items that are no longer offered', () {
      const defaults = <MenuSectionDefault>[
        MenuSectionDefault(
          MenuSectionType.quickLinks,
          items: [MenuItemDefault(MenuItemType.history)],
        ),
      ];
      final persisted = [
        _section(
          MenuSectionType.quickLinks,
          items: [_item(MenuItemType.history), _item(MenuItemType.downloads)],
        ),
        _section(MenuSectionType.about),
      ];

      final merged = mergeMenuLayoutWithDefaults(persisted, defaults);

      expect(_sectionTypes(merged), [MenuSectionType.quickLinks]);
      expect(_itemTypes(merged, MenuSectionType.quickLinks), [
        MenuItemType.history,
      ]);
    });

    test('inserts a newly offered section at its designed position', () {
      const defaults = <MenuSectionDefault>[
        MenuSectionDefault(MenuSectionType.tabActions),
        MenuSectionDefault(MenuSectionType.pageActions, visible: false),
        MenuSectionDefault(MenuSectionType.quickLinks),
      ];
      // Saved before pageActions existed, and reordered since.
      final persisted = [
        _section(MenuSectionType.quickLinks),
        _section(MenuSectionType.tabActions),
      ];

      final merged = mergeMenuLayoutWithDefaults(persisted, defaults);

      // Second, as the defaults ask — not appended to the bottom of the
      // user's list.
      expect(_sectionTypes(merged), [
        MenuSectionType.quickLinks,
        MenuSectionType.pageActions,
        MenuSectionType.tabActions,
      ]);
      // And off, because that is how it is offered: adding a section must not
      // change the menu of someone who already arranged theirs.
      expect(
        merged.firstWhere((s) => s.type == MenuSectionType.pageActions).visible,
        isFalse,
      );
    });

    test('inserts a newly offered item at its designed position', () {
      const defaults = <MenuSectionDefault>[
        MenuSectionDefault(
          MenuSectionType.pageActions,
          items: [
            MenuItemDefault(MenuItemType.addBookmark),
            MenuItemDefault(MenuItemType.findInPage),
            MenuItemDefault(MenuItemType.inspectElement, visible: false),
          ],
        ),
      ];
      final persisted = [
        _section(
          MenuSectionType.pageActions,
          items: [
            _item(MenuItemType.findInPage),
            _item(MenuItemType.addBookmark),
          ],
        ),
      ];

      final merged = mergeMenuLayoutWithDefaults(persisted, defaults);

      expect(_itemTypes(merged, MenuSectionType.pageActions), [
        MenuItemType.findInPage,
        MenuItemType.addBookmark,
        MenuItemType.inspectElement,
      ]);
      expect(merged.single.visibleItemTypes, [
        MenuItemType.findInPage,
        MenuItemType.addBookmark,
      ]);
    });

    test('preserves a reordered list of the rows a row reveals', () {
      const defaults = [
        MenuSectionDefault(
          MenuSectionType.tabActions,
          items: [
            MenuItemDefault(
              MenuItemType.share,
              items: [
                MenuItemDefault(MenuItemType.copyAddress),
                MenuItemDefault(MenuItemType.shareLink),
                MenuItemDefault(MenuItemType.showQrCode),
              ],
            ),
          ],
        ),
      ];
      final persisted = [
        _section(
          MenuSectionType.tabActions,
          items: [
            MenuItemEntry(
              type: MenuItemType.share,
              visible: true,
              items: [
                _item(MenuItemType.showQrCode),
                _item(MenuItemType.copyAddress),
                _item(MenuItemType.shareLink, visible: false),
              ],
            ),
          ],
        ),
      ];

      final merged = mergeMenuLayoutWithDefaults(persisted, defaults);
      final share = merged.single.items.single;

      expect(share.items.map((item) => item.type), [
        MenuItemType.showQrCode,
        MenuItemType.copyAddress,
        MenuItemType.shareLink,
      ]);
      expect(share.visibleItems.map((item) => item.type), [
        MenuItemType.showQrCode,
        MenuItemType.copyAddress,
      ]);
    });

    test('fills in the rows of a row persisted before it had any', () {
      const defaults = [
        MenuSectionDefault(
          MenuSectionType.tabActions,
          items: [
            MenuItemDefault(
              MenuItemType.export,
              items: [
                MenuItemDefault(MenuItemType.exportAsPdf),
                MenuItemDefault(MenuItemType.printPage),
              ],
            ),
          ],
        ),
      ];
      // Saved by a build where Export was a leaf.
      final persisted = [
        _section(
          MenuSectionType.tabActions,
          items: [_item(MenuItemType.export)],
        ),
      ];

      final merged = mergeMenuLayoutWithDefaults(persisted, defaults);

      expect(merged.single.items.single.items.map((item) => item.type), [
        MenuItemType.exportAsPdf,
        MenuItemType.printPage,
      ]);
    });

    test('gives a section persisted without items the offered ones', () {
      const defaults = <MenuSectionDefault>[
        MenuSectionDefault(
          MenuSectionType.about,
          items: [MenuItemDefault(MenuItemType.about)],
        ),
      ];

      final merged = mergeMenuLayoutWithDefaults([
        _section(MenuSectionType.about),
      ], defaults);

      expect(_itemTypes(merged, MenuSectionType.about), [MenuItemType.about]);
    });
  });

  group('menuItemEntriesFromJson', () {
    test('drops entries that no longer decode', () {
      final decoded = menuItemEntriesFromJson([
        {'type': 'history', 'visible': true},
        {'type': 'a_retired_item', 'visible': true},
        {'type': 'bookmarks', 'visible': false},
      ]);

      // One retired item must not cost the user the rest of the section.
      expect(decoded.map((item) => item.type), [
        MenuItemType.history,
        MenuItemType.bookmarks,
      ]);
      expect(decoded.last.visible, isFalse);
    });

    test('a layout naming retired menu items still loads', () {
      // `feeds`, `fetchFeeds`, `smallWeb`, `bangs`, `translatePage`,
      // `pinTopSite`, `readerMode` and `gestures` shipped as MenuItemType
      // values and are still named in stored menu layouts. Removing the enum
      // values must not throw, and must not cost the user the rest of their
      // arrangement.
      final decoded = menuItemEntriesFromJson([
        {'type': 'history', 'visible': true},
        {'type': 'feeds', 'visible': true},
        {'type': 'fetchFeeds', 'visible': true},
        {'type': 'smallWeb', 'visible': true},
        {'type': 'bangs', 'visible': true},
        {'type': 'translatePage', 'visible': true},
        {'type': 'pinTopSite', 'visible': true},
        {'type': 'readerMode', 'visible': true},
        {'type': 'gestures', 'visible': true},
        {'type': 'bookmarks', 'visible': true},
      ]);

      expect(decoded.map((item) => item.type), [
        MenuItemType.history,
        MenuItemType.bookmarks,
      ]);
    });

    test('keeps the rows nested under a row', () {
      final decoded = menuItemEntriesFromJson([
        {
          'type': 'share',
          'visible': true,
          'items': [
            {'type': 'showQrCode', 'visible': true},
            {'type': 'a_retired_row', 'visible': true},
          ],
        },
      ]);

      expect(decoded.single.items.map((item) => item.type), [
        MenuItemType.showQrCode,
      ]);
    });

    test('reads anything that is not a list as no arrangement', () {
      expect(menuItemEntriesFromJson(null), isEmpty);
      expect(menuItemEntriesFromJson('items'), isEmpty);
    });
  });

  group('menuSectionEntriesFromJson', () {
    test('drops sections that no longer decode', () {
      final decoded = menuSectionEntriesFromJson([
        {'type': 'pageActions', 'visible': true},
        {'type': 'a_retired_section', 'visible': true},
        {'type': 'about', 'visible': false},
      ]);

      // One retired section must not cost the user the rest of the menu.
      expect(decoded.map((section) => section.type), [
        MenuSectionType.pageActions,
        MenuSectionType.about,
      ]);
      expect(decoded.last.visible, isFalse);
    });

    test('a layout naming retired sections still loads', () {
      // `quickToggles` shipped as a MenuSectionType value and is still named in
      // stored menu layouts, with rows of its own. Removing the enum value must
      // not throw, and must not cost the user the rest of their arrangement.
      final decoded = menuSectionEntriesFromJson([
        {'type': 'pageActions', 'visible': true},
        {
          'type': 'quickToggles',
          'visible': true,
          'items': [
            {'type': 'desktopMode', 'visible': true},
            {'type': 'gestures', 'visible': true},
          ],
        },
        {'type': 'quickLinks', 'visible': true},
      ]);

      expect(decoded.map((section) => section.type), [
        MenuSectionType.pageActions,
        MenuSectionType.quickLinks,
      ]);
    });

    test('keeps the rows arranged inside a section', () {
      final decoded = menuSectionEntriesFromJson([
        {
          'type': 'quickLinks',
          'visible': true,
          'items': [
            {'type': 'downloads', 'visible': true},
            {'type': 'a_retired_row', 'visible': true},
            {'type': 'history', 'visible': false},
          ],
        },
      ]);

      expect(decoded.single.items.map((item) => item.type), [
        MenuItemType.downloads,
        MenuItemType.history,
      ]);
      expect(decoded.single.visibleItemTypes, [MenuItemType.downloads]);
    });

    test('reads anything that is not a list as no arrangement', () {
      expect(menuSectionEntriesFromJson(null), isEmpty);
      expect(menuSectionEntriesFromJson('sections'), isEmpty);
    });
  });
}
