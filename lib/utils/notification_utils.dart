import 'package:flutter/material.dart';

/// Utility functions for app notifications and alerts
class NotificationUtils {
  /// Shows a snackbar with centered text and a modern design
  static void showCenteredSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Shows a snackbar with an icon, centered text and a modern design
  static void showIconSnackBar(
    BuildContext context, 
    String message, 
    {IconData icon = Icons.info, 
    Color iconColor = Colors.white}
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Shows a success snackbar with check icon
  static void showSuccessSnackBar(BuildContext context, String message) {
    showIconSnackBar(
      context, 
      message,
      icon: Icons.check_circle, 
      iconColor: Colors.green[300]!,
    );
  }
  
  /// Shows an error snackbar with error icon
  static void showErrorSnackBar(BuildContext context, String message) {
    showIconSnackBar(
      context, 
      message,
      icon: Icons.error_outline, 
      iconColor: Colors.red[300]!,
    );
  }
} 