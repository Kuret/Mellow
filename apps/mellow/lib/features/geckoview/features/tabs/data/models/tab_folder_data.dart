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

part 'tab_folder_data.g.dart';

/// A Zen tab folder: a nestable grouping of tabs within a space
/// (PLAN §4, §6.1).
@JsonSerializable()
@CopyWith()
class TabFolderData with FastEquatable {
  final String id;

  final String name;

  final String? icon;

  final String? spaceUuid;

  final String? parentFolderId;

  /// Opaque JSON, round-tripped verbatim.
  final String? live;

  /// Local only, never synced.
  @JsonKey(defaultValue: false)
  final bool isCollapsed;

  final String orderKey;

  TabFolderData({
    required this.id,
    this.name = '',
    this.icon,
    this.spaceUuid,
    this.parentFolderId,
    this.live,
    this.isCollapsed = false,
    required this.orderKey,
  });

  factory TabFolderData.fromJson(Map<String, dynamic> json) =>
      _$TabFolderDataFromJson(json);

  Map<String, dynamic> toJson() => _$TabFolderDataToJson(this);

  @override
  List<Object?> get hashParameters => [
    id,
    name,
    icon,
    spaceUuid,
    parentFolderId,
    live,
    isCollapsed,
    orderKey,
  ];
}
