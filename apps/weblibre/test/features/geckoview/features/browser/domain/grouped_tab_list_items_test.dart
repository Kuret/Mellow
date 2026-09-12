import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_list_scope.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/entities/tab_view_filter_options.dart';
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/controllers/tab_view_controllers.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_entity.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

const _space = '{space}';

/// A row of the space: a root tab (or child of [parentId]) with its shelf,
/// folder, split and liveness.
class _Tab {
  final String id;
  final String orderKey;
  final String? parentId;
  final TabShelf shelf;
  final String? folderId;
  final String? splitId;
  final int? splitIndex;
  final bool cold;

  const _Tab(
    this.id,
    this.orderKey, {
    this.parentId,
    this.shelf = TabShelf.normal,
    this.folderId,
    this.splitId,
    this.splitIndex,
    this.cold = false,
  });

  TabsWithRootAndDepthResult get row => TabsWithRootAndDepthResult(
    id: id,
    parentId: parentId,
    orderKey: orderKey,
    rootId: parentId ?? id,
    depth: parentId == null ? 0 : 1,
  );

  TabSummary get summary => TabSummary(
    id: id,
    engineTabId: cold ? null : id,
    source: TabSource.manual,
    parentId: parentId,
    containerId: null,
    spaceUuid: _space,
    folderId: folderId,
    splitId: splitId,
    splitIndex: splitIndex,
    tabShelf: shelf,
    orderKey: orderKey,
    url: Uri.parse('https://$id.example'),
    title: id,
    iconUrl: null,
    staticLabel: null,
    tabMode: TabModeDbValue.regular,
    isProbablyReaderable: null,
    timestamp: DateTime(2024),
  );
}

TabFolderData _folder(
  String id,
  String orderKey, {
  String? parentFolderId,
  bool collapsed = false,
}) => TabFolderData(
  id: id,
  name: id,
  spaceUuid: _space,
  parentFolderId: parentFolderId,
  isCollapsed: collapsed,
  orderKey: orderKey,
);

void main() {
  ProviderContainer makeContainer({
    required List<_Tab> tabs,
    List<TabFolderData> folders = const [],
    Set<String>? liveIds,
    TabDirection direction = TabDirection.oldestFirst,
  }) {
    final live =
        liveIds ??
        {
          for (final tab in tabs)
            if (!tab.cold) tab.id,
        };
    final container = ProviderContainer(
      overrides: [
        watchTabsWithRootAndDepthProvider(
          _space,
        ).overrideWith((ref) => Stream.value([for (final t in tabs) t.row])),
        watchSpaceTabsDataProvider(_space).overrideWith(
          (ref) => Stream.value([for (final t in tabs) t.summary]),
        ),
        watchFoldersProvider(
          _space,
        ).overrideWith((ref) => Stream.value(folders)),
        tabListProvider.overrideWith(() => _FakeTabList(live.toList())),
        tabSortKeysProvider.overrideWith(
          (ref) => EquatableValue({
            for (final tab in tabs)
              if (live.contains(tab.id))
                tab.id: TabSortKeys(
                  tabMode: const RegularTabMode(),
                  titleOrAuthority: tab.id,
                  url: 'https://${tab.id}.example',
                ),
          }),
        ),
        watchTabShelvesProvider.overrideWith(
          (ref) => Stream.value({for (final t in tabs) t.id: t.shelf}),
        ),
        watchTabTimestampsProvider.overrideWith(
          (ref) => Stream.value(const <String, DateTime>{}),
        ),
        generalSettingsWithDefaultsProvider.overrideWith(
          (ref) => GeneralSettings.withDefaults(
            tabListDirection: direction,
            tabBarDirection: direction,
          ),
        ),
        tabViewFilterControllerProvider.overrideWith(
          () => _FakeFilterController(TabViewFilterOptions.withDefaults()),
        ),
        collapsedGroupsProvider.overrideWith(() => _FakeCollapsedGroups()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<List<TabListItemEntity>> read(ProviderContainer container) async {
    final provider = groupedTabListItemsProvider(
      spaceUuid: _space,
      scope: TabListScope.tray,
    );
    container.listen(provider, (_, _) {}, fireImmediately: true);
    await Future<void>.delayed(Duration.zero);
    return container.read(provider).value;
  }

  String label(TabListItemEntity item) => switch (item) {
    TabListStandaloneItem(:final tabId, :final depth) => '$tabId@$depth',
    TabListParentGroup(:final tabId, :final depth) => '$tabId+@$depth',
    TabListChildItem(:final tabId, :final depth) => '$tabId>@$depth',
    TabListFolderItem(:final folderId, :final depth, :final childCount) =>
      '[$folderId:$childCount]@$depth',
  };

  test('the pinned shelf comes first, in its own order', () async {
    final container = makeContainer(
      tabs: const [
        _Tab('a', 'a'),
        _Tab('p2', 'b', shelf: TabShelf.pinned),
        _Tab('c', 'c'),
        _Tab('p1', 'a', shelf: TabShelf.pinned),
      ],
    );
    expect((await read(container)).map(label), ['p1@0', 'p2@0', 'a@0', 'c@0']);
  });

  test('a folder row is followed by its indented contents', () async {
    final container = makeContainer(
      tabs: const [
        _Tab('a', 'a'),
        _Tab('f1', 'a', folderId: 'F'),
        _Tab('f2', 'b', folderId: 'F'),
        _Tab('f2c', 'c', folderId: 'F', parentId: 'f2'),
        _Tab('n1', 'a', folderId: 'N'),
        _Tab('c', 'c'),
      ],
      folders: [
        _folder('F', 'b'),
        _folder('N', 'z', parentFolderId: 'F'),
      ],
    );
    expect((await read(container)).map(label), [
      'a@0',
      '[F:4]@0',
      'f1@1',
      'f2+@1',
      'f2c>@2',
      '[N:1]@1',
      'n1@2',
      'c@0',
    ]);
  });

  test('a collapsed folder hides its contents', () async {
    final container = makeContainer(
      tabs: const [
        _Tab('a', 'a'),
        _Tab('f1', 'a', folderId: 'F'),
        _Tab('c', 'c'),
      ],
      folders: [_folder('F', 'b', collapsed: true)],
    );
    expect((await read(container)).map(label), ['a@0', '[F:1]@0', 'c@0']);
  });

  test('cold rows are listed, live rows the engine lost are not', () async {
    final container = makeContainer(
      tabs: const [
        _Tab('live', 'a'),
        _Tab('cold', 'b', cold: true),
        _Tab('lost', 'c'),
      ],
      liveIds: {'live'},
    );
    expect((await read(container)).map(label), ['live@0', 'cold@0']);
  });

  test('essentials never appear', () async {
    final container = makeContainer(
      tabs: const [
        _Tab('a', 'a'),
        _Tab('e', 'b', shelf: TabShelf.essential),
      ],
    );
    expect((await read(container)).map(label), ['a@0']);
  });

  test('split members stay adjacent in splitIndex order', () async {
    final container = makeContainer(
      tabs: const [
        _Tab('m1', 'b', splitId: 'S', splitIndex: 1),
        _Tab('x', 'c'),
        _Tab('m0', 'd', splitId: 'S', splitIndex: 0),
        _Tab('a', 'a'),
      ],
    );
    expect((await read(container)).map(label), ['a@0', 'm0@0', 'm1@0', 'x@0']);
    final newestFirst = makeContainer(
      tabs: const [
        _Tab('m1', 'b', splitId: 'S', splitIndex: 1),
        _Tab('x', 'c'),
        _Tab('m0', 'd', splitId: 'S', splitIndex: 0),
        _Tab('a', 'a'),
      ],
      direction: TabDirection.newestFirst,
    );
    expect((await read(newestFirst)).map(label), [
      'x@0',
      'm0@0',
      'm1@0',
      'a@0',
    ]);
  });
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

class _FakeCollapsedGroups extends CollapsedGroups {
  @override
  Set<String> build() => const {};
}
