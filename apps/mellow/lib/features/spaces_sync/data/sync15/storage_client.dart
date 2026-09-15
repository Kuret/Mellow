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
import 'package:mellow/features/spaces_sync/data/models/zen_records.dart';
import 'package:mellow/features/spaces_sync/data/sync15/hawk.dart';
import 'package:mellow/features/spaces_sync/data/sync15/key_bundle.dart';
import 'package:mellow/features/spaces_sync/data/sync15/record_crypto.dart';
import 'package:mellow/features/spaces_sync/data/sync15/tokenserver_client.dart';

const _maxUploadBatchCount = 100;
const _maxUploadBatchBytes = 1024 * 1024;

/// One Basic Storage Object, as stored/returned by a Sync 1.5 storage server.
/// `payload` is opaque to this layer: a plain JSON string for `meta/global`,
/// or the JSON encoding of an [EncryptedPayload] for `crypto/keys` and every
/// `spaces` record.
class Bso {
  Bso({
    required this.id,
    required this.payload,
    this.modified,
    this.sortindex,
    this.ttl,
  });

  factory Bso.fromJson(Map<String, Object?> json) => Bso(
    id: json['id']! as String,
    payload: json['payload']! as String,
    modified: (json['modified'] as num?)?.toDouble(),
    sortindex: json['sortindex'] as int?,
    ttl: json['ttl'] as int?,
  );

  final String id;
  final String payload;
  final double? modified;
  final int? sortindex;
  final int? ttl;

  /// The subset of fields a client is allowed to upload (`modified` is
  /// server-assigned).
  Map<String, Object?> toUploadJson() => {
    'id': id,
    'payload': payload,
    if (sortindex != null) 'sortindex': sortindex,
    if (ttl != null) 'ttl': ttl,
  };
}

/// One collection's declared version and syncID from `meta/global`'s
/// `engines` map.
class MetaGlobalEngine {
  MetaGlobalEngine({required this.version, required this.syncId});

  factory MetaGlobalEngine.fromJson(Map<String, Object?> json) =>
      MetaGlobalEngine(
        version: json['version']! as int,
        syncId: json['syncID']! as String,
      );

  final int version;
  final String syncId;
}

/// The decoded `meta/global` record (PLAN §8.3 item 4): its `payload` is a
/// JSON **string** of unencrypted engine metadata, not an [EncryptedPayload].
class MetaGlobal {
  MetaGlobal({
    required this.syncId,
    required this.storageVersion,
    required this.engines,
    required this.declined,
  });

  factory MetaGlobal.fromJson(Map<String, Object?> json) {
    final enginesJson =
        (json['engines'] as Map?)?.cast<String, Object?>() ?? const {};
    return MetaGlobal(
      syncId: json['syncID']! as String,
      storageVersion: json['storageVersion']! as int,
      engines: {
        for (final entry in enginesJson.entries)
          entry.key: MetaGlobalEngine.fromJson(
            (entry.value! as Map).cast<String, Object?>(),
          ),
      },
      declined: json['declined'],
    );
  }

  final String syncId;
  final int storageVersion;
  final Map<String, MetaGlobalEngine> engines;
  final Object? declined;

  /// This client only ever cares about the `spaces` engine's declared
  /// version/syncID (the version gate, PLAN §8.6 item 3).
  MetaGlobalEngine? get spacesEngine => engines['spaces'];
}

/// The decrypted `crypto/keys` record: a default AES/HMAC key bundle plus
/// optional per-collection overrides.
class CryptoKeys {
  CryptoKeys({required this.defaultBundle, required this.collections});

  final KeyBundle defaultBundle;
  final Map<String, KeyBundle> collections;

  /// The key bundle to use for [collection], falling back to [defaultBundle]
  /// when the collection has no override — matches Firefox's own fallback.
  KeyBundle bundleFor(String collection) =>
      collections[collection] ?? defaultBundle;
}

/// One page-follow result of [SyncStorageClient.fetchCollection].
class FetchResult {
  FetchResult({required this.records, required this.lastModified});

  final List<Bso> records;

  /// The collection's `X-Last-Modified` timestamp (seconds), if the server
  /// sent one.
  final double? lastModified;
}

/// The parsed response of [SyncStorageClient.postRecords].
class PostResult {
  PostResult({required this.success, required this.failed, this.modified});

  final List<String> success;
  final Map<String, String> failed;
  final double? modified;
}

/// Thrown when a write is rejected because the collection changed since the
/// caller's `X-If-Unmodified-Since` timestamp (412). Callers must refetch
/// and reapply, never force the write (PLAN §8.3 item 6).
class PreconditionFailed implements Exception {
  @override
  String toString() => 'PreconditionFailed';
}

/// Thrown on 401: the Hawk token has expired and the caller must re-fetch
/// one from the tokenserver.
class SyncAuthException implements Exception {
  SyncAuthException(this.body);

  final String body;

  @override
  String toString() => 'SyncAuthException: $body';
}

/// Thrown for 503/429 responses, surfacing however many seconds the server
/// asked the client to back off for (`Retry-After` / `X-Backoff` /
/// `X-Weave-Backoff`, in that preference order).
class BackoffException implements Exception {
  BackoffException(this.seconds);

  final int seconds;

  @override
  String toString() => 'BackoffException: back off for ${seconds}s';
}

/// Any other unexpected non-2xx storage response.
class SyncStorageException implements Exception {
  SyncStorageException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'SyncStorageException($statusCode): $body';
}

String? _header(http.Response response, String name) {
  final lower = name.toLowerCase();
  for (final entry in response.headers.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value;
    }
  }
  return null;
}

/// Sync 1.5 storage client for one collection namespace (`spaces`, for this
/// client), Hawk-authenticated on every request (PLAN §8.3).
class SyncStorageClient {
  SyncStorageClient(this._httpClient, this._token);

  final http.Client _httpClient;
  final SyncToken _token;

  HawkCredentials get _credentials =>
      HawkCredentials(id: _token.hawkId, key: utf8.encode(_token.hawkKey));

  Uri _path(String suffix, [Map<String, String>? query]) {
    final base = _token.apiEndpoint.toString();
    final trimmed = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final uri = Uri.parse('$trimmed/$suffix');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<http.Response> _get(Uri uri) async {
    final header = hawkAuthorizationHeader(
      credentials: _credentials,
      method: 'GET',
      uri: uri,
    );
    final response = await _httpClient.get(
      uri,
      headers: {'Authorization': header},
    );
    _checkTransient(response);
    return response;
  }

  Future<http.Response> _post(
    Uri uri,
    List<int> body, {
    required Map<String, String> extraHeaders,
  }) async {
    final header = hawkAuthorizationHeader(
      credentials: _credentials,
      method: 'POST',
      uri: uri,
      payload: body,
      contentType: 'application/json',
    );
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': header,
        'Content-Type': 'application/json',
        ...extraHeaders,
      },
      body: body,
    );
    _checkTransient(response);
    return response;
  }

  void _checkTransient(http.Response response) {
    if (response.statusCode == 503 || response.statusCode == 429) {
      final raw =
          _header(response, 'Retry-After') ??
          _header(response, 'X-Backoff') ??
          _header(response, 'X-Weave-Backoff');
      throw BackoffException(raw == null ? 0 : int.tryParse(raw) ?? 0);
    }
    if (response.statusCode == 401) {
      throw SyncAuthException(response.body);
    }
  }

  void _checkOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncStorageException(response.statusCode, response.body);
    }
  }

  /// `GET {base}/storage/meta/global`. Returns `null` on 404 (no
  /// `meta/global` yet — a brand-new account).
  Future<MetaGlobal?> getMetaGlobal() async {
    final response = await _get(_path('storage/meta/global'));
    if (response.statusCode == 404) {
      return null;
    }
    _checkOk(response);
    final bso = Bso.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
    final payloadJson = jsonDecode(bso.payload) as Map<String, Object?>;
    return MetaGlobal.fromJson(payloadJson);
  }

  /// `GET {base}/storage/crypto/keys`, decrypted with the account's
  /// sync-key bundle (PLAN §8.3 item 3).
  Future<CryptoKeys> getCryptoKeys(KeyBundle syncKeyBundle) async {
    final response = await _get(_path('storage/crypto/keys'));
    _checkOk(response);
    final bso = Bso.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
    final encrypted = EncryptedPayload.fromJson(
      (jsonDecode(bso.payload) as Map).cast<String, Object?>(),
    );
    final cleartext =
        (await decryptPayload(encrypted, syncKeyBundle))!
            as Map<String, Object?>;

    final defaultPair = (cleartext['default']! as List).cast<String>();
    final collectionsJson =
        (cleartext['collections'] as Map?)?.cast<String, Object?>() ?? const {};
    return CryptoKeys(
      defaultBundle: KeyBundle.fromBase64Pair(defaultPair[0], defaultPair[1]),
      collections: {
        for (final entry in collectionsJson.entries)
          entry.key: KeyBundle.fromBase64Pair(
            (entry.value! as List)[0] as String,
            (entry.value! as List)[1] as String,
          ),
      },
    );
  }

  /// `GET {base}/info/collections`: last-modified seconds per collection.
  Future<Map<String, double>> getCollectionInfo() async {
    final response = await _get(_path('info/collections'));
    _checkOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    return {
      for (final entry in json.entries)
        entry.key: (entry.value! as num).toDouble(),
    };
  }

  /// `GET {base}/storage/{collection}?full=1[&newer=][&ids=][&limit=]`,
  /// following `X-Weave-Next-Offset` until the server stops sending one.
  /// [ids] restricts the fetch to those records (how previously failed
  /// records are re-fetched, the way Firefox's `previousFailed` works).
  Future<FetchResult> fetchCollection(
    String collection, {
    double? newer,
    Iterable<String>? ids,
    int limit = 1000,
  }) async {
    final records = <Bso>[];
    double? lastModified;
    String? offset;

    while (true) {
      final query = <String, String>{'full': '1'};
      if (newer != null) {
        query['newer'] = newer.toStringAsFixed(2);
      }
      if (ids != null) {
        query['ids'] = ids.join(',');
      }
      if (limit > 0) {
        query['limit'] = '$limit';
      }
      if (offset != null) {
        query['offset'] = offset;
      }

      final response = await _get(_path('storage/$collection', query));
      _checkOk(response);

      final lastModifiedHeader = _header(response, 'X-Last-Modified');
      if (lastModifiedHeader != null) {
        lastModified = double.parse(lastModifiedHeader);
      }

      final list = jsonDecode(response.body) as List<Object?>;
      records.addAll(
        list.map(
          (element) => Bso.fromJson((element! as Map).cast<String, Object?>()),
        ),
      );

      final nextOffset = _header(response, 'X-Weave-Next-Offset');
      if (nextOffset == null || nextOffset.isEmpty) {
        break;
      }
      offset = nextOffset;
    }

    return FetchResult(records: records, lastModified: lastModified);
  }

  /// Splits [records] into upload batches of at most 100 records and
  /// approximately 1 MiB of JSON each.
  List<List<Bso>> _chunkForUpload(List<Bso> records) {
    final chunks = <List<Bso>>[];
    var current = <Bso>[];
    var currentBytes = 2; // '[' + ']'

    for (final record in records) {
      final encodedLength =
          utf8.encode(jsonEncode(record.toUploadJson())).length + 1;
      if (current.isNotEmpty &&
          (current.length >= _maxUploadBatchCount ||
              currentBytes + encodedLength > _maxUploadBatchBytes)) {
        chunks.add(current);
        current = [];
        currentBytes = 2;
      }
      current.add(record);
      currentBytes += encodedLength;
    }
    if (current.isNotEmpty) {
      chunks.add(current);
    }
    return chunks;
  }

  /// `POST {base}/storage/{collection}`, chunked to stay within Sync's
  /// per-request limits, with `X-If-Unmodified-Since` set on every chunk.
  /// Throws [PreconditionFailed] on 412 rather than forcing the write
  /// (PLAN §8.3 item 6).
  Future<PostResult> postRecords(
    String collection,
    List<Bso> records, {
    required double ifUnmodifiedSince,
  }) async {
    final success = <String>[];
    final failed = <String, String>{};
    double? modified;

    for (final chunk in _chunkForUpload(records)) {
      final body = utf8.encode(
        jsonEncode(chunk.map((record) => record.toUploadJson()).toList()),
      );
      final response = await _post(
        _path('storage/$collection'),
        body,
        extraHeaders: {
          'X-If-Unmodified-Since': ifUnmodifiedSince.toStringAsFixed(2),
        },
      );
      if (response.statusCode == 412) {
        throw PreconditionFailed();
      }
      _checkOk(response);

      final json = jsonDecode(response.body) as Map<String, Object?>;
      success.addAll((json['success'] as List? ?? const []).cast<String>());
      final failedJson =
          (json['failed'] as Map?)?.cast<String, Object?>() ?? const {};
      for (final entry in failedJson.entries) {
        failed[entry.key] = '${entry.value}';
      }
      if (json['modified'] != null) {
        modified = (json['modified']! as num).toDouble();
      }
    }

    return PostResult(success: success, failed: failed, modified: modified);
  }

  /// Decrypts and decodes one `spaces` BSO into a [ZenIncoming].
  Future<ZenIncoming> decryptBso(Bso bso, KeyBundle keys) async {
    final encrypted = EncryptedPayload.fromJson(
      (jsonDecode(bso.payload) as Map).cast<String, Object?>(),
    );
    final cleartext =
        (await decryptPayload(encrypted, keys))! as Map<String, Object?>;
    return ZenRecordCodec.decode(cleartext);
  }

  /// Encrypts a cleartext envelope (a live record's
  /// `{"id","kind","data"}`, or a tombstone's `{"id","deleted":true}`) into
  /// the JSON string a BSO's `payload` field holds.
  Future<String> encryptCleartext(
    Map<String, Object?> cleartext,
    KeyBundle keys,
  ) async {
    final payload = await encryptPayload(cleartext, keys);
    return jsonEncode(payload.toJson());
  }
}
