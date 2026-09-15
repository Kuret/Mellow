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
import 'package:flutter/material.dart';
import 'package:mellow/features/geckoview/features/search/domain/providers/search_section_display.dart';

/// Marks which [SearchSectionHost] the sections below it belong to, and how
/// their headers are painted.
///
/// A section can appear on both hosts at once, so it cannot name its own host —
/// the host does, once, above its scroll view.
class SearchSectionScope extends InheritedWidget {
  final SearchSectionHost host;

  /// Painted behind the section headers, which pin to the top of the viewport
  /// when this is set. Null leaves them unpinned and unpainted.
  ///
  /// The two are one setting because they are one decision: a pinned header
  /// has content scrolling underneath it and therefore *must* be opaque, while
  /// an unpinned header never covers anything and so needs no backdrop at all.
  ///
  /// The search screen pins: its result lists are long, and the header tells
  /// you which section you are looking at. The browser home does not pin. Its
  /// sections are short, and on the `BrowserPage` aura gradient an opaque band
  /// per header stacks into a set of slabs cutting across the backdrop.
  final Color? pinnedHeaderBackgroundColor;

  const SearchSectionScope({
    super.key,
    required this.host,
    required this.pinnedHeaderBackgroundColor,
    required super.child,
  });

  static SearchSectionScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SearchSectionScope>();
    assert(
      scope != null,
      'No SearchSectionScope found. Wrap the host scroll view in one.',
    );
    return scope!;
  }

  /// The host sections below [context] belong to.
  static SearchSectionHost hostOf(BuildContext context) => of(context).host;

  @override
  bool updateShouldNotify(SearchSectionScope oldWidget) =>
      host != oldWidget.host ||
      pinnedHeaderBackgroundColor != oldWidget.pinnedHeaderBackgroundColor;
}
