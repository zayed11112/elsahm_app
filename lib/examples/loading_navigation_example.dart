import 'package:flutter/material.dart';
import '../utils/navigation_utils.dart';

class LoadingNavigationExample extends StatelessWidget {
  const LoadingNavigationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال للانتقال مع التحميل'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example 1: Simple page transition with loading animation
            ElevatedButton(
              onPressed: () => _navigateToSimplePage(context),
              child: const Text('انتقال بسيط مع تحميل'),
            ),
            const SizedBox(height: 20),
            
            // Example 2: Navigate with data loading
            ElevatedButton(
              onPressed: () => _navigateWithDataLoading(context),
              child: const Text('انتقال مع تحميل البيانات'),
            ),
          ],
        ),
      ),
    );
  }

  // Simple page transition with loading animation
  void _navigateToSimplePage(BuildContext context) {
    NavigationUtils.navigateWithLoading(
      context: context,
      page: const DestinationPage(title: 'صفحة بسيطة'),
      // You can customize these parameters
      lottieAsset: 'assets/animations/loading.json',
      minimumLoadingTime: const Duration(milliseconds: 1500),
    );
  }

  // Navigate with data loading in the background
  void _navigateWithDataLoading(BuildContext context) {
    NavigationUtils.navigateWithDataLoading<void, List<String>>(
      context: context,
      // Simulate data loading
      dataLoader: () => Future.delayed(
        const Duration(seconds: 2),
        () => ['بيانات 1', 'بيانات 2', 'بيانات 3'],
      ),
      // Build the page with the loaded data
      pageBuilder: (context, data) => DataPage(items: data),
      // You can customize these parameters
      lottieAsset: 'assets/animations/loading.json',
      minimumLoadingTime: const Duration(milliseconds: 1000),
    );
  }
}

// Simple destination page
class DestinationPage extends StatelessWidget {
  final String title;

  const DestinationPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(
        child: Text('تم الانتقال بنجاح مع عرض أنيميشن التحميل'),
      ),
    );
  }
}

// Page that displays loaded data
class DataPage extends StatelessWidget {
  final List<String> items;

  const DataPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحة البيانات'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(items[index]),
            leading: const Icon(Icons.check_circle),
          );
        },
      ),
    );
  }
} 