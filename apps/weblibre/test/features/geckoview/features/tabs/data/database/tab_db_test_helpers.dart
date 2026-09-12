import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:weblibre/data/database/functions/lexo_rank_functions.dart';
import 'package:weblibre/data/database/functions/url_functions.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';

/// An in-memory `tab.db` with the SQL functions the schema needs
/// (LexoRank UDFs, url helpers and `generate_content_hash`).
TabDatabase openTestTabDatabase() {
  return TabDatabase(
    NativeDatabase.memory(
      setup: (database) {
        registerLexorankFunctions(database);
        registerUrlFunctions(database);
      },
    ),
  );
}

Future<void> seedSpaces(TabDatabase db, List<String> uuids) async {
  for (final (index, uuid) in uuids.indexed) {
    await db.spaceDao.insertSpace(
      SpaceData(uuid: uuid, name: uuid, orderIndex: index),
    );
  }
}

Future<void> seedContainer(TabDatabase db, String id) {
  return db.containerDao.addContainer(
    ContainerData(id: id, name: id, orderKey: id),
  );
}

/// Inserts a live tab through the DAO so its key is generated for its scope
/// exactly as production code would.
Future<void> seedTab(
  TabDatabase db,
  String id, {
  String? parentId,
  String? spaceUuid,
  String? folderId,
  String? containerId,
  String? orderKey,
  TabShelf shelf = TabShelf.normal,
  TabMode? tabMode,
}) {
  return db.tabDao.insertTab(
    id,
    source: TabSource.manual,
    parentId: Value(parentId),
    spaceUuid: Value(spaceUuid),
    folderId: Value(folderId),
    containerId: Value(containerId),
    shelf: shelf,
    orderKey: Value(orderKey),
    tabMode: tabMode == null ? const Value.absent() : Value(tabMode),
    url: Value(Uri.parse('https://$id.example/')),
    title: Value(id),
  );
}

Future<TabSummary> summaryOf(TabDatabase db, String id) async {
  final tab = await db.tabDao.getTabSummaryById(id).getSingleOrNull();
  if (tab == null) {
    throw StateError('tab $id does not exist');
  }
  return tab;
}

/// Every tab in [scope], in `order_key` order, regardless of parent.
Future<List<String>> idsInScope(TabDatabase db, TabOrderScope scope) async {
  final rows =
      await (db.tab.select()
            ..where(
              (t) =>
                  t.spaceUuid.equalsNullable(scope.spaceUuid) &
                  t.folderId.equalsNullable(scope.folderId) &
                  t.tabShelf.equalsValue(scope.shelf) &
                  (scope.isEssential
                      ? t.containerId.equalsNullable(scope.containerId)
                      : t.id.isNotNull()),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.orderKey)]))
          .get();
  return [for (final row in rows) row.id];
}
