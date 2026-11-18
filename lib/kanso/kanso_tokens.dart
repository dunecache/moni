import 'package:flutter/material.dart';

/// The Kanso Matcha color system.
///
/// Source of truth: `~/kanso/kanso_design_system` v1.3.0 —
/// `tokens/semantic/morning-matcha.json` and `tokens/semantic/evening-zen.json`.
///
/// This is the ONLY file in the app allowed to contain raw color values.
/// Every other component consumes the semantic roles below. The values are
/// frozen: do not edit them to make a screen "work". If a pairing fails
/// contrast, change the role assignment in the Kanso system first.
enum KansoMode { morningMatcha, eveningZen }

/// Semantic color roles for one Kanso mode.
///
/// Role names map 1:1 to the design system's semantic token names.
@immutable
class KansoColors {
  const KansoColors._({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.surfaceAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderSubtle,
    required this.borderStrong,
    required this.accentPrimary,
    required this.accentStrong,
    required this.accentSecondary,
    required this.onAccent,
    required this.selection,
    required this.selectedInk,
    required this.focus,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.floating,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSunken;
  final Color surfaceAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderSubtle;
  final Color borderStrong;
  final Color accentPrimary;
  final Color accentStrong;
  final Color accentSecondary;

  /// Ink for labels drawn on an [accentPrimary] fill. Dark in both modes so
  /// filled actions keep AA contrast and do not change color on theme switch.
  final Color onAccent;
  final Color selection;

  /// Ink for the label/icon of a selected nav item or tab. In the light theme
  /// this must be darker than [textSecondary]: the pill alone is too subtle.
  final Color selectedInk;
  final Color focus;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Dialogs and popovers. Evening Zen uses the reserved `ink-3` primitive
  /// (`#4A5B45`); Morning Matcha uses the most elevated paper surface.
  final Color floating;

  static const KansoColors morningMatcha = KansoColors._(
    background: Color(0xFFF3F1E9),
    surface: Color(0xFFE8E5DA),
    surfaceElevated: Color(0xFFFAF9F4),
    surfaceSunken: Color(0xFFE2DED2),
    surfaceAccent: Color(0xFFDCE2D1),
    textPrimary: Color(0xFF34382F),
    textSecondary: Color(0xFF616359),
    textMuted: Color(0xFF616359),
    borderSubtle: Color(0xFFD5D0C2),
    borderStrong: Color(0xFF827E74),
    accentPrimary: Color(0xFF89977A),
    accentStrong: Color(0xFF5C664A),
    accentSecondary: Color(0xFFAAB49A),
    onAccent: Color(0xFF171E16),
    selection: Color(0xFFDCE2D1),
    selectedInk: Color(0xFF3D4A33),
    focus: Color(0xFF626D4F),
    success: Color(0xFF5C664A),
    warning: Color(0xFF795E2C),
    danger: Color(0xFF944E47),
    info: Color(0xFF48676B),
    floating: Color(0xFFFAF9F4),
  );

  static const KansoColors eveningZen = KansoColors._(
    background: Color(0xFF171F18),
    surface: Color(0xFF263326),
    surfaceElevated: Color(0xFF364735),
    surfaceSunken: Color(0xFF10160F),
    surfaceAccent: Color(0xFF3B4C35),
    textPrimary: Color(0xFFE9EEE2),
    textSecondary: Color(0xFFCBD3C2),
    textMuted: Color(0xFFB2BBAB),
    borderSubtle: Color(0xFF3D4A3B),
    borderStrong: Color(0xFF829875),
    accentPrimary: Color(0xFFB0C39C),
    accentStrong: Color(0xFFD2E4BB),
    accentSecondary: Color(0xFF829875),
    onAccent: Color(0xFF171E16),
    selection: Color(0xFF3B4C35),
    selectedInk: Color(0xFFD2E4BB),
    focus: Color(0xFFB0C39C),
    success: Color(0xFFD2E4BB),
    warning: Color(0xFFD9BD7E),
    danger: Color(0xFFE1ACA4),
    info: Color(0xFFA5C5C3),
    floating: Color(0xFF4A5B45),
  );

  factory KansoColors.of(KansoMode mode) =>
      mode == KansoMode.morningMatcha ? morningMatcha : eveningZen;

  /// Categorical series for charts, in the Kanso-mandated order.
  static const List<Color> chartSeriesMorning = <Color>[
    Color(0xFF89977A),
    Color(0xFF4F7075),
    Color(0xFF8A6654),
    Color(0xFF79658B),
    Color(0xFF80642F),
    Color(0xFFAAB49A),
    Color(0xFF9A514A),
  ];

  static const List<Color> chartSeriesEvening = <Color>[
    Color(0xFFB0C39C),
    Color(0xFFA5C5C3),
    Color(0xFFD8B49B),
    Color(0xFFC1B1D2),
    Color(0xFFD9BD7E),
    Color(0xFF829875),
    Color(0xFFD68D82),
  ];

  List<Color> chartSeries(KansoMode mode) =>
      mode == KansoMode.morningMatcha ? chartSeriesMorning : chartSeriesEvening;
}

/// Resolves the active Kanso mode from the ambient [ThemeData] brightness.
///
/// Keeping this derived from [ThemeData] means a single source of truth: the
/// app never has to synchronize a separate "current palette" variable.
KansoMode kansoModeOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? KansoMode.eveningZen
        : KansoMode.morningMatcha;

extension KansoBuildContext on BuildContext {
  KansoColors get kanso => KansoColors.of(kansoModeOf(this));

  KansoMode get kansoMode => kansoModeOf(this);
}
