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

import 'package:mellow/core/routing/tab_type.dart';

/// Persisted tab privacy mode.
///
/// Values map to integer values stored in the `tab_mode` column:
/// - 0 = regular
/// - 1 = private
enum TabModeDbValue { regular, private }

sealed class TabMode {
  static const TabMode regular = RegularTabMode();
  static const TabMode private = PrivateTabMode();

  const TabMode();

  factory TabMode.fromTabType(TabType tabType) => switch (tabType) {
    TabType.private => TabMode.private,
    _ => TabMode.regular,
  };

  TabModeDbValue toDbValue() => switch (this) {
    RegularTabMode() => TabModeDbValue.regular,
    PrivateTabMode() => TabModeDbValue.private,
  };

  TabType toTabType() => switch (this) {
    RegularTabMode() => TabType.regular,
    PrivateTabMode() => TabType.private,
  };

  factory TabMode.fromDbValue(TabModeDbValue dbValue) {
    return switch (dbValue) {
      TabModeDbValue.regular => regular,
      TabModeDbValue.private => private,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TabMode && other.toDbValue() == toDbValue();
  }

  @override
  int get hashCode => toDbValue().hashCode;
}

final class RegularTabMode extends TabMode {
  const RegularTabMode();
}

final class PrivateTabMode extends TabMode {
  const PrivateTabMode();
}
