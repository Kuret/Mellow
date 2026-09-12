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
import 'package:fast_equatable/fast_equatable.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';

enum ScopeSlotKind { tab, folder, split }

/// One entry of a `(space_uuid, folder_id)` scope's ordered child sequence —
/// the local source of Zen's `children` array (PLAN §4.2, §6.6). A slot is a
/// root tab that is not a split member, a folder, or a split; split members
/// and essentials never occupy a slot.
class ScopeSlot with FastEquatable {
  final String id;
  final ScopeSlotKind kind;
  final String orderKey;

  /// [TabShelf.pinned] slots precede [TabShelf.normal] ones. Folders are
  /// always normal; a split is pinned when its `is_pinned` flag is set.
  final TabShelf shelf;

  // Not `const`: the FastEquatable mixin carries a mutable cached-hash field.
  ScopeSlot({
    required this.id,
    required this.kind,
    required this.orderKey,
    required this.shelf,
  });

  @override
  List<Object?> get hashParameters => [id, kind, orderKey, shelf];
}
