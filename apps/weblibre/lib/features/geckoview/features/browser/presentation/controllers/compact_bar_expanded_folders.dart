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
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compact_bar_expanded_folders.g.dart';

/// The folders the compact tab bar currently shows the members of, by folder
/// id. Local to the bar and never persisted: a folder's stored collapse state
/// belongs to the tray and the desktop sidebar, while the bar only has room
/// for one folder's members at a time and forgets them on restart.
@Riverpod(keepAlive: true)
class CompactBarExpandedFolders extends _$CompactBarExpandedFolders {
  @override
  Set<String> build() => const {};

  bool isExpanded(String folderId) => state.contains(folderId);

  void toggle(String folderId) {
    state = state.contains(folderId)
        ? ({...state}..remove(folderId))
        : {...state, folderId};
  }
}
