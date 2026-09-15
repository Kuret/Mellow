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
import 'package:nullability/nullability.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/features/browser/presentation/dialogs/delete_data.dart';
import 'package:weblibre/features/intent_gatekeeper/domain/entities/intent_source_policy.dart';
import 'package:weblibre/features/intent_gatekeeper/domain/services/package_label_resolver.dart';
import 'package:weblibre/features/settings/presentation/controllers/save_settings.dart';
import 'package:weblibre/features/settings/presentation/widgets/sections.dart';
import 'package:weblibre/features/settings/presentation/widgets/settings_detail.dart';
import 'package:weblibre/features/user/data/models/engine_settings.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/engine_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

const List<SettingsSectionDefinition> privacySecuritySettingsSections = [
  SettingsSectionDefinition(
    title: 'Tracking Protection',
    keywords: ['privacy'],
    entries: [
      SettingsEntryDefinition(
        title: 'Enhanced Tracking Protection',
        subtitle: 'Choose how aggressively trackers are blocked',
        keywords: ['etp', 'standard', 'strict', 'custom'],
        child: _EnhancedTrackingProtectionSection(),
      ),
      SettingsEntryDefinition(
        title: 'Tracking Protection Exceptions',
        subtitle: 'Sites where tracking protection is disabled',
        keywords: ['exceptions'],
        child: _TrackingProtectionExceptionsTile(),
      ),
      SettingsEntryDefinition(
        title: 'uBlock Filter Lists & Hardenings',
        subtitle: 'Manage filter lists and apply Mellow hardenings',
        keywords: ['ublock', 'filters'],
        child: _UBlockFilterListsTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Connection',
    keywords: ['connection security'],
    entries: [
      SettingsEntryDefinition(
        title: 'DNS over HTTPS',
        subtitle: 'Encrypt DNS lookups',
        keywords: ['doh'],
        child: _DnsTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Data',
    keywords: ['data management'],
    entries: [
      SettingsEntryDefinition(
        title: 'Incognito Mode',
        subtitle: 'Delete selected browsing data on app restart',
        keywords: ['private mode', 'privacy signals', 'modes'],
        child: _IncognitoModeSection(),
      ),
      SettingsEntryDefinition(
        title: 'Delete Browsing Data',
        subtitle: 'Clear history, cookies, and other browsing data',
        keywords: ['clear data'],
        child: _DeleteBrowsingDataTile(),
      ),
      SettingsEntryDefinition(
        title: 'Auto-Clear History',
        subtitle: 'Automatically clear history after a chosen duration',
        keywords: ['history retention'],
        child: _AutoClearHistorySection(),
      ),
      SettingsEntryDefinition(
        title: 'Auto-Clear Unassigned Tabs',
        subtitle: 'Automatically close tabs not assigned to a container',
        keywords: ['cleanup tabs'],
        child: _AutoClearUnassignedTabsSection(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Advanced',
    keywords: ['advanced security'],
    entries: [
      SettingsEntryDefinition(
        title: 'Block apps from opening your browser',
        subtitle: 'Control which apps may launch Mellow directly',
        keywords: [
          'intent gatekeeper',
          'external apps',
          'app-opening protection',
        ],
        child: _AppOpeningProtectionSection(),
      ),
      SettingsEntryDefinition(
        title: 'Web Engine Hardening',
        subtitle: 'Harden browser engine behavior and defaults',
        keywords: ['hardening'],
        child: _WebEngineHardeningTile(),
      ),
    ],
  ),
];

class PrivacySecuritySettingsScreen extends StatelessWidget {
  const PrivacySecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'Privacy & Security',
      subtitle:
          'Tracking protection, fingerprinting, browsing data, and network hardening.',
      icon: MdiIcons.shieldLock,
      sections: privacySecuritySettingsSections,
    );
  }
}

class _TrackingProtectionExceptionsTile extends StatelessWidget {
  const _TrackingProtectionExceptionsTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(MdiIcons.shieldOffOutline),
      title: const Text('Tracking Protection Exceptions'),
      subtitle: const Text('Sites where tracking protection is disabled'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await TrackingProtectionExceptionsRoute().push(context);
      },
    );
  }
}

class _IncognitoModeSection extends HookConsumerWidget {
  const _IncognitoModeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteBrowsingDataOnQuit = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.deleteBrowsingDataOnQuit,
      ),
    );

    return Column(
      children: [
        SwitchListTile.adaptive(
          title: const Text('Incognito Mode'),
          subtitle: const Text(
            'Deletes selected browsing data upon app restart for enhanced privacy.',
          ),
          secondary: const Icon(MdiIcons.incognito),
          value: deleteBrowsingDataOnQuit != null,
          onChanged: (value) async {
            await ref
                .read(saveGeneralSettingsControllerProvider.notifier)
                .save(
                  (currentSettings) => value
                      ? currentSettings.copyWith.deleteBrowsingDataOnQuit({})
                      : currentSettings.copyWith.deleteBrowsingDataOnQuit(null),
                );
          },
        ),
        if (deleteBrowsingDataOnQuit != null)
          _DeleteBrowsingDataTypes(selectedTypes: deleteBrowsingDataOnQuit),
      ],
    );
  }
}

class _DeleteBrowsingDataTypes extends HookConsumerWidget {
  final Set<DeleteBrowsingDataType> selectedTypes;

  const _DeleteBrowsingDataTypes({required this.selectedTypes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        children: [
          for (final type in DeleteBrowsingDataType.values)
            CheckboxListTile.adaptive(
              value: selectedTypes.contains(type),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(type.title),
              subtitle: type.description.mapNotNull(
                (description) => Text(description),
              ),
              onChanged: (value) async {
                final notifier = ref.read(
                  saveGeneralSettingsControllerProvider.notifier,
                );

                if (value == true) {
                  await notifier.save(
                    (currentSettings) =>
                        currentSettings.copyWith.deleteBrowsingDataOnQuit({
                          ...currentSettings.deleteBrowsingDataOnQuit!,
                          type,
                        }),
                  );
                } else {
                  await notifier.save(
                    (currentSettings) =>
                        currentSettings.copyWith.deleteBrowsingDataOnQuit(
                          {...currentSettings.deleteBrowsingDataOnQuit!}
                            ..remove(type),
                        ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}

class _DeleteBrowsingDataTile extends StatelessWidget {
  const _DeleteBrowsingDataTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Delete Browsing Data'),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      leading: const Icon(MdiIcons.databaseRemove),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await showDeleteDataDialog(context);
      },
    );
  }
}

class _AutoClearHistorySection extends HookConsumerWidget {
  const _AutoClearHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAutoCleanInterval = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.historyAutoCleanInterval,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Auto-Clear History'),
            subtitle: Text(
              'Automatically delete browsing history older than the selected time period',
            ),
            leading: Icon(MdiIcons.deleteClock),
            contentPadding: EdgeInsets.zero,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: DropdownMenu<Duration>(
              initialSelection: historyAutoCleanInterval,
              inputDecorationTheme: InputDecorationTheme(
                prefixIconConstraints: BoxConstraints.tight(
                  const Size.square(24),
                ),
              ),
              width: double.infinity,
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: Duration.zero, label: 'Never'),
                DropdownMenuEntry(value: Duration(days: 1), label: '1 Day'),
                DropdownMenuEntry(value: Duration(days: 3), label: '3 Days'),
                DropdownMenuEntry(value: Duration(days: 7), label: '1 Week'),
                DropdownMenuEntry(value: Duration(days: 14), label: '2 Weeks'),
                DropdownMenuEntry(value: Duration(days: 30), label: '1 Month'),
                DropdownMenuEntry(value: Duration(days: 90), label: '3 Months'),
              ],
              onSelected: (value) async {
                await ref
                    .read(saveGeneralSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) => currentSettings.copyWith
                          .historyAutoCleanInterval(value ?? Duration.zero),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoClearUnassignedTabsSection extends HookConsumerWidget {
  const _AutoClearUnassignedTabsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unassignedTabsAutoCleanInterval = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.unassignedTabsAutoCleanInterval,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Auto-Clear Unassigned Tabs'),
            subtitle: Text(
              'Automatically close unassigned tabs older than the selected time period',
            ),
            leading: Icon(MdiIcons.tabRemove),
            contentPadding: EdgeInsets.zero,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: DropdownMenu<Duration>(
              initialSelection: unassignedTabsAutoCleanInterval,
              inputDecorationTheme: InputDecorationTheme(
                prefixIconConstraints: BoxConstraints.tight(
                  const Size.square(24),
                ),
              ),
              width: double.infinity,
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: Duration.zero, label: 'Never'),
                DropdownMenuEntry(value: Duration(days: 1), label: '1 Day'),
                DropdownMenuEntry(value: Duration(days: 3), label: '3 Days'),
                DropdownMenuEntry(value: Duration(days: 7), label: '1 Week'),
                DropdownMenuEntry(value: Duration(days: 14), label: '2 Weeks'),
                DropdownMenuEntry(value: Duration(days: 30), label: '1 Month'),
                DropdownMenuEntry(value: Duration(days: 90), label: '3 Months'),
              ],
              onSelected: (value) async {
                await ref
                    .read(saveGeneralSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) => currentSettings.copyWith
                          .unassignedTabsAutoCleanInterval(
                            value ?? Duration.zero,
                          ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DnsTile extends StatelessWidget {
  const _DnsTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('DNS over HTTPS'),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      leading: const Icon(MdiIcons.dns),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await DohSettingsRoute().push(context);
      },
    );
  }
}

class _EnhancedTrackingProtectionSection extends HookConsumerWidget {
  const _EnhancedTrackingProtectionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingProtectionPolicy = ref.watch(
      engineSettingsWithDefaultsProvider.select(
        (s) => s.trackingProtectionPolicy,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Enhanced Tracking Protection'),
            leading: Icon(MdiIcons.incognitoCircleOff),
            contentPadding: EdgeInsets.zero,
          ),
          RadioGroup(
            groupValue: trackingProtectionPolicy,
            onChanged: (value) async {
              if (value != null) {
                // Save the policy change
                await ref
                    .read(saveEngineSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) => currentSettings.copyWith
                          .trackingProtectionPolicy(value),
                    );
              }
            },
            child: const Column(
              children: [
                RadioListTile<TrackingProtectionPolicy>.adaptive(
                  value: TrackingProtectionPolicy.none,
                  title: Text('Disabled'),
                ),
                RadioListTile<TrackingProtectionPolicy>.adaptive(
                  value: TrackingProtectionPolicy.recommended,
                  title: Text('Standard'),
                  subtitle: Text(
                    'Balances protection and compatibility by blocking fewer tracker categories.',
                  ),
                ),
                RadioListTile<TrackingProtectionPolicy>.adaptive(
                  value: TrackingProtectionPolicy.strict,
                  title: Text('Strict'),
                  subtitle: Text(
                    'Blocks more tracker categories, including tracking content, but may break some sites.',
                  ),
                ),
                RadioListTile<TrackingProtectionPolicy>.adaptive(
                  value: TrackingProtectionPolicy.custom,
                  toggleable: true,
                  title: Text('Custom'),
                  subtitle: Text(
                    'Blocks the strict categories with total cookie '
                    'protection.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebEngineHardeningTile extends StatelessWidget {
  const _WebEngineHardeningTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Web Engine Hardening'),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      leading: const Icon(MdiIcons.shieldLock),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await WebEngineHardeningRoute().push(context);
      },
    );
  }
}

class _UBlockFilterListsTile extends StatelessWidget {
  const _UBlockFilterListsTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('uBlock Filter Lists & Hardenings'),
      subtitle: const Text('Manage filter lists and apply Mellow hardenings'),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      leading: const Icon(Icons.filter_list),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await UBlockFilterListsRoute().push<void>(context);
      },
    );
  }
}

class _AppOpeningProtectionSection extends HookConsumerWidget {
  const _AppOpeningProtectionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.blockExternalAppsEnabled,
      ),
    );
    final policies = ref.watch(
      generalSettingsWithDefaultsProvider.select(
        (s) => s.externalAppIntentPolicies,
      ),
    );

    return Column(
      children: [
        const SettingSection(name: 'App-Opening Protection'),
        SwitchListTile.adaptive(
          title: const Text('Block apps from opening your browser'),
          subtitle: const Text(
            'Ask before opening links that other apps send to Mellow.',
          ),
          secondary: const Icon(MdiIcons.appsBox),
          value: enabled,
          onChanged: (value) async {
            await ref
                .read(saveGeneralSettingsControllerProvider.notifier)
                .save(
                  (current) => current.copyWith.blockExternalAppsEnabled(value),
                );
          },
        ),
        if (enabled && policies.isNotEmpty)
          _ManagedAppPolicyList(policies: policies),
      ],
    );
  }
}

class _ManagedAppPolicyList extends HookConsumerWidget {
  final Map<String, IntentSourcePolicy> policies;

  const _ManagedAppPolicyList({required this.policies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = policies.entries.toList(growable: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Managed apps', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final entry in entries)
            _ManagedAppPolicyTile(
              packageName: entry.key,
              policy: entry.value,
              onAction: (action) async {
                final notifier = ref.read(
                  saveGeneralSettingsControllerProvider.notifier,
                );
                switch (action) {
                  case _PolicyAction.allow:
                    await notifier.save(
                      (current) => current.copyWith.externalAppIntentPolicies({
                        ...current.externalAppIntentPolicies,
                        entry.key: IntentSourcePolicy.allow,
                      }),
                    );
                  case _PolicyAction.block:
                    await notifier.save(
                      (current) => current.copyWith.externalAppIntentPolicies({
                        ...current.externalAppIntentPolicies,
                        entry.key: IntentSourcePolicy.block,
                      }),
                    );
                  case _PolicyAction.remove:
                    await notifier.save(
                      (current) => current.copyWith.externalAppIntentPolicies(
                        {...current.externalAppIntentPolicies}
                          ..remove(entry.key),
                      ),
                    );
                }
              },
            ),
        ],
      ),
    );
  }
}

class _ManagedAppPolicyTile extends HookConsumerWidget {
  final String packageName;
  final IntentSourcePolicy policy;
  final Future<void> Function(_PolicyAction action) onAction;

  const _ManagedAppPolicyTile({
    required this.packageName,
    required this.policy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(
      packageLabelProvider(packageName).select((value) => value.value),
    );
    final hasLabel = label != null && label.isNotEmpty;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        policy == IntentSourcePolicy.allow
            ? MdiIcons.checkCircleOutline
            : MdiIcons.cancel,
      ),
      title: Text(hasLabel ? label : packageName),
      subtitle: Text(
        hasLabel
            ? '${policy == IntentSourcePolicy.allow ? 'Always allowed' : 'Always blocked'} · $packageName'
            : (policy == IntentSourcePolicy.allow
                  ? 'Always allowed'
                  : 'Always blocked'),
      ),
      trailing: PopupMenuButton<_PolicyAction>(
        onSelected: onAction,
        itemBuilder: (context) => const [
          PopupMenuItem(value: _PolicyAction.allow, child: Text('Allow')),
          PopupMenuItem(value: _PolicyAction.block, child: Text('Block')),
          PopupMenuItem(value: _PolicyAction.remove, child: Text('Remove')),
        ],
      ),
    );
  }
}

enum _PolicyAction { allow, block, remove }
