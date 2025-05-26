import 'package:flutter/material.dart';
import 'loading_route.dart';
import 'data_loading_route.dart';

class NavigationUtils {
  // Keep track of active navigation operations to prevent duplicates
  static bool _isNavigating = false;

  /// Navigate to a page with a loading animation
  /// Uses the basic LoadingRoute for simple page transitions
  static Future<T?> navigateWithLoading<T>({
    required BuildContext context,
    required Widget page,
    String lottieAsset = 'assets/animations/loading.json',
    Duration minimumLoadingTime = const Duration(milliseconds: 1200),
    bool replaceCurrent = false,
    Color? backgroundColor,
    double lottieSize = 100,
  }) async {
    // Prevent multiple navigation requests while one is in progress
    if (_isNavigating) {
      debugPrint("🚫 تم منع عملية انتقال متكررة");
      return null;
    }

    try {
      _isNavigating = true;

      // Capture Navigator before any async operations
      final navigator = Navigator.of(context);
      final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

      final route = LoadingRoute<T>(
        page: page,
        lottieAsset: lottieAsset,
        minimumLoadingTime: minimumLoadingTime,
        backgroundColor: backgroundColor ?? scaffoldBackgroundColor,
        lottieSize: lottieSize,
      );

      final result =
          replaceCurrent
              ? await navigator.pushReplacement(route)
              : await navigator.push(route);

      return result;
    } catch (e) {
      debugPrint("❌ خطأ في الانتقال: $e");
      return null;
    } finally {
      // Reset navigation lock after a short delay to prevent quick double-taps
      Future.delayed(const Duration(milliseconds: 300), () {
        _isNavigating = false;
      });
    }
  }

  /// Navigate to a page with loading animation and data fetching
  /// Uses DataLoadingRoute for loading data before showing the page
  static Future<T?> navigateWithDataLoading<T, D>({
    required BuildContext context,
    required Future<D> Function() dataLoader,
    required Widget Function(BuildContext, D) pageBuilder,
    String lottieAsset = 'assets/animations/loading.json',
    Duration minimumLoadingTime = const Duration(milliseconds: 1200),
    bool replaceCurrent = false,
    Color? backgroundColor,
    double lottieSize = 100,
  }) async {
    // Prevent multiple navigation requests while one is in progress
    if (_isNavigating) {
      debugPrint("🚫 تم منع عملية انتقال متكررة");
      return null;
    }

    try {
      _isNavigating = true;

      // Capture Navigator before any async operations
      final navigator = Navigator.of(context);
      final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

      final route = DataLoadingRoute<T, D>(
        dataLoader: dataLoader,
        buildPageWithData: pageBuilder,
        lottieAsset: lottieAsset,
        minimumLoadingTime: minimumLoadingTime,
        backgroundColor: backgroundColor ?? scaffoldBackgroundColor,
        lottieSize: lottieSize,
      );

      final result =
          replaceCurrent
              ? await navigator.pushReplacement(route)
              : await navigator.push(route);

      return result;
    } catch (e) {
      debugPrint("❌ خطأ في الانتقال: $e");
      return null;
    } finally {
      // Reset navigation lock after a short delay to prevent quick double-taps
      Future.delayed(const Duration(milliseconds: 300), () {
        _isNavigating = false;
      });
    }
  }

  /// Navigate back safely, preventing crashes and freezes
  static bool navigateBack(BuildContext context, {dynamic result}) {
    if (!_isNavigating && Navigator.canPop(context)) {
      try {
        Navigator.pop(context, result);
        return true;
      } catch (e) {
        debugPrint("❌ خطأ في العودة: $e");
      }
    }
    return false;
  }
}
