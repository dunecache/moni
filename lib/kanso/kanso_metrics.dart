import 'package:flutter/material.dart';

/// Kanso spatial and temporal metrics.
///
/// These complement the color tokens with a restrained, consistent rhythm.
/// Values are deliberately few: fewer choices produce a calmer interface.
abstract final class KansoSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal inset used by every scrollable screen.
  static const double page = lg;

  /// Minimum accessible touch target.
  static const double touch = 48;
}

abstract final class KansoRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
}

abstract final class KansoMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve gentle = Curves.easeInOutCubic;

  /// Motion is deliberately quiet: no bounce, no overshoot, no loops.
  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
