// dart format width=80
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/data/database/functions/url_functions.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/firefox_container_vocab.dart';

import 'generated/schema.dart';
import 'generated/schema_v17.dart' as v17;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper(), setup: registerUrlFunctions);
  });

  test(
    'migration from v17 to v18 backfills spaces, containers and tab order',
    () async {
      final schema = await verifier.schemaAt(17);
      final oldDb = v17.DatabaseAtV17(schema.newConnection());

      // Container A: named, custom color and a legacy MDI icon that maps to
      // a Firefox keyword, history/index excluded via the old metadata JSON.
      // `contextualIdentity` is a removed key (D3 refinement) and must be
      // ignored rather than rejected.
      const briefcaseCodePoint = 0xf00d6;
      const containerAMetadata =
          '{"iconData":{"codePoint":$briefcaseCodePoint, '
          '"fontFamily":"Material Design Icons", '
          '"fontPackage":"flutter_material_design_icons", '
          '"matchTextDirection":false}, '
          '"excludeFromHistory":true,"excludeFromIndex":true, '
          '"clearDataOnExit":false,"contextualIdentity":"a"}';
      await oldDb.customStatement(
        'INSERT INTO container '
        '(id, name, color, order_key, is_pinned, metadata) '
        "VALUES ('a', 'Work', ?, 'a', 0, ?)",
        [0xFF00C79A, containerAMetadata],
      );

      // Container B: unnamed, no metadata at all (both are legal in v17).
      await oldDb.customStatement(
        'INSERT INTO container '
        "(id, name, color, order_key, is_pinned, metadata) "
        "VALUES ('b', NULL, ?, 'b', 0, NULL)",
        [0xFF123456],
      );

      Future<void> insertTab({
        required String id,
        required String? containerId,
        required String orderKey,
        required int tabMode,
        required bool isPinned,
        String? parentId,
        String? isolationContextId,
      }) {
        final isPinnedValue = isPinned ? 1 : 0;
        return oldDb.customStatement(
          'INSERT INTO tab '
          '(id, source, parent_id, container_id, order_key, tab_mode, '
          'isolation_context_id, is_pinned, timestamp) '
          'VALUES (?, 2, ?, ?, ?, ?, ?, ?, 0)',
          [
            id,
            parentId,
            containerId,
            orderKey,
            tabMode,
            isolationContextId,
            isPinnedValue,
          ],
        );
      }

      // t1: pinned, in A.
      await insertTab(
        id: 't1',
        containerId: 'a',
        orderKey: 'p1',
        tabMode: 0,
        isPinned: true,
      );
      // t2: normal, in A — sorts before B's tabs in the normal shelf scope.
      await insertTab(
        id: 't2',
        containerId: 'a',
        orderKey: 'a2',
        tabMode: 0,
        isPinned: false,
      );
      // t3: private, no container.
      await insertTab(
        id: 't3',
        containerId: null,
        orderKey: 'z0',
        tabMode: 1,
        isPinned: false,
      );
      // t4: isolated, in B.
      await insertTab(
        id: 't4',
        containerId: 'b',
        orderKey: 'b1',
        tabMode: 2,
        isPinned: false,
        isolationContextId: 'iso',
      );
      // t5: normal, in B, parent of t6.
      await insertTab(
        id: 't5',
        containerId: 'b',
        orderKey: 'b2',
        tabMode: 0,
        isPinned: false,
      );
      // t6: normal, in B, child of t5 — must land immediately after it.
      await insertTab(
        id: 't6',
        containerId: 'b',
        orderKey: 'b3',
        tabMode: 0,
        isPinned: false,
        parentId: 't5',
      );
      // t7: normal, no container — sorts last (no container order_key).
      await insertTab(
        id: 't7',
        containerId: null,
        orderKey: 'z1',
        tabMode: 0,
        isPinned: false,
      );

      await oldDb.close();

      final db = TabDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 18);

      // --- Default space ---
      final spaces = await db
          .customSelect('SELECT uuid, name, order_index FROM space')
          .get();
      expect(spaces, hasLength(1));
      final spaceUuid = spaces.single.read<String>('uuid');
      expect(spaces.single.read<String>('name'), '');
      expect(spaces.single.read<int>('order_index'), 0);

      // --- Per-tab backfilled columns ---
      final tabRows = {
        for (final row
            in await db
                .customSelect(
                  'SELECT id, engine_tab_id, tab_shelf, space_uuid, tab_mode, '
                  'folder_id FROM tab',
                )
                .get())
          row.read<String>('id'): row,
      };
      expect(tabRows, hasLength(7));

      expect(tabRows['t1']!.read<int>('tab_shelf'), 1);
      for (final id in ['t2', 't3', 't4', 't5', 't6', 't7']) {
        expect(
          tabRows[id]!.read<int>('tab_shelf'),
          0,
          reason: '$id should not be on the pinned shelf',
        );
      }

      expect(tabRows['t3']!.read<String?>('space_uuid'), null);
      for (final id in ['t1', 't2', 't4', 't5', 't6', 't7']) {
        expect(
          tabRows[id]!.read<String?>('space_uuid'),
          spaceUuid,
          reason: '$id should be in the default space',
        );
      }

      for (final id in ['t1', 't2', 't3', 't4', 't5', 't6', 't7']) {
        expect(tabRows[id]!.read<String>('engine_tab_id'), id);
      }

      // Isolated (2) folds into regular (0); isolation is now intrinsic to
      // the container id.
      expect(tabRows['t4']!.read<int>('tab_mode'), 0);

      expect(
        tabRows['t6']!.read<String?>('space_uuid'),
        tabRows['t5']!.read<String?>('space_uuid'),
      );
      expect(
        tabRows['t6']!.read<String?>('folder_id'),
        tabRows['t5']!.read<String?>('folder_id'),
      );

      // --- Containers ---
      final containers = {
        for (final row
            in await db
                .customSelect(
                  'SELECT id, name, icon_key, color_key FROM container',
                )
                .get())
          row.read<String>('id'): row,
      };
      expect(containers['a']!.read<String>('name'), 'Work');
      expect(containers['a']!.read<String>('color_key'), 'turquoise');
      expect(containers['a']!.read<String>('icon_key'), 'briefcase');

      expect(containers['b']!.read<String>('name'), '');
      expect(containers['b']!.read<String>('icon_key'), 'circle');
      expect(
        containers['b']!.read<String>('color_key'),
        FirefoxContainerColor.nearestTo(0xFF123456).keyword,
      );

      // --- container_local ---
      final containerLocal = {
        for (final row
            in await db
                .customSelect(
                  'SELECT container_id, exclude_from_index, '
                  'exclude_from_history, clear_data_on_exit FROM container_local',
                )
                .get())
          row.read<String>('container_id'): row,
      };
      expect(containerLocal['a']!.read<bool>('exclude_from_history'), isTrue);
      expect(containerLocal['a']!.read<bool>('exclude_from_index'), isTrue);
      expect(containerLocal['a']!.read<bool>('clear_data_on_exit'), isFalse);
      expect(containerLocal['b']!.read<bool>('exclude_from_history'), isFalse);
      expect(containerLocal['b']!.read<bool>('exclude_from_index'), isFalse);
      expect(containerLocal['b']!.read<bool>('clear_data_on_exit'), isFalse);

      // --- Order survives the rebuild, per shelf scope ---
      final normalShelf = await db
          .customSelect(
            'SELECT id FROM tab '
            "WHERE tab_shelf = 0 AND space_uuid = '$spaceUuid' "
            'ORDER BY order_key',
          )
          .get();
      expect(
        [for (final row in normalShelf) row.read<String>('id')],
        ['t2', 't4', 't5', 't6', 't7'],
        reason:
            "A's tabs (t2) sort before B's (t4, t5, t6); t6 immediately "
            'follows its parent t5; the containerless tab (t7) sorts last',
      );

      final pinnedShelf = await db
          .customSelect(
            "SELECT id FROM tab WHERE tab_shelf = 1 ORDER BY order_key",
          )
          .get();
      expect([for (final row in pinnedShelf) row.read<String>('id')], ['t1']);

      // --- tab_fts stays in sync with the rebuilt table ---
      final ftsCount =
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM tab_fts')
                  .getSingle())
              .read<int>('c');
      final tabCount =
          (await db.customSelect('SELECT COUNT(*) AS c FROM tab').getSingle())
              .read<int>('c');
      expect(ftsCount, tabCount);

      // --- isolation_context_id is gone ---
      final tabColumns = await db.customSelect('PRAGMA table_info(tab)').get();
      expect(
        tabColumns.map((row) => row.read<String>('name')),
        isNot(contains('isolation_context_id')),
      );

      await db.close();
    },
  );
}
