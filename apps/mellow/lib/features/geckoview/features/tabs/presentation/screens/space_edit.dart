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
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/space.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/dialogs/discard_changes_dialog.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/container_chip_content.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/container_title.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/space_icon.dart';

enum _DialogMode { create, edit }

/// Create/edit form for a space (Zen workspace, PLAN §6.3), modelled on
/// `ContainerEditScreen`: name, icon and default container, with delete for
/// an existing space that is not the last one.
class SpaceEditScreen extends ConsumerWidget {
  final _DialogMode _mode;

  /// The space being edited; `null` when creating.
  final String? uuid;

  const SpaceEditScreen.create({super.key})
    : _mode = _DialogMode.create,
      uuid = null;

  const SpaceEditScreen.edit({super.key, required String this.uuid})
    : _mode = _DialogMode.edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_mode == _DialogMode.create) {
      return const _SpaceForm(mode: _DialogMode.create, initial: null);
    }

    final spaces = ref.watch(watchSpacesProvider);
    final space = spaces.value?.firstWhereOrNull((s) => s.uuid == uuid);

    if (spaces.value == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (space == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Space')),
        body: const Center(child: Text('This space no longer exists.')),
      );
    }

    // Keyed on the uuid so a live rename from elsewhere does not clobber the
    // text the user is typing: the form takes its initial values once.
    return _SpaceForm(
      key: ValueKey(space.uuid),
      mode: _DialogMode.edit,
      initial: space,
    );
  }
}

class _SpaceForm extends HookConsumerWidget {
  final _DialogMode mode;
  final SpaceData? initial;

  const _SpaceForm({super.key, required this.mode, required this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final nameController = useTextEditingController(text: initial?.name ?? '');
    final iconController = useTextEditingController(text: initial?.icon ?? '');
    useListenable(nameController);
    useListenable(iconController);
    final containerId = useState<String?>(initial?.containerId);

    final containers =
        ref.watch(
          watchContainersWithCountProvider.select((value) => value.value),
        ) ??
        const <ContainerDataWithCount>[];
    final spaceCount = ref.watch(
      watchSpacesProvider.select((value) => value.value?.length ?? 1),
    );

    String name() => nameController.text.trim();
    String? icon() {
      final text = iconController.text.trim();
      return text.isEmpty ? null : text;
    }

    final isDirty = switch (mode) {
      _DialogMode.create =>
        name().isNotEmpty || icon() != null || containerId.value != null,
      _DialogMode.edit =>
        name() != initial!.name ||
            icon() != initial!.icon ||
            containerId.value != initial!.containerId,
    };

    Future<void> save() async {
      final repository = ref.read(spaceRepositoryProvider.notifier);
      switch (mode) {
        case _DialogMode.create:
          final created = await repository.createSpace(
            name: name(),
            icon: icon(),
            containerId: containerId.value,
          );
          ref.read(selectedSpaceProvider.notifier).space = created.uuid;
        case _DialogMode.edit:
          final space = initial!;
          if (name() != space.name) {
            await repository.renameSpace(space.uuid, name());
          }
          if (icon() != space.icon) {
            await repository.setSpaceIcon(space.uuid, icon());
          }
          if (containerId.value != space.containerId) {
            await repository.setSpaceContainer(space.uuid, containerId.value);
          }
      }
    }

    Future<void> saveAndClose() async {
      await save();
      if (context.mounted) {
        context.pop();
      }
    }

    Future<void> deleteSpace() async {
      final space = initial!;
      final repository = ref.read(spaceRepositoryProvider.notifier);
      final tabCount = await repository.countTabsInSpace(space.uuid);
      if (!context.mounted) return;

      final displayName = space.name.isEmpty ? 'Space' : space.name;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text("Delete '$displayName'?"),
          content: Text(
            '$tabCount ${tabCount == 1 ? 'tab' : 'tabs'} will be closed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      await repository.deleteSpace(space.uuid);
      if (context.mounted) {
        context.pop();
      }
    }

    final canDelete = mode == _DialogMode.edit && spaceCount > 1;

    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final choice = await showDiscardChangesDialog(context);
        if (choice == null) return;

        switch (choice) {
          case DiscardChangesChoice.discard:
            if (context.mounted) {
              context.pop();
            }
          case DiscardChangesChoice.save:
            await saveAndClose();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(switch (mode) {
            _DialogMode.create => 'New Space',
            _DialogMode.edit => 'Edit Space',
          }),
          actions: [
            IconButton(
              tooltip: 'Save',
              icon: const Icon(Icons.check),
              onPressed: saveAndClose,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SpaceIconAvatar(icon: icon(), radius: 28),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              style: theme.textTheme.titleLarge,
                              decoration: const InputDecoration(
                                hintText: 'Space Name',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Icon',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: colorScheme.surfaceContainer,
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: const Icon(MdiIcons.emoticonOutline),
                      title: TextField(
                        controller: iconController,
                        // Zen stores a free string here: an emoji, a short
                        // label or nothing at all.
                        maxLength: 8,
                        decoration: const InputDecoration(
                          hintText: 'Emoji or short text',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                      subtitle: const Text(
                        'Shown on the space chip; leave empty for the default',
                      ),
                      trailing: icon() == null
                          ? null
                          : IconButton(
                              tooltip: 'Clear icon',
                              icon: const Icon(Icons.clear),
                              onPressed: iconController.clear,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Default Container',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New tabs in this space open in this container. The '
                    'Essentials strip follows it too.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: colorScheme.surfaceContainer,
                    clipBehavior: Clip.antiAlias,
                    child: RadioGroup<String?>(
                      groupValue: containerId.value,
                      onChanged: (value) => containerId.value = value,
                      child: Column(
                        children: [
                          const RadioListTile<String?>.adaptive(
                            value: null,
                            title: Text('None'),
                            subtitle: Text('Tabs open without a container'),
                            secondary: Icon(MdiIcons.folderOffOutline),
                          ),
                          for (final container in containers) ...[
                            const Divider(height: 1, indent: 56),
                            _ContainerOption(container: container),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (mode == _DialogMode.edit)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.tonalIcon(
                      onPressed: canDelete ? deleteSpace : null,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        canDelete
                            ? 'Delete Space'
                            : 'The last space cannot be deleted',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContainerOption extends StatelessWidget {
  final ContainerDataWithCount container;

  const _ContainerOption({required this.container});

  @override
  Widget build(BuildContext context) {
    final palette = containerPalette(context, container);
    final tabCount = container.tabCount ?? 0;

    return RadioListTile<String?>.adaptive(
      value: container.id,
      title: ContainerTitle(container: container),
      subtitle: Text('$tabCount ${tabCount == 1 ? 'tab' : 'tabs'}'),
      secondary: CircleAvatar(
        radius: 18,
        backgroundColor: palette.avatarBackgroundColor,
        foregroundColor: palette.avatarForegroundColor,
        child: Icon(container.icon.icon, size: 18),
      ),
    );
  }
}
