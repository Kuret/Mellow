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
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/features/search/domain/entities/builtin_search_providers.dart';
import 'package:weblibre/features/search/domain/entities/custom_search_providers.dart';
import 'package:weblibre/features/search/domain/entities/search_provider.dart';
import 'package:weblibre/features/search/presentation/widgets/search_provider_icon.dart';
import 'package:weblibre/features/settings/presentation/controllers/save_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

/// The engine catalogue as something to edit: the built-ins to read, the user's
/// own to add to, change and remove.
///
/// Deleting the engine that is currently the default is deliberately not
/// special-cased here. `defaultSearchProvider` resolves a stored id that names
/// no engine to `fallbackSearchProvider`, so the browser stays searchable
/// without this screen having to reach into another settings model to patch it
/// up.
class CustomSearchEnginesEditor extends ConsumerWidget {
  const CustomSearchEnginesEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final engines = ref.watch(
      zenSettingsWithDefaultsProvider.select(
        (settings) => settings.customSearchProviders,
      ),
    );

    Future<void> save(
      List<CustomSearchEngine> Function(List<CustomSearchEngine> current)
      update,
    ) async {
      await ref
          .read(saveZenSettingsControllerProvider.notifier)
          .save(
            (currentSettings) => currentSettings.copyWith.customSearchProviders(
              update(currentSettings.customSearchProviders),
            ),
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Built in',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final provider in builtinSearchProviders)
          ListTile(
            leading: SearchProviderIcon(provider: provider),
            title: Text(provider.name),
            subtitle: Text(provider.iconHost),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Your engines',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (engines.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Engines you add show up in every search provider picker, '
              'beside the built-in ones.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final engine in engines)
          ListTile(
            leading: SearchProviderIcon(provider: customSearchProvider(engine)),
            title: Text(engine.name),
            subtitle: Text(engine.urlTemplate),
            trailing: _EngineActions(
              onEdit: () async {
                final result = await _promptForEngine(context, initial: engine);
                if (result == null) {
                  return;
                }

                await save(
                  (current) => [
                    for (final entry in current)
                      if (entry.id == engine.id) result else entry,
                  ],
                );
              },
              onDelete: () async {
                await save(
                  (current) => [
                    for (final entry in current)
                      if (entry.id != engine.id) entry,
                  ],
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.add),
              label: const Text('Add search engine'),
              onPressed: () async {
                final result = await _promptForEngine(context);
                if (result == null) {
                  return;
                }

                await save((current) => [...current, result]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _EngineActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EngineActions({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          color: colorScheme.onSurfaceVariant,
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: colorScheme.onSurfaceVariant,
          tooltip: 'Remove',
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

Future<CustomSearchEngine?> _promptForEngine(
  BuildContext context, {
  CustomSearchEngine? initial,
}) {
  return showDialog<CustomSearchEngine>(
    context: context,
    builder: (context) => _CustomSearchEngineDialog(initial: initial),
  );
}

/// The add/edit form.
///
/// An edit keeps [CustomSearchEngine.id]: it is what the default-engine setting
/// persists, so minting a new one while renaming would quietly drop the user
/// back to the fallback engine.
class _CustomSearchEngineDialog extends HookWidget {
  final CustomSearchEngine? initial;

  const _CustomSearchEngineDialog({this.initial});

  @override
  Widget build(BuildContext context) {
    final isEdit = initial != null;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameController = useTextEditingController(text: initial?.name ?? '');
    final urlController = useTextEditingController(
      text: initial?.urlTemplate ?? '',
    );

    return AlertDialog(
      title: Text(isEdit ? 'Edit search engine' : 'Add search engine'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              autofocus: !isEdit,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Searx',
              ),
              validator: (value) => customSearchEngineNameError(value ?? ''),
            ),
            TextFormField(
              controller: urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Search URL',
                hintText:
                    'https://example.com/?q='
                    '${SearchProvider.searchTermsPlaceholder}',
                helperText:
                    '${SearchProvider.searchTermsPlaceholder} is replaced '
                    'with what you type.',
                helperMaxLines: 2,
              ),
              validator: (value) => customSearchEngineUrlError(value ?? ''),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) {
              return;
            }

            Navigator.of(context).pop(
              CustomSearchEngine(
                id: initial?.id ?? newCustomSearchProviderId(),
                name: nameController.text.trim(),
                urlTemplate: urlController.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
