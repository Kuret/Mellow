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
import 'dart:io';

import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:http/http.dart' as http;
import 'package:mellow/core/filesystem.dart';
import 'package:mellow/features/spaces_sync/data/snapshot_store.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The HTTP client the Sync 1.5 requests go through. Tests override it with
/// an `http.testing.MockClient`.
@Riverpod(keepAlive: true)
http.Client spacesSyncHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

/// The account's `oldsync` credentials (PLAN §8.2): the OAuth token, its
/// `kid`, the base64url 64-byte sync key, and the tokenserver to use (the
/// app's override when configured).
typedef SpacesSyncCredentials = ({
  String accessToken,
  String keyId,
  String syncKeyBase64Url,
  String tokenServerUrl,
  int expiresAtEpochSeconds,
});

/// Fetches the credentials from native; `null` without a signed-in account.
/// Tests override it with a stub.
typedef SyncCredentialsSource = Future<SpacesSyncCredentials?> Function();

@Riverpod(keepAlive: true)
SyncCredentialsSource spacesSyncCredentials(Ref ref) {
  final service = GeckoSyncService();
  return () async {
    final native = await service.getSyncCredentials();
    if (native == null) {
      return null;
    }
    return (
      accessToken: native.accessToken,
      keyId: native.keyId,
      syncKeyBase64Url: native.syncKeyBase64Url,
      tokenServerUrl: native.tokenServerUrl,
      expiresAtEpochSeconds: native.expiresAtEpochSeconds,
    );
  };
}

/// Where the collection snapshots and the failed-id list live:
/// `<profile>/spaces_sync/`.
@Riverpod(keepAlive: true)
SnapshotStore spacesSyncSnapshotStore(Ref ref) => SnapshotStore(
  Directory(p.join(filesystem.selectedProfileDir.path, 'spaces_sync')),
);
