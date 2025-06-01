import 'package:flutter/material.dart';

/// Enhanced Theme System for Elsahm App
/// Modern color palette with improved accessibility and visual appeal

// === PRIMARY COLOR PALETTE ===
// Modern Blue Gradient System
const Color primaryBlue = Color(0xFF1E88E5); // Main primary
const Color primaryBlueDark = Color(0xFF1565C0); // Darker variant
const Color primaryBlueLight = Color(0xFF42A5F5); // Lighter variant
const Color accentBlue = Color(0xFF29B6F6); // Accent blue
const Color skyBlue = Color(0xFF81D4FA); // Sky blue
const Color deepBlue = Color(0xFF0D47A1); // Deep blue

// === SECONDARY COLORS ===
const Color secondaryTeal = Color(0xFF26A69A); // Teal accent
const Color secondaryPurple = Color(0xFF7E57C2); // Purple accent
const Color secondaryOrange = Color(0xFFFF7043); // Orange accent

// === BACKGROUND COLORS ===
// Dark Theme Backgrounds
const Color darkBackground = Color(0xFF0A0E1A); // Deep dark blue
const Color darkSurface = Color(0xFF1A1F2E); // Card surface dark
const Color darkCard = Color(0xFF252B3A); // Card background
const Color darkElevated = Color(0xFF2D3447); // Elevated surfaces

// Light Theme Backgrounds
const Color lightBackground = Color(0xFFF8FAFC); // Soft light background
const Color lightSurface = Color(0xFFFFFFFF); // Pure white surface
const Color lightCard = Color(0xFFFFFFFF); // White cards
const Color lightElevated = Color(0xFFF1F5F9); // Elevated light

// === TEXT COLORS ===
// Dark Theme Text
const Color darkTextPrimary = Color(0xFFE2E8F0); // Primary text dark
const Color darkTextSecondary = Color(0xFFCBD5E1); // Secondary text dark
const Color darkTextTertiary = Color(0xFF94A3B8); // Tertiary text dark

// Light Theme Text
const Color lightTextPrimary = Color(0xFF1E293B); // Primary text light
const Color lightTextSecondary = Color(0xFF475569); // Secondary text light
const Color lightTextTertiary = Color(0xFF64748B); // Tertiary text light

// === STATUS COLORS ===
const Color successColor = Color(0xFF10B981); // Success green
const Color warningColor = Color(0xFFF59E0B); // Warning amber
const Color errorColor = Color(0xFFEF4444); // Error red
const Color infoColor = Color(0xFF3B82F6); // Info blue
const Color pendingColor = Color(0xFFEAB308); // Pending yellow

// Legacy color names for backward compatibility
const Color approvedColor = successColor; // Approved = Success
const Color rejectedColor = errorColor; // Rejected = Error
const Color inactiveColor = Color(0xFF9E9E9E); // Inactive gray

// Additional legacy colors for compatibility
const Color lightBlue = skyBlue; // Legacy light blue
const Color darkBlue = deepBlue; // Legacy dark blue
const Color primarySkyBlue = primaryBlueLight; // Legacy sky blue
const Color lightCardColor = lightCard; // Legacy card color
const Color darkCardColor = darkCard; // Legacy dark card

// === ENHANCED GRADIENTS ===
const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [primaryBlue, primaryBlueLight],
);

const LinearGradient darkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [primaryBlueDark, deepBlue],
);

const LinearGradient accentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [secondaryTeal, accentBlue],
);

const LinearGradient warmGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [secondaryOrange, warningColor],
);

const LinearGradient coolGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [secondaryPurple, primaryBlue],
);

// === SPACING & SIZING CONSTANTS ===
const double defaultPadding = 16.0;
const double smallPadding = 8.0;
const double largePadding = 24.0;
const double extraLargePadding = 32.0;

// Border Radius
const double defaultBorderRadius = 12.0;
const double smallBorderRadius = 8.0;
const double largeBorderRadius = 16.0;
const double extraLargeBorderRadius = 24.0;

// Card Properties
const double cardElevation = 4.0;
const double cardBorderRadius = defaultBorderRadius;

// Button Properties
const double buttonHeight = 48.0;
const double buttonBorderRadius = defaultBorderRadius;

// Icon Sizes
const double smallIconSize = 16.0;
const double defaultIconSize = 24.0;
const double largeIconSize = 32.0;
const double extraLargeIconSize = 48.0;

// === SHADOWS ===
const List<BoxShadow> lightShadow = [
  BoxShadow(color: Color(0x1A000000), blurRadius: 8.0, offset: Offset(0, 2)),
];

const List<BoxShadow> mediumShadow = [
  BoxShadow(color: Color(0x1F000000), blurRadius: 12.0, offset: Offset(0, 4)),
];

const List<BoxShadow> heavyShadow = [
  BoxShadow(color: Color(0x29000000), blurRadius: 16.0, offset: Offset(0, 8)),
];

// === ANIMATION DURATIONS ===
const Duration fastAnimation = Duration(milliseconds: 200);
const Duration normalAnimation = Duration(milliseconds: 300);
const Duration slowAnimation = Duration(milliseconds: 500);

// === FONT FAMILY ===
const String fontFamily = 'Tajawal';
