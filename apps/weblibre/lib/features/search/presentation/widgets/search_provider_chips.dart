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
import 'package:weblibre/features/geckoview/features/browser/domain/providers.dart';
import 'package:weblibre/features/search/domain/entities/builtin_search_providers.dart';
import 'package:weblibre/features/search/domain/providers/search_provider.dart';
import 'package:weblibre/features/search/presentation/widgets/search_provider_icon.dart';

/// Horizontal picker for the engine the next search goes to.
///
/// Selecting a chip overrides the standing default for this search only, via
/// [selectedSearchProviderProvider]; tapping the selected chip again drops the
/// override. When [domain] is set the override is scoped to that site, so
/// choosing an engine while editing a page's address does not change where the
/// next search from a blank tab goes.
class SearchProviderChips extends ConsumerWidget {
  final String? domain;

  const SearchProviderChips({required this.domain, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultProvider = ref.watch(defaultSearchProviderProvider);
    final siteSelected = domain != null
        ? ref.watch(selectedSearchProviderProvider(domain: domain))
        : null;
    final globalSelected = ref.watch(selectedSearchProviderProvider());

    // The chip that reads as "on" is whatever this search would use right now,
    // an override if there is one and the standing default otherwise.
    final active = siteSelected ?? globalSelected ?? defaultProvider;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final provider in builtinSearchProviders)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                showCheckmark: false,
                avatar: SearchProviderIcon(provider: provider),
                label: Text(provider.name),
                selected: provider.id == active.id,
                onSelected: (selected) {
                  // Site and global overrides are mutually exclusive: a stale
                  // site choice must not shadow the one just made globally.
                  if (domain != null) {
                    ref
                        .read(
                          selectedSearchProviderProvider(
                            domain: domain,
                          ).notifier,
                        )
                        .clear();
                  }

                  final notifier = ref.read(
                    selectedSearchProviderProvider().notifier,
                  );

                  if (selected) {
                    notifier.select(provider);
                  } else {
                    notifier.clear();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
