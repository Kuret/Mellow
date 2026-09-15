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
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/app_links/domain/entities/app_link_rule.dart';
import 'package:mellow/features/settings/presentation/controllers/save_settings.dart';
import 'package:mellow/features/settings/presentation/widgets/settings_detail.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';

const List<SettingsSectionDefinition> linksSitesSettingsSections = [
  SettingsSectionDefinition(
    title: 'Opening Links',
    keywords: ['navigation'],
    entries: [
      SettingsEntryDefinition(
        title: 'Open Links in Apps',
        subtitle: 'Choose how external app links open',
        keywords: ['app links', 'external apps'],
        child: _AppLinksModeSection(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Desktop Mode',
    entries: [
      SettingsEntryDefinition(
        title: 'Always Request Desktop Site',
        subtitle: 'Open new tabs in desktop mode by default',
        keywords: ['desktop mode', 'user agent', 'mobile site', 'tablet'],
        child: _GlobalDesktopModeTile(),
      ),
      SettingsEntryDefinition(
        title: 'Desktop Mode Sites',
        subtitle: 'Sites that always load in desktop mode',
        keywords: ['desktop mode', 'per-site', 'user agent', 'exceptions'],
        child: _DesktopModeSitesTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Web Apps',
    keywords: ['home screen', 'pwa'],
    entries: [
      SettingsEntryDefinition(
        title: 'Install Sites as Apps',
        subtitle: 'Allow websites without a manifest to be installed as apps',
        keywords: ['pwa', 'web apps'],
        child: _AllowNonManifestPwaInstallTile(),
      ),
    ],
  ),
];

class LinksSitesSettingsScreen extends StatelessWidget {
  const LinksSitesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'Links & Sites',
      subtitle: 'How links open, and what individual sites are served.',
      icon: MdiIcons.compassOutline,
      sections: linksSitesSettingsSections,
    );
  }
}

class _AppLinksModeSection extends HookConsumerWidget {
  const _AppLinksModeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLinksMode = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.appLinksMode),
    );
    final rules = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.appLinkRules),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Open Links in Apps'),
            subtitle: Text(
              'Choose how links that can be opened in other apps are handled',
            ),
            leading: Icon(MdiIcons.openInApp),
            contentPadding: EdgeInsets.zero,
          ),
          RadioGroup(
            groupValue: appLinksMode,
            onChanged: (value) async {
              if (value != null) {
                await ref
                    .read(saveGeneralSettingsControllerProvider.notifier)
                    .save((current) => current.copyWith.appLinksMode(value));
              }
            },
            child: const Column(
              children: [
                RadioListTile.adaptive(
                  value: AppLinksMode.always,
                  title: Text('Always'),
                  subtitle: Text(
                    'Always open links in their native apps without asking',
                  ),
                ),
                RadioListTile.adaptive(
                  value: AppLinksMode.ask,
                  title: Text('Ask before opening'),
                  subtitle: Text('Show a prompt before opening links in apps'),
                ),
                RadioListTile.adaptive(
                  value: AppLinksMode.never,
                  title: Text('Never'),
                  subtitle: Text(
                    'Always open links in the browser instead of apps',
                  ),
                ),
              ],
            ),
          ),
          _AppLinkRulesSubsection(rules: rules),
        ],
      ),
    );
  }
}

/// Managed per-site app-link rules (§2.5): "always open" and "never open"
/// decisions the user remembered from a prompt. Read-only list with removal.
class _AppLinkRulesSubsection extends ConsumerWidget {
  final Map<String, PersistedAppLinkRule> rules;

  const _AppLinkRulesSubsection({required this.rules});

  String _displayScope(String scope) {
    if (scope.startsWith('host:')) return scope.substring('host:'.length);
    if (scope.startsWith('pkg:')) return scope.substring('pkg:'.length);
    return scope;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rules.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = rules.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 4),
          child: Text('Remembered site rules'),
        ),
        for (final MapEntry(:key, :value) in entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              value.decision == AppLinkRuleDecision.alwaysOpen
                  ? MdiIcons.openInApp
                  : Icons.public,
            ),
            title: Text(_displayScope(key)),
            subtitle: Text(
              value.decision == AppLinkRuleDecision.alwaysOpen
                  ? 'Always open in the app'
                  : 'Always keep in the browser',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove rule',
              onPressed: () async {
                await ref
                    .read(saveGeneralSettingsControllerProvider.notifier)
                    .save(
                      (current) => current.copyWith.appLinkRules(
                        {...current.appLinkRules}..remove(key),
                      ),
                    );
              },
            ),
          ),
      ],
    );
  }
}

class _GlobalDesktopModeTile extends HookConsumerWidget {
  const _GlobalDesktopModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalDesktopMode = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.globalDesktopMode),
    );

    return SwitchListTile.adaptive(
      title: const Text('Always Request Desktop Site'),
      subtitle: const Text(
        'Open new tabs in desktop mode by default. You can still toggle desktop '
        'mode per tab from the page menu.',
      ),
      secondary: const Icon(MdiIcons.monitor),
      value: globalDesktopMode,
      onChanged: (value) async {
        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.globalDesktopMode(value),
            );
      },
    );
  }
}

class _DesktopModeSitesTile extends StatelessWidget {
  const _DesktopModeSitesTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.desktop_windows),
      title: const Text('Desktop Mode Sites'),
      subtitle: const Text('Sites that always load in desktop mode'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await const DesktopModeSitesRoute().push(context);
      },
    );
  }
}

class _AllowNonManifestPwaInstallTile extends HookConsumerWidget {
  const _AllowNonManifestPwaInstallTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowNonManifestPwaInstall = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.allowNonManifestPwaInstall,
      ),
    );

    return SwitchListTile.adaptive(
      title: const Text('Install Sites as Apps'),
      subtitle: const Text(
        'Allow installing websites without a PWA manifest as standalone apps',
      ),
      secondary: const Icon(Icons.add_to_home_screen),
      value: allowNonManifestPwaInstall,
      onChanged: (value) async {
        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.allowNonManifestPwaInstall(value),
            );
      },
    );
  }
}
