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
import 'package:drift/native.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:weblibre/data/database/functions/lexo_rank_functions.dart';
import 'package:weblibre/data/database/functions/url_functions.dart';
import 'package:weblibre/domain/services/generic_website.dart';
import 'package:weblibre/features/addons/domain/providers.dart';
import 'package:weblibre/features/geckoview/domain/entities/browser_icon.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/features/contextual_toolbar/data/providers/toolbar_button_configs.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/bottom_app_bar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_layout.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/user/data/database/definitions.drift.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

class _TestSelectedSpace extends SelectedSpace {
  @override
  String? build() => 'space-1';
}

class _NotRestored extends BrowserRestoreComplete {
  @override
  bool build() => false;
}

class _NoIconGenericWebsiteService extends GenericWebsiteService {
  @override
  void build() {}

  @override
  Future<BrowserIcon?> getCachedIcon(Uri url) async => null;
}

class _EmptyTabList extends TabList {
  @override
  EquatableValue<List<String>> build() => EquatableValue(const []);
}

class _EmptyTabStates extends TabStates {
  @override
  Map<String, TabState> build() => const {};
}

class _DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

class _NoPinnedAddonIds extends PinnedAddonIds {
  @override
  Set<String> build() => const {};
}

/// A single configured button — reload — visible and with no fallback, so
/// resolution always draws exactly one reload widget regardless of whether a
/// tab is selected.
final _reloadOnlyToolbarConfigs = EquatableValue(const [
  ToolbarButtonConfig(
    buttonId: 'reload',
    orderKey: 'a',
    isVisible: true,
    fallbackId: null,
  ),
]);

/// Providers every [BrowserTabBar] flavor needs, regardless of layout: no
/// selected tab (so the address/title chain takes its "empty" branch instead
/// of needing a live tab), plain settings and no pinned add-ons.
List<Override> _commonOverrides() => [
  selectedTabProvider.overrideWith(_NoSelectedTab.new),
  generalSettingsWithDefaultsProvider.overrideWith(
    (ref) => GeneralSettings.withDefaults(),
  ),
  zenSettingsWithDefaultsProvider.overrideWith(
    (ref) => ZenSettings.withDefaults(),
  ),
  effectiveToolbarButtonConfigsProvider.overrideWithValue(
    _reloadOnlyToolbarConfigs,
  ),
  pinnedAddonIdsProvider.overrideWith(_NoPinnedAddonIds.new),
];

/// The extra provider tree only the wide-rail branch's tab shelves and space
/// switcher need.
Future<List<Override>> _railOnlyOverrides() async {
  final db = TabDatabase(
    NativeDatabase.memory(
      setup: (database) {
        registerLexorankFunctions(database);
        registerUrlFunctions(database);
      },
    ),
  );
  addTearDown(db.close);

  return [
    tabDatabaseProvider.overrideWith((ref) => db),
    watchSpacesProvider.overrideWith((ref) => Stream.value(const [])),
    selectedSpaceProvider.overrideWith(_TestSelectedSpace.new),
    browserRestoreCompleteProvider.overrideWith(_NotRestored.new),
    genericWebsiteServiceProvider.overrideWith(
      _NoIconGenericWebsiteService.new,
    ),
    tabViewFilterControllerProvider.overrideWith(
      _DefaultTabViewFilterController.new,
    ),
    tabListProvider.overrideWith(_EmptyTabList.new),
    tabStatesProvider.overrideWith(_EmptyTabStates.new),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BrowserTabBar', () {
    testWidgets(
      'draws a configured button (reload) exactly once in the compact bar',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: _commonOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: BrowserTabBar(
                  showMainToolbar: true,
                  displayedSheet: null,
                  quickTabSwitcherRowCount: 0,
                  enableGestures: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets(
      'draws a configured button (reload) exactly once in the wide rail',
      (tester) async {
        final overrides = [
          ..._commonOverrides(),
          ...await _railOnlyOverrides(),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(size: Size(900, 800)),
                  child: SizedBox(
                    width: 200,
                    height: 600,
                    child: BrowserTabBar(
                      showMainToolbar: true,
                      displayedSheet: null,
                      quickTabSwitcherRowCount: 0,
                      enableGestures: false,
                      railSide: RailSide.left,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.refresh), findsOneWidget);

        // Not painted twice into the same run either: exactly one target in
        // the toolbar row carries it.
        expect(
          find.descendant(
            of: find.byType(WideRailToolbarRow),
            matching: find.byIcon(Icons.refresh),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );
  });
}
