import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';
import '../utils/theme_utils.dart';

/// A card widget that adapts to the current theme
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool withShadow;
  final VoidCallback? onTap;
  final Widget? header;
  final Widget? footer;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(defaultPadding),
    this.color,
    this.elevation,
    this.borderRadius,
    this.withShadow = true,
    this.onTap,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final effectiveBorderRadius = borderRadius ?? context.defaultBorderRadius;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: ThemeUtils.getCardDecoration(
          isDarkMode: isDarkMode,
          color: color ?? context.cardColor,
          borderRadius: effectiveBorderRadius,
          withShadow: withShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) header!,
            Padding(padding: padding, child: child),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}

/// A card with a status indicator
class StatusCard extends StatelessWidget {
  final String status;
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const StatusCard({
    super.key,
    required this.status,
    required this.title,
    this.subtitle,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(defaultPadding),
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = context.getStatusColor(status);

    return ThemedCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      header: Container(
        padding: context.defaultPaddingHorizontal.copyWith(top: defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: smallPadding * 1.5,
                    vertical: smallPadding / 2,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getStatusColorWithOpacity(status),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Text(
                    status,
                    style: context.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: smallPadding / 2),
              Text(
                subtitle!,
                style: context.bodySmall?.copyWith(
                  color:
                      context.isDarkMode
                          ? darkTextSecondary
                          : lightTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: defaultPadding),
            Divider(
              height: 1,
              color:
                  context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
