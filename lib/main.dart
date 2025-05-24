import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
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

// OneSignal App ID
const String ONESIGNAL_APP_ID = '3136dbc6-c09c-4bca-b0aa-fe35421ac513';

// تمت إزالة _firebaseMessagingBackgroundHandler لأنه لم يعد مطلوباً مع OneSignal

Future<void> main() async {
  // التقاط أي أخطاء غير متوقعة في التطبيق
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
        print('Firebase initialized successfully');
        
        // Initialize OneSignal
        await _initializeOneSignal();
      } catch (e) {
        print('Firebase initialization error: $e');
      }

      // تهيئة بيانات اللغة العربية للتواريخ
      await initializeDateFormatting('ar', null);

      // Enable debug prints for widget rebuilds (to diagnose issues)
      // debugPrintRebuildDirtyWidgets = true; // تعطيل هذا يقلل من الضغط على الخيط الرئيسي

      try {
        // تشغيل التطبيق بعد تهيئة Firebase
        runApp(const MyApp());

        // تهيئة Supabase بشكل غير متزامن بعد عرض واجهة المستخدم
        _initializeSupabase();
        
        // Initialize the notification service
        await NotificationService().initialize();
      } catch (e, stackTrace) {
        // في حالة حدوث خطأ أثناء التهيئة، عرض شاشة خطأ
        print('خطأ أثناء تهيئة التطبيق: $e');
        print('التفاصيل التقنية: $stackTrace');

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
      print('خطأ غير متوقع: $error');
      print('التفاصيل التقنية: $stack');
    },
  );
}

// تهيئة OneSignal
Future<void> _initializeOneSignal() async {
  try {
    // تهيئة OneSignal مع مستوى سجل مفصل للتصحيح
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    
    // تكوين OneSignal
    OneSignal.initialize(ONESIGNAL_APP_ID);

    // إضافة مستمع لحالة السماح بالإشعارات (تشخيص)
    final permission = await OneSignal.Notifications.permission;
    print('OneSignal Notification permission status: $permission');
    
    // طلب إذن الإشعارات من المستخدم بشكل صريح
    bool allowed = await OneSignal.Notifications.requestPermission(true);
    print('OneSignal permission was granted: $allowed');
    
    // تمكين الإشعارات في المقدمة بشكل صريح
    OneSignal.Notifications.clearAll();
    
    // طباعة معرف الجهاز للتشخيص
    final deviceState = await OneSignal.User.pushSubscription;
    print('OneSignal Device ID: ${deviceState.id}');
    print('OneSignal Device Token: ${deviceState.token}');
    print('OneSignal Device Opted In: ${deviceState.optedIn}');
    
    // إعداد معالج للإشعارات عند فتحها
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION OPENED HANDLER CALLED');
      print('Notification title: ${event.notification.title}');
      print('Notification body: ${event.notification.body}');
      
      // التحقق من وجود بيانات إضافية في الإشعار
      Map<String, dynamic>? additionalData = event.notification.additionalData;
      
      if (additionalData != null) {
        print('Additional Data: $additionalData');
        
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
      print('NOTIFICATION RECEIVED IN FOREGROUND');
      print('Notification ID: ${event.notification.notificationId}');
      print('Notification title: ${event.notification.title}');
      print('Notification body: ${event.notification.body}');
      
      // احتفظ بالإشعار واعرضه
      event.preventDefault();
      event.notification.display();
    });
    
    print('OneSignal initialized successfully');
  } catch (e) {
    print('Error initializing OneSignal: $e');
  }
}

// إضافة دالة لربط معرف المستخدم بعد تسجيل الدخول (يُستدعى من AuthProvider)
Future<void> setOneSignalExternalUserId(String userId) async {
  try {
    // تطهير معرف المستخدم
    final cleanUserId = userId.trim();
    
    // ربط معرف المستخدم
    await OneSignal.login(cleanUserId);
    print('OneSignal login with user ID: $cleanUserId');
    
    // إضافة علامة (tag) لمعرف المستخدم للاستهداف المخصص
    await OneSignal.User.addTags({
      'user_id': cleanUserId,
      'auth_time': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    
    // طباعة المعلومات للتشخيص
    final tags = await OneSignal.User.getTags();
    print('OneSignal tags after login: $tags');
    
    // حفظ المعرف في Shared Preferences للاستخدام المستقبلي
    final pushStatus = await OneSignal.User.pushSubscription;
    print('OneSignal Device ID: ${pushStatus.id}');
    print('OneSignal Device Token: ${pushStatus.token}');
    print('OneSignal user ID set: $cleanUserId');
  } catch (e) {
    print('Error setting OneSignal user ID: $e');
  }
}

// إضافة دالة لإزالة ربط معرف المستخدم عند تسجيل الخروج (يُستدعى من AuthProvider)
Future<void> removeOneSignalExternalUserId() async {
  try {
    // إزالة ربط معرف المستخدم
    OneSignal.logout();
    
    // حذف علامة (tag) معرف المستخدم
    OneSignal.User.removeTags(['user_id']);
    
    print('OneSignal user ID removed');
  } catch (e) {
    print('Error removing OneSignal user ID: $e');
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
          print('تجاوزت مهلة الاتصال مع Supabase، سيتم إعادة المحاولة لاحقاً');
          throw TimeoutException('تجاوز الوقت');
        },
      );
    } catch (e) {
      print('خطأ في تهيئة Supabase: $e');
      // المتابعة حتى مع وجود خطأ
    }

    // تم الانتهاء من التهيئة بنجاح
    isInitialized = true;
  } catch (e) {
    print('حدث خطأ أثناء تهيئة الخدمات: $e');
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
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightBlueAccent,
              brightness: Brightness.dark,
              primary: Colors.lightBlueAccent,
              secondary: Colors.lightBlueAccent[100]!,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF1E1E1E),
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
              bodyLarge: const TextStyle(color: Colors.white),
              bodyMedium: const TextStyle(color: Colors.white70),
              titleLarge: const TextStyle(color: Colors.white),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[800],
              hintStyle: TextStyle(color: Colors.grey[500]),
              labelStyle: const TextStyle(color: Colors.lightBlueAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.lightBlueAccent),
              ),
              prefixIconColor: Colors.grey[400],
              suffixIconColor: Colors.grey[400],
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.black,
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
                foregroundColor: Colors.lightBlueAccent,
                side: const BorderSide(color: Colors.lightBlueAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                ), // Apply Tajawal font
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              selectedItemColor: Colors.lightBlueAccent,
              unselectedItemColor: Colors.grey[600],
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              elevation: 0,
            ),
            chipTheme: ChipThemeData(
              // Style for chips
              backgroundColor: Colors.grey[800],
              labelStyle: GoogleFonts.tajawal(color: Colors.white),
              selectedColor: Colors.lightBlueAccent,
              secondarySelectedColor:
                  Colors.lightBlueAccent, // Ensure consistency
              checkmarkColor: Colors.black,
              shape: StadiumBorder(side: BorderSide(color: Colors.grey[700]!)),
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
            home: const SplashScreen(), // استخدام شاشة البداية مباشرة
            // تعريف الطرق المسماة (Named Routes)
            routes: {'/login': (context) => const LoginScreen()},
            // Add theme animation duration
            builder: (context, child) {
              return AnimatedTheme(
                data: themeProvider.themeMode == ThemeMode.dark 
                    ? darkTheme 
                    : lightTheme,
                duration: const Duration(milliseconds: 300), // Smooth animation duration
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
