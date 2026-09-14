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
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
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
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_layout.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_tab_list.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

class _EmptyTabStates extends TabStates {
  @override
  Map<String, TabState> build() => const {};
}

class _NoSelectedTab extends SelectedTab {
  @override
  String? build() => null;
}

/// [SelectedTab] without its native listeners, switchable from the test.
class _SettableSelectedTab extends SelectedTab {
  @override
  String? build() => 'tab-1';

  String? get selected => state;

  set selected(String? tabId) => state = tabId;
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

/// The engine lists [ids]: rows the grouped list keeps as live tabs.
class _TabListOf extends TabList {
  _TabListOf(this.ids);

  final List<String> ids;

  @override
  EquatableValue<List<String>> build() => EquatableValue(ids);
}

class _DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

Future<TabDatabase> _memoryDatabaseWithOneTab({required String title}) =>
    _memoryDatabaseWithTabs([(id: 'tab-1', title: title)]);

/// One space holding [tabs] in storage order (ascending order_key), each
/// optionally pinned or filed in the folder [folderId].
Future<TabDatabase> _memoryDatabaseWithTabs(
  List<({String id, String title})> tabs, {
  Set<String> pinned = const {},
  String? folderId,
  Set<String> inFolder = const {},
}) async {
  final db = TabDatabase(
    NativeDatabase.memory(
      setup: (database) {
        registerLexorankFunctions(database);
        registerUrlFunctions(database);
      },
    ),
  );
  await db.spaceDao.insertSpace(SpaceData(uuid: 'space-1', orderIndex: 0));
  if (folderId != null) {
    await db.tabFolderDao.insertFolder(
      TabFolderData(
        id: folderId,
        name: 'Folder',
        spaceUuid: 'space-1',
        orderKey: 'f',
      ),
    );
  }
  for (final tab in tabs) {
    final filed = inFolder.contains(tab.id);
    await db.tabDao.insertTab(
      tab.id,
      source: TabSource.manual,
      spaceUuid: const Value('space-1'),
      folderId: Value(filed ? folderId : null),
      shelf: pinned.contains(tab.id) || filed
          ? TabShelf.pinned
          : TabShelf.normal,
      url: Value(Uri.parse('https://example.com/${tab.id}')),
      title: Value(tab.title),
      tabMode: const Value(TabMode.regular),
    );
  }
  return db;
}

/// The provider tree a [WideRailTabList] needs on top of [db], with the tabs
/// unrestored so titles come from the database rows.
List<Override> _railOverrides(
  TabDatabase db, {
  required double railWidth,
  List<String> liveTabIds = const [],
}) => [
  tabDatabaseProvider.overrideWith((ref) => db),
  generalSettingsWithDefaultsProvider.overrideWith(
    (ref) => GeneralSettings.withDefaults(tabBarPosition: TabBarPosition.left),
  ),
  zenSettingsWithDefaultsProvider.overrideWith(
    (ref) => ZenSettings.withDefaults(railWidth: railWidth),
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
  genericWebsiteServiceProvider.overrideWith(_NoIconGenericWebsiteService.new),
  tabViewFilterControllerProvider.overrideWith(
    _DefaultTabViewFilterController.new,
  ),
  tabListProvider.overrideWith(() => _TabListOf(liveTabIds)),
];

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

    testWidgets('collapses the toolbar when every button draws nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _railBox(
          railWidth: railWidth,
          viewportWidth: 900,
          child: const WideRailLayout(
            urlRow: SizedBox(height: 56, width: double.infinity),
            tabs: SizedBox.expand(),
            // The add-on bar with nothing pinned and the switcher row with
            // its buttons off both build, and both draw nothing.
            toolbar: WideRailToolbarRow(
              buttons: [SizedBox.shrink(), SizedBox.shrink()],
            ),
            spaces: SizedBox(height: 56, width: double.infinity),
          ),
        ),
      );

      final toolbar = tester.getRect(find.byKey(WideRailLayout.toolbarKey));
      final spaces = tester.getRect(find.byKey(WideRailLayout.spacesKey));
      expect(toolbar.height, lessThan(WideRailToolbarRow.targetHeight));
      expect(toolbar.bottom, spaces.top);
    });

    testWidgets(
      'keeps the toolbar one run tall when the selected tab widens it past '
      'the rail',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedTabProvider.overrideWith(_SettableSelectedTab.new),
            ],
            child: _railBox(
              railWidth: railWidth,
              viewportWidth: 900,
              child: WideRailLayout(
                urlRow: const SizedBox(height: 56, width: double.infinity),
                tabs: const SizedBox.expand(),
                contextualToolbar: const SizedBox(
                  height: 40,
                  width: double.infinity,
                ),
                toolbar: WideRailToolbarRow(
                  buttons: [
                    // Stands in for the pinned add-on bar: one composite child
                    // whose width follows the tab. Wide enough on tab-2 to
                    // overflow the rail, which is what used to open a second
                    // run and push the contextual strip up.
                    Consumer(
                      builder: (context, ref, _) {
                        final tab = ref.watch(selectedTabProvider);
                        final count = tab == 'tab-2' ? 8 : 1;
                        // Shaped like the real bars: a row that scrolls
                        // inside whatever width the rail gives it.
                        return SizedBox(
                          height: 40,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var i = 0; i < count; i++)
                                  const SizedBox(width: 48, height: 40),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const Icon(Icons.menu),
                  ],
                ),
                spaces: const SizedBox(height: 56, width: double.infinity),
              ),
            ),
          ),
        );

        final toolbarBefore = tester.getRect(
          find.byKey(WideRailLayout.toolbarKey),
        );
        final spacesBefore = tester.getRect(
          find.byKey(WideRailLayout.spacesKey),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(WideRailLayout)),
        );
        (container.read(selectedTabProvider.notifier) as _SettableSelectedTab)
                .selected =
            'tab-2';
        await tester.pump();

        final toolbarAfter = tester.getRect(
          find.byKey(WideRailLayout.toolbarKey),
        );
        // The row keeps whatever height its content needs, unchanged by the
        // switch, and never more than one target tall.
        expect(toolbarAfter, toolbarBefore);
        expect(
          toolbarAfter.height,
          lessThanOrEqualTo(WideRailToolbarRow.rowHeight),
        );
        expect(
          tester.getRect(find.byKey(WideRailLayout.spacesKey)),
          spacesBefore,
        );
        // Nothing opened up between the strip and the toolbar either.
        expect(toolbarAfter.top, tester.getRect(_contextualStrip).bottom);
      },
    );

    testWidgets(
      'keeps the toolbar and the spaces rows in place when the selected tab '
      'changes what a toolbar button contains',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedTabProvider.overrideWith(_SettableSelectedTab.new),
            ],
            child: _railBox(
              railWidth: railWidth,
              viewportWidth: 900,
              child: WideRailLayout(
                urlRow: const SizedBox(height: 56, width: double.infinity),
                tabs: const SizedBox.expand(),
                toolbar: WideRailToolbarRow(
                  buttons: [
                    const Icon(Icons.add),
                    // Stands in for a button whose own layout follows the
                    // selected tab — the pinned add-on bar once stacked one
                    // icon per add-on enabled on that tab.
                    Consumer(
                      builder: (context, ref, _) {
                        final tab = ref.watch(selectedTabProvider);
                        final count = tab == 'tab-2' ? 3 : 1;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < count; i++)
                              const SizedBox(width: 24, height: 40),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                spaces: const SizedBox(height: 56, width: double.infinity),
              ),
            ),
          ),
        );

        final toolbarBefore = tester.getRect(
          find.byKey(WideRailLayout.toolbarKey),
        );
        final spacesBefore = tester.getRect(
          find.byKey(WideRailLayout.spacesKey),
        );
        expect(toolbarBefore.bottom, spacesBefore.top);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(WideRailLayout)),
        );
        (container.read(selectedTabProvider.notifier) as _SettableSelectedTab)
                .selected =
            'tab-2';
        await tester.pump();

        final toolbarAfter = tester.getRect(
          find.byKey(WideRailLayout.toolbarKey),
        );
        final spacesAfter = tester.getRect(
          find.byKey(WideRailLayout.spacesKey),
        );
        expect(toolbarAfter, toolbarBefore);
        expect(spacesAfter, spacesBefore);
        expect(toolbarAfter.bottom, spacesAfter.top);
        // One run: both targets side by side, spanning the rail, and never
        // taller than a single target.
        expect(
          toolbarAfter.height,
          lessThanOrEqualTo(WideRailToolbarRow.rowHeight),
        );
        expect(toolbarAfter.width, railWidth);
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

      await tester.pumpWidget(urlRow(WideRailUrlRow.collapseWidth - 8));
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
          overrides: _railOverrides(db, railWidth: railWidth),
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

    testWidgets('renders storage order', (tester) async {
      final db = await _memoryDatabaseWithTabs([
        (id: 'tab-1', title: 'First'),
        (id: 'tab-2', title: 'Second'),
      ]);
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _railOverrides(
            db,
            railWidth: railWidth,
            liveTabIds: const ['tab-1', 'tab-2'],
          ),
          child: _railBox(
            railWidth: railWidth,
            viewportWidth: 900,
            child: const WideRailTabList(),
          ),
        ),
      );
      await _settle(tester);

      // The rail mirrors the desktop sidebar: order_key ascending, so the
      // first tab stays above the second.
      expect(
        tester.getTopLeft(find.text('First')).dy,
        lessThan(tester.getTopLeft(find.text('Second')).dy),
      );

      await _disposeTree(tester);
    });

    testWidgets('a folder alone puts up the Pinned header', (tester) async {
      final db = await _memoryDatabaseWithTabs(
        [(id: 'tab-1', title: 'Member'), (id: 'tab-2', title: 'Loose')],
        folderId: 'folder-1',
        inFolder: {'tab-1'},
      );
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _railOverrides(
            db,
            railWidth: railWidth,
            liveTabIds: const ['tab-1', 'tab-2'],
          ),
          child: _railBox(
            railWidth: railWidth,
            viewportWidth: 900,
            child: const WideRailTabList(),
          ),
        ),
      );
      await _settle(tester);

      // No root pinned tab, but the folder lives in the pinned section: its
      // header, the folder row and its member come before the main list.
      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('Tabs'), findsOneWidget);
      final pinnedY = tester.getTopLeft(find.text('Pinned')).dy;
      final folderY = tester.getTopLeft(find.text('Folder')).dy;
      final memberY = tester.getTopLeft(find.text('Member')).dy;
      final tabsY = tester.getTopLeft(find.text('Tabs')).dy;
      final looseY = tester.getTopLeft(find.text('Loose')).dy;
      expect(pinnedY, lessThan(folderY));
      expect(folderY, lessThan(memberY));
      expect(memberY, lessThan(tabsY));
      expect(tabsY, lessThan(looseY));

      await _disposeTree(tester);
    });
  });
}

/// The stand-in contextual strip of the overflow test: the 40-tall box the
/// layout wraps in its own ClipRect.
final _contextualStrip = find.byWidgetPredicate(
  (widget) =>
      widget is SizedBox &&
      widget.height == 40 &&
      widget.width == double.infinity,
);
