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
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/core/design/app_colors.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/app_links/domain/entities/app_link_rule.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/compact_space_selector.dart';
import 'package:weblibre/features/settings/presentation/controllers/save_settings.dart';
import 'package:weblibre/features/settings/presentation/widgets/settings_detail.dart';
import 'package:weblibre/features/share_intent/domain/entities/share_intent_space_mode.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart';
import 'package:weblibre/features/user/data/models/zen_settings.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';
import 'package:weblibre/features/user/domain/repositories/zen_settings.dart';

const List<SettingsSectionDefinition> browsingSettingsSections = [
  SettingsSectionDefinition(
    title: 'Tabs',
    entries: [
      SettingsEntryDefinition(
        title: 'Keep at most N tabs loaded',
        subtitle: 'Unload the least recently used tabs beyond this many',
        keywords: ['memory', 'unload', 'cold', 'live', 'loaded'],
        child: _MaxLiveTabsSection(),
      ),
      SettingsEntryDefinition(
        title: 'Separate essentials per container',
        subtitle: 'Each container keeps its own Essentials strip',
        keywords: ['essentials', 'pinned', 'spaces', 'containers', 'zen'],
        child: _SeparateEssentialsTile(),
      ),
      SettingsEntryDefinition(
        title: 'Show Container UI',
        subtitle: 'Show container selectors, menus, and management',
        keywords: ['containers'],
        child: _ShowContainerUiTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Navigation',
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
    title: 'Home Screen',
    entries: [
      SettingsEntryDefinition(
        title: 'Install Sites as Apps',
        subtitle: 'Allow websites without a manifest to be installed as apps',
        keywords: ['pwa', 'web apps'],
        child: _AllowNonManifestPwaInstallTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'External Links',
    entries: [
      SettingsEntryDefinition(
        title: 'External Link Handling',
        subtitle: 'Choose how external links open in WebLibre',
        keywords: ['intents'],
        child: _ExternalLinkHandlingSection(),
      ),
      SettingsEntryDefinition(
        title: 'Shared Link Space',
        subtitle: 'Choose which space a shared link opens in',
        keywords: ['share', 'shared link', 'space', 'spaces', 'send to'],
        child: _ShareIntentSpaceSection(),
      ),
      SettingsEntryDefinition(
        title: 'Custom Tabs',
        subtitle:
            'Let other apps open links in a lightweight in-app tab, instead '
            'of the main browser',
        keywords: [
          'custom tabs',
          'in-app browser',
          'chrome custom tabs',
          'external app',
          'share',
        ],
        child: _CustomTabsTile(),
      ),
    ],
  ),
  SettingsSectionDefinition(
    title: 'Bookmarks',
    entries: [
      SettingsEntryDefinition(
        title: 'Bookmark Open Behavior',
        subtitle: 'Choose how tapping a bookmark opens it',
        keywords: ['bookmarks', 'open', 'custom tab'],
        child: _BookmarkOpenBehaviorSection(),
      ),
    ],
  ),
];

class BrowsingSettingsScreen extends StatelessWidget {
  const BrowsingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'Browsing',
      subtitle: 'Tabs, navigation and app links.',
      icon: MdiIcons.compassOutline,
      sections: browsingSettingsSections,
    );
  }
}

class _ExternalLinkHandlingSection extends HookConsumerWidget {
  const _ExternalLinkHandlingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(generalSettingsWithDefaultsProvider);
    final tabIntentOpenSetting = settings.tabIntentOpenSetting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('External Link Handling'),
            subtitle: Text('Choose how external links open in WebLibre'),
            leading: Icon(MdiIcons.tabPlus),
            contentPadding: EdgeInsets.zero,
          ),
          RadioGroup(
            groupValue: tabIntentOpenSetting,
            onChanged: (value) async {
              if (value != null) {
                await ref
                    .read(saveGeneralSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) =>
                          currentSettings.copyWith.tabIntentOpenSetting(value),
                    );
              }
            },
            child: Column(
              children: [
                const RadioListTile.adaptive(
                  value: TabIntentOpenSetting.ask,
                  title: Text('Prompt'),
                  subtitle: Text('Ask how external links should open'),
                  secondary: Icon(MdiIcons.messageQuestion),
                ),
                const RadioListTile.adaptive(
                  value: TabIntentOpenSetting.regular,
                  title: Text('Regular'),
                  subtitle: Text('Open external links in a regular tab'),
                  secondary: Icon(MdiIcons.tab),
                ),
                RadioListTile.adaptive(
                  value: TabIntentOpenSetting.private,
                  title: const Text('Private'),
                  subtitle: const Text('Open external links in a private tab'),
                  secondary: Icon(
                    MdiIcons.dominoMask,
                    color: AppColors.of(context).privateTabPurple,
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

/// Which space a link shared in from another app opens in — a separate
/// question from [_ExternalLinkHandlingSection] above, which decides regular
/// vs. private vs. asking. This decides *where among spaces*, and only
/// matters once a link is actually going to land in a tab (so it applies to
/// every branch above, `ask` included: `OpenSharedContent` asks it there
/// too).
class _ShareIntentSpaceSection extends ConsumerWidget {
  const _ShareIntentSpaceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(zenSettingsWithDefaultsProvider);
    final mode = settings.shareIntentSpaceMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text('Shared Link Space'),
          subtitle: Text('Choose which space a shared link opens in'),
          leading: Icon(MdiIcons.viewDashboardOutline),
          contentPadding: EdgeInsets.zero,
        ),
        RadioGroup(
          groupValue: mode,
          onChanged: (value) async {
            if (value != null) {
              await ref
                  .read(saveZenSettingsControllerProvider.notifier)
                  .save(
                    (currentSettings) =>
                        currentSettings.copyWith.shareIntentSpaceMode(value),
                  );
            }
          },
          child: const Column(
            children: [
              RadioListTile.adaptive(
                value: ShareIntentSpaceMode.ask,
                title: Text('Ask'),
                subtitle: Text('Choose the space each time a link arrives'),
                secondary: Icon(MdiIcons.messageQuestion),
              ),
              RadioListTile.adaptive(
                value: ShareIntentSpaceMode.fixed,
                title: Text('Always the same space'),
                subtitle: Text('Shared links always open in one chosen space'),
                secondary: Icon(MdiIcons.pin),
              ),
            ],
          ),
        ),
        if (mode == ShareIntentSpaceMode.fixed)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16),
            title: const Text('Space'),
            trailing: CompactSpaceSelector(
              selectedSpaceUuid: settings.shareIntentSpaceUuid,
              emphasizeSelection: false,
              onSelectionChanged: (uuid) async {
                await ref
                    .read(saveZenSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) => currentSettings.copyWith
                          .shareIntentSpaceUuid(uuid),
                    );
              },
            ),
          ),
      ],
    );
  }
}

class _BookmarkOpenBehaviorSection extends HookConsumerWidget {
  const _BookmarkOpenBehaviorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(generalSettingsWithDefaultsProvider);
    final bookmarkOpenSetting = settings.effectiveBookmarkOpenSetting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Bookmark Open Behavior'),
            subtitle: Text('Choose how tapping a bookmark opens it'),
            leading: Icon(MdiIcons.bookmarkMultiple),
            contentPadding: EdgeInsets.zero,
          ),
          RadioGroup(
            groupValue: bookmarkOpenSetting,
            onChanged: (value) async {
              if (value != null) {
                await ref
                    .read(saveGeneralSettingsControllerProvider.notifier)
                    .save(
                      (currentSettings) =>
                          currentSettings.copyWith.bookmarkOpenSetting(value),
                    );
              }
            },
            child: Column(
              children: [
                const RadioListTile.adaptive(
                  value: BookmarkOpenSetting.ask,
                  title: Text('Prompt'),
                  subtitle: Text('Ask how the bookmark should open'),
                  secondary: Icon(MdiIcons.messageQuestion),
                ),
                const RadioListTile.adaptive(
                  value: BookmarkOpenSetting.regular,
                  title: Text('Regular'),
                  subtitle: Text('Open the bookmark in a regular tab'),
                  secondary: Icon(MdiIcons.tab),
                ),
                RadioListTile.adaptive(
                  value: BookmarkOpenSetting.private,
                  title: const Text('Private'),
                  subtitle: const Text('Open the bookmark in a private tab'),
                  secondary: Icon(
                    MdiIcons.dominoMask,
                    color: AppColors.of(context).privateTabPurple,
                  ),
                ),
                const RadioListTile.adaptive(
                  value: BookmarkOpenSetting.customTab,
                  title: Text('Custom Tab'),
                  subtitle: Text(
                    'Open the bookmark in a lightweight custom tab',
                  ),
                  secondary: Icon(MdiIcons.applicationOutline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Zen's `zen.workspaces.separate-essentials` (PLAN §6.4): whether the
/// Essentials strip is keyed on the current space's container or shared by
/// every space.
class _SeparateEssentialsTile extends ConsumerWidget {
  const _SeparateEssentialsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final separateEssentials = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.separateEssentials),
    );

    return SwitchListTile.adaptive(
      title: const Text('Separate essentials per container'),
      subtitle: const Text(
        'A space shows the essentials of its own container, as on the Zen '
        'desktop; off, every space shows all essentials',
      ),
      secondary: const Icon(MdiIcons.starBoxMultipleOutline),
      value: separateEssentials,
      onChanged: (value) async {
        await ref
            .read(saveZenSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.separateEssentials(value),
            );
      },
    );
  }
}

class _ShowContainerUiTile extends HookConsumerWidget {
  const _ShowContainerUiTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showContainerUi = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.showContainerUi),
    );

    return SwitchListTile.adaptive(
      title: const Text('Show Container UI'),
      subtitle: const Text('Show container selectors, menus, and management'),
      secondary: const Icon(MdiIcons.folder),
      value: showContainerUi,
      onChanged: (value) async {
        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.showContainerUi(value),
            );

        if (!value) {
          ref.read(selectedContainerProvider.notifier).clearContainer();
        }
      },
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

class _CustomTabsTile extends HookConsumerWidget {
  const _CustomTabsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customTabsEnabled = ref.watch(
      generalSettingsWithDefaultsProvider.select((s) => s.customTabsEnabled),
    );

    return SwitchListTile.adaptive(
      title: const Text('Custom Tabs'),
      subtitle: const Text(
        'Let other apps open links in a lightweight in-app tab. When off, '
        'these links and shared URLs open as normal tabs in the main browser.',
      ),
      secondary: const Icon(Icons.web_asset),
      value: customTabsEnabled,
      onChanged: (value) async {
        await ref
            .read(saveGeneralSettingsControllerProvider.notifier)
            .save(
              (currentSettings) =>
                  currentSettings.copyWith.customTabsEnabled(value),
            );
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

/// "Keep at most N tabs loaded" — [GeneralSettings.maxLiveTabs], the budget
/// `LiveTabBudget` enforces (PLAN §7.4). Steps of five between
/// [minMaxLiveTabs] and [maxMaxLiveTabs].
class _MaxLiveTabsSection extends HookConsumerWidget {
  static const _step = 5;

  const _MaxLiveTabsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxLiveTabs = ref.watch(
      zenSettingsWithDefaultsProvider.select((s) => s.maxLiveTabs),
    );
    final sliderValue = useState(maxLiveTabs.toDouble());
    useEffect(() {
      sliderValue.value = maxLiveTabs.toDouble();
      return null;
    }, [maxLiveTabs]);
    final shown = sliderValue.value.round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(MdiIcons.snowflakeVariant),
          title: Text('Keep at most $shown tabs loaded'),
          subtitle: const Text(
            'Tabs beyond this are unloaded, least recently used first, and '
            'load again when tapped',
          ),
          contentPadding: EdgeInsets.zero,
        ),
        Slider(
          min: minMaxLiveTabs.toDouble(),
          max: maxMaxLiveTabs.toDouble(),
          divisions: (maxMaxLiveTabs - minMaxLiveTabs) ~/ _step,
          label: '$shown',
          value: sliderValue.value.clamp(
            minMaxLiveTabs.toDouble(),
            maxMaxLiveTabs.toDouble(),
          ),
          onChanged: (value) {
            sliderValue.value = value;
          },
          onChangeEnd: (value) async {
            final rounded = ((value / _step).round() * _step).clamp(
              minMaxLiveTabs,
              maxMaxLiveTabs,
            );
            sliderValue.value = rounded.toDouble();
            await ref
                .read(saveZenSettingsControllerProvider.notifier)
                .save(
                  (currentSettings) =>
                      currentSettings.copyWith.maxLiveTabs(rounded),
                );
          },
        ),
      ],
    );
  }
}
