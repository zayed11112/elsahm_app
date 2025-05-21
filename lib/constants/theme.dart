import 'package:flutter/material.dart';

/// Theme constants for the Elsahm app
/// These constants provide consistent colors and styling across the app

// Primary Colors
const Color primarySkyBlue = Color(0xFF4FC3F7);
const Color accentBlue = Color(0xFF29B6F6);
const Color darkBlue = Color(0xFF0288D1);
const Color lightBlue = Color(0xFF81D4FA);

// Background Colors
const Color darkBackground = Color(0xFF121212);
const Color darkCardColor = Color(0xFF1E1E1E);
const Color lightBackground = Color(0xFFF5F7FA);
const Color lightCardColor = Color(0xFFFFFFFF);

// Text Colors
const Color darkTextPrimary = Color(0xFFFFFFFF);
const Color darkTextSecondary = Color(0xB3FFFFFF); // 70% white
const Color lightTextPrimary = Color(0xFF263238);
const Color lightTextSecondary = Color(0xFF546E7A);

// Status Colors
const Color pendingColor = Color(0xFFFF9800); // Orange
const Color approvedColor = Color(0xFF4CAF50); // Green
const Color rejectedColor = Color(0xFFF44336); // Red
const Color inactiveColor = Color(0xFF9E9E9E); // Grey

// Gradients
const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [primarySkyBlue, accentBlue],
);

// Padding and Sizing
const double defaultPadding = 16.0;
const double smallPadding = 8.0;
const double largePadding = 24.0;
const double borderRadius = 8.0;
const double buttonBorderRadius = 8.0;
const double cardBorderRadius = 12.0;
const double iconSize = 24.0;

// Shadows
final List<BoxShadow> lightShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: const Offset(0, 5),
  ),
];

final List<BoxShadow> mediumShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 20,
    offset: const Offset(0, 10),
  ),
];

// Font Family Name
const String fontFamily = 'Tajawal'; 