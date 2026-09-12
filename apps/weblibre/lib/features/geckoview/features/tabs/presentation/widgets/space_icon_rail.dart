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
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_icon.dart';

/// The space switcher at the foot of the wide vertical rail (PLAN §9 W1):
/// one round icon per space, the selected one highlighted, and a trailing
/// "+" that opens the editor for a new space. Tap selects, long-press opens
/// the space editor. Scrolls horizontally when the spaces outgrow the rail.
class SpaceIconRail extends ConsumerWidget {
  const SpaceIconRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces =
        ref.watch(watchSpacesProvider.select((value) => value.value)) ??
        const <SpaceData>[];
    final selectedSpaceUuid = ref.watch(selectedSpaceProvider);

    return SpaceIconRailView(
      entries: [
        for (final space in spaces)
          SpaceIconRailEntry(
            id: space.uuid,
            icon: space.icon,
            name: space.name,
            selected: space.uuid == selectedSpaceUuid,
          ),
      ],
      onSelected: (id) {
        ref.read(selectedSpaceProvider.notifier).space = id;
      },
      onEdit: (id) => SpaceEditRoute(uuid: id).push(context),
      onCreate: () => const SpaceCreateRoute().push(context),
    );
  }
}

/// One space in the [SpaceIconRailView].
class SpaceIconRailEntry {
  final String id;
  final String? icon;
  final String name;
  final bool selected;

  const SpaceIconRailEntry({
    required this.id,
    required this.icon,
    required this.name,
    required this.selected,
  });
}

/// Provider-free rendering of [SpaceIconRail], shared with the settings
/// preview.
class SpaceIconRailView extends StatelessWidget {
  final List<SpaceIconRailEntry> entries;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onEdit;
  final VoidCallback? onCreate;

  const SpaceIconRailView({
    super.key,
    required this.entries,
    this.onSelected,
    this.onEdit,
    this.onCreate,
  });

  /// Diameter of one space circle.
  static const circleSize = 40.0;

  /// Height of the whole row, circles plus their vertical padding.
  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _SpaceCircle(
                entry: entry,
                onTap: onSelected == null ? null : () => onSelected!(entry.id),
                onLongPress: onEdit == null ? null : () => onEdit!(entry.id),
              ),
            ),
          Tooltip(
            message: 'New space',
            child: Material(
              color: Colors.transparent,
              shape: CircleBorder(side: BorderSide(color: scheme.outline)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onCreate,
                child: SizedBox(
                  width: circleSize,
                  height: circleSize,
                  child: Icon(Icons.add, size: 20, color: scheme.onSurface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceCircle extends StatelessWidget {
  final SpaceIconRailEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _SpaceCircle({
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = entry.selected
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final foreground = entry.selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final displayName = entry.name.isEmpty ? 'Space' : entry.name;
    final icon = entry.icon?.trim();

    // Zen's icon is a free string (usually an emoji). Fall back to the first
    // letter of the space's name so unlabelled spaces still tell apart.
    final Widget glyph = icon != null && icon.isNotEmpty
        ? SpaceIcon(icon: icon, size: 20, color: foreground)
        : Text(
            entry.name.isEmpty
                ? '?'
                : entry.name.characters.first.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          );

    return Tooltip(
      message: displayName,
      child: Material(
        color: fill,
        shape: CircleBorder(
          side: entry.selected
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: SpaceIconRailView.circleSize,
            height: SpaceIconRailView.circleSize,
            child: Center(child: glyph),
          ),
        ),
      ),
    );
  }
}
