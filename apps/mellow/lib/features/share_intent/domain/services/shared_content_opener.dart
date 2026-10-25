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

import 'package:go_router/go_router.dart';
import 'package:mellow/core/logger.dart';
import 'package:mellow/core/providers/router.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/features/browser/domain/providers/intent.dart';
import 'package:mellow/features/share_intent/domain/entities/shared_content.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_content_opener.g.dart';

/// Turns every [SharedContent] that reaches the app into the route that acts
/// on it: the "Open link" sheet for a URL, the search screen for text.
///
/// A link that arrives from outside never lands in a tab on its own: it opens
/// the custom tab, and the sheet pushed here is the only way to promote it into
/// one — which is also where its space is chosen.
///
/// This is a service rather than a listener in the browser widget because
/// flutter_riverpod pauses a widget's subscriptions while its `TickerMode` is
/// off, which is the case whenever an opaque route (settings, say) sits over
/// the browser. A share that arrived in the meantime was then held and delivered
/// only once the user came back, by which time it looked like a stale link
/// re-opening by itself. A keepAlive provider is never paused.
///
/// Two more things used to make an old link reappear, and are handled here:
///
/// * A sheet that the user left open (switched apps without dismissing it) got
///   the next sheet stacked on top, and showed again when that one popped. A
///   new share now replaces a sheet that is already on top.
/// * A rebuild of the intent stream re-emits its last value as
///   `AsyncData(previous, isLoading: true)`. The same instance is ignored; a
///   genuine repeat share is a new [SharedContent] and still opens.
@Riverpod(keepAlive: true)
void sharedContentOpener(Ref ref) {
  ref.listen(
    engineBoundIntentStreamProvider,
    (previous, next) {
      final content = next.value;
      if (content == null || identical(previous?.value, content)) {
        return;
      }

      unawaited(_open(ref, content));
    },
    onError: (error, stackTrace) {
      logger.e(
        'Error listening to engineBoundIntentStreamProvider',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

Future<void> _open(Ref ref, SharedContent content) async {
  try {
    final router = await ref.read(routerProvider.future);

    final (route, name) = switch (content) {
      SharedUrl() => (
        OpenSharedContentRoute(
          sharedUrl: content.url.toString(),
          contextId: content.contextId,
          containerMode: content.containerMode.queryValueOrNull,
        ),
        'OpenSharedContentRoute',
      ),
      SharedText() => (
        SearchRoute(
          tabType: ref.read(selectedTabTypeProvider) ?? TabType.regular,
          searchText: content.text,
          launchedFromIntent: true,
        ),
        'SearchRoute',
      ),
    };

    final top = _topRouteName(router);
    if (top == name) {
      // The previous share is still open; this one takes its place rather than
      // stacking on top and bringing it back when popped.
      await router.pushReplacement(route.location);
      return;
    }

    if (top != BrowserRoute.name) {
      // Do not push the sheet over settings (or wherever the user is): the
      // browser is where a shared link belongs, and where the sheet makes
      // sense.
      router.go(const BrowserRoute().location);
    }

    await router.push(route.location);
  } catch (error, stackTrace) {
    logger.e(
      'Failed to open shared content',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// The name of the route on top of the stack, or null while the router has no
/// configuration yet ([GoRouter.state] throws on an empty one).
String? _topRouteName(GoRouter router) {
  try {
    return router.state.topRoute?.name;
  } catch (_) {
    return null;
  }
}
