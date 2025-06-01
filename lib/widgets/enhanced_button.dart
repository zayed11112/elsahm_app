import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';

/// Enhanced Button with modern design and animations
class EnhancedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonStyle? style;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool enableHapticFeedback;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.style,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.enableHapticFeedback = true,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: fastAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();

      if (widget.enableHapticFeedback) {
        // Add haptic feedback here if needed
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final effectiveBackgroundColor = widget.backgroundColor ?? primaryBlue;

    final effectiveForegroundColor = widget.foregroundColor ?? Colors.white;

    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(buttonBorderRadius);

    final effectivePadding =
        widget.padding ??
        const EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: defaultPadding,
        );

    final effectiveHeight = widget.height ?? buttonHeight;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Container(
              width: widget.width,
              height: effectiveHeight,
              decoration: BoxDecoration(
                color:
                    widget.gradient == null ? effectiveBackgroundColor : null,
                gradient: widget.gradient,
                borderRadius: effectiveBorderRadius,
                boxShadow:
                    widget.onPressed != null && !widget.isLoading
                        ? lightShadow
                        : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: effectiveBorderRadius,
                  onTap: widget.isLoading ? null : widget.onPressed,
                  child: Container(
                    padding: effectivePadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                effectiveForegroundColor,
                              ),
                            ),
                          )
                        else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: effectiveForegroundColor,
                            size: defaultIconSize,
                          ),
                          const SizedBox(width: smallPadding),
                        ],
                        if (!widget.isLoading)
                          Text(
                            widget.text,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: effectiveForegroundColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Primary Button with gradient background
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      width: width,
      gradient: primaryGradient,
    );
  }
}

/// Secondary Button with outline style
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: buttonHeight,
      decoration: BoxDecoration(
        border: Border.all(color: primaryBlue, width: 2),
        borderRadius: BorderRadius.circular(buttonBorderRadius),
      ),
      child: EnhancedButton(
        text: text,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
        width: width,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryBlue,
      ),
    );
  }
}

/// Success Button with green gradient
class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const SuccessButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      width: width,
      backgroundColor: successColor,
    );
  }
}

/// Danger Button with red gradient
class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      width: width,
      backgroundColor: errorColor,
    );
  }
}
