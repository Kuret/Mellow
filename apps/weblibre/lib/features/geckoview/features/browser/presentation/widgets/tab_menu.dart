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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/core/design/app_colors.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/domain/controllers/bottom_sheet.dart';
import 'package:weblibre/features/geckoview/domain/entities/tab_container_selection.dart';
import 'package:weblibre/features/geckoview/domain/providers/desktop_mode.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_detail_state.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_session.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/utils/close_tab_helper.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/menu_item_buttons.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/widgets/navigation_buttons.dart';
import 'package:weblibre/features/geckoview/features/find_in_page/presentation/controllers/find_in_page.dart';
import 'package:weblibre/features/geckoview/features/pwa/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/pwa/presentation/widgets/pwa_install_button.dart';
import 'package:weblibre/features/geckoview/features/readerview/presentation/controllers/readerable.dart';
import 'package:weblibre/features/geckoview/features/readerview/presentation/widgets/reader_button.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/entities/container_selection_result.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/folder.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/container_relation_visibility.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/background_tab_open.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/presentation/hooks/menu_controller.dart';
import 'package:weblibre/utils/ui_helper.dart' as ui_helper;

class TabMenu extends HookConsumerWidget {
  final MenuAnchorChildBuilder builder;
  final MenuController? controller;
  final String selectedTabId;
  final bool enableFindInPage;
  final bool enableReaderMode;
  final bool enableDesktopMode;
  final bool enableAddBookmark;
  final bool enableAddToHomeScreen;
  final bool enableCloneTab;
  final bool enableContainer;
  final bool enableShare;
  final bool enableExport;
  final bool enableCloseTab;
  final bool enablePinTab;
  final bool enableReloadButton;
  final bool enableNavigationButtons;
  final bool enableReorder;

  const TabMenu({
    super.key,
    required this.builder,
    required this.selectedTabId,
    this.controller,
    this.enableFindInPage = true,
    this.enableReaderMode = true,
    this.enableDesktopMode = true,
    this.enableAddBookmark = true,
    this.enableAddToHomeScreen = true,
    this.enableCloneTab = true,
    this.enableContainer = true,
    this.enableShare = true,
    this.enableExport = true,
    this.enableCloseTab = true,
    this.enablePinTab = true,
    this.enableReloadButton = true,
    this.enableNavigationButtons = true,
    this.enableReorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(generalSettingsWithDefaultsProvider);

    final controller = this.controller ?? useMenuController();

    return MenuAnchor(
      controller: controller,
      builder: builder,
      menuChildren: [
        if (enableFindInPage)
          MenuItemButton(
            onPressed: () {
              ref.read(bottomSheetControllerProvider.notifier).requestDismiss();

              ref
                  .read(findInPageControllerProvider(selectedTabId).notifier)
                  .show();
            },
            leadingIcon: const Icon(Icons.search),
            child: const Text('Find in Page'),
          ),
        if (enableReaderMode)
          ReaderButton(
            buttonBuilder: (isLoading, readerActive, icon) => MenuItemButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      await ref
                          .read(readerableScreenControllerProvider.notifier)
                          .toggleReaderView(!readerActive);
                    },
              leadingIcon: icon,
              trailingIcon: Checkbox(
                value: readerActive,
                onChanged: (value) async {
                  if (value != null && !isLoading) {
                    await ref
                        .read(readerableScreenControllerProvider.notifier)
                        .toggleReaderView(!readerActive);
                    controller.close();
                  }
                },
              ),
              child: const Text('Reader Mode'),
            ),
          ),
        if (enableDesktopMode)
          _DesktopModeMenuItem(
            selectedTabId: selectedTabId,
            controller: controller,
            onToggle: () {
              ref.read(desktopModeProvider(selectedTabId).notifier).toggle();
            },
            onEnabledChanged: (value) {
              ref
                  .read(desktopModeProvider(selectedTabId).notifier)
                  .enabled(value);
            },
          ),
        if (enableFindInPage || enableReaderMode || enableDesktopMode)
          const Divider(),
        if (enableAddBookmark)
          MenuItemButton(
            leadingIcon: const Icon(MdiIcons.bookmarkPlus),
            child: const Text('Add Bookmark'),
            onPressed: () async {
              final tabState = ref.read(tabStateProvider(selectedTabId))!;
              final bookmarkUrl = tabState.url;

              await BookmarkEntryAddRoute(
                bookmarkInfo: jsonEncode(
                  BookmarkInfo(
                    title: tabState.titleOrAuthority,
                    url: bookmarkUrl.toString(),
                  ).encode(),
                ),
              ).push(context);
            },
          ),
        if (enableAddToHomeScreen) const _AddToHomeScreenMenuItem(),
        if (enableCloneTab)
          SubmenuButton(
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(MdiIcons.tab),
                child: const Text('Regular'),
                onPressed: () async {
                  final tabState = ref.read(tabStateProvider(selectedTabId))!;
                  final containerData = await ref
                      .read(tabDataRepositoryProvider.notifier)
                      .getTabContainerData(selectedTabId);

                  final cloneUrl = tabState.url;
                  final tabId = (tabState.tabMode is! RegularTabMode)
                      ? await ref
                            .read(tabRepositoryProvider.notifier)
                            .addTab(
                              tabMode: TabMode.regular,
                              url: cloneUrl,
                              containerSelection: containerData == null
                                  ? const TabContainerSelection.unassigned()
                                  : TabContainerSelection.specific(
                                      containerData,
                                    ),
                              selectTab: false,
                            )
                      : await ref
                            .read(tabRepositoryProvider.notifier)
                            .duplicateTab(
                              selectTabId: selectedTabId,
                              containerData: containerData,
                              selectTab: false,
                            );

                  if (context.mounted) {
                    handleBackgroundTabOpened(context, ref, tabId);
                  }
                },
              ),
              MenuItemButton(
                leadingIcon: Icon(
                  MdiIcons.dominoMask,
                  color: AppColors.of(context).privateTabPurple,
                ),
                child: const Text('Private'),
                onPressed: () async {
                  final tabState = ref.read(tabStateProvider(selectedTabId))!;
                  final containerData = await ref
                      .read(tabDataRepositoryProvider.notifier)
                      .getTabContainerData(selectedTabId);

                  final cloneUrl = tabState.url;
                  final tabId = (tabState.tabMode is! PrivateTabMode)
                      ? await ref
                            .read(tabRepositoryProvider.notifier)
                            .addTab(
                              url: cloneUrl,
                              tabMode: TabMode.private,
                              containerSelection: containerData == null
                                  ? const TabContainerSelection.unassigned()
                                  : TabContainerSelection.specific(
                                      containerData,
                                    ),
                              selectTab: false,
                            )
                      : await ref
                            .read(tabRepositoryProvider.notifier)
                            .duplicateTab(
                              selectTabId: selectedTabId,
                              containerData: containerData,
                              selectTab: false,
                            );

                  if (context.mounted) {
                    handleBackgroundTabOpened(context, ref, tabId);
                  }
                },
              ),
            ],
            leadingIcon: const Icon(MdiIcons.contentDuplicate),
            child: const Text('Clone Tab'),
          ),
        if (enableContainer && settings.showContainerUi)
          SubmenuButton(
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(MdiIcons.folderArrowUpDownOutline),
                child: const Text('Assign Container'),
                onPressed: () async {
                  final selection = await const ContainerSelectionRoute()
                      .push<ContainerSelectionResult?>(context);

                  switch (selection) {
                    case ContainerSelectionSelected(:final containerId):
                      final containerData = await ref
                          .read(containerRepositoryProvider.notifier)
                          .getContainerData(containerId);

                      if (containerData != null) {
                        final tabState = ref.read(
                          tabStateProvider(selectedTabId),
                        )!;

                        await ref
                            .read(tabDataRepositoryProvider.notifier)
                            .assignContainer(tabState.id, containerData);
                      }
                    case ContainerSelectionUnassigned():
                      final tabState = ref.read(
                        tabStateProvider(selectedTabId),
                      )!;

                      await ref
                          .read(tabDataRepositoryProvider.notifier)
                          .unassignContainer(tabState.id);
                    case null:
                      break;
                  }
                },
              ),
              ContainerAssignedVisibility(
                tabId: selectedTabId,
                child: MenuItemButton(
                  leadingIcon: const Icon(MdiIcons.folderCancelOutline),
                  child: const Text('Unassign Container'),
                  onPressed: () async {
                    final tabState = ref.read(tabStateProvider(selectedTabId))!;

                    await ref
                        .read(tabDataRepositoryProvider.notifier)
                        .unassignContainer(tabState.id);
                  },
                ),
              ),
            ],
            leadingIcon: const Icon(MdiIcons.folder),
            child: const Text('Container'),
          ),
        if (enableReorder)
          SubmenuButton(
            leadingIcon: const Icon(MdiIcons.swapVertical),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(MdiIcons.chevronUp),
                onPressed: () async {
                  await ref
                      .read(tabDataRepositoryProvider.notifier)
                      .moveTabAmongSiblings(selectedTabId, down: false);
                },
                child: const Text('Move up'),
              ),
              MenuItemButton(
                leadingIcon: const Icon(MdiIcons.chevronDown),
                onPressed: () async {
                  await ref
                      .read(tabDataRepositoryProvider.notifier)
                      .moveTabAmongSiblings(selectedTabId, down: true);
                },
                child: const Text('Move down'),
              ),
            ],
            child: const Text('Reorder'),
          ),
        if (enableShare)
          SubmenuButton(
            menuChildren: [
              CopyAddressMenuItemButton(selectedTabId: selectedTabId),
              OpenInAppMenuItemButton(selectedTabId: selectedTabId),
              ShareScreenshotMenuItemButton(selectedTabId: selectedTabId),
              ShareMenuItemButton(selectedTabId: selectedTabId),
              SendTabToDeviceMenuItemButton(selectedTabId: selectedTabId),
              ShowQrCodeMenuItemButton(selectedTabId: selectedTabId),
            ],
            leadingIcon: const Icon(Icons.share),
            child: const Text('Share'),
          ),
        if (enableExport)
          SubmenuButton(
            menuChildren: [
              ShareMarkdownActionMenuItemButton(
                selectedTabId: selectedTabId,
                title: const Text('Copy as Markdown'),
                // ignore: deprecated_member_use
                icon: const Icon(MdiIcons.languageMarkdownOutline),
                shareMarkdownAction: (content, fileName) async {
                  await Clipboard.setData(ClipboardData(text: content));

                  if (context.mounted) {
                    ui_helper.showInfoMessage(
                      context,
                      'Markdown copied to clipboard',
                    );
                  }
                },
              ),
              ShareMarkdownActionMenuItemButton(
                selectedTabId: selectedTabId,
                title: const Text('Export as Markdown'),
                // ignore: deprecated_member_use
                icon: const Icon(MdiIcons.languageMarkdown),
                shareMarkdownAction: (content, fileName) async {
                  await FilePicker.saveFile(
                    fileName: fileName ?? 'page',
                    type: FileType.custom,
                    allowedExtensions: ['md'],
                    bytes: utf8.encode(content),
                  );
                },
              ),
              SaveToPdfMenuItemButton(selectedTabId: selectedTabId),
              ExportScreenshotMenuItemButton(selectedTabId: selectedTabId),
              PrintMenuItemButton(selectedTabId: selectedTabId),
            ],
            leadingIcon: const Icon(MdiIcons.fileExport),
            child: const Text('Export'),
          ),
        if (enablePinTab) _PinTabMenuItem(selectedTabId: selectedTabId),
        if (enableCloseTab)
          MenuItemButton(
            onPressed: () =>
                closeTabWithConfirmationAndUndo(context, ref, selectedTabId),
            leadingIcon: const Icon(MdiIcons.tabMinus),
            child: const Text('Close Tab'),
          ),
        if (enableReloadButton || enableNavigationButtons) const Divider(),
        if (enableReloadButton)
          MenuItemButton(
            onPressed: () async {
              final sessionController = ref.read(
                tabSessionProvider(tabId: selectedTabId).notifier,
              );

              await sessionController.reload();
              controller.close();
            },
            leadingIcon: const Icon(Icons.refresh),
            child: const Text('Reload'),
          ),
        if (enableNavigationButtons)
          _NavigationButtonsRow(
            selectedTabId: selectedTabId,
            controller: controller,
          ),
      ],
    );
  }
}

class _DesktopModeMenuItem extends ConsumerWidget {
  final String selectedTabId;
  final MenuController controller;
  final VoidCallback onToggle;
  final ValueChanged<bool> onEnabledChanged;

  const _DesktopModeMenuItem({
    required this.selectedTabId,
    required this.controller,
    required this.onToggle,
    required this.onEnabledChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(desktopModeProvider(selectedTabId));

    return MenuItemButton(
      onPressed: onToggle,
      leadingIcon: const Icon(MdiIcons.monitor),
      trailingIcon: Checkbox(
        value: enabled,
        onChanged: (value) {
          if (value != null) {
            onEnabledChanged(value);
            controller.close();
          }
        },
      ),
      child: const Text('Desktop Mode'),
    );
  }
}

class _AddToHomeScreenMenuItem extends ConsumerWidget {
  const _AddToHomeScreenMenuItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInstallable = ref.watch(isCurrentTabInstallableProvider);
    final isShortcutable = ref.watch(isCurrentTabShortcutableProvider);

    return Visibility(
      visible: isInstallable || isShortcutable,
      child: MenuItemButton(
        closeOnActivate: false,
        leadingIcon: const Icon(Icons.add_to_home_screen),
        child: const Text('Add to Home Screen'),
        onPressed: () async {
          if (isInstallable) {
            await showPwaInstallDialog(context, ref);
          } else {
            await showShortcutInstallDialog(context, ref);
          }

          if (context.mounted) {
            MenuController.maybeOf(context)?.close();
          }
        },
      ),
    );
  }
}

/// Pin/essential/space/folder tab-organization actions, all driven off the
/// tab's own DB row ([watchTabDbDataProvider]) rather than separate providers
/// per field, since the menu needs [TabSummary.tabShelf], [TabSummary.folderId]
/// and [TabSummary.spaceUuid] together to decide what to show.
class _PinTabMenuItem extends ConsumerWidget {
  final String selectedTabId;

  const _PinTabMenuItem({required this.selectedTabId});

  Future<void> _setShelf(WidgetRef ref, TabShelf shelf) => ref
      .read(tabDataRepositoryProvider.notifier)
      .setShelf(
        selectedTabId,
        shelf,
        activeSpaceUuid: ref.read(selectedSpaceProvider),
      );

  Future<void> _showMoveToSpaceDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentSpaceUuid,
  ) async {
    final spaces = ref.read(watchSpacesProvider).value ?? const <SpaceData>[];
    final otherSpaces = spaces
        .where((space) => space.uuid != currentSpaceUuid)
        .toList();

    final target = await showDialog<SpaceData>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Move to space'),
        children: [
          for (final space in otherSpaces)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, space),
              child: Text(space.name.isEmpty ? 'Space' : space.name),
            ),
        ],
      ),
    );

    if (target != null) {
      await ref
          .read(tabDataRepositoryProvider.notifier)
          .moveTabToSpace(selectedTabId, target.uuid);
    }
  }

  Future<void> _showMoveToFolderDialog(
    BuildContext context,
    WidgetRef ref,
    String? spaceUuid,
  ) async {
    final folders =
        ref.read(watchFoldersProvider(spaceUuid)).value ??
        const <TabFolderData>[];

    final choice = await showDialog<Object>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Move to folder'),
        children: [
          for (final folder in folders)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, folder),
              child: Text(folder.name.isEmpty ? 'Folder' : folder.name),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, _newFolderChoice),
            child: const Text('New folder…'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    String? targetFolderId;
    if (identical(choice, _newFolderChoice)) {
      if (spaceUuid == null) return;

      final nameController = TextEditingController();
      final name = context.mounted
          ? await showDialog<String>(
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
                    onPressed: () =>
                        Navigator.pop(dialogContext, nameController.text),
                    child: const Text('Create'),
                  ),
                ],
              ),
            )
          : null;

      if (name == null) return;

      final folder = await ref
          .read(folderRepositoryProvider.notifier)
          .createFolder(spaceUuid, name: name.isEmpty ? 'Folder' : name);
      targetFolderId = folder.id;
    } else {
      targetFolderId = (choice as TabFolderData).id;
    }

    await ref
        .read(tabDataRepositoryProvider.notifier)
        .moveTabToFolder(selectedTabId, targetFolderId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabData = ref.watch(watchTabDbDataProvider(selectedTabId)).value;
    final isPinned = tabData?.tabShelf == TabShelf.pinned;
    final isEssential = tabData?.tabShelf == TabShelf.essential;
    final folderId = tabData?.folderId;
    final spaceUuid = tabData?.spaceUuid;
    final isPrivate = tabData?.tabMode == TabModeDbValue.private;
    // A split member moves with its split (PLAN §6.5 rule 2), so the
    // per-tab space/folder moves are replaced by an info row.
    final splitId = tabData?.splitId;
    final splitSize = splitId == null
        ? 0
        : ref.watch(
            watchSpaceTabsDataProvider(spaceUuid).select(
              (value) =>
                  value.value
                      ?.where((summary) => summary.splitId == splitId)
                      .length ??
                  0,
            ),
          );
    final isSplitMember = splitId != null && splitSize > 1;
    final showSpaceAndFolderItems =
        !isEssential && !isPrivate && !isSplitMember;
    // A folder member is pinned by definition (Zen keeps folders in the
    // pinned section): "Unpin tab" leaves the folder, "Remove from folder"
    // keeps it pinned at the space root. "Pin tab" makes no sense for a
    // member, so a row that is somehow in a folder without being pinned
    // only gets the folder actions.
    final isFolderMember = folderId != null && !isEssential;
    final showPinItem = isPinned || !isFolderMember;
    // Unloading (PLAN §7.4) is for live, regular, normal-shelf tabs that are
    // not on screen — the same rule [TabRepository.demoteToCold] enforces.
    final isSelected = ref.watch(selectedTabProvider) == selectedTabId;
    final canUnload =
        tabData != null &&
        !tabData.isCold &&
        tabData.tabShelf == TabShelf.normal &&
        !isPrivate &&
        !isSelected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPinItem)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: () async {
              await _setShelf(
                ref,
                isPinned ? TabShelf.normal : TabShelf.pinned,
              );

              if (context.mounted) {
                MenuController.maybeOf(context)?.close();
              }
            },
            leadingIcon: Icon(isPinned ? MdiIcons.pinOff : MdiIcons.pin),
            child: Text(isPinned ? 'Unpin tab' : 'Pin tab'),
          ),
        MenuItemButton(
          closeOnActivate: false,
          onPressed: () async {
            await _setShelf(
              ref,
              isEssential ? TabShelf.normal : TabShelf.essential,
            );

            if (context.mounted) {
              MenuController.maybeOf(context)?.close();
            }
          },
          leadingIcon: Icon(
            isEssential ? MdiIcons.starOffOutline : MdiIcons.starOutline,
          ),
          child: Text(
            isEssential ? 'Remove from essentials' : 'Add to essentials',
          ),
        ),
        if (canUnload)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: () async {
              await ref
                  .read(tabRepositoryProvider.notifier)
                  .demoteToCold(selectedTabId);

              if (context.mounted) {
                MenuController.maybeOf(context)?.close();
              }
            },
            leadingIcon: const Icon(MdiIcons.snowflakeVariant),
            child: const Text('Unload tab'),
          ),
        if (isSplitMember)
          MenuItemButton(
            onPressed: null,
            leadingIcon: const Icon(MdiIcons.viewSplitVertical),
            child: Text('Split view ($splitSize tabs)'),
          ),
        if (showSpaceAndFolderItems)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: () async {
              await _showMoveToSpaceDialog(context, ref, spaceUuid);

              if (context.mounted) {
                MenuController.maybeOf(context)?.close();
              }
            },
            leadingIcon: const Icon(MdiIcons.arrowRightBoldOutline),
            child: const Text('Move to space…'),
          ),
        if (showSpaceAndFolderItems)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: () async {
              await _showMoveToFolderDialog(context, ref, spaceUuid);

              if (context.mounted) {
                MenuController.maybeOf(context)?.close();
              }
            },
            leadingIcon: const Icon(MdiIcons.folderMoveOutline),
            child: const Text('Move to folder…'),
          ),
        if (showSpaceAndFolderItems && folderId != null)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: () async {
              await ref
                  .read(tabDataRepositoryProvider.notifier)
                  .moveTabToFolder(selectedTabId, null);

              if (context.mounted) {
                MenuController.maybeOf(context)?.close();
              }
            },
            leadingIcon: const Icon(MdiIcons.folderRemoveOutline),
            child: const Text('Remove from folder'),
          ),
      ],
    );
  }
}

/// Sentinel choice value for the "New folder…" entry in the move-to-folder
/// dialog, distinct from any real [TabFolderData].
final Object _newFolderChoice = Object();

class _NavigationButtonsRow extends ConsumerWidget {
  final String selectedTabId;
  final MenuController controller;

  const _NavigationButtonsRow({
    required this.selectedTabId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(tabHistoryStateProvider(selectedTabId));

    final isLoading = ref.watch(
      selectedTabStateProvider.select((state) => state?.isLoading ?? false),
    );

    return Row(
      children: [
        Expanded(
          child: NavigateBackButton(
            selectedTabId: selectedTabId,
            isLoading: isLoading,
            menuControllerToClose: controller,
            canGoBack: history.canGoBack,
          ),
        ),
        const SizedBox(height: 48, child: VerticalDivider()),
        Expanded(
          child: NavigateForwardButton(
            selectedTabId: selectedTabId,
            menuControllerToClose: controller,
            canGoForward: history.canGoForward,
          ),
        ),
      ],
    );
  }
}
