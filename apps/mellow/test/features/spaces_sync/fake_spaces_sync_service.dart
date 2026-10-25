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
import 'package:mellow/features/spaces_sync/domain/entities/spaces_sync_status.dart';
import 'package:mellow/features/spaces_sync/domain/spaces_sync_service.dart';

/// A `SpacesSyncService` that never syncs: `build` just reports the status it
/// was given, so widgets that watch the provider see a blocked (or clear)
/// batch without the real service's database, token or engine behind it.
///
/// Any widget test that pumps the compact bar, the space indicator or the
/// quick menu needs one of these in its overrides, since those watch the
/// provider for the paused-upload notice.
class FakeSpacesSyncService extends SpacesSyncService {
  FakeSpacesSyncService([SpacesSyncStatus? status])
    : _status = status ?? SpacesSyncStatus();

  /// A service whose canary has refused a batch, so the paused-upload notice
  /// and badge show.
  FakeSpacesSyncService.paused()
    : _status = SpacesSyncStatus(blockedBatch: pausedBatch());

  final SpacesSyncStatus _status;

  /// A representative refused batch: thirty tombstones against the floor of
  /// twenty.
  static SpacesSyncBlockedBatch pausedBatch() => SpacesSyncBlockedBatch(
    reason: SpacesSyncBlockReason.tombstoneVolume,
    tombstoneCount: 30,
    limit: 20,
    sampleIds: const ['t0', 't1'],
    at: DateTime(2026, 10, 25),
  );

  @override
  SpacesSyncStatus build() => _status;
}
