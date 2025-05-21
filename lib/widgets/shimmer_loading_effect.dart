import 'package:flutter/material.dart';

/// A shimmer loading effect widget for placeholders during data loading
class ShimmerLoadingEffect extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  final Duration duration;

  const ShimmerLoadingEffect({
    Key? key,
    required this.height,
    required this.width,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<ShimmerLoadingEffect> createState() => _ShimmerLoadingEffectState();
}

class _ShimmerLoadingEffectState extends State<ShimmerLoadingEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ]
                      : [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!,
                        ],
                  stops: const [0.1, 0.5, 0.9],
                  transform: SlidingGradientTransform(_animation.value),
                ).createShader(bounds);
              },
              child: Container(
                width: widget.width,
                height: widget.height,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom gradient transform for the shimmer effect
class SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
} 