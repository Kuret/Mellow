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
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/share_intent/domain/entities/share_intent_space_mode.dart';
import 'package:weblibre/features/share_intent/domain/services/share_intent_space.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

import '../../geckoview/features/tabs/data/database/tab_db_test_helpers.dart';

void main() {
  group('resolveShareIntentSpaceUuid', () {
    test('ask returns null: the picker asks instead of guessing', () async {
      final db = openTestTabDatabase();
      final container = ProviderContainer(
        overrides: [
          tabDatabaseProvider.overrideWithValue(db),
          zenSettingsWithDefaultsProvider.overrideWithValue(
            ZenSettings.withDefaults().copyWith(
              shareIntentSpaceMode: ShareIntentSpaceMode.ask,
              shareIntentSpaceUuid: 'space-a',
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      await seedSpaces(db, ['space-a']);

      final result = await container.read(
        resolveShareIntentSpaceUuidProvider.future,
      );

      expect(result, isNull);
    });

    test('fixed with a live space returns its uuid', () async {
      final db = openTestTabDatabase();
      final container = ProviderContainer(
        overrides: [
          tabDatabaseProvider.overrideWithValue(db),
          zenSettingsWithDefaultsProvider.overrideWithValue(
            ZenSettings.withDefaults().copyWith(
              shareIntentSpaceMode: ShareIntentSpaceMode.fixed,
              shareIntentSpaceUuid: 'space-a',
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      await seedSpaces(db, ['space-a']);

      final result = await container.read(
        resolveShareIntentSpaceUuidProvider.future,
      );

      expect(result, 'space-a');
    });

    test(
      'fixed with a deleted space returns null: the setting is advisory',
      () async {
        final db = openTestTabDatabase();
        final container = ProviderContainer(
          overrides: [
            tabDatabaseProvider.overrideWithValue(db),
            zenSettingsWithDefaultsProvider.overrideWithValue(
              ZenSettings.withDefaults().copyWith(
                shareIntentSpaceMode: ShareIntentSpaceMode.fixed,
                shareIntentSpaceUuid: 'space-gone',
              ),
            ),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await db.close();
        });
        // Deliberately not seeded: 'space-gone' names no row.

        final result = await container.read(
          resolveShareIntentSpaceUuidProvider.future,
        );

        expect(result, isNull);
      },
    );
  });
}
