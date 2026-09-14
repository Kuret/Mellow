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

import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/core/providers/router.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_state.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/find_in_page/domain/repositories/find_in_page.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/search/domain/providers/search_provider.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
GeckoSelectionActionService selectionActionService(Ref ref) {
  final service = GeckoSelectionActionService.setUp();

  unawaited(
    service.setActions([
      NewTabAction((text) async {
        if (ref.mounted) {
          final router = await ref.read(routerProvider.future);
          if (ref.mounted) {
            final settings = ref.read(generalSettingsWithDefaultsProvider);
            final selectedTabState = ref.read(
              tabStatesProvider,
            )[ref.read(selectedTabProvider)];

            final selectedTabType = selectedTabState?.tabMode.toTabType();

            final route = SearchRoute(
              tabType:
                  selectedTabType ?? settings.effectiveDefaultCreateTabType,
              searchText: text,
            );

            await router.push(route.location);
          }
        }
      }),
      DefaultSearchAction((text) async {
        if (!ref.mounted) return;

        // Always answers, so the external search intent can no longer fall
        // through to the search screen for want of an engine.
        final searchProvider = ref.read(defaultSearchProviderProvider);

        final currentTab = ref.read(
          tabStatesProvider,
        )[ref.read(selectedTabProvider)];

        final tabMode =
            currentTab?.tabMode ??
            TabMode.fromTabType(
              ref
                  .read(generalSettingsWithDefaultsProvider)
                  .effectiveDefaultCreateTabType,
            );

        await ref
            .read(tabRepositoryProvider.notifier)
            .addTab(
              url: searchProvider.searchUrl(text),
              tabMode: tabMode,
              selectTab: true,
            );
      }),
      FindInPageAction((text) async {
        if (ref.mounted) {
          final tabId = ref.read(selectedTabProvider);
          if (tabId != null) {
            await ref
                .read(findInPageRepositoryProvider(tabId).notifier)
                .findAll(text);
          }
        }
      }),
      ShareAction((text) async {
        await SharePlus.instance.share(ShareParams(text: text));
      }),
      CallAction((text) async {
        final uri = Uri.tryParse('tel:${text.replaceAll(' ', '')}');

        if (uri != null) {
          final canLaunch = await canLaunchUrl(uri);
          if (canLaunch) {
            await launchUrl(uri);
          }
        }
      }),
      EmailAction((text) async {
        final uri = Uri.tryParse('mailto:$text');

        if (uri != null) {
          final canLaunch = await canLaunchUrl(uri);
          if (canLaunch) {
            await launchUrl(uri);
          }
        }
      }),
    ]),
  );

  return service;
}

/// The engine's tab API. A provider rather than a bare constructor so tests
/// can stand in a fake engine for [TabRepository].
@Riverpod(keepAlive: true)
GeckoTabService geckoTabService(Ref ref) => GeckoTabService();

@Riverpod(keepAlive: true)
GeckoEventService eventService(Ref ref) {
  final service = GeckoEventService.setUp();

  ref.onDispose(() async {
    await service.dispose();
  });

  return service;
}

@Riverpod(keepAlive: true)
GeckoAddonService addonService(Ref ref) {
  final service = GeckoAddonService.setUp();

  ref.onDispose(() async {
    await service.dispose();
  });

  return service;
}

@Riverpod(keepAlive: true)
GeckoTabContentService tabContentService(Ref ref) {
  final service = GeckoTabContentService.setUp();

  ref.onDispose(() async {
    await service.dispose();
  });

  return service;
}

@Riverpod(keepAlive: true)
GeckoSuggestionsService engineSuggestionsService(Ref ref) {
  final service = GeckoSuggestionsService.setUp();

  ref.onDispose(() async {
    await service.dispose();
  });

  return service;
}

@Riverpod(keepAlive: true)
GeckoViewportService viewportService(Ref ref) {
  final service = GeckoViewportService();
  service.setUp();

  ref.onDispose(() async {
    await service.dispose();
  });

  return service;
}

/// Whether native has reported that the engine and its components are up.
///
/// Native reports this once `GeckoBrowserApi.initialize` has built the
/// components, and again whenever a Flutter view attaches (a restarted Dart
/// half has lost the first report). It says nothing about tabs: the pull-based
/// `syncEvents` catch-ups that gate on it need the engine, not a session.
///
/// It used to be inferred from a reader-view action, which AC only dispatches
/// once a tab is selected — so a start that landed on the home surface never
/// reported ready and every catch-up sat out the timeout below instead.
@Riverpod(keepAlive: true)
class EngineReadyState extends _$EngineReadyState {
  /// Long enough that it only ever expires when the native report is genuinely
  /// missing, rather than merely late.
  static const _readySignalTimeout = Duration(seconds: 10);

  Future<bool> waitUntilReady({Duration timeout = _readySignalTimeout}) async {
    final eventService = ref.read(eventServiceProvider);
    final currentState =
        eventService.engineReadyStateEvents.valueOrNull ?? false;

    if (currentState) {
      return true;
    }

    try {
      final ready = await eventService.engineReadyStateEvents
          .firstWhere((value) => value == true)
          .timeout(timeout);

      if (ref.mounted) {
        state = ready;
      }

      return ready;
    } on TimeoutException {
      // Proceeding anyway is the safety valve, not the design: every caller
      // here only wants to ask native for state it may have missed, and never
      // asking is worse than asking too early. If this fires, the native report
      // is missing — see [EngineReadyState].
      logger.w(
        'Engine never reported ready; proceeding after '
        '${timeout.inSeconds}s without the native signal',
      );

      if (ref.mounted) {
        state = true;
      }

      return true;
    }
  }

  @override
  bool build() {
    final eventService = ref.watch(eventServiceProvider);

    final currentState =
        eventService.engineReadyStateEvents.valueOrNull ?? false;

    if (!currentState) {
      unawaited(waitUntilReady());
    }

    final sub = eventService.engineReadyStateEvents.listen((value) {
      if (ref.mounted) {
        state = value;
      }
    });

    ref.onDispose(() async {
      await sub.cancel();
    });

    return currentState;
  }
}
