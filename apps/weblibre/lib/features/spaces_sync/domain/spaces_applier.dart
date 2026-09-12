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
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/core/uuid.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_split_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_summary.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/folder.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/space.dart';
import 'package:weblibre/features/spaces_sync/data/models/zen_records.dart';
import 'package:weblibre/features/spaces_sync/domain/spaces_projection.dart';
import 'package:weblibre/features/spaces_sync/domain/zen_ids.dart';

part 'spaces_applier.g.dart';

/// A record named a `containerGuid` no local container carries. Like Zen's
/// `#resolveContainerId`, the record fails and is retried on a later sync,
/// by which time the container record may have applied.
class UnknownContainerGuid implements Exception {
  UnknownContainerGuid(this.guid);

  final String guid;

  @override
  String toString() => 'unknown container guid $guid';
}

/// A tab record named a folder that does not exist locally. Failed rather
/// than silently dropped to the space root: re-uploading the tab without its
/// folder would move it out of the folder on the desktop.
class UnknownFolder implements Exception {
  UnknownFolder(this.folderId);

  final String folderId;

  @override
  String toString() => 'unknown folder $folderId';
}

class _Entry<T extends ZenRecordData> {
  _Entry(this.id, this.data);

  final String id;
  final T data;
}

class _Incoming {
  final containers = <_Entry<ZenContainerRecord>>[];
  final spaces = <_Entry<ZenSpaceRecord>>[];
  final tabs = <_Entry<ZenTabRecord>>[];
  final folders = <_Entry<ZenFolderRecord>>[];
  final splits = <_Entry<ZenSplitRecord>>[];
  _Entry<ZenLayoutRecord>? layout;
  final deleted = <String>[];
  final unknown = <ZenIncomingUnknownKind>[];
}

class _Removals {
  final tabs = <String>[];
  final folders = <String>[];
  final splits = <String>[];
  final spaces = <String>[];
}

/// Incoming Zen records → local rows, in `ZenSpacesSyncApplier.applyBatch`'s
/// order: containers, routed tombstones, tab and split deletes, spaces,
/// folders (parents first), tabs, splits, folder and space deletes,
/// ordering (W6.2). Goes through the repositories for anything that touches
/// tabs so invariants and triggers hold; never creates an engine session —
/// a new remote tab is a cold row (PLAN §7.4).
class SpacesApplier {
  SpacesApplier(this._ref);

  final Ref _ref;

  TabDatabase get _db => _ref.read(tabDatabaseProvider);
  ContainerRepository get _containers =>
      _ref.read(containerRepositoryProvider.notifier);
  SpaceRepository get _spaces => _ref.read(spaceRepositoryProvider.notifier);
  FolderRepository get _folders => _ref.read(folderRepositoryProvider.notifier);
  TabRepository get _tabs => _ref.read(tabRepositoryProvider.notifier);

  /// Applies [records]; returns the ids that failed (retried on a later
  /// sync). Every other id has its digest stored (Zen's `noteApplied`) so a
  /// faithful local materialisation produces no re-upload.
  ///
  /// [firstSync] only changes what is logged: the "first sync never deletes"
  /// rule (PLAN §8.6 item 4) is about outgoing tombstones and lives in the
  /// service; remote state is authoritative here either way.
  Future<Set<String>> applyBatch(
    List<ZenIncoming> records, {
    required bool firstSync,
  }) async {
    final incoming = _sort(records);
    logger.i(
      'spaces sync: incoming batch${firstSync ? ' (first sync)' : ''}: '
      '${incoming.containers.length} containers, '
      '${incoming.spaces.length} spaces, ${incoming.tabs.length} tabs, '
      '${incoming.folders.length} folders, ${incoming.splits.length} splits, '
      'layout=${incoming.layout != null}, ${incoming.deleted.length} '
      'tombstones, ${incoming.unknown.length} unknown',
    );

    final failed = <String>{};
    void fail(String id, Object error, [StackTrace? stackTrace]) {
      failed.add(id);
      logger.e(
        'spaces sync: failed to apply $id',
        error: error,
        stackTrace: stackTrace,
      );
    }

    for (final record in incoming.unknown) {
      try {
        await _db.syncStateDao.upsertForeign(
          record.id,
          kind: record.kind,
          payload: jsonEncode(record.rawData),
          modified: DateTime.now().millisecondsSinceEpoch / 1000,
        );
      } catch (e, s) {
        fail(record.id, e, s);
      }
    }

    final remainingTombstones = await _applyContainers(incoming, fail);
    final removals = await _routeTombstones(remainingTombstones);
    await _deleteTabs(removals.tabs, fail);
    await _deleteSplits(removals.splits, fail);
    await _applySpaces(incoming.spaces, fail);
    await _applyFolders(incoming.folders, fail);
    await _applyTabs(incoming.tabs, fail);
    await _applySplits(incoming.splits, fail);
    await _deleteFolders(removals.folders, fail);
    await _deleteSpaces(removals.spaces, fail);
    await _applyOrdering(incoming, fail);

    await _noteApplied(records, failed);
    return failed;
  }

  _Incoming _sort(List<ZenIncoming> records) {
    final incoming = _Incoming();
    for (final record in records) {
      switch (record) {
        case ZenIncomingTombstone(:final id):
          if (id != ZenLayoutRecord.recordIdLiteral) {
            incoming.deleted.add(id);
          }
        case ZenIncomingUnknownKind():
          incoming.unknown.add(record);
        case ZenIncomingRecord(:final cleartext):
          switch (cleartext.data) {
            case final ZenContainerRecord data:
              incoming.containers.add(_Entry(cleartext.id, data));
            case final ZenSpaceRecord data:
              incoming.spaces.add(_Entry(cleartext.id, data));
            case final ZenTabRecord data:
              incoming.tabs.add(_Entry(cleartext.id, data));
            case final ZenFolderRecord data:
              incoming.folders.add(_Entry(cleartext.id, data));
            case final ZenSplitRecord data:
              incoming.splits.add(_Entry(cleartext.id, data));
            case final ZenLayoutRecord data:
              incoming.layout = _Entry(cleartext.id, data);
            case ZenForeignRecord():
              // Never produced by the codec; nothing to apply.
              break;
          }
      }
    }
    return incoming;
  }

  /// A `containerGuid` → local container id: an existing row by guid, one
  /// of Firefox's built-ins created on first sight, or [UnknownContainerGuid].
  Future<String?> _resolveContainerId(String? guid) async {
    if (guid == null || guid.isEmpty) {
      return null;
    }
    final existing = await _containers.getBySyncGuid(guid);
    if (existing != null) {
      return existing.id;
    }
    if (ZenIds.isBuiltinContainerGuid(guid)) {
      return (await _containers.getOrCreateBuiltin(guid)).id;
    }
    throw UnknownContainerGuid(guid);
  }

  /* Mark: containers */

  Future<List<String>> _applyContainers(
    _Incoming incoming,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    for (final entry in incoming.containers) {
      final data = entry.data;
      try {
        if (data.name.isEmpty) {
          continue;
        }
        var existing = await _containers.getBySyncGuid(data.guid);
        if (existing == null && ZenIds.isBuiltinContainerGuid(data.guid)) {
          existing = await _containers.getOrCreateBuiltin(data.guid);
        }
        if (existing != null) {
          await _containers.replaceContainer(
            ContainerData(
              id: existing.id,
              syncGuid: existing.syncGuid,
              name: data.name,
              iconKey: data.icon,
              colorKey: data.color,
              orderKey: existing.orderKey,
              isPinned: existing.isPinned,
            ),
          );
        } else {
          await _containers.addContainer(
            ContainerData(
              id: uuid.v7(),
              syncGuid: data.guid,
              name: data.name,
              iconKey: data.icon,
              colorKey: data.color,
              orderKey: await _containers.getTrailingContainerOrderKey(
                isPinned: false,
              ),
            ),
          );
        }
      } catch (e, s) {
        fail(entry.id, e, s);
      }
    }

    final rest = <String>[];
    for (final id in incoming.deleted) {
      final container = await _containers.getBySyncGuid(id);
      if (container == null) {
        rest.add(id);
        continue;
      }
      try {
        // Tabs keep running: `container_id` is set NULL by the FK (W6.2 step
        // 3), so the DAO rather than the repository, which would close them.
        await _db.containerDao.deleteContainer(container.id);
      } catch (e, s) {
        fail(id, e, s);
      }
    }
    return rest;
  }

  /* Mark: tombstones */

  /// Whatever local thing owns the id decides what kind of deletion this is;
  /// ids with no local counterpart need no work.
  Future<_Removals> _routeTombstones(List<String> ids) async {
    final routed = _Removals();
    for (final id in ids) {
      if (await _db.tabDao.getTabSummaryById(id).getSingleOrNull() != null) {
        routed.tabs.add(id);
      } else if (await _db.tabFolderDao.getById(id).getSingleOrNull() != null) {
        routed.folders.add(id);
      } else if (await _db.tabSplitDao.getById(id).getSingleOrNull() != null) {
        routed.splits.add(id);
      } else if (await _db.spaceDao.getByUuid(id).getSingleOrNull() != null) {
        routed.spaces.add(id);
      }
    }
    return routed;
  }

  Future<void> _deleteTabs(
    List<String> ids,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    if (ids.isEmpty) {
      return;
    }
    try {
      await _tabs.closeTabsFromSync(ids);
    } catch (e, s) {
      for (final id in ids) {
        fail(id, e, s);
      }
    }
  }

  Future<void> _deleteSplits(
    List<String> ids,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    for (final id in ids) {
      try {
        await _db.tabSplitDao.deleteSplit(id);
      } catch (e, s) {
        fail(id, e, s);
      }
    }
  }

  /* Mark: spaces */

  Future<void> _applySpaces(
    List<_Entry<ZenSpaceRecord>> spaces,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    for (final entry in spaces) {
      final data = entry.data;
      try {
        final containerId = await _resolveContainerId(data.containerGuid);
        final current = await _spaces.getSpace(data.uuid);
        final fields = SpaceData(
          uuid: data.uuid,
          name: data.name,
          icon: data.icon,
          theme: data.theme == null ? null : jsonEncode(data.theme),
          containerId: containerId,
          orderIndex: current?.orderIndex ?? await _db.spaceDao.count(),
        );
        if (current == null) {
          await _db.spaceDao.insertSpace(fields);
        } else if (current != fields) {
          await _db.spaceDao.updateSpace(fields);
        }
      } catch (e, s) {
        fail(entry.id, e, s);
      }
    }
  }

  Future<void> _deleteSpaces(
    List<String> uuids,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    for (final uuid in uuids) {
      try {
        if (await _spaces.getSpace(uuid) == null) {
          continue;
        }
        if (await _db.spaceDao.count() <= 1) {
          // Never delete the last space; the local copy revives it remotely.
          logger.w('spaces sync: tombstone for the last space $uuid ignored');
          continue;
        }
        // The desktop already asked its user; here the deletion is applied.
        // Tabs go without a closed_tab_tombstone so they are not echoed back.
        final tabs = await _db.tabDao.getSpaceTabsData(uuid).get();
        if (tabs.isNotEmpty) {
          await _tabs.closeTabsFromSync([for (final tab in tabs) tab.id]);
        }
        await _spaces.deleteSpace(uuid);
      } catch (e, s) {
        fail(uuid, e, s);
      }
    }
  }

  /* Mark: folders */

  Future<void> _applyFolders(
    List<_Entry<ZenFolderRecord>> folders,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    // Parents before children so nesting targets exist.
    final parents = {for (final f in folders) f.id: f.data.parentFolderId};
    int depthOf(String id) {
      final seen = {id};
      var depth = 0;
      var parent = parents[id];
      while (parent != null &&
          parents.containsKey(parent) &&
          seen.add(parent)) {
        depth++;
        parent = parents[parent];
      }
      return depth;
    }

    final ordered = [...folders]
      ..sort((a, b) => depthOf(a.id).compareTo(depthOf(b.id)));

    for (final entry in ordered) {
      final data = entry.data;
      try {
        final current = await _folders.getFolder(data.folderId);
        final live = data.live == null ? null : jsonEncode(data.live);
        if (current == null) {
          final orderKey = await _db.tabFolderDao
              .trailingSlotKey(
                TabOrderScope.normal(
                  spaceUuid: data.workspaceUuid,
                  folderId: data.parentFolderId,
                ),
              )
              .getSingle();
          await _db.tabFolderDao.insertFolder(
            TabFolderData(
              id: data.folderId,
              name: data.name,
              icon: data.icon,
              spaceUuid: data.workspaceUuid,
              parentFolderId: data.parentFolderId,
              live: live,
              isCollapsed: true,
              orderKey: orderKey,
            ),
          );
          continue;
        }
        await _db.tabFolderDao.updateFolder(
          TabFolderData(
            id: current.id,
            name: data.name,
            icon: data.icon,
            spaceUuid: current.spaceUuid,
            parentFolderId: current.parentFolderId,
            live: live,
            isCollapsed: current.isCollapsed,
            orderKey: current.orderKey,
          ),
        );
        if (current.spaceUuid != data.workspaceUuid ||
            current.parentFolderId != data.parentFolderId) {
          final moved = await _db.tabFolderDao.setParent(
            current.id,
            spaceUuid: data.workspaceUuid,
            parentFolderId: data.parentFolderId,
            orderKey: current.orderKey,
          );
          if (!moved) {
            throw StateError(
              'folder ${data.folderId} cannot nest under '
              '${data.parentFolderId}',
            );
          }
        }
      } catch (e, s) {
        fail(entry.id, e, s);
      }
    }
  }

  Future<void> _deleteFolders(
    List<String> ids,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    for (final id in ids) {
      try {
        if (await _folders.getFolder(id) == null) {
          continue;
        }
        final tabIds = await _folders.tabIdsInFolder(id);
        if (tabIds.isNotEmpty) {
          await _tabs.closeTabsFromSync(tabIds);
        }
        await _folders.deleteFolder(id);
      } catch (e, s) {
        fail(id, e, s);
      }
    }
  }

  /* Mark: tabs */

  Future<void> _applyTabs(
    List<_Entry<ZenTabRecord>> tabs,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    for (final entry in tabs) {
      final data = entry.data;
      try {
        if (data.url.isEmpty || data.url == 'about:blank') {
          continue;
        }
        final existing = await _db.tabDao
            .getTabSummaryById(entry.id)
            .getSingleOrNull();
        if (existing != null) {
          await _updateTab(existing, data);
        } else {
          await _createTab(entry.id, data);
        }
      } catch (e, s) {
        fail(entry.id, e, s);
      }
    }
  }

  /// The decode rule: `essential` first, then `pinned` (PLAN §4.2).
  static TabShelf _shelfOf(ZenTabRecord data) => data.essential
      ? TabShelf.essential
      : data.pinned
      ? TabShelf.pinned
      : TabShelf.normal;

  /// Where the record puts the tab. Essentials have no space or folder (I1);
  /// a regular tab without a `workspaceUuid` lands in the default space (I2)
  /// and re-uploads with it, the way Zen's `noteApplied` self-heals.
  Future<({String? spaceUuid, String? folderId, TabOrderScope scope})>
  _placementOf(ZenTabRecord data, String? containerId) async {
    final shelf = _shelfOf(data);
    if (shelf == TabShelf.essential) {
      return (
        spaceUuid: null,
        folderId: null,
        scope: TabOrderScope.essential(containerId),
      );
    }
    var spaceUuid = data.workspaceUuid;
    if (spaceUuid == null || await _spaces.getSpace(spaceUuid) == null) {
      logger.w(
        'spaces sync: tab ${data.tabId} names no known space '
        '(${data.workspaceUuid}); placing it in the default space',
      );
      spaceUuid = (await _spaces.ensureDefaultSpace()).uuid;
    }
    if (shelf == TabShelf.pinned) {
      return (
        spaceUuid: spaceUuid,
        folderId: null,
        scope: TabOrderScope.pinned(spaceUuid),
      );
    }
    final folderId = data.folderId;
    if (folderId != null) {
      final folder = await _folders.getFolder(folderId);
      if (folder == null) {
        throw UnknownFolder(folderId);
      }
      // The folder's space wins, as it does for a local move.
      spaceUuid = folder.spaceUuid ?? spaceUuid;
    }
    return (
      spaceUuid: spaceUuid,
      folderId: folderId,
      scope: TabOrderScope.normal(spaceUuid: spaceUuid, folderId: folderId),
    );
  }

  Future<void> _createTab(String tabId, ZenTabRecord data) async {
    final containerId = await _resolveContainerId(data.containerGuid);
    final placement = await _placementOf(data, containerId);
    final icon = syncableIconUrl(data.icon);
    logger.i(
      'spaces sync: creating cold tab $tabId (essential=${data.essential}, '
      'container=$containerId) ${data.url}',
    );
    await _db.tabDao.insertColdTab(
      id: tabId,
      url: Uri.tryParse(data.url),
      title: data.title,
      iconUrl: icon.isEmpty ? null : icon,
      containerId: containerId,
      spaceUuid: placement.spaceUuid,
      folderId: placement.folderId,
      shelf: _shelfOf(data),
      staticLabel: data.staticLabel,
      hasStaticIcon: data.hasStaticIcon,
      defaultContainer: data.defaultContainer,
    );
  }

  Future<void> _updateTab(TabSummary tab, ZenTabRecord data) async {
    final containerId = await _resolveContainerId(data.containerGuid);
    final placement = await _placementOf(data, containerId);
    final icon = syncableIconUrl(data.icon);

    // A pinned/essential tab's identity is frozen at pin time on the
    // desktop, and a cold tab has no live state to lose; a live normal tab
    // keeps its live url (Zen's `#retargetUnloadedTab` only touches unloaded
    // tabs).
    final urlDiffers = (tab.url?.toString() ?? '') != data.url;
    final titleDiffers = (tab.title ?? '') != data.title;
    final identityFrozen = tab.isCold || tab.tabShelf != TabShelf.normal;
    final retarget = identityFrozen && (urlDiffers || titleDiffers);

    await _db.tabDao.updateTabFromSync(
      tab.id,
      url: retarget ? Value(Uri.tryParse(data.url)) : const Value.absent(),
      title: retarget ? Value(data.title) : const Value.absent(),
      iconUrl: icon.isEmpty ? const Value.absent() : Value(icon),
      containerId: Value(containerId),
      staticLabel: Value(data.staticLabel),
      hasStaticIcon: Value(data.hasStaticIcon),
      defaultContainer: Value(data.defaultContainer),
    );

    if (tab.splitId != null && !data.essential) {
      // The split record governs placement of its members.
      return;
    }
    final currentScope = TabOrderScope.forTab(tab);
    if (currentScope != placement.scope) {
      if (data.essential && tab.tabShelf != TabShelf.essential) {
        logger.i(
          'spaces sync: incoming record promotes tab ${tab.id} to essential',
        );
      } else if (!data.essential && tab.tabShelf == TabShelf.essential) {
        logger.w(
          'spaces sync: incoming record demotes essential tab ${tab.id}',
        );
      }
      await _db.tabDao.moveToScope([tab.id], placement.scope);
    }
  }

  /* Mark: splits */

  Future<void> _applySplits(
    List<_Entry<ZenSplitRecord>> splits,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    for (final entry in splits) {
      final data = entry.data;
      try {
        final members = <String>[];
        for (final tabId in data.tabs) {
          if (await _db.tabDao.getTabSummaryById(tabId).getSingleOrNull() !=
              null) {
            members.add(tabId);
          }
        }
        final existing = await _db.tabSplitDao
            .getById(data.splitId)
            .getSingleOrNull();
        if (members.length < 2) {
          if (existing != null) {
            await _db.tabSplitDao.deleteSplit(existing.id);
          }
          continue;
        }
        final scope = data.pinned && data.workspaceUuid != null
            ? TabOrderScope.pinned(data.workspaceUuid!)
            : TabOrderScope.normal(
                spaceUuid: data.workspaceUuid,
                folderId: data.folderId,
              );
        final split = TabSplitData(
          id: data.splitId,
          gridType: data.gridType,
          isPinned: data.pinned,
          spaceUuid: data.workspaceUuid,
          folderId: data.folderId,
          orderKey:
              existing?.orderKey ??
              await _db.tabFolderDao.trailingSlotKey(scope).getSingle(),
        );
        if (existing == null) {
          await _db.tabSplitDao.insertSplit(split);
        } else {
          await _db.tabSplitDao.updateSplit(split);
        }
        await _db.tabSplitDao.setMembers(data.splitId, members);
      } catch (e, s) {
        fail(entry.id, e, s);
      }
    }
  }

  /* Mark: ordering */

  Future<void> _applyOrdering(
    _Incoming incoming,
    void Function(String id, Object error, [StackTrace? stackTrace]) fail,
  ) async {
    for (final entry in incoming.spaces) {
      if (entry.data.children.isEmpty) {
        continue;
      }
      try {
        await _db.tabDao.applyScopeOrder(
          TabOrderScope.normal(spaceUuid: entry.data.uuid),
          entry.data.children,
        );
      } catch (e, s) {
        fail(entry.id, e, s);
      }
    }
    for (final entry in incoming.folders) {
      if (entry.data.children.isEmpty) {
        continue;
      }
      try {
        final folder = await _folders.getFolder(entry.data.folderId);
        if (folder == null) {
          continue;
        }
        await _db.tabDao.applyScopeOrder(
          TabOrderScope.normal(
            spaceUuid: folder.spaceUuid,
            folderId: folder.id,
          ),
          entry.data.children,
        );
      } catch (e, s) {
        fail(entry.id, e, s);
      }
    }

    final layout = incoming.layout;
    if (layout == null) {
      return;
    }
    try {
      for (final group in layout.data.essentials.entries) {
        if (group.value.length < 2) {
          continue;
        }
        final String? containerId;
        if (group.key == 'default') {
          containerId = null;
        } else {
          try {
            containerId = await _resolveContainerId(group.key);
          } on UnknownContainerGuid {
            logger.w(
              'spaces sync: layout names essentials of unknown container '
              '${group.key}; skipped',
            );
            continue;
          }
        }
        await _db.tabDao.applyScopeOrder(
          TabOrderScope.essential(containerId),
          group.value,
        );
      }
      if (layout.data.spaces.length > 1) {
        final current = await _spaces.getAllSpaces();
        final byUuid = {for (final space in current) space.uuid: space.uuid};
        final ordered = [
          for (final uuid in layout.data.spaces)
            if (byUuid.containsKey(uuid)) uuid,
        ];
        for (final space in current) {
          if (!ordered.contains(space.uuid)) {
            ordered.add(space.uuid);
          }
        }
        final changed = [
          for (var i = 0; i < current.length; i++)
            if (current[i].uuid != ordered[i]) true,
        ].isNotEmpty;
        if (changed) {
          await _spaces.reorderSpaces(ordered);
        }
      }
    } catch (e, s) {
      fail(layout.id, e, s);
    }
  }

  /* Mark: bookkeeping */

  /// Zen's `noteApplied`: the incoming payload's digest becomes the uploaded
  /// state; tombstones drop it and settle any local deletion note.
  Future<void> _noteApplied(
    List<ZenIncoming> records,
    Set<String> failed,
  ) async {
    final dao = _db.syncStateDao;
    for (final record in records) {
      switch (record) {
        case ZenIncomingTombstone(:final id):
          if (failed.contains(id)) continue;
          await dao.deleteDigest(id);
          await dao.deleteForeign(id);
          await dao.clearDeletions([id]);
        case ZenIncomingUnknownKind(:final id, :final kind, :final rawData):
          if (failed.contains(id)) continue;
          if (rawData is Map) {
            await dao.putDigest(
              id,
              kind,
              recordDigest(kind, rawData.cast<String, Object?>()),
            );
          }
        case ZenIncomingRecord(:final cleartext):
          if (failed.contains(cleartext.id)) continue;
          await dao.putDigest(
            cleartext.id,
            cleartext.kind,
            recordDigest(cleartext.kind, cleartext.data.toJson()),
          );
          await dao.clearDeletions([cleartext.id]);
      }
    }
  }
}

@Riverpod(keepAlive: true)
SpacesApplier spacesApplier(Ref ref) => SpacesApplier(ref);
