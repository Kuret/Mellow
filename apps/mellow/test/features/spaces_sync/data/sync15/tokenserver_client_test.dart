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
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mellow/features/spaces_sync/data/sync15/tokenserver_client.dart';

Map<String, Object?> _successBody() => {
  'id': 'hawk-id',
  'key': 'hawk-key',
  'uid': 123456,
  'api_endpoint':
      'https://sync-1-us-west1-g.sync.services.mozilla.com/1.5/123456',
  'duration': 3600,
  'hashed_fxa_uid': 'abcdef',
};

void main() {
  group('TokenServerClient.fetch', () {
    test('sends bearer token and kid, parses the token response', () async {
      http.Request? seenRequest;
      final mock = MockClient((request) async {
        seenRequest = request;
        return http.Response(jsonEncode(_successBody()), 200);
      });

      final token = await TokenServerClient(mock).fetch(
        tokenServerUrl: Uri.parse('https://token.services.mozilla.com'),
        accessToken: 'access-token',
        kid: 'the-kid',
      );

      expect(
        seenRequest!.url.toString(),
        'https://token.services.mozilla.com/1.0/sync/1.5',
      );
      expect(seenRequest!.headers['Authorization'], 'Bearer access-token');
      expect(seenRequest!.headers['X-KeyID'], 'the-kid');

      expect(token.hawkId, 'hawk-id');
      expect(token.hawkKey, 'hawk-key');
      expect(token.uid, '123456');
      expect(
        token.apiEndpoint,
        Uri.parse(
          'https://sync-1-us-west1-g.sync.services.mozilla.com/1.5/123456',
        ),
      );
      expect(token.duration, const Duration(seconds: 3600));
      expect(token.isExpired, isFalse);
    });

    test('does not double-append the path when already present', () async {
      final mock = MockClient((request) async {
        expect(request.url.toString(), 'https://custom.example/1.0/sync/1.5');
        return http.Response(jsonEncode(_successBody()), 200);
      });

      await TokenServerClient(mock).fetch(
        tokenServerUrl: Uri.parse('https://custom.example/1.0/sync/1.5'),
        accessToken: 'access-token',
        kid: 'the-kid',
      );
    });

    test('maps 401 to TokenServerAuthException', () async {
      final mock = MockClient((request) async => http.Response('nope', 401));

      await expectLater(
        TokenServerClient(mock).fetch(
          tokenServerUrl: Uri.parse('https://token.services.mozilla.com'),
          accessToken: 'bad-token',
          kid: 'kid',
        ),
        throwsA(isA<TokenServerAuthException>()),
      );
    });

    test('maps other non-2xx statuses to TokenServerException', () async {
      final mock = MockClient((request) async => http.Response('boom', 503));

      await expectLater(
        TokenServerClient(mock).fetch(
          tokenServerUrl: Uri.parse('https://token.services.mozilla.com'),
          accessToken: 'token',
          kid: 'kid',
        ),
        throwsA(isA<TokenServerException>()),
      );
    });
  });
}
