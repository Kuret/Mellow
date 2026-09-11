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
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hawk MAC credentials, as returned by the Sync tokenserver (PLAN §8.3):
/// a request-scoped `id` and shared `key`, used to sign every storage
/// request.
class HawkCredentials {
  const HawkCredentials({
    required this.id,
    required this.key,
    this.algorithm = 'sha256',
  });

  final String id;
  final List<int> key;

  /// Always `sha256` for Sync 1.5 (the only algorithm the tokenserver
  /// issues), kept explicit because it selects the HMAC/hash used below.
  final String algorithm;
}

const _nonceAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

String _randomNonce([Random? random]) {
  final rng = random ?? Random.secure();
  return List.generate(
    6,
    (_) => _nonceAlphabet[rng.nextInt(_nonceAlphabet.length)],
  ).join();
}

int _defaultPortFor(Uri uri) {
  if (uri.hasPort) {
    return uri.port;
  }
  return uri.scheme == 'https' ? 443 : 80;
}

String _requestUri(Uri uri) {
  final path = uri.path.isEmpty ? '/' : uri.path;
  return uri.query.isEmpty ? path : '$path?${uri.query}';
}

/// Base64 SHA-256 of `"hawk.1.payload\n{content-type}\n{body}\n"`, where the
/// content type is stripped of any `;`-separated parameters and lowercased —
/// matches `HAWKAuthenticatedRESTRequest`'s payload hash.
String hawkPayloadHash({
  required String contentType,
  required List<int> payload,
}) {
  final normalizedContentType = contentType
      .split(';')
      .first
      .trim()
      .toLowerCase();
  final builder = BytesBuilder()
    ..add(utf8.encode('hawk.1.payload\n'))
    ..add(utf8.encode('$normalizedContentType\n'))
    ..add(payload)
    ..add(utf8.encode('\n'));
  return base64Encode(sha256.convert(builder.toBytes()).bytes);
}

/// Builds a `Hawk` `Authorization` header value for one request.
///
/// [ext] defaults to empty, matching Firefox's Sync storage requests (which
/// never set an `ext` string); it exists as a parameter so the Hawk
/// reference test vectors — which do set `ext` — can be exercised directly.
String hawkAuthorizationHeader({
  required HawkCredentials credentials,
  required String method,
  required Uri uri,
  List<int>? payload,
  String? contentType,
  int? timestamp,
  String? nonce,
  String ext = '',
}) {
  final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final resolvedNonce = nonce ?? _randomNonce();
  final port = _defaultPortFor(uri);
  final hash = payload == null
      ? null
      : hawkPayloadHash(contentType: contentType ?? '', payload: payload);

  final normalized =
      'hawk.1.header\n'
      '$ts\n'
      '$resolvedNonce\n'
      '${method.toUpperCase()}\n'
      '${_requestUri(uri)}\n'
      '${uri.host}\n'
      '$port\n'
      '${hash ?? ''}\n'
      '$ext\n';

  final mac = base64Encode(
    Hmac(sha256, credentials.key).convert(utf8.encode(normalized)).bytes,
  );

  final parts = <String>[
    'id="${credentials.id}"',
    'ts="$ts"',
    'nonce="$resolvedNonce"',
    if (hash != null) 'hash="$hash"',
    'mac="$mac"',
  ];
  return 'Hawk ${parts.join(', ')}';
}
