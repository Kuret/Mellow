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
import 'dart:async';
import 'dart:convert';

import 'package:riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/features/user/data/providers.dart';

part 'space_last_tab.g.dart';

/// What a space was last showing.
sealed class SpaceLastTabEntry {
  const SpaceLastTabEntry();
}

/// The space's tab list was last showing [tabId].
///
/// Recorded when the tab was selected; not proof it still exists or is still
/// in this space by the time it is read back — [tabId] can have been closed
/// or moved to another space in the meantime (locally, or through Zen sync),
/// and callers must validate it before selecting it.
final class SpaceLastTabTab extends SpaceLastTabEntry {
  const SpaceLastTabTab(this.tabId);

  final String tabId;
}

/// The space was last deliberately left on the home surface.
///
/// Distinct from "no entry" (never visited, or pruned): a space the user
/// explicitly sent home should come back to home, not to some tab picked by
/// a fallback.
final class SpaceLastTabHome extends SpaceLastTabEntry {
  const SpaceLastTabHome();
}

/// Per-space memory of what the tab list was last showing there, so
/// switching back to a space lands where it was left instead of on the home
/// surface.
///
/// Keyed on space uuid, holding either a tab id or an explicit "home" marker
/// (`null`). Absent from the map means "never recorded", which callers treat
/// the same as a stale/invalid entry — fall back to the space's own tabs.
///
/// A field of its own rather than a column on `ZenSettings`: that row is read
/// on hot paths and rewritten on every navigation, and would end up being
/// persisted on every tab switch for no reason connected to its own settings.
/// Local only — never part of Zen sync — and expected to go stale under it:
/// spaces and tabs can appear or disappear on the desktop side at any time,
/// so every read is a hint for `TabRepository.restoreSpaceTab` to validate,
/// never ground truth on its own.
@Riverpod(keepAlive: true)
class SpaceLastTab extends _$SpaceLastTab {
  Completer<void>? _ready;

  Future<void> _awaitReady() async {
    final ready = _ready;
    if (ready != null && !ready.isCompleted) {
      await ready.future;
    }
  }

  @override
  Map<String, String?> build() {
    final ready = Completer<void>();
    _ready = ready;
    final persistResult = persist(
      ref.watch(riverpodDatabaseStorageProvider),
      key: 'SpaceLastTab',
      options: const StorageOptions(cacheTime: StorageCacheTime.unsafe_forever),
      encode: jsonEncode,
      decode: (encoded) => (jsonDecode(encoded) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String?),
      ),
    );
    unawaited((persistResult.future ?? Future.value()).whenComplete(ready.complete));

    return stateOrNull ?? const {};
  }

  /// The entry recorded for [spaceUuid], or `null` if none was, or the
  /// persisted state has not loaded yet.
  Future<SpaceLastTabEntry?> entryFor(String spaceUuid) async {
    await _awaitReady();
    if (!ref.mounted || !state.containsKey(spaceUuid)) {
      return null;
    }
    final tabId = state[spaceUuid];
    return tabId == null ? const SpaceLastTabHome() : SpaceLastTabTab(tabId);
  }

  /// Records that [spaceUuid]'s tab list was last showing [tabId].
  Future<void> recordTab(String spaceUuid, String tabId) async {
    await _awaitReady();
    if (!ref.mounted || state[spaceUuid] == tabId) {
      return;
    }
    state = {...state, spaceUuid: tabId};
  }

  /// Records that [spaceUuid] was last deliberately left on the home
  /// surface.
  Future<void> recordHome(String spaceUuid) async {
    await _awaitReady();
    if (!ref.mounted ||
        (state.containsKey(spaceUuid) && state[spaceUuid] == null)) {
      return;
    }
    state = {...state, spaceUuid: null};
  }

  /// Drops entries for spaces not in [validSpaceUuids], so a space that gets
  /// deleted does not leave its entry behind forever.
  Future<void> pruneToSpaces(Set<String> validSpaceUuids) async {
    await _awaitReady();
    if (!ref.mounted || state.keys.every(validSpaceUuids.contains)) {
      return;
    }
    state = {
      for (final entry in state.entries)
        if (validSpaceUuids.contains(entry.key)) entry.key: entry.value,
    };
  }
}
