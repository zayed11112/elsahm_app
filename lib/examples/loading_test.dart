import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/navigation_utils.dart';
import '../utils/loading_service.dart';

class LoadingTest extends StatelessWidget {
  const LoadingTest({super.key});

  @override
  Widget build(BuildContext context) {
    // تفعيل وضع التصحيح
    LoadingService.debugMode = true;

    return Scaffold(
      appBar: AppBar(title: const Text('اختبار التحميل')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // اختبار باستخدام NavigationProvider
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<NavigationProvider>(
                  context,
                  listen: false,
                );
                provider.navigateWithLoading(
                  context: context,
                  page: const TestDestination(title: 'النمط القديم'),
                  lottieAsset: 'assets/animations/loading.json',
                );
              },
              child: const Text('طريقة NavigationProvider'),
            ),

            const SizedBox(height: 20),

            // اختبار باستخدام NavigationUtils مباشرة
            ElevatedButton(
              onPressed: () {
                NavigationUtils.navigateWithLoading(
                  context: context,
                  page: const TestDestination(title: 'طريقة NavigationUtils'),
                  lottieAsset: 'assets/animations/loading.json',
                  minimumLoadingTime: const Duration(
                    seconds: 2,
                  ), // زيادة وقت التحميل للاختبار
                );
              },
              child: const Text('طريقة NavigationUtils'),
            ),

            const SizedBox(height: 20),

            // استخدام الخدمة المركزية الجديدة
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: const Size(240, 50),
              ),
              onPressed: () {
                LoadingService.navigateWithLoading(
                  context: context,
                  page: const TestDestination(title: 'الخدمة المركزية'),
                  minimumLoadingTime: const Duration(seconds: 2),
                );
              },
              child: const Text(
                'LoadingService - محسّن',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            // اختبار تحميل البيانات
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(240, 50),
              ),
              onPressed: () {
                LoadingService.navigateWithDataLoading<void, List<String>>(
                  context: context,
                  dataLoader:
                      () => Future.delayed(
                        const Duration(seconds: 3),
                        () => [
                          'بيانات 1',
                          'بيانات 2',
                          'بيانات 3',
                          'بيانات 4',
                          'بيانات 5',
                        ],
                      ),
                  pageBuilder: (context, data) => DataPage(items: data),
                );
              },
              child: const Text(
                'تحميل مع بيانات خارجية',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple destination page
class TestDestination extends StatelessWidget {
  final String title;

  const TestDestination({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('تم الانتقال إلى هذه الصفحة بنجاح'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('عودة'),
            ),
          ],
        ),
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
      appBar: AppBar(title: const Text('صفحة البيانات')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: const Text(
              'تم تحميل البيانات قبل عرض الصفحة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(items[index]),
                  leading: const Icon(Icons.check_circle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
