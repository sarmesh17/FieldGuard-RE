import 'package:flutter/material.dart';

/// Lightweight responsive utilities. No external packages required.
///
/// Base design width: 390 px (iPhone 14 / mid-range Android).
/// Tablet threshold: 600 px logical width.
class AppResponsive {
  AppResponsive._();

  static const double _baseWidth = 390.0;
  static const double _tabletBreakpoint = 600.0;

  static double _width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double _height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Returns true when the logical screen width is ≥ 600 px (tablet/iPad).
  static bool isTablet(BuildContext context) =>
      _width(context) >= _tabletBreakpoint;

  /// Responsive font / icon / spacing scalar.
  ///
  /// Clamps scale to [0.85 … 1.3] so the UI never becomes unreadably tiny
  /// on a watch-sized surface or absurdly huge on a large tablet.
  static double _scale(BuildContext context) =>
      (_width(context) / _baseWidth).clamp(0.85, 1.3);

  /// Scale a font size to the current screen width.
  static double sp(BuildContext context, double size) =>
      size * _scale(context);

  /// Scale a dimension (icon size, container size, etc.) to screen width.
  static double r(BuildContext context, double size) =>
      size * _scale(context);

  /// Width as a percentage of screen width (0–100).
  static double wp(BuildContext context, double percent) =>
      _width(context) * percent / 100;

  /// Height as a percentage of screen height (0–100).
  static double hp(BuildContext context, double percent) =>
      _height(context) * percent / 100;

  /// Adaptive horizontal page padding.
  ///
  /// | Screen width | Padding                     |
  /// |-------------|------------------------------|
  /// | ≥ 900 px    | 15 % of width (wide tablet)  |
  /// | ≥ 600 px    | 10 % of width (tablet)       |
  /// | < 600 px    | 16 px (phone)                |
  static double horizontalPad(BuildContext context) {
    final w = _width(context);
    if (w >= 900) return w * 0.15;
    if (w >= _tabletBreakpoint) return w * 0.10;
    return 16.0;
  }

  /// Returns [tablet] value when on tablet, [mobile] otherwise.
  /// Falls back to [mobile] when [tablet] is omitted.
  static T value<T>(BuildContext context, {required T mobile, T? tablet}) =>
      isTablet(context) ? (tablet ?? mobile) : mobile;
}
