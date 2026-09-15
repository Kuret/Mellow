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
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/browser_quick_menu.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/space_icon.dart';

/// The space switcher at the foot of the wide vertical rail (PLAN §9 W1):
/// one flat glyph per space, the selected one in the accent color, and a
/// trailing "+" that opens a new tab in the current space (matching Zen).
/// Tap a space to select it, long-press a space to edit it. Long-pressing
/// "+" opens a menu with the rest of the toolbar's actions (see
/// [showBrowserQuickMenu]). Scrolls horizontally when the spaces outgrow the
/// rail.
class SpaceIconRail extends ConsumerWidget {
  const SpaceIconRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces =
        ref.watch(watchSpacesProvider.select((value) => value.value)) ??
        const <SpaceData>[];
    final selectedSpaceUuid = ref.watch(selectedSpaceProvider);

    return SpaceIconRailView(
      entries: [
        for (final space in spaces)
          SpaceIconRailEntry(
            id: space.uuid,
            icon: space.icon,
            name: space.name,
            selected: space.uuid == selectedSpaceUuid,
          ),
      ],
      onSelected: (id) {
        ref.read(selectedSpaceProvider.notifier).space = id;
      },
      onEdit: (id) => SpaceEditRoute(uuid: id).push(context),
      onNewTab: () => openNewTabFromQuickMenu(context, ref),
      onAddLongPress: (buttonContext) =>
          showBrowserQuickMenu(buttonContext, ref),
    );
  }
}

/// One space in the [SpaceIconRailView].
class SpaceIconRailEntry {
  final String id;
  final String? icon;
  final String name;
  final bool selected;

  const SpaceIconRailEntry({
    required this.id,
    required this.icon,
    required this.name,
    required this.selected,
  });
}

/// Provider-free rendering of [SpaceIconRail], shared with the settings
/// preview.
class SpaceIconRailView extends StatelessWidget {
  final List<SpaceIconRailEntry> entries;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onEdit;

  /// Fired on a plain tap of the trailing "+": opens a new tab.
  final VoidCallback? onNewTab;

  /// Fired on a long-press of the trailing "+", with the "+" button's own
  /// [BuildContext] (to anchor a popup menu near it). The rail (a
  /// [ConsumerWidget]) owns building and acting on that menu, so this view
  /// stays provider-free.
  final void Function(BuildContext buttonContext)? onAddLongPress;

  const SpaceIconRailView({
    super.key,
    required this.entries,
    this.onSelected,
    this.onEdit,
    this.onNewTab,
    this.onAddLongPress,
  });

  /// Side of one space glyph's square tap target.
  static const targetSize = 40.0;

  /// Size the glyph itself is drawn at, with no chip behind it (PLAN §9 W1
  /// change 3: Zen's sidebar icons are bare, only the active one colored).
  static const glyphSize = 20.0;

  /// Height of the whole row: the tap target plus its vertical padding.
  static const height = 44.0;

  /// Horizontal gap between tap targets.
  static const spacing = 4.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(right: spacing),
              child: _SpaceGlyphButton(
                entry: entry,
                onTap: onSelected == null ? null : () => onSelected!(entry.id),
                onLongPress: onEdit == null ? null : () => onEdit!(entry.id),
              ),
            ),
          Tooltip(
            message: 'New tab',
            // Manual, or the tooltip's own long-press recognizer joins the
            // gesture arena beside the one that opens the menu and sometimes
            // wins it — which is how a long-press on "+" occasionally put a
            // "New tab" bubble on screen instead of the menu. Hover and
            // semantics still get the label.
            triggerMode: TooltipTriggerMode.manual,
            child: Builder(
              builder: (context) => GestureDetector(
                onLongPress: onAddLongPress == null
                    ? null
                    : () => onAddLongPress!(context),
                child: InkResponse(
                  onTap: onNewTab,
                  radius: targetSize / 2,
                  child: SizedBox(
                    width: targetSize,
                    height: targetSize,
                    child: Icon(
                      Icons.add,
                      size: glyphSize,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One space's flat glyph in the [SpaceIconRailView]: no circular chip, no
/// selected border — only the active space's glyph is colored (PLAN §9 W1
/// change 3, matching Zen's sidebar). The permanent chip is gone; the
/// [InkResponse] still gives a circular ripple on tap.
/// How far back an unselected space's glyph is pushed. Enough to read as
/// "not this one" beside a full-strength glyph, not so far that a rail of
/// four spaces looks disabled.
const double _inactiveGlyphOpacity = 0.45;

class _SpaceGlyphButton extends StatelessWidget {
  final SpaceIconRailEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _SpaceGlyphButton({
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = entry.selected
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final displayName = entry.name.isEmpty ? 'Space' : entry.name;
    final icon = entry.icon?.trim();

    // Zen's icon is a free string (usually an emoji). Fall back to the first
    // letter of the space's name so unlabelled spaces still tell apart.
    final Widget glyph = icon != null && icon.isNotEmpty
        ? SpaceIcon(
            icon: icon,
            size: SpaceIconRailView.glyphSize,
            color: foreground,
          )
        : Text(
            entry.name.isEmpty
                ? '?'
                : entry.name.characters.first.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          );

    return Tooltip(
      message: displayName,
      // Manual for the same reason as the "+" above: this glyph's long-press
      // opens the space editor, and the tooltip must not race it.
      triggerMode: TooltipTriggerMode.manual,
      child: InkResponse(
        onTap: onTap,
        onLongPress: onLongPress,
        radius: SpaceIconRailView.targetSize / 2,
        child: SizedBox(
          width: SpaceIconRailView.targetSize,
          height: SpaceIconRailView.targetSize,
          // Dimmed rather than only recoloured: a space's icon is usually a
          // colour emoji, and a colour font ignores the foreground colour
          // entirely — so on an emoji rail the accent alone marks nothing as
          // active. Opacity is the one affordance that works for both an
          // emoji and a tinted vector glyph.
          child: Center(
            child: entry.selected
                ? glyph
                : Opacity(opacity: _inactiveGlyphOpacity, child: glyph),
          ),
        ),
      ),
    );
  }
}
