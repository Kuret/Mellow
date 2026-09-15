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
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/domain/entities/states/tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/features/browser/domain/entities/tab_presence.dart';
import 'package:mellow/features/geckoview/features/browser/domain/providers.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/cold_tab_badge.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/tab_icon.dart';
import 'package:mellow/features/geckoview/features/browser/presentation/widgets/tab_view/split_badge.dart';

/// A pinned-shelf row (PLAN §6.4): favicon and a single-line title, no URL
/// and no thumbnail. Pinned tabs are the ones the user returns to, so the
/// list spends one line on each rather than a preview card.
class CompactTabRow extends ConsumerWidget {
  final String tabId;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final double height;

  /// Set when the tab is a split member; drives the badge and accent bar.
  final SplitMembership? split;

  const CompactTabRow({
    super.key,
    required this.tabId,
    required this.isActive,
    this.onTap,
    this.onClose,
    this.height = defaultHeight,
    this.split,
  });

  static const defaultHeight = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tabState =
        ref.watch(
          tabStateWithFallbackProvider(tabId).select((value) => value.value),
        ) ??
        TabState.$default(tabId);
    final isCold = ref.watch(tabPresenceProvider(tabId)) == TabPresence.cold;

    const iconSize = 20.0;
    final icon = TabIcon(tabState: tabState, iconSize: iconSize);
    final leading = isCold ? ColdTabBadge(size: iconSize, child: icon) : icon;

    const radius = BorderRadius.all(Radius.circular(10));
    Widget row = Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? scheme.primary.withAlpha(20) : Colors.transparent,
        borderRadius: radius,
        border: isActive
            ? Border(left: BorderSide(color: scheme.primary, width: 4))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                SplitBadgeOverlay(split: split, size: iconSize, child: leading),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tabState.titleOrAuthority,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(MdiIcons.pin, size: 14, color: scheme.primary),
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );

    if (isCold) {
      row = Opacity(opacity: ColdTabBadge.opacity, child: row);
    }

    return SplitAccentBar(split: split, child: row);
  }
}
