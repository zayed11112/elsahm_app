import 'package:flutter/material.dart';
import 'loading_route.dart';

/// A specialized route that loads data before showing the destination page
class DataLoadingRoute<T, D> extends LoadingRoute<T> {
  final Future<D> Function() dataLoader;
  final Widget Function(BuildContext, D) buildPageWithData;
  late Future<D> _dataFuture;
  bool _isRetrying = false;
  bool _hasTimedOut = false;
  // Flag to track if route is still active
  bool _isActive = true;

  DataLoadingRoute({
    required this.dataLoader,
    required this.buildPageWithData,
    super.lottieAsset = 'assets/animations/loading.json',
    super.animationDuration = const Duration(milliseconds: 800),
    super.minimumLoadingTime = const Duration(milliseconds: 1200),
    super.backgroundColor = Colors.white,
    super.lottieSize = 100,
    super.timeout = const Duration(seconds: 15),
  }) : super(
         page: Container(), // Placeholder, will be replaced
       ) {
    // Start loading data immediately when route is created
    _dataFuture = dataLoader();

    // Set up timeout for data loading
    Future.delayed(timeout).then((_) {
      if (_isActive) {
        _hasTimedOut = true;
      }
    });
  }

  @override
  void dispose() {
    _isActive = false;
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FutureBuilder<D>(
      future: _dataFuture,
      builder: (context, snapshot) {
        // Check for timeout first
        if (_hasTimedOut) {
          return _buildTimeoutErrorScreen(context);
        }

        // Then check data loading states
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // Handle data loading error
            return _buildErrorScreen(context, snapshot.error);
          } else if (snapshot.hasData) {
            // Data loaded, now check if minimum loading time is complete
            return FutureBuilder(
              future: Future.delayed(minimumLoadingTime),
              builder: (context, timeSnapshot) {
                if (timeSnapshot.connectionState == ConnectionState.done) {
                  return buildPageWithData(context, snapshot.data as D);
                } else {
                  return buildLoadingScreen(context);
                }
              },
            );
          }
        }

        // Still loading data
        return buildLoadingScreen(context);
      },
    );
  }

  @override
  Future<void> precachePageData(BuildContext context) async {
    // Data is already being loaded through _dataFuture
    return;
  }

  Widget _buildTimeoutErrorScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      // Handle back button press safely
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : backgroundColor,
        appBar: AppBar(
          title: const Text('خطأ في التحميل'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'تجاوز وقت الاستجابة المسموح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, dynamic error) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      // Handle back button press safely
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خطأ'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ أثناء تحميل البيانات',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error?.toString() ?? 'خطأ غير معروف',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (!_isRetrying) {
                        _isRetrying = true;
                        _dataFuture = dataLoader();
                        _isRetrying = false;
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('العودة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
