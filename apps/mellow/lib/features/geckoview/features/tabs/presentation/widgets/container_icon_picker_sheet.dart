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
import 'package:mellow/features/geckoview/features/tabs/utils/container_colors.dart';
import 'package:mellow/features/geckoview/features/tabs/utils/firefox_container_vocab.dart';
import 'package:mellow/presentation/widgets/sheet_drag_handle.dart';

/// Picks one of Firefox's thirteen contextual-identity icon keywords.
///
/// Calls [onSelected] with the chosen keyword (`FirefoxContainerIcon.keyword`).
class FirefoxContainerIconPicker extends StatelessWidget {
  const FirefoxContainerIconPicker({
    required this.accentColor,
    required this.selectedIconKey,
    required this.onSelected,
    super.key,
  });

  /// Seed for the preview and selection highlight; the container's colour, or
  /// the theme primary when it follows the toolbar.
  final Color accentColor;
  final String selectedIconKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ContainerColors.palette(context, accentColor);
    final selectedIcon = FirefoxContainerIcon.fromKeyword(selectedIconKey);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetDragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Choose Icon', style: theme.textTheme.titleMedium),
                        Text(
                          'Shared with Firefox containers',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.avatarBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.outlineColor, width: 2),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      selectedIcon.icon,
                      color: palette.avatarForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columnCount = (constraints.maxWidth / 76).floor().clamp(
                    4,
                    7,
                  );

                  return GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: FirefoxContainerIcon.values.length,
                    itemBuilder: (context, index) {
                      final option = FirefoxContainerIcon.values[index];
                      final isSelected = option == selectedIcon;

                      return Tooltip(
                        message: option.keyword,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onSelected(option.keyword),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? palette.surfaceHighColor
                                    : theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(18),
                                border: isSelected
                                    ? Border.all(
                                        color: palette.outlineColor,
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.35),
                                      ),
                              ),
                              child: Icon(
                                option.icon,
                                color: isSelected
                                    ? palette.avatarForegroundColor
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
