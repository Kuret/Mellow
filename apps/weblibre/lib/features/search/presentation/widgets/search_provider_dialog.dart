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
import 'package:weblibre/features/search/domain/entities/search_provider.dart';
import 'package:weblibre/features/search/domain/providers/search_provider.dart';
import 'package:weblibre/features/search/presentation/widgets/search_provider_icon.dart';

/// Asks the user which engine to search with.
///
/// The catalogue is the eight built-ins plus however many engines the user
/// added, so it still fits in a dialog and needs neither a search field nor a
/// route of its own — which is what the bang picker this replaced needed. The
/// list is scrollable so a user with a long shelf of their own engines can
/// still reach the bottom of it.
///
/// Returns the chosen provider, or null if the user dismissed the dialog.
Future<SearchProvider?> showSearchProviderDialog(
  BuildContext context, {
  SearchProvider? selected,
}) {
  return showDialog<SearchProvider>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Search provider'),
      children: [
        Consumer(
          builder: (context, ref, child) {
            final providers = ref.watch(allSearchProvidersProvider);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final provider in providers)
                  ListTile(
                    leading: SearchProviderIcon(provider: provider),
                    title: Text(provider.name),
                    trailing: provider.id == selected?.id
                        ? const Icon(Icons.check)
                        : null,
                    selected: provider.id == selected?.id,
                    onTap: () => Navigator.of(context).pop(provider),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
