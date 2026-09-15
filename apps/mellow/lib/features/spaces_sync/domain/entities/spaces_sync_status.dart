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
import 'package:fast_equatable/fast_equatable.dart';

/// Why the destructive-batch canary refused an upload (DESIGN "Hardening
/// against Zen's stale-projection race", defence 5).
enum SpacesSyncBlockReason {
  /// The batch would tombstone more of this device's syncable tabs than the
  /// configured fraction/count allows.
  tombstoneVolume,

  /// The batch creates a record whose id this device applied a tombstone for
  /// moments ago — the exact signature of Zen's stale-projection race.
  resurrection,
}

/// A refused outgoing batch, kept until the user explicitly retries.
class SpacesSyncBlockedBatch with FastEquatable {
  SpacesSyncBlockedBatch({
    required this.reason,
    required this.tombstoneCount,
    required this.limit,
    required this.sampleIds,
    required this.at,
  });

  final SpacesSyncBlockReason reason;

  /// Tombstones the refused batch carried (`0` for a resurrection block, whose
  /// offending records are creates).
  final int tombstoneCount;

  /// The volume limit in force when the batch was refused; `0` for a
  /// resurrection block, which has no limit to compare against.
  final int limit;

  /// Up to five of the offending record ids, for the log and the settings card.
  final List<String> sampleIds;

  final DateTime at;

  String get description => switch (reason) {
    SpacesSyncBlockReason.tombstoneVolume =>
      'This sync would delete $tombstoneCount items on the desktop, more '
          'than the $limit allowed in one batch.',
    SpacesSyncBlockReason.resurrection =>
      'This sync would re-create ${sampleIds.length} item(s) this device '
          'just deleted on the desktop.',
  };

  @override
  List<Object?> get hashParameters => [
    reason,
    tombstoneCount,
    limit,
    sampleIds,
    at,
  ];
}

/// What the Zen Spaces sync client last did, for the settings screen.
class SpacesSyncStatus with FastEquatable {
  SpacesSyncStatus({
    this.lastSyncAt,
    this.lastError,
    this.writesBlockedReason,
    this.engineVersionSeen,
    this.engineEnabled,
    this.lastHealedCount = 0,
    this.syncing = false,
    this.blockedBatch,
  });

  /// When the last sync finished without throwing.
  final DateTime? lastSyncAt;

  /// The last failure, in words; cleared by the next clean sync.
  final String? lastError;

  /// Set while the desktop declares a `spaces` engine version this client
  /// does not write (PLAN §8.6 item 3): reading continues, uploads stop.
  final String? writesBlockedReason;

  /// `meta/global.engines.spaces.version` from the last sync.
  final int? engineVersionSeen;

  /// `false` when `meta/global` carries no `spaces` engine: Zen has not
  /// enabled the engine on this account yet, so there is nothing to do.
  /// `null` until the first sync has looked.
  final bool? engineEnabled;

  /// How many records the last sync re-applied from the desktop because
  /// uploads were off and this device had diverged from them (the read-only
  /// heal); `0` when uploads are on or nothing had diverged.
  final int lastHealedCount;

  final bool syncing;

  /// Set when the destructive-batch canary refused an upload. While it is set
  /// the client keeps reading but uploads nothing; only
  /// `SpacesSyncService.retryBlockedBatch()` clears it.
  final SpacesSyncBlockedBatch? blockedBatch;

  SpacesSyncStatus copyWith({
    DateTime? lastSyncAt,
    Object? lastError = _absent,
    Object? writesBlockedReason = _absent,
    int? engineVersionSeen,
    bool? engineEnabled,
    int? lastHealedCount,
    bool? syncing,
    Object? blockedBatch = _absent,
  }) => SpacesSyncStatus(
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastError: lastError == _absent ? this.lastError : lastError as String?,
    writesBlockedReason: writesBlockedReason == _absent
        ? this.writesBlockedReason
        : writesBlockedReason as String?,
    engineVersionSeen: engineVersionSeen ?? this.engineVersionSeen,
    engineEnabled: engineEnabled ?? this.engineEnabled,
    lastHealedCount: lastHealedCount ?? this.lastHealedCount,
    syncing: syncing ?? this.syncing,
    blockedBatch: blockedBatch == _absent
        ? this.blockedBatch
        : blockedBatch as SpacesSyncBlockedBatch?,
  );

  static const _absent = Object();

  @override
  List<Object?> get hashParameters => [
    lastSyncAt,
    lastError,
    writesBlockedReason,
    engineVersionSeen,
    engineEnabled,
    lastHealedCount,
    syncing,
    blockedBatch,
  ];
}
