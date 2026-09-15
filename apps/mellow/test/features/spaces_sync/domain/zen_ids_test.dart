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
import 'package:mellow/features/spaces_sync/domain/zen_ids.dart';

void main() {
  group('ZenIds.newTabId', () {
    test('matches Date.now()-random(0..100) shape', () {
      final id = ZenIds.newTabId();
      final parts = id.split('-');
      expect(parts, hasLength(2));
      final millis = int.parse(parts[0]);
      final rand = int.parse(parts[1]);
      expect(millis, greaterThan(0));
      expect(rand, inInclusiveRange(0, 100));
    });

    test('newGroupId has the same shape', () {
      final id = ZenIds.newGroupId();
      expect(RegExp(r'^\d+-\d+$').hasMatch(id), isTrue);
    });
  });

  group('ZenIds.newSpaceUuid', () {
    test('wraps a v4 uuid in braces', () {
      final id = ZenIds.newSpaceUuid();
      expect(
        RegExp(
          r'^\{[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\}$',
        ).hasMatch(id),
        isTrue,
        reason: id,
      );
    });
  });

  group('ZenIds.newContainerGuid', () {
    test('is a bare v4 uuid, no braces', () {
      final id = ZenIds.newContainerGuid();
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
        reason: id,
      );
    });
  });

  group('ZenIds.isBuiltinContainerGuid', () {
    test('accepts builtin-1..4', () {
      for (final n in [1, 2, 3, 4]) {
        expect(ZenIds.isBuiltinContainerGuid('builtin-$n'), isTrue);
      }
    });

    test('rejects everything else', () {
      expect(ZenIds.isBuiltinContainerGuid('builtin-0'), isFalse);
      expect(ZenIds.isBuiltinContainerGuid('builtin-5'), isFalse);
      expect(ZenIds.isBuiltinContainerGuid('builtin-'), isFalse);
      expect(ZenIds.isBuiltinContainerGuid(ZenIds.newContainerGuid()), isFalse);
    });
  });
}
