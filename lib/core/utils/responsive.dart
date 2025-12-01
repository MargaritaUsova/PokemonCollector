import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
          MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static int getCrossAxisCount(BuildContext context) {
    if (isLandscape(context)) {
      if (isTablet(context) || isDesktop(context)) return 4;
      return 3;
    } else {
      if (isTablet(context)) return 3;
      return 2;
    }
  }

  static double getCardAspectRatio(BuildContext context) {
    return isLandscape(context) ? 0.6 : 0.7;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isTablet(context) || isDesktop(context)) {
      return EdgeInsets.all(24);
    }
    return EdgeInsets.all(16);
  }
}
