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
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/tab_summary.dart';

/// A tab's place in its split (PLAN §6.5): [index] of [count] members, in
/// `splitIndex` order. Members render adjacent; this tells a row whether it
/// opens, continues or closes the shared accent bar.
class SplitMembership with FastEquatable {
  final String splitId;
  final int index;
  final int count;

  SplitMembership({
    required this.splitId,
    required this.index,
    required this.count,
  });

  bool get isFirst => index == 0;
  bool get isLast => index == count - 1;

  /// Membership of [tabId] within [summaries], or `null` when the tab is not
  /// a split member (or its split has a single visible member).
  static SplitMembership? of(String tabId, Iterable<TabSummary> summaries) {
    TabSummary? tab;
    for (final summary in summaries) {
      if (summary.id == tabId) {
        tab = summary;
        break;
      }
    }
    final splitId = tab?.splitId;
    if (splitId == null) {
      return null;
    }
    final members =
        summaries.where((summary) => summary.splitId == splitId).toList()
          ..sort((a, b) => (a.splitIndex ?? 0).compareTo(b.splitIndex ?? 0));
    if (members.length < 2) {
      return null;
    }
    return SplitMembership(
      splitId: splitId,
      index: members.indexWhere((member) => member.id == tabId),
      count: members.length,
    );
  }

  @override
  List<Object?> get hashParameters => [splitId, index, count];
}

/// The split glyph in a small disc, in the bottom-left corner of a favicon —
/// the mirror image of [ColdTabBadge]'s corner, so both can show at once.
class SplitBadgeOverlay extends StatelessWidget {
  final SplitMembership? split;
  final double size;
  final Widget child;

  const SplitBadgeOverlay({
    super.key,
    required this.split,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (split == null) {
      return child;
    }
    final scheme = Theme.of(context).colorScheme;
    final badgeSize = (size * 0.55).clamp(12.0, 18.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: -badgeSize / 4,
            bottom: -badgeSize / 4,
            child: Tooltip(
              message: 'Split view (${split!.count} tabs)',
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.surfaceContainer,
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  MdiIcons.viewSplitVertical,
                  size: badgeSize * 0.7,
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The accent bar split members share on their left edge: one continuous
/// tertiary stripe spanning the adjacent rows, rounded at the first and last.
class SplitAccentBar extends StatelessWidget {
  final SplitMembership? split;
  final Widget child;

  const SplitAccentBar({super.key, required this.split, required this.child});

  static const width = 4.0;

  @override
  Widget build(BuildContext context) {
    final split = this.split;
    if (split == null) {
      return child;
    }
    final scheme = Theme.of(context).colorScheme;
    const radius = Radius.circular(width);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 2,
            top: split.isFirst ? 4 : 0,
            bottom: split.isLast ? 4 : 0,
          ),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: scheme.tertiary,
              borderRadius: BorderRadius.vertical(
                top: split.isFirst ? radius : Radius.zero,
                bottom: split.isLast ? radius : Radius.zero,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
