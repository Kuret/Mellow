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
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/space.dart';

/// A horizontal row of switch chips, one per [SpaceData], replacing the old
/// per-container chip row now that the tab list is scoped by space rather
/// than by container.
///
/// Deliberately plain — a later workstream restyles this row. Tapping a chip
/// selects that space; long-pressing opens a menu to rename the space,
/// change its container, or delete it. A trailing "+" chip creates a new
/// space and selects it.
class SpaceChips extends ConsumerWidget {
  const SpaceChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces =
        ref.watch(watchSpacesProvider.select((value) => value.value)) ??
        const <SpaceData>[];
    final selectedSpaceUuid = ref.watch(selectedSpaceProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final space in spaces) ...[
            _SpaceChip(space: space, selected: space.uuid == selectedSpaceUuid),
            const SizedBox(width: 8),
          ],
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('New space'),
            onPressed: () async {
              final created = await ref
                  .read(spaceRepositoryProvider.notifier)
                  .createSpace();
              ref.read(selectedSpaceProvider.notifier).setSpace(created.uuid);
            },
          ),
        ],
      ),
    );
  }
}

class _SpaceChip extends ConsumerWidget {
  final SpaceData space;
  final bool selected;

  const _SpaceChip({required this.space, required this.selected});

  String get _displayName => space.name.isEmpty ? 'Space' : space.name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _openMenu(context, ref),
      child: ChoiceChip(
        avatar: Icon(MdiIcons.viewDashboardOutline, size: 18),
        label: Text(_displayName),
        selected: selected,
        onSelected: (value) {
          if (value) {
            ref.read(selectedSpaceProvider.notifier).setSpace(space.uuid);
          }
        },
      ),
    );
  }

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    final spaceCount = ref.read(watchSpacesProvider).value?.length ?? 1;
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final position = box != null && overlay != null
        ? RelativeRect.fromRect(
            Rect.fromPoints(
              box.localToGlobal(Offset.zero, ancestor: overlay),
              box.localToGlobal(
                box.size.bottomRight(Offset.zero),
                ancestor: overlay,
              ),
            ),
            Offset.zero & overlay.size,
          )
        : const RelativeRect.fromLTRB(0, 0, 0, 0);

    final action = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem<String>(value: 'rename', child: Text('Rename')),
        PopupMenuItem<String>(value: 'container', child: Text('Set container')),
        PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
      ],
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case 'rename':
        await _showRenameDialog(context, ref);
      case 'container':
        await _showContainerPickerDialog(context, ref);
      case 'delete':
        if (spaceCount <= 1) {
          return;
        }
        await _showDeleteConfirmation(context, ref);
    }
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: space.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename space'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null) {
      await ref
          .read(spaceRepositoryProvider.notifier)
          .renameSpace(space.uuid, newName);
    }
  }

  Future<void> _showContainerPickerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final containers =
        ref.read(watchContainersWithCountProvider).value ?? const [];

    // Wrapped so a dismissed dialog (null) is distinguishable from
    // explicitly picking "No container" (a pick whose containerId is null).
    final pick = await showDialog<_ContainerPick>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Set container'),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(context).pop(const _ContainerPick(null)),
            child: const Text('No container'),
          ),
          for (final container in containers)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(context).pop(_ContainerPick(container.id)),
              child: Text(container.name),
            ),
        ],
      ),
    );

    if (pick != null) {
      await ref
          .read(spaceRepositoryProvider.notifier)
          .setSpaceContainer(space.uuid, pick.containerId);
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final tabCount = await ref
        .read(spaceRepositoryProvider.notifier)
        .countTabsInSpace(space.uuid);

    if (!context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete \'$_displayName\'?'),
        content: Text('$tabCount tabs will be closed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(spaceRepositoryProvider.notifier).deleteSpace(space.uuid);
    } on StateError {
      // The last remaining space can't be deleted; nothing to do here, the
      // menu already hides delete once only one space is left, but the
      // count could have changed between opening the menu and confirming.
    }
  }
}

/// A confirmed container choice from the "Set container" dialog, wrapping a
/// nullable containerId so it can be told apart from a dismissed dialog.
class _ContainerPick {
  final String? containerId;

  const _ContainerPick(this.containerId);
}
