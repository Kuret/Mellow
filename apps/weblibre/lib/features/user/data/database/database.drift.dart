// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:weblibre/features/user/data/database/definitions.drift.dart'
    as i1;
import 'package:weblibre/features/user/data/database/daos/setting.dart' as i2;
import 'package:weblibre/features/user/data/database/database.dart' as i3;
import 'package:weblibre/features/user/data/database/daos/cache.dart' as i4;
import 'package:weblibre/features/user/data/database/daos/toolbar_button_config.dart'
    as i5;
import 'package:weblibre/features/user/data/database/daos/quick_switcher_button_config.dart'
    as i6;
import 'package:weblibre/features/user/data/database/daos/search_tokens.dart'
    as i7;
import 'package:weblibre/features/user/data/database/daos/search_history.dart'
    as i8;
import 'package:drift/internal/modular.dart' as i9;
import 'package:sqlite3/common.dart' as i10;

abstract class $UserDatabase extends i0.GeneratedDatabase {
  $UserDatabase(i0.QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final i1.Setting setting = i1.Setting(this);
  late final i1.IconCache iconCache = i1.IconCache(this);
  late final i1.Riverpod riverpod = i1.Riverpod(this);
  late final i1.ToolbarButtonConfigs toolbarButtonConfigs =
      i1.ToolbarButtonConfigs(this);
  late final i1.QuickSwitcherButtonConfigs quickSwitcherButtonConfigs =
      i1.QuickSwitcherButtonConfigs(this);
  late final i1.SearchTokens searchTokens = i1.SearchTokens(this);
  late final i1.SearchHistory searchHistory = i1.SearchHistory(this);
  late final i2.SettingDao settingDao = i2.SettingDao(this as i3.UserDatabase);
  late final i4.CacheDao cacheDao = i4.CacheDao(this as i3.UserDatabase);
  late final i5.ToolbarButtonConfigDao toolbarButtonConfigDao =
      i5.ToolbarButtonConfigDao(this as i3.UserDatabase);
  late final i6.QuickSwitcherButtonConfigDao quickSwitcherButtonConfigDao =
      i6.QuickSwitcherButtonConfigDao(this as i3.UserDatabase);
  late final i7.SearchTokensDao searchTokensDao = i7.SearchTokensDao(
    this as i3.UserDatabase,
  );
  late final i8.SearchHistoryDao searchHistoryDao = i8.SearchHistoryDao(
    this as i3.UserDatabase,
  );
  i1.DefinitionsDrift get definitionsDrift => i9.ReadDatabaseContainer(
    this,
  ).accessor<i1.DefinitionsDrift>(i1.DefinitionsDrift.new);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    setting,
    iconCache,
    riverpod,
    toolbarButtonConfigs,
    i1.idxToolbarOrderKey,
    quickSwitcherButtonConfigs,
    i1.idxQuickSwitcherOrderKey,
    searchTokens,
    i1.idxSearchTokensInsertedAt,
    i1.idxSearchTokensReservedAt,
    searchHistory,
    i1.idxSearchHistoryDate,
  ];
  @override
  i0.StreamQueryUpdateRules get streamUpdateRules =>
      const i0.StreamQueryUpdateRules([
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'toolbar_button_configs',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [
            i0.TableUpdate(
              'toolbar_button_configs',
              kind: i0.UpdateKind.update,
            ),
          ],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'quick_switcher_button_configs',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [
            i0.TableUpdate(
              'quick_switcher_button_configs',
              kind: i0.UpdateKind.update,
            ),
          ],
        ),
      ]);
}

class $UserDatabaseManager {
  final $UserDatabase _db;
  $UserDatabaseManager(this._db);
  i1.$SettingTableManager get setting =>
      i1.$SettingTableManager(_db, _db.setting);
  i1.$IconCacheTableManager get iconCache =>
      i1.$IconCacheTableManager(_db, _db.iconCache);
  i1.$RiverpodTableManager get riverpod =>
      i1.$RiverpodTableManager(_db, _db.riverpod);
  i1.$ToolbarButtonConfigsTableManager get toolbarButtonConfigs =>
      i1.$ToolbarButtonConfigsTableManager(_db, _db.toolbarButtonConfigs);
  i1.$QuickSwitcherButtonConfigsTableManager get quickSwitcherButtonConfigs =>
      i1.$QuickSwitcherButtonConfigsTableManager(
        _db,
        _db.quickSwitcherButtonConfigs,
      );
  i1.$SearchTokensTableManager get searchTokens =>
      i1.$SearchTokensTableManager(_db, _db.searchTokens);
  i1.$SearchHistoryTableManager get searchHistory =>
      i1.$SearchHistoryTableManager(_db, _db.searchHistory);
}

extension DefineFunctions on i10.CommonDatabase {
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
      argumentCount: const i10.AllowedArgumentCount(2),
      function: (args) {
        final arg0 = args[0] as int;
        final arg1 = args[1] as String?;
        return lexoRankNext(arg0, arg1);
      },
    );
    createFunction(
      functionName: 'lexo_rank_previous',
      argumentCount: const i10.AllowedArgumentCount(2),
      function: (args) {
        final arg0 = args[0] as int;
        final arg1 = args[1] as String?;
        return lexoRankPrevious(arg0, arg1);
      },
    );
    createFunction(
      functionName: 'lexo_rank_reorder_after',
      argumentCount: const i10.AllowedArgumentCount(2),
      function: (args) {
        final arg0 = args[0] as String?;
        final arg1 = args[1] as String?;
        return lexoRankReorderAfter(arg0, arg1);
      },
    );
    createFunction(
      functionName: 'lexo_rank_reorder_before',
      argumentCount: const i10.AllowedArgumentCount(2),
      function: (args) {
        final arg0 = args[0] as String?;
        final arg1 = args[1] as String?;
        return lexoRankReorderBefore(arg0, arg1);
      },
    );
    createFunction(
      functionName: 'generate_content_hash',
      argumentCount: const i10.AllowedArgumentCount(0),
      function: (args) {
        return generateContentHash();
      },
    );
    createFunction(
      functionName: 'url_indexable',
      argumentCount: const i10.AllowedArgumentCount(1),
      function: (args) {
        final arg0 = args[0] as String?;
        return urlIndexable(arg0);
      },
    );
    createFunction(
      functionName: 'url_canonical',
      argumentCount: const i10.AllowedArgumentCount(1),
      function: (args) {
        final arg0 = args[0] as String?;
        return urlCanonical(arg0);
      },
    );
    createFunction(
      functionName: 'url_host',
      argumentCount: const i10.AllowedArgumentCount(1),
      function: (args) {
        final arg0 = args[0] as String?;
        return urlHost(arg0);
      },
    );
    createFunction(
      functionName: 'url_path',
      argumentCount: const i10.AllowedArgumentCount(1),
      function: (args) {
        final arg0 = args[0] as String?;
        return urlPath(arg0);
      },
    );
  }
}
