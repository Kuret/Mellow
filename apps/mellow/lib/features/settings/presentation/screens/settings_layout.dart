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

/// Viewport width, in logical px, from which the Settings screen lays itself
/// out as two panes — the category list beside the selected category's
/// settings — instead of a single full-width list that pushes a route per
/// category.
///
/// This is deliberately not [narrowRailViewportBreakpoint] (600, in
/// `zen_settings.dart`). That breakpoint decides when the browser trades its
/// compact bottom bar for a side rail; a viewport that has only just cleared
/// it is still too narrow to hold a category list *and* a settings pane
/// beside each other without crowding both. 840 leaves the two-pane layout
/// for unfolded foldables, tablets and landscape phones/tablets, where each
/// pane has real room.
const settingsTwoPaneBreakpoint = 840.0;

/// Whether a viewport of [viewportWidth] gets the two-pane Settings layout.
bool useTwoPaneSettings(double viewportWidth) =>
    viewportWidth >= settingsTwoPaneBreakpoint;
