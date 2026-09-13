/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_mozilla_components/src/pigeons/gecko.g.dart';

final _apiInstance = GeckoWebInspectorApi();

/// Drives the built-in web inspector (a vendored Eruda) in one tab.
///
/// A null [tabId] addresses the selected tab. Every call is best effort: it is
/// dropped by native when the tab has no engine session or the inspector's
/// content port has not connected yet.
class GeckoWebInspectorService {
  final GeckoWebInspectorApi _api;
  final String? tabId;

  GeckoWebInspectorService({required this.tabId, GeckoWebInspectorApi? api})
    : _api = api ?? _apiInstance;

  /// Shows the inspector, optionally opening it on [panel] (e.g. `elements`).
  Future<void> show({String? panel}) {
    return _api.showInspector(tabId, panel);
  }

  /// Hides the inspector without tearing it down.
  Future<void> hide() {
    return _api.hideInspector(tabId);
  }

  /// Enters tap-to-inspect: the next tap on the page selects that element.
  Future<void> pickElement() {
    return _api.pickElement(tabId);
  }
}
