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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/providers/app_state.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/settings/presentation/controllers/save_settings.dart';
import 'package:mellow/features/settings/presentation/dialogs/user_agent_restart_dialog.dart';
import 'package:mellow/features/settings/presentation/widgets/custom_list_tile.dart';
import 'package:mellow/features/settings/presentation/widgets/settings_detail.dart';
import 'package:mellow/features/user/data/models/engine_settings.dart';
import 'package:mellow/features/user/domain/providers.dart';
import 'package:mellow/features/user/domain/repositories/cache.dart';
import 'package:mellow/features/user/domain/repositories/engine_settings.dart';
import 'package:mellow/utils/exit_app.dart';

const List<SettingsSectionDefinition> advancedSettingsSections = [
  SettingsSectionDefinition(
    title: 'Web Engine',
    keywords: ['engine', 'content', 'identity'],
    entries: [
      SettingsEntryDefinition(
        title: 'Enable JavaScript',
        subtitle: 'Turn website scripting on or off',
        keywords: ['javascript'],
        child: _JavaScriptTile(),
      ),
      SettingsEntryDefinition(
        title: 'Custom User Agent',
        subtitle: 'Override the browser user agent string',
        keywords: ['ua'],
        child: _UserAgentTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Developer',
    keywords: ['debug', 'developer tools'],
    entries: [
      SettingsEntryDefinition(
        title: 'Remote debugging via USB',
        subtitle: 'Attach Firefox DevTools from a computer',
        keywords: ['devtools', 'inspect', 'debugging', 'adb'],
        child: _RemoteDebuggingTile(),
      ),
      SettingsEntryDefinition(
        title: 'Error Logs',
        subtitle: 'View and copy logs for issue reporting',
        keywords: ['logs'],
        child: _ErrorLogsTile(),
      ),
      SettingsEntryDefinition(
        title: 'Icon Cache',
        subtitle: 'Stored favicons',
        keywords: ['favicons', 'cache'],
        child: _IconCacheTile(),
      ),
      SettingsEntryDefinition(
        title: 'Reset UI',
        subtitle: 'Rebuild the entire browser UI',
        keywords: ['refresh ui'],
        child: _ResetUITile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Profile',
    keywords: ['user', 'profile'],
    entries: [
      SettingsEntryDefinition(
        title: 'Back up this profile',
        subtitle: 'Write an encrypted backup file of the profile you are using',
        keywords: [
          'backup',
          'archive',
          'export',
          'save',
          'encrypted',
          'restore',
        ],
        child: _BackupProfileTile(),
      ),
      SettingsEntryDefinition(
        title: 'Export & Import Settings',
        subtitle: 'Move settings to another profile, device, or a bug report',
        keywords: [
          'export',
          'import',
          'settings',
          'transfer',
          'share',
          'clipboard',
          'json',
          'copy',
          'migrate',
        ],
        child: _SettingsTransferTile(),
      ),
    ],
  ),
];

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'Advanced',
      subtitle:
          'Engine behavior, developer tools, and profile-level housekeeping.',
      icon: MdiIcons.tuneVertical,
      sections: advancedSettingsSections,
    );
  }
}

class _JavaScriptTile extends HookConsumerWidget {
  const _JavaScriptTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final javascriptEnabled = ref.watch(
      engineSettingsWithDefaultsProvider.select((s) => s.javascriptEnabled),
    );

    return SwitchListTile.adaptive(
      title: const Text('Enable JavaScript'),
      subtitle: const Text(
        'While turning off JavaScript can boost security, privacy, and speed, it may cause some sites to not work as intended.',
      ),
      // ignore: deprecated_member_use use this icon for now
      secondary: const Icon(MdiIcons.languageJavascript),
      value: javascriptEnabled,
      onChanged: (value) async {
        await ref
            .read(saveEngineSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.javascriptEnabled(value),
            );
      },
    );
  }
}

class _UserAgentTile extends HookConsumerWidget {
  const _UserAgentTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAgent = ref.watch(
      engineSettingsWithDefaultsProvider.select((s) => s.userAgent),
    );

    final userAgentTextController = useTextEditingController(
      text: userAgent,
      keys: [userAgent],
    );

    return ListTile(
      leading: const Icon(MdiIcons.cardAccountDetails),
      title: TextField(
        controller: userAgentTextController,
        decoration: const InputDecoration(
          labelText: 'Custom User Agent',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: 'Mozilla/5.0 …',
        ),
        onSubmitted: (value) async {
          await ref
              .read(saveEngineSettingsControllerProvider.notifier)
              .save(
                (currentSettings) => currentSettings.copyWith.userAgent(value),
              );

          if (context.mounted) {
            final restart = await showUserAgentRestartDialog(context);

            if (restart == true) {
              await exitApp(ref.container);
            }
          }
        },
      ),
    );
  }
}

class _RemoteDebuggingTile extends HookConsumerWidget {
  const _RemoteDebuggingTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteDebuggingEnabled = ref.watch(
      engineSettingsWithDefaultsProvider.select(
        (s) => s.remoteDebuggingEnabled,
      ),
    );

    return SwitchListTile.adaptive(
      title: const Text('Remote debugging via USB'),
      subtitle: const Text(
        'While this is on, anything that can reach the debugger socket on this '
        'device can inspect and control the browser',
      ),
      secondary: const Icon(MdiIcons.bugOutline),
      value: remoteDebuggingEnabled,
      onChanged: (value) async {
        await ref
            .read(saveEngineSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.remoteDebuggingEnabled(value),
            );
      },
    );
  }
}

class _IconCacheTile extends HookConsumerWidget {
  const _IconCacheTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(
      iconCacheSizeMegabytesProvider.select((value) => value.value),
    );

    return CustomListTile(
      title: 'Icon Cache',
      subtitle: 'Stored favicons',
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Icon(
          Icons.image,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: DefaultTextStyle(
          style: GoogleFonts.robotoMono(
            textStyle: DefaultTextStyle.of(context).style,
          ),
          child: Table(
            columnWidths: const {0: FixedColumnWidth(100)},
            children: [
              TableRow(
                children: [
                  const Text('Size'),
                  Text('${size?.toStringAsFixed(2) ?? 0} MB'),
                ],
              ),
            ],
          ),
        ),
      ),
      suffix: FilledButton.icon(
        onPressed: () async {
          await ref.read(cacheRepositoryProvider.notifier).clearCache();
        },
        icon: const Icon(Icons.delete),
        label: const Text('Clear'),
      ),
    );
  }
}

class _ErrorLogsTile extends StatelessWidget {
  const _ErrorLogsTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.bug_report,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: const Text('Error Logs'),
      subtitle: const Text('View and copy logs for issue reporting'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await ErrorLogsRoute().push(context);
      },
    );
  }
}

class _ResetUITile extends ConsumerWidget {
  const _ResetUITile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomListTile(
      title: 'Reset UI',
      subtitle: 'Rebuild the entire browser UI',
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Icon(
          Icons.bug_report,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      suffix: FilledButton.icon(
        onPressed: () {
          ref.read(appStateKeyProvider.notifier).reset();
        },
        icon: const Icon(Icons.restore),
        label: const Text('Reset'),
      ),
    );
  }
}

/// Takes a backup of the *active* profile without switching away from it.
///
/// The route it opens is the same one the user list reaches, and nothing about
/// the operation is special-cased here: the backup is queued and taken by the
/// next process, with the profile closed. This tile exists only because backing
/// up the profile you are using is the common case, and getting to it through
/// Profiles → yourself → Backup is not an obvious path.
class _BackupProfileTile extends HookConsumerWidget {
  const _BackupProfileTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(selectedProfileProvider);

    return ListTile(
      enabled: profile.hasValue,
      leading: const Icon(MdiIcons.safe),
      title: const Text('Back up this profile'),
      subtitle: Text(switch (profile) {
        AsyncData(:final value) =>
          'Write "${value.name}" to an encrypted backup file',
        AsyncError() => 'Could not read the active profile',
        _ => 'Loading…',
      }),
      trailing: const Icon(Icons.chevron_right),
      onTap: profile.hasValue
          ? () async {
              await BackupProfileRoute(
                profile: jsonEncode(profile.requireValue.toJson()),
              ).push(context);
            }
          : null,
    );
  }
}

/// Settings only — the profile backup above it is the whole-profile answer.
///
/// Sits next to it because that is where people look for "get my setup onto
/// the other device", and the two differ in what they carry rather than in
/// where they live.
class _SettingsTransferTile extends StatelessWidget {
  const _SettingsTransferTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(MdiIcons.swapHorizontal),
      title: const Text('Export & Import Settings'),
      subtitle: const Text(
        'Write settings to a file or the clipboard, and read them back',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => const SettingsTransferRoute().push(context),
    );
  }
}
