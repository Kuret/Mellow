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

/// A 32-byte AES key and a 32-byte HMAC key, the pair every Sync 1.5
/// collection (and the special `crypto/keys` record itself) is encrypted
/// with (PLAN §8.3 item 3).
class KeyBundle {
  const KeyBundle({required this.encryptionKey, required this.hmacKey});

  /// Splits the 64-byte scoped `oldsync` key (`k` in the FxA
  /// `OAuthScopedKey`) into its two 32-byte halves: the first 32 bytes are
  /// the AES encryption key, the last 32 the HMAC key.
  factory KeyBundle.fromSyncKey(List<int> kSync) {
    if (kSync.length != 64) {
      throw ArgumentError.value(
        kSync.length,
        'kSync.length',
        'the sync key must be exactly 64 bytes',
      );
    }
    return KeyBundle(
      encryptionKey: kSync.sublist(0, 32),
      hmacKey: kSync.sublist(32, 64),
    );
  }

  /// Builds a bundle from the standard-base64-encoded pair the
  /// `crypto/keys` BSO stores each collection's key bundle as.
  factory KeyBundle.fromBase64Pair(
    String encryptionKeyB64,
    String hmacKeyB64,
  ) => KeyBundle(
    encryptionKey: base64Decode(encryptionKeyB64),
    hmacKey: base64Decode(hmacKeyB64),
  );

  /// 32-byte AES-256-CBC key.
  final List<int> encryptionKey;

  /// 32-byte HMAC-SHA256 key.
  final List<int> hmacKey;
}
