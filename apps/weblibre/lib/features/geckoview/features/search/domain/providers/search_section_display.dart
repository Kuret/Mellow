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
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_section_display.g.dart';

/// Which surface a section is being drawn on.
///
/// The same section can be on screen twice at once — the browser home stays
/// mounted underneath the pushed search screen, and both show recent searches —
/// so collapsing it in one place must not collapse it in the other. The host is
/// supplied from above, via `SearchSectionScope`, because a section cannot know
/// which of the two it is in.
enum SearchSectionHost {
  /// The browser home, shown when there is no tab to display.
  home,

  /// The address-bar search screen, whether full screen or as a panel.
  panel,
}

/// The fixed set of sections the search surfaces render.
///
/// Deliberately closed and unordered-by-the-user: the panel shows suggestions
/// then history while typing, recent searches when the query is empty, and
/// nothing else. This enum exists only to key per-section view state.
enum SearchSection { recentSearches, suggestions, history }

/// How much of a section is on screen.
enum SearchSectionDisplayState { preview, expanded, collapsed }

/// Per-section collapse and show-all state, keyed by host as well as section.
@Riverpod()
class SearchSectionDisplayStateController
    extends _$SearchSectionDisplayStateController {
  void cycle() {
    state = switch (state) {
      SearchSectionDisplayState.preview => SearchSectionDisplayState.expanded,
      SearchSectionDisplayState.expanded => SearchSectionDisplayState.collapsed,
      SearchSectionDisplayState.collapsed => SearchSectionDisplayState.preview,
    };
  }

  void toggleCollapse() {
    state = switch (state) {
      SearchSectionDisplayState.collapsed => SearchSectionDisplayState.preview,
      _ => SearchSectionDisplayState.collapsed,
    };
  }

  void toggleExpansion() {
    state = switch (state) {
      SearchSectionDisplayState.preview => SearchSectionDisplayState.expanded,
      SearchSectionDisplayState.expanded => SearchSectionDisplayState.preview,
      _ => state,
    };
  }

  @override
  SearchSectionDisplayState build(
    SearchSectionHost host,
    SearchSection section,
  ) {
    return SearchSectionDisplayState.preview;
  }
}
