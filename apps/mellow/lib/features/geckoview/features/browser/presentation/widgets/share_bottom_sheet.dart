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
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_session.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/dialogs/qr_code.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/utils/image_helper.dart';
import 'package:weblibre/features/sync/domain/repositories/sync.dart';
import 'package:weblibre/presentation/hooks/cached_future.dart';
import 'package:weblibre/presentation/widgets/uri_breadcrumb.dart';
import 'package:weblibre/presentation/widgets/url_icon.dart';
import 'package:weblibre/utils/ui_helper.dart' as ui_helper;

Future<void> showShareBottomSheet(
  BuildContext context, {
  required String selectedTabId,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => ShareBottomSheet(selectedTabId: selectedTabId),
  );
}

class ShareBottomSheet extends HookConsumerWidget {
  final String selectedTabId;

  const ShareBottomSheet({super.key, required this.selectedTabId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final tabUrl = ref.watch(
      tabStateProvider(selectedTabId).select((v) => v?.url),
    );

    final effectiveUrl = tabUrl;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShareHeader(url: effectiveUrl),

            // Copy Address
            ListTile(
              leading: const Icon(MdiIcons.contentCopy),
              title: const Text('Copy Address'),
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: effectiveUrl.toString()),
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),

            // Open in App (conditional)
            _OpenInAppTile(selectedTabId: selectedTabId),

            // Share Screenshot
            ListTile(
              leading: const Icon(Icons.mobile_screen_share),
              title: const Text('Share Screenshot'),
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

            // Share Link
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Link'),
              onTap: () async {
                await SharePlus.instance.share(ShareParams(uri: effectiveUrl));
                if (context.mounted) Navigator.pop(context);
              },
            ),

            // Send To Device (conditional)
            _SendToDeviceTile(selectedTabId: selectedTabId),

            // Show QR Code
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Show QR Code'),
              onTap: () async {
                if (context.mounted) {
                  Navigator.pop(context);
                  await showQrCode(context, effectiveUrl.toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareHeader extends StatelessWidget {
  final Uri? url;

  const _ShareHeader({required this.url});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: (url != null)
          ? UriBreadcrumb(
              uri: url!,
              icon: UrlIcon([url!], iconSize: 20),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _OpenInAppTile extends HookConsumerWidget {
  final String selectedTabId;

  static final _service = GeckoAppLinksService();

  const _OpenInAppTile({required this.selectedTabId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabStateProvider(selectedTabId));
    final url = tabState?.url;
    final appLink = useCachedFuture(
      () => url != null ? _service.resolveAppLink(url) : Future.value(null),
      [url],
    );

    final target = appLink.data;
    if (target == null) return const SizedBox.shrink();

    final appName = target.appName;

    return ListTile(
      leading: const Icon(Icons.open_in_new),
      title: Text(appName != null ? 'Open in $appName' : 'Open in App'),
      onTap: () async {
        if (url == null) return;
        final success = await _service.launchAppLink(url);
        if (success && context.mounted) Navigator.pop(context);
      },
    );
  }
}

class _SendToDeviceTile extends ConsumerWidget {
  final String selectedTabId;

  const _SendToDeviceTile({required this.selectedTabId});

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
          leading: const Icon(Icons.send_outlined),
          title: const Text('Send To Device'),
          children: devices.when(
            data: (deviceList) {
              final targets = deviceList
                  .where(
                    (device) => !device.isCurrentDevice && device.canSendTab,
                  )
                  .toList(growable: false);

              if (targets.isEmpty) {
                return const [
                  ListTile(
                    contentPadding: EdgeInsets.only(left: 72, right: 16),
                    title: Text('No target devices'),
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
                      title: Text(device.displayName),
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
                title: Text('Loading devices...'),
              ),
            ],
            error: (_, _) => const [
              ListTile(
                contentPadding: EdgeInsets.only(left: 72, right: 16),
                title: Text('Failed to load devices'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
