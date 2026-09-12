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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_local_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/controllers/container_topic.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/dialogs/discard_changes_dialog.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/utils/container_actions.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/color_picker_dialog.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/container_icon_picker_sheet.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/container_colors.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/firefox_container_vocab.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/wallpaper/domain/entities/wallpaper_override.dart';
import 'package:weblibre/features/wallpaper/presentation/widgets/wallpaper_editor.dart';

enum _DialogMode { create, edit }

class ContainerEditScreen extends HookConsumerWidget {
  final _DialogMode _mode;

  final ContainerData initialContainer;
  final Set<String>? tabIds;

  const ContainerEditScreen._({
    required _DialogMode mode,
    required this.initialContainer,
    this.tabIds,
  }) : _mode = mode;

  factory ContainerEditScreen.create({
    required ContainerData initialContainer,
    Set<String>? tabIds,
  }) {
    return ContainerEditScreen._(
      mode: _DialogMode.create,
      initialContainer: initialContainer,
      tabIds: tabIds,
    );
  }

  factory ContainerEditScreen.edit({
    required ContainerDataWithCount initialContainer,
  }) {
    return ContainerEditScreen._(
      mode: _DialogMode.edit,
      initialContainer: initialContainer,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final colorKey = useState(initialContainer.colorKey);
    final iconKey = useState(initialContainer.iconKey);
    final isPinned = useState(initialContainer.isPinned);

    // The local, never-synced half of the container: privacy flags and the
    // wallpaper override. A new container starts from the defaults; an
    // existing one loads its row once and edits a copy of it.
    final initialLocal = useState(
      ContainerLocalData.defaults(initialContainer.id),
    );
    final local = useState(initialLocal.value);
    useEffect(() {
      if (_mode != _DialogMode.edit) return null;
      var cancelled = false;
      unawaited(
        ref
            .read(containerRepositoryProvider.notifier)
            .getLocal(initialContainer.id)
            .then((ContainerLocalData loaded) {
              if (cancelled) return;
              initialLocal.value = loaded;
              local.value = loaded;
            }),
      );
      return () => cancelled = true;
    }, [initialContainer.id]);

    final textController = useTextEditingController(
      text: initialContainer.name,
    );
    useListenable(textController);

    ContainerData buildContainer() {
      return initialContainer.copyWith(
        name: textController.text.trim(),
        colorKey: colorKey.value,
        iconKey: iconKey.value,
        isPinned: isPinned.value,
      );
    }

    Future<ContainerData> saveContainer() async {
      final container = buildContainer();
      final repository = ref.read(containerRepositoryProvider.notifier);
      switch (_mode) {
        case _DialogMode.create:
          await repository.addContainer(container);
        case _DialogMode.edit:
          await repository.replaceContainer(container);
      }
      if (isPinned.value != initialContainer.isPinned) {
        await repository.setContainerPinned(
          container.id,
          isPinned: isPinned.value,
        );
      }
      await repository.setLocal(
        local.value.copyWith(containerId: container.id),
      );
      return container;
    }

    Future<void> saveAndClose() async {
      final container = await saveContainer();
      if (context.mounted) {
        context.pop(container);
      }
    }

    Future<void> openColorPicker() async {
      final result = await showDialog<String?>(
        context: context,
        builder: (context) =>
            FirefoxContainerColorPicker(initialColorKey: colorKey.value),
      );

      if (result != null) {
        colorKey.value = result;
      }
    }

    Color seedColor() =>
        FirefoxContainerColor.fromKeyword(colorKey.value).color ??
        colorScheme.primary;

    Future<void> openIconPicker() async {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => FirefoxContainerIconPicker(
          accentColor: seedColor(),
          selectedIconKey: iconKey.value,
          onSelected: (key) => Navigator.of(context).pop(key),
        ),
      );

      if (result != null) {
        iconKey.value = result;
      }
    }

    Future<void> openAppearanceMenu() async {
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Change Color'),
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(openColorPicker());
                  },
                ),
                ListTile(
                  leading: Icon(
                    FirefoxContainerIcon.fromKeyword(iconKey.value).icon,
                  ),
                  title: const Text('Change Icon'),
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(openIconPicker());
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }

    Future<void> deleteContainer() async {
      final deleted = await confirmAndDeleteContainer(
        context,
        ref,
        initialContainer,
      );

      if (deleted && context.mounted) {
        context.pop();
      }
    }

    final container = buildContainer();
    //Empty copy to create comparable container with same type
    final comparison = initialContainer.copyWith();
    final isDirty =
        container != comparison || local.value != initialLocal.value;
    final previewIcon = FirefoxContainerIcon.fromKeyword(iconKey.value).icon;
    final previewPalette = ContainerColors.palette(context, seedColor());
    final wallpaper = WallpaperOverride.fromStored(local.value.wallpaper);

    void setWallpaper(WallpaperOverride? override) {
      local.value = local.value.copyWith(wallpaper: override?.toStored());
    }

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
          title: Text(switch (_mode) {
            _DialogMode.create => 'New Container',
            _DialogMode.edit => 'Edit Container',
          }),
          actions: [
            IconButton(onPressed: saveAndClose, icon: const Icon(Icons.check)),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: openAppearanceMenu,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                AnimatedContainer(
                                  duration: disableAnimations
                                      ? Duration.zero
                                      : const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: previewPalette.avatarBackgroundColor,
                                    border: Border.all(
                                      color: previewPalette.outlineColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    previewIcon,
                                    color: previewPalette.avatarForegroundColor,
                                    size: 34,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextField(
                              controller: textController,
                              style: theme.textTheme.titleLarge,
                              decoration: InputDecoration(
                                hintText: 'Container Name',
                                border: InputBorder.none,
                                suffixIcon: _buildMagicWandButton(
                                  context,
                                  ref,
                                  textController,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Display',
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
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: isPinned.value,
                          title: const Text('Pin Container'),
                          subtitle: const Text(
                            'Keep this container at the top of the list',
                          ),
                          secondary: const Icon(MdiIcons.pin),
                          onChanged: (value) {
                            isPinned.value = value;
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        // Collapsed by default: most containers use the
                        // profile's wallpaper, and an always-open picker with a
                        // preview would push the rest of this form off screen.
                        ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: const Icon(MdiIcons.imageOutline),
                          title: const Text('Wallpaper'),
                          subtitle: Text(
                            wallpaper != null
                                ? 'Shown on home while this container is '
                                      'selected'
                                : 'Uses the wallpaper from settings',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              // The inherited treatment is read here rather
                              // than in the screen's build: a collapsed
                              // ExpansionTile never builds its body, so a form
                              // whose wallpaper section is untouched does not
                              // open the settings database at all.
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final settings = ref.watch(
                                    generalSettingsWithDefaultsProvider,
                                  );

                                  return WallpaperEditor(
                                    fileName: wallpaper?.file,
                                    blur:
                                        wallpaper?.blur ??
                                        settings.homeWallpaperBlur,
                                    dim:
                                        wallpaper?.dim ??
                                        settings.homeWallpaperDim,
                                    emptyDescription:
                                        'This container falls back to the '
                                        'wallpaper set in settings.',
                                    // Replacing the picture keeps the
                                    // treatment; removing it drops the whole
                                    // override, so a later pick starts from
                                    // whatever the profile does now rather
                                    // than from a setting made months ago.
                                    onFileChanged: (fileName) => setWallpaper(
                                      fileName == null
                                          ? null
                                          : WallpaperOverride(
                                              file: fileName,
                                              blur: wallpaper?.blur,
                                              dim: wallpaper?.dim,
                                            ),
                                    ),
                                    // The sliders are disabled without a
                                    // wallpaper, so there is always an
                                    // override to amend here.
                                    onBlurChanged: (value) => setWallpaper(
                                      wallpaper?.copyWith(blur: value),
                                    ),
                                    onDimChanged: (value) => setWallpaper(
                                      wallpaper?.copyWith(dim: value),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Privacy & Security',
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
                    child: Column(
                      children: [
                        // Isolation is intrinsic: the container id is its
                        // Gecko cookie jar, so there is nothing to switch.
                        const ListTile(
                          leading: Icon(MdiIcons.cookieLock),
                          title: Text('Cookie Isolation'),
                          subtitle: Text(
                            'Every container keeps its own cookies and site '
                            'data, separate from other containers.',
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile.adaptive(
                          value: local.value.clearDataOnExit,
                          title: const Text('Clear Data on Exit'),
                          subtitle: const Text(
                            "Clear cookies and site data for this container's "
                            'regular tabs when the app closes. Private tabs '
                            'keep separate data.',
                          ),
                          secondary: const Icon(MdiIcons.databaseRemove),
                          onChanged: (value) {
                            local.value = local.value.copyWith(
                              clearDataOnExit: value,
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile.adaptive(
                          value: local.value.excludeFromIndex,
                          title: const Text('Exclude from Search Index'),
                          subtitle: const Text(
                            'Skip pages in this container from the local search index',
                          ),
                          secondary: const Icon(MdiIcons.magnifyRemoveOutline),
                          onChanged: (value) {
                            local.value = local.value.copyWith(
                              excludeFromIndex: value,
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile.adaptive(
                          value: local.value.excludeFromHistory,
                          title: const Text('Exclude from History'),
                          subtitle: const Text(
                            "Don't record new visits from this container's "
                            'tabs, and drop its pages from local search. '
                            'Existing browsing history is kept.',
                          ),
                          secondary: const Icon(MdiIcons.incognito),
                          onChanged: (value) {
                            local.value = local.value.copyWith(
                              excludeFromHistory: value,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_mode == _DialogMode.edit)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.tonalIcon(
                      onPressed: deleteContainer,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Container'),
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

  Widget? _buildMagicWandButton(
    BuildContext context,
    WidgetRef ref,
    TextEditingController textController,
  ) {
    final predict = switch (_mode) {
      _DialogMode.edit => switch (initialContainer) {
        ContainerDataWithCount(:final tabCount?) when tabCount > 0 =>
          (WidgetRef ref) => ref
              .read(containerTopicControllerProvider.notifier)
              .predictDocumentTopic(initialContainer.id),
        _ => null,
      },
      _DialogMode.create => switch (tabIds) {
        final ids? when ids.isNotEmpty =>
          (WidgetRef ref) => ref
              .read(containerTopicControllerProvider.notifier)
              .predictTopicFromTabIds(ids),
        _ => null,
      },
    };

    if (predict == null) return null;

    return Consumer(
      builder: (context, ref, child) {
        final isLoading = ref.watch(
          containerTopicControllerProvider.select((value) => value.isLoading),
        );

        return IconButton(
          onPressed: isLoading
              ? null
              : () async {
                  final topic = await predict(ref);
                  if (topic != null) {
                    textController.text = topic;
                  }
                },
          icon: const Icon(MdiIcons.creation),
        );
      },
    );
  }
}
