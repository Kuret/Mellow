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
import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:weblibre/data/database/converters/color.dart';
import 'package:weblibre/data/database/converters/icon_data.dart';
import 'package:weblibre/features/wallpaper/domain/entities/wallpaper_override.dart';

part 'container_data.g.dart';

@CopyWith()
@JsonSerializable(constructor: 'withDefaults')
class ContainerMetadata with FastEquatable {
  @IconDataJsonConverter()
  final IconData? iconData;

  final String? contextualIdentity;

  @JsonKey(defaultValue: false)
  final bool clearDataOnExit;

  // Read by the `tab_to_history_on_*` SQL triggers via
  // `json_extract(metadata, '$.excludeFromIndex')`. Keep this key name in
  // sync with the trigger gate in definitions.drift.
  @JsonKey(defaultValue: false)
  final bool excludeFromIndex;

  // When true, this container's browsing history is not recorded at all: the
  // history delegate of each of its tabs skips the Mozilla Places write (hard
  // exclude / "incognito container"), and no visit→container relation row is
  // written. Gates history recording independently of `excludeFromIndex` (which
  // only gates the local FTS search index).
  //
  // Applies to every container: the exclusion is replicated to native per tab,
  // not per Gecko contextId, so it works with cookie isolation off — where all
  // of the container's tabs share the default context — just as well as on.
  @JsonKey(defaultValue: false)
  final bool excludeFromHistory;

  // When true, ContainerData.color is used directly as primaryContainer
  // instead of being fed through ColorScheme.fromSeed. Lets power users pick
  // any color (including dark/black) at the cost of M3 harmonization.
  @JsonKey(defaultValue: false)
  final bool useCustomColor;

  // This container's own home wallpaper, shown instead of the profile-wide one
  // while the container is selected. Null follows the profile. See
  // [WallpaperOverride] and [GeneralSettings.homeWallpaperFile].
  //
  // This needs no contextId: it is pure presentation, resolved in Dart from
  // the selected container, and means the same thing with cookie isolation
  // off.
  final WallpaperOverride? wallpaper;

  ContainerMetadata({
    required this.iconData,
    required this.contextualIdentity,
    required this.clearDataOnExit,
    required this.excludeFromIndex,
    required this.excludeFromHistory,
    required this.useCustomColor,
    required this.wallpaper,
  });

  ContainerMetadata.withDefaults({
    IconData? iconData,
    String? contextualIdentity,
    bool? clearDataOnExit,
    bool? excludeFromIndex,
    bool? excludeFromHistory,
    bool? useCustomColor,
    WallpaperOverride? wallpaper,
  }) : this(
         iconData: iconData,
         contextualIdentity: contextualIdentity,
         clearDataOnExit: clearDataOnExit ?? false,
         excludeFromIndex: excludeFromIndex ?? false,
         excludeFromHistory: excludeFromHistory ?? false,
         useCustomColor: useCustomColor ?? false,
         wallpaper: wallpaper,
       );

  /// No-op today — kept as the seam writers route persistence through, so a
  /// future contextId-only field has somewhere to normalize itself before
  /// being written.
  ///
  /// [excludeFromHistory] is deliberately absent from any such normalization:
  /// it is keyed on tabs natively and applies to every container.
  ContainerMetadata sanitized() => this;

  factory ContainerMetadata.fromJson(Map<String, dynamic> json) =>
      _$ContainerMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ContainerMetadataToJson(this);

  @override
  List<Object?> get hashParameters => [
    iconData,
    contextualIdentity,
    clearDataOnExit,
    excludeFromIndex,
    excludeFromHistory,
    useCustomColor,
    wallpaper,
  ];
}

@JsonSerializable()
@CopyWith()
class ContainerData with FastEquatable {
  final String id;
  final String? name;
  @ColorJsonConverter()
  final Color color;

  final String orderKey;

  @JsonKey(defaultValue: false)
  final bool isPinned;

  final ContainerMetadata metadata;

  ContainerData({
    required this.id,
    this.name,
    required this.color,
    required this.orderKey,
    this.isPinned = false,
    ContainerMetadata? metadata,
  }) : metadata = metadata ?? ContainerMetadata.withDefaults();

  factory ContainerData.fromJson(Map<String, dynamic> json) =>
      _$ContainerDataFromJson(json);

  Map<String, dynamic> toJson() => _$ContainerDataToJson(this);

  @override
  List<Object?> get hashParameters => [
    id,
    name,
    color,
    orderKey,
    isPinned,
    metadata,
  ];
}

@JsonSerializable()
class ContainerDataWithCount extends ContainerData {
  final int? tabCount;

  ContainerDataWithCount({
    required super.id,
    super.name,
    required super.color,
    required super.orderKey,
    super.isPinned,
    super.metadata,
    required this.tabCount,
  });

  factory ContainerDataWithCount.fromJson(Map<String, dynamic> json) =>
      _$ContainerDataWithCountFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ContainerDataWithCountToJson(this);

  @override
  List<Object?> get hashParameters => [...super.hashParameters, tabCount];
}
