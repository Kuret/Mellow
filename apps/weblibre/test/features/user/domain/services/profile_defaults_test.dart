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
import 'package:weblibre/features/user/data/models/ublock_filter_list_settings.dart';
import 'package:weblibre/features/user/domain/services/profile_defaults.dart';

void main() {
  group('isPristineUBlockFilterListSettings', () {
    test('is true for the model default', () {
      expect(
        isPristineUBlockFilterListSettings(UBlockFilterListSettings()),
        isTrue,
      );
    });

    test('is false once enabled', () {
      expect(
        isPristineUBlockFilterListSettings(
          UBlockFilterListSettings(enabled: true),
        ),
        isFalse,
      );
    });

    test('is false once a stock list is manually enabled', () {
      expect(
        isPristineUBlockFilterListSettings(
          UBlockFilterListSettings(enabledStockListTokens: const ['easylist']),
        ),
        isFalse,
      );
    });

    test('is false once a stock list is auto-enabled', () {
      expect(
        isPristineUBlockFilterListSettings(
          UBlockFilterListSettings(
            autoEnabledStockListTokens: const ['easylist'],
          ),
        ),
        isFalse,
      );
    });

    test('is false once an external filter list is added', () {
      expect(
        isPristineUBlockFilterListSettings(
          UBlockFilterListSettings(
            externalFilterLists: [
              UBlockExternalList(url: 'https://example.com/list.txt'),
            ],
          ),
        ),
        isFalse,
      );
    });
  });
}
