// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart'
    as i1;
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/container.dart'
    as i2;
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart'
    as i3;
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/tab.dart'
    as i4;
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/space.dart'
    as i5;
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/tab_folder.dart'
    as i6;
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/tab_split.dart'
    as i7;
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/sync_state.dart'
    as i8;
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/capture_tab.dart'
    as i9;
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/history.dart'
    as i10;
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/visit_container.dart'
    as i11;
import 'package:drift/internal/modular.dart' as i12;
import 'package:sqlite3/common.dart' as i13;

abstract class $TabDatabase extends i0.GeneratedDatabase {
  $TabDatabase(i0.QueryExecutor e) : super(e);
  $TabDatabaseManager get managers => $TabDatabaseManager(this);
  late final i1.Container container = i1.Container(this);
  late final i1.ContainerLocal containerLocal = i1.ContainerLocal(this);
  late final i1.Space space = i1.Space(this);
  late final i1.TabFolder tabFolder = i1.TabFolder(this);
  late final i1.TabSplit tabSplit = i1.TabSplit(this);
  late final i1.Tab tab = i1.Tab(this);
  late final i1.ClosedTabTombstone closedTabTombstone = i1.ClosedTabTombstone(
    this,
  );
  late final i1.CaptureTab captureTab = i1.CaptureTab(this);
  late final i1.TabFts tabFts = i1.TabFts(this);
  late final i1.LocalIndexSetting localIndexSetting = i1.LocalIndexSetting(
    this,
  );
  late final i1.History history = i1.History(this);
  late final i1.HistoryFts historyFts = i1.HistoryFts(this);
  late final i1.VisitContainer visitContainer = i1.VisitContainer(this);
  late final i1.ForeignRecord foreignRecord = i1.ForeignRecord(this);
  late final i1.SyncRecordState syncRecordState = i1.SyncRecordState(this);
  late final i1.DeletedRecord deletedRecord = i1.DeletedRecord(this);
  late final i1.AppliedTombstone appliedTombstone = i1.AppliedTombstone(this);
  late final i1.PendingEngineClose pendingEngineClose = i1.PendingEngineClose(
    this,
  );
  late final i2.ContainerDao containerDao = i2.ContainerDao(
    this as i3.TabDatabase,
  );
  late final i4.TabDao tabDao = i4.TabDao(this as i3.TabDatabase);
  late final i5.SpaceDao spaceDao = i5.SpaceDao(this as i3.TabDatabase);
  late final i6.TabFolderDao tabFolderDao = i6.TabFolderDao(
    this as i3.TabDatabase,
  );
  late final i7.TabSplitDao tabSplitDao = i7.TabSplitDao(
    this as i3.TabDatabase,
  );
  late final i8.SyncStateDao syncStateDao = i8.SyncStateDao(
    this as i3.TabDatabase,
  );
  late final i9.CaptureTabDao captureTabDao = i9.CaptureTabDao(
    this as i3.TabDatabase,
  );
  late final i10.HistoryDao historyDao = i10.HistoryDao(this as i3.TabDatabase);
  late final i11.VisitContainerDao visitContainerDao = i11.VisitContainerDao(
    this as i3.TabDatabase,
  );
  i1.DefinitionsDrift get definitionsDrift => i12.ReadDatabaseContainer(
    this,
  ).accessor<i1.DefinitionsDrift>(i1.DefinitionsDrift.new);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    container,
    containerLocal,
    space,
    tabFolder,
    tabSplit,
    tab,
    closedTabTombstone,
    i1.idxTabScopeOrder,
    i1.idxTabParentSpace,
    i1.idxTabContainer,
    i1.idxTabTimestamp,
    i1.idxTabFolderParent,
    i1.idxTabSplitScope,
    captureTab,
    i1.idxCaptureTabCaptureId,
    tabFts,
    i1.tabMaintainParentChainOnDelete,
    i1.tabChildFollowsParentScope,
    i1.tabAfterInsert,
    i1.tabAfterDelete,
    i1.tabAfterUpdate,
    localIndexSetting,
    history,
    i1.idxHistoryHost,
    i1.idxHistoryObserved,
    historyFts,
    i1.historyAfterInsert,
    i1.historyAfterDelete,
    i1.historyAfterUpdate,
    i1.tabToHistoryOnInsert,
    i1.tabToHistoryOnUpdate,
    i1.tabToHistoryOnContainerUpdate,
    i1.containerLocalToHistoryOnInsert,
    i1.containerLocalToHistoryOnUpdate,
    visitContainer,
    i1.idxVcCanonical,
    i1.idxVcContainer,
    foreignRecord,
    syncRecordState,
    deletedRecord,
    appliedTombstone,
    pendingEngineClose,
  ];
  @override
  i0.StreamQueryUpdateRules get streamUpdateRules =>
      const i0.StreamQueryUpdateRules([
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'container',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [
            i0.TableUpdate('container_local', kind: i0.UpdateKind.delete),
          ],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'container',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('space', kind: i0.UpdateKind.update)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'space',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab_folder', kind: i0.UpdateKind.delete)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab_folder',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab_folder', kind: i0.UpdateKind.delete)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'space',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab_split', kind: i0.UpdateKind.delete)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab_folder',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab_split', kind: i0.UpdateKind.update)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab', kind: i0.UpdateKind.update)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'container',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab', kind: i0.UpdateKind.update)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'space',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab', kind: i0.UpdateKind.update)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab_folder',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab', kind: i0.UpdateKind.update)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab_split',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab', kind: i0.UpdateKind.update)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('capture_tab', kind: i0.UpdateKind.delete)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab', kind: i0.UpdateKind.update)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [i0.TableUpdate('tab', kind: i0.UpdateKind.update)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.insert,
          ),
          result: [i0.TableUpdate('tab_fts', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('tab_fts', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [i0.TableUpdate('tab_fts', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'history',
            limitUpdateKind: i0.UpdateKind.insert,
          ),
          result: [i0.TableUpdate('history_fts', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'history',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('history_fts', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'history',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [i0.TableUpdate('history_fts', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.insert,
          ),
          result: [i0.TableUpdate('history', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [i0.TableUpdate('history', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tab',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [
            i0.TableUpdate('history', kind: i0.UpdateKind.delete),
            i0.TableUpdate('history', kind: i0.UpdateKind.insert),
          ],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'container_local',
            limitUpdateKind: i0.UpdateKind.insert,
          ),
          result: [
            i0.TableUpdate('history', kind: i0.UpdateKind.delete),
            i0.TableUpdate('history', kind: i0.UpdateKind.insert),
          ],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'container_local',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [
            i0.TableUpdate('history', kind: i0.UpdateKind.delete),
            i0.TableUpdate('history', kind: i0.UpdateKind.insert),
          ],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'container',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [
            i0.TableUpdate('visit_container', kind: i0.UpdateKind.delete),
          ],
        ),
      ]);
}

class $TabDatabaseManager {
  final $TabDatabase _db;
  $TabDatabaseManager(this._db);
  i1.$ContainerTableManager get container =>
      i1.$ContainerTableManager(_db, _db.container);
  i1.$ContainerLocalTableManager get containerLocal =>
      i1.$ContainerLocalTableManager(_db, _db.containerLocal);
  i1.$SpaceTableManager get space => i1.$SpaceTableManager(_db, _db.space);
  i1.$TabFolderTableManager get tabFolder =>
      i1.$TabFolderTableManager(_db, _db.tabFolder);
  i1.$TabSplitTableManager get tabSplit =>
      i1.$TabSplitTableManager(_db, _db.tabSplit);
  i1.$TabTableManager get tab => i1.$TabTableManager(_db, _db.tab);
  i1.$ClosedTabTombstoneTableManager get closedTabTombstone =>
      i1.$ClosedTabTombstoneTableManager(_db, _db.closedTabTombstone);
  i1.$CaptureTabTableManager get captureTab =>
      i1.$CaptureTabTableManager(_db, _db.captureTab);
  i1.$TabFtsTableManager get tabFts => i1.$TabFtsTableManager(_db, _db.tabFts);
  i1.$LocalIndexSettingTableManager get localIndexSetting =>
      i1.$LocalIndexSettingTableManager(_db, _db.localIndexSetting);
  i1.$HistoryTableManager get history =>
      i1.$HistoryTableManager(_db, _db.history);
  i1.$HistoryFtsTableManager get historyFts =>
      i1.$HistoryFtsTableManager(_db, _db.historyFts);
  i1.$VisitContainerTableManager get visitContainer =>
      i1.$VisitContainerTableManager(_db, _db.visitContainer);
  i1.$ForeignRecordTableManager get foreignRecord =>
      i1.$ForeignRecordTableManager(_db, _db.foreignRecord);
  i1.$SyncRecordStateTableManager get syncRecordState =>
      i1.$SyncRecordStateTableManager(_db, _db.syncRecordState);
  i1.$DeletedRecordTableManager get deletedRecord =>
      i1.$DeletedRecordTableManager(_db, _db.deletedRecord);
  i1.$AppliedTombstoneTableManager get appliedTombstone =>
      i1.$AppliedTombstoneTableManager(_db, _db.appliedTombstone);
  i1.$PendingEngineCloseTableManager get pendingEngineClose =>
      i1.$PendingEngineCloseTableManager(_db, _db.pendingEngineClose);
}

extension DefineFunctions on i13.CommonDatabase {
  void defineFunctions({
    required String Function(int, String?) lexoRankNext,
    required String Function(int, String?) lexoRankPrevious,
    required String Function(String?, String?) lexoRankReorderAfter,
    required String Function(String?, String?) lexoRankReorderBefore,
    required int Function() generateContentHash,
    required bool Function(String?) urlIndexable,
    required String Function(String?) urlCanonical,
    required String Function(String?) urlHost,
    required String Function(String?) urlPath,
  }) {
    createFunction(
      functionName: 'lexo_rank_next',
      argumentCount: const i13.AllowedArgumentCount(2),
      function: (args) {
        final arg0 = args[0] as int;
        final arg1 = args[1] as String?;
        return lexoRankNext(arg0, arg1);
      },
    );
    createFunction(
      functionName: 'lexo_rank_previous',
      argumentCount: const i13.AllowedArgumentCount(2),
      function: (args) {
        final arg0 = args[0] as int;
        final arg1 = args[1] as String?;
        return lexoRankPrevious(arg0, arg1);
      },
    );
    createFunction(
      functionName: 'lexo_rank_reorder_after',
      argumentCount: const i13.AllowedArgumentCount(2),
      function: (args) {
        final arg0 = args[0] as String?;
        final arg1 = args[1] as String?;
        return lexoRankReorderAfter(arg0, arg1);
      },
    );
    createFunction(
      functionName: 'lexo_rank_reorder_before',
      argumentCount: const i13.AllowedArgumentCount(2),
      function: (args) {
        final arg0 = args[0] as String?;
        final arg1 = args[1] as String?;
        return lexoRankReorderBefore(arg0, arg1);
      },
    );
    createFunction(
      functionName: 'generate_content_hash',
      argumentCount: const i13.AllowedArgumentCount(0),
      function: (args) {
        return generateContentHash();
      },
    );
    createFunction(
      functionName: 'url_indexable',
      argumentCount: const i13.AllowedArgumentCount(1),
      function: (args) {
        final arg0 = args[0] as String?;
        return urlIndexable(arg0);
      },
    );
    createFunction(
      functionName: 'url_canonical',
      argumentCount: const i13.AllowedArgumentCount(1),
      function: (args) {
        final arg0 = args[0] as String?;
        return urlCanonical(arg0);
      },
    );
    createFunction(
      functionName: 'url_host',
      argumentCount: const i13.AllowedArgumentCount(1),
      function: (args) {
        final arg0 = args[0] as String?;
        return urlHost(arg0);
      },
    );
    createFunction(
      functionName: 'url_path',
      argumentCount: const i13.AllowedArgumentCount(1),
      function: (args) {
        final arg0 = args[0] as String?;
        return urlPath(arg0);
      },
    );
  }
}
