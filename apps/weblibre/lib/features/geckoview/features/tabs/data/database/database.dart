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
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/internal/versioned_schema.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter/foundation.dart';
import 'package:lexo_rank/lexo_rank.dart';
import 'package:weblibre/data/database/functions/lexo_rank_functions.dart';
import 'package:weblibre/data/database/functions/url_functions.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/capture_tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/container.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/history.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/space.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/sync_state.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/tab_folder.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/tab_split.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/visit_container.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.steps.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/migrations/v16_history_eviction_sql.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/container_icon_migration_map.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/firefox_container_vocab.dart';
import 'package:weblibre/features/search/domain/fts_tokenizer.dart';
import 'package:weblibre/features/spaces_sync/domain/zen_ids.dart';

@DriftDatabase(
  include: {'definitions.drift'},
  daos: [
    ContainerDao,
    TabDao,
    SpaceDao,
    TabFolderDao,
    TabSplitDao,
    SyncStateDao,
    CaptureTabDao,
    HistoryDao,
    VisitContainerDao,
  ],
)
class TabDatabase extends $TabDatabase with TrigramQueryBuilderMixin {
  @override
  final int schemaVersion = 20;

  @override
  final int ftsTokenLimit = 10;
  @override
  final int ftsMinTokenLength = 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      if (kDebugMode) {
        // This check pulls in a fair amount of code that's not needed
        // anywhere else, so we recommend only doing it in debug builds.
        await validateDatabaseSchema(
          setup: (database) {
            registerLexorankFunctions(database);
            registerUrlFunctions(database);
          },
        );
      }

      await customStatement('PRAGMA foreign_keys = ON');
      await definitionsDrift.optimizeFtsIndex();
      if (details.versionNow >= 12) {
        await definitionsDrift.optimizeHistoryFtsIndex();
      }
    },
    onUpgrade: (m, from, to) async {
      // Following the advice from https://drift.simonbinder.eu/Migrations/api/#general-tips
      await customStatement('PRAGMA foreign_keys = OFF');

      await transaction(
        () => VersionedSchema.runMigrationSteps(
          migrator: m,
          from: from,
          to: to,
          steps: _upgrade,
        ),
      );

      if (kDebugMode) {
        final wrongForeignKeys = await customSelect(
          'PRAGMA foreign_key_check',
        ).get();
        assert(
          wrongForeignKeys.isEmpty,
          '${wrongForeignKeys.map((e) => e.data)}',
        );
      }

      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  TabDatabase(super.e);

  static final _upgrade = migrationSteps(
    from2To3: (m, schema) async {
      final tabAtV3 = schema.tab;
      await m.addColumn(tabAtV3, tabAtV3.isPrivate);
    },
    from3To4: (m, schema) async {
      await m.alterTable(
        TableMigration(
          schema.tab,
          columnTransformer: {
            schema.tab.source: Constant(TabSource.manual.index),
          },
          newColumns: [schema.tab.source],
        ),
      );
    },
    from4To5: (m, schema) async {
      await m.drop(schema.tabMaintainParentChainOnDelete);
      await m.create(schema.tabMaintainParentChainOnDelete);
    },
    from5To6: (m, schema) async {
      await m.alterTable(
        TableMigration(
          schema.tab,
          columnTransformer: {
            // Backfill tab_mode from is_private: private=true -> 1 (private), else -> 0 (regular)
            schema.tab.tabMode: const CustomExpression(
              'CASE WHEN is_private = 1 THEN 1 ELSE 0 END',
            ),
          },
          newColumns: [schema.tab.tabMode, schema.tab.isolationContextId],
        ),
      );

      await m.alterTable(TableMigration(schema.tab));
    },
    from6To7: (m, schema) async {
      await m.addColumn(schema.tab, schema.tab.isPinned);
    },
    from7To8: (m, schema) async {
      // Composite index supporting `tabsWithRootAndDepth` (parent existence
      // checks scoped per container) and `lastChildTabId` (last child of a
      // parent within a container). On large containers SQLite was falling
      // back to per-row scans on the recursive seed.
      //
      // Also drop any rows whose `parent_id` references a tab that no
      // longer exists (e.g. left over from a close that ran without the
      // delete trigger). `tab_maintain_parent_chain_on_delete` keeps this
      // clean going forward; the one-shot UPDATE here removes legacy
      // dangling pointers so the new index is built on consistent data.
      await m.database.customStatement(
        'UPDATE tab SET parent_id = NULL '
        'WHERE parent_id IS NOT NULL '
        'AND NOT EXISTS (SELECT 1 FROM tab p WHERE p.id = tab.parent_id)',
      );

      await m.createIndex(schema.idxTabParentContainer);
    },
    from8To9: (m, schema) async {
      await m.create(schema.closedTabTombstone);
    },
    from9To10: (m, schema) async {
      await m.create(schema.captureTab);
      await m.create(schema.idxCaptureTabCaptureId);
    },
    from10To11: (m, schema) async {
      // Re-scope `tab_after_update` to fire only when FTS-relevant columns
      // change. Previously every tab UPDATE (order_key reshuffle, container
      // reassignment, pin toggle, timestamp touch, ...) rewrote the trigram
      // shadow rows for free.
      await m.drop(schema.tabAfterUpdate);
      await m.create(schema.tabAfterUpdate);
    },
    from11To12: (m, schema) async {
      // Local search index — content companion to Mozilla Places (which
      // remains SoT for visit metadata). See definitions.drift for layout.
      //
      // Order matters: the generated `tab.content_hash` column references
      // the `content_hash()` SQL function, which is registered in the
      // tab.db `setup` callback. The migration runs after `setup`, so the
      // function is available here.
      //
      // `tab.content_hash` requires recreating the tab table because
      // SQLite's ALTER TABLE only supports adding VIRTUAL generated
      // columns when the column is not part of any existing index/trigger
      // dependency chain — drift's TableMigration handles the rebuild.
      await m.alterTable(TableMigration(schema.tab));

      // Settings table seeded with defaults: index enabled, private tabs
      // not indexed.
      await m.create(schema.localIndexSetting);
      await m.database.customStatement(
        "INSERT INTO local_index_setting (key, value) VALUES ('enabled', 1)",
      );
      await m.database.customStatement(
        "INSERT INTO local_index_setting (key, value) VALUES ('index_private', 0)",
      );

      // History content table + FTS5 + maintenance triggers.
      await m.create(schema.history);
      await m.create(schema.idxHistoryHost);
      await m.create(schema.idxHistoryObserved);
      await m.create(schema.historyFts);
      await m.create(schema.historyAfterInsert);
      await m.create(schema.historyAfterDelete);
      await m.create(schema.historyAfterUpdate);

      // tab_after_update gains a content_hash WHEN guard. Recreate.
      await m.drop(schema.tabAfterUpdate);
      await m.create(schema.tabAfterUpdate);

      // Tab → history fan-out triggers.
      await m.create(schema.tabToHistoryOnInsert);
      await m.create(schema.tabToHistoryOnUpdate);
    },
    from12To13: (m, schema) async {
      await m.alterTable(
        TableMigration(
          schema.container,
          newColumns: [schema.container.orderKey, schema.container.isPinned],
          columnTransformer: {
            schema.container.orderKey: Constant(LexoRank.middle().value),
            schema.container.isPinned: const Constant(false),
          },
        ),
      );

      final database = m.database as TabDatabase;
      final containerIds = await database.definitionsDrift
          .containerIdsByLastUpdated()
          .get();

      var rank = LexoRank.middle();
      for (final containerId in containerIds) {
        await (database.update(database.container)
              ..where((container) => container.id.equals(containerId)))
            .write(ContainerCompanion(orderKey: Value(rank.value)));
        rank = rank.genNext();
      }
    },
    from13To14: (m, schema) async {
      // Add per-container exclude-from-index gate to the tab→history
      // triggers, plus re-evaluation triggers for container assignment and
      // exclude-flag changes.
      await m.drop(schema.tabToHistoryOnInsert);
      await m.create(schema.tabToHistoryOnInsert);
      await m.drop(schema.tabToHistoryOnUpdate);
      await m.create(schema.tabToHistoryOnUpdate);
      await m.create(schema.tabToHistoryOnContainerUpdate);
      await m.create(schema.containerToHistoryOnMetadataUpdate);
    },
    from14To15: (m, schema) async {
      // Visit → container relation. Mozilla Places stays the source of truth
      // for history; this table only records which container each contained
      // visit belonged to. See definitions.drift.
      await m.create(schema.visitContainer);
      await m.create(schema.idxVcCanonical);
      await m.create(schema.idxVcContainer);
    },
    from15To16: (m, schema) async {
      // Exclude-from-history now also keeps a container out of the local
      // search index: recording nothing in Places is pointless while the same
      // pages stay searchable locally (and reachable from any other tab that
      // opens the same URL). Every fan-out trigger gained the second flag.
      await m.drop(schema.tabToHistoryOnInsert);
      await m.create(schema.tabToHistoryOnInsert);
      await m.drop(schema.tabToHistoryOnUpdate);
      await m.create(schema.tabToHistoryOnUpdate);
      await m.drop(schema.tabToHistoryOnContainerUpdate);
      await m.create(schema.tabToHistoryOnContainerUpdate);
      await m.drop(schema.containerToHistoryOnMetadataUpdate);
      await m.create(schema.containerToHistoryOnMetadataUpdate);

      // Re-evaluate what the old predicate already let in, exactly as
      // container_to_history_on_metadata_update does — DELETE, then re-INSERT
      // the best remaining candidate — applied to every excluded container at
      // once. Both halves are needed: the DELETE spares a URL that some other
      // eligible tab still holds, and that spared row would otherwise keep the
      // *excluded* tab's title and content (in `history` and in `history_fts`)
      // until something touched that tab again.
      //
      // Frozen to the v16 table shapes: the live named queries now read
      // `container_local`, which does not exist yet at this version.
      await m.database.customStatement(v16EvictExcludedHistoryPagesSql);
      await m.database.customStatement(
        v16ReindexAfterExcludedHistoryEvictionSql,
      );
    },
    from16To17: (m, schema) async {
      // Two indexes only. `getTabsFifo` ordered by `timestamp DESC LIMIT n`
      // with nothing to walk, so SQLite scanned every row of `tab` and pushed
      // it through a sorter — and that query is a live stream re-run on every
      // write to the table. `getContainerTabsData` had the same problem for
      // `container_id` + `order_key`, which `idx_tab_parent_container` cannot
      // serve because `container_id` is not its leftmost column.
      await m.create(schema.idxTabTimestamp);
      await m.create(schema.idxTabContainerOrder);
    },
    from17To18: (m, schema) async {
      final database = m.database as TabDatabase;

      // Zen model tables: spaces, folders, splits, the sync bookkeeping
      // tables, and container_local (containers' local-only settings, split
      // out of `container` so the sync projection of that table stays a
      // pure mirror of Zen's record). Safe to create ahead of the
      // container/tab rebuilds below: their foreign keys aren't enforced
      // mid-migration (`PRAGMA foreign_keys = OFF`, see `onUpgrade` above).
      await m.create(schema.space);
      await m.create(schema.tabFolder);
      await m.create(schema.tabSplit);
      await m.create(schema.containerLocal);
      await m.create(schema.foreignRecord);
      await m.create(schema.syncRecordState);

      // --- Containers -------------------------------------------------
      //
      // Frozen to the v17 shape (`id, name, color, order_key, is_pinned,
      // metadata`) — this step must keep reading it exactly like this even
      // if `container` changes again later. `metadata` is the old
      // `ContainerMetadata` JSON blob; see `_LegacyContainer.fromRow` for
      // the keys read out of it.
      final oldContainers = await database
          .customSelect(
            'SELECT id, name, color, order_key, is_pinned, metadata '
            'FROM container',
          )
          .get();
      final legacyContainers = [
        for (final row in oldContainers) _LegacyContainer.fromRow(row),
      ];

      await m.drop(schema.container);
      await m.create(schema.container);

      for (final container in legacyContainers) {
        final isPinned = container.isPinned ? 1 : 0;
        await database.customStatement(
          'INSERT INTO container '
          '(id, sync_guid, name, icon_key, color_key, order_key, is_pinned) '
          'VALUES (?, NULL, ?, ?, ?, ?, ?)',
          [
            container.id,
            container.name,
            container.iconKey,
            container.colorKey,
            container.orderKey,
            isPinned,
          ],
        );
        final excludeFromIndex = container.excludeFromIndex ? 1 : 0;
        final excludeFromHistory = container.excludeFromHistory ? 1 : 0;
        final clearDataOnExit = container.clearDataOnExit ? 1 : 0;
        await database.customStatement(
          'INSERT INTO container_local '
          '(container_id, exclude_from_index, exclude_from_history, '
          'clear_data_on_exit, wallpaper) '
          'VALUES (?, ?, ?, ?, ?)',
          [
            container.id,
            excludeFromIndex,
            excludeFromHistory,
            clearDataOnExit,
            container.wallpaperJson,
          ],
        );
      }

      // --- Default space ------------------------------------------------
      //
      // Every pre-existing tab lands in one space (PLAN §7.2 / DESIGN.md
      // "Backfill"); folders and splits are new in v18, so nothing pre-v18
      // ever populates them.
      final defaultSpaceUuid = ZenIds.newSpaceUuid();
      await database.customStatement(
        'INSERT INTO space (uuid, name, icon, theme, container_id, '
        "order_index) VALUES (?, '', NULL, NULL, NULL, 0)",
        [defaultSpaceUuid],
      );

      // --- Tabs -----------------------------------------------------
      //
      // Frozen to the v17 shape. `tab.content_hash` is a VIRTUAL generated
      // column, so it's never read or written directly.
      final oldTabs = await database
          .customSelect(
            'SELECT id, source, parent_id, container_id, order_key, url, '
            'title, tab_mode, is_pinned, is_probably_readerable, '
            'extracted_content_markdown, extracted_content_plain, '
            'full_content_markdown, full_content_plain, timestamp '
            'FROM tab',
          )
          .get();

      await m.drop(schema.tab);
      await m.create(schema.tab);

      for (final row in oldTabs) {
        final id = row.read<String>('id');
        final tabMode = row.read<int>('tab_mode');
        final isPinned = row.read<bool>('is_pinned');

        // Private tabs (old tab_mode 1) never sync and get no space;
        // everything else (regular=0, isolated=2) lands in the default
        // space.
        final String? spaceUuid = tabMode == 1 ? null : defaultSpaceUuid;
        final tabShelf = isPinned ? 1 : 0;
        // Cookie isolation is now intrinsic to the container id (D3
        // refinement); the old isolated mode (2) folds into regular (0) and
        // `isolation_context_id` is dropped entirely.
        final newTabMode = tabMode == 2 ? 0 : tabMode;

        await database.customStatement(
          'INSERT INTO tab '
          '(id, engine_tab_id, source, parent_id, container_id, space_uuid, '
          'folder_id, split_id, split_index, tab_shelf, order_key, url, '
          'title, icon_url, static_label, has_static_icon, '
          'default_container, tab_mode, is_probably_readerable, '
          'extracted_content_markdown, extracted_content_plain, '
          'full_content_markdown, full_content_plain, timestamp) '
          'VALUES (?, ?, ?, ?, ?, ?, NULL, NULL, NULL, ?, ?, ?, ?, NULL, '
          'NULL, 0, 0, ?, ?, ?, ?, ?, ?, ?)',
          [
            id,
            // engine_tab_id = id: every pre-v18 tab already has an engine
            // session (cold tabs are new in v18).
            id,
            row.read<int>('source'),
            row.read<String?>('parent_id'),
            row.read<String?>('container_id'),
            spaceUuid,
            tabShelf,
            row.read<String>('order_key'),
            row.data['url'],
            row.read<String?>('title'),
            newTabMode,
            row.data['is_probably_readerable'],
            row.read<String?>('extracted_content_markdown'),
            row.read<String?>('extracted_content_plain'),
            row.read<String?>('full_content_markdown'),
            row.read<String?>('full_content_plain'),
            row.data['timestamp'],
          ],
        );
      }

      // New/changed indexes and triggers on `tab`. Dropping the table above
      // already dropped the v17 ones that lived on it (SQLite drops a
      // table's indexes and triggers along with it); `tab_fts` is an
      // external-content FTS5 table and survives independently, so it needs
      // an explicit rebuild once the new rows (and their new rowids) exist.
      await m.create(schema.idxTabScopeOrder);
      await m.create(schema.idxTabParentSpace);
      await m.create(schema.idxTabContainer);
      await m.create(schema.idxTabTimestamp);
      await m.create(schema.idxTabFolderParent);
      await m.create(schema.idxTabSplitScope);

      await m.create(schema.tabMaintainParentChainOnDelete);
      await m.create(schema.tabChildFollowsParentScope);
      await m.create(schema.tabAfterInsert);
      await m.create(schema.tabAfterDelete);
      await m.create(schema.tabAfterUpdate);
      await m.create(schema.tabToHistoryOnInsert);
      await m.create(schema.tabToHistoryOnUpdate);
      await m.create(schema.tabToHistoryOnContainerUpdate);

      await database.customStatement(
        "INSERT INTO tab_fts(tab_fts) VALUES('rebuild')",
      );

      // container_local's history-eviction triggers, created only now that
      // every row above is already in place: creating them earlier would
      // have re-run the same eviction once per excluded container as each
      // row was inserted, instead of once below.
      await m.create(schema.containerLocalToHistoryOnInsert);
      await m.create(schema.containerLocalToHistoryOnUpdate);

      // Visible order survives the rebuild: re-key `order_key` per new
      // scope (space, folder, shelf), ordered by the containers' own
      // (new) order_key, then the tab's old order_key, matching how
      // `TabDao`'s own between-generation helpers keep siblings ordered.
      await _rekeyTabOrderAfterV18Migration(database);

      // Exclude-from-history/-index is now per container_local row instead
      // of per container.metadata; re-evaluate the whole index once against
      // it, exactly like the v16 step did for the old predicate. The SQL
      // lives in definitions.drift, pinned to the v18 shape (see the note
      // there).
      await database.definitionsDrift.evictExcludedHistoryPages();
      await database.definitionsDrift.reindexAfterExcludedHistoryEviction();
    },
    from18To19: (m, schema) async {
      // The local "deleted for a reason" ledger the sync client reads before
      // it projects a tombstone (PLAN §8.6 item 5).
      await m.create(schema.deletedRecord);
    },
    from19To20: (m, schema) async {
      // The applied-deletion ledger the upload canary reads, and the queue of
      // engine sessions an applied batch left behind (PLAN §8.6, Zen
      // gh-15380).
      await m.create(schema.appliedTombstone);
      await m.create(schema.pendingEngineClose);
    },
  );
}

/// A `container` row as it existed at v17, plus everything the `from17To18`
/// migration step needs decoded out of its old `metadata` JSON blob.
///
/// `metadata` held the old `ContainerMetadata` (`iconData`, `wallpaper`,
/// `excludeFromIndex`, `excludeFromHistory`, `clearDataOnExit`, plus removed
/// proxy/site/`contextualIdentity` keys this migration has no use for — see
/// DESIGN.md "D3 refinement: containers"). Absent or unparsable metadata is
/// treated as an all-defaults row rather than failing the migration.
class _LegacyContainer {
  _LegacyContainer({
    required this.id,
    required this.name,
    required this.colorKey,
    required this.iconKey,
    required this.orderKey,
    required this.isPinned,
    required this.excludeFromIndex,
    required this.excludeFromHistory,
    required this.clearDataOnExit,
    required this.wallpaperJson,
  });

  factory _LegacyContainer.fromRow(QueryRow row) {
    final name = row.read<String?>('name');
    final colorArgb = row.read<int>('color');
    final metadataText = row.read<String?>('metadata');

    Map<String, dynamic>? metadata;
    if (metadataText != null) {
      try {
        final decoded = jsonDecode(metadataText);
        if (decoded is Map<String, dynamic>) {
          metadata = decoded;
        }
      } on FormatException {
        metadata = null;
      }
    }

    final iconData = metadata?['iconData'];
    final legacyCodePoint = iconData is Map ? iconData['codePoint'] : null;
    final wallpaper = metadata?['wallpaper'];

    return _LegacyContainer(
      id: row.read<String>('id'),
      name: name ?? '',
      colorKey: FirefoxContainerColor.nearestTo(colorArgb).keyword,
      iconKey:
          containerIconKeyForLegacyCodePoint(
            legacyCodePoint is int ? legacyCodePoint : null,
          ) ??
          'circle',
      orderKey: row.read<String>('order_key'),
      isPinned: row.read<bool>('is_pinned'),
      excludeFromIndex: metadata?['excludeFromIndex'] == true,
      excludeFromHistory: metadata?['excludeFromHistory'] == true,
      clearDataOnExit: metadata?['clearDataOnExit'] == true,
      wallpaperJson: wallpaper == null ? null : jsonEncode(wallpaper),
    );
  }

  final String id;
  final String name;
  final String colorKey;
  final String iconKey;
  final String orderKey;
  final bool isPinned;
  final bool excludeFromIndex;
  final bool excludeFromHistory;
  final bool clearDataOnExit;
  final String? wallpaperJson;
}

/// A `tab` row, as re-inserted into the v18 shape by `from17To18`, carrying
/// just what [_rekeyTabOrderAfterV18Migration] needs to re-key `order_key`.
class _MigratedTabRow {
  _MigratedTabRow({
    required this.id,
    required this.parentId,
    required this.containerId,
    required this.orderKey,
  });

  final String id;
  final String? parentId;
  final String? containerId;
  final String orderKey;
}

/// Re-keys every `tab.order_key` after the `from17To18` rebuild so the
/// pre-migration visible order survives it.
///
/// Tabs are grouped into scopes of `(space_uuid, folder_id, tab_shelf)` —
/// `folder_id` is always NULL immediately after this migration, since
/// folders are new in v18 — and, within each scope, ordered as they used to
/// be ordered on screen: by the tab's (new) container's `order_key`, then by
/// the tab's own (old) `order_key`. Root tabs (no in-scope parent) are laid
/// out in that order first; each root's descendants, in the same DFS
/// pre-order used by `TabDao`'s own between-generation helpers
/// (`_generateOrderKeysBetween`), immediately follow it. Every tab in a scope
/// then gets a fresh, densely-increasing `LexoRank` key in that final order.
Future<void> _rekeyTabOrderAfterV18Migration(TabDatabase database) async {
  final containerOrderKeys = <String, String>{
    for (final row
        in await database
            .customSelect('SELECT id, order_key FROM container')
            .get())
      row.read<String>('id'): row.read<String>('order_key'),
  };

  final tabsByScope = <(String?, int), List<_MigratedTabRow>>{};
  for (final row
      in await database
          .customSelect(
            'SELECT id, parent_id, container_id, space_uuid, tab_shelf, '
            'order_key FROM tab WHERE folder_id IS NULL',
          )
          .get()) {
    final scope = (row.read<String?>('space_uuid'), row.read<int>('tab_shelf'));
    (tabsByScope[scope] ??= []).add(
      _MigratedTabRow(
        id: row.read<String>('id'),
        parentId: row.read<String?>('parent_id'),
        containerId: row.read<String?>('container_id'),
        orderKey: row.read<String>('order_key'),
      ),
    );
  }

  for (final scopedTabs in tabsByScope.values) {
    final byId = {for (final tab in scopedTabs) tab.id: tab};
    final childrenByParentId = <String, List<_MigratedTabRow>>{};
    final roots = <_MigratedTabRow>[];
    for (final tab in scopedTabs) {
      final parentId = tab.parentId;
      if (parentId != null && byId.containsKey(parentId)) {
        (childrenByParentId[parentId] ??= []).add(tab);
      } else {
        roots.add(tab);
      }
    }
    for (final children in childrenByParentId.values) {
      children.sort((a, b) => a.orderKey.compareTo(b.orderKey));
    }
    roots.sort((a, b) {
      final containerOrder = (containerOrderKeys[a.containerId] ?? 'zzz')
          .compareTo(containerOrderKeys[b.containerId] ?? 'zzz');
      return containerOrder != 0
          ? containerOrder
          : a.orderKey.compareTo(b.orderKey);
    });

    final dfsOrder = <String>[];
    void visit(_MigratedTabRow tab) {
      dfsOrder.add(tab.id);
      for (final child
          in childrenByParentId[tab.id] ?? const <_MigratedTabRow>[]) {
        visit(child);
      }
    }

    for (final root in roots) {
      visit(root);
    }

    var rank = LexoRank.middle();
    for (final id in dfsOrder) {
      await database.customStatement(
        'UPDATE tab SET order_key = ? WHERE id = ?',
        [rank.value, id],
      );
      rank = rank.genNext();
    }
  }
}
