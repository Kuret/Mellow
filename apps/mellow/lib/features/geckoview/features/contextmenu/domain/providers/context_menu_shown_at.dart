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

part 'context_menu_shown_at.g.dart';

/// When the hit-result context menu (over a link, image or media source)
/// last opened.
///
/// A right click always reaches the native router, whether or not it lands on
/// something Gecko can hit-test, and the router reports it to Flutter either
/// way. The page context menu — raised for the case it doesn't — reads this
/// to tell "a hit-result menu just opened for this same click" from "nothing
/// did", rather than the two menus coordinating directly.
@Riverpod(keepAlive: true)
class ContextMenuShownAt extends _$ContextMenuShownAt {
  @override
  DateTime? build() => null;

  void markShown() => state = DateTime.now();
}
