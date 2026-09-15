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
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tab_split_data.g.dart';

/// A Zen split view: a set of tabs shown side by side in one slot
/// (PLAN §6.5).
@JsonSerializable()
@CopyWith()
class TabSplitData with FastEquatable {
  final String id;

  final String gridType;

  /// Zen's `split.pinned`, round-tripped.
  @JsonKey(defaultValue: false)
  final bool isPinned;

  final String? spaceUuid;

  final String? folderId;

  final String orderKey;

  TabSplitData({
    required this.id,
    this.gridType = 'grid',
    this.isPinned = false,
    this.spaceUuid,
    this.folderId,
    required this.orderKey,
  });

  factory TabSplitData.fromJson(Map<String, dynamic> json) =>
      _$TabSplitDataFromJson(json);

  Map<String, dynamic> toJson() => _$TabSplitDataToJson(this);

  @override
  List<Object?> get hashParameters => [
    id,
    gridType,
    isPinned,
    spaceUuid,
    folderId,
    orderKey,
  ];
}
