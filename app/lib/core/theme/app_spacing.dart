import 'package:flutter/material.dart';

abstract final class AppSpacing {
  // Base unit: 4px
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;

  // Border radius
  static const radiusSmall = Radius.circular(8);
  static const radiusMedium = Radius.circular(12);
  static const radiusLarge = Radius.circular(16);
  static const radiusFull = Radius.circular(999);

  static final borderRadiusSmall = BorderRadius.circular(8);
  static final borderRadiusMedium = BorderRadius.circular(12);
  static final borderRadiusLarge = BorderRadius.circular(16);
  static final borderRadiusFull = BorderRadius.circular(999);

  // Common padding
  static const paddingAllSm = EdgeInsets.all(sm);
  static const paddingAllMd = EdgeInsets.all(md);
  static const paddingAllLg = EdgeInsets.all(lg);
  static const paddingAllXl = EdgeInsets.all(xl);

  static const paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const paddingVerticalMd = EdgeInsets.symmetric(vertical: md);

  // Screen padding
  static const screenPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
}
