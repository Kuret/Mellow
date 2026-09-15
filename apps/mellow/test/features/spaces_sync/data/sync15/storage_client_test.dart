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
import 'package:mellow/features/spaces_sync/data/models/zen_records.dart';
import 'package:mellow/features/spaces_sync/data/sync15/key_bundle.dart';
import 'package:mellow/features/spaces_sync/data/sync15/record_crypto.dart';
import 'package:mellow/features/spaces_sync/data/sync15/storage_client.dart';
import 'package:mellow/features/spaces_sync/data/sync15/tokenserver_client.dart';

SyncToken _token() => SyncToken(
  hawkId: 'hawk-id',
  hawkKey: 'hawk-key',
  uid: '123456',
  apiEndpoint: Uri.parse(
    'https://sync-1-us-west1-g.sync.services.mozilla.com/1.5/123456',
  ),
  duration: const Duration(hours: 1),
  obtainedAt: DateTime.now(),
);

void main() {
  group('getMetaGlobal', () {
    test('parses the meta/global BSO payload string', () async {
      final metaGlobalPayload = jsonEncode({
        'syncID': 'sync-id-1',
        'storageVersion': 5,
        'engines': {
          'spaces': {'version': 3, 'syncID': 'spaces-sync-id'},
        },
        'declined': <String>[],
      });
      final mock = MockClient((request) async {
        expect(request.url.path, endsWith('/storage/meta/global'));
        return http.Response(
          jsonEncode({
            'id': 'global',
            'modified': 1000.0,
            'payload': metaGlobalPayload,
          }),
          200,
        );
      });

      final client = SyncStorageClient(mock, _token());
      final metaGlobal = await client.getMetaGlobal();

      expect(metaGlobal!.syncId, 'sync-id-1');
      expect(metaGlobal.storageVersion, 5);
      expect(metaGlobal.spacesEngine!.version, 3);
      expect(metaGlobal.spacesEngine!.syncId, 'spaces-sync-id');
    });

    test('returns null on 404', () async {
      final mock = MockClient((request) async => http.Response('', 404));
      final client = SyncStorageClient(mock, _token());
      expect(await client.getMetaGlobal(), isNull);
    });
  });

  group('getCryptoKeys', () {
    test('decrypts with the sync-key bundle and exposes bundleFor', () async {
      final syncKeyBundle = KeyBundle(
        encryptionKey: List<int>.generate(32, (i) => i),
        hmacKey: List<int>.generate(32, (i) => 32 + i),
      );
      final defaultBundle = KeyBundle(
        encryptionKey: List<int>.generate(32, (i) => 100 + i),
        hmacKey: List<int>.generate(32, (i) => 132 + i),
      );
      final cleartext = {
        'default': [
          base64Encode(defaultBundle.encryptionKey),
          base64Encode(defaultBundle.hmacKey),
        ],
        'collections': <String, Object?>{},
      };
      final encrypted = await encryptPayload(cleartext, syncKeyBundle);

      final mock = MockClient((request) async {
        expect(request.url.path, endsWith('/storage/crypto/keys'));
        return http.Response(
          jsonEncode({
            'id': 'keys',
            'modified': 1000.0,
            'payload': jsonEncode(encrypted.toJson()),
          }),
          200,
        );
      });

      final client = SyncStorageClient(mock, _token());
      final keys = await client.getCryptoKeys(syncKeyBundle);

      expect(keys.defaultBundle.encryptionKey, defaultBundle.encryptionKey);
      expect(
        keys.bundleFor('spaces').encryptionKey,
        defaultBundle.encryptionKey,
      );
    });
  });

  group('fetchCollection pagination', () {
    test('follows X-Weave-Next-Offset until exhausted', () async {
      var call = 0;
      final mock = MockClient((request) async {
        call++;
        if (call == 1) {
          expect(request.url.queryParameters['offset'], isNull);
          return http.Response(
            jsonEncode([
              {'id': 'a', 'modified': 1.0, 'payload': 'a-payload'},
            ]),
            200,
            headers: {
              'x-weave-next-offset': 'page-2',
              'x-last-modified': '1000.50',
            },
          );
        }
        expect(request.url.queryParameters['offset'], 'page-2');
        return http.Response(
          jsonEncode([
            {'id': 'b', 'modified': 2.0, 'payload': 'b-payload'},
          ]),
          200,
          headers: {'x-last-modified': '1000.75'},
        );
      });

      final client = SyncStorageClient(mock, _token());
      final result = await client.fetchCollection('spaces');

      expect(call, 2);
      expect(result.records.map((r) => r.id), ['a', 'b']);
      expect(result.lastModified, 1000.75);
    });
  });

  group('postRecords', () {
    test('throws PreconditionFailed on 412', () async {
      final mock = MockClient((request) async => http.Response('', 412));
      final client = SyncStorageClient(mock, _token());

      await expectLater(
        client.postRecords('spaces', [
          Bso(id: 'a', payload: 'p'),
        ], ifUnmodifiedSince: 1000),
        throwsA(isA<PreconditionFailed>()),
      );
    });

    test('chunks 250 records into 3 POSTs of at most 100', () async {
      final requestSizes = <int>[];
      final mock = MockClient((request) async {
        final body = jsonDecode(request.body) as List<Object?>;
        requestSizes.add(body.length);
        return http.Response(
          jsonEncode({
            'success': body.map((e) => (e! as Map)['id']).toList(),
            'failed': <String, Object?>{},
            'modified': 2000.0,
          }),
          200,
        );
      });

      final records = List.generate(
        250,
        (i) => Bso(id: 'tab-$i', payload: 'payload-$i'),
      );
      final client = SyncStorageClient(mock, _token());
      final result = await client.postRecords(
        'spaces',
        records,
        ifUnmodifiedSince: 1000,
      );

      expect(requestSizes, [100, 100, 50]);
      expect(result.success, hasLength(250));
      expect(result.modified, 2000.0);
    });

    test('sends X-If-Unmodified-Since on each chunk', () async {
      final mock = MockClient((request) async {
        expect(request.headers['x-if-unmodified-since'], '1234.50');
        return http.Response(
          jsonEncode({'success': <String>[], 'failed': <String, Object?>{}}),
          200,
        );
      });

      final client = SyncStorageClient(mock, _token());
      await client.postRecords('spaces', [
        Bso(id: 'a', payload: 'p'),
      ], ifUnmodifiedSince: 1234.5);
    });
  });

  group('backoff', () {
    test('503 with Retry-After surfaces BackoffException', () async {
      final mock = MockClient(
        (request) async =>
            http.Response('', 503, headers: {'retry-after': '30'}),
      );
      final client = SyncStorageClient(mock, _token());

      await expectLater(
        client.getCollectionInfo(),
        throwsA(
          isA<BackoffException>().having((e) => e.seconds, 'seconds', 30),
        ),
      );
    });
  });

  group('401', () {
    test('surfaces SyncAuthException', () async {
      final mock = MockClient((request) async => http.Response('', 401));
      final client = SyncStorageClient(mock, _token());
      await expectLater(
        client.getCollectionInfo(),
        throwsA(isA<SyncAuthException>()),
      );
    });
  });

  group('decryptBso / encryptCleartext', () {
    test('round-trip a tombstone through encrypted BSO payload', () async {
      final keys = KeyBundle(
        encryptionKey: List<int>.generate(32, (i) => i),
        hmacKey: List<int>.generate(32, (i) => 32 + i),
      );
      final client = SyncStorageClient(
        MockClient((_) async => http.Response('', 500)),
        _token(),
      );

      final tombstone = ZenTombstone(id: 'tab-1').toJson();
      final payloadString = await client.encryptCleartext(tombstone, keys);
      final bso = Bso(id: 'tab-1', payload: payloadString);

      final incoming = await client.decryptBso(bso, keys);
      expect(incoming, isA<ZenIncomingTombstone>());
      expect((incoming as ZenIncomingTombstone).id, 'tab-1');
    });

    test('round-trip a live record through encrypted BSO payload', () async {
      final keys = KeyBundle(
        encryptionKey: List<int>.generate(32, (i) => i),
        hmacKey: List<int>.generate(32, (i) => 32 + i),
      );
      final client = SyncStorageClient(
        MockClient((_) async => http.Response('', 500)),
        _token(),
      );

      final cleartext = {
        'id': 'guid-1',
        'kind': 'container',
        'data': {
          'guid': 'guid-1',
          'name': 'Work',
          'icon': 'briefcase',
          'color': 'blue',
        },
      };
      final payloadString = await client.encryptCleartext(cleartext, keys);
      final bso = Bso(id: 'guid-1', payload: payloadString);

      final incoming = await client.decryptBso(bso, keys);
      expect(incoming, isA<ZenIncomingRecord>());
      final record = incoming as ZenIncomingRecord;
      expect(record.cleartext.id, 'guid-1');
      expect(record.cleartext.data, isA<ZenContainerRecord>());
    });
  });
}
