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
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// The `riverpod` table's generated class is also named `Riverpod`, colliding
// with the annotation of the same name from riverpod_annotation.
import 'package:weblibre/features/user/data/database/definitions.drift.dart'
    hide Riverpod;
import 'package:weblibre/features/user/data/providers.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

part 'search_history.g.dart';

/// Address-bar search history. Rehomed from the bangs database so it outlives
/// the bangs feature; the engine a search ran through was never surfaced
/// anywhere, so only the query text and its timestamp made the move.
@Riverpod(keepAlive: true)
class SearchHistoryRepository extends _$SearchHistoryRepository {
  Stream<List<SearchHistoryData>> watchEntries({required int limit}) {
    // drift's watch() already emits the current rows immediately on
    // subscription, so Recent Searches is populated on app start without
    // waiting for the next search_history write.
    return ref
        .read(userDatabaseProvider)
        .searchHistoryDao
        .watchEntries(limit: limit);
  }

  Future<void> addEntry(String searchQuery, {required int maxEntryCount}) {
    // Skip capturing history if maxEntryCount is 0
    if (maxEntryCount <= 0) {
      return Future.value();
    }

    return ref
        .read(userDatabaseProvider)
        .searchHistoryDao
        .addEntry(searchQuery, maxEntryCount: maxEntryCount);
  }

  Future<void> removeEntry(String searchQuery) {
    return ref
        .read(userDatabaseProvider)
        .searchHistoryDao
        .removeEntry(searchQuery);
  }

  Future<int> clear() {
    return ref.read(userDatabaseProvider).searchHistoryDao.clear();
  }

  @override
  void build() {
    return;
  }
}

@Riverpod()
Stream<List<SearchHistoryData>> searchHistory(Ref ref) {
  final repository = ref.watch(searchHistoryRepositoryProvider.notifier);
  final maxSearchHistoryEntries = ref.watch(
    generalSettingsWithDefaultsProvider.select(
      (s) => s.maxSearchHistoryEntries,
    ),
  );
  return repository.watchEntries(limit: maxSearchHistoryEntries);
}
