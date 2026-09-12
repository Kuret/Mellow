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

part 'container_local_data.g.dart';

/// Local-only per-container settings, never synced (Zen has no equivalent).
@JsonSerializable()
@CopyWith()
class ContainerLocalData with FastEquatable {
  final String containerId;

  @JsonKey(defaultValue: false)
  final bool excludeFromIndex;

  @JsonKey(defaultValue: false)
  final bool excludeFromHistory;

  @JsonKey(defaultValue: false)
  final bool clearDataOnExit;

  /// JSON of `WallpaperOverride`; stored as plain text, the model layer
  /// converts.
  final String? wallpaper;

  ContainerLocalData({
    required this.containerId,
    this.excludeFromIndex = false,
    this.excludeFromHistory = false,
    this.clearDataOnExit = false,
    this.wallpaper,
  });

  factory ContainerLocalData.fromJson(Map<String, dynamic> json) =>
      _$ContainerLocalDataFromJson(json);

  /// The settings a container has before any row was written for it — every
  /// flag off, no wallpaper.
  factory ContainerLocalData.defaults(String containerId) =>
      ContainerLocalData(containerId: containerId);

  Map<String, dynamic> toJson() => _$ContainerLocalDataToJson(this);

  @override
  List<Object?> get hashParameters => [
    containerId,
    excludeFromIndex,
    excludeFromHistory,
    clearDataOnExit,
    wallpaper,
  ];
}
