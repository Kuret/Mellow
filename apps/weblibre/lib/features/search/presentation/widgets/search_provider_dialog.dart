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
import 'package:weblibre/features/search/domain/entities/builtin_search_providers.dart';
import 'package:weblibre/features/search/domain/entities/search_provider.dart';
import 'package:weblibre/features/search/presentation/widgets/search_provider_icon.dart';

/// Asks the user which engine to search with.
///
/// The catalogue is eight entries, so it fits in a dialog and needs neither a
/// search field nor a route of its own — which is what the bang picker this
/// replaced needed.
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
        for (final provider in builtinSearchProviders)
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
    ),
  );
}
