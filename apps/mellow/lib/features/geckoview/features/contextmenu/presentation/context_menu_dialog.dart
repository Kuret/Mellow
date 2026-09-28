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
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/presentation/hooks/cached_future.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ContextMenuDialog extends HookConsumerWidget {
  final HitResult hitResult;

  const ContextMenuDialog({super.key, required this.hitResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return _AnchoredContextMenu(anchor: anchor, title: title, items: items);
  }
}

/// A compact, content-sized menu placed at the pointer, the way a desktop
/// browser's context menu behaves, rather than the centred Material dialog
/// phones get.
class _AnchoredContextMenu extends StatelessWidget {
  const _AnchoredContextMenu({
    required this.anchor,
    required this.title,
    required this.items,
  });

  final Offset anchor;
  final Widget title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    // [anchor] is measured against the raw view, but the route's SafeArea has
    // already pushed this widget's own origin clear of system chrome — the
    // DeX caption bar in particular — so the same amount is subtracted here
    // to keep the anchor in step with this widget's local coordinate space.
    final insets = MediaQuery.paddingOf(context);
    final localAnchor = anchor - Offset(insets.left, insets.top);

    return CustomSingleChildLayout(
      delegate: _AnchoredContextMenuLayout(localAnchor),
      child: Material(
        key: const Key('anchoredContextMenu'),
        type: MaterialType.card,
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleMedium!,
                    child: title,
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: items,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Places the menu with its top-left at [anchor], then shifts it back onto
/// screen if that would run it off the right or bottom edge — the same way a
/// desktop context menu never lets itself be opened partly off-screen.
class _AnchoredContextMenuLayout extends SingleChildLayoutDelegate {
  const _AnchoredContextMenuLayout(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxLeft = math.max(0.0, size.width - childSize.width);
    final maxTop = math.max(0.0, size.height - childSize.height);
    return Offset(anchor.dx.clamp(0.0, maxLeft), anchor.dy.clamp(0.0, maxTop));
  }

  @override
  bool shouldRelayout(covariant _AnchoredContextMenuLayout oldDelegate) =>
      anchor != oldDelegate.anchor;
}
