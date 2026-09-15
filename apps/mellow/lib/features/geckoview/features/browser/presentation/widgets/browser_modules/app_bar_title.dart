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
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/design/app_colors.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/extensions/uri.dart';
import 'package:mellow/features/geckoview/domain/controllers/bottom_sheet.dart';
import 'package:mellow/features/geckoview/domain/entities/states/tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/features/browser/domain/entities/sheet.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/providers/site_settings_badge_provider.dart';
import 'package:mellow/features/geckoview/features/search/domain/entities/search_text.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:mellow/features/geckoview/features/tabs/utils/container_colors.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/presentation/widgets/qr_scanner_button.dart';
import 'package:mellow/presentation/widgets/speech_to_text_button.dart';
import 'package:mellow/presentation/widgets/uri_breadcrumb.dart';

class CompactAppBarTitle extends ConsumerWidget {
  const CompactAppBarTitle({
    super.key,
    this.containerColor,
    this.useCustomColor = false,
  });

  final Color? containerColor;
  final bool useCustomColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(selectedTabStateProvider);
    final selectedTabType = ref.watch(selectedTabTypeProvider);
    final settings = ref.watch(generalSettingsWithDefaultsProvider);
    final isTabTuneledAsync = ref.watch(isTabTunneledProvider(tabState?.id));
    final siteSettingsBadgeState = ref.watch(
      showSiteSettingsBadgeProvider.select(
        (value) => value.value ?? SiteSettingsBadgeState.hidden,
      ),
    );

    if (tabState == null) {
      return _EmptyAppBarAddressField(
        tabType: selectedTabType ?? TabType.regular,
        // The tools turn this field from "no page loaded" into the home
        // surface's search entry, which is only what it is when the pill has
        // stood down for it. Everywhere else the row has a page's worth of
        // buttons beside it and no width to spare.
        showSearchTools:
            ref.watch(shouldShowBrowserHomeProvider) &&
            settings.effectiveHomeSearchBarPlacement() ==
                HomeSearchBarPlacement.tabBar,
      );
    }

    return CompactAppBarTitleView(
      tabState: tabState,
      isTabTunneled:
          isTabTuneledAsync.hasValue && isTabTuneledAsync.value == true,
      siteSettingsBadgeState: siteSettingsBadgeState,
      containerColor: containerColor,
      useCustomColor: useCustomColor,
      onSiteSettingsTap: () {
        ref
            .read(bottomSheetControllerProvider.notifier)
            .show(SiteSettingsSheet(tabState: tabState));
      },
      onTitleTap: () async {
        await SearchRoute(
          tabId: tabState.id,
          searchText: searchTextForTab(tabState),
          tabType: tabState.tabMode.toTabType(),
        ).push(context);
      },
    );
  }
}

class CompactAppBarTitleView extends StatelessWidget {
  const CompactAppBarTitleView({
    super.key,
    required this.tabState,
    required this.isTabTunneled,
    required this.siteSettingsBadgeState,
    required this.onSiteSettingsTap,
    required this.onTitleTap,
    this.containerColor,
    this.useCustomColor = false,
  });

  final TabState tabState;
  final bool isTabTunneled;
  final SiteSettingsBadgeState siteSettingsBadgeState;
  final VoidCallback onSiteSettingsTap;
  final VoidCallback onTitleTap;
  final Color? containerColor;
  final bool useCustomColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = AppColors.of(context);
    final containerColor = this.containerColor;
    final containerPalette = containerColor != null
        ? ContainerColors.palette(
            context,
            containerColor,
            useCustomColor: useCustomColor,
          )
        : null;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTitleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: containerColor != null
                    ? containerPalette!.surfaceColor
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: containerPalette != null
                    ? Border.all(color: containerPalette.outlineColor)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tabState.tabMode is PrivateTabMode) ...[
                    Icon(
                      MdiIcons.dominoMask,
                      color: appColors.privateTabPurple,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (isTabTunneled) ...[
                    const Icon(MdiIcons.tunnelOutline, size: 16),
                    const SizedBox(width: 4),
                  ],
                  _SecurityStatusIcon(
                    tabState: tabState,
                    size: 16,
                    containerColor: containerPalette?.accentColor,
                  ),
                  // The site-settings shield used to ride on the favicon this
                  // row no longer has; it sits beside the lock instead, where
                  // it still names what the long press opens.
                  if (siteSettingsBadgeState != SiteSettingsBadgeState.hidden)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        siteSettingsBadgeState ==
                                SiteSettingsBadgeState.improved
                            ? MdiIcons.shield
                            : MdiIcons.shieldAlert,
                        size: 14,
                        color:
                            siteSettingsBadgeState ==
                                SiteSettingsBadgeState.improved
                            ? Colors.green
                            : appColors.warningAmber,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: UriBreadcrumb(
                      uri: tabState.url,
                      showHttpScheme: false,
                      // The pill's own sideways drag belongs to the space
                      // swipe on the bar.
                      scrollable: false,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      // Long press on the address bar: the way into site
                      // settings now that the favicon that used to open them
                      // is gone.
                      onTooltipTriggered: onSiteSettingsTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8.0),
      ],
    );
  }
}

class _SecurityStatusIcon extends StatelessWidget {
  const _SecurityStatusIcon({
    required this.tabState,
    required this.size,
    this.containerColor,
  });

  final TabState tabState;
  final double size;
  final Color? containerColor;

  @override
  Widget build(BuildContext context) {
    if (tabState.url.isHttp) {
      return Icon(
        MdiIcons.lockOff,
        color: Theme.of(context).colorScheme.error,
        size: size,
      );
    } else if (!tabState.securityInfoState.secure) {
      return Icon(
        MdiIcons.lockAlert,
        color: Theme.of(context).colorScheme.errorContainer,
        size: size,
      );
    } else if (!tabState.isLoading) {
      return Icon(MdiIcons.lock, color: containerColor, size: size);
    }

    return Icon(MdiIcons.timerSand, color: containerColor, size: size);
  }
}

/// The address field with no tab behind it.
///
/// With [showSearchTools] it is the home surface's search entry under
/// [HomeSearchBarPlacement.tabBar], and grows the same leading icon and
/// QR/voice buttons [HomeSearchPill] carries — the row is otherwise empty here
/// (no favicon, no site settings, no page actions), so there is room for them
/// exactly where there would not be beside a loaded page.
///
/// Like the pill, the tools cannot type into anything: there is no live field
/// in the toolbar. They hand their result to the search screen as its initial
/// text, and neither auto-submits — speech recognition misfires, and a scanned
/// code is untrusted input that should not navigate on its own.
class _EmptyAppBarAddressField extends StatelessWidget {
  const _EmptyAppBarAddressField({
    required this.tabType,
    this.showSearchTools = false,
  });

  final TabType tabType;
  final bool showSearchTools;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    void openSearch([String? initialText]) {
      unawaited(
        SearchRoute(
          tabType: tabType,
          // The route encodes this into a path segment, so an empty string
          // would leave a trailing slash that no longer matches the pattern.
          searchText: (initialText == null || initialText.isEmpty)
              ? SearchRoute.emptySearchText
              : initialText,
        ).push(context),
      );
    }

    final label = Text(
      'Search or enter URL',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: showSearchTools
            ? Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: openSearch,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: label),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // The bar row is [kToolbarHeight] tall and this field only
                  // part of it, so the buttons have to give up their default
                  // 48px tap target or they force the pill taller than the row.
                  IconButtonTheme(
                    data: IconButtonThemeData(
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.square(32),
                        iconSize: 18,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrScannerButton(
                          onScanResult: (scanResult) {
                            final code = scanResult?.code;
                            if (code == null || !context.mounted) return;

                            openSearch(code);
                          },
                        ),
                        const SizedBox(width: 4),
                        SpeechToTextButton(
                          onTextReceived: (text) {
                            if (!context.mounted) return;

                            openSearch(text);
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: openSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  alignment: Alignment.center,
                  child: label,
                ),
              ),
      ),
    );
  }
}
