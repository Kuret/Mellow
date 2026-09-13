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
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/search/domain/providers/search_module_order.dart';
import 'package:weblibre/features/geckoview/features/search/domain/providers/search_modules_view.dart';

ModuleOrderEntry _entry(SearchModuleType type, {bool visible = true}) =>
    ModuleOrderEntry(type: type, visible: visible);

List<SearchModuleType> _types(List<ModuleOrderEntry> entries) =>
    entries.map((e) => e.type).toList();

void main() {
  group('mergeModuleOrderWithDefaults', () {
    test('uses the defaults verbatim when nothing is persisted', () {
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.recentSearches, visible: true),
        (type: SearchModuleType.topSites, visible: true),
      ];

      final merged = mergeModuleOrderWithDefaults(null, defaults);

      expect(_types(merged), defaults.map((d) => d.type).toList());
      expect(merged.every((e) => e.visible), isTrue);
    });

    test('preserves a reordered persisted list', () {
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.recentSearches, visible: true),
        (type: SearchModuleType.searchProviders, visible: true),
        (type: SearchModuleType.topSites, visible: true),
      ];
      final persisted = [
        _entry(SearchModuleType.topSites),
        _entry(SearchModuleType.recentSearches),
        _entry(SearchModuleType.searchProviders),
      ];

      final merged = mergeModuleOrderWithDefaults(persisted, defaults);

      expect(_types(merged), _types(persisted));
    });

    test('preserves persisted visibility', () {
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.recentSearches, visible: true),
        (type: SearchModuleType.topSites, visible: true),
      ];
      final persisted = [
        _entry(SearchModuleType.recentSearches, visible: false),
        _entry(SearchModuleType.topSites),
      ];

      final merged = mergeModuleOrderWithDefaults(persisted, defaults);

      expect(merged[0].visible, isFalse);
      expect(merged[1].visible, isTrue);
    });

    test('drops persisted modules that are no longer offered', () {
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.topSites, visible: true),
      ];
      final persisted = [
        _entry(SearchModuleType.recentSearches),
        _entry(SearchModuleType.topSites),
      ];

      final merged = mergeModuleOrderWithDefaults(persisted, defaults);

      expect(_types(merged), [SearchModuleType.topSites]);
    });

    test('inserts a new default at its position, not at the tail', () {
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.recentSearches, visible: true),
        (
          type: SearchModuleType.searchProviders,
          visible: true,
        ), // newly introduced, in the middle
        (type: SearchModuleType.topSites, visible: true),
      ];
      final persisted = [
        _entry(SearchModuleType.recentSearches),
        _entry(SearchModuleType.topSites),
      ];

      final merged = mergeModuleOrderWithDefaults(persisted, defaults);

      expect(_types(merged), [
        SearchModuleType.recentSearches,
        SearchModuleType.searchProviders,
        SearchModuleType.topSites,
      ]);
    });

    test('a new default keeps its own visibility instead of forcing on', () {
      // This is what lets a module be offered on a surface without switching it
      // on for everyone who already customised that surface.
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.topSites, visible: true),
        (type: SearchModuleType.containers, visible: false),
      ];
      final persisted = [_entry(SearchModuleType.topSites)];

      final merged = mergeModuleOrderWithDefaults(persisted, defaults);

      expect(
        merged.firstWhere((e) => e.type == SearchModuleType.containers).visible,
        isFalse,
      );
    });

    test('clamps the insert position when the persisted list is shorter', () {
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.recentSearches, visible: true),
        (type: SearchModuleType.searchProviders, visible: true),
        (type: SearchModuleType.topSites, visible: true),
        (
          type: SearchModuleType.containers,
          visible: true,
        ), // index 3, beyond the persisted length
      ];
      final persisted = [_entry(SearchModuleType.recentSearches)];

      final merged = mergeModuleOrderWithDefaults(persisted, defaults);

      expect(
        merged.map((e) => e.type).toSet(),
        defaults.map((d) => d.type).toSet(),
      );
      expect(merged, hasLength(defaults.length));
    });

    test('is idempotent', () {
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.recentSearches, visible: true),
        (type: SearchModuleType.searchProviders, visible: true),
        (type: SearchModuleType.topSites, visible: true),
      ];
      final persisted = [
        _entry(SearchModuleType.topSites, visible: false),
        _entry(SearchModuleType.recentSearches),
      ];

      final once = mergeModuleOrderWithDefaults(persisted, defaults);
      final twice = mergeModuleOrderWithDefaults(once, defaults);

      expect(twice, once);
    });
  });

  group('persisted payload compatibility', () {
    // The storage key and the on-disk shape are a compatibility contract: the
    // empty-state order has shipped to users under this exact key, encoded by
    // ModuleOrderEntry.toJson. Changing either silently resets their layout.
    test('the empty-state order keeps its shipped storage key', () {
      expect(ModuleSurface.newTab.key, 'EmptyStateModuleOrder');
    });

    test('a real shipped payload round-trips unchanged', () {
      // Captured from the shape SearchModuleOrder.build writes today: a user
      // who moved Shortcuts to the top and hid History Highlights. History
      // Highlights, Recent Articles and Frequent Bangs have since been removed,
      // so the decode has to drop those entries and keep the rest of the layout.
      const payload =
          '[{"type":"topSites","visible":true},'
          '{"type":"recentSearches","visible":true},'
          '{"type":"frequentBangs","visible":true},'
          '{"type":"recentArticles","visible":true},'
          '{"type":"recentTabs","visible":true},'
          '{"type":"recentHistory","visible":true},'
          '{"type":"historyHighlights","visible":false},'
          '{"type":"containers","visible":true}]';

      final merged = decodeModuleOrder(
        payload,
        ModuleSurface.newTab.defaultModules,
      );

      // Everything the user saved that still exists survives, in their order.
      expect(_types(merged), [
        SearchModuleType.topSites,
        SearchModuleType.recentSearches,
        SearchModuleType.recentTabs,
        SearchModuleType.recentHistory,
        SearchModuleType.containers,
      ]);
      expect(merged.every((e) => e.visible), isTrue);
    });

    test('unparseable entries are skipped rather than poisoning the list', () {
      // An entry naming a module that no longer exists must not discard the
      // whole order.
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.topSites, visible: true),
      ];
      const payload =
          '[{"type":"topSites","visible":true},'
          '{"type":"aModuleThatWasRemoved","visible":true}]';

      expect(_types(decodeModuleOrder(payload, defaults)), [
        SearchModuleType.topSites,
      ]);
    });

    test('a layout naming a module we deleted still loads', () {
      // These all shipped as SearchModuleType values and are still named in
      // stored configurations. Removing the enum values must not throw, and
      // must not cost the user the rest of their layout.
      const removedModuleNames = [
        'quote',
        'popularSites',
        'historyHighlights',
        'articles',
        'recentArticles',
        'frequentBangs',
      ];
      const defaults = <ModuleSurfaceDefault>[
        (type: SearchModuleType.recentSearches, visible: true),
        (type: SearchModuleType.topSites, visible: true),
        (type: SearchModuleType.recentTabs, visible: false),
      ];

      final payload = jsonEncode([
        {'type': 'topSites', 'visible': true},
        for (final name in removedModuleNames) {'type': name, 'visible': true},
        {'type': 'recentSearches', 'visible': false},
      ]);

      final decoded = decodeModuleOrder(payload, defaults);

      // The surviving entries keep their persisted order and visibility, and
      // the surface's other defaults are merged back in.
      expect(_types(decoded), [
        SearchModuleType.topSites,
        SearchModuleType.recentSearches,
        SearchModuleType.recentTabs,
      ]);
      expect(
        decoded
            .firstWhere((e) => e.type == SearchModuleType.recentSearches)
            .visible,
        isFalse,
      );
    });
  });
}
