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
import 'package:drift/drift.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/definitions.drift.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_summary.dart';

/// The `tab` columns a [TabSummary] is built from.
///
/// Deliberately omits `extracted_content_*`, `full_content_*` and
/// `content_hash`; see [TabSummary] for why reading them is expensive enough to
/// be worth spelling the projection out by hand.
List<Expression<Object>> tabSummaryColumns(Tab tab) => [
  tab.id,
  tab.engineTabId,
  tab.source,
  tab.containerId,
  tab.spaceUuid,
  tab.folderId,
  tab.splitId,
  tab.splitIndex,
  tab.tabShelf,
  tab.orderKey,
  tab.url,
  tab.title,
  tab.iconUrl,
  tab.staticLabel,
  tab.tabMode,
  tab.isProbablyReaderable,
  tab.timestamp,
];

/// Reads a row produced by a `selectOnly` over [tabSummaryColumns].
TabSummary readTabSummary(TypedResult row, Tab tab) => TabSummary(
  id: row.read(tab.id)!,
  engineTabId: row.read(tab.engineTabId),
  source: row.readWithConverter(tab.source)!,
  containerId: row.read(tab.containerId),
  spaceUuid: row.read(tab.spaceUuid),
  folderId: row.read(tab.folderId),
  splitId: row.read(tab.splitId),
  splitIndex: row.read(tab.splitIndex),
  tabShelf: row.readWithConverter(tab.tabShelf)!,
  orderKey: row.read(tab.orderKey)!,
  // Type arguments pinned: inference would take the `Uri?` context type as
  // `D?` and demand a non-nullable `Uri` converter column.
  url: row.readWithConverter<Uri?, String>(tab.url),
  title: row.read(tab.title),
  iconUrl: row.read(tab.iconUrl),
  staticLabel: row.read(tab.staticLabel),
  tabMode: row.readWithConverter(tab.tabMode)!,
  isProbablyReaderable: row.read(tab.isProbablyReaderable),
  timestamp: row.read(tab.timestamp)!,
);

/// A `selectOnly` over [tabSummaryColumns], mapped to [TabSummary].
///
/// Callers add their own `where`/`orderBy`/`limit` to the returned statement
/// before mapping — hence the two-step shape rather than one helper.
JoinedSelectStatement<Tab, TabData> selectTabSummaries(
  DatabaseConnectionUser db,
  Tab tab,
) => db.selectOnly(tab)..addColumns(tabSummaryColumns(tab));
