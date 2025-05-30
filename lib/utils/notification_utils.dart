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
  
  /// Shows an error message as a MaterialBanner at the top of the screen
  static void showTopErrorBanner(BuildContext context, String message) {
    // Hide any existing banner first
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leadingPadding: const EdgeInsets.only(right: 0),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text(
              'حسناً',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    
    // Auto-hide the banner after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }
  
  /// Shows a success message as a MaterialBanner at the top of the screen
  static void showTopSuccessBanner(BuildContext context, String message) {
    // Hide any existing banner first
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leadingPadding: const EdgeInsets.only(right: 0),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text(
              'حسناً',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    
    // Auto-hide the banner after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }
} 