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
import 'package:weblibre/features/search/presentation/widgets/search_provider_dialog.dart';
import 'package:weblibre/features/search/presentation/widgets/search_provider_icon.dart';
import 'package:weblibre/features/settings/presentation/controllers/save_settings.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';

class DefaultSearchSelector extends HookConsumerWidget {
  const DefaultSearchSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProvider = ref.watch(defaultSearchProviderProvider);

    Future<void> updateSearchProvider(SearchProvider provider) async {
      await ref
          .read(saveGeneralSettingsControllerProvider.notifier)
          .save(
            (currentSettings) =>
                currentSettings.copyWith.defaultSearchProvider(provider.id),
          );
    }

    Future<void> pickProvider() async {
      final picked = await showSearchProviderDialog(
        context,
        selected: activeProvider,
      );

      if (picked != null) {
        await updateSearchProvider(picked);
      }
    }

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ActionChip(
              avatar: SearchProviderIcon(provider: activeProvider),
              label: Text(activeProvider.name),
              onPressed: pickProvider,
            ),
          ),
          IconButton(
            onPressed: pickProvider,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
