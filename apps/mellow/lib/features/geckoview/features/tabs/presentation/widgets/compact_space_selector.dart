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
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/space_icon.dart';

/// A compact space selector: the chip shows the selected space's icon and
/// name, and tapping opens a menu of every space.
///
/// Unlike [CompactContainerSelector], there is always something to select —
/// [SpaceRepository.ensureDefaultSpace] guarantees at least one space exists
/// — so there is no "unassigned" state and the result is a plain uuid rather
/// than a selection result. The picker is a [MenuAnchor] rather than a route
/// or a modal sheet because this widget is itself used from inside a bottom
/// sheet (see `OpenSharedContent`), where a nested modal sheet is fragile.
class CompactSpaceSelector extends ConsumerWidget {
  final String? selectedSpaceUuid;
  final ValueChanged<String>? onSelectionChanged;
  final bool emphasizeSelection;

  const CompactSpaceSelector({
    super.key,
    this.selectedSpaceUuid,
    this.onSelectionChanged,
    this.emphasizeSelection = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(watchSpacesProvider).value ?? const <SpaceData>[];
    final colorScheme = Theme.of(context).colorScheme;

    SpaceData? selected;
    for (final space in spaces) {
      if (space.uuid == selectedSpaceUuid) {
        selected = space;
        break;
      }
    }

    final showSelectedHighlight = selected != null && emphasizeSelection;

    return MenuAnchor(
      builder: (context, controller, child) {
        return FilterChip(
          avatar: SpaceIconAvatar(icon: selected?.icon, radius: 9),
          label: Text(
            selected != null && selected.name.isNotEmpty
                ? selected.name
                : 'Space',
            style: TextStyle(
              fontWeight: showSelectedHighlight
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          color: WidgetStatePropertyAll(
            showSelectedHighlight
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainer,
          ),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          selected: false,
          showCheckmark: false,
          onSelected: (_) {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        for (final space in spaces)
          MenuItemButton(
            leadingIcon: SpaceIconAvatar(icon: space.icon, radius: 12),
            onPressed: () => onSelectionChanged?.call(space.uuid),
            child: Text(space.name.isNotEmpty ? space.name : 'Space'),
          ),
      ],
    );
  }
}
