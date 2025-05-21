import 'package:flutter/material.dart';

/// A custom tab indicator with a rounded rectangle shape
class CustomTabIndicator extends Decoration {
  final Color color;
  final double radius;
  final double indicatorHeight;

  const CustomTabIndicator({
    required this.color,
    this.radius = 4,
    this.indicatorHeight = 3,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomPainter(
      this,
      onChanged,
    );
  }
}

class _CustomPainter extends BoxPainter {
  final CustomTabIndicator decoration;

  _CustomPainter(this.decoration, VoidCallback? onChanged) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    
    // Calculate indicator position
    final Rect rect = offset & configuration.size!;
    final Paint paint = Paint();
    
    // Set indicator color
    paint.color = decoration.color;
    paint.style = PaintingStyle.fill;
    
    // Calculate indicator dimensions and position
    final indicatorWidth = rect.width * 0.6; // 60% of tab width
    final indicatorHeight = decoration.indicatorHeight;
    
    final indicatorRect = Rect.fromLTWH(
      rect.left + (rect.width - indicatorWidth) / 2, // Center horizontally
      rect.bottom - indicatorHeight, // Position at bottom
      indicatorWidth,
      indicatorHeight,
    );
    
    final RRect roundedRect = RRect.fromRectAndRadius(
      indicatorRect,
      Radius.circular(decoration.radius),
    );
    
    // Draw the indicator
    canvas.drawRRect(roundedRect, paint);
  }
} 