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

import 'package:crypto/crypto.dart' as pkg_crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/spaces_sync/data/sync15/key_bundle.dart';
import 'package:weblibre/features/spaces_sync/data/sync15/record_crypto.dart';

void main() {
  final keys = KeyBundle(
    encryptionKey: List<int>.generate(32, (i) => i),
    hmacKey: List<int>.generate(32, (i) => 32 + i),
  );

  group('round-trip', () {
    test(
      'encryptPayload then decryptPayload returns the original JSON',
      () async {
        final original = {
          'id': 'space-1',
          'kind': 'space',
          'data': {
            'uuid': '{11111111-1111-4111-8111-111111111111}',
            'name': 'Personal',
          },
        };

        final payload = await encryptPayload(original, keys);
        final decrypted = await decryptPayload(payload, keys);

        expect(decrypted, original);
      },
    );
  });

  group('tamper detection', () {
    test(
      'decryptPayload throws HmacMismatch when the ciphertext is altered',
      () async {
        final payload = await encryptPayload({'a': 1}, keys);
        final tamperedBytes = base64Decode(payload.ciphertext);
        tamperedBytes[0] ^= 0xff;
        final tampered = EncryptedPayload(
          ciphertext: base64Encode(tamperedBytes),
          iv: payload.iv,
          hmac: payload.hmac,
        );

        expect(
          () => decryptPayload(tampered, keys),
          throwsA(isA<HmacMismatch>()),
        );
      },
    );

    test(
      'decryptPayload throws HmacMismatch when the hmac itself is wrong',
      () async {
        final payload = await encryptPayload({'a': 1}, keys);
        final tampered = EncryptedPayload(
          ciphertext: payload.ciphertext,
          iv: payload.iv,
          hmac: '0' * payload.hmac.length,
        );

        expect(
          () => decryptPayload(tampered, keys),
          throwsA(isA<HmacMismatch>()),
        );
      },
    );
  });

  group('known-answer', () {
    test('hmac is computed over the base64 TEXT of the ciphertext', () async {
      final iv = List<int>.generate(16, (i) => i);
      final payload = await encryptPayload({'a': 1}, keys, iv: iv);

      final expectedHmac = pkg_crypto.Hmac(
        pkg_crypto.sha256,
        keys.hmacKey,
      ).convert(utf8.encode(payload.ciphertext)).toString();

      expect(payload.hmac, expectedHmac);
      expect(payload.iv, base64Encode(iv));
    });

    test(
      'a fixed IV reproduces the same ciphertext for the same input',
      () async {
        final iv = List<int>.generate(16, (i) => 15 - i);
        final payload1 = await encryptPayload({'a': 1}, keys, iv: iv);
        final payload2 = await encryptPayload({'a': 1}, keys, iv: iv);

        expect(payload1.ciphertext, payload2.ciphertext);
        expect(payload1.hmac, payload2.hmac);
      },
    );
  });

  group('EncryptedPayload JSON', () {
    test('round-trips through {"ciphertext","IV","hmac"}', () {
      const payload = EncryptedPayload(
        ciphertext: 'Y2lwaGVy',
        iv: 'aXY=',
        hmac: 'deadbeef',
      );
      final json = payload.toJson();
      expect(json, {
        'ciphertext': 'Y2lwaGVy',
        'IV': 'aXY=',
        'hmac': 'deadbeef',
      });
      final decoded = EncryptedPayload.fromJson(json);
      expect(decoded.ciphertext, payload.ciphertext);
      expect(decoded.iv, payload.iv);
      expect(decoded.hmac, payload.hmac);
    });
  });
}
