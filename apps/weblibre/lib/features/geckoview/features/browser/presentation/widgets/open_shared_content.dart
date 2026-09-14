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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart'
    show GeckoAppLinksService;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weblibre/core/design/app_colors.dart';
import 'package:weblibre/extensions/uri.dart';
import 'package:weblibre/features/geckoview/domain/entities/tab_container_selection.dart';
import 'package:weblibre/features/geckoview/domain/repositories/tab.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/repositories/container.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_icon.dart';
import 'package:weblibre/features/share_intent/domain/entities/intent_container_mode.dart';
import 'package:weblibre/presentation/hooks/cached_future.dart';
import 'package:weblibre/presentation/hooks/debouncer.dart';
import 'package:weblibre/utils/form_validators.dart';
import 'package:weblibre/utils/ui_helper.dart';

/// Where a shared link should land.
///
/// The sheet is a list of destinations, not a form: every row opens the link
/// immediately, so there is no confirm step and no second action to explain.
/// The only editable thing is the URL itself, because a shared link is often
/// worth correcting before it is opened.
///
/// The container is deliberately not asked about. It is still resolved — from
/// the intent ([contextId]/[containerMode]), then the site assignment, then
/// the selected container — just silently, the same way the rest of the app
/// resolves it.
class OpenSharedContent extends HookConsumerWidget {
  final Uri sharedUrl;
  final String? contextId;
  final IntentContainerMode containerMode;

  static final _appLinksService = GeckoAppLinksService();

  const OpenSharedContent({
    super.key,
    required this.sharedUrl,
    this.contextId,
    this.containerMode = IntentContainerMode.useSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final textController = useTextEditingController(text: sharedUrl.toString());
    final appColors = AppColors.of(context);

    final globalSelectedContainer = ref.watch(
      selectedContainerDataProvider.select((value) => value.value),
    );
    final selectedContainer = useState<ContainerData?>(
      containerMode == IntentContainerMode.useSelected
          ? globalSelectedContainer
          : null,
    );

    final globalSelectedSpaceUuid = ref.watch(selectedSpaceProvider);

    // Which row is the one the app would have picked on its own. It only
    // highlights a row — every space stays one tap away.
    final defaultSpaceUuid = useState<String?>(globalSelectedSpaceUuid);

    useEffect(() {
      defaultSpaceUuid.value = globalSelectedSpaceUuid;
      return null;
    }, [globalSelectedSpaceUuid]);

    final currentUrl = useValueListenable(textController).text;

    // Debounce the URL to avoid running expensive operations on every keystroke.
    final debouncedUrl = useState(currentUrl);
    final debouncer = useDebouncer(const Duration(milliseconds: 300));
    useEffect(() {
      debouncer.eventOccured(() => debouncedUrl.value = currentUrl);
      return null;
    }, [currentUrl]);

    final parsedDebouncedUrl = parseValidatedUrl(
      debouncedUrl.value,
      eagerParsing: false,
    );

    final selectionUrlKey =
        parsedDebouncedUrl != null &&
            parsedDebouncedUrl.hasAuthority &&
            parsedDebouncedUrl.isHttpOrHttps
        ? parsedDebouncedUrl.toString()
        : null;

    useEffect(() {
      var cancelled = false;

      unawaited(
        Future(() async {
          ContainerData? resolved;
          final containerRepo = ref.read(containerRepositoryProvider.notifier);

          // Priority: explicit intent container (PWA shortcut) > site
          // assignment for the URL > mode default.
          if (containerMode == IntentContainerMode.specific &&
              contextId != null) {
            resolved = await containerRepo.getContainerByContextualIdentity(
              contextId!,
            );
          } else {
            if (selectionUrlKey != null) {
              final siteAssignedId = await containerRepo
                  .siteAssignedContainerId(Uri.parse(selectionUrlKey));
              if (siteAssignedId != null) {
                resolved = await containerRepo.getContainerData(siteAssignedId);
              }
            }

            resolved ??= switch (containerMode) {
              IntentContainerMode.useSelected => globalSelectedContainer,
              IntentContainerMode.unassigned ||
              IntentContainerMode.specific => null,
            };
          }

          if (cancelled || !context.mounted) {
            return;
          }

          selectedContainer.value = resolved;
        }),
      );

      return () {
        cancelled = true;
      };
    }, [containerMode, contextId, selectionUrlKey, globalSelectedContainer]);

    final appLink = useCachedFuture(
      // ignore: discarded_futures useFuture
      () => parsedDebouncedUrl != null
          ? _appLinksService.resolveAppLink(parsedDebouncedUrl)
          : Future.value(null),
      [parsedDebouncedUrl],
    );

    final spaces = ref.watch(watchSpacesProvider).value ?? const <SpaceData>[];

    /// Opens the URL currently in the field. [spaceUuid] is ignored by
    /// [TabRepository.addTab] for private tabs, which belong to no space
    /// (invariant I3).
    Future<void> openTab(TabMode tabMode, {String? spaceUuid}) async {
      if (formKey.currentState?.validate() != true) {
        return;
      }

      final parsedUrl = parseValidatedUrl(
        textController.text,
        eagerParsing: false,
      );
      if (parsedUrl == null) {
        return;
      }

      await ref
          .read(tabRepositoryProvider.notifier)
          .addTab(
            url: parsedUrl,
            tabMode: tabMode,
            containerSelection: selectedContainer.value == null
                ? const TabContainerSelection.unassigned()
                : TabContainerSelection.specific(selectedContainer.value!),
            spaceUuid: spaceUuid,
            launchedFromIntent: true,
            selectTab: true,
          );

      if (context.mounted) {
        context.pop(true);
      }
    }

    Future<void> openInApp() async {
      if (formKey.currentState?.validate() == true) {
        final uri = parseValidatedUrl(textController.text, eagerParsing: false);
        if (uri == null) return;

        final success = await _appLinksService.launchAppLink(uri);

        if (success && context.mounted) {
          context.pop(true);
        } else if (!success && context.mounted) {
          showErrorMessage(context, 'Could not open in app');
        }
      }
    }

    return SafeArea(
      child: Form(
        key: formKey,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Open link', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: textController,
                keyboardType: TextInputType.url,
                minLines: 1,
                maxLines: 10,
                validator: (value) {
                  return validateUrl(value, eagerParsing: false);
                },
              ),
              const SizedBox(height: 8),
              if (appLink.data != null)
                _OpenActionTile(
                  title: appLink.data?.appName != null
                      ? 'Open in ${appLink.data!.appName}'
                      : 'Open in App',
                  subtitle: 'Open in an installed app',
                  icon: Icons.open_in_new,
                  onTap: openInApp,
                ),
              Flexible(
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final space in spaces)
                      ListTile(
                        key: ValueKey('open-shared-space-${space.uuid}'),
                        leading: SpaceIconAvatar(icon: space.icon, radius: 16),
                        title: Text(
                          space.name.isNotEmpty ? space.name : 'Space',
                        ),
                        selected: space.uuid == defaultSpaceUuid.value,
                        onTap: () =>
                            openTab(TabMode.regular, spaceUuid: space.uuid),
                      ),
                  ],
                ),
              ),
              // A private tab is not a fifth space — it belongs to none — so
              // it reads as its own kind of choice.
              const Divider(),
              ListTile(
                key: const ValueKey('open-shared-private'),
                leading: Icon(
                  MdiIcons.dominoMask,
                  color: appColors.privateTabPurple,
                ),
                title: Text(
                  'Private',
                  style: TextStyle(color: appColors.privateTabPurple),
                ),
                onTap: () => openTab(TabMode.private),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _OpenActionTile({
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: Icon(icon),
      onTap: onTap,
    );
  }
}
