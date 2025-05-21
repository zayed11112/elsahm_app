import 'package:flutter/material.dart';
import '../utils/navigation_utils.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0; // Default to home screen

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  /// Navigate to a page with loading animation
  Future<T?> navigateWithLoading<T>({
    required BuildContext context,
    required Widget page,
    String lottieAsset = 'assets/animations/loading.json',
    Duration minimumLoadingTime = const Duration(milliseconds: 1200),
    bool replaceCurrent = false,
  }) {
    return NavigationUtils.navigateWithLoading<T>(
      context: context,
      page: page,
      lottieAsset: lottieAsset,
      minimumLoadingTime: minimumLoadingTime,
      replaceCurrent: replaceCurrent,
    );
  }

  /// Navigate to a page with data loading
  Future<T?> navigateWithDataLoading<T, D>({
    required BuildContext context,
    required Future<D> Function() dataLoader,
    required Widget Function(BuildContext, D) pageBuilder,
    String lottieAsset = 'assets/animations/loading.json',
    Duration minimumLoadingTime = const Duration(milliseconds: 1200),
    bool replaceCurrent = false,
  }) {
    return NavigationUtils.navigateWithDataLoading<T, D>(
      context: context,
      dataLoader: dataLoader,
      pageBuilder: pageBuilder,
      lottieAsset: lottieAsset,
      minimumLoadingTime: minimumLoadingTime,
      replaceCurrent: replaceCurrent,
    );
  }
}
