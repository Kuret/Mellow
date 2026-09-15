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

import 'package:http/http.dart' as http;

const _tokenPath = '/1.0/sync/1.5';

Uri _tokenServerRequestUri(Uri tokenServerUrl) {
  final base = tokenServerUrl.toString();
  if (base.endsWith(_tokenPath) || base.endsWith('$_tokenPath/')) {
    return tokenServerUrl;
  }
  final trimmed = base.endsWith('/')
      ? base.substring(0, base.length - 1)
      : base;
  return Uri.parse('$trimmed$_tokenPath');
}

/// The Hawk credentials and storage endpoint the Sync 1.5 tokenserver hands
/// out for one FxA `oldsync`-scoped access token (PLAN §8.3 item 1).
class SyncToken {
  SyncToken({
    required this.hawkId,
    required this.hawkKey,
    required this.uid,
    required this.apiEndpoint,
    required this.duration,
    required this.obtainedAt,
  });

  final String hawkId;
  final String hawkKey;
  final String uid;
  final Uri apiEndpoint;
  final Duration duration;
  final DateTime obtainedAt;

  bool get isExpired => DateTime.now().isAfter(obtainedAt.add(duration));
}

/// Thrown when the tokenserver rejects the access token (401).
class TokenServerAuthException implements Exception {
  TokenServerAuthException(this.body);

  final String body;

  @override
  String toString() => 'TokenServerAuthException: $body';
}

/// Thrown for any other non-2xx tokenserver response.
class TokenServerException implements Exception {
  TokenServerException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'TokenServerException($statusCode): $body';
}

/// Exchanges an FxA `oldsync`-scoped OAuth token for Sync 1.5 storage
/// credentials (PLAN §8.3 item 1, §8.2).
class TokenServerClient {
  TokenServerClient(this._httpClient);

  final http.Client _httpClient;

  Future<SyncToken> fetch({
    required Uri tokenServerUrl,
    required String accessToken,
    required String kid,
  }) async {
    final uri = _tokenServerRequestUri(tokenServerUrl);
    final response = await _httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken', 'X-KeyID': kid},
    );

    if (response.statusCode == 401) {
      throw TokenServerAuthException(response.body);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TokenServerException(response.statusCode, response.body);
    }

    final json = jsonDecode(response.body) as Map<String, Object?>;
    return SyncToken(
      hawkId: json['id']! as String,
      hawkKey: json['key']! as String,
      uid: '${json['uid']}',
      apiEndpoint: Uri.parse(json['api_endpoint']! as String),
      duration: Duration(seconds: json['duration']! as int),
      obtainedAt: DateTime.now(),
    );
  }
}
