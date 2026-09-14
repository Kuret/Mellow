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
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/features/user/data/models/engine_settings.dart';
import 'package:weblibre/features/user/data/models/ublock_filter_list_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/data/providers/ublock_assets.dart';
import 'package:weblibre/features/user/domain/repositories/engine_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

part 'profile_defaults.g.dart';

/// Bump this whenever a new default needs seeding into existing profiles.
///
/// [ProfileDefaultsService.applyIfOwed] compares it against the persisted
/// `ZenSettings.profileDefaultsRevision` and only runs the seed once per
/// profile: a fresh profile starts here without ever having seen the
/// (now-deleted) onboarding wizard, and an upgraded profile that already
/// carries the wizard's choices must not have them overwritten.
const profileDefaultsTargetRevision = 1;

/// True when [settings] is exactly `UBlockFilterListSettings()` — i.e. the
/// profile has never enabled uBlock filtering or curated a list of its own.
///
/// Seeding the optimized defaults on top of a profile that already made its
/// own choice (whether that choice came from a previous onboarding run or
/// from Settings) would silently discard that choice, so the caller must
/// check this before writing.
bool isPristineUBlockFilterListSettings(UBlockFilterListSettings settings) {
  return !settings.enabled &&
      settings.enabledStockListTokens.isEmpty &&
      settings.autoEnabledStockListTokens.isEmpty &&
      settings.externalFilterLists.isEmpty;
}

@Riverpod()
class ProfileDefaultsService extends _$ProfileDefaultsService {
  Future<void> _seedUBlockDefaults() async {
    final engineRepository = ref.read(
      engineSettingsRepositoryProvider.notifier,
    );
    final current = await ref.read(engineSettingsRepositoryProvider.future);

    if (!isPristineUBlockFilterListSettings(
      current.ublockFilterListSettings,
    )) {
      return;
    }

    final registry = await ref.read(ublockAssetsRegistryProvider.future);
    final optimized = UBlockFilterListSettings.optimizedDefaults(registry);

    await engineRepository.updateSettings(
      (current) => current.copyWith.ublockFilterListSettings(optimized),
    );
  }

  /// Seeds this fork's own defaults into a profile exactly once.
  ///
  /// These used to be applied by the first-run onboarding wizard, which has
  /// been removed. A fresh profile must land in the same place without ever
  /// seeing that wizard, and an already-onboarded profile must not have its
  /// choices replayed on every launch — hence the revision gate.
  ///
  /// Each seeded default is independently wrapped: a failure in one (a
  /// missing asset, a Gecko IPC error) must not block the others, and the
  /// revision is written regardless of the outcome so a permanently failing
  /// seed cannot retry on every single launch. It simply stays un-applied
  /// until fixed, same as the onboarding wizard's failures used to.
  Future<void> applyIfOwed() async {
    final settings = ref.read(zenSettingsWithDefaultsProvider);

    if (settings.profileDefaultsRevision >= profileDefaultsTargetRevision) {
      return;
    }

    try {
      await _seedUBlockDefaults();
    } catch (e, s) {
      logger.w(
        'Failed seeding uBlock profile defaults',
        error: e,
        stackTrace: s,
      );
    }

    await ref
        .read(zenSettingsRepositoryProvider.notifier)
        .updateSettings(
          (current) => current.copyWith(
            profileDefaultsRevision: profileDefaultsTargetRevision,
          ),
        );
  }

  @override
  void build() {}
}
