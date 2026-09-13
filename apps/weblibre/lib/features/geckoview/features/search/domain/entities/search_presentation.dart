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

/// How the search surface is presented.
///
/// The screen's content is the same either way — the tab-type switcher, the
/// field, bangs and every suggestion module. Only the chrome around it and
/// how it is sized differ.
enum SearchPresentation {
  /// A page of its own: opaque, full-bleed, with a [Scaffold] and a safe area.
  ///
  /// This is what an intent that opened the app from outside gets, because
  /// there is no browser behind the search to float over.
  fullScreen,

  /// A floating card over whatever was already on screen.
  ///
  /// The caller owns the backdrop and the card, and hands the screen a height
  /// budget; the screen shrink-wraps to its content up to that budget so an
  /// empty query is a field and a short list, not a tall empty box.
  panel,
}
