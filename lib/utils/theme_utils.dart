import 'package:flutter/material.dart';
import '../constants/theme.dart';

/// Utility functions for theme styling across the app
class ThemeUtils {
  /// Get appropriate text color based on background color
  /// Uses contrast ratio to determine if text should be light or dark
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calculate relative luminance
    double luminance = backgroundColor.computeLuminance();

    // Use white text on dark backgrounds, black text on light backgrounds
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Get decoration for cards with consistent styling
  static BoxDecoration getCardDecoration({
    required bool isDarkMode,
    Color? color,
    BorderRadius? borderRadius,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: color ?? (isDarkMode ? darkCardColor : lightCardColor),
      borderRadius: borderRadius ?? BorderRadius.circular(cardBorderRadius),
      boxShadow: withShadow && !isDarkMode ? lightShadow : [],
    );
  }

  /// Get decoration for buttons with gradient
  static BoxDecoration getGradientButtonDecoration({
    LinearGradient? gradient,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      gradient: gradient ?? primaryGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(buttonBorderRadius),
      boxShadow: lightShadow,
    );
  }

  /// Get status color with opacity
  static Color getStatusColorWithOpacity(
    String status, {
    double opacity = 0.2,
  }) {
    Color baseColor;

    switch (status.toLowerCase()) {
      case 'pending':
        baseColor = pendingColor;
        break;
      case 'approved':
        baseColor = approvedColor;
        break;
      case 'rejected':
        baseColor = rejectedColor;
        break;
      case 'inactive':
        baseColor = inactiveColor;
        break;
      default:
        baseColor = Colors.grey;
    }

    return baseColor.withValues(alpha: opacity);
  }

  /// Apply theme to text field
  static InputDecoration getInputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isDarkMode = false,
    bool isError = false,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      errorText: isError ? errorText : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: isDarkMode ? primarySkyBlue : darkBlue,
          width: 1.5,
        ),
      ),
      labelStyle: TextStyle(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
      ),
      hintStyle: TextStyle(
        color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
      ),
    );
  }
}
