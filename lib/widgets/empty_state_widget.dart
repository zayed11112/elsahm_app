import 'package:flutter/material.dart';

/// A reusable empty state widget to display when no content is available
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with animated container
              Container(
                width: iconSize * 1.5,
                height: iconSize * 1.5,
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? theme.colorScheme.primary.withValues(alpha: 0.05)
                          : theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title text
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Message text
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Action button
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 16.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 10),
                    Text(buttonText),
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
