import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';

/// Enhanced Notification Types
enum NotificationType { success, error, warning, info }

/// Enhanced Notification Banner
class EnhancedNotificationBanner extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration? duration;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final Widget? action;
  final bool showCloseButton;

  const EnhancedNotificationBanner({
    super.key,
    required this.message,
    this.type = NotificationType.info,
    this.duration,
    this.onDismiss,
    this.onTap,
    this.action,
    this.showCloseButton = true,
  });

  @override
  State<EnhancedNotificationBanner> createState() =>
      _EnhancedNotificationBannerState();
}

class _EnhancedNotificationBannerState extends State<EnhancedNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: normalAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Auto dismiss after duration
    if (widget.duration != null) {
      Future.delayed(widget.duration!, () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return successColor;
      case NotificationType.error:
        return errorColor;
      case NotificationType.warning:
        return warningColor;
      case NotificationType.info:
        return infoColor;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final icon = _getIcon();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(defaultPadding),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(defaultBorderRadius),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                boxShadow: mediumShadow,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(smallPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: defaultIconSize,
                        ),
                      ),

                      const SizedBox(width: defaultPadding),

                      // Message
                      Expanded(
                        child: Text(
                          widget.message,
                          style: context.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Action or Close Button
                      if (widget.action != null)
                        widget.action!
                      else if (widget.showCloseButton)
                        IconButton(
                          onPressed: _dismiss,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced Snackbar
class EnhancedSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final backgroundColor = _getBackgroundColor(type);
    final icon = _getIcon(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
        margin: const EdgeInsets.all(defaultPadding),
        action:
            actionLabel != null
                ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onActionPressed ?? () {},
                )
                : null,
      ),
    );
  }

  static Color _getBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return successColor;
      case NotificationType.error:
        return errorColor;
      case NotificationType.warning:
        return warningColor;
      case NotificationType.info:
        return infoColor;
    }
  }

  static IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }
}

/// Enhanced Alert Dialog
class EnhancedAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final NotificationType type;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool barrierDismissible;

  const EnhancedAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.type = NotificationType.info,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.barrierDismissible = true,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    NotificationType type = NotificationType.info,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (context) => EnhancedAlertDialog(
            title: title,
            content: content,
            type: type,
            confirmText: confirmText,
            cancelText: cancelText,
            onConfirm: onConfirm,
            onCancel: onCancel,
            barrierDismissible: barrierDismissible,
          ),
    );
  }

  Color _getColor() {
    switch (type) {
      case NotificationType.success:
        return successColor;
      case NotificationType.error:
        return errorColor;
      case NotificationType.warning:
        return warningColor;
      case NotificationType.info:
        return infoColor;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final color = _getColor();
    final icon = _getIcon();

    return AlertDialog(
      backgroundColor: isDarkMode ? darkCard : lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(largeBorderRadius),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(smallPadding),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: defaultIconSize),
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Text(
              title,
              style: context.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? darkTextPrimary : lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: context.bodyMedium?.copyWith(
          color: isDarkMode ? darkTextSecondary : lightTextSecondary,
        ),
      ),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              onCancel?.call();
            },
            child: Text(
              cancelText!,
              style: TextStyle(
                color: isDarkMode ? darkTextSecondary : lightTextSecondary,
              ),
            ),
          ),
        if (confirmText != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
              ),
            ),
            child: Text(confirmText!),
          ),
      ],
    );
  }
}
