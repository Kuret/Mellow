import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_projection.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_sync_service.dart';

import '../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';
import 'spaces_sync_test_support.dart';

void main() {
  test('private tabs and about:blank tabs are never projected', () async {
    final harness = openApplierHarness();
    final db = harness.db;
    await seedSpaces(db, [space1]);
    await seedTab(db, 'regular', spaceUuid: space1);
    await seedTab(db, 'secret', tabMode: TabMode.private);
    await db.tabDao.insertTab(
      'blank',
      source: TabSource.manual,
      parentId: const Value(null),
      spaceUuid: const Value(space1),
      url: Value(Uri.parse('about:blank')),
    );
    await db.tabDao.insertTab(
      'empty',
      source: TabSource.manual,
      parentId: const Value(null),
      spaceUuid: const Value(space1),
    );

    final projected = await harness.container
        .read(spacesProjectionProvider)
        .project();

    expect(projected.keys, containsAll(['regular', space1, 'layout']));
    expect(projected.keys, isNot(contains('secret')));
    expect(projected.keys, isNot(contains('blank')));
    expect(projected.keys, isNot(contains('empty')));
    for (final record in projected.values) {
      expect(canonicalJsonMentions(record, 'secret'), isFalse);
      expect(canonicalJsonMentions(record, 'blank'), isFalse);
    }
  });

  test('an unauthenticated account makes no network calls', () async {
    final harness = await ServiceHarness.open(authenticated: false);
    await seedSpaces(harness.db, [space1]);
    await seedTab(harness.db, 'local', spaceUuid: space1);

    await harness.container
        .read(spacesSyncServiceProvider.notifier)
        .sync(reason: 'test');

    expect(harness.server.requests, isEmpty);
    expect(harness.container.read(spacesSyncServiceProvider).lastError, isNull);
  });
}

bool canonicalJsonMentions(Object record, String id) =>
    record.toString().contains('"$id"');
