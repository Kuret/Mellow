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
import 'package:mellow/features/geckoview/domain/entities/states/history.dart';
import 'package:mellow/features/geckoview/domain/entities/states/tab.dart';
import 'package:mellow/features/geckoview/features/browser/domain/entities/sheet.dart';

class ContextualToolbarScope with FastEquatable {
  final String? selectedTabId;
  final Sheet? displayedSheet;
  final TabState? tabState;

  /// Back/forward availability. Lives outside [TabState] (see
  /// `providers/tab_detail_state.dart`) but the navigation buttons need it, so
  /// the toolbar resolves it once and passes it down with the scope.
  final HistoryState historyState;

  final bool isPreview;

  ContextualToolbarScope({
    required this.selectedTabId,
    required this.displayedSheet,
    required this.tabState,
    required this.isPreview,
    HistoryState? historyState,
  }) : historyState = historyState ?? HistoryState.$default();

  @override
  List<Object?> get hashParameters => [
    selectedTabId,
    displayedSheet,
    tabState,
    historyState,
    isPreview,
  ];
}
