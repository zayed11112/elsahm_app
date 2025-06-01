import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';

/// Enhanced Loading Widget with multiple animation styles
class EnhancedLoading extends StatefulWidget {
  final LoadingStyle style;
  final Color? color;
  final double size;
  final String? message;
  final bool showMessage;

  const EnhancedLoading({
    super.key,
    this.style = LoadingStyle.circular,
    this.color,
    this.size = 40.0,
    this.message,
    this.showMessage = false,
  });

  @override
  State<EnhancedLoading> createState() => _EnhancedLoadingState();
}

enum LoadingStyle { circular, dots, pulse, wave, shimmer }

class _EnhancedLoadingState extends State<EnhancedLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final effectiveColor =
        widget.color ?? (isDarkMode ? primaryBlueLight : primaryBlue);

    Widget loadingWidget;

    switch (widget.style) {
      case LoadingStyle.circular:
        loadingWidget = _buildCircularLoading(effectiveColor);
        break;
      case LoadingStyle.dots:
        loadingWidget = _buildDotsLoading(effectiveColor);
        break;
      case LoadingStyle.pulse:
        loadingWidget = _buildPulseLoading(effectiveColor);
        break;
      case LoadingStyle.wave:
        loadingWidget = _buildWaveLoading(effectiveColor);
        break;
      case LoadingStyle.shimmer:
        loadingWidget = _buildShimmerLoading(effectiveColor);
        break;
    }

    if (widget.showMessage && widget.message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingWidget,
          const SizedBox(height: defaultPadding),
          Text(
            widget.message!,
            style: context.bodyMedium?.copyWith(color: effectiveColor),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return loadingWidget;
  }

  Widget _buildCircularLoading(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildDotsLoading(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_animation.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size / 4,
                  height: widget.size / 4,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.7 + (0.3 * scale)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPulseLoading(Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveLoading(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final delay = index * 0.1;
            final animationValue = (_animation.value - delay) % 1.0;
            final height =
                widget.size *
                (0.3 + 0.7 * (1 - (animationValue - 0.5).abs() * 2));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: widget.size / 8,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(widget.size / 16),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildShimmerLoading(Color color) {
    return Shimmer.fromColors(
      baseColor: color.withValues(alpha: 0.3),
      highlightColor: color.withValues(alpha: 0.7),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
      ),
    );
  }
}

/// Loading Overlay for full screen loading
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final LoadingStyle style;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.style = LoadingStyle.circular,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color:
                backgroundColor ??
                (isDarkMode
                    ? Colors.black.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.8)),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(largePadding),
                decoration: BoxDecoration(
                  color: isDarkMode ? darkCard : lightCard,
                  borderRadius: BorderRadius.circular(largeBorderRadius),
                  boxShadow: mediumShadow,
                ),
                child: EnhancedLoading(
                  style: style,
                  message: message,
                  showMessage: message != null,
                  size: 50,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shimmer Loading for list items
class ShimmerListItem extends StatelessWidget {
  final double height;
  final EdgeInsets? margin;

  const ShimmerListItem({super.key, this.height = 80, this.margin});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return Container(
      margin:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: smallPadding,
          ),
      child: Shimmer.fromColors(
        baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(defaultBorderRadius),
          ),
          child: Row(
            children: [
              // Avatar placeholder
              Container(
                margin: const EdgeInsets.all(defaultPadding),
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              // Content placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      margin: const EdgeInsets.only(right: defaultPadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: smallPadding),
                    Container(
                      height: 12,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
