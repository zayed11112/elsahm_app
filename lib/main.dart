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
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart'; // Import NavigationProvider
import 'providers/category_provider.dart'; // Import CategoryProvider
import 'providers/favorites_provider.dart'; // Import FavoritesProvider
import 'services/notification_service.dart'; // Import NotificationService
import 'constants/theme.dart'; // Import theme constants
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
// إضافة دالة لعرض مربع حوار الخروج من التطبيق
Future<bool> showExitConfirmationDialog(BuildContext context) async {
  final ThemeData theme = Theme.of(context);
  final bool isDarkMode = theme.brightness == Brightness.dark;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(
                color:
                    isDarkMode
                        ? Colors.lightBlueAccent
                        : Colors.lightBlueAccent[700]!,
                width: 1.5,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color:
                      isDarkMode
                          ? Colors.lightBlueAccent
                          : Colors.lightBlueAccent[700],
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
                        foregroundColor:
                            isDarkMode ? Colors.white70 : Colors.grey[700],
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
                        backgroundColor:
                            isDarkMode
                                ? Colors.lightBlueAccent
                                : Colors.lightBlueAccent[700],
                        foregroundColor:
                            isDarkMode ? Colors.black : Colors.white,
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
      ) ??
      false;
}

// إضافة رابط لشاشة البداية مع تنبيه الخروج
class ExitConfirmationWrapper extends StatelessWidget {
  final Widget child;

  const ExitConfirmationWrapper({super.key, required this.child});

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
  await _initializeApp();
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
  } catch (e) {
    _logger.severe('Error setting OneSignal user ID: $e');
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
  } catch (e) {
    _logger.severe('Error removing OneSignal user ID: $e');
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
          // Define Enhanced Dark Theme Data
          final darkTheme = ThemeData(
            fontFamily: GoogleFonts.tajawal().fontFamily,
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: darkBackground,
            cardColor: darkCard,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryBlue,
              brightness: Brightness.dark,
              primary: primaryBlue,
              secondary: accentBlue,
              surface: darkSurface,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: darkTextPrimary,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: darkSurface,
              elevation: 0,
              titleTextStyle: GoogleFonts.tajawal(
                color: darkTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: darkTextPrimary),
            ),
            textTheme: GoogleFonts.tajawalTextTheme(
              ThemeData.dark().textTheme,
            ).copyWith(
              bodyLarge: TextStyle(color: darkTextPrimary),
              bodyMedium: TextStyle(color: darkTextSecondary),
              titleLarge: TextStyle(color: darkTextPrimary),
              titleMedium: TextStyle(color: darkTextPrimary),
              titleSmall: TextStyle(color: darkTextSecondary),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: darkCard,
              hintStyle: TextStyle(color: darkTextTertiary),
              labelStyle: TextStyle(color: accentBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(color: primaryBlue),
              ),
              prefixIconColor: accentBlue,
              suffixIconColor: accentBlue,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: accentBlue,
                side: BorderSide(color: accentBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: darkSurface,
              selectedItemColor: accentBlue,
              unselectedItemColor: darkTextTertiary,
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              elevation: 0,
            ),
            chipTheme: ChipThemeData(
              backgroundColor: darkCard,
              labelStyle: GoogleFonts.tajawal(color: darkTextPrimary),
              selectedColor: accentBlue,
              secondarySelectedColor: accentBlue,
              checkmarkColor: Colors.white,
              shape: StadiumBorder(side: BorderSide(color: darkTextTertiary)),
            ),
          );

          // Define Enhanced Light Theme Data
          final lightTheme = ThemeData(
            fontFamily: GoogleFonts.tajawal().fontFamily,
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: lightBackground,
            cardColor: lightCard,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryBlue,
              brightness: Brightness.light,
              primary: primaryBlue,
              secondary: accentBlue,
              surface: lightSurface,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: lightTextPrimary,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: lightSurface,
              elevation: 0,
              titleTextStyle: GoogleFonts.tajawal(
                color: lightTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: lightTextPrimary),
            ),
            textTheme: GoogleFonts.tajawalTextTheme(
              ThemeData.light().textTheme,
            ).copyWith(
              bodyLarge: TextStyle(color: lightTextPrimary),
              bodyMedium: TextStyle(color: lightTextSecondary),
              titleLarge: TextStyle(color: lightTextPrimary),
              titleMedium: TextStyle(color: lightTextPrimary),
              titleSmall: TextStyle(color: lightTextSecondary),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: lightElevated,
              hintStyle: TextStyle(color: lightTextTertiary),
              labelStyle: TextStyle(color: primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(color: primaryBlue),
              ),
              prefixIconColor: lightTextSecondary,
              suffixIconColor: lightTextSecondary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: BorderSide(color: primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: lightSurface,
              selectedItemColor: primaryBlue,
              unselectedItemColor: lightTextTertiary,
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              elevation: 0,
            ),
            chipTheme: ChipThemeData(
              backgroundColor: lightElevated,
              labelStyle: GoogleFonts.tajawal(color: lightTextPrimary),
              selectedColor: primaryBlueLight,
              secondarySelectedColor: primaryBlueLight,
              checkmarkColor: Colors.white,
              shape: StadiumBorder(side: BorderSide(color: lightTextTertiary)),
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
                data:
                    themeProvider.themeMode == ThemeMode.dark
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
