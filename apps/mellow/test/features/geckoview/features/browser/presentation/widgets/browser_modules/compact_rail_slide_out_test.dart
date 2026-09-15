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
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent, SwipeEdge;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/data/database/functions/lexo_rank_functions.dart';
import 'package:mellow/data/database/functions/url_functions.dart';
import 'package:mellow/domain/services/generic_website.dart';
import 'package:mellow/features/addons/domain/providers.dart';
import 'package:mellow/features/geckoview/domain/entities/browser_icon.dart';
import 'package:mellow/features/geckoview/domain/entities/states/tab.dart';
import 'package:mellow/features/geckoview/domain/providers/restore_complete.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_list.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:mellow/features/geckoview/features/browser/features/contextual_toolbar/data/providers/toolbar_button_configs.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/controllers/compact_rail_panel.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/browser_modules/bottom_app_bar.dart'
    show RailSpaceTabs;
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/browser_modules/compact_rail_slide_out.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/browser_modules/wide_rail_layout.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/space_icon_rail.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/zen_settings.dart';
import 'package:riverpod/misc.dart' show Override;

class _EmptyTabStates extends TabStates {
  @override
  Map<String, TabState> build() => const {};
}

/// [SelectedTab] without its native listeners, switchable from the test —
/// stands in for a user picking a tab in the panel's shelves.
class _SettableSelectedTab extends SelectedTab {
  @override
  String? build() => null;

  String? get selected => state;

  set selected(String? tabId) => state = tabId;
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

class _TabListOf extends TabList {
  _TabListOf(this.ids);

  final List<String> ids;

  @override
  EquatableValue<List<String>> build() => EquatableValue(ids);
}

Future<TabDatabase> _memoryDatabaseWithOneTab() async {
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
    spaceUuid: const Value('space-1'),
    url: Value(Uri.parse('https://example.com/tab-1')),
  );
  return db;
}

/// The provider tree the panel's real content ([RailSpaceTabs],
/// [SpaceIconRail]) needs on top of [db].
List<Override> _panelOverrides(
  TabDatabase db, {
  CompactRailSide? compactRailSide,
}) => [
  tabDatabaseProvider.overrideWith((ref) => db),
  generalSettingsWithDefaultsProvider.overrideWith(
    (ref) => GeneralSettings.withDefaults(),
  ),
  zenSettingsWithDefaultsProvider.overrideWith(
    (ref) => ZenSettings.withDefaults(compactRailSide: compactRailSide),
  ),
  watchSpacesProvider.overrideWith(
    (ref) => Stream.value(<SpaceData>[
      SpaceData(uuid: 'space-1', name: 'Space', orderIndex: 0),
    ]),
  ),
  selectedSpaceProvider.overrideWith(_TestSelectedSpace.new),
  selectedTabProvider.overrideWith(_SettableSelectedTab.new),
  tabStatesProvider.overrideWith(_EmptyTabStates.new),
  browserRestoreCompleteProvider.overrideWith(_NotRestored.new),
  genericWebsiteServiceProvider.overrideWith(_NoIconGenericWebsiteService.new),
  tabViewFilterControllerProvider.overrideWith(
    _DefaultTabViewFilterController.new,
  ),
  tabListProvider.overrideWith(() => _TabListOf(const [])),
  effectiveToolbarButtonConfigsProvider.overrideWithValue(
    EquatableValue(const []),
  ),
  pinnedAddonIdsProvider.overrideWith(_NoPinnedAddonIds.new),
];

class _DefaultTabViewFilterController extends TabViewFilterController {
  @override
  TabViewFilterOptions build() => TabViewFilterOptions.withDefaults();
}

class _NoPinnedAddonIds extends PinnedAddonIds {
  @override
  Set<String> build() => const {};
}

Widget _harness({
  required List<Override> overrides,
  required double viewportWidth,
  EdgeInsets viewPadding = EdgeInsets.zero,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(viewportWidth, 800),
          padding: viewPadding,
        ),
        child: Scaffold(
          body: CompactRailSlideOut(
            isNarrowViewport: true,
            viewportWidth: viewportWidth,
            railWidth: 260,
            showToolbarButtons: true,
            child: Container(key: const Key('content'), color: Colors.white),
          ),
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

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('with the setting off, the panel never mounts', (tester) async {
    final db = await _memoryDatabaseWithOneTab();
    addTearDown(db.close);

    await tester.pumpWidget(
      _harness(
        overrides: _panelOverrides(db, compactRailSide: null),
        viewportWidth: 360,
      ),
    );
    await _settle(tester);

    expect(find.byKey(const Key('content')), findsOneWidget);
    expect(find.byType(WideRailLayout), findsNothing);
    expect(find.byType(RailSpaceTabs), findsNothing);
    expect(find.byType(SpaceIconRail), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('opens on the configured edge and closes on a scrim tap', (
    tester,
  ) async {
    final db = await _memoryDatabaseWithOneTab();
    addTearDown(db.close);

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _harness(
        overrides: _panelOverrides(db, compactRailSide: CompactRailSide.right),
        viewportWidth: 360,
      ),
    );
    await _settle(tester);

    // Closed: the panel content exists (kept mounted, translated off-screen)
    // but is not on screen.
    expect(find.byType(RailSpaceTabs), findsOneWidget);
    final closedRect = tester.getRect(find.byType(WideRailLayout));
    expect(closedRect.left, greaterThanOrEqualTo(360));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WideRailLayout)),
    );
    container.read(compactRailPanelOpenProvider.notifier).open();
    await _settle(tester);

    final openRect = tester.getRect(find.byType(WideRailLayout));
    // Docked to the right edge once open.
    expect(openRect.right, closeTo(360, 0.5));
    expect(container.read(compactRailPanelOpenProvider), isTrue);

    // Tapping the scrim closes it.
    await tester.tapAt(const Offset(10, 400));
    await _settle(tester);

    expect(container.read(compactRailPanelOpenProvider), isFalse);

    await _disposeTree(tester);
  });

  testWidgets(
    'the panel carries the address row, like the wide rail composes it',
    (tester) async {
      final db = await _memoryDatabaseWithOneTab();
      addTearDown(db.close);

      await tester.pumpWidget(
        _harness(
          overrides: _panelOverrides(db, compactRailSide: CompactRailSide.left),
          viewportWidth: 360,
        ),
      );
      await _settle(tester);

      // No compact bar's own widgets exist — only the wide rail's blocks,
      // reused inside the panel.
      expect(find.byType(WideRailLayout), findsOneWidget);
      expect(find.byKey(WideRailLayout.urlRowKey), findsOneWidget);
      expect(find.byKey(WideRailLayout.tabsKey), findsOneWidget);
      expect(find.byKey(WideRailLayout.spacesKey), findsOneWidget);

      await _disposeTree(tester);
    },
  );

  testWidgets('the panel clears the top system inset (status bar)', (
    tester,
  ) async {
    final db = await _memoryDatabaseWithOneTab();
    addTearDown(db.close);

    await tester.pumpWidget(
      _harness(
        overrides: _panelOverrides(db, compactRailSide: CompactRailSide.left),
        viewportWidth: 360,
        viewPadding: const EdgeInsets.only(top: 40),
      ),
    );
    await _settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WideRailLayout)),
    );
    container.read(compactRailPanelOpenProvider.notifier).open();
    await _settle(tester);

    final panelRect = tester.getRect(find.byType(WideRailLayout));
    expect(panelRect.top, greaterThanOrEqualTo(40));

    await _disposeTree(tester);
  });

  testWidgets('stays open when a tab is selected', (tester) async {
    final db = await _memoryDatabaseWithOneTab();
    addTearDown(db.close);

    await tester.pumpWidget(
      _harness(
        overrides: _panelOverrides(db, compactRailSide: CompactRailSide.left),
        viewportWidth: 360,
      ),
    );
    await _settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WideRailLayout)),
    );
    container.read(compactRailPanelOpenProvider.notifier).open();
    await _settle(tester);
    expect(container.read(compactRailPanelOpenProvider), isTrue);

    // Hunting for a tab means tapping through several of them, so picking one
    // leaves the panel up; only a tap on the scrim closes it.
    (container.read(selectedTabProvider.notifier) as _SettableSelectedTab)
            .selected =
        'tab-1';
    await _settle(tester);

    expect(container.read(compactRailPanelOpenProvider), isTrue);

    await tester.tapAt(const Offset(350, 400));
    await _settle(tester);

    expect(container.read(compactRailPanelOpenProvider), isFalse);

    await _disposeTree(tester);
  });

  testWidgets(
    'on Either side the panel moves to the swiped edge as the gesture starts',
    (tester) async {
      final db = await _memoryDatabaseWithOneTab();
      addTearDown(db.close);

      await tester.pumpWidget(
        _harness(
          overrides: _panelOverrides(
            db,
            compactRailSide: CompactRailSide.either,
          ),
          viewportWidth: 360,
        ),
      );
      await _settle(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(WideRailLayout)),
      );
      final observer =
          tester.state(find.byType(CompactRailSlideOut))
              as WidgetsBindingObserver;

      // The side has to land on the *start* of the gesture, not when it
      // commits: the drag animates from the progress events in between, and
      // a side applied at the end played the whole animation on the edge the
      // panel last opened from.
      expect(
        observer.handleStartBackGesture(_backGesture(SwipeEdge.right)),
        isTrue,
      );
      expect(container.read(compactRailPanelSideProvider), RailSide.right);

      observer.handleCancelBackGesture();
      await _settle(tester);

      expect(
        observer.handleStartBackGesture(_backGesture(SwipeEdge.left)),
        isTrue,
      );
      expect(container.read(compactRailPanelSideProvider), RailSide.left);

      await _disposeTree(tester);
    },
  );
}

/// A predictive back gesture just starting at [edge]. `fromMap` is the only
/// public way to build one.
PredictiveBackEvent _backGesture(SwipeEdge edge) =>
    PredictiveBackEvent.fromMap(<String?, Object?>{
      'touchOffset': const <Object?>[0.0, 400.0],
      'progress': 0.0,
      'swipeEdge': edge.index,
    });
