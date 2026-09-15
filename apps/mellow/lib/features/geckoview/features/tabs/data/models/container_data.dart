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
import 'package:weblibre/features/geckoview/features/tabs/utils/firefox_container_vocab.dart';

part 'container_data.g.dart';

@JsonSerializable()
@CopyWith()
class ContainerData with FastEquatable {
  final String id;

  /// Zen sync guid: uuid or `builtin-1`..`builtin-4`. Null until this
  /// container is first projected to the sync collection (PLAN §6.2).
  final String? syncGuid;

  final String name;

  /// Firefox icon keyword, stored raw as received/chosen.
  final String iconKey;

  /// Firefox colour keyword, stored raw.
  final String colorKey;

  final String orderKey;

  @JsonKey(defaultValue: false)
  final bool isPinned;

  ContainerData({
    required this.id,
    this.syncGuid,
    this.name = '',
    this.iconKey = 'circle',
    this.colorKey = 'blue',
    required this.orderKey,
    this.isPinned = false,
  });

  factory ContainerData.fromJson(Map<String, dynamic> json) =>
      _$ContainerDataFromJson(json);

  /// Display interpretation of [colorKey]; unknown keywords render as
  /// [FirefoxContainerColor.toolbar]. The raw keyword stays in the row.
  FirefoxContainerColor get color =>
      FirefoxContainerColor.fromKeyword(colorKey);

  /// Display interpretation of [iconKey]; unknown keywords render as
  /// [FirefoxContainerIcon.circle]. The raw keyword stays in the row.
  FirefoxContainerIcon get icon => FirefoxContainerIcon.fromKeyword(iconKey);

  Map<String, dynamic> toJson() => _$ContainerDataToJson(this);

  @override
  List<Object?> get hashParameters => [
    id,
    syncGuid,
    name,
    iconKey,
    colorKey,
    orderKey,
    isPinned,
  ];
}

@JsonSerializable()
class ContainerDataWithCount extends ContainerData {
  final int? tabCount;

  ContainerDataWithCount({
    required super.id,
    super.syncGuid,
    super.name,
    super.iconKey,
    super.colorKey,
    required super.orderKey,
    super.isPinned,
    required this.tabCount,
  });

  factory ContainerDataWithCount.fromJson(Map<String, dynamic> json) =>
      _$ContainerDataWithCountFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ContainerDataWithCountToJson(this);

  @override
  List<Object?> get hashParameters => [...super.hashParameters, tabCount];
}
