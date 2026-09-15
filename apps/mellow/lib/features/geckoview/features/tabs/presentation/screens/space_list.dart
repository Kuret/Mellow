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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/repositories/space.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/container_title.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/space_icon.dart';
import 'package:mellow/presentation/widgets/failure_widget.dart';

/// Every space by `order_index`, reorderable by drag handle; tapping a row
/// opens the editor and the FAB creates a new space.
class SpaceListScreen extends ConsumerWidget {
  const SpaceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(watchSpacesProvider);
    final selectedSpace = ref.watch(selectedSpaceProvider);
    final containers =
        ref.watch(
          watchContainersWithCountProvider.select((value) => value.value),
        ) ??
        const <ContainerDataWithCount>[];

    Widget buildList(List<SpaceData> spaces) {
      return CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Spaces')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            sliver: SliverReorderableList(
              itemCount: spaces.length,
              onReorderItem: (oldIndex, newIndex) {
                final order = [for (final space in spaces) space.uuid];
                final moved = order.removeAt(oldIndex);
                order.insert(newIndex.clamp(0, order.length), moved);
                unawaited(
                  ref
                      .read(spaceRepositoryProvider.notifier)
                      .reorderSpaces(order),
                );
              },
              itemBuilder: (context, index) {
                final space = spaces[index];
                final container = containers.firstWhereOrNull(
                  (c) => c.id == space.containerId,
                );
                return Padding(
                  key: ValueKey(space.uuid),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SpaceCard(
                    space: space,
                    container: container,
                    index: index,
                    isSelected: space.uuid == selectedSpace,
                    onTap: () => SpaceEditRoute(uuid: space.uuid).push(context),
                    onSelect: () =>
                        ref.read(selectedSpaceProvider.notifier).space =
                            space.uuid,
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: spacesAsync.when(
        skipLoadingOnReload: true,
        data: buildList,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FailureWidget(
            title: 'Failed to load spaces',
            exception: error,
            onRetry: () => ref.invalidate(watchSpacesProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => const SpaceCreateRoute().push(context),
        label: const Text('Space'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _SpaceCard extends ConsumerWidget {
  final SpaceData space;
  final ContainerData? container;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  const _SpaceCard({
    required this.space,
    required this.container,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tabCount = ref.watch(spaceTabCountProvider(space.uuid)).value ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? colorScheme.secondary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SpaceIconAvatar(icon: space.icon, radius: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        space.name.isEmpty ? 'Space' : space.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      DefaultTextStyle.merge(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        child: Row(
                          children: [
                            Text('$tabCount ${tabCount == 1 ? 'tab' : 'tabs'}'),
                            if (container != null) ...[
                              const Text(' · '),
                              Icon(
                                container!.icon.icon,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: ContainerTitle(container: container!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSelected)
                  IconButton(
                    tooltip: 'Switch to this space',
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: onSelect,
                  )
                else
                  Icon(Icons.check_circle, color: colorScheme.secondary),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.drag_indicator,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
