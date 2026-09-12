import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';

import '../data/database/tab_db_test_helpers.dart';

/// A [TabRepository] whose engine is the database itself: closing tabs deletes
/// their rows (as the engine's tab-list event would) and records every call,
/// together with whether the given space / folder rows still existed at that
/// moment — the ordering PLAN §7.3 requires.
class FakeTabRepository extends TabRepository {
  final closedBatches = <List<String>>[];
  final spaceExistedAtClose = <String, bool>{};
  final folderExistedAtClose = <String, bool>{};
  final watchedSpaces = <String>{};
  final watchedFolders = <String>{};

  @override
  void build() {}

  @override
  Future<void> closeTabs(List<String> tabIds) async {
    final db = ref.read(tabDatabaseProvider);
    for (final uuid in watchedSpaces) {
      spaceExistedAtClose[uuid] =
          await db.spaceDao.getByUuid(uuid).getSingleOrNull() != null;
    }
    for (final id in watchedFolders) {
      folderExistedAtClose[id] =
          await db.tabFolderDao.getById(id).getSingleOrNull() != null;
    }
    closedBatches.add(List.of(tabIds));
    await (db.tab.delete()..where((t) => t.id.isIn(tabIds))).go();
  }

  @override
  Future<void> closeTab(String tabId) => closeTabs([tabId]);

  List<String> get closedTabIds => [
    for (final batch in closedBatches) ...batch,
  ];
}

/// A container with an in-memory [TabDatabase] and a [FakeTabRepository].
({ProviderContainer container, TabDatabase db, FakeTabRepository tabs})
openRepositoryHarness() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = openTestTabDatabase();
  final tabs = FakeTabRepository();
  final container = ProviderContainer(
    overrides: [
      tabDatabaseProvider.overrideWithValue(db),
      tabRepositoryProvider.overrideWith(() => tabs),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return (container: container, db: db, tabs: tabs);
}

Future<List<String>> tabIds(TabDatabase db) async {
  final rows = await (db.selectOnly(db.tab)..addColumns([db.tab.id])).get();
  return [for (final row in rows) row.read(db.tab.id)!];
}
