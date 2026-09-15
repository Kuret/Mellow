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
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_source.dart';

/// Every column of `tab` except the four content columns and `content_hash`.
///
/// The reason this type exists rather than reusing drift's `TabData`: a `tab`
/// row carries up to four 256 KB text columns (`TabDao._contentSizeCap`) plus
/// `content_hash`, a `VIRTUAL` generated column SQLite evaluates through a Dart
/// UDF for every row it materialises. So `SELECT *` on `tab` re-encodes and
/// re-hashes every stored page's full text — and the queries that render tabs
/// are `.watch()` streams that re-run on *every* write to the table
/// (`touchTab` on each tab switch, `updateTabContent` on each extraction). None
/// of those consumers reads a content column.
///
/// Anything that genuinely wants page text goes through `TabDao.getTabDataById`
/// for the one row it needs.
class TabSummary with FastEquatable {
  final String id;

  /// `NULL` = cold tab, no live engine session (PLAN §7.4). When set it equals
  /// [id] (DESIGN.md "D2 refinement").
  final String? engineTabId;
  final TabSource source;
  final String? containerId;
  final String? spaceUuid;
  final String? folderId;
  final String? splitId;
  final int? splitIndex;
  final TabShelf tabShelf;
  final String orderKey;
  final Uri? url;
  final String? title;
  final String? iconUrl;

  /// Zen's user-renamed tab title. Rendered in preference to [title] when set.
  final String? staticLabel;
  final TabModeDbValue tabMode;
  final bool? isProbablyReaderable;
  final DateTime timestamp;

  bool get isCold => engineTabId == null;

  // Not `const`: the FastEquatable mixin carries a mutable cached-hash field.
  TabSummary({
    required this.id,
    required this.engineTabId,
    required this.source,
    required this.containerId,
    required this.spaceUuid,
    required this.folderId,
    required this.splitId,
    required this.splitIndex,
    required this.tabShelf,
    required this.orderKey,
    required this.url,
    required this.title,
    required this.iconUrl,
    required this.staticLabel,
    required this.tabMode,
    required this.isProbablyReaderable,
    required this.timestamp,
  });

  @override
  List<Object?> get hashParameters => [
    id,
    engineTabId,
    source,
    containerId,
    spaceUuid,
    folderId,
    splitId,
    splitIndex,
    tabShelf,
    orderKey,
    url,
    title,
    iconUrl,
    staticLabel,
    tabMode,
    isProbablyReaderable,
    timestamp,
  ];
}
