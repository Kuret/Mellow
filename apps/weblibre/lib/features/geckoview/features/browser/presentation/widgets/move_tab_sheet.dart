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
import 'package:fading_scroll/fading_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_order_scope.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/entities/folder_tree.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/folder.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_icon.dart';

/// Shows the "move tab" picker: pin the tab at the root of a space, or file
/// it into one of that space's folders (however deeply nested), for the
/// tab's own space and for every other space — in one sheet, one action.
///
/// Picking a folder that belongs to another space moves the tab there too:
/// [TabDataRepository.moveTabToFolder] takes its target space from the
/// folder itself, so a single call does the whole job.
Future<void> showMoveTabSheet(
  BuildContext context, {
  required String tabId,
  required String? currentSpaceUuid,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _MoveTabSheet(tabId: tabId, currentSpaceUuid: currentSpaceUuid),
  );
}

/// Sentinel used only as a widget key suffix so tests can tell sections
/// apart without depending on translated copy.
const currentSpaceSectionLabel = 'This space';

class _MoveTabSheet extends ConsumerWidget {
  final String tabId;
  final String? currentSpaceUuid;

  const _MoveTabSheet({required this.tabId, required this.currentSpaceUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces =
        ref.watch(watchSpacesProvider).value ?? const <SpaceData>[];
    final otherSpaces = spaces
        .where((space) => space.uuid != currentSpaceUuid)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Move tab',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: FadingScroll(
                fadingSize: 25,
                builder: (context, controller) => SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SpaceSection(
                        tabId: tabId,
                        spaceUuid: currentSpaceUuid,
                        label: currentSpaceSectionLabel,
                        icon: null,
                        isCurrentSpace: true,
                      ),
                      for (final space in otherSpaces)
                        _SpaceSection(
                          tabId: tabId,
                          spaceUuid: space.uuid,
                          label: space.name.isEmpty ? 'Space' : space.name,
                          icon: space.icon,
                          isCurrentSpace: false,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SpaceSection extends ConsumerWidget {
  final String tabId;
  final String? spaceUuid;
  final String label;
  final String? icon;
  final bool isCurrentSpace;

  const _SpaceSection({
    required this.tabId,
    required this.spaceUuid,
    required this.label,
    required this.icon,
    required this.isCurrentSpace,
  });

  Future<void> _pinHere(WidgetRef ref) {
    if (isCurrentSpace) {
      // Mirrors the top-level "Pin tab" item: setShelf keeps the tab's own
      // space when it has one, and only falls back to the active space
      // otherwise.
      return ref
          .read(tabDataRepositoryProvider.notifier)
          .setShelf(
            tabId,
            TabShelf.pinned,
            activeSpaceUuid: ref.read(selectedSpaceProvider),
          )
          .then((_) {});
    }
    // A different space: name it explicitly rather than relying on the
    // tab's current space, which setShelf would otherwise keep.
    return ref
        .read(tabDataRepositoryProvider.notifier)
        .moveToScope([tabId], TabOrderScope.pinned(spaceUuid!));
  }

  Future<void> _moveToFolder(WidgetRef ref, String folderId) {
    return ref
        .read(tabDataRepositoryProvider.notifier)
        .moveTabToFolder(tabId, folderId);
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final currentSpaceUuid = spaceUuid;
    if (currentSpaceUuid == null) return;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null) return;

    final folder = await ref
        .read(folderRepositoryProvider.notifier)
        .createFolder(currentSpaceUuid, name: name.isEmpty ? 'Folder' : name);
    await _moveToFolder(ref, folder.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders =
        ref.watch(watchFoldersProvider(spaceUuid)).value ??
        const <TabFolderData>[];
    final rows = buildFolderTree(folders);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              if (!isCurrentSpace) ...[
                SpaceIcon(icon: icon, size: 16),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          key: ValueKey('move-tab-pin-${spaceUuid ?? 'none'}'),
          dense: true,
          leading: const Icon(MdiIcons.pin),
          title: const Text('Pin tab'),
          onTap: () async {
            await _pinHere(ref);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        for (final row in rows)
          ListTile(
            key: ValueKey('move-tab-folder-${row.folder.id}'),
            dense: true,
            contentPadding: EdgeInsetsDirectional.only(
              start: 16 + (row.depth * 20),
              end: 16,
            ),
            leading: const Icon(MdiIcons.folderOutline),
            title: Text(row.folder.name.isEmpty ? 'Folder' : row.folder.name),
            subtitle: row.path.isEmpty ? null : Text(row.path),
            onTap: () async {
              await _moveToFolder(ref, row.folder.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        if (isCurrentSpace)
          ListTile(
            dense: true,
            leading: const Icon(MdiIcons.folderPlusOutline),
            title: const Text('New folder…'),
            onTap: () => _createFolder(context, ref),
          ),
      ],
    );
  }
}
