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
// Mirrors the record model of Zen Browser's ZenSpacesSync (MPL-2.0), src/zen/sync/, commit 22961e9.
//
// THE PROJECTION IS NEVER CACHED. Read this before adding one.
//
// Zen's own `spaces` engine diffs against a cached, delayed projection and
// ships destructive batches because of it (upstream zen-browser/desktop#15380;
// DESIGN "Hardening against Zen's stale-projection race"). After applying an
// incoming batch `ZenSpacesSyncApplier.sys.mjs:182` calls
// `SessionSaver.runDelayed()` fire-and-forget, while `noteApplied`
// (`ZenSpacesSyncModel.sys.mjs:826-830`) stamps the uploaded snapshot
// immediately. Its projection cache is keyed on `sidebar.lastCollected`
// (`:509-511`), so between the apply and the delayed collection the projection
// is pre-apply while the snapshot is post-apply, and `computeChangedIDs`
// (`:748-757`) reads that skew as real change:
//
//   * an applied tombstone is re-uploaded as a create — closed tabs resurrect;
//   * an applied create yields a tombstone — tabs nobody closed are destroyed
//     on the other device.
//
// `#sidebarReady` (`:730-732`) does not save them: it only checks that *some*
// space data exists, not that it is current.
//
// [SpacesProjection] is therefore stateless: every field is an injected
// collaborator, `project()` reads the database on every call, and nothing it
// computes survives the call. `spacesProjectionProvider` is `keepAlive` but
// only caches the *object*, never its output. If a cache ever becomes
// necessary for performance it must be keyed on a monotonic database write
// counter (a counter bumped from Drift's `tableUpdates` notifications) — never
// on a wall-clock timestamp, a "last collected" stamp or a dirty flag, all of
// which are exactly what fails above.
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mellow/core/logger.dart';
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/scope_slot.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_split_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:mellow/features/spaces_sync/data/models/zen_records.dart';
import 'package:mellow/features/spaces_sync/domain/zen_ids.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'spaces_projection.g.dart';

/// Everything `setIcon` accepts without a loading principal — the only icon
/// URLs Zen puts on the wire (`LOCAL_ICON_PROTOCOLS`).
const _localIconProtocols = ['data:', 'chrome:', 'about:', 'resource:'];

/// Ports Zen's `syncableIconUrl`: a `moz-remote-image:` wrapper is unwrapped
/// to the URL it carries, and anything that is not a locally settable icon
/// becomes the empty string.
String syncableIconUrl(String? icon) {
  if (icon == null || icon.isEmpty) {
    return '';
  }
  var candidate = icon;
  if (candidate.startsWith('moz-remote-image:')) {
    final uri = Uri.tryParse(candidate);
    candidate = uri?.queryParameters['url'] ?? '';
  }
  return _localIconProtocols.any(candidate.startsWith) ? candidate : '';
}

/// The columns of `tab` the projection needs — not `TabData`, whose content
/// columns would drag every stored page through the query.
class _TabRow {
  _TabRow({
    required this.id,
    required this.containerId,
    required this.spaceUuid,
    required this.folderId,
    required this.splitId,
    required this.splitIndex,
    required this.shelf,
    required this.orderKey,
    required this.url,
    required this.title,
    required this.iconUrl,
    required this.staticLabel,
    required this.hasStaticIcon,
    required this.defaultContainer,
  });

  final String id;
  final String? containerId;
  final String? spaceUuid;
  final String? folderId;
  final String? splitId;
  final int? splitIndex;
  final TabShelf shelf;
  final String orderKey;
  final String url;
  final String title;
  final String? iconUrl;
  final String? staticLabel;
  final bool hasStaticIcon;
  final bool defaultContainer;

  bool get isEssential => shelf == TabShelf.essential;
}

/// DB → Zen records, mirroring `ZenSpacesSyncModel.projections()` (PLAN
/// §4.2, W6.1). Read-only apart from minting container guids
/// (`ContainerRepository.ensureSyncGuid`), which is what Zen's
/// `guidForContextId(create: true)` does inside its projection too.
///
/// **Stateless by contract** — it holds no mutable state between calls and
/// caches nothing. See the file header for why; do not add a field that
/// outlives [project].
class SpacesProjection {
  SpacesProjection(this._db, this._containers);

  final TabDatabase _db;
  final ContainerRepository _containers;

  /// Every record this device currently projects, keyed by record id.
  /// Foreign records are re-emitted verbatim.
  ///
  /// Queries the database on every call. Never memoise the returned map.
  Future<Map<String, ZenCleartext>> project() async {
    final tabs = await _regularTabs();
    final spaces = await _db.spaceDao.getAll();
    final folders = await _db.tabFolder.select().get();
    final splits = await _db.tabSplit.select().get();
    final containers = await _db.container.select().get();

    final syncableTabs = <String, _TabRow>{
      for (final tab in tabs)
        if (_isSyncable(tab)) tab.id: tab,
    };

    // Splits sync only when every member (≥ 2) syncs (Zen's
    // `#projectionContext`).
    final membersBySplit = <String, List<_TabRow>>{};
    for (final tab in tabs) {
      final splitId = tab.splitId;
      if (splitId != null) {
        (membersBySplit[splitId] ??= []).add(tab);
      }
    }
    for (final members in membersBySplit.values) {
      members.sort((a, b) => (a.splitIndex ?? 0).compareTo(b.splitIndex ?? 0));
    }
    final syncableSplits = <String, TabSplitData>{
      for (final split in splits)
        if (_splitIsSyncable(membersBySplit[split.id], syncableTabs))
          split.id: split,
    };
    final folderIds = {for (final folder in folders) folder.id};

    // Container guids: minted for every container a projected tab or space
    // references, so a record never points at a guid the server has not seen.
    final containerById = {for (final c in containers) c.id: c};
    final guidByContainerId = <String, String>{};
    Future<String?> guidFor(String? containerId) async {
      if (containerId == null) {
        return null;
      }
      final known = guidByContainerId[containerId];
      if (known != null) {
        return known;
      }
      if (!containerById.containsKey(containerId)) {
        return null;
      }
      final guid = await _containers.ensureSyncGuid(containerId);
      guidByContainerId[containerId] = guid;
      return guid;
    }

    for (final tab in syncableTabs.values) {
      await guidFor(tab.containerId);
    }
    for (final space in spaces) {
      await guidFor(space.containerId);
    }

    final map = <String, ZenCleartext>{};

    // Foreign records first so a known kind projected below wins over a
    // stale foreign copy of the same id.
    for (final foreign in await _db.syncStateDao.allForeign()) {
      final decoded = jsonDecode(foreign.payload);
      if (decoded is! Map) {
        logger.w('spaces sync: foreign record ${foreign.id} has no object');
        continue;
      }
      map[foreign.id] = ZenCleartext(
        id: foreign.id,
        data: ZenForeignRecord(
          recordId: foreign.id,
          kind: foreign.kind,
          rawData: decoded.cast<String, Object?>(),
        ),
      );
    }

    _projectContainers(map, containers, guidByContainerId);
    await _projectSpaces(map, spaces, syncableTabs, syncableSplits, guidFor);
    await _projectFolders(map, folders, syncableTabs, syncableSplits);
    for (final tab in syncableTabs.values) {
      map[tab.id] = ZenCleartext(
        id: tab.id,
        data: _tabRecord(tab, await guidFor(tab.containerId), folderIds),
      );
    }
    _projectSplits(map, syncableSplits, membersBySplit);
    await _projectLayout(map, spaces, syncableTabs, guidFor);

    return map;
  }

  Future<List<_TabRow>> _regularTabs() async {
    final t = _db.tab;
    final query = _db.selectOnly(t)
      ..addColumns([
        t.id,
        t.containerId,
        t.spaceUuid,
        t.folderId,
        t.splitId,
        t.splitIndex,
        t.tabShelf,
        t.orderKey,
        t.url,
        t.title,
        t.iconUrl,
        t.staticLabel,
        t.hasStaticIcon,
        t.defaultContainer,
      ])
      // Private tabs never leave the device (I3, PLAN §8.4).
      ..where(t.tabMode.equalsValue(TabModeDbValue.regular))
      ..orderBy([OrderingTerm.asc(t.orderKey)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        _TabRow(
          id: row.read(t.id)!,
          containerId: row.read(t.containerId),
          spaceUuid: row.read(t.spaceUuid),
          folderId: row.read(t.folderId),
          splitId: row.read(t.splitId),
          splitIndex: row.read(t.splitIndex),
          shelf: row.readWithConverter(t.tabShelf)!,
          orderKey: row.read(t.orderKey)!,
          url: row.readWithConverter(t.url)?.toString() ?? '',
          title: row.read(t.title) ?? '',
          iconUrl: row.read(t.iconUrl),
          staticLabel: row.read(t.staticLabel),
          hasStaticIcon: row.read(t.hasStaticIcon) ?? false,
          defaultContainer: row.read(t.defaultContainer) ?? false,
        ),
    ];
  }

  /// Zen's `#isSyncableTab` + `#tabIdentity`: a URL-less or `about:blank`
  /// tab has no record; a normal tab without a space breaks I2 and is
  /// skipped with a log line rather than shipped.
  bool _isSyncable(_TabRow tab) {
    if (tab.url.isEmpty || tab.url == 'about:blank') {
      return false;
    }
    if (!tab.isEssential && tab.spaceUuid == null) {
      logger.w(
        'spaces sync: tab ${tab.id} has no space and is not essential; '
        'not projected',
      );
      return false;
    }
    return true;
  }

  bool _splitIsSyncable(
    List<_TabRow>? members,
    Map<String, _TabRow> syncableTabs,
  ) {
    if (members == null || members.length < 2) {
      return false;
    }
    return members.every((member) => syncableTabs.containsKey(member.id));
  }

  /// Slot ids of `(space, folder)` in strip order, restricted to what syncs.
  Future<List<String>> _children(
    String? spaceUuid,
    String? folderId,
    Map<String, _TabRow> syncableTabs,
    Map<String, TabSplitData> syncableSplits,
  ) async {
    final slots = await _db.tabDao.scopeChildSlots(spaceUuid, folderId);
    return [
      for (final slot in slots)
        if (switch (slot.kind) {
          ScopeSlotKind.tab => syncableTabs.containsKey(slot.id),
          ScopeSlotKind.folder => true,
          ScopeSlotKind.split => syncableSplits.containsKey(slot.id),
        })
          slot.id,
    ];
  }

  void _projectContainers(
    Map<String, ZenCleartext> map,
    List<ContainerData> containers,
    Map<String, String> guidByContainerId,
  ) {
    for (final container in containers) {
      final guid = container.syncGuid ?? guidByContainerId[container.id];
      // Built-ins are never records (Zen skips them too); nameless
      // identities are skipped like Zen's `if (!identity.name) continue`.
      if (guid == null ||
          ZenIds.isBuiltinContainerGuid(guid) ||
          container.name.isEmpty) {
        continue;
      }
      map[guid] = ZenCleartext(
        id: guid,
        data: ZenContainerRecord(
          guid: guid,
          name: container.name,
          icon: container.iconKey,
          color: container.colorKey,
        ),
      );
    }
  }

  Future<void> _projectSpaces(
    Map<String, ZenCleartext> map,
    List<SpaceData> spaces,
    Map<String, _TabRow> syncableTabs,
    Map<String, TabSplitData> syncableSplits,
    Future<String?> Function(String? containerId) guidFor,
  ) async {
    for (final space in spaces) {
      map[space.uuid] = ZenCleartext(
        id: space.uuid,
        data: ZenSpaceRecord(
          uuid: space.uuid,
          name: space.name,
          icon: space.icon,
          theme: _decodeOpaque(space.theme),
          containerGuid: await guidFor(space.containerId),
          children: await _children(
            space.uuid,
            null,
            syncableTabs,
            syncableSplits,
          ),
        ),
      );
    }
  }

  Future<void> _projectFolders(
    Map<String, ZenCleartext> map,
    List<TabFolderData> folders,
    Map<String, _TabRow> syncableTabs,
    Map<String, TabSplitData> syncableSplits,
  ) async {
    for (final folder in folders) {
      map[folder.id] = ZenCleartext(
        id: folder.id,
        data: ZenFolderRecord(
          folderId: folder.id,
          name: folder.name,
          icon: folder.icon,
          workspaceUuid: folder.spaceUuid,
          parentFolderId: folder.parentFolderId,
          live: _decodeOpaque(folder.live),
          children: await _children(
            folder.spaceUuid,
            folder.id,
            syncableTabs,
            syncableSplits,
          ),
        ),
      );
    }
  }

  ZenTabRecord _tabRecord(
    _TabRow tab,
    String? containerGuid,
    Set<String> folderIds,
  ) {
    final essential = tab.isEssential;
    final folderId = tab.folderId;
    return ZenTabRecord(
      tabId: tab.id,
      url: tab.url,
      title: tab.title,
      icon: syncableIconUrl(tab.iconUrl),
      containerGuid: containerGuid,
      essential: essential,
      // An Essential is always also pinned (PLAN §4.2).
      pinned: tab.shelf != TabShelf.normal,
      workspaceUuid: essential ? null : tab.spaceUuid,
      folderId: essential || folderId == null || !folderIds.contains(folderId)
          ? null
          : folderId,
      staticLabel: tab.staticLabel,
      hasStaticIcon: tab.hasStaticIcon,
      defaultContainer: tab.defaultContainer,
    );
  }

  void _projectSplits(
    Map<String, ZenCleartext> map,
    Map<String, TabSplitData> syncableSplits,
    Map<String, List<_TabRow>> membersBySplit,
  ) {
    for (final split in syncableSplits.values) {
      final members = membersBySplit[split.id]!;
      map[split.id] = ZenCleartext(
        id: split.id,
        data: ZenSplitRecord(
          splitId: split.id,
          gridType: split.gridType,
          pinned: split.isPinned,
          tabs: [for (final member in members) member.id],
          workspaceUuid: split.spaceUuid,
          folderId: split.folderId,
        ),
      );
    }
  }

  Future<void> _projectLayout(
    Map<String, ZenCleartext> map,
    List<SpaceData> spaces,
    Map<String, _TabRow> syncableTabs,
    Future<String?> Function(String? containerId) guidFor,
  ) async {
    if (spaces.isEmpty) {
      return;
    }
    final essentials = <String, List<String>>{};
    // `syncableTabs` preserves the global `order_key` order, which within one
    // container strip is that strip's order.
    for (final tab in syncableTabs.values) {
      if (!tab.isEssential) {
        continue;
      }
      final key = await guidFor(tab.containerId) ?? 'default';
      (essentials[key] ??= []).add(tab.id);
    }
    map[ZenLayoutRecord.recordIdLiteral] = ZenCleartext(
      id: ZenLayoutRecord.recordIdLiteral,
      data: ZenLayoutRecord(
        spaces: [for (final space in spaces) space.uuid],
        essentials: essentials,
      ),
    );
  }

  /// `theme` / `live` are stored as the JSON text they arrived as.
  static Object? _decodeOpaque(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } on FormatException {
      logger.w('spaces sync: opaque JSON column is not JSON: $raw');
      return null;
    }
  }
}

/// Caches the stateless [SpacesProjection] object, never a projection: each
/// `project()` call still hits the database (see the file header).
@Riverpod(keepAlive: true)
SpacesProjection spacesProjection(Ref ref) => SpacesProjection(
  ref.watch(tabDatabaseProvider),
  ref.watch(containerRepositoryProvider.notifier),
);
