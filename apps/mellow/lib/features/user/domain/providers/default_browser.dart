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
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'default_browser.g.dart';

/// Whether this app currently holds the system's default-browser role.
///
/// Kept alive on purpose. The menu row that offers to claim the role only
/// renders while the role is *not* held, so a fresh async read on every menu
/// open would leave the row missing for the first frames of the sheet and then
/// drop it in mid-animation. Cached, only the very first open pays for the
/// platform call.
///
/// Nothing observes the role, so the answer is refreshed by whoever could have
/// changed it: the row itself after the system dialog, and the menu sheet on
/// open, which covers the user granting the role in Android's own settings.
@Riverpod(keepAlive: true)
class IsDefaultBrowser extends _$IsDefaultBrowser {
  @override
  Future<bool> build() {
    return GeckoBrowserService().isDefaultBrowser();
  }

  /// Re-reads the role, keeping the previous answer visible while it does.
  ///
  /// Deliberately a rebuild rather than an assignment from a second read: the
  /// first build may still be in flight when a refresh is asked for, and two
  /// racing reads would let the older one land last.
  void refresh() => ref.invalidateSelf();
}
