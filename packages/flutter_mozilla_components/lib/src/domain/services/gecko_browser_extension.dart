/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/services.dart';
import 'package:flutter_mozilla_components/src/domain/entities/turndown_result.dart';
import 'package:flutter_mozilla_components/src/pigeons/gecko.g.dart';

final _apiInstance = GeckoBrowserExtensionApi();

class GeckoBrowserExtensionService extends BrowserExtensionEvents {
  static Future<List<TurndownResults>> turndownHtml(
    List<String> htmlList, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    if (htmlList.isEmpty) {
      return [];
    }

    final markdownResult = await _apiInstance
        .getMarkdown(htmlList)
        .timeout(timeout);

    final results = markdownResult
        .cast()
        .map(
          (result) => TurndownResults(
            // ignore: avoid_dynamic_calls valid
            markdown: result['fullContentMarkdown'] as String,
            // ignore: avoid_dynamic_calls valid
            plain: result['fullContentPlain'] as String,
          ),
        )
        .toList();

    return results;
  }

  GeckoBrowserExtensionService.setUp({
    BinaryMessenger? binaryMessenger,
    String messageChannelSuffix = '',
  }) {
    BrowserExtensionEvents.setUp(
      this,
      binaryMessenger: binaryMessenger,
      messageChannelSuffix: messageChannelSuffix,
    );
  }
}
