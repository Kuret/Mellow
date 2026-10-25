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
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/spaces_sync/domain/spaces_sync_service.dart';

/// A compact strip at the foot of the rail's shelves while the
/// destructive-batch canary holds an upload back (DESIGN "Hardening against
/// Zen's stale-projection race", defence 5). Until the user reviews the batch
/// in Settings > Firefox Sync nothing this device does reaches the desktop,
/// which used to go unnoticed for days; the strip is the chrome's one hint.
/// Renders nothing while no batch is blocked.
class SpacesSyncPausedNotice extends ConsumerWidget {
  const SpacesSyncPausedNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(
      spacesSyncServiceProvider.select((s) => s.blockedBatch),
    );
    if (blocked == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    void review() => SyncSettingsRoute().push(context);
    // One node for the whole strip: the two text lines read as a single
    // button rather than two labels and a tap target.
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: 'Sync upload paused, tap to review',
      onTap: review,
      child: Material(
        color: scheme.errorContainer,
        child: InkWell(
          onTap: review,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 20,
                    color: scheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sync upload paused',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onErrorContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Tap to review',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onErrorContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlays a small [ColorScheme.error] dot on the top-right of [child] while
/// the canary holds an upload back; the compact bar puts it on the space
/// indicator, whose quick menu then carries the "Sync upload paused" row.
/// Just [child] while no batch is blocked.
class SpacesSyncPausedBadge extends ConsumerWidget {
  const SpacesSyncPausedBadge({required this.child, super.key});

  final Widget child;

  /// Diameter of the dot.
  static const dotSize = 8.0;

  /// Finds the dot in tests; it has no text or icon of its own.
  @visibleForTesting
  static const dotKey = Key('spaces_sync_paused_dot');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(
      spacesSyncServiceProvider.select((s) => s.blockedBatch),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (blocked != null)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: DecoratedBox(
                key: dotKey,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: dotSize),
              ),
            ),
          ),
      ],
    );
  }
}
