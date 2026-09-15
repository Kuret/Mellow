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

/// Whether a tab row has an engine session behind it (PLAN §7.4, DESIGN.md
/// "Cold tabs").
///
/// - [live]: the engine reports state for it.
/// - [restoring]: the row says it is live (`engine_tab_id` set) but the
///   session restore has not delivered its state yet.
/// - [cold]: no engine session (`engine_tab_id IS NULL`); rendered as a
///   placeholder from the row, materialised on selection.
enum TabPresence {
  live,
  restoring,
  cold;

  /// The row cannot answer for itself yet: what the widgets used to call
  /// `isPlaceholder`.
  bool get isPlaceholder => this != live;
}
