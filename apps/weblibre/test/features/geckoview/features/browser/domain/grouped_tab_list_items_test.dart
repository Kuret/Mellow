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
        browserRestoreCompleteProvider.overrideWith(_Restored.new),
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
          (ref) => GeneralSettings.withDefaults(),
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
    // The provider chains stream providers (tree rows, then their summaries
    // and folders); each hop is delivered on a later event-loop turn.
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(provider).value;
  }

  Future<List<TabListItemEntity>> readVisible(
    ProviderContainer container,
  ) async {
    final provider = visibleTabListItemsProvider(
      spaceUuid: _space,
      scope: TabListScope.presentation,
    );
    container.listen(provider, (_, _) {}, fireImmediately: true);
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
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
    // Folders live in the pinned section, ahead of the normal tabs.
    expect((await read(container)).map(label), [
      '[F:4]@0',
      'f1@1',
      'f2+@1',
      'f2c>@2',
      '[N:1]@1',
      'n1@2',
      'a@0',
      'c@0',
    ]);
  });

  test('pinned folder members render inside their folder', () async {
    // Zen's projection: folder members are pinned tabs with a folder_id.
    // The flat Pinned section holds only root pinned tabs; the folder's
    // members and sub-folders form one order_key sequence below the folder.
    final container = makeContainer(
      tabs: const [
        _Tab('t4', 'a', shelf: TabShelf.pinned),
        _Tab('t1', 'a', shelf: TabShelf.pinned, folderId: 'F'),
        _Tab('t2', 'a', shelf: TabShelf.pinned, folderId: 'G'),
        _Tab('t3', 'c'),
      ],
      folders: [
        _folder('F', 'b'),
        _folder('G', 'b', parentFolderId: 'F'),
      ],
    );
    expect((await read(container)).map(label), [
      't4@0',
      '[F:2]@0',
      't1@1',
      '[G:1]@1',
      't2@2',
      't3@0',
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
    expect((await read(container)).map(label), ['[F:1]@0', 'a@0', 'c@0']);
  });

  test(
    'folders sit in the Pinned section among root pinned tabs by order_key',
    () async {
      final container = makeContainer(
        tabs: const [
          _Tab('n1', 'b'),
          _Tab('p2', 'd', shelf: TabShelf.pinned),
          _Tab('f1', 'x', shelf: TabShelf.pinned, folderId: 'F'),
          _Tab('p1', 'a', shelf: TabShelf.pinned),
        ],
        folders: [_folder('F', 'c')],
      );
      // Zen's strip: pinned tabs and folders interleaved by order_key, the
      // folder followed by its members; the normal tabs after all of them.
      expect((await read(container)).map(label), [
        'p1@0',
        '[F:1]@0',
        'f1@1',
        'p2@0',
        'n1@0',
      ]);
    },
  );

  test(
    'presentation flattening keeps folder members under their folder',
    () async {
      final container = makeContainer(
        tabs: const [
          _Tab('m', 'a', shelf: TabShelf.pinned, folderId: 'F'),
          _Tab('n', 'b'),
          _Tab('p', 'c', shelf: TabShelf.pinned),
        ],
        folders: [_folder('F', 'b')],
      );
      // Only the root pinned tab floats to the front; the folder's pinned
      // member stays below its folder row.
      expect((await readVisible(container)).map(label), [
        'p@0',
        '[F:1]@0',
        'm@1',
        'n@0',
      ]);
    },
  );

  test('every surface renders order_key ascending', () async {
    final container = makeContainer(
      tabs: const [_Tab('b', 'b'), _Tab('a', 'a'), _Tab('c', 'c')],
    );
    expect((await readVisible(container)).map(label), ['a@0', 'b@0', 'c@0']);
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

  test('rows carry their shelf, pinned ones TabShelf.pinned', () async {
    final container = makeContainer(
      tabs: const [
        _Tab('a', 'a'),
        _Tab('p', 'b', shelf: TabShelf.pinned),
        _Tab('pc', 'c', parentId: 'p', shelf: TabShelf.pinned),
        _Tab('d', 'd'),
      ],
    );
    final items = (await read(container)).whereType<TabListTabItem>();
    expect(
      {for (final item in items) item.tabId: item.shelf},
      {
        'p': TabShelf.pinned,
        'pc': TabShelf.pinned,
        'a': TabShelf.normal,
        'd': TabShelf.normal,
      },
    );
    // The pinned section is a leading run: every pinned row precedes every
    // normal one.
    final shelves = [for (final item in items) item.shelf];
    expect(shelves, [
      TabShelf.pinned,
      TabShelf.pinned,
      TabShelf.normal,
      TabShelf.normal,
    ]);
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

/// The restore has completed, so only engine-listed and cold rows render.
class _Restored extends BrowserRestoreComplete {
  @override
  bool build() => true;
}
