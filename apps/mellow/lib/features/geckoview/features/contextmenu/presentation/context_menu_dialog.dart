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
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/features/contextmenu/domain/providers/context_menu_shown_at.dart';
import 'package:mellow/features/geckoview/features/contextmenu/extensions/hit_result.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/copy_email.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/copy_image.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/copy_image_location.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/copy_link.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/copy_link_text.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/inspect_element.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/launch_external.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/open_image_new_tab.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/open_in_container.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/open_new_tab.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/save_file.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/save_image.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/share_email.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/share_image.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/candidates/share_link.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/widgets/anchored_menu.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/presentation/hooks/cached_future.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ContextMenuDialog extends HookConsumerWidget {
  final HitResult hitResult;

  const ContextMenuDialog({super.key, required this.hitResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recorded once, on the first build this dialog ever gets: the page
    // context menu's own grace-period timer reads it to tell a right click on
    // a link — which opens this dialog — from one over empty page area,
    // without the two menus needing to know about each other beyond this.
    final shownAt = ref.read(contextMenuShownAtProvider.notifier);
    useEffect(() {
      // Deferred off the build: a hook effect still runs inside the build
      // phase, and writing a provider there is what Riverpod refuses. The
      // grace period is measured in hundreds of milliseconds, so a microtask
      // costs it nothing.
      unawaited(Future.microtask(shownAt.markShown));
      return null;
    }, const []);

    final settings = ref.watch(generalSettingsWithDefaultsProvider);
    final showContainerUi = settings.showContainerUi;

    final effective = hitResult;

    final title = AutoSizeText(
      effective.getTitle(),
      minFontSize: 18,
      maxFontSize: DefaultTextStyle.of(context).style.fontSize,
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
    );

    final items = [
      if (OpenInNewTab.isSupported(effective))
        OpenInNewTab(hitResult: effective),
      if (showContainerUi && OpenInContainer.isSupported(effective))
        OpenInContainer(hitResult: effective),
      if (CopyLink.isSupported(effective)) CopyLink(hitResult: effective),
      if (CopyLinkText.isSupported(effective))
        CopyLinkText(hitResult: effective),
      if (SaveFile.isSupported(effective)) SaveFile(hitResult: effective),
      if (ShareLink.isSupported(effective)) ShareLink(hitResult: effective),
      if (ShareImage.isSupported(effective)) ShareImage(hitResult: effective),
      if (OpenImageInNewTab.isSupported(effective))
        OpenImageInNewTab(hitResult: effective),
      if (CopyImage.isSupported(effective)) CopyImage(hitResult: effective),
      if (SaveImage.isSupported(effective)) SaveImage(hitResult: effective),
      if (CopyImageLocation.isSupported(effective))
        CopyImageLocation(hitResult: effective),
      if (ShareEmail.isSupported(effective)) ShareEmail(hitResult: effective),
      if (CopyEmail.isSupported(effective)) CopyEmail(hitResult: effective),
      const InspectElement(),
      HookBuilder(
        builder: (context) {
          final isSupported = useCachedFuture(
            // ignore: discarded_futures useFuture
            () => LaunchExternal.isSupported(effective),
            [effective],
          );

          if (isSupported.data == false) {
            return const SizedBox.shrink();
          }

          return Skeletonizer(
            enabled: isSupported.connectionState != ConnectionState.done,
            child: LaunchExternal(hitResult: effective),
          );
        },
      ),
    ];

    // A mouse leaves its last hover position on the bridge; a long-press from
    // a finger never does, so the phone — the primary device — keeps the
    // familiar full-width dialog centred on screen.
    final anchor = PointerInputBridge.pointerPosition;
    if (anchor == null) {
      return SimpleDialog(title: title, children: items);
    }

    return AnchoredMenu(
      anchor: anchor,
      menuKey: const Key('anchoredContextMenu'),
      title: title,
      items: items,
    );
  }
}
