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
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/space.dart';
import 'package:weblibre/features/share_intent/domain/entities/share_intent_space_mode.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

part 'share_intent_space.g.dart';

/// The space a shared link should open in without asking, or `null` for "no
/// opinion".
///
/// `null` is deliberate output, not a missing case: [TabRepository.addTab]
/// already falls back to the selected space (and, failing that,
/// [SpaceRepository.ensureDefaultSpace]) when it is handed no `spaceUuid`.
/// Resolving that fallback here too would just be a second, competing
/// definition of "default space" to keep in sync with the first — better to
/// have exactly one place that decides it.
///
/// [ShareIntentSpaceMode.fixed] only wins when the space it names still
/// exists: `shareIntentSpaceUuid` is advisory, because the space it points at
/// can be deleted long after the setting was chosen.
///
/// A provider rather than a bare function so both call sites — a widget's
/// `WidgetRef` and a provider's `Ref` — reach it the same way, through
/// `ref.read(...future)`.
@Riverpod(keepAlive: false)
Future<String?> resolveShareIntentSpaceUuid(Ref ref) async {
  final settings = ref.read(zenSettingsWithDefaultsProvider);
  if (settings.shareIntentSpaceMode != ShareIntentSpaceMode.fixed) {
    return null;
  }

  final uuid = settings.shareIntentSpaceUuid;
  if (uuid == null) {
    return null;
  }

  final space = await ref
      .read(spaceRepositoryProvider.notifier)
      .getSpace(uuid);
  return space != null ? uuid : null;
}
