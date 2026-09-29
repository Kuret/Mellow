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

import 'package:flutter/material.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_detail_state.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_session.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/widgets/anchored_menu.dart';
import 'package:mellow/features/geckoview/features/find_in_page/presentation/controllers/find_in_page.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:mellow/features/geckoview/features/web_inspector/domain/providers/web_inspector.dart';
import 'package:share_plus/share_plus.dart';

/// The desktop-style menu a right click over empty page area raises — the
/// case Gecko has no link, image or media source to hand back a hit result
/// for, so [ContextMenuDialog] never opens on its own.
///
/// Unlike that menu, this one is not about anything under the cursor: it acts
/// on the page as a whole, so it carries no title and its actions come from
/// the tab itself rather than a [HitResult].
class PageContextMenuDialog extends HookConsumerWidget {
  final Offset anchor;

  const PageContextMenuDialog({super.key, required this.anchor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTabId = ref.watch(selectedTabProvider);
    if (selectedTabId == null) {
      // Nothing to act on; the caller raced a tab going away underneath it.
      return const SizedBox.shrink();
    }

    final history = ref.watch(tabHistoryStateProvider(selectedTabId));
    final url = ref.watch(
      tabStateProvider(selectedTabId).select((state) => state?.url),
    );
    final sessionNotifier = ref.read(
      tabSessionProvider(tabId: selectedTabId).notifier,
    );

    void closeThenRun(void Function() action) {
      Navigator.of(context).pop();
      action();
    }

    final canViewSource =
        url != null && (url.scheme == 'http' || url.scheme == 'https');

    final items = [
      ListTile(
        leading: const Icon(Icons.arrow_back),
        title: const Text('Back'),
        enabled: history.canGoBack,
        onTap: () => closeThenRun(() => unawaited(sessionNotifier.goBack())),
      ),
      ListTile(
        leading: const Icon(Icons.arrow_forward),
        title: const Text('Forward'),
        enabled: history.canGoForward,
        onTap: () => closeThenRun(() => unawaited(sessionNotifier.goForward())),
      ),
      ListTile(
        leading: const Icon(Icons.refresh),
        title: const Text('Reload'),
        onTap: () => closeThenRun(() => unawaited(sessionNotifier.reload())),
      ),
      const Divider(height: 1),
      ListTile(
        leading: const Icon(Icons.bookmark_add_outlined),
        title: const Text('Bookmark page'),
        onTap: () {
          final tabState = ref.read(tabStateProvider(selectedTabId))!;
          final bookmarkUrl = tabState.url;
          Navigator.of(context).pop();
          unawaited(
            BookmarkEntryAddRoute(
              bookmarkInfo: jsonEncode(
                BookmarkInfo(
                  title: tabState.titleOrAuthority,
                  url: bookmarkUrl.toString(),
                ).encode(),
              ),
            ).push(context),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.share),
        title: const Text('Share'),
        onTap: () => closeThenRun(() {
          if (url == null) return;
          unawaited(SharePlus.instance.share(ShareParams(uri: url)));
        }),
      ),
      ListTile(
        leading: const Icon(Icons.search),
        title: const Text('Find in page'),
        onTap: () => closeThenRun(
          () => ref
              .read(findInPageControllerProvider(selectedTabId).notifier)
              .show(),
        ),
      ),
      const Divider(height: 1),
      if (canViewSource)
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('View page source'),
          onTap: () => closeThenRun(() {
            final currentMode =
                ref.read(tabStateProvider(selectedTabId))?.tabMode ??
                TabMode.regular;
            unawaited(
              ref
                  .read(tabRepositoryProvider.notifier)
                  .addTab(
                    url: Uri.parse('view-source:$url'),
                    selectTab: true,
                    tabMode: currentMode,
                  ),
            );
          }),
        ),
      ListTile(
        leading: const Icon(Icons.pageview),
        title: const Text('Inspect element'),
        onTap: () => closeThenRun(
          () => unawaited(
            ref
                .read(webInspectorServiceProvider(tabId: selectedTabId))
                .pickElement(),
          ),
        ),
      ),
    ];

    return AnchoredMenu(
      anchor: anchor,
      menuKey: const Key('pageContextMenu'),
      items: items,
    );
  }
}
