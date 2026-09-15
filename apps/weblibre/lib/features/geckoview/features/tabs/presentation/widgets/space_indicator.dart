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
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers.dart';
import 'package:weblibre/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/browser_quick_menu.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_icon.dart';
import 'package:weblibre/features/geckoview/features/tabs/presentation/widgets/space_swipe.dart';

/// The compact bar's fixed leading control: the selected space's icon (or the
/// first letter of its name) with a strip of dots underneath marking where it
/// sits among the spaces. A horizontal swipe steps to the neighbouring
/// space; both a tap and a long-press open the shared quick menu (see
/// [showBrowserQuickMenu]) with its spaces section included — the tap
/// silently, the long-press with the acknowledging haptic tick, matching the
/// wide rail's "+" long-press, since the compact bar's toolbar row can be
/// switched off the same way the rail's can.
class SpaceIndicator extends ConsumerWidget {
  const SpaceIndicator({super.key});

  /// Width of the whole control; matches the bar's row height so it is a
  /// square touch target.
  static const width = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces =
        ref.watch(watchSpacesProvider.select((value) => value.value)) ??
        const <SpaceData>[];
    final selectedUuid = ref.watch(selectedSpaceProvider);
    final index = spaces.indexWhere((space) => space.uuid == selectedUuid);
    final selected = index >= 0 ? spaces[index] : null;

    return SpaceSwipeDetector(
      behavior: HitTestBehavior.opaque,
      child: SpaceIndicatorView(
        icon: selected?.icon,
        name: selected?.name ?? '',
        index: index,
        count: spaces.length,
        onTap: (buttonContext) => showBrowserQuickMenu(
          buttonContext,
          ref,
          includeSpaces: true,
          haptic: false,
        ),
        onLongPress: (buttonContext) =>
            showBrowserQuickMenu(buttonContext, ref, includeSpaces: true),
      ),
    );
  }
}

/// Provider-free rendering of [SpaceIndicator], shared with the settings
/// preview.
class SpaceIndicatorView extends StatelessWidget {
  final String? icon;
  final String name;

  /// Position of the selected space among [count]; negative while unknown.
  final int index;
  final int count;

  /// Fired on a tap, with the indicator's own [BuildContext] (to anchor a
  /// popup menu near it) — the same shape as [onLongPress], since both open
  /// the same menu.
  final void Function(BuildContext buttonContext)? onTap;

  /// Fired on a long-press, with the indicator's own [BuildContext] (to
  /// anchor a popup menu near it) — the same pattern as
  /// `SpaceIconRailView.onAddLongPress`. The owner (a [ConsumerWidget])
  /// builds and acts on the menu, so this view stays provider-free.
  final void Function(BuildContext buttonContext)? onLongPress;

  const SpaceIndicatorView({
    super.key,
    required this.icon,
    required this.name,
    required this.index,
    required this.count,
    this.onTap,
    this.onLongPress,
  });

  /// Above this many spaces the dot strip would not fit the width; the
  /// position is written out instead.
  static const maxDots = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayName = name.isEmpty ? 'Space' : name;
    final glyphText = icon?.trim();
    final Widget glyph = glyphText != null && glyphText.isNotEmpty
        ? SpaceIcon(icon: glyphText, size: 20, color: scheme.onSurface)
        : Text(
            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          );

    final Widget position;
    if (count <= 1) {
      position = const SizedBox(height: 4);
    } else if (count <= maxDots) {
      position = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: i == index ? 8 : 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: i == index ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      );
    } else {
      position = Text(
        '${index + 1}/$count',
        style: textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1,
          fontSize: 9,
        ),
      );
    }

    return Tooltip(
      message: displayName,
      // Manual, or the tooltip's own long-press recognizer joins the gesture
      // arena beside the one that opens the quick menu and sometimes wins it
      // (see the same fix on the rail's "+" in space_icon_rail.dart).
      triggerMode: TooltipTriggerMode.manual,
      child: Semantics(
        button: true,
        label: 'Space: $displayName',
        child: Builder(
          builder: (context) => InkWell(
            onTap: onTap == null ? null : () => onTap!(context),
            onLongPress: onLongPress == null
                ? null
                : () => onLongPress!(context),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 22, child: Center(child: glyph)),
                  const SizedBox(height: 3),
                  SizedBox(height: 9, child: Center(child: position)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const width = SpaceIndicator.width;
}
