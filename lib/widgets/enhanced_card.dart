import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';

/// Enhanced Card Widget with modern design and animations
class EnhancedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool enableHoverEffect;
  final bool enablePressEffect;
  final Gradient? gradient;
  final Border? border;
  final double? elevation;

  const EnhancedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.onTap,
    this.enableHoverEffect = true,
    this.enablePressEffect = true,
    this.gradient,
    this.border,
    this.elevation,
  });

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: fastAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enablePressEffect && widget.onTap != null) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enablePressEffect && widget.onTap != null) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enablePressEffect && widget.onTap != null) {
      _animationController.reverse();
    }
  }

  void _handleHover(bool isHovered) {
    if (widget.enableHoverEffect) {
      setState(() => _isHovered = isHovered);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    // Determine colors based on theme
    final effectiveBackgroundColor =
        widget.backgroundColor ?? (isDarkMode ? darkCard : lightCard);

    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(cardBorderRadius);

    final effectiveBoxShadow =
        widget.boxShadow ?? (isDarkMode ? [] : lightShadow);

    final effectivePadding =
        widget.padding ?? const EdgeInsets.all(defaultPadding);

    final effectiveMargin = widget.margin ?? const EdgeInsets.all(smallPadding);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: effectiveMargin,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: widget.onTap,
              child: Transform.scale(
                scale: widget.enablePressEffect ? _scaleAnimation.value : 1.0,
                child: AnimatedContainer(
                  duration: normalAnimation,
                  curve: Curves.easeInOut,
                  padding: effectivePadding,
                  decoration: BoxDecoration(
                    color:
                        widget.gradient == null
                            ? effectiveBackgroundColor
                            : null,
                    gradient: widget.gradient,
                    borderRadius: effectiveBorderRadius,
                    border: widget.border,
                    boxShadow:
                        _isHovered && widget.enableHoverEffect
                            ? mediumShadow
                            : effectiveBoxShadow,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced Card with Gradient Background
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedCard(
      gradient: gradient,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }
}

/// Enhanced Card with Status Indicator
class StatusCard extends StatelessWidget {
  final Widget child;
  final String status;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.child,
    required this.status,
    this.padding,
    this.margin,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'موافق':
        return successColor;
      case 'pending':
      case 'معلق':
        return pendingColor;
      case 'rejected':
      case 'مرفوض':
        return errorColor;
      default:
        return inactiveColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return EnhancedCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: smallPadding,
              vertical: smallPadding / 2,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(smallBorderRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: smallPadding / 2),
                Text(
                  status,
                  style: context.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: smallPadding),
          // Main content
          child,
        ],
      ),
    );
  }
}
