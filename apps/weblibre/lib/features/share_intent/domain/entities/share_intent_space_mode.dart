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
import 'package:json_annotation/json_annotation.dart';

/// Which space a link shared from another app opens in.
///
/// The question a share used to ask was which *container* to open in, which is
/// the wrong unit for this fork: a container is a cookie jar, and the thing a
/// user is actually sorting a link into is a space. A tab still belongs to a
/// container underneath — the chosen space supplies its default — but the space
/// is what the share sheet asks about and what syncs to the desktop.
///
/// Deliberately shaped like `IntentContainerMode`, the setting it replaces: a
/// small enum with pinned wire values, so a stored choice survives a rename of
/// the Dart identifier.
enum ShareIntentSpaceMode {
  /// Show the space picker on the share sheet, starting on whichever space is
  /// currently selected. The default, because a share arrives out of context —
  /// the app may not even have been open — and guessing wrong files the link
  /// somewhere the user will not look for it.
  @JsonValue('ask')
  ask,

  /// Always open shared links in the space named by
  /// `ZenSettings.shareIntentSpaceUuid`, without asking. For people who keep a
  /// dedicated "Read later" or "Inbox" space.
  @JsonValue('fixed')
  fixed,
}
