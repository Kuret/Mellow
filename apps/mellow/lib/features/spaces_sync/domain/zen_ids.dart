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
import 'dart:math';

import 'package:mellow/core/uuid.dart';

/// Identity formats for Zen's synced records (DESIGN.md "Identity formats").
///
/// These mirror the exact string shapes Zen's desktop client generates so
/// that ids created on either device are indistinguishable on the wire.
// ignore: avoid_classes_with_only_static_members
abstract final class ZenIds {
  static final Random _random = Random.secure();

  /// A new `zenSyncId` for a tab, matching
  /// `` `${Date.now()}-${Math.round(Math.random()*100)}` `` from
  /// `ZenWindowSync.sys.mjs` (`#newTabSyncId`).
  static String newTabId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(101)}';

  /// A new folder (or split group) id. Firefox's tab-group ids share the tab
  /// id's shape (`gBrowser.addTabGroup`), so this is the same format.
  static String newGroupId() => newTabId();

  /// A new space uuid: a v4 uuid wrapped in braces, matching
  /// `Services.uuid.generateUUID().toString()` (`ZenSpaceManager.mjs`).
  static String newSpaceUuid() => '{${uuid.v4()}}';

  /// A new container guid: a v4 uuid without braces
  /// (`ZenSpacesSyncModel.guidForContextId`).
  static String newContainerGuid() => uuid.v4();

  static final RegExp _builtinPattern = RegExp(r'^builtin-[1-4]$');

  /// Whether [guid] is one of Firefox's four well-known built-in container
  /// guids (`builtin-1` .. `builtin-4`), which are never projected as
  /// `container` records themselves.
  static bool isBuiltinContainerGuid(String guid) =>
      _builtinPattern.hasMatch(guid);
}
