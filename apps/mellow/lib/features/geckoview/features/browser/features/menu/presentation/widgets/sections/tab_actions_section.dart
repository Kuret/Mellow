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
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/design/app_colors.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/geckoview/domain/entities/tab_container_selection.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_session.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/browser/features/menu/domain/entities/menu_layout.dart';
import 'package:mellow/features/geckoview/features/browser/features/menu/presentation/widgets/menu_card.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/dialogs/content_selection_dialog.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/dialogs/qr_code.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/entities/container_selection_result.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/container_relation_visibility.dart';
import 'package:mellow/features/geckoview/features/tabs/utils/background_tab_open.dart';
import 'package:mellow/features/geckoview/utils/image_helper.dart';
import 'package:mellow/features/sync/domain/repositories/sync.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/utils/ui_helper.dart' as ui_helper;
import 'package:nullability/nullability.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Actions on the tab itself.
///
/// [MenuItemType.moreDisclosure] is a position in the item list rather than a
/// row: everything the user placed after it folds away behind a "More" row
/// until it is tapped. Switching the marker off shows the whole section flat,
/// and dragging it decides how much stays in view — which is how the shipped
/// "More: Clone Tab, Export, Pin Shortcut, Fetch Feeds" split survives being
/// user-configurable.
class TabActionsSection extends HookConsumerWidget {
  final String selectedTabId;
  final List<MenuItemEntry> items;

  const TabActionsSection({
    super.key,
    required this.selectedTabId,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showContainerUi = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (value) => value.showContainerUi,
      ),
    );
    final showMore = useState(false);

    final applicable = [
      for (final item in items)
        if (item.type != MenuItemType.containers || showContainerUi) item,
    ];

    final markerIndex = applicable.indexWhere(
      (item) => item.type == MenuItemType.moreDisclosure,
    );
    final upfront = markerIndex == -1
        ? applicable
        : applicable.sublist(0, markerIndex);
    final folded = markerIndex == -1
        ? const <MenuItemEntry>[]
        : applicable.sublist(markerIndex + 1);

    return buildMenuCard(
      context,
      children: [
        for (final item in upfront) _buildItem(item),
        // A marker with nothing behind it would be a "More" row that reveals an
        // empty card, so it only earns its place once something is folded.
        if (folded.isNotEmpty && !showMore.value)
          ListTile(
            leading: const Icon(Icons.more_horiz),
            title: Text(MenuItemType.moreDisclosure.label),
            subtitle: Text(folded.map((item) => item.type.label).join(', ')),
            trailing: const Icon(Icons.expand_more),
            onTap: () => showMore.value = true,
          )
        else
          for (final item in folded) _buildItem(item),
      ],
    );
  }

  Widget _buildItem(MenuItemEntry item) => switch (item.type) {
    MenuItemType.containers => _ContainerExpansion(
      selectedTabId: selectedTabId,
      items: item.visibleItems,
    ),
    MenuItemType.share => _ShareExpansion(
      selectedTabId: selectedTabId,
      items: item.visibleItems,
    ),
    MenuItemType.cloneTab => _CloneTabExpansion(
      selectedTabId: selectedTabId,
      items: item.visibleItems,
    ),
    MenuItemType.export => _ExportExpansion(
      selectedTabId: selectedTabId,
      items: item.visibleItems,
    ),
    _ => const SizedBox.shrink(),
  };
}

class _ContainerExpansion extends ConsumerWidget {
  final String selectedTabId;
  final List<MenuItemEntry> items;

  const _ContainerExpansion({required this.selectedTabId, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(MdiIcons.folder),
        title: const Text('Containers'),
        children: orderMenuChildren(items, {
          MenuItemType.manageContainers: () => buildMenuSubTile(
            'Manage Containers',
            icon: MdiIcons.folder,
            onTap: () async {
              Navigator.pop(context);
              await const ContainerListRoute().push(context);
            },
          ),
          MenuItemType.assignContainer: () => buildMenuSubTile(
            'Assign Container',
            icon: MdiIcons.folderArrowUpDownOutline,
            onTap: () async {
              final selection = await const ContainerSelectionRoute()
                  .push<ContainerSelectionResult?>(context);

              switch (selection) {
                case ContainerSelectionSelected(:final containerId):
                  final containerData = await ref
                      .read(containerRepositoryProvider.notifier)
                      .getContainerData(containerId);

                  if (containerData != null) {
                    final tabState = ref.read(tabStateProvider(selectedTabId))!;
                    await ref
                        .read(tabDataRepositoryProvider.notifier)
                        .assignContainer(tabState.id, containerData);
                  }
                case ContainerSelectionUnassigned():
                  final tabState = ref.read(tabStateProvider(selectedTabId))!;
                  await ref
                      .read(tabDataRepositoryProvider.notifier)
                      .unassignContainer(tabState.id);
                case null:
                  break;
              }

              if (context.mounted) Navigator.pop(context);
            },
          ),
          MenuItemType.unassignContainer: () => ContainerAssignedVisibility(
            tabId: selectedTabId,
            child: buildMenuSubTile(
              'Unassign Container',
              icon: MdiIcons.folderCancelOutline,
              onTap: () async {
                final tabState = ref.read(tabStateProvider(selectedTabId))!;
                await ref
                    .read(tabDataRepositoryProvider.notifier)
                    .unassignContainer(tabState.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        }),
      ),
    );
  }
}

class _ShareExpansion extends HookConsumerWidget {
  final String selectedTabId;
  final List<MenuItemEntry> items;

  const _ShareExpansion({required this.selectedTabId, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabStateProvider(selectedTabId));
    final effectiveUrl = tabState?.url;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.share),
        title: const Text('Share'),
        children: [
          ...orderMenuChildren(items, {
            MenuItemType.copyAddress: () => buildMenuSubTile(
              'Copy Address',
              icon: MdiIcons.contentCopy,
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: effectiveUrl.toString()),
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),
            MenuItemType.shareScreenshot: () => buildMenuSubTile(
              'Share Screenshot',
              icon: Icons.mobile_screen_share,
              onTap: () async {
                final screenshot = await ref
                    .read(selectedTabSessionProvider)
                    .requestScreenshot();

                final ts = ref.read(tabStateProvider(selectedTabId))!;

                if (screenshot != null) {
                  final png = await encodeScreenshotAsPng(screenshot);

                  if (png != null) {
                    final file = XFile.fromData(png, mimeType: 'image/png');

                    await SharePlus.instance.share(
                      ShareParams(files: [file], subject: ts.titleOrAuthority),
                    );
                  }
                }

                if (context.mounted) Navigator.pop(context);
              },
            ),
            MenuItemType.shareLink: () => buildMenuSubTile(
              'Share Link',
              icon: Icons.share,
              onTap: () async {
                await SharePlus.instance.share(ShareParams(uri: effectiveUrl));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            MenuItemType.sendToDevice: () =>
                _SendToDeviceExpansion(selectedTabId: selectedTabId),
            MenuItemType.showQrCode: () => buildMenuSubTile(
              'Show QR Code',
              icon: Icons.qr_code,
              onTap: () async {
                if (context.mounted) {
                  Navigator.pop(context);
                  await showQrCode(context, effectiveUrl.toString());
                }
              },
            ),
          }),
        ],
      ),
    );
  }
}

class _SendToDeviceExpansion extends ConsumerWidget {
  final String selectedTabId;

  const _SendToDeviceExpansion({required this.selectedTabId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(syncIsAuthenticatedProvider);
    final devices = ref.watch(syncDevicesProvider);

    if (!isAuthenticated) return const SizedBox.shrink();

    return Skeletonizer(
      enabled: devices.isLoading && devices.value == null,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 56, right: 16),
          leading: const Icon(Icons.send_outlined, size: 20),
          title: const Text('Send To Device', style: TextStyle(fontSize: 14)),
          children: devices.when(
            data: (deviceList) {
              final targets = deviceList
                  .where(
                    (device) => !device.isCurrentDevice && device.canSendTab,
                  )
                  .toList(growable: false);

              if (targets.isEmpty) {
                return [
                  const ListTile(
                    contentPadding: EdgeInsets.only(left: 72, right: 16),
                    title: Text(
                      'No target devices',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ];
              }

              return targets
                  .map(
                    (device) => ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 72,
                        right: 16,
                      ),
                      leading: const Icon(Icons.devices_other, size: 18),
                      title: Text(
                        device.displayName,
                        style: const TextStyle(fontSize: 13),
                      ),
                      dense: true,
                      onTap: () async {
                        final tabState = ref.read(
                          tabStateProvider(selectedTabId),
                        );
                        if (tabState == null) return;

                        final sendUrl = tabState.url;
                        final title = tabState.title.isNotEmpty
                            ? tabState.title
                            : sendUrl.toString();

                        final success = await ref
                            .read(syncRepositoryProvider.notifier)
                            .sendTabToDevice(
                              deviceId: device.deviceId,
                              title: title,
                              url: sendUrl.toString(),
                              private: tabState.tabMode == TabMode.private,
                            );

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ui_helper.showInfoMessage(
                              context,
                              'Sent tab to ${device.displayName}',
                            );
                          } else {
                            ui_helper.showErrorMessage(
                              context,
                              'Failed to send tab',
                            );
                          }
                        }
                      },
                    ),
                  )
                  .toList(growable: false);
            },
            loading: () => const [
              ListTile(
                contentPadding: EdgeInsets.only(left: 72, right: 16),
                leading: Icon(Icons.devices_other, size: 18),
                title: Text(
                  'Loading devices...',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
            error: (_, _) => const [
              ListTile(
                contentPadding: EdgeInsets.only(left: 72, right: 16),
                title: Text(
                  'Failed to load devices',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloneTabExpansion extends ConsumerWidget {
  final String selectedTabId;
  final List<MenuItemEntry> items;

  const _CloneTabExpansion({required this.selectedTabId, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = AppColors.of(context);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(MdiIcons.contentDuplicate),
        title: const Text('Clone Tab'),
        children: orderMenuChildren(items, {
          MenuItemType.cloneRegularTab: () => buildMenuSubTile(
            'Regular',
            icon: MdiIcons.tab,
            onTap: () async {
              final tabState = ref.read(tabStateProvider(selectedTabId))!;
              final cloneUrl = tabState.url;
              final containerData = await ref
                  .read(tabDataRepositoryProvider.notifier)
                  .getTabContainerData(selectedTabId);

              final tabId = (tabState.tabMode is! RegularTabMode)
                  ? await ref
                        .read(tabRepositoryProvider.notifier)
                        .addTab(
                          tabMode: TabMode.regular,
                          url: cloneUrl,
                          containerSelection: containerData == null
                              ? const TabContainerSelection.unassigned()
                              : TabContainerSelection.specific(containerData),
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
                Navigator.pop(context);
              }
            },
          ),
          MenuItemType.clonePrivateTab: () => buildMenuSubTile(
            'Private',
            icon: MdiIcons.dominoMask,
            iconColor: appColors.privateTabPurple,
            onTap: () async {
              final tabState = ref.read(tabStateProvider(selectedTabId))!;
              final cloneUrl = tabState.url;
              final containerData = await ref
                  .read(tabDataRepositoryProvider.notifier)
                  .getTabContainerData(selectedTabId);

              final tabId = (tabState.tabMode is! PrivateTabMode)
                  ? await ref
                        .read(tabRepositoryProvider.notifier)
                        .addTab(
                          url: cloneUrl,
                          tabMode: TabMode.private,
                          containerSelection: containerData == null
                              ? const TabContainerSelection.unassigned()
                              : TabContainerSelection.specific(containerData),
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
                Navigator.pop(context);
              }
            },
          ),
        }),
      ),
    );
  }
}

class _ExportExpansion extends ConsumerWidget {
  final String selectedTabId;
  final List<MenuItemEntry> items;

  const _ExportExpansion({required this.selectedTabId, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(MdiIcons.fileExport),
        title: const Text('Export'),
        children: orderMenuChildren(items, {
          MenuItemType.copyAsMarkdown: () => buildMenuSubTile(
            'Copy as Markdown',
            // ignore: deprecated_member_use
            icon: MdiIcons.languageMarkdownOutline,
            onTap: () async {
              await _handleMarkdownExport(context, ref, selectedTabId, (
                content,
                fileName,
              ) async {
                await Clipboard.setData(ClipboardData(text: content));
                if (context.mounted) {
                  ui_helper.showInfoMessage(
                    context,
                    'Markdown copied to clipboard',
                  );
                }
              }, const Text('Copy as Markdown'));
            },
          ),
          MenuItemType.exportAsMarkdown: () => buildMenuSubTile(
            'Export as Markdown',
            // ignore: deprecated_member_use
            icon: MdiIcons.languageMarkdown,
            onTap: () async {
              await _handleMarkdownExport(context, ref, selectedTabId, (
                content,
                fileName,
              ) async {
                await FilePicker.saveFile(
                  fileName: fileName ?? 'page',
                  type: FileType.custom,
                  allowedExtensions: ['md'],
                  bytes: utf8.encode(content),
                );
              }, const Text('Export as Markdown'));
            },
          ),
          MenuItemType.exportAsPdf: () => buildMenuSubTile(
            'Export as PDF',
            icon: MdiIcons.filePdfBox,
            onTap: () async {
              await ref
                  .read(tabSessionProvider(tabId: selectedTabId).notifier)
                  .saveToPdf();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          MenuItemType.exportAsPng: () => buildMenuSubTile(
            'Export as PNG',
            icon: MdiIcons.fileImage,
            onTap: () async {
              final screenshot = await ref
                  .read(selectedTabSessionProvider)
                  .requestScreenshot();

              final ts = ref.read(tabStateProvider(selectedTabId))!;

              if (screenshot != null) {
                final png = await encodeScreenshotAsPng(screenshot);

                if (png != null) {
                  await FilePicker.saveFile(
                    fileName: '${ts.titleOrAuthority}.png',
                    type: FileType.custom,
                    allowedExtensions: ['png'],
                    bytes: png,
                  );
                }
              }

              if (context.mounted) Navigator.pop(context);
            },
          ),
          MenuItemType.printPage: () => buildMenuSubTile(
            'Print',
            icon: MdiIcons.printer,
            onTap: () async {
              try {
                await ref
                    .read(tabSessionProvider(tabId: selectedTabId).notifier)
                    .printContent();
              } catch (e) {
                if (context.mounted) {
                  ui_helper.showErrorMessage(context, 'Failed to print page');
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        }),
      ),
    );
  }

  Future<void> _handleMarkdownExport(
    BuildContext context,
    WidgetRef ref,
    String tabId,
    Future<void> Function(String content, String? fileName) shareAction,
    Widget title,
  ) async {
    final tabData = await ref
        .read(tabDataRepositoryProvider.notifier)
        .getTabDataById(tabId);

    if (tabData == null || tabData.fullContentMarkdown.isEmpty) {
      if (context.mounted) Navigator.pop(context);
      return;
    }

    final shouldShowDialog =
        tabData.isProbablyReaderable == true &&
        tabData.extractedContentMarkdown.isNotEmpty;

    if (shouldShowDialog && context.mounted) {
      Navigator.pop(context);
      await showContentSelectionDialog(
        context,
        title: title,
        tabData: tabData,
        shareMarkdownAction: shareAction,
      );
    } else {
      await shareAction(
        tabData.fullContentMarkdown!,
        tabData.title ?? tabData.url?.authority,
      );
      if (context.mounted) Navigator.pop(context);
    }
  }
}
