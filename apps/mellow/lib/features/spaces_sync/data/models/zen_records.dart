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

import 'package:crypto/crypto.dart';
import 'package:fast_equatable/fast_equatable.dart';

/// Converts [value] to the string list Zen's `children` / `tabs` arrays hold.
List<String> _stringList(Object? value) {
  if (value == null) {
    return const [];
  }
  return (value as List)
      .map((element) => element! as String)
      .toList(growable: false);
}

/// A sealed synced payload: the `data` half of a Zen cleartext record.
///
/// Zen's six synced record kinds (`RECORD_KINDS` in
/// `ZenSpacesSyncModel.sys.mjs`), plus the shared cleartext envelope,
/// canonical JSON and record digest that make up the desktop's snapshot-diff
/// contract (PLAN §4).
///
/// Key order in every `toJson()` in this file matches Zen's `#projectX`
/// functions exactly (read there before touching this file) so that a
/// record we re-encode without modification produces byte-identical
/// canonical JSON to one Zen itself produced — the round-trip fidelity gate
/// (PLAN §8.6 item 1) depends on it.
sealed class ZenRecordData with FastEquatable {
  /// One of `container`, `space`, `tab`, `folder`, `split`, `layout`.
  String get kind;

  /// The record id, as it appears in the enclosing cleartext's `id` field:
  /// a guid, a uuid, a tab id, a folder id, a split id, or the literal
  /// string `layout`.
  String get recordId;

  /// Encodes `data` with keys in Zen's exact projection order.
  Map<String, Object?> toJson();

  /// Decodes a `data` object for a known [kind]. Throws for unknown kinds —
  /// callers that must tolerate unknown kinds go through
  /// [ZenRecordCodec.decode] instead, which routes those to
  /// [ZenIncomingUnknownKind].
  static ZenRecordData fromKindJson(String kind, Map<String, Object?> json) {
    return switch (kind) {
      'container' => ZenContainerRecord.fromJson(json),
      'space' => ZenSpaceRecord.fromJson(json),
      'tab' => ZenTabRecord.fromJson(json),
      'folder' => ZenFolderRecord.fromJson(json),
      'split' => ZenSplitRecord.fromJson(json),
      'layout' => ZenLayoutRecord.fromJson(json),
      _ => throw ArgumentError.value(kind, 'kind', 'unknown Zen record kind'),
    };
  }
}

/// `container` — a Firefox contextual identity (PLAN §4.2).
final class ZenContainerRecord extends ZenRecordData {
  ZenContainerRecord({
    required this.guid,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory ZenContainerRecord.fromJson(Map<String, Object?> json) =>
      ZenContainerRecord(
        guid: json['guid']! as String,
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        color: json['color'] as String? ?? '',
      );

  final String guid;
  final String name;
  final String icon;
  final String color;

  @override
  String get kind => 'container';

  @override
  String get recordId => guid;

  @override
  Map<String, Object?> toJson() => {
    'guid': guid,
    'name': name,
    'icon': icon,
    'color': color,
  };

  @override
  List<Object?> get hashParameters => [guid, name, icon, color];
}

/// `space` — a Zen workspace (PLAN §4.2). `theme` is opaque desktop-defined
/// JSON, stored and re-emitted unchanged.
final class ZenSpaceRecord extends ZenRecordData {
  ZenSpaceRecord({
    required this.uuid,
    required this.name,
    required this.icon,
    required this.theme,
    required this.containerGuid,
    required this.children,
  });

  factory ZenSpaceRecord.fromJson(Map<String, Object?> json) => ZenSpaceRecord(
    uuid: json['uuid']! as String,
    name: json['name'] as String? ?? '',
    icon: json['icon'] as String?,
    theme: json['theme'],
    containerGuid: json['containerGuid'] as String?,
    children: _stringList(json['children']),
  );

  final String uuid;
  final String name;
  final String? icon;
  final Object? theme;
  final String? containerGuid;
  final List<String> children;

  @override
  String get kind => 'space';

  @override
  String get recordId => uuid;

  @override
  Map<String, Object?> toJson() => {
    'uuid': uuid,
    'name': name,
    'icon': icon,
    'theme': theme,
    'containerGuid': containerGuid,
    'children': children,
  };

  @override
  List<Object?> get hashParameters => [
    uuid,
    name,
    icon,
    theme,
    containerGuid,
    children,
  ];
}

/// `tab` — record id is `zenSyncId` (PLAN §4.2). See `#tabIdentity` /
/// `#projectTabs` in `ZenSpacesSyncModel.sys.mjs` for the semantics encoded
/// here: pinned/essential tabs freeze url/title at pin time, an essential
/// tab always has `pinned == true` and `workspaceUuid == null`.
final class ZenTabRecord extends ZenRecordData {
  ZenTabRecord({
    required this.tabId,
    required this.url,
    required this.title,
    required this.icon,
    required this.containerGuid,
    required this.essential,
    required this.pinned,
    required this.workspaceUuid,
    required this.folderId,
    required this.staticLabel,
    required this.hasStaticIcon,
    required this.defaultContainer,
  });

  factory ZenTabRecord.fromJson(Map<String, Object?> json) => ZenTabRecord(
    tabId: json['tabId']! as String,
    url: json['url'] as String? ?? '',
    title: json['title'] as String? ?? '',
    icon: json['icon'] as String? ?? '',
    containerGuid: json['containerGuid'] as String?,
    essential: json['essential'] as bool? ?? false,
    pinned: json['pinned'] as bool? ?? false,
    workspaceUuid: json['workspaceUuid'] as String?,
    folderId: json['folderId'] as String?,
    staticLabel: json['staticLabel'] as String?,
    hasStaticIcon: json['hasStaticIcon'] as bool? ?? false,
    defaultContainer: json['defaultContainer'] as bool? ?? false,
  );

  final String tabId;
  final String url;
  final String title;
  final String icon;
  final String? containerGuid;
  final bool essential;
  final bool pinned;
  final String? workspaceUuid;
  final String? folderId;
  final String? staticLabel;
  final bool hasStaticIcon;
  final bool defaultContainer;

  @override
  String get kind => 'tab';

  @override
  String get recordId => tabId;

  @override
  Map<String, Object?> toJson() => {
    'tabId': tabId,
    'url': url,
    'title': title,
    'icon': icon,
    'containerGuid': containerGuid,
    'essential': essential,
    'pinned': pinned,
    'workspaceUuid': workspaceUuid,
    'folderId': folderId,
    'staticLabel': staticLabel,
    'hasStaticIcon': hasStaticIcon,
    'defaultContainer': defaultContainer,
  };

  @override
  List<Object?> get hashParameters => [
    tabId,
    url,
    title,
    icon,
    containerGuid,
    essential,
    pinned,
    workspaceUuid,
    folderId,
    staticLabel,
    hasStaticIcon,
    defaultContainer,
  ];
}

/// `folder` — record id is the folder id (PLAN §4.2). `live` is opaque
/// live-folder provider config, stored and re-emitted unchanged.
final class ZenFolderRecord extends ZenRecordData {
  ZenFolderRecord({
    required this.folderId,
    required this.name,
    required this.icon,
    required this.workspaceUuid,
    required this.parentFolderId,
    required this.live,
    required this.children,
  });

  factory ZenFolderRecord.fromJson(Map<String, Object?> json) =>
      ZenFolderRecord(
        folderId: json['folderId']! as String,
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String?,
        workspaceUuid: json['workspaceUuid'] as String?,
        parentFolderId: json['parentFolderId'] as String?,
        live: json['live'],
        children: _stringList(json['children']),
      );

  final String folderId;
  final String name;
  final String? icon;
  final String? workspaceUuid;
  final String? parentFolderId;
  final Object? live;
  final List<String> children;

  @override
  String get kind => 'folder';

  @override
  String get recordId => folderId;

  @override
  Map<String, Object?> toJson() => {
    'folderId': folderId,
    'name': name,
    'icon': icon,
    'workspaceUuid': workspaceUuid,
    'parentFolderId': parentFolderId,
    'live': live,
    'children': children,
  };

  @override
  List<Object?> get hashParameters => [
    folderId,
    name,
    icon,
    workspaceUuid,
    parentFolderId,
    live,
    children,
  ];
}

/// `split` — record id is the group id (PLAN §4.2). Zen's split view;
/// WebLibre cannot render it but must round-trip it faithfully.
final class ZenSplitRecord extends ZenRecordData {
  ZenSplitRecord({
    required this.splitId,
    required this.gridType,
    required this.pinned,
    required this.tabs,
    required this.workspaceUuid,
    required this.folderId,
  });

  factory ZenSplitRecord.fromJson(Map<String, Object?> json) => ZenSplitRecord(
    splitId: json['splitId']! as String,
    gridType: json['gridType'] as String? ?? 'grid',
    pinned: json['pinned'] as bool? ?? false,
    tabs: _stringList(json['tabs']),
    workspaceUuid: json['workspaceUuid'] as String?,
    folderId: json['folderId'] as String?,
  );

  final String splitId;
  final String gridType;
  final bool pinned;
  final List<String> tabs;
  final String? workspaceUuid;
  final String? folderId;

  @override
  String get kind => 'split';

  @override
  String get recordId => splitId;

  @override
  Map<String, Object?> toJson() => {
    'splitId': splitId,
    'gridType': gridType,
    'pinned': pinned,
    'tabs': tabs,
    'workspaceUuid': workspaceUuid,
    'folderId': folderId,
  };

  @override
  List<Object?> get hashParameters => [
    splitId,
    gridType,
    pinned,
    tabs,
    workspaceUuid,
    folderId,
  ];
}

/// `layout` — record id is the literal string `"layout"` (PLAN §4.2). Global
/// space order and Essentials grouped by container guid (or `"default"`).
final class ZenLayoutRecord extends ZenRecordData {
  ZenLayoutRecord({required this.spaces, required this.essentials});

  factory ZenLayoutRecord.fromJson(Map<String, Object?> json) {
    final rawEssentials =
        (json['essentials'] as Map?)?.cast<String, Object?>() ?? const {};
    return ZenLayoutRecord(
      spaces: _stringList(json['spaces']),
      essentials: {
        for (final entry in rawEssentials.entries)
          entry.key: _stringList(entry.value),
      },
    );
  }

  /// The literal record id Zen uses for the single layout record.
  static const recordIdLiteral = 'layout';

  final List<String> spaces;
  final Map<String, List<String>> essentials;

  @override
  String get kind => 'layout';

  @override
  String get recordId => recordIdLiteral;

  @override
  Map<String, Object?> toJson() => {'spaces': spaces, 'essentials': essentials};

  @override
  List<Object?> get hashParameters => [spaces, essentials];
}

/// A record of a kind this client does not model (a newer Zen), held
/// verbatim in `foreign_record` and re-emitted unchanged so a round-trip
/// through this device never drops another client's data (PLAN §6.5).
///
/// Never decoded from the wire directly — [ZenRecordCodec.decode] routes
/// unknown kinds to [ZenIncomingUnknownKind]; the projection builds one of
/// these from the stored payload.
final class ZenForeignRecord extends ZenRecordData {
  ZenForeignRecord({
    required this.recordId,
    required this.kind,
    required this.rawData,
  });

  @override
  final String recordId;

  @override
  final String kind;

  /// The undecoded `data` object, exactly as received.
  final Map<String, Object?> rawData;

  @override
  Map<String, Object?> toJson() => rawData;

  @override
  List<Object?> get hashParameters => [recordId, kind, rawData];
}

/// The decrypted, decoded payload of one Sync BSO for the `spaces`
/// collection: `{"id":..,"kind":..,"data":{...}}`.
class ZenCleartext with FastEquatable {
  ZenCleartext({required this.id, required this.data});

  final String id;
  final ZenRecordData data;

  String get kind => data.kind;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': data.kind,
    'data': data.toJson(),
  };

  @override
  List<Object?> get hashParameters => [id, data];
}

/// A Sync tombstone: `{"id":..,"deleted":true}`.
class ZenTombstone with FastEquatable {
  ZenTombstone({required this.id});

  final String id;

  Map<String, Object?> toJson() => {'id': id, 'deleted': true};

  @override
  List<Object?> get hashParameters => [id];
}

/// One decoded incoming Sync record for the `spaces` collection: either a
/// live record of a known kind, a tombstone, or a record of a kind this
/// client does not (yet) understand, kept verbatim so a round-trip through
/// this client never drops another client's data (PLAN §6.5
/// `foreign_record`).
sealed class ZenIncoming with FastEquatable {}

/// A live record of a known kind.
final class ZenIncomingRecord extends ZenIncoming {
  ZenIncomingRecord(this.cleartext);

  final ZenCleartext cleartext;

  @override
  List<Object?> get hashParameters => [cleartext];
}

/// A Sync tombstone.
final class ZenIncomingTombstone extends ZenIncoming {
  ZenIncomingTombstone(this.id);

  final String id;

  @override
  List<Object?> get hashParameters => [id];
}

/// A record of an unrecognised `kind`. `rawData` is the undecoded `data`
/// value, kept as-is so it can be re-emitted unchanged if this record is
/// ever written back.
final class ZenIncomingUnknownKind extends ZenIncoming {
  ZenIncomingUnknownKind({
    required this.id,
    required this.kind,
    required this.rawData,
  });

  final String id;
  final String kind;
  final Object? rawData;

  @override
  List<Object?> get hashParameters => [id, kind, rawData];
}

/// Decodes/encodes the cleartext envelope shared by all six record kinds.
// ignore: avoid_classes_with_only_static_members
abstract final class ZenRecordCodec {
  /// Decodes one cleartext BSO payload (already JSON-decoded) into a
  /// [ZenIncoming]. `{"deleted": true}` is a tombstone regardless of `kind`
  /// (Sync's convention); otherwise a known `kind` decodes to
  /// [ZenIncomingRecord] and an unknown one to [ZenIncomingUnknownKind].
  static ZenIncoming decode(Map<String, Object?> json) {
    final id = json['id']! as String;
    if (json['deleted'] == true) {
      return ZenIncomingTombstone(id);
    }
    final kind = json['kind']! as String;
    final rawData = json['data'];
    switch (kind) {
      case 'container':
      case 'space':
      case 'tab':
      case 'folder':
      case 'split':
      case 'layout':
        final data = ZenRecordData.fromKindJson(
          kind,
          (rawData as Map?)?.cast<String, Object?>() ?? {},
        );
        return ZenIncomingRecord(ZenCleartext(id: id, data: data));
      default:
        return ZenIncomingUnknownKind(id: id, kind: kind, rawData: rawData);
    }
  }
}

Object? _sortedClone(Object? value) {
  if (value is List) {
    return value.map(_sortedClone).toList(growable: false);
  }
  if (value is Map) {
    final sortedKeys = value.keys.map((key) => key! as String).toList()..sort();
    return {for (final key in sortedKeys) key: _sortedClone(value[key])};
  }
  return value;
}

/// Deterministic JSON serialization: recursively key-sorted, so two
/// structurally equal payloads always encode identically. Ports Zen's
/// `sortedClone`/`canonicalJSON` (`ZenSpacesSyncModel.sys.mjs`) — a missing
/// value there is JS `undefined`, which `sortedClone` maps to `null`; Dart has
/// no `undefined`, so an absent key is already `null` once decoded.
String canonicalJson(Object? value) => jsonEncode(_sortedClone(value));

/// Base64 SHA-256 of the canonical JSON of `{"kind": kind, "data": data}`,
/// matching Zen's `recordDigest`. This is the per-record content digest the
/// snapshot-diff store compares against to decide what to upload (PLAN §4.3).
String recordDigest(String kind, Map<String, Object?> data) {
  final bytes = utf8.encode(canonicalJson({'kind': kind, 'data': data}));
  return base64Encode(sha256.convert(bytes).bytes);
}
