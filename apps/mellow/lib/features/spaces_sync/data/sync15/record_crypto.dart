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
import 'dart:math';

import 'package:crypto/crypto.dart' as pkg_crypto;
import 'package:cryptography/cryptography.dart';
import 'package:mellow/features/spaces_sync/data/sync15/key_bundle.dart';

/// A Sync 1.5 encrypted BSO payload: `{"ciphertext","IV","hmac"}`. `ciphertext`
/// and `iv` are standard base64; `hmac` is lowercase hex.
class EncryptedPayload {
  const EncryptedPayload({
    required this.ciphertext,
    required this.iv,
    required this.hmac,
  });

  factory EncryptedPayload.fromJson(Map<String, Object?> json) =>
      EncryptedPayload(
        ciphertext: json['ciphertext']! as String,
        iv: json['IV']! as String,
        hmac: json['hmac']! as String,
      );

  final String ciphertext;
  final String iv;
  final String hmac;

  Map<String, Object?> toJson() => {
    'ciphertext': ciphertext,
    'IV': iv,
    'hmac': hmac,
  };
}

/// Thrown by [decryptPayload] when the stored `hmac` does not match the
/// ciphertext — either corruption or a payload encrypted with the wrong key
/// bundle. Never decrypt past this: it is the only integrity check Sync 1.5
/// payloads get.
class HmacMismatch implements Exception {
  HmacMismatch([this.message = 'Sync record HMAC does not match']);

  final String message;

  @override
  String toString() => 'HmacMismatch: $message';
}

final _cipher = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) {
    return false;
  }
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return difference == 0;
}

/// The HMAC is computed over the base64 *text* of the ciphertext (not the
/// decoded bytes) — this is how Firefox's `crypto/keys` and collection
/// records are both signed.
String _payloadHmacHex(String ciphertextBase64, KeyBundle keys) {
  final digest = pkg_crypto.Hmac(
    pkg_crypto.sha256,
    keys.hmacKey,
  ).convert(utf8.encode(ciphertextBase64));
  return digest.toString();
}

/// Verifies and decrypts one Sync 1.5 [EncryptedPayload], returning the
/// decoded cleartext JSON value. Throws [HmacMismatch] if the HMAC does not
/// verify.
Future<Object?> decryptPayload(EncryptedPayload payload, KeyBundle keys) async {
  final expectedHmac = _payloadHmacHex(payload.ciphertext, keys);
  if (!_constantTimeEquals(expectedHmac, payload.hmac.toLowerCase())) {
    throw HmacMismatch();
  }

  final secretBox = SecretBox(
    base64Decode(payload.ciphertext),
    nonce: base64Decode(payload.iv),
    mac: Mac.empty,
  );
  final clearBytes = await _cipher.decrypt(
    secretBox,
    secretKey: SecretKey(keys.encryptionKey),
  );
  return jsonDecode(utf8.decode(clearBytes));
}

/// Encrypts [json] (any `jsonEncode`-able value) into a fresh
/// [EncryptedPayload] under [keys]. A random 16-byte IV is used unless [iv]
/// is given (tests only — production callers must never reuse an IV).
Future<EncryptedPayload> encryptPayload(
  Object? json,
  KeyBundle keys, {
  List<int>? iv,
}) async {
  final ivBytes = iv ?? _randomIv();
  final clearBytes = utf8.encode(jsonEncode(json));
  final secretBox = await _cipher.encrypt(
    clearBytes,
    secretKey: SecretKey(keys.encryptionKey),
    nonce: ivBytes,
  );
  final ciphertextBase64 = base64Encode(secretBox.cipherText);
  return EncryptedPayload(
    ciphertext: ciphertextBase64,
    iv: base64Encode(ivBytes),
    hmac: _payloadHmacHex(ciphertextBase64, keys),
  );
}

final _secureRandom = Random.secure();

List<int> _randomIv() =>
    List.generate(16, (_) => _secureRandom.nextInt(256), growable: false);
