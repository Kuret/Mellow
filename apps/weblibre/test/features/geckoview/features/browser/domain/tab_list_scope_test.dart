import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_list_scope.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_entity.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

/// Four tabs in the unassigned container, `order_key` a < b < b1 < c.
final _rows = [
  _row(id: 'a', orderKey: 'a'),
  _row(id: 'b', orderKey: 'b'),
  _row(id: 'b1', orderKey: 'c'),
  _row(id: 'c', orderKey: 'd'),
];

({String id, String orderKey}) _row({
  required String id,
  required String orderKey,
}) => (id: id, orderKey: orderKey);

TabSummary _summary(
  ({String id, String orderKey}) row, {
  required TabShelf shelf,
}) => TabSummary(
  id: row.id,
  engineTabId: row.id,
  source: TabSource.manual,
  parentId: null,
  containerId: null,
  spaceUuid: null,
  folderId: null,
  splitId: null,
  splitIndex: null,
  tabShelf: shelf,
  orderKey: row.orderKey,
  url: Uri.parse('https://${row.id}.example'),
  title: row.id,
  iconUrl: null,
  staticLabel: null,
  tabMode: TabModeDbValue.regular,
  isProbablyReaderable: null,
  timestamp: DateTime(2024),
);

TabSortKeys _sortKeys(String title, {TabMode mode = const RegularTabMode()}) =>
    TabSortKeys(
      tabMode: mode,
      titleOrAuthority: title,
      url: 'https://$title.example',
    );

void main() {
  ProviderContainer makeContainer({
    TabViewFilterOptions? filterOptions,
    Set<String> pinned = const {},
    Map<String, TabSortKeys>? sortKeys,
    List<({String id, String orderKey})>? rows,
  }) {
    final container = ProviderContainer(
      overrides: [
        watchSpaceTabsDataProvider(null).overrideWith(
          (ref) => Stream.value([
            for (final row in rows ?? _rows)
              _summary(
                row,
                shelf: pinned.contains(row.id)
                    ? TabShelf.pinned
                    : TabShelf.normal,
              ),
          ]),
        ),
        browserRestoreCompleteProvider.overrideWith(_Restored.new),
        tabListProvider.overrideWith(
          () => _FakeTabList((rows ?? _rows).map((row) => row.id).toList()),
        ),
        tabSortKeysProvider.overrideWith(
          (ref) => EquatableValue(
            sortKeys ??
                {
                  'a': _sortKeys('alpha'),
                  'b': _sortKeys('bravo'),
                  'b1': _sortKeys('bravo-child'),
                  'c': _sortKeys('charlie'),
                },
          ),
        ),
        watchTabShelvesProvider.overrideWith(
          (ref) => Stream.value({for (final id in pinned) id: TabShelf.pinned}),
        ),
        watchTabTimestampsProvider.overrideWith(
          (ref) => Stream.value(const <String, DateTime>{}),
        ),
        generalSettingsWithDefaultsProvider.overrideWith(
          (ref) => GeneralSettings.withDefaults(
            sequentialTabNavigationCrossContainers: false,
          ),
        ),
        tabViewFilterControllerProvider.overrideWith(
          () => _FakeFilterController(
            filterOptions ?? TabViewFilterOptions.withDefaults(),
          ),
        ),
        selectedSpaceProvider.overrideWith(() => _FakeSelectedSpace()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Reads an order once its underlying streams have delivered.
  Future<List<String>> readOrder(
    ProviderContainer container,
    TabListScope scope,
  ) async {
    final provider = visibleTabListItemsProvider(spaceUuid: null, scope: scope);
    container.listen(provider, (_, _) {}, fireImmediately: true);
    await _settle();
    return container
        .read(provider)
        .value
        .whereType<TabListTabItem>()
        .map((item) => item.tabId)
        .toList();
  }

  Future<List<String>?> readNavigationOrder(ProviderContainer container) async {
    container.listen(
      sequentialTabNavigationOrderProvider,
      (_, _) {},
      fireImmediately: true,
    );
    await _settle();
    return container.read(sequentialTabNavigationOrderProvider).value;
  }

  group('presentation scope ignores tray-only state', () {
    test('the baseline order is storage order', () async {
      final container = makeContainer();

      expect(await readOrder(container, TabListScope.presentation), [
        'a',
        'b',
        'b1',
        'c',
      ]);
    });

    test(
      'a tab-type filter hides rows in the tray but not outside it',
      () async {
        final container = makeContainer(
          filterOptions: TabViewFilterOptions.withDefaults().copyWith
              .tabTypeFilter(TabTypeFilter.privateOnly),
          sortKeys: {
            'a': _sortKeys('alpha'),
            'b': _sortKeys('bravo', mode: const PrivateTabMode()),
            'b1': _sortKeys('bravo-child'),
            'c': _sortKeys('charlie'),
          },
        );

        expect(await readOrder(container, TabListScope.tray), ['b']);
        expect(await readOrder(container, TabListScope.presentation), [
          'a',
          'b',
          'b1',
          'c',
        ]);
      },
    );

    test('the tray sort reorders the tray only', () async {
      final container = makeContainer(
        filterOptions: TabViewFilterOptions.withDefaults().copyWith.sortType(
          TabSortType.titleDesc,
        ),
      );

      expect(await readOrder(container, TabListScope.tray), [
        'c',
        'b1',
        'b',
        'a',
      ]);
      expect(await readOrder(container, TabListScope.presentation), [
        'a',
        'b',
        'b1',
        'c',
      ]);
    });
  });

  group('order', () {
    test('both scopes render storage order', () async {
      final container = makeContainer();

      expect(await readOrder(container, TabListScope.tray), [
        'a',
        'b',
        'b1',
        'c',
      ]);
      expect(await readOrder(container, TabListScope.presentation), [
        'a',
        'b',
        'b1',
        'c',
      ]);
    });
  });

  group('pinned handling', () {
    test(
      'a pinned tab leads both orders, so no surface disagrees about it',
      () async {
        // The stock configuration: pinned-first on. This is the pair that
        // disagreed in issue #603 — the bar hoisted the pinned row while
        // navigation kept walking it where storage put it.
        final container = makeContainer(pinned: {'b1'});

        expect(await readOrder(container, TabListScope.tray), [
          'b1',
          'a',
          'b',
          'c',
        ]);
        expect(await readOrder(container, TabListScope.presentation), [
          'b1',
          'a',
          'b',
          'c',
        ]);
      },
    );
  });

  group('sequentialTabNavigationOrder', () {
    test('matches the presentation order the switcher renders', () async {
      final container = makeContainer(
        filterOptions: TabViewFilterOptions.withDefaults().copyWith.sortType(
          TabSortType.titleDesc,
        ),
        pinned: {'b1'},
      );

      final rendered = await readOrder(container, TabListScope.presentation);
      final navigation = await readNavigationOrder(container);

      expect(navigation, rendered);
      // ...and specifically not the tray's, which the tray's sort moved.
      expect(navigation, isNot(await readOrder(container, TabListScope.tray)));
    });

    test('reaches every tab, so no swipe can skip one', () async {
      final container = makeContainer(pinned: {'b1'});

      expect(
        (await readNavigationOrder(container))?.toSet(),
        _rows.map((row) => row.id).toSet(),
      );
    });
  });
}

/// The grouped list chains several stream providers (row summaries, then
/// folders); each hop is delivered on a later event-loop turn.
Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeTabList extends TabList {
  _FakeTabList(this.ids);

  final List<String> ids;

  @override
  EquatableValue<List<String>> build() => EquatableValue(ids);
}

class _FakeFilterController extends TabViewFilterController {
  _FakeFilterController(this.options);

  final TabViewFilterOptions options;

  @override
  TabViewFilterOptions build() => options;
}

class _FakeSelectedSpace extends SelectedSpace {
  @override
  String? build() => null;
}

/// The restore has completed, so only engine-listed and cold rows render.
class _Restored extends BrowserRestoreComplete {
  @override
  bool build() => true;
}
