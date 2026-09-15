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
import 'package:mellow/core/design/app_colors.dart';

/// Curated accent choices offered by the "Accent Color" setting. Each reads
/// as a legible highlight (selection, switches, focus rings) against both the
/// light and the dark neutral schemes built by [buildAppColorScheme].
///
/// A `null` accent setting means "follow the system" (the platform's dynamic
/// wallpaper color, or [AppColors.light]'s brand teal where dynamic color is
/// unavailable) — this palette is only the *explicit* choices.
const kAccentChoices = <Color>[
  Color(0xFF3F80EA), // blue
  Color(0xFF167C80), // teal (the app's own fallback seed)
  Color(0xFF2E9E5B), // green
  Color(0xFFC98A00), // amber
  Color(0xFFE0692A), // orange
  Color(0xFFD5473F), // red
  Color(0xFFD84E82), // pink
  AppColors.brandPurple, // purple (#9C83F8)
  Color(0xFF5B5FE0), // indigo
];

/// Picks whichever of black or white has the higher contrast ratio against
/// [background], per the WCAG contrast formula.
///
/// Duplicated in spirit from `ContainerColors._contrastingForeground`
/// (`features/geckoview/features/tabs/utils/container_colors.dart`) rather
/// than shared: that helper is private to a file this task must not touch,
/// and the computation is a few lines.
Color contrastingOnColor(Color background) {
  double contrastRatio(Color a, Color b) {
    final aLuminance = a.computeLuminance();
    final bLuminance = b.computeLuminance();
    final lighter = aLuminance > bLuminance ? aLuminance : bLuminance;
    final darker = aLuminance > bLuminance ? bLuminance : aLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  final blackContrast = contrastRatio(background, Colors.black);
  final whiteContrast = contrastRatio(background, Colors.white);
  return blackContrast >= whiteContrast ? Colors.black : Colors.white;
}

/// Blends [accent] toward [surface] into a soft selection wash — the fill a
/// selected row or the active segment of a [SegmentedButton] gets — rather
/// than a saturated slab of the accent itself.
Color _accentWash(Color accent, Color surface, double amount) {
  return Color.lerp(surface, accent, amount)!;
}

/// Builds an explicit, neutral-grey [ColorScheme] with [accent] as its single
/// chromatic color.
///
/// Unlike `ColorScheme.fromSeed`, no surface role is tinted toward the
/// accent's hue: every surface, container and outline stays a true grey (or
/// black/white), so pages read as Windows-Phone-style "black on white" /
/// "white on black" blocks instead of the muddy blue-grey a Material 3 seed
/// scheme produces. The accent shows up only on `primary`/`secondary`/
/// `tertiary` and the containers derived from them, which is what drives
/// switches, selection, and highlighted controls.
///
/// [pureBlack] only affects [brightness] == [Brightness.dark]: it collapses
/// `surface` and the lower containers to true black for OLED power saving,
/// matching the meaning `GeneralSettings.pureBlack` already has.
ColorScheme buildAppColorScheme({
  required Brightness brightness,
  required Color accent,
  bool pureBlack = false,
}) {
  final onAccent = contrastingOnColor(accent);

  if (brightness == Brightness.light) {
    const surface = Color(0xFFFFFFFF);
    const onSurface = Color(0xFF000000);
    const surfaceContainerHigh = Color(0xFFF6F6F8);
    const surfaceContainerHighest = Color(0xFFEFEFF2);
    const onSurfaceVariant = Color(0xFF5A5A60);
    const outlineVariant = Color(0xFFD9D9DE);
    const outline = Color(0xFFB5B5BC);

    final accentContainer = _accentWash(accent, surface, 0.18);
    const defaultScheme = ColorScheme.light();

    return ColorScheme(
      brightness: Brightness.light,
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: accentContainer,
      onPrimaryContainer: onSurface,
      secondary: accent,
      onSecondary: onAccent,
      secondaryContainer: accentContainer,
      onSecondaryContainer: onSurface,
      tertiary: accent,
      onTertiary: onAccent,
      tertiaryContainer: accentContainer,
      onTertiaryContainer: onSurface,
      error: defaultScheme.error,
      onError: defaultScheme.onError,
      errorContainer: defaultScheme.errorContainer,
      onErrorContainer: defaultScheme.onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      surfaceDim: outlineVariant,
      surfaceBright: surface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFF1A1A1D),
      onInverseSurface: const Color(0xFFFFFFFF),
      inversePrimary: accent,
      surfaceTint: Colors.transparent,
    );
  }

  // Dark.
  final surface = pureBlack ? const Color(0xFF000000) : const Color(0xFF0A0A0B);
  const onSurface = Color(0xFFFFFFFF);
  final surfaceContainerLow = pureBlack
      ? const Color(0xFF000000)
      : const Color(0xFF121214);
  final surfaceContainer = pureBlack
      ? const Color(0xFF000000)
      : const Color(0xFF16161A);
  final surfaceContainerHigh = pureBlack
      ? const Color(0xFF0F0F10)
      : const Color(0xFF1A1A1D);
  final surfaceContainerHighest = pureBlack
      ? const Color(0xFF0F0F10)
      : const Color(0xFF1A1A1D);
  final outlineVariant = pureBlack
      ? const Color(0xFF232326)
      : const Color(0xFF2C2C30);
  const onSurfaceVariant = Color(0xFFA8A8AE);
  const outline = Color(0xFF77777E);

  final accentContainer = _accentWash(accent, surface, 0.32);
  const defaultScheme = ColorScheme.dark();

  return ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: accentContainer,
    onPrimaryContainer: onSurface,
    secondary: accent,
    onSecondary: onAccent,
    secondaryContainer: accentContainer,
    onSecondaryContainer: onSurface,
    tertiary: accent,
    onTertiary: onAccent,
    tertiaryContainer: accentContainer,
    onTertiaryContainer: onSurface,
    error: defaultScheme.error,
    onError: defaultScheme.onError,
    errorContainer: defaultScheme.errorContainer,
    onErrorContainer: defaultScheme.onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerLowest: surface,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    surfaceDim: surface,
    surfaceBright: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: const Color(0xFFFFFFFF),
    onInverseSurface: const Color(0xFF000000),
    inversePrimary: accent,
    surfaceTint: Colors.transparent,
  );
}

/// Builds the app's [ThemeData] around [buildAppColorScheme], with component
/// themes that stop Material 3 from re-introducing the tinted-surface look
/// through elevation: `surfaceTintColor` is neutralized everywhere and
/// elevation drops to zero on the widgets ([AppBar], [Card], sheets, dialogs,
/// menus) that would otherwise paint a tint wash as they "rise". Separation
/// between adjacent surfaces comes from hairline [ColorScheme.outlineVariant]
/// borders/dividers instead.
ThemeData buildAppTheme({
  required Brightness brightness,
  required Color accent,
  bool pureBlack = false,
}) {
  final colorScheme = buildAppColorScheme(
    brightness: brightness,
    accent: accent,
    pureBlack: pureBlack,
  );

  final selectedFillColor = WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.disabled)) return null;
    if (states.contains(WidgetState.selected)) return colorScheme.primary;
    return null;
  });

  final accentWash = _accentWash(
    colorScheme.primary,
    colorScheme.surface,
    0.16,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: <ThemeExtension<dynamic>>[
      switch (brightness) {
        Brightness.light => AppColors.light,
        Brightness.dark => pureBlack ? AppColors.darkOled : AppColors.dark,
      },
    ],
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarThemeData(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      modalBackgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: accentWash,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withValues(alpha: 0.5);
        }
        return null;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: selectedFillColor,
      checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
    ),
    radioTheme: RadioThemeData(fillColor: selectedFillColor),
    sliderTheme: SliderThemeData(
      activeTrackColor: colorScheme.primary,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      inactiveTrackColor: colorScheme.outlineVariant,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.outlineVariant,
      circularTrackColor: colorScheme.outlineVariant,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return accentWash;
          return colorScheme.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.onSurface;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 2,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primary.withValues(alpha: 0.3),
      selectionHandleColor: colorScheme.primary,
    ),
    listTileTheme: ListTileThemeData(
      selectedColor: colorScheme.primary,
      selectedTileColor: accentWash,
    ),
  );
}
