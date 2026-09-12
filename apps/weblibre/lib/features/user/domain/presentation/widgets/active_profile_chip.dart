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
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/domain/entities/profile.dart';
import 'package:weblibre/features/user/domain/providers.dart';

/// A colour that is stable for one profile and (very likely) different from
/// the next: the hue comes from the profile id, the tone from the theme.
Color profileAccentColor(String profileId, Brightness brightness) {
  var hash = 0;
  for (final unit in profileId.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(
    1.0,
    hue,
    0.6,
    brightness == Brightness.dark ? 0.65 : 0.38,
  ).toColor();
}

/// The active profile, always on screen where tabs are (PLAN §7.5): a chip
/// with the profile's name on its own colour, so sensitive browsing in a
/// separate profile is unmistakable. Tapping opens the profile switcher.
///
/// Shown even with a single profile — the point is that the answer to "which
/// profile is this?" never depends on remembering how many exist.
class ActiveProfileChip extends ConsumerWidget {
  /// Smaller chip for dense headers (the tab tray).
  final bool compact;

  const ActiveProfileChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(selectedProfileProvider).value;
    if (profile == null) {
      return const SizedBox.shrink();
    }
    return ActiveProfileChipView(
      profile: profile,
      compact: compact,
      onTap: () => const SelectProfileRoute().push(context),
    );
  }
}

/// The stateless body of [ActiveProfileChip], for previews and tests.
class ActiveProfileChipView extends StatelessWidget {
  final Profile profile;
  final bool compact;
  final VoidCallback? onTap;

  const ActiveProfileChipView({
    super.key,
    required this.profile,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = profileAccentColor(profile.id, theme.brightness);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final name = profile.name.isEmpty ? 'Profile' : profile.name;

    return Tooltip(
      message: 'Active profile: $name',
      child: Material(
        color: accent,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        child: InkWell(
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 4 : 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle,
                  size: compact ? 16 : 20,
                  color: onAccent,
                ),
                SizedBox(width: compact ? 4 : 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 96 : 160),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? theme.textTheme.labelSmall
                                : theme.textTheme.labelLarge)
                            ?.copyWith(
                              color: onAccent,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
