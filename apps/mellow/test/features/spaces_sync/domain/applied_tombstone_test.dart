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
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';

import '../../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';

/// Writes a row with an explicit timestamp; `recordAppliedTombstone` always
/// stamps `now`, and these tests need a window either side of it.
Future<void> _applyAt(TabDatabase db, String id, DateTime at) =>
    db.appliedTombstone.insertOne(
      AppliedTombstoneCompanion.insert(id: id, appliedAt: at),
      mode: InsertMode.insertOrReplace,
    );

void main() {
  late TabDatabase db;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = openTestTabDatabase();
  });
  tearDown(() => db.close());

  test('a recorded tombstone comes back with its time', () async {
    final before = DateTime.now().subtract(const Duration(seconds: 2));
    await db.syncStateDao.recordAppliedTombstone('gone');

    final applied = await db.syncStateDao.appliedTombstonesSince(before);
    expect(applied.keys, ['gone']);
    expect(applied['gone']!.isAfter(before), isTrue);
  });

  test('recording the same id twice keeps one row', () async {
    await db.syncStateDao.recordAppliedTombstone('gone');
    await db.syncStateDao.recordAppliedTombstone('gone');

    expect(
      await db.syncStateDao.appliedTombstonesSince(
        DateTime.fromMillisecondsSinceEpoch(0),
      ),
      hasLength(1),
    );
  });

  test('the window excludes anything older than it', () async {
    final now = DateTime.now();
    await _applyAt(db, 'old', now.subtract(const Duration(hours: 2)));
    await _applyAt(db, 'recent', now.subtract(const Duration(minutes: 1)));

    final recent = await db.syncStateDao.appliedTombstonesSince(
      now.subtract(const Duration(minutes: 10)),
    );
    expect(recent.keys, ['recent']);
  });

  test('pruning drops the entries before the cutoff only', () async {
    final now = DateTime.now();
    await _applyAt(db, 'old', now.subtract(const Duration(hours: 2)));
    await _applyAt(db, 'recent', now.subtract(const Duration(minutes: 1)));

    await db.syncStateDao.pruneAppliedTombstones(
      now.subtract(const Duration(hours: 1)),
    );

    expect(
      (await db.syncStateDao.appliedTombstonesSince(
        DateTime.fromMillisecondsSinceEpoch(0),
      )).keys,
      ['recent'],
    );
  });

  test('an applied remote tombstone is not a local deletion', () async {
    await db.syncStateDao.recordAppliedTombstone('gone');

    expect(await db.syncStateDao.pendingDeletions(), isEmpty);
  });
}
