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
import 'package:weblibre/features/user/data/database/database.dart';
import 'package:weblibre/features/user/data/database/definitions.drift.dart';

@DriftAccessor()
class SearchHistoryDao extends DatabaseAccessor<UserDatabase> {
  SearchHistoryDao(super.attachedDatabase);

  Stream<List<SearchHistoryData>> watchEntries({required int limit}) {
    return db.definitionsDrift.searchHistoryEntries(limit: limit).watch();
  }

  Future<void> addEntry(String searchQuery, {required int maxEntryCount}) {
    // Bundled in a transaction so a write and the eviction it triggers land
    // as a single rebuild of any watch() query, matching the bangs-era
    // behaviour this replaces.
    return transaction(() async {
      await db.searchHistory.insertOne(
        SearchHistoryCompanion.insert(
          searchQuery: searchQuery,
          searchDate: DateTime.now(),
        ),
        // The old table relied on `search_query UNIQUE` to move a repeated
        // query to the top instead of duplicating it; insertOrReplace on the
        // primary key gets the same effect here.
        mode: InsertMode.insertOrReplace,
      );
      await db.definitionsDrift.evictHistoryEntries(limit: maxEntryCount);
    });
  }

  Future<void> removeEntry(String searchQuery) {
    return db.searchHistory.deleteWhere(
      (t) => t.searchQuery.equals(searchQuery),
    );
  }

  Future<int> clear() {
    return db.searchHistory.deleteAll();
  }

  Future<void> evictBeyond(int limit) {
    return db.definitionsDrift.evictHistoryEntries(limit: limit);
  }
}
