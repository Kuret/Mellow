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
import 'package:mellow/features/geckoview/features/tabs/data/entities/container_filter.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';

class ContainerTitle extends HookConsumerWidget {
  final ContainerData container;

  const ContainerTitle({super.key, required this.container});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (container.name.isNotEmpty) {
      return Text(container.name, overflow: TextOverflow.ellipsis, maxLines: 1);
    }

    final containerHasTabs = ref.watch(
      containerTabCountProvider(
        // ignore: provider_parameters
        ContainerFilterById(containerId: container.id),
      ).select((value) => (value.value ?? 0) > 0),
    );

    return Text(
      containerHasTabs ? 'Untitled' : 'Empty',
      style: const TextStyle(fontStyle: FontStyle.italic),
    );
  }
}
