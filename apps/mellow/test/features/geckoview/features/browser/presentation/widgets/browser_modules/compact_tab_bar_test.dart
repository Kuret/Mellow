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
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/browser_modules/compact_tab_bar.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/cold_tab_badge.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/essentials_grid.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_indicator.dart';
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

/// [SelectedSpace] without its persistence and tab-selection listeners.
class _TestSelectedSpace extends SelectedSpace {
  @override
  String? build() => 'space-1';
}

class _NotRestored extends BrowserRestoreComplete {
  @override
  bool build() => false;
}

class _Restored extends BrowserRestoreComplete {
  @override
  bool build() => true;
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

/// [TabRepository] without the engine: records which tab a tap selects.
class _RecordingTabRepository extends TabRepository {
  final selectedTabIds = <String>[];

  @override
  void build() {}

  @override
  Future<bool> selectTab(String tabId) async {
    selectedTabIds.add(tabId);
    return true;
  }
}

Future<TabDatabase> _memoryDatabase({
  List<({String id, String title})> tabs = const [],
  List<String> essentials = const [],
  String? folderId,
  bool folderCollapsed = false,
  Set<String> inFolder = const {},
  Set<String> cold = const {},
  List<TabFolderData> extraFolders = const [],
  Map<String, String> folderOfTab = const {},
}) async {
  final db = TabDatabase(
    NativeDatabase.memory(
      setup: (database) {
        registerLexorankFunctions(database);
        registerUrlFunctions(database);
      },
    ),
  );
  await db.spaceDao.insertSpace(
    SpaceData(uuid: 'space-1', name: 'Work', icon: 'W', orderIndex: 0),
  );
  await db.spaceDao.insertSpace(
    SpaceData(uuid: 'space-2', name: 'Home', orderIndex: 1),
  );
  if (folderId != null) {
    await db.tabFolderDao.insertFolder(
      TabFolderData(
        id: folderId,
        name: 'Folder',
        spaceUuid: 'space-1',
        orderKey: 'f',
        isCollapsed: folderCollapsed,
      ),
    );
  }
  for (final folder in extraFolders) {
    await db.tabFolderDao.insertFolder(folder);
  }
  for (final id in essentials) {
    await db.tabDao.insertTab(
      id,
      source: TabSource.manual,
      shelf: TabShelf.essential,
      url: Value(Uri.parse('https://example.com/$id')),
      title: Value('Essential $id'),
      tabMode: const Value(TabMode.regular),
    );
  }
  for (final tab in tabs) {
    final tabFolderId =
        folderOfTab[tab.id] ?? (inFolder.contains(tab.id) ? folderId : null);
    await db.tabDao.insertTab(
      tab.id,
      source: TabSource.manual,
      spaceUuid: const Value('space-1'),
      folderId: Value(tabFolderId),
      shelf: tabFolderId != null ? TabShelf.pinned : TabShelf.normal,
      url: Value(Uri.parse('https://example.com/${tab.id}')),
      title: Value(tab.title),
      tabMode: const Value(TabMode.regular),
    );
    if (cold.contains(tab.id)) {
      await db.tabDao.setEngineTabId(tab.id, null);
    }
  }
  return db;
}

final _spaces = <SpaceData>[
  SpaceData(uuid: 'space-1', name: 'Work', icon: 'W', orderIndex: 0),
  SpaceData(uuid: 'space-2', name: 'Home', orderIndex: 1),
];

Future<_RecordingTabRepository> _pumpBar(
  WidgetTester tester, {
  required TabDatabase db,
  bool restored = false,
  double viewportWidth = 400,
  ZenSettings? zenSettings,
}) async {
  final repository = _RecordingTabRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tabDatabaseProvider.overrideWith((ref) => db),
        tabRepositoryProvider.overrideWith(() => repository),
        zenSettingsWithDefaultsProvider.overrideWith(
          (ref) => zenSettings ?? ZenSettings.withDefaults(),
        ),
        generalSettingsWithDefaultsProvider.overrideWith(
          (ref) => GeneralSettings.withDefaults(),
        ),
        watchSpacesProvider.overrideWith((ref) => Stream.value(_spaces)),
        selectedSpaceProvider.overrideWith(_TestSelectedSpace.new),
        selectedTabProvider.overrideWith(_NoSelectedTab.new),
        tabStatesProvider.overrideWith(_EmptyTabStates.new),
        browserRestoreCompleteProvider.overrideWith(
          restored ? _Restored.new : _NotRestored.new,
        ),
        genericWebsiteServiceProvider.overrideWith(
          _NoIconGenericWebsiteService.new,
        ),
        tabViewFilterControllerProvider.overrideWith(
          _DefaultTabViewFilterController.new,
        ),
        tabListProvider.overrideWith(_EmptyTabList.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(size: Size(viewportWidth, 800)),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: viewportWidth,
                child: const CompactTabBar(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: favicon placeholders shimmer forever.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return repository;
}

/// Drift's stream cleanup timers need one more pump after the tree is gone.
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'renders the essentials as icon chips before the tab chips, no taller '
    'than 56dp',
    (tester) async {
      final db = await _memoryDatabase(
        essentials: const ['ess-1', 'ess-2'],
        tabs: const [
          (id: 'tab-1', title: 'Docs'),
          (id: 'tab-2', title: 'News'),
        ],
      );
      addTearDown(db.close);

      await _pumpBar(tester, db: db);

      expect(find.byType(EssentialTile), findsNWidgets(2));
      for (final tile in find.byType(EssentialTile).evaluate()) {
        final size = tester.getSize(find.byWidget(tile.widget));
        expect(size, const Size.square(compactEssentialSize));
      }
      expect(find.text('Docs'), findsOneWidget);
      expect(find.text('News'), findsOneWidget);
      // Essentials lead, the divider sits between them and the tabs.
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(EssentialTile).last).dx,
        lessThan(tester.getTopLeft(find.byType(VerticalDivider)).dx),
      );
      expect(
        tester.getTopLeft(find.byType(VerticalDivider)).dx,
        lessThan(tester.getTopLeft(find.text('Docs')).dx),
      );
      expect(
        tester.getSize(find.byType(CompactTabBar)).height,
        CompactTabBar.height,
      );
      expect(
        tester.getSize(find.byType(CompactTabBar)).height,
        lessThanOrEqualTo(56),
      );
      expect(find.byType(SpaceIndicator), findsOneWidget);

      await _disposeTree(tester);
    },
  );

  testWidgets('a folder chip shows its members inline when tapped', (
    tester,
  ) async {
    final db = await _memoryDatabase(
      tabs: const [
        (id: 'tab-1', title: 'Member'),
        (id: 'tab-2', title: 'Loose'),
      ],
      folderId: 'folder-1',
      inFolder: {'tab-1'},
    );
    addTearDown(db.close);

    await _pumpBar(tester, db: db, viewportWidth: 500);

    expect(find.byType(CompactFolderChip), findsOneWidget);
    expect(find.text('Folder'), findsOneWidget);
    expect(find.text('Loose'), findsOneWidget);
    // Collapsed on the bar until asked, whatever the stored state says.
    expect(find.text('Member'), findsNothing);

    await tester.tap(find.text('Folder'));
    await tester.pump();
    // The strip animates the opened folder to the leading edge; the chip has
    // to come to rest before it can be tapped again.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Member'), findsOneWidget);
    // Inline, right after the folder and ahead of the loose tab.
    expect(
      tester.getTopLeft(find.text('Folder')).dx,
      lessThan(tester.getTopLeft(find.text('Member')).dx),
    );
    expect(
      tester.getTopLeft(find.text('Member')).dx,
      lessThan(tester.getTopLeft(find.text('Loose')).dx),
    );
    expect(
      tester.getSize(find.byType(CompactTabBar)).height,
      lessThanOrEqualTo(56),
    );

    await tester.tap(find.text('Folder'));
    await tester.pump();
    // The strip animates the opened folder to the leading edge; the chip has
    // to come to rest before it can be tapped again.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Member'), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('expanding a folder leaves the scroll position alone', (
    tester,
  ) async {
    final db = await _memoryDatabase(
      tabs: [
        (id: 'tab-1', title: 'Member'),
        for (var i = 0; i < 14; i++) (id: 'loose-$i', title: 'Loose $i'),
      ],
      folderId: 'folder-1',
      inFolder: const {'tab-1'},
    );
    addTearDown(db.close);

    await _pumpBar(tester, db: db, viewportWidth: 500);

    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    // The folder sits near the leading edge with room to its right, so its
    // contents have somewhere to open into.
    final before = controller.offset;

    await tester.tap(find.text('Folder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Member'), findsOneWidget);
    expect(controller.offset, before);

    await _disposeTree(tester);
  });

  testWidgets('expanding a folder brings its contents into view', (
    tester,
  ) async {
    final db = await _memoryDatabase(
      // Essentials push the folder towards the trailing edge, which is where
      // expanding it used to insert its members off-screen.
      essentials: const [
        'e1',
        'e2',
        'e3',
        'e4',
        'e5',
        'e6',
        'e7',
        'e8',
        'e9',
        'e10',
      ],
      tabs: const [
        (id: 'tab-1', title: 'Member'),
        (id: 'tab-2', title: 'Loose'),
      ],
      folderId: 'folder-1',
      inFolder: {'tab-1'},
    );
    addTearDown(db.close);

    await _pumpBar(tester, db: db, viewportWidth: 320);

    // Scroll only until the folder chip appears, which leaves it at the
    // trailing edge — the position where its members land off-screen.
    await tester.dragUntilVisible(
      find.text('Folder'),
      find.byType(ListView),
      const Offset(-40, 0),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final bar = tester.getRect(find.byType(CompactTabBar));

    await tester.tap(find.text('Folder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The folder sits near the leading edge afterwards and its member is on
    // screen, rather than inserted past the right edge where expanding looked
    // like it had done nothing.
    expect(find.text('Member'), findsOneWidget);
    final folder = tester.getRect(find.text('Folder'));
    expect(folder.left - bar.left, lessThan(bar.width / 2));
    final member = tester.getRect(find.text('Member'));
    expect(member.left, greaterThanOrEqualTo(bar.left));
    expect(member.right, lessThanOrEqualTo(bar.right));

    // Ten essential tiles leave their favicon shimmers running; let them
    // finish before the tree goes away.
    await tester.pump(const Duration(seconds: 2));
    await _disposeTree(tester);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'a folder collapsed in storage still shows its members when expanded '
    'on the bar',
    (tester) async {
      final db = await _memoryDatabase(
        tabs: const [(id: 'tab-1', title: 'Member')],
        folderId: 'folder-1',
        folderCollapsed: true,
        inFolder: {'tab-1'},
      );
      addTearDown(db.close);

      await _pumpBar(tester, db: db);
      expect(find.text('Member'), findsNothing);

      await tester.tap(find.byType(CompactFolderChip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Member'), findsOneWidget);

      await _disposeTree(tester);
    },
  );

  testWidgets(
    'expanding a folder reveals its tabs and a chip per subfolder, in '
    'order_key order',
    (tester) async {
      final db = await _memoryDatabase(
        tabs: const [
          (id: 'tab-1', title: 'Inner'),
          (id: 'tab-2', title: 'Deeper'),
        ],
        folderId: 'folder-f',
        folderCollapsed: true,
        extraFolders: [
          TabFolderData(
            id: 'folder-g',
            name: 'Sub',
            spaceUuid: 'space-1',
            parentFolderId: 'folder-f',
            // After tab-1, whose generated key sorts ahead of it.
            orderKey: 'zz',
            isCollapsed: true,
          ),
        ],
        folderOfTab: const {'tab-1': 'folder-f', 'tab-2': 'folder-g'},
      );
      addTearDown(db.close);

      // Wide enough for the folder, its tab and both subfolder chips.
      await _pumpBar(tester, db: db, viewportWidth: 800);

      // Closed on the bar: neither the subfolder nor anything under it.
      expect(find.byType(CompactFolderChip), findsOneWidget);
      expect(find.text('Sub'), findsNothing);
      expect(find.text('Inner'), findsNothing);

      await tester.tap(find.text('Folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The folder's own tab and a chip for the subfolder, in order_key
      // order, both behind the folder chip.
      expect(find.text('Inner'), findsOneWidget);
      expect(find.text('Sub'), findsOneWidget);
      expect(find.text('Deeper'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Folder')).dx,
        lessThan(tester.getTopLeft(find.text('Inner')).dx),
      );
      expect(
        tester.getTopLeft(find.text('Inner')).dx,
        lessThan(tester.getTopLeft(find.text('Sub')).dx),
      );
      // A chevron marks the subfolder as belonging to the chip in front of
      // it; the row has no room to indent.
      expect(find.text('\u203a'), findsOneWidget);

      await tester.tap(find.text('Sub'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Deeper'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Sub')).dx,
        lessThan(tester.getTopLeft(find.text('Deeper')).dx),
      );

      // Collapsing the parent takes the subfolder and its tab with it, and
      // re-opening it does not bring the subfolder back open.
      await tester.tap(find.text('Folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Inner'), findsNothing);
      expect(find.text('Sub'), findsNothing);
      expect(find.text('Deeper'), findsNothing);

      await tester.tap(find.text('Folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sub'), findsOneWidget);
      expect(find.text('Deeper'), findsNothing);

      // The folder's contents sit on a band that is rounded where the group
      // opens and where it closes, so a row that cannot indent still says
      // where the folder ends and the space resumes.
      BorderRadius bandRadiusAround(Finder text) {
        final boxes = tester.widgetList<DecoratedBox>(
          find.ancestor(of: text, matching: find.byType(DecoratedBox)),
        );
        for (final box in boxes) {
          final decoration = box.decoration;
          if (decoration is BoxDecoration &&
              decoration.borderRadius is BorderRadius) {
            return decoration.borderRadius! as BorderRadius;
          }
        }
        fail('no band behind the chip');
      }

      final opening = bandRadiusAround(find.text('Folder'));
      expect(opening.topLeft, isNot(Radius.zero));
      expect(opening.topRight, Radius.zero);

      final closing = bandRadiusAround(find.text('Sub'));
      expect(closing.topLeft, Radius.zero);
      expect(closing.topRight, isNot(Radius.zero));

      await _disposeTree(tester);
    },
  );

  testWidgets(
    'a subfolder of a folder expanded in storage gets a chip of its own',
    (tester) async {
      final db = await _memoryDatabase(
        tabs: const [(id: 'tab-2', title: 'Deeper')],
        folderId: 'folder-f',
        extraFolders: [
          TabFolderData(
            id: 'folder-g',
            name: 'Sub',
            spaceUuid: 'space-1',
            parentFolderId: 'folder-f',
            orderKey: 'zz',
          ),
        ],
        folderOfTab: const {'tab-2': 'folder-g'},
      );
      addTearDown(db.close);

      await _pumpBar(tester, db: db, viewportWidth: 800);

      expect(find.text('Sub'), findsNothing);

      await tester.tap(find.text('Folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sub'), findsOneWidget);
      expect(find.text('Deeper'), findsNothing);

      await tester.tap(find.text('Sub'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Deeper'), findsOneWidget);

      await _disposeTree(tester);
    },
  );

  testWidgets('a swipe on the space indicator switches to the next space', (
    tester,
  ) async {
    final db = await _memoryDatabase(
      tabs: const [(id: 'tab-1', title: 'Docs')],
    );
    addTearDown(db.close);

    await _pumpBar(tester, db: db);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CompactTabBar)),
    );
    expect(container.read(selectedSpaceProvider), 'space-1');

    await tester.drag(find.byType(SpaceIndicator), const Offset(-120, 0));
    await tester.pump();
    expect(container.read(selectedSpaceProvider), 'space-2');

    // And back the other way, wrapping around the end.
    await tester.drag(find.byType(SpaceIndicator), const Offset(-120, 0));
    await tester.pump();
    expect(container.read(selectedSpaceProvider), 'space-1');

    await tester.drag(find.byType(SpaceIndicator), const Offset(120, 0));
    await tester.pump();
    expect(container.read(selectedSpaceProvider), 'space-2');

    await _disposeTree(tester);
  });

  testWidgets(
    'the space indicator sits before the chip strip by default, and after '
    'it when the setting says right',
    (tester) async {
      final db = await _memoryDatabase(
        tabs: const [(id: 'tab-1', title: 'Docs')],
      );
      addTearDown(db.close);

      await _pumpBar(tester, db: db);
      final leftIndicatorX = tester.getTopLeft(find.byType(SpaceIndicator)).dx;
      final leftChipX = tester.getTopLeft(find.text('Docs')).dx;
      expect(leftIndicatorX, lessThan(leftChipX));

      await _disposeTree(tester);

      await _pumpBar(
        tester,
        db: db,
        zenSettings: ZenSettings.withDefaults(
          spaceIndicatorSide: SpaceIndicatorSide.right,
        ),
      );
      final rightIndicatorX = tester
          .getTopLeft(find.byType(SpaceIndicator))
          .dx;
      final rightChipX = tester.getTopLeft(find.text('Docs')).dx;
      expect(rightIndicatorX, greaterThan(rightChipX));

      await _disposeTree(tester);
    },
  );

  testWidgets('a cold tab renders dimmed with the snowflake badge', (
    tester,
  ) async {
    final db = await _memoryDatabase(
      tabs: const [(id: 'tab-1', title: 'Cold Tab')],
      cold: {'tab-1'},
    );
    addTearDown(db.close);

    await _pumpBar(tester, db: db, restored: true);

    expect(find.text('Cold Tab'), findsOneWidget);
    expect(find.byType(ColdTabBadge), findsOneWidget);
    expect(find.byIcon(MdiIcons.snowflakeVariant), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('tapping a cold tab selects it, which materialises it', (
    tester,
  ) async {
    final db = await _memoryDatabase(
      tabs: const [(id: 'tab-1', title: 'Cold Tab')],
      cold: {'tab-1'},
    );
    addTearDown(db.close);

    final repository = await _pumpBar(tester, db: db, restored: true);
    await tester.tap(find.text('Cold Tab'));
    await tester.pump();

    expect(repository.selectedTabIds, ['tab-1']);

    await _disposeTree(tester);
  });
}
