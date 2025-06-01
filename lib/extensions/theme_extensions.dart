import 'package:flutter/material.dart';
import '../constants/theme.dart';

/// Extensions on BuildContext for easily accessing theme properties
extension ThemeExtensions on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);

  // Colors
  ColorScheme get colorScheme => theme.colorScheme;
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get backgroundColor => theme.scaffoldBackgroundColor;
  Color get cardColor => theme.cardColor;

  // Text Styles
  TextTheme get textTheme => theme.textTheme;
  TextStyle? get titleLarge => textTheme.titleLarge;
  TextStyle? get titleMedium => textTheme.titleMedium;
  TextStyle? get titleSmall => textTheme.titleSmall;
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;

  // Theme Mode
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // Status Colors based on the theme
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pendingColor;
      case 'approved':
        return approvedColor;
      case 'rejected':
        return rejectedColor;
      case 'inactive':
        return inactiveColor;
      default:
        return isDarkMode ? darkTextSecondary : lightTextSecondary;
    }
  }

  // Widget Styling - Border Radius
  BorderRadius get defaultBorderRadiusValue =>
      BorderRadius.circular(defaultBorderRadius);
  BorderRadius get buttonRadiusBorder =>
      BorderRadius.circular(buttonBorderRadius);
  BorderRadius get cardRadiusBorder => BorderRadius.circular(cardBorderRadius);

  EdgeInsets get defaultPaddingAll => const EdgeInsets.all(defaultPadding);
  EdgeInsets get smallPaddingAll => const EdgeInsets.all(smallPadding);
  EdgeInsets get largePaddingAll => const EdgeInsets.all(largePadding);

  EdgeInsets get defaultPaddingHorizontal =>
      const EdgeInsets.symmetric(horizontal: defaultPadding);
  EdgeInsets get defaultPaddingVertical =>
      const EdgeInsets.symmetric(vertical: defaultPadding);

  List<BoxShadow> get cardShadow => isDarkMode ? [] : lightShadow;
  List<BoxShadow> get elevatedShadow => isDarkMode ? [] : mediumShadow;
}
