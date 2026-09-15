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
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/spaces_sync/data/sync15/key_bundle.dart';

void main() {
  group('KeyBundle.fromSyncKey', () {
    test('splits 64 bytes into two 32-byte halves', () {
      final kSync = List<int>.generate(64, (i) => i);
      final bundle = KeyBundle.fromSyncKey(kSync);
      expect(bundle.encryptionKey, List<int>.generate(32, (i) => i));
      expect(bundle.hmacKey, List<int>.generate(32, (i) => 32 + i));
    });

    test('rejects a key that is not exactly 64 bytes', () {
      expect(
        () => KeyBundle.fromSyncKey(List<int>.filled(63, 0)),
        throwsArgumentError,
      );
      expect(
        () => KeyBundle.fromSyncKey(List<int>.filled(65, 0)),
        throwsArgumentError,
      );
    });
  });

  group('KeyBundle.fromBase64Pair', () {
    test('decodes standard base64', () {
      final enc = List<int>.generate(32, (i) => i);
      final hmac = List<int>.generate(32, (i) => 255 - i);
      final bundle = KeyBundle.fromBase64Pair(
        base64Encode(enc),
        base64Encode(hmac),
      );
      expect(bundle.encryptionKey, enc);
      expect(bundle.hmacKey, hmac);
    });
  });
}
