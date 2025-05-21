import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String lottieAsset;
  final Duration animationDuration;
  final Duration minimumLoadingTime;
  final Color backgroundColor;
  final double lottieSize;
  
  // Add a timeout to prevent infinite loading
  final Duration timeout;
  bool _hasTimedOut = false;
  
  LoadingRoute({
    required this.page,
    this.lottieAsset = 'assets/animations/loading.json',
    this.animationDuration = const Duration(milliseconds: 800),
    this.minimumLoadingTime = const Duration(milliseconds: 1200),
    this.backgroundColor = Colors.white,
    this.lottieSize = 100,
    this.timeout = const Duration(seconds: 10),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Use a fade transition for smoother experience
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          // Short transition duration to make it smoother but still visual
          transitionDuration: const Duration(milliseconds: 150),
          reverseTransitionDuration: const Duration(milliseconds: 100),
          // Prevent system back gesture during transition to avoid crashes
          barrierDismissible: false,
        );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FutureBuilder(
      future: _loadPageWithMinimumTime(context),
      builder: (context, snapshot) {
        if (_hasTimedOut) {
          // If timeout occurred, show error with retry option
          return _buildTimeoutErrorScreen(context);
        } else if (snapshot.connectionState == ConnectionState.done) {
          return page;
        } else {
          return buildLoadingScreen(context);
        }
      },
    );
  }

  Future<void> _loadPageWithMinimumTime(BuildContext context) async {
    // إضافة تأخير إجباري ليظهر التحميل دائماً
    debugPrint("بدء شاشة التحميل");
    try {
      // Set up timeout to prevent infinite loading
      bool completed = false;
      
      // Main loading tasks
      final loadingTask = Future.wait([
        Future.delayed(minimumLoadingTime),
        Future.microtask(() => precachePageData(context)),
      ]).then((_) {
        completed = true;
      });
      
      // Timeout handler
      final timeoutTask = Future.delayed(timeout).then((_) {
        if (!completed) {
          _hasTimedOut = true;
          debugPrint("⚠️ تجاوز مهلة التحميل");
        }
      });
      
      // Wait for either completion or timeout
      await Future.any([loadingTask, timeoutTask]);
      
      if (completed) {
        debugPrint("✅ انتهاء التحميل بنجاح");
      }
    } catch (e) {
      debugPrint("❌ خطأ أثناء التحميل: $e");
    }
  }

  Future<void> precachePageData(BuildContext context) async {
    // Overridable method to allow for data loading/precaching
    // This can be used to preload images, fetch data, etc.
  }

  Widget buildLoadingScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: lottieSize,
              width: lottieSize,
              child: Lottie.asset(
                lottieAsset,
                frameRate: FrameRate.max,
                repeat: true,
              ),
            ),
            const SizedBox(height: 20),
            // إضافة نص يوضح أن التحميل جارٍ
            Text(
              'جارٍ التحميل...',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeoutErrorScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      // Handle back button press safely
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 