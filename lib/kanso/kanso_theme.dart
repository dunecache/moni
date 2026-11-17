import 'package:flutter/material.dart';

import 'kanso_tokens.dart';

const String _displayFont = 'Google Sans Flex';
const String _textFont = 'Inter';

/// Typographic hierarchy: distinctive headlines, quiet metadata.
TextTheme buildKansoTextTheme({required bool useBundledFonts}) {
  final display = useBundledFonts ? _displayFont : null;
  final text = useBundledFonts ? _textFont : null;
  return TextTheme(
    displayLarge:
        TextStyle(fontFamily: display, fontSize: 40, height: 1.08, fontWeight: FontWeight.w600, letterSpacing: -0.02),
    headlineLarge:
        TextStyle(fontFamily: display, fontSize: 28, height: 1.15, fontWeight: FontWeight.w600, letterSpacing: -0.015),
    headlineMedium:
        TextStyle(fontFamily: display, fontSize: 22, height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.01),
    titleLarge:
        TextStyle(fontFamily: display, fontSize: 18, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: -0.005),
    titleMedium:
        TextStyle(fontFamily: text, fontSize: 15, height: 1.35, fontWeight: FontWeight.w600),
    titleSmall:
        TextStyle(fontFamily: text, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontFamily: text, fontSize: 16, height: 1.5, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: text, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontFamily: text, fontSize: 12, height: 1.45, fontWeight: FontWeight.w400),
    labelLarge:
        TextStyle(fontFamily: text, fontSize: 14, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: 0.01),
    labelMedium:
        TextStyle(fontFamily: text, fontSize: 12, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: 0.015),
    labelSmall:
        TextStyle(fontFamily: text, fontSize: 11, height: 1.3, fontWeight: FontWeight.w500, letterSpacing: 0.02),
  );
}

/// Builds a complete [ThemeData] from one Kanso mode.
///
/// No widget should set an arbitrary color; every role reaches a widget via
/// `context.kanso` or the generated [ColorScheme].
ThemeData buildKansoTheme(KansoMode mode) {
  final c = KansoColors.of(mode);
  final dark = mode == KansoMode.eveningZen;
  final brightness = dark ? Brightness.dark : Brightness.light;
  final textTheme = buildKansoTextTheme(useBundledFonts: true);

  final scheme = ColorScheme.fromSeed(
    seedColor: c.accentStrong,
    brightness: brightness,
  ).copyWith(
    primary: c.accentPrimary,
    onPrimary: c.background,
    primaryContainer: c.selection,
    onPrimaryContainer: c.accentStrong,
    secondary: c.accentSecondary,
    onSecondary: c.background,
    surface: c.surface,
    onSurface: c.textPrimary,
    error: c.danger,
    onError: c.background,
    outline: c.borderStrong,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    visualDensity: VisualDensity.standard,
    fontFamily: _textFont,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: c.textPrimary),
      iconTheme: IconThemeData(color: c.textSecondary, size: 22),
    ),
    iconTheme: IconThemeData(color: c.textPrimary, size: 22),
    dividerTheme: DividerThemeData(color: c.borderSubtle, space: 1, thickness: 1),
    listTileTheme: ListTileThemeData(
      iconColor: c.textSecondary,
      textColor: c.textPrimary,
      titleTextStyle: textTheme.titleMedium?.copyWith(color: c.textPrimary),
      subtitleTextStyle: textTheme.bodySmall?.copyWith(color: c.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.selection,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall!.copyWith(
          color: selected ? c.accentStrong : c.textMuted,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? c.accentStrong : c.textMuted, size: 22);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceSunken,
      hintStyle: textTheme.bodyMedium?.copyWith(color: c.textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.focus, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.accentPrimary,
      inactiveTrackColor: c.borderSubtle,
      thumbColor: c.accentPrimary,
      overlayColor: c.accentPrimary.withOpacity(0.12),
      trackHeight: 4,
      showValueIndicator: ShowValueIndicator.never,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.floating,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: c.textPrimary),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.floating,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceSunken,
      selectedColor: c.selection,
      checkmarkColor: c.accentStrong,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: textTheme.labelMedium?.copyWith(color: c.textSecondary),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: c.accentStrong),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accentPrimary,
      linearTrackColor: c.borderSubtle,
      circularTrackColor: c.borderSubtle,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return c.borderStrong;
        return states.contains(WidgetState.selected) ? c.background : c.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) return c.accentPrimary;
        return c.borderSubtle;
      }),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
