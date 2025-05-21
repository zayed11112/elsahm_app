import 'package:flutter/material.dart';

/// Helper class to convert string icon names to Flutter Icons
class IconHelper {
  static Icon getIconFromString(String iconName, {double size = 24.0, Color? color}) {
    IconData iconData;
    
    switch (iconName) {
      case 'location_city':
        iconData = Icons.location_city_outlined;
        break;
      case 'single_bed':
        iconData = Icons.single_bed_outlined;
        break;
      case 'star':
        iconData = Icons.star_border_outlined;
        break;
      case 'girl':
        iconData = Icons.girl_outlined;
        break;
      case 'home':
        iconData = Icons.home_outlined;
        break;
      case 'apartment':
        iconData = Icons.apartment_outlined;
        break;
      case 'house':
        iconData = Icons.house_outlined;
        break;
      case 'building':
        iconData = Icons.domain_outlined;
        break;
      case 'category':
        iconData = Icons.category_outlined;
        break;
      default:
        iconData = Icons.category_outlined; // Default icon
    }
    
    return Icon(iconData, size: size, color: color);
  }
} 