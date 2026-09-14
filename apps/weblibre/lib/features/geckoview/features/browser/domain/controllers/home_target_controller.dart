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
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/features/geckoview/domain/providers.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_container.dart';

part 'home_target_controller.g.dart';

/// How long the startup check waits for the restored selection to arrive before
/// concluding that there is none. Covers the native selected-tab debounce (50ms)
/// plus the channel hop, with room to spare.
const _restoredSelectionWindow = Duration(milliseconds: 300);

/// Resumes the last opened tab when the browser has nothing to show.
///
/// There is deliberately no choice here. Zen's synced state is the source of
/// truth for what tabs exist, so launching must never *conjure* one: the
/// browser either picks up a tab that is already in that state, or it falls
/// back to the home surface and waits. A configurable "open this address on
/// startup" would add a tab nothing upstream knows about, and sync would then
/// have to carry it back out.
@Riverpod(keepAlive: true)
class HomeTargetController extends _$HomeTargetController {
  var _startupHandled = false;

  /// Selects the most recently used tab, or shows the home surface if there is
  /// none to resume.
  ///
  /// With [scopeToSpace] the resume is confined to [spaceUuid], so closing the
  /// last tab in a space keeps the user there. A null [spaceUuid] under that
  /// flag means the tabs *without* a space (private, essential), which is a
  /// real scope — not the absence of one.
  ///
  /// [excludedTabIds] are tabs that are on their way out — closed but not yet
  /// deleted, which a resume must not select.
  Future<void> applyTarget({
    bool scopeToSpace = false,
    String? spaceUuid,
    Set<String> excludedTabIds = const {},
  }) async {
    final tabs = ref.read(tabRepositoryProvider.notifier);

    final resumed = scopeToSpace
        ? await tabs.resumeLatestSpaceTab(
            spaceUuid,
            excludedTabIds: excludedTabIds,
          )
        : await tabs.resumeLatestTab(excludedTabIds: excludedTabIds);

    if (!resumed && ref.mounted) {
      // Nothing to resume: home beats leaving a blank viewport.
      ref.read(forceBrowserHomeProvider.notifier).request();
    }
  }

  /// Runs the resume at cold start, unless the engine restored a selection of
  /// its own — the user is then already looking at a page.
  Future<void> _applyStartupTarget() async {
    if (await _hasRestoredSelection()) return;
    if (!ref.mounted) return;

    await applyTarget();
  }

  /// Whether the restored session came with a selected tab.
  ///
  /// The answer cannot be read off [selectedTabProvider] the moment restore
  /// completes: the two facts travel over independent native flows, and only
  /// the selected-tab one is debounced (~50ms, so that it lands after the
  /// tab-added and tab-list events). Restore-complete therefore reliably
  /// *overtakes* the selection it implies, and reading at that instant reports
  /// no tab for a session that has one. Acting on that latches the home surface
  /// over the restored tab, where it stays until the user picks a tab by hand.
  ///
  /// So the absence is waited on rather than read. [GeckoTabService.syncEvents]
  /// nudges native into pushing the current selection undebounced, but its
  /// reply is deliberately not the signal: native replies once it has *sent*
  /// the event, which says nothing about the event having arrived here — it
  /// travels on its own channel, and Flutter orders messages within a channel,
  /// not across them. The event itself is the signal; the nudge only shortens
  /// the wait for it.
  Future<bool> _hasRestoredSelection() async {
    if (ref.read(selectedTabProvider) != null) return true;

    final completer = Completer<bool>();

    // A ValueStream, so a selection that arrived before this subscription is
    // replayed into it — the gap between the read above and here cannot swallow
    // the event.
    final subscription = ref
        .read(eventServiceProvider)
        .selectedTabEvents
        .listen((tabId) {
          if (tabId != null && !completer.isCompleted) {
            completer.complete(true);
          }
        });

    // Bounds the wait for a session that genuinely restored nothing. Paid only
    // in that case, and against the home surface — which is already on screen
    // while no tab is selected, so the delay costs a resume that happens
    // slightly later, not a visible stall.
    final timeout = Timer(_restoredSelectionWindow, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    unawaited(
      GeckoTabService().syncEvents(onSelectedTabChange: true).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        // Non-fatal: the debounced push still arrives within the window.
        logger.w(
          'Failed to request the selected tab for the startup home target',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );

    try {
      return await completer.future;
    } finally {
      timeout.cancel();
      await subscription.cancel();
    }
  }

  @override
  void build() {
    ref.listen(
      fireImmediately: true,
      browserRestoreCompleteProvider,
      (previous, next) {
        if (!next || _startupHandled) return;
        _startupHandled = true;

        // This controller is created lazily by the browser view. Restore can
        // already be complete by then, and a plain listen would sit waiting for
        // an edge that has been and gone, silently skipping the startup resume.
        unawaited(_applyStartupTarget());
      },
    );
  }
}
