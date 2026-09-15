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
import 'package:weblibre/features/spaces_sync/data/sync15/hawk.dart';

/// Header-only Hawk reference vector, straight from the Hawk 1.x spec /
/// draft-hammer-oauth-v2-mac.
final _credentials = HawkCredentials(
  id: 'dh37fgj492je',
  key: utf8.encode('werxhqb98rpaxn39848xrunpaw3489ruxnpa98w4rxn'),
);

String _macOf(String header) {
  final match = RegExp('mac="([^"]+)"').firstMatch(header);
  return match!.group(1)!;
}

String? _hashOf(String header) {
  final match = RegExp('hash="([^"]+)"').firstMatch(header);
  return match?.group(1);
}

void main() {
  test('header-only reference vector produces the expected mac', () {
    final header = hawkAuthorizationHeader(
      credentials: _credentials,
      method: 'GET',
      uri: Uri.parse('http://example.com:8000/resource/1?b=1&a=2'),
      timestamp: 1353832234,
      nonce: 'j4h3g2',
      ext: 'some-app-ext-data',
    );

    expect(_macOf(header), '6R4rV5iE+NPoym+WwjeHzjAGXUtLNIxmo1vpMofpLAE=');
    expect(header, contains('id="dh37fgj492je"'));
    expect(header, contains('ts="1353832234"'));
    expect(header, contains('nonce="j4h3g2"'));
    expect(_hashOf(header), isNull);
  });

  test('payload reference vector produces the expected hash and mac', () {
    final body = utf8.encode('Thank you for flying Hawk');

    final hash = hawkPayloadHash(contentType: 'text/plain', payload: body);
    expect(hash, 'Yi9LfIIFRtBEPt74PVmbTF/xVAwPn7ub15ePICfgnuY=');

    final header = hawkAuthorizationHeader(
      credentials: _credentials,
      method: 'POST',
      uri: Uri.parse('http://example.com:8000/resource/1?b=1&a=2'),
      payload: body,
      contentType: 'text/plain',
      timestamp: 1353832234,
      nonce: 'j4h3g2',
      ext: 'some-app-ext-data',
    );

    expect(_hashOf(header), 'Yi9LfIIFRtBEPt74PVmbTF/xVAwPn7ub15ePICfgnuY=');
    expect(_macOf(header), 'aSe1DERmZuRl3pI36/9BdZmnErTw3sNzOOAUlfeKjVw=');
  });

  test('content-type parameters and case are normalized before hashing', () {
    final body = utf8.encode('Thank you for flying Hawk');
    final withParams = hawkPayloadHash(
      contentType: 'TEXT/PLAIN; charset=utf-8',
      payload: body,
    );
    expect(withParams, 'Yi9LfIIFRtBEPt74PVmbTF/xVAwPn7ub15ePICfgnuY=');
  });

  test('omits hash when there is no payload', () {
    final header = hawkAuthorizationHeader(
      credentials: _credentials,
      method: 'GET',
      uri: Uri.parse('https://example.com/storage/meta/global'),
    );
    expect(header, isNot(contains('hash=')));
  });

  test(
    'generates a fresh 6-character alphanumeric nonce when none is given',
    () {
      final header = hawkAuthorizationHeader(
        credentials: _credentials,
        method: 'GET',
        uri: Uri.parse('https://example.com/storage/meta/global'),
      );
      final match = RegExp('nonce="([^"]+)"').firstMatch(header)!;
      expect(match.group(1), matches(RegExp(r'^[A-Za-z0-9]{6}$')));
    },
  );
}
