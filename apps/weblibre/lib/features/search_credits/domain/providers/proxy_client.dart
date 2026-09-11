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

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proxy_client.g.dart';

/// HttpClient used by both WebSocket (via `IOWebSocketChannel.customClient`)
/// and HTTP-based search clients.
@Riverpod(keepAlive: true)
HttpClient searchHttpClient(Ref ref) {
  final client = HttpClient()
    // The default HttpClient has no connection timeout, so a search service
    // that is unreachable can stall the UI for ~minute(s) before failing.
    // Cap the TCP/TLS handshake at a few seconds so the user sees an error
    // quickly and can retry; the WebSocket session itself imposes no
    // ceiling on long-running streams once connected.
    ..connectionTimeout = const Duration(seconds: 25);
  ref.onDispose(() => client.close(force: true));
  return client;
}

/// `package:http` Client wrapping [searchHttpClientProvider]. Use for the
/// non-WebSocket parts of the search flow (token issuance, one-shot capture,
/// capture artifact downloads).
@Riverpod(keepAlive: true)
http.Client searchProxyHttpClient(Ref ref) {
  final httpClient = ref.watch(searchHttpClientProvider);
  // IOClient does not own the HttpClient lifetime here — the underlying
  // HttpClient is closed by the searchHttpClientProvider's onDispose. Don't
  // close the IOClient on dispose to avoid prematurely tearing down the
  // shared HttpClient on rebuild.
  return IOClient(httpClient);
}
