import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/spaces_sync/data/models/zen_records.dart';
import 'package:weblibre/features/spaces_sync/data/snapshot_store.dart';
import 'package:weblibre/features/spaces_sync/data/sync15/key_bundle.dart';
import 'package:weblibre/features/spaces_sync/data/sync15/record_crypto.dart';
import 'package:weblibre/features/spaces_sync/domain/providers.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_applier.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_projection.dart';
import 'package:weblibre/features/sync/domain/repositories/sync.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

import '../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';

/// A [TabRepository] whose closes are plain row deletes: `closeTabs` records
/// the closed-tab tombstone and the deletion-ledger entry the real one does,
/// `closeTabsFromSync` records neither.
class FakeSyncTabRepository extends TabRepository {
  final closedFromSync = <String>[];

  @override
  void build() {}

  @override
  Future<void> closeTabs(List<String> tabIds) async {
    final db = ref.read(tabDatabaseProvider);
    await db.tabDao.addClosedTabTombstones(tabIds);
    // The real repository notes the witnessed deletion here too; that ledger
    // entry, not the undo buffer, is what the upload path projects from.
    for (final tabId in await db.tabDao.syncableTabIdsAmong(tabIds)) {
      await db.syncStateDao.recordDeletion(tabId, 'tab');
    }
    await (db.tab.delete()..where((t) => t.id.isIn(tabIds))).go();
  }

  @override
  Future<void> closeTab(String tabId) => closeTabs([tabId]);

  @override
  Future<void> closeTabsFromSync(List<String> tabIds) async {
    closedFromSync.addAll(tabIds);
    final db = ref.read(tabDatabaseProvider);
    await (db.tab.delete()..where((t) => t.id.isIn(tabIds))).go();
  }

  /// The engine sessions the applier queued while its transaction was open,
  /// drained without an engine.
  final drainedEngineCloses = <String>[];

  @override
  Future<void> drainPendingEngineCloses() async {
    final db = ref.read(tabDatabaseProvider);
    final pending = await db.tabDao.pendingEngineCloseIds();
    drainedEngineCloses.addAll(pending);
    await db.tabDao.deletePendingEngineCloses(pending);
  }
}

/// In-memory settings: what the service reads and writes between runs.
class FakeZenSettingsRepository extends ZenSettingsRepository {
  FakeZenSettingsRepository(this.current);

  ZenSettings current;

  @override
  Stream<ZenSettings> build() => Stream.value(current);

  @override
  Future<ZenSettings> fetchSettings() async => current;

  @override
  Future<void> updateSettings(UpdateZenSettingsFunc updateWithCurrent) async {
    current = updateWithCurrent(current);
    state = AsyncData(current);
  }
}

/// Never completes restore, so the service schedules nothing on its own and
/// every sync in a test is the one the test asked for.
class NeverRestored extends BrowserRestoreComplete {
  @override
  bool build() => false;
}

/// A container with an in-memory [TabDatabase] and a [FakeSyncTabRepository].
({ProviderContainer container, TabDatabase db, FakeSyncTabRepository tabs})
openApplierHarness({List<Override> overrides = const []}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = openTestTabDatabase();
  final tabs = FakeSyncTabRepository();
  final container = ProviderContainer(
    overrides: [
      tabDatabaseProvider.overrideWithValue(db),
      tabRepositoryProvider.overrideWith(() => tabs),
      ...overrides,
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return (container: container, db: db, tabs: tabs);
}

// --- fixtures -----------------------------------------------------------------

const workGuid = '11111111-1111-4111-8111-111111111111';
const bankGuid = '22222222-2222-4222-8222-222222222222';
const space1 = '{aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa}';
const space2 = '{bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb}';

ZenIncomingRecord record(ZenRecordData data) =>
    ZenIncomingRecord(ZenCleartext(id: data.recordId, data: data));

ZenTabRecord tabRecord(
  String id, {
  String? url,
  String title = '',
  String icon = '',
  String? containerGuid,
  bool essential = false,
  bool pinned = false,
  String? workspaceUuid,
  String? folderId,
  String? staticLabel,
  bool hasStaticIcon = false,
  bool defaultContainer = false,
}) => ZenTabRecord(
  tabId: id,
  url: url ?? 'https://$id.example/page',
  title: title,
  icon: icon,
  containerGuid: containerGuid,
  essential: essential,
  pinned: essential || pinned,
  workspaceUuid: essential ? null : workspaceUuid,
  folderId: folderId,
  staticLabel: staticLabel,
  hasStaticIcon: hasStaticIcon,
  defaultContainer: defaultContainer,
);

/// Every kind at least once: two containers (one referenced built-in on top),
/// two spaces with themes, tabs across all three shelves, nested folders (one
/// live), a split, the layout, plus a seventh unknown kind.
List<ZenIncoming> roundTripFixture() => [
  record(
    ZenContainerRecord(
      guid: workGuid,
      name: 'Work',
      icon: 'briefcase',
      color: 'orange',
    ),
  ),
  record(
    ZenContainerRecord(guid: bankGuid, name: 'Bank', icon: 'dollar', color: ''),
  ),
  record(
    ZenSpaceRecord(
      uuid: space1,
      name: 'Personal',
      icon: null,
      theme: {
        'type': 'gradient',
        'gradientColors': [
          {
            'c': [12, 34, 56],
            'isCustom': false,
          },
        ],
        'opacity': 0.5,
        'texture': null,
      },
      containerGuid: null,
      // Zen's strip order: the pinned section (pinned tabs, folders, pinned
      // splits) first, then the normal tabs and splits.
      children: ['t1', 'f1', 't2', 'sp1'],
    ),
  ),
  record(
    ZenSpaceRecord(
      uuid: space2,
      name: 'Work',
      icon: '💼',
      theme: null,
      containerGuid: workGuid,
      children: const [],
    ),
  ),
  record(
    ZenFolderRecord(
      folderId: 'f1',
      name: 'Research',
      icon: null,
      workspaceUuid: space1,
      parentFolderId: null,
      live: null,
      children: ['t3', 'f2'],
    ),
  ),
  record(
    ZenFolderRecord(
      folderId: 'f2',
      name: 'Feeds',
      icon: 'chrome://browser/skin/zen-icons/rss.svg',
      workspaceUuid: space1,
      parentFolderId: 'f1',
      live: {
        'provider': 'rss',
        'config': {'url': 'https://example.org/feed', 'limit': 10},
      },
      children: ['t8', 't9'],
    ),
  ),
  record(
    tabRecord(
      't1',
      title: 'Mail',
      pinned: true,
      workspaceUuid: space1,
      containerGuid: workGuid,
      staticLabel: 'Mail',
    ),
  ),
  record(tabRecord('t2', title: 'Two', workspaceUuid: space1)),
  record(
    tabRecord(
      't3',
      title: 'Three',
      // Folder members are pinned: Zen keeps folders in the pinned section.
      pinned: true,
      workspaceUuid: space1,
      folderId: 'f1',
      containerGuid: 'builtin-2',
      defaultContainer: true,
    ),
  ),
  record(
    tabRecord(
      't4',
      title: 'Essential',
      essential: true,
      icon: 'data:image/png;base64,AAAA',
      hasStaticIcon: true,
    ),
  ),
  record(tabRecord('t5', title: 'Left', workspaceUuid: space1)),
  record(tabRecord('t6', title: 'Right', workspaceUuid: space1)),
  // Two pinned members of the nested folder f2 (parent f1).
  record(
    tabRecord(
      't8',
      title: 'Feed A',
      pinned: true,
      workspaceUuid: space1,
      folderId: 'f2',
    ),
  ),
  record(
    tabRecord(
      't9',
      title: 'Feed B',
      pinned: true,
      workspaceUuid: space1,
      folderId: 'f2',
    ),
  ),
  record(
    tabRecord(
      't7',
      title: 'Bank essential',
      essential: true,
      containerGuid: bankGuid,
    ),
  ),
  record(
    ZenSplitRecord(
      splitId: 'sp1',
      gridType: 'vsep',
      pinned: false,
      tabs: ['t5', 't6'],
      workspaceUuid: space1,
      folderId: null,
    ),
  ),
  record(
    ZenLayoutRecord(
      spaces: [space1, space2],
      essentials: {
        'default': ['t4'],
        bankGuid: ['t7'],
      },
    ),
  ),
  ZenIncomingUnknownKind(
    id: 'x1',
    kind: 'gizmo',
    rawData: {
      'foo': 1,
      'bar': [1, 2, 'three'],
      'nested': {'z': null},
    },
  ),
];

Map<String, Map<String, Object?>> cleartextsOf(List<ZenIncoming> records) {
  final result = <String, Map<String, Object?>>{};
  for (final record in records) {
    switch (record) {
      case ZenIncomingRecord(:final cleartext):
        result[cleartext.id] = cleartext.toJson();
      case ZenIncomingUnknownKind(:final id, :final kind, :final rawData):
        result[id] = {'id': id, 'kind': kind, 'data': rawData};
      case ZenIncomingTombstone(:final id):
        result[id] = {'id': id, 'deleted': true};
    }
  }
  return result;
}

Future<List<String>> tabIds(TabDatabase db) async {
  final rows = await (db.selectOnly(db.tab)..addColumns([db.tab.id])).get();
  return [for (final row in rows) row.read(db.tab.id)!];
}

// --- fake Sync 1.5 server -------------------------------------------------------

final kSync = List<int>.generate(64, (i) => (i * 7 + 3) & 0xff);
final syncKeyBundle = KeyBundle.fromSyncKey(kSync);
final collectionBundle = KeyBundle(
  encryptionKey: List<int>.generate(32, (i) => 200 - i),
  hmacKey: List<int>.generate(32, (i) => 100 + i),
);

const tokenServerUrl = 'https://token.example/1.0/sync/1.5';
const storageBase = 'https://storage.example/1.5/123456';

SpacesSyncCredentials testCredentials() => (
  accessToken: 'access-token',
  keyId: '1700000000000-abc',
  syncKeyBase64Url: base64Url.encode(kSync),
  tokenServerUrl: tokenServerUrl,
  expiresAtEpochSeconds: 4102444800,
);

/// Tokenserver + storage for one account, faked with `MockClient`.
class FakeSyncServer {
  FakeSyncServer({this.engineVersion = 3, this.syncId = 'spaces-sync-1'});

  int? engineVersion;
  String syncId;
  bool omitSpacesEngine = false;
  bool omitMetaGlobal = false;

  /// id → (cleartext, modified seconds)
  final records =
      <String, ({Map<String, Object?> cleartext, double modified})>{};
  double collectionModified = 1000;

  /// Every POST body decrypted, one list per request.
  final uploads = <List<Map<String, Object?>>>[];
  final requests = <http.Request>[];
  int rejectNextPosts = 0;

  int get postCount =>
      requests.where((request) => request.method == 'POST').length;

  Iterable<http.Request> get fetches => requests.where(
    (request) =>
        request.method == 'GET' && request.url.path.endsWith('/storage/spaces'),
  );

  void put(Map<String, Object?> cleartext, {double? modified}) {
    collectionModified = modified ?? collectionModified + 1;
    records[cleartext['id']! as String] = (
      cleartext: cleartext,
      modified: collectionModified,
    );
  }

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (request.url.host == 'token.example') {
      expect(request.headers['Authorization'], 'Bearer access-token');
      expect(request.headers['X-KeyID'], '1700000000000-abc');
      return http.Response(
        jsonEncode({
          'id': 'hawk-id',
          'key': 'hawk-key',
          'uid': 123456,
          'api_endpoint': storageBase,
          'duration': 3600,
          'hashalg': 'sha256',
        }),
        200,
      );
    }
    expect(request.headers['Authorization'], startsWith('Hawk '));
    if (path.endsWith('/storage/meta/global')) {
      if (omitMetaGlobal) {
        return http.Response('', 404);
      }
      return http.Response(
        jsonEncode({
          'id': 'global',
          'modified': 900.0,
          'payload': jsonEncode({
            'syncID': 'global-sync-id',
            'storageVersion': 5,
            'engines': {
              'bookmarks': {'version': 2, 'syncID': 'bm'},
              if (!omitSpacesEngine)
                'spaces': {'version': engineVersion, 'syncID': syncId},
            },
            'declined': <String>[],
          }),
        }),
        200,
      );
    }
    if (path.endsWith('/storage/crypto/keys')) {
      final encrypted = await encryptPayload({
        'id': 'keys',
        'collection': 'crypto',
        'default': [
          base64Encode(collectionBundle.encryptionKey),
          base64Encode(collectionBundle.hmacKey),
        ],
        'collections': <String, Object?>{},
      }, syncKeyBundle);
      return http.Response(
        jsonEncode({
          'id': 'keys',
          'modified': 900.0,
          'payload': jsonEncode(encrypted.toJson()),
        }),
        200,
      );
    }
    if (path.endsWith('/info/collections')) {
      return http.Response(jsonEncode({'spaces': collectionModified}), 200);
    }
    if (path.endsWith('/storage/spaces') && request.method == 'GET') {
      final newer = double.tryParse(request.url.queryParameters['newer'] ?? '');
      final ids = request.url.queryParameters['ids']?.split(',').toSet();
      final selected = records.entries.where((entry) {
        if (ids != null) {
          return ids.contains(entry.key);
        }
        return newer == null || entry.value.modified > newer;
      });
      final bsos = <Map<String, Object?>>[];
      for (final entry in selected) {
        final encrypted = await encryptPayload(
          entry.value.cleartext,
          collectionBundle,
        );
        bsos.add({
          'id': entry.key,
          'modified': entry.value.modified,
          'payload': jsonEncode(encrypted.toJson()),
        });
      }
      return http.Response(
        jsonEncode(bsos),
        200,
        headers: {'X-Last-Modified': collectionModified.toStringAsFixed(2)},
      );
    }
    if (path.endsWith('/storage/spaces') && request.method == 'POST') {
      final since = double.parse(request.headers['X-If-Unmodified-Since']!);
      if (rejectNextPosts > 0 || since < collectionModified) {
        if (rejectNextPosts > 0) {
          rejectNextPosts--;
        }
        return http.Response('', 412);
      }
      final body = jsonDecode(request.body) as List;
      final batch = <Map<String, Object?>>[];
      collectionModified += 1;
      for (final element in body) {
        final bso = (element as Map).cast<String, Object?>();
        final cleartext =
            (await decryptPayload(
                  EncryptedPayload.fromJson(
                    (jsonDecode(bso['payload']! as String) as Map)
                        .cast<String, Object?>(),
                  ),
                  collectionBundle,
                ))!
                as Map<String, Object?>;
        batch.add(cleartext);
        final id = bso['id']! as String;
        if (cleartext['deleted'] == true) {
          records.remove(id);
        } else {
          records[id] = (cleartext: cleartext, modified: collectionModified);
        }
      }
      uploads.add(batch);
      return http.Response(
        jsonEncode({
          'success': [for (final bso in body) (bso as Map)['id']],
          'failed': <String, Object?>{},
          'modified': collectionModified,
        }),
        200,
      );
    }
    fail('unexpected request ${request.method} ${request.url}');
  }

  http.Client client() => MockClient(handle);
}

/// Full harness for the service: DB, fake tab repository, fake server, fake
/// settings, a temp snapshot directory.
class ServiceHarness {
  ServiceHarness._({
    required this.container,
    required this.db,
    required this.tabs,
    required this.server,
    required this.settings,
    required this.snapshotDir,
  });

  final ProviderContainer container;
  final TabDatabase db;
  final FakeSyncTabRepository tabs;
  final FakeSyncServer server;
  final FakeZenSettingsRepository settings;
  final Directory snapshotDir;

  /// [applierVersion] defaults to the current one so a test starts from a
  /// device whose rows the current applier produced; pass an older value to
  /// exercise the re-apply reset.
  static Future<ServiceHarness> open({
    FakeSyncServer? server,
    ZenSettings? initialSettings,
    int applierVersion = spacesApplierVersion,
    bool authenticated = true,
    List<Override> overrides = const [],
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final db = openTestTabDatabase();
    final tabs = FakeSyncTabRepository();
    final fakeServer = server ?? FakeSyncServer();
    final settings = FakeZenSettingsRepository(
      (initialSettings ?? ZenSettings.withDefaults()).copyWith(
        spacesSyncApplierVersion: applierVersion,
      ),
    );
    final snapshotDir = await Directory.systemTemp.createTemp('spaces_sync');
    final container = ProviderContainer(
      overrides: [
        tabDatabaseProvider.overrideWithValue(db),
        tabRepositoryProvider.overrideWith(() => tabs),
        spacesSyncHttpClientProvider.overrideWith((ref) => fakeServer.client()),
        spacesSyncCredentialsProvider.overrideWith(
          (ref) =>
              () async => testCredentials(),
        ),
        syncIsAuthenticatedProvider.overrideWith((ref) => authenticated),
        zenSettingsRepositoryProvider.overrideWith(() => settings),
        browserRestoreCompleteProvider.overrideWith(NeverRestored.new),
        spacesSyncSnapshotStoreProvider.overrideWith(
          (ref) => SnapshotStore(snapshotDir),
        ),
        ...overrides,
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
      await snapshotDir.delete(recursive: true);
    });
    return ServiceHarness._(
      container: container,
      db: db,
      tabs: tabs,
      server: fakeServer,
      settings: settings,
      snapshotDir: snapshotDir,
    );
  }
}

/// A projection whose output the test chooses.
class CannedProjection extends SpacesProjection {
  CannedProjection(super.db, super.containers, this.records);

  final Map<String, ZenCleartext> records;

  @override
  Future<Map<String, ZenCleartext>> project() async => records;
}
