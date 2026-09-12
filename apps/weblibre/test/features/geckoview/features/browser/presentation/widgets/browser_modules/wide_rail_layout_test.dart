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
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/data/database/functions/lexo_rank_functions.dart';
import 'package:weblibre/data/database/functions/url_functions.dart';
import 'package:weblibre/domain/services/generic_website.dart';
import 'package:weblibre/features/geckoview/domain/entities/browser_icon.dart';
import 'package:weblibre/features/geckoview/domain/entities/states/tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/providers/site_settings_badge_provider.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/app_bar_title.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/bottom_app_bar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_layout.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_tab_list.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

class _EmptyTabStates extends TabStates {
  @override
  Map<String, TabState> build() => const {};
}

class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

class _TestSelectedSpace extends SelectedSpace {
  @override
  String? build() => 'space-1';
}

/// Pre-restore path: titles come from the database row and the long-press
/// [TabMenu] (which wants live engine state) is skipped.
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

class _DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

Future<TabDatabase> _memoryDatabaseWithOneTab({required String title}) async {
  final db = TabDatabase(
    NativeDatabase.memory(
      setup: (database) {
        registerLexorankFunctions(database);
        registerUrlFunctions(database);
      },
    ),
  );
  await db.spaceDao.insertSpace(SpaceData(uuid: 'space-1', orderIndex: 0));
  await db.tabDao.insertTab(
    'tab-1',
    source: TabSource.manual,
    parentId: const Value(null),
    spaceUuid: const Value('space-1'),
    url: Value(Uri.parse('https://example.com')),
    title: Value(title),
    tabMode: const Value(TabMode.regular),
  );
  return db;
}

Widget _railBox({
  required double railWidth,
  required double viewportWidth,
  required Widget child,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(size: Size(viewportWidth, 800)),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: railWidth, height: 600, child: child),
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  // Not pumpAndSettle: favicon placeholders shimmer forever.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// See the accordion wide-rail test: drift's stream cleanup Timer needs one
/// more pump after the tree is gone.
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WideRailLayout', () {
    const railWidth = 200.0;

    testWidgets(
      'stacks the URL row on top, the tabs filling the height, then the '
      'toolbar and the spaces at the foot',
      (tester) async {
        await tester.pumpWidget(
          _railBox(
            railWidth: railWidth,
            viewportWidth: 900,
            child: const WideRailLayout(
              urlRow: SizedBox(height: 56, width: double.infinity),
              tabs: SizedBox.expand(),
              toolbar: SizedBox(height: 48, width: double.infinity),
              spaces: SizedBox(height: 56, width: double.infinity),
            ),
          ),
        );

        final rail = tester.getRect(find.byType(WideRailLayout));
        final urlRow = tester.getRect(find.byKey(WideRailLayout.urlRowKey));
        final tabs = tester.getRect(find.byKey(WideRailLayout.tabsKey));
        final toolbar = tester.getRect(find.byKey(WideRailLayout.toolbarKey));
        final spaces = tester.getRect(find.byKey(WideRailLayout.spacesKey));

        expect(urlRow.top, rail.top);
        expect(urlRow.bottom, tabs.top);
        expect(tabs.bottom, toolbar.top);
        expect(toolbar.bottom, spaces.top);
        expect(spaces.bottom, rail.bottom);

        // The shelves take every pixel the fixed rows leave over.
        expect(tabs.height, rail.height - 56 - 48 - 56);
        for (final block in [urlRow, tabs, toolbar, spaces]) {
          expect(block.width, railWidth);
        }
      },
    );

    testWidgets('hides the URL row and toolbar with the main toolbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _railBox(
          railWidth: railWidth,
          viewportWidth: 900,
          child: const WideRailLayout(
            showUrlRow: false,
            showToolbar: false,
            urlRow: SizedBox(height: 56),
            tabs: SizedBox.expand(),
            toolbar: SizedBox(height: 48),
            spaces: SizedBox(height: 56),
          ),
        ),
      );

      expect(find.byKey(WideRailLayout.urlRowKey), findsNothing);
      expect(find.byKey(WideRailLayout.toolbarKey), findsNothing);
      expect(find.byKey(WideRailLayout.tabsKey), findsOneWidget);
      expect(find.byKey(WideRailLayout.spacesKey), findsOneWidget);
    });

    testWidgets('collapses the URL row to the icon button on a narrow rail', (
      tester,
    ) async {
      Widget urlRow(double width) => _railBox(
        railWidth: width,
        viewportWidth: 900,
        child: const WideRailUrlRow(
          title: Text('host'),
          collapsed: Icon(Icons.search),
        ),
      );

      await tester.pumpWidget(urlRow(240));
      expect(find.text('host'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);

      await tester.pumpWidget(urlRow(minWideRailWidth));
      expect(find.text('host'), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  group('WideRailTabList', () {
    const tabTitle = 'Wide Rail Tab';
    const railWidth = 200.0;

    testWidgets('renders each tab as a row spanning the rail width', (
      tester,
    ) async {
      final db = await _memoryDatabaseWithOneTab(title: tabTitle);
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tabDatabaseProvider.overrideWith((ref) => db),
            generalSettingsWithDefaultsProvider.overrideWith(
              (ref) => GeneralSettings.withDefaults(
                tabBarPosition: TabBarPosition.left,
                railWidth: railWidth,
              ),
            ),
            watchSpacesProvider.overrideWith(
              (ref) => Stream.value(<SpaceData>[
                SpaceData(uuid: 'space-1', name: 'Space', orderIndex: 0),
              ]),
            ),
            selectedSpaceProvider.overrideWith(_TestSelectedSpace.new),
            selectedTabProvider.overrideWith(_NoSelectedTab.new),
            tabStatesProvider.overrideWith(_EmptyTabStates.new),
            browserRestoreCompleteProvider.overrideWith(_NotRestored.new),
            genericWebsiteServiceProvider.overrideWith(
              _NoIconGenericWebsiteService.new,
            ),
            tabViewFilterControllerProvider.overrideWith(
              _DefaultTabViewFilterController.new,
            ),
            tabListProvider.overrideWith(_EmptyTabList.new),
          ],
          child: _railBox(
            railWidth: railWidth,
            viewportWidth: 900,
            child: const WideRailTabList(),
          ),
        ),
      );
      await _settle(tester);

      expect(find.text(tabTitle), findsOneWidget);
      final row = find.byType(WideRailTabRowView);
      expect(row, findsOneWidget);
      expect(tester.getSize(row).width, railWidth);

      await _disposeTree(tester);
    });
  });

  group('narrow rail', () {
    test('a rail below minWideRailWidth is never wide', () {
      expect(
        isWideRail(
          isVertical: true,
          railWidth: minWideRailWidth - railWidthStep,
          viewportWidth: 900,
        ),
        isFalse,
      );
      expect(
        isWideRail(isVertical: true, railWidth: 200, viewportWidth: 900),
        isTrue,
      );
    });

    testWidgets('still renders the rotated title', (tester) async {
      final tabState = TabState.$default(
        'preview-tab',
      ).copyWith(url: Uri.parse('https://weblibre.eu/docs'), title: 'WebLibre');

      await tester.pumpWidget(
        _railBox(
          railWidth: defaultRailWidth,
          viewportWidth: 900,
          child: BrowserTabBarView(
            axis: Axis.vertical,
            showMainToolbar: true,
            showContextualToolbar: false,
            showQuickTabSwitcherBar: false,
            displayAppBar: true,
            displayQuickTabSwitcher: false,
            backgroundColor: null,
            title: RailAppBarTitleView(
              tabState: tabState,
              quarterTurns: 3,
              isTabTunneled: false,
              siteSettingsBadgeState: SiteSettingsBadgeState.hidden,
              onSiteSettingsTap: () {},
              onTitleTap: () {},
              tabIcon: const Icon(Icons.public, size: 24),
              longPressUrlCopy: false,
            ),
            actions: const [],
            quickTabSwitcher: const SizedBox.shrink(),
            contextualToolbar: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(WideRailLayout), findsNothing);
      final rotated = tester.widget<RotatedBox>(
        find.descendant(
          of: find.byType(RailAppBarTitleView),
          matching: find.byType(RotatedBox),
        ),
      );
      expect(rotated.quarterTurns, 3);
    });
  });
}
