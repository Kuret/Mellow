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
import 'package:weblibre/features/geckoview/features/tabs/data/database/daos/sync_state.drift.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart';

/// Zen sync bookkeeping (PLAN §8): `sync_record_state` mirrors the desktop's
/// `zen-spaces-sync.json` "uploaded" digests so a sync only pushes records
/// that changed; `foreign_record` holds remote records this device must
/// round-trip verbatim without modelling them.
@DriftAccessor()
class SyncStateDao extends DatabaseAccessor<TabDatabase>
    with $SyncStateDaoMixin {
  SyncStateDao(super.db);

  Future<String?> getDigest(String recordId) async {
    final row =
        await (db.syncRecordState.select()
              ..where((s) => s.recordId.equals(recordId)))
            .getSingleOrNull();
    return row?.digest;
  }

  /// Every stored digest keyed by record id, with the record's kind.
  Future<Map<String, ({String kind, String digest})>> allDigests() async {
    final rows = await db.syncRecordState.select().get();
    return {
      for (final row in rows)
        row.recordId: (kind: row.kind, digest: row.digest),
    };
  }

  Future<void> putDigest(String recordId, String kind, String digest) =>
      db.syncRecordState.insertOne(
        SyncRecordStateCompanion.insert(
          recordId: recordId,
          kind: kind,
          digest: digest,
        ),
        onConflict: DoUpdate(
          (_) => SyncRecordStateCompanion(
            kind: Value(kind),
            digest: Value(digest),
          ),
        ),
      );

  Future<void> deleteDigest(String recordId) =>
      (db.syncRecordState.delete()..where((s) => s.recordId.equals(recordId)))
          .go();

  /// Forgets every digest, e.g. after a collection `syncID` reset — the next
  /// sync then re-uploads everything.
  Future<void> clearAll() => db.syncRecordState.delete().go();

  Future<void> upsertForeign(
    String id, {
    required String kind,
    required String payload,
    required double modified,
  }) => db.foreignRecord.insertOne(
    ForeignRecordCompanion.insert(
      id: id,
      kind: kind,
      payload: payload,
      modified: modified,
    ),
    onConflict: DoUpdate(
      (_) => ForeignRecordCompanion(
        kind: Value(kind),
        payload: Value(payload),
        modified: Value(modified),
      ),
    ),
  );

  Future<void> deleteForeign(String id) =>
      (db.foreignRecord.delete()..where((r) => r.id.equals(id))).go();

  Future<List<ForeignRecordData>> allForeign() =>
      db.foreignRecord.select().get();
}
