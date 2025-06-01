import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:logging/logging.dart'; // Import logging
import 'dart:async'; // ضروري للتعامل مع الاستثناءات بشكل متزامن
import 'package:flutter/services.dart'; // لضبط توجيه الشاشة
import 'package:onesignal_flutter/onesignal_flutter.dart'; // Import OneSignal
import 'package:intl/date_symbol_data_local.dart'; // إضافة استيراد جديد
import 'package:sentry_flutter/sentry_flutter.dart'; // Import Sentry
import 'package:flutter/foundation.dart'; // For kReleaseMode

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart'; // Import NavigationProvider
import 'providers/category_provider.dart'; // Import CategoryProvider
import 'providers/favorites_provider.dart'; // Import FavoritesProvider
import 'services/notification_service.dart'; // Import NotificationService

// Import the generated file
import 'firebase_options.dart';

// Import the screens
import 'screens/splash_screen.dart';
import 'screens/error_screen.dart'; // تم إنشاء هذا الملف
import 'screens/login_screen.dart'; // Import LoginScreen for routes

// إضافة مفتاح Navigator عام للوصول إلى context بطريقة آمنة
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// إضافة تحكم في زمن انتظار الاتصال
const Duration connectionTimeout = Duration(seconds: 8);

// إضافة متغير للتحكم في حالة البدء
bool isInitialized = false;

// Logger instance for main.dart
final Logger _logger = Logger('Main');
final Logger _oneSignalLogger = Logger('OneSignal');

// OneSignal App ID
const String oneSignalAppId = '3136dbc6-c09c-4bca-b0aa-fe35421ac513';

// Sentry DSN
const String sentryDsn = 'https://1ba5f23f8807449a9943d0e4bea7b445@o4509413739266049.ingest.de.sentry.io/4509413740380240';

// إضافة دالة لعرض مربع حوار الخروج من التطبيق
Future<bool> showExitConfirmationDialog(BuildContext context) async {
  final ThemeData theme = Theme.of(context);
  final bool isDarkMode = theme.brightness == Brightness.dark;
  
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: isDarkMode ? Colors.lightBlueAccent : Colors.lightBlueAccent[700]!,
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: isDarkMode ? Colors.lightBlueAccent : Colors.lightBlueAccent[700],
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'تأكيد الخروج',
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في الخروج من التطبيق؟',
          style: GoogleFonts.tajawal(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
          textAlign: TextAlign.right,
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white70 : Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.lightBlueAccent : Colors.lightBlueAccent[700],
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'خروج',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  ) ?? false;
}

// إضافة رابط لشاشة البداية مع تنبيه الخروج
class ExitConfirmationWrapper extends StatelessWidget {
  final Widget child;

  const ExitConfirmationWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // عرض تنبيه تأكيد الخروج
        return await showExitConfirmationDialog(context);
      },
      child: child,
    );
  }
}

Future<void> main() async {
  if (kReleaseMode) {
    // Initialize Sentry only in release mode
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.sendDefaultPii = true;
        options.release = 'elsahm-app@1.0.0';
        options.environment = 'production';
        options.tracesSampleRate = 0.5;
        options.debug = false;
      },
      appRunner: () => _initializeApp(),
    );
  } else {
    // In debug mode, run without Sentry
    await _initializeApp();
  }
}

Future<void> _initializeApp() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // ضبط توجيه الشاشة للوضع العمودي فقط للتقليل من استهلاك الموارد
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // تهيئة Firebase بشكل متزامن قبل تشغيل التطبيق
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _logger.info('Firebase initialized successfully');

        // Initialize OneSignal
        await _initializeOneSignal();
      } catch (e) {
        _logger.severe('Firebase initialization error: $e');
        if (kReleaseMode) {
          await Sentry.captureException(e);
        }
      }

      // تهيئة بيانات اللغة العربية للتواريخ
      await initializeDateFormatting('ar', null);

      try {
        // تشغيل التطبيق بعد تهيئة Firebase
        runApp(const MyApp());

        // تهيئة Supabase بشكل غير متزامن بعد عرض واجهة المستخدم
        _initializeSupabase();

        // Initialize the notification service
        await NotificationService().initialize();
      } catch (e, stackTrace) {
        // في حالة حدوث خطأ أثناء التهيئة، عرض شاشة خطأ
        _logger.severe('خطأ أثناء تهيئة التطبيق: $e');
        _logger.severe('التفاصيل التقنية: $stackTrace');

        // Send the error to Sentry in release mode
        if (kReleaseMode) {
          await Sentry.captureException(e, stackTrace: stackTrace);
        }

        // تشغيل تطبيق في وضع الطوارئ (آمن)
        runApp(
          ErrorApp(
            errorMessage: e.toString(),
            isConnectionError: e is TimeoutException,
          ),
        );
      }
    },
    (error, stack) {
      // إلتقاط أي استثناءات غير معالجة في التطبيق
      _logger.severe('خطأ غير متوقع: $error');
      _logger.severe('التفاصيل التقنية: $stack');

      // Send the error to Sentry in release mode
      if (kReleaseMode) {
        Sentry.captureException(error, stackTrace: stack);
      }
    },
  );
}

// تهيئة OneSignal بشكل غير متزامن
Future<void> _initializeOneSignal() async {
  try {
    // تهيئة OneSignal مع مستوى سجل مفصل للتصحيح
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // تكوين OneSignal
    OneSignal.initialize(oneSignalAppId);

    // إضافة مستمع لحالة السماح بالإشعارات (تشخيص)
    final permission = OneSignal.Notifications.permission;
    _logger.info('OneSignal Notification permission status: $permission');

    // طلب إذن الإشعارات من المستخدم بشكل صريح
    bool allowed = await OneSignal.Notifications.requestPermission(true);
    _logger.info('OneSignal permission was granted: $allowed');

    // تمكين الإشعارات في المقدمة بشكل صريح
    OneSignal.Notifications.clearAll();

    // طباعة معرف الجهاز للتشخيص
    final deviceState = OneSignal.User.pushSubscription;
    _logger.info('OneSignal Device ID: ${deviceState.id}');
    _logger.info('OneSignal Device Token: ${deviceState.token}');
    _logger.info('OneSignal Device Opted In: ${deviceState.optedIn}');

    // إعداد معالج للإشعارات عند فتحها
    OneSignal.Notifications.addClickListener((event) {
      _oneSignalLogger.info('NOTIFICATION OPENED HANDLER CALLED');
      _oneSignalLogger.info('Notification title: ${event.notification.title}');
      _oneSignalLogger.info('Notification body: ${event.notification.body}');

      // التحقق من وجود بيانات إضافية في الإشعار
      Map<String, dynamic>? additionalData = event.notification.additionalData;

      if (additionalData != null) {
        _oneSignalLogger.info('Additional Data: $additionalData');

        // التعامل مع أنواع مختلفة من الإشعارات
        String? type = additionalData['type'];

        if (type == 'wallet') {
          // الانتقال إلى شاشة المحفظة
          navigatorKey.currentState?.pushNamed('/wallet');
        } else if (type == 'reservation') {
          // الانتقال إلى تفاصيل الحجز
          String? requestId = additionalData['requestId'];
          if (requestId != null) {
            navigatorKey.currentState?.pushNamed(
              '/booking-details',
              arguments: requestId,
            );
          }
        }
      }
    });

    // إعداد معالج للإشعارات عند استلامها (وهي في المقدمة)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      _oneSignalLogger.info('NOTIFICATION RECEIVED IN FOREGROUND');
      _oneSignalLogger.info(
        'Notification ID: ${event.notification.notificationId}',
      );
      _oneSignalLogger.info('Notification title: ${event.notification.title}');
      _oneSignalLogger.info('Notification body: ${event.notification.body}');

      // احتفظ بالإشعار واعرضه
      event.preventDefault();
      event.notification.display();
    });

    _logger.info('OneSignal initialized successfully');
  } catch (e) {
    _logger.severe('Error initializing OneSignal: $e');
    // Send OneSignal initialization errors to Sentry in release mode
    if (kReleaseMode) {
      Sentry.captureException(e);
    }
  }
}

// إضافة دالة لربط معرف المستخدم بعد تسجيل الدخول (يُستدعى من AuthProvider)
Future<void> setOneSignalExternalUserId(String userId) async {
  try {
    // تطهير معرف المستخدم
    final cleanUserId = userId.trim();

    // ربط معرف المستخدم
    await OneSignal.login(cleanUserId);
    _logger.info('OneSignal login with user ID: $cleanUserId');

    // إضافة علامة (tag) لمعرف المستخدم للاستهداف المخصص
    await OneSignal.User.addTags({
      'user_id': cleanUserId,
      'auth_time': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    // طباعة المعلومات للتشخيص
    final tags = await OneSignal.User.getTags();
    _logger.info('OneSignal tags after login: $tags');

    // حفظ المعرف في Shared Preferences للاستخدام المستقبلي
    final pushStatus = OneSignal.User.pushSubscription;
    _logger.info('OneSignal Device ID: ${pushStatus.id}');
    _logger.info('OneSignal Device Token: ${pushStatus.token}');
    _logger.info('OneSignal user ID set: $cleanUserId');
    
    // Set user identifier in Sentry in release mode
    if (kReleaseMode) {
      Sentry.configureScope((scope) {
        scope.setUser(SentryUser(id: cleanUserId));
      });
      _logger.info('Sentry user ID set: $cleanUserId');
    }
  } catch (e) {
    _logger.severe('Error setting OneSignal user ID: $e');
    if (kReleaseMode) {
      Sentry.captureException(e);
    }
  }
}

// إضافة دالة لإزالة ربط معرف المستخدم عند تسجيل الخروج (يُستدعى من AuthProvider)
Future<void> removeOneSignalExternalUserId() async {
  try {
    // إزالة ربط معرف المستخدم
    OneSignal.logout();

    // حذف علامة (tag) معرف المستخدم
    OneSignal.User.removeTags(['user_id']);

    _logger.info('OneSignal user ID removed');
    
    // Clear user identifier in Sentry in release mode
    if (kReleaseMode) {
      Sentry.configureScope((scope) {
        scope.setUser(null);
      });
      _logger.info('Sentry user ID cleared');
    }
  } catch (e) {
    _logger.severe('Error removing OneSignal user ID: $e');
    if (kReleaseMode) {
      Sentry.captureException(e);
    }
  }
}

// تهيئة Supabase بشكل غير متزامن
Future<void> _initializeSupabase() async {
  try {
    // تهيئة Supabase بشكل غير متزامن مع مهلة زمنية
    try {
      await Supabase.initialize(
        url: 'https://cxntsoxkldjoblehmdpo.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4bnRzb3hrbGRqb2JsZWhtZHBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU3MDA1MDMsImV4cCI6MjA2MTI3NjUwM30.XEuVHmJrWNX1XYphBZKpwyZqRf_HMsNg6IMJLiIu-ks',
      ).timeout(
        connectionTimeout,
        onTimeout: () {
          _logger.warning(
            'تجاوزت مهلة الاتصال مع Supabase، سيتم إعادة المحاولة لاحقاً',
          );
          throw TimeoutException('تجاوز الوقت');
        },
      );
    } catch (e) {
      _logger.severe('خطأ في تهيئة Supabase: $e');
      // المتابعة حتى مع وجود خطأ
    }

    // تم الانتهاء من التهيئة بنجاح
    isInitialized = true;
  } catch (e) {
    _logger.severe('حدث خطأ أثناء تهيئة الخدمات: $e');
    // ليس ضرورياً إيقاف التطبيق، سيستمر بدون اتصال وتظهر رسالة خطأ عند محاولة استخدام الخدمات
  }
}

// تطبيق الخطأ (في وضع الطوارئ)
class ErrorApp extends StatelessWidget {
  final String errorMessage;
  final bool isConnectionError;

  const ErrorApp({
    super.key,
    required this.errorMessage,
    this.isConnectionError = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'السهم للتسكين - وضع الطوارئ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Tajawal',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlueAccent,
          primary: Colors.lightBlueAccent[700],
        ),
      ),
      home: ErrorScreen(
        errorMessage: errorMessage,
        isConnectionError: isConnectionError,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the entire app with MultiProvider
    return MultiProvider(
      providers: [
        // Register AuthProvider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Register ThemeProvider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Register NavigationProvider
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        // Register CategoryProvider
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        // Register FavoritesProvider
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      // Use Consumer to rebuild MaterialApp when theme changes
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Define Dark Theme Data
          final darkTheme = ThemeData(
            fontFamily: GoogleFonts.tajawal().fontFamily, // Apply Tajawal font
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Updated dark background
            cardColor: const Color(0xFF2D2D2D), // Updated dark card color
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightBlueAccent,
              brightness: Brightness.dark,
              primary: const Color(0xFF1976D2), // Updated primary color for dark theme
              secondary: const Color(0xFF42A5F5),
              surface: const Color(0xFF252525), // Added surface color
              background: const Color(0xFF1A1A1A),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF252525), // Updated app bar color
              elevation: 0, // Ensure no elevation in dark mode
              titleTextStyle: GoogleFonts.tajawal(
                // Apply Tajawal font
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            textTheme: GoogleFonts.tajawalTextTheme(
              ThemeData.dark().textTheme,
            ).copyWith(
              // Apply Tajawal font
              bodyLarge: const TextStyle(color: Color(0xFFE0E0E0)), // Updated text color
              bodyMedium: const TextStyle(color: Color(0xFFB0B0B0)), // Updated secondary text color
              titleLarge: const TextStyle(color: Color(0xFFE0E0E0)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2D2D2D), // Updated input field color
              hintStyle: TextStyle(color: Colors.grey[500]),
              labelStyle: const TextStyle(color: Color(0xFF81D4FA)), // Updated label color
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Color(0xFF29B6F6)), // Updated border color
              ),
              prefixIconColor: const Color(0xFF81D4FA), // Updated icon color
              suffixIconColor: const Color(0xFF81D4FA), // Updated icon color
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2), // Updated button color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                textStyle: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                ), // Apply Tajawal font
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              // Add style for outlined buttons
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF29B6F6), // Updated button text color
                side: const BorderSide(color: Color(0xFF29B6F6)), // Updated button border color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                ), // Apply Tajawal font
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: const Color(0xFF252525), // Updated navigation bar color
              selectedItemColor: const Color(0xFF29B6F6), // Updated selected item color
              unselectedItemColor: Colors.grey[600],
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              elevation: 0,
            ),
            chipTheme: ChipThemeData(
              // Style for chips
              backgroundColor: const Color(0xFF2D2D2D), // Updated chip background color
              labelStyle: GoogleFonts.tajawal(color: Colors.white),
              selectedColor: const Color(0xFF29B6F6), // Updated selected chip color
              secondarySelectedColor:
                  const Color(0xFF29B6F6), // Ensure consistency
              checkmarkColor: Colors.black,
              shape: StadiumBorder(side: BorderSide(color: const Color(0xFF3D3D3D))), // Updated border color
            ),
          );

          // Define Light Theme Data
          final lightTheme = ThemeData(
            fontFamily: GoogleFonts.tajawal().fontFamily, // Apply Tajawal font
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[100], // Light background
            cardColor: Colors.white, // White cards
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightBlueAccent,
              brightness: Brightness.light,
              primary:
                  Colors.lightBlueAccent[700]!, // Darker accent for light theme
              secondary: Colors.lightBlueAccent,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white, // White app bar
              elevation: 0, // Remove elevation in light mode too
              titleTextStyle: GoogleFonts.tajawal(
                // Apply Tajawal font
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.grey[800]),
            ),
            textTheme: GoogleFonts.tajawalTextTheme(
              ThemeData.light().textTheme,
            ).copyWith(
              // Apply Tajawal font
              bodyLarge: const TextStyle(color: Colors.black87),
              bodyMedium: TextStyle(color: Colors.grey[700]),
              titleLarge: const TextStyle(color: Colors.black87),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[200],
              hintStyle: TextStyle(color: Colors.grey[500]),
              labelStyle: TextStyle(color: Colors.lightBlueAccent[700]!),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.lightBlueAccent[700]!),
              ),
              prefixIconColor: Colors.grey[600],
              suffixIconColor: Colors.grey[600],
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                textStyle: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                ), // Apply Tajawal font
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              // Add style for outlined buttons
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.lightBlueAccent[700],
                side: BorderSide(color: Colors.lightBlueAccent[700]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                ), // Apply Tajawal font
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.lightBlueAccent[700],
              unselectedItemColor: Colors.grey[500],
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              elevation: 0,
            ),
            chipTheme: ChipThemeData(
              // Style for chips
              backgroundColor: Colors.grey[200],
              labelStyle: GoogleFonts.tajawal(color: Colors.black87),
              selectedColor: Colors.lightBlueAccent[100],
              secondarySelectedColor: Colors.lightBlueAccent[100],
              checkmarkColor: Colors.black,
              shape: StadiumBorder(side: BorderSide(color: Colors.grey[400]!)),
            ),
          );

          return MaterialApp(
            navigatorKey: navigatorKey, // استخدام مفتاح Navigator العام
            title: 'السهم للتسكين',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode, // Use provider state
            theme: lightTheme, // Provide light theme
            darkTheme: darkTheme, // Provide dark theme
            home: const ExitConfirmationWrapper(
              child: SplashScreen(),
            ), // تطبيق ExitConfirmationWrapper فقط على الشاشة الرئيسية
            // تعريف الطرق المسماة (Named Routes)
            routes: {'/login': (context) => const LoginScreen()},
            // Add theme animation duration
            builder: (context, child) {
              return AnimatedTheme(
                data: themeProvider.themeMode == ThemeMode.dark
                    ? darkTheme
                    : lightTheme,
                duration: const Duration(
                  milliseconds: 300,
                ), // Smooth animation duration
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
