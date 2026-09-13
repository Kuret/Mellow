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
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/features/geckoview/domain/providers/restore_complete.dart';
import 'package:weblibre/features/geckoview/domain/providers/selected_tab.dart';
import 'package:weblibre/features/geckoview/domain/providers/tab_list.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/providers.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

part 'live_tab_budget.g.dart';

/// Keeps the number of live engine sessions within
/// [GeneralSettings.maxLiveTabs] (PLAN §7.4 item 5).
///
/// Whenever the engine's tab list or the budget changes, and once the list
/// has been quiet for [settleDelay], the least recently used regular tabs
/// (by `tab.timestamp`) are unloaded back to cold rows through
/// [TabRepository.demoteToCold], one every [demoteGap], until the count is
/// within budget. The selected tab, pinned and essential tabs and private
/// tabs are never unloaded. Memory pressure from the OS trims harder, down to
/// half the budget. Nothing is unloaded while the session restore is still
/// running: a partial tab list would read as "over budget" for nothing.
///
/// Long-lived: activate it with `_activateService` in `main.dart` (PLAN §3.6).
@Riverpod(keepAlive: true)
class LiveTabBudget extends _$LiveTabBudget with WidgetsBindingObserver {
  static const settleDelay = Duration(seconds: 2);
  static const demoteGap = Duration(milliseconds: 250);

  Timer? _settleTimer;
  bool _enforcing = false;

  @override
  void build() {
    WidgetsBinding.instance.addObserver(this);

    ref.listen(tabListProvider, (_, _) => _scheduleEnforcement());
    ref.listen(
      generalSettingsWithDefaultsProvider.select((s) => s.maxLiveTabs),
      (_, _) => _scheduleEnforcement(),
    );
    ref.listen(
      browserRestoreCompleteProvider,
      (_, _) => _scheduleEnforcement(),
      fireImmediately: true,
    );

    ref.onDispose(() {
      _settleTimer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });
  }

  int get _maxLiveTabs =>
      ref.read(generalSettingsWithDefaultsProvider).maxLiveTabs;

  void _scheduleEnforcement() {
    _settleTimer?.cancel();
    _settleTimer = Timer(settleDelay, () {
      unawaited(enforce(_maxLiveTabs));
    });
  }

  @override
  void didHaveMemoryPressure() {
    _settleTimer?.cancel();
    unawaited(enforce(max(minMaxLiveTabs, _maxLiveTabs ~/ 2)));
  }

  /// Unloads least recently used tabs until at most [target] are live.
  ///
  /// One pass at a time; a pass already running keeps its own target. Live
  /// means listed by the engine, so the count also covers private tabs, which
  /// are never unloaded themselves.
  Future<void> enforce(int target) async {
    if (_enforcing || !ref.read(browserRestoreCompleteProvider)) {
      return;
    }
    _enforcing = true;
    try {
      var live = ref.read(tabListProvider).value.length;
      if (live <= target) {
        return;
      }

      final candidates = await ref
          .read(tabDatabaseProvider)
          .tabDao
          .liveDemotionCandidates()
          .get();
      if (!ref.mounted) return;
      final repository = ref.read(tabRepositoryProvider.notifier);

      for (final candidate in candidates) {
        if (live <= target || !ref.mounted) {
          return;
        }
        if (candidate.id == ref.read(selectedTabProvider) ||
            !ref.read(tabListProvider).value.contains(candidate.id)) {
          continue;
        }
        if (await repository.demoteToCold(candidate.id)) {
          live -= 1;
          if (live <= target) {
            return;
          }
          await Future<void>.delayed(demoteGap);
        }
      }
    } catch (error, stackTrace) {
      logger.e(
        'Live tab budget pass failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _enforcing = false;
    }
  }
}
