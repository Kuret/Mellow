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
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/settings/presentation/screens/settings_layout.dart';

void main() {
  group('useTwoPaneSettings', () {
    test('is false below the breakpoint', () {
      expect(useTwoPaneSettings(settingsTwoPaneBreakpoint - 1), isFalse);
      expect(useTwoPaneSettings(600), isFalse);
    });

    test('is true at the breakpoint', () {
      expect(useTwoPaneSettings(settingsTwoPaneBreakpoint), isTrue);
    });

    test('is true above the breakpoint', () {
      expect(useTwoPaneSettings(settingsTwoPaneBreakpoint + 1), isTrue);
      expect(useTwoPaneSettings(1200), isTrue);
    });
  });
}
