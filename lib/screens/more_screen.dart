import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'wallet_screen.dart';
import 'change_password_screen.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'favorites_screen.dart';
import 'contact_us_screen.dart';
import 'why_choose_us_screen.dart';
import 'categories_screen.dart';
import 'payment_requests_screen.dart';
import 'groups_screen.dart'; // استيراد صفحة الجروبات الجديدة
import 'notifications_screen.dart'; // استيراد صفحة الإشعارات الجديدة
import 'complaints_screen.dart'; // استيراد صفحة الشكاوى الجديدة
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/notification_service.dart'; // استيراد خدمة الإشعارات
import '../screens/settings_screen.dart'; // استيراد صفحة الإعدادات
import 'booking_requests_screen.dart'; // استيراد صفحة طلبات الحجز
//  Import other necessary screens when created (e.g., Prescriptions, Purchases)

// تعريف الألوان الجديدة المستخدمة في الشاشة
const Color primarySkyBlue = Color(0xFF4FC3F7); // لون أزرق سماوي
const Color darkHeaderColor = Color(0xFF1A2025); // لون الهيدر الداكن
const Color lightBackgroundColor = Color(0xFFF5F7FA); // خلفية رمادية فاتحة
const Color darkBackgroundColor = Color(0xFF121212); // خلفية داكنة
const Color darkCardColor = Color(0xFF2C3E50); // لون البطاقة/الزر الداكن
const Color lightBlue = Color(0xFF81D4FA); // لون أزرق فاتح للمسات إضافية
const Color accentBlue = Color(0xFF29B6F6); // لون أزرق للتأكيد
const Color gradientStart = Color(0xFF2196F3); // بداية التدرج
const Color gradientEnd = Color(0xFF4FC3F7); // نهاية التدرج
const Color goldColor = Color(0xFFFFD700); // لون ذهبي للعناصر المميزة

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final Logger _logger = Logger('MoreScreen');
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService(); // إضافة خدمة الإشعارات
  UserProfile? userProfile;
  bool isLoading = false;
  int unreadNotificationsCount = 0; // إضافة متغير لتخزين عدد الإشعارات غير المقروءة
  StreamSubscription? _notificationCountSubscription; // إضافة متغير للاشتراك


  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        userProfile = await _firestoreService.getUserProfile(
          authProvider.user!.uid,
        );
      }
    } catch (error) {
      _logger.warning('Error loading profile: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkForUnreadNotifications(); // استدعاء دالة فحص الإشعارات غير المقروءة
  }

  @override
  void dispose() {
    // إلغاء الاشتراك في تدفق الإشعارات عند إغلاق الشاشة
    _notificationCountSubscription?.cancel();
    super.dispose();
  }

  // إضافة دالة للتحقق من وجود إشعارات غير مقروءة
  void _checkForUnreadNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      try {
        // إلغاء الاشتراك السابق إن وجد
        _notificationCountSubscription?.cancel();
        
        // الاستماع لتغييرات عدد الإشعارات غير المقروءة
        _notificationCountSubscription = _notificationService
            .getUnreadNotificationsCount(authProvider.user!.uid)
            .listen((count) {
          if (mounted) {  // التحقق من وجود الـ widget قبل تحديث الحالة
            setState(() {
              unreadNotificationsCount = count;
            });
          }
        }, onError: (error) {
          // التعامل مع الأخطاء
          _logger.warning('خطأ في تحميل عدد الإشعارات: $error');
          if (mounted) {
            setState(() {
              unreadNotificationsCount = 0;
            });
          }
        });
      } catch (e) {
        _logger.severe('استثناء في عداد الإشعارات: $e');
        if (mounted) {
          setState(() {
            unreadNotificationsCount = 0;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeProvider changes for locale updates
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    // تحديد الألوان بناءً على السمة والصورة
    final Color screenBgColor =
        isDarkMode ? darkBackgroundColor : lightBackgroundColor;
    final Color cardBgColor = isDarkMode ? darkCardColor : Colors.white;
    final Color cardTextColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color blueButtonColor = accentBlue; // استخدام اللون الأزرق للزر

    // تعريف تدرج لوني للهيدر
    final Gradient headerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [gradientStart, gradientEnd],
    );

    // الحصول على معرف المستخدم الحالي
    final String? userId = authProvider.user?.uid;

    return Scaffold(
      backgroundColor: screenBgColor,
      body:
          userId == null
              ? _buildLoginPrompt(context) // Show login prompt if not logged in
              : StreamBuilder<UserProfile?>(
                stream: _firestoreService.getUserProfileStream(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primarySkyBlue),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("خطأ: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(
                      child: Text("لم يتم العثور على الملف الشخصي."),
                    );
                  }

                  final userProfile = snapshot.data!;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeaderAndProfile(
                          context,
                          headerGradient,
                          userProfile,
                        ),
                        const SizedBox(
                          height: 40, // Increased space to move details down
                        ), // Space below header elements (profile pic etc.)
                        _buildUserDetailsSection(
                          context,
                          userProfile,
                          cardBgColor,
                          cardTextColor,
                        ), // Add the new details section
                        const SizedBox(height: 15),
                        _buildEditProfileButton(
                          context,
                          blueButtonColor,
                          userProfile,
                        ),
                        const SizedBox(height: 25), // Space below edit button
                        _buildMainWallet(context, cardBgColor, cardTextColor),
                        const SizedBox(height: 15),
                        _buildActionGrid(
                          context,
                          cardBgColor,
                          cardTextColor,
                          primarySkyBlue,
                        ),
                      ],
                    ), // Closes Column
                  ); // Closes SingleChildScrollView return from builder
                }, // Closes StreamBuilder builder
              ), // Closes StreamBuilder
    ); // Closes Scaffold
  } // Closes build method

  // قسم الهيدر والملف الشخصي المجمعين - تصميم جديد
  Widget _buildHeaderAndProfile(
    BuildContext context,
    Gradient headerGradient,
    UserProfile userProfile,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double profileImageSize = 90.0;

    // استخراج البيانات من ملف المستخدم
    final String displayName =
        userProfile.name.isNotEmpty
            ? userProfile.name
            : userProfile.email.isNotEmpty
            ? userProfile.email
            : 'مستخدم';
    final String profileImageUrl = userProfile.avatarUrl;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // الخلفية المنحنية مع تدرج لوني
        ClipPath(
          clipper: HeaderCurveClipper(curveDepth: 65.0), // تعديل عمق المنحنى
          child: Container(
            height: 200, // زيادة ارتفاع الهيدر
            decoration: BoxDecoration(gradient: headerGradient),
            child: Stack(
              children: [
                // زخارف متحركة في الخلفية
                Positioned.fill(
                  child: CustomPaint(painter: HeaderPatternPainter()),
                ),

                // دوائر زخرفية متوهجة
                Positioned(
                  top: -30,
                  left: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withAlpha(15),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(20),
                    ),
                  ),
                ),

                // نص الترحيب بالمستخدم مع تأثيرات
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // تأثير توهج خلف النص
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [Colors.white, Colors.white.withAlpha(200)],
                            tileMode: TileMode.mirror,
                          ).createShader(bounds);
                        },
                        child: Text(
                          "أهلاً بك", // تحسين النص
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // اسم المستخدم بخط أكبر وتأثير ظل
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(100),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // صورة الملف الشخصي والأيقونات (موضوعة أسفل منحنى الرأس)
        Positioned(
          top: 130,
          child: SizedBox(
            width: screenWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // أيقونة الشكاوى
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact(); // إضافة اهتزاز خفيف عند النقر
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ComplaintsScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.contact_support_outlined, // تغيير الأيقونة إلى أيقونة شكاوى مناسبة
                      size: 30,
                      color: accentBlue,
                    ),
                  ),
                ),
                // صورة الملف الشخصي - تبسيط العرض
                Column(
                  children: [
                    GestureDetector(
                      onTap:
                          isLoading
                              ? null
                              : () =>
                                  _viewProfileImage(context, profileImageUrl),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width:
                                profileImageSize + 16, // Add padding for frame
                            height: profileImageSize + 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                12.0,
                              ), // Slight rounding
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(3.0), // Inner padding
                            child: Hero(
                              tag: 'profileImage',
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    8.0,
                                  ), // Match with outer border radius
                                  color: Colors.grey.shade100,
                                  image:
                                      profileImageUrl.isNotEmpty
                                          ? DecorationImage(
                                            image: NetworkImage(
                                              profileImageUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                          : null,
                                ),
                                child:
                                    profileImageUrl.isEmpty
                                        ? Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 45,
                                            color: accentBlue.withValues(alpha: 0.8),
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                          ),
                          // Loading indicator overlay
                          if (isLoading)
                            Container(
                              width: profileImageSize + 16,
                              height: profileImageSize + 16,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // أيقونة الإشعارات - تعديل لإضافة وظيفة النقر لفتح صفحة الإشعارات
                GestureDetector(
                  onTap: () {
                    // إضافة اهتزاز خفيف عند النقر
                    HapticFeedback.lightImpact();
                    // الانتقال إلى صفحة الإشعارات
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()
                      ),
                    ).then((_) {
                      // تحديث عدد الإشعارات بعد العودة من صفحة الإشعارات
                      _checkForUnreadNotifications();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 30,
                          color: accentBlue,
                        ),
                        // عرض مؤشر للإشعارات غير المقروءة
                        if (unreadNotificationsCount > 0)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 2,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: unreadNotificationsCount > 9
                                  ? const Text(
                                      "9+",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  : unreadNotificationsCount > 0
                                      ? Text(
                                          unreadNotificationsCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        )
                                      : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // New separate method for the Edit Profile Button
  Widget _buildEditProfileButton(
    BuildContext context,
    Color blueButtonColor,
    UserProfile userProfile,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(
            top: 20,
          ), // Add margin to position below the Stack elements
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: accentBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              _logger.info("Edit Profile button pressed!");
              _logger.info("User Profile to pass: ${userProfile.uid}");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(userProfile: userProfile),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: blueButtonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 12),
            ),
            child: const Text(
              "تعديل بياناتي", 
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // إضافة نص توضيحي تحت الزر
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "انقر على الزر لتتمكن من تغيير البيانات",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // Helper for displaying detail items within the header (REMOVED - no longer used)
  // Widget _buildHeaderDetailItem(...) { ... }

  // New section for user details with improved formatting
  Widget _buildUserDetailsSection(
    BuildContext context,
    UserProfile userProfile,
    Color cardBgColor,
    Color cardTextColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final detailIconColor =
        isDarkMode ? primarySkyBlue.withValues(alpha: 0.8) : primarySkyBlue;
    final detailLabelColor = isDarkMode ? Colors.white70 : Colors.grey[600];
    final detailValueColor = cardTextColor;

    // Helper to create each detail item row
    Widget buildDetailItem(IconData icon, String label, String value) {
      final displayValue =
          value.isNotEmpty ? value : "غير محدد"; 
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 6.0,
        ), // Spacing between items
        child: Row(
          children: [
            Icon(icon, size: 20, color: detailIconColor),
            const SizedBox(width: 12),
            Text(
              "$label:", // Localize this label
              style: TextStyle(
                fontSize: 13,
                color: detailLabelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  color: detailValueColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right, // Align value to the right
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30.0),
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDetailItem(
            Icons.verified_user_outlined,
            "الحالة", //  Localize
            userProfile.status,
          ),
          Divider(
            color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
          buildDetailItem(
            Icons.badge_outlined,
            "ID   ّ", //  Localize
            userProfile.studentId,
          ),
          Divider(
            color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
          buildDetailItem(
            Icons.school_outlined,
            "الكلية", //  Localize
            userProfile.faculty,
          ),
          Divider(
            color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
          buildDetailItem(
            Icons.location_city_outlined,
            "الفرع", 
            userProfile.branch,
          ),
        ],
      ),
    );
  }

  // تم تغيير هذه الدالة لعرض المحفظة الرئيسية فقط
  Widget _buildMainWallet(
    BuildContext context,
    Color cardBgColor,
    Color textColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final walletCardBg =
        isDarkMode ? darkCardColor.withValues(alpha: 0.7) : Colors.white;
    final walletTextColor = isDarkMode ? Colors.white70 : Colors.black87;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // استخدام الرصيد الفعلي للمستخدم بدلاً من القيمة الثابتة
    String currentBalance = "0"; // قيمة افتراضية

    // الوصول إلى FirestoreService للحصول على بيانات المستخدم
    final firestoreService = FirestoreService();

    // الحصول على معرف المستخدم الحالي وتنفيذ FutureBuilder للحصول على بيانات المستخدم
    final userId = authProvider.user?.uid;

    return FutureBuilder<UserProfile?>(
      future: userId != null ? firestoreService.getUserProfile(userId) : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // عرض مؤشر التحميل أثناء جلب البيانات
          currentBalance = "...";
        } else if (snapshot.hasData && snapshot.data != null) {
          final userProfile = snapshot.data!;
          // تنسيق الرصيد للعرض
          if (userProfile.balance == userProfile.balance.toInt()) {
            // إذا كان الرصيد عدد صحيح نعرضه بدون كسور
            currentBalance = userProfile.balance.toInt().toString();
          } else {
            // إذا كان الرصيد به كسور نعرضه مع تقريب لرقمين عشريين
            currentBalance = userProfile.balance.toStringAsFixed(2);
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 22.0,
              horizontal: 16.0,
            ),
            decoration: BoxDecoration(
              color: walletCardBg,
              borderRadius: BorderRadius.circular(18.0),
              boxShadow: [
                if (Theme.of(context).brightness == Brightness.light)
                  BoxShadow(
                    color: primarySkyBlue.withValues(alpha: 0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
              ],
              border: Border.all(
                color: primarySkyBlue.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "المحفظة الاساسية", 
                      style: TextStyle(
                        color: walletTextColor.withValues(alpha: 0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.account_balance_wallet,
                      color: primarySkyBlue,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "جنيه", // Localize currency
                      style: TextStyle(
                        color: walletTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentBalance,
                      style: TextStyle(
                        color: primarySkyBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionGrid(
    BuildContext context,
    Color buttonColor,
    Color textColor,
    Color highlightColor,
  ) {

    // قائمة الإجراءات المتاحة
    final List<Map<String, dynamic>> actions = [
      {'icon': Icons.wallet, 'text': 'شحن محفظتي', 'highlight': true},
      {'icon': Icons.favorite, 'text': 'المفضلة', 'highlight': false},
      {'icon': Icons.place, 'text': 'الاماكن المتاحة', 'highlight': false},
      {'icon': Icons.category, 'text': ' الاقسام', 'highlight': false},
      {'icon': Icons.support_agent, 'text': 'الشكاوى', 'highlight': false},
      {'icon': Icons.request_page, 'text': 'طلبات الدفع', 'highlight': false},
      {'icon': Icons.bookmark_outlined, 'text': 'طلبات الحجز', 'highlight': false},
      {'icon': Icons.groups, 'text': 'جروبات', 'highlight': false},
      {'icon': Icons.settings, 'text': 'الإعدادات', 'highlight': false},
      {'icon': Icons.info, 'text': 'عن السهم', 'highlight': false},
      {'icon': Icons.key, 'text': 'تغير كلمة المرور', 'highlight': false},
      {'icon': Icons.phone_outlined, 'text': 'اتصل بنا', 'highlight': false},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 2.6,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              final bool isHighlighted = action['highlight'] as bool;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    if (isHighlighted)
                      BoxShadow(
                        color: primarySkyBlue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    else if (Theme.of(context).brightness == Brightness.light)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: _buildActionButton(
                  context,
                  action['icon'] as IconData,
                  action['text'] as String,
                  isHighlighted ? primarySkyBlue : buttonColor,
                  isHighlighted ? Colors.white : textColor,
                  isHighlighted,
                ),
              );
            },
          ),
          
          // Add special logout button that takes full width
          const SizedBox(height: 25),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  // ويدجت مساعد لإنشاء كل زر إجراء
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String text, // This is the original text key (e.g., 'English', 'خروج')
    Color bgColor,
    Color contentColor,
    bool isHighlighted,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Remove ThemeProvider reference for localization

    return ElevatedButton(
      onPressed: () async {
        // تنفيذ الإجراء لكل زر
        _logger.info("تم النقر على: $text"); // Log original key

        // Use the original 'text' key for logic comparison
        if (text == 'المفضلة') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavoritesScreen()),
          );
        } else if (text == 'اتصل بنا') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactUsScreen()),
          );
        } else if (text == 'عن السهم') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WhyChooseUsScreen(),
            ), // Or a dedicated About screen
          );
        } else if (text == 'شحن محفظتي') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          );
        } else if (text == 'طلبات الدفع') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentRequestsScreen(),
            ),
          );
        } else if (text == 'طلبات الحجز') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingRequestsScreen(),
            ),
          );
        } else if (text == 'الاماكن المتاحة') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => const CategoriesScreen(
                    fromMainScreen: false,
                    scrollToAvailablePlaces:
                        true, // تمرير true للتمرير إلى قسم الأماكن المتاحة
                  ),
            ),
          );
        } else if (text == 'جروبات') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GroupsScreen()),
          );
        } else if (text == ' الاقسام') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => const CategoriesScreen(
                    fromMainScreen: false,
                    scrollToAvailablePlaces:
                        false, // لا تمرير إلى قسم الأماكن المتاحة
                  ),
            ), // Navigate to Categories
          );
        } else if (text == 'تغير كلمة المرور') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangePasswordScreen(),
            ),
          );
        } else if (text == 'الشكاوى') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ComplaintsScreen(),
            ),
          );
        }
        // Add handling for settings button
        else if (text == 'الإعدادات') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: contentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color:
                isHighlighted
                    ? Colors.transparent
                    : (isDarkMode
                        ? Colors.transparent
                        : primarySkyBlue.withValues(alpha: 0.1)),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        elevation: 0, // إزالة الارتفاع الافتراضي للزر
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              // Use the original text directly
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 22),
        ],
      ),
    );
  }

  // New method for the logout button
  Widget _buildLogoutButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        gradient: LinearGradient(
          colors: [
            Colors.redAccent.shade200,
            Colors.redAccent.shade400,
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15.0),
          onTap: () async {
            // Add haptic feedback for better UX
            HapticFeedback.mediumImpact();
            
            // Show confirmation dialog
            if (!mounted) return;
            final bool confirm = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('تأكيد الخروج'),
                content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ) ?? false;
            
            if (confirm) {
              await authProvider.signOut();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: icon in a circle
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                // Center: text
                const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                // Right side: arrow icon
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget to display when the user is not logged in
  Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined, // Or Icons.login
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              "الرجاء تسجيل الدخول", //  Localize
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "تحتاج إلى تسجيل الدخول لعرض ملفك الشخصي وإدارة حسابك.", //Localize
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("الذهاب إلى تسجيل الدخول"), //Localize
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewProfileImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return; // Don't show anything if there's no image

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full screen image with interactive viewer for zooming
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: GestureDetector(
                  onTap:
                      () =>
                          Navigator.of(
                            context,
                          ).pop(), // Tap background to close
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Center(
                      child: Hero(
                        tag: 'profileImage',
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "فشل تحميل الصورة",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Close button positioned at the top
              Positioned(
                top: 30,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// قاطع مخصص لمنحنى الهيدر
class HeaderCurveClipper extends CustomClipper<Path> {
  final double curveDepth;

  HeaderCurveClipper({this.curveDepth = 50.0});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - curveDepth);

    // تحديد نقاط التحكم للمنحنى
    Offset controlPoint1 = Offset(size.width / 4, size.height);
    Offset endPoint = Offset(size.width / 2, size.height);
    path.quadraticBezierTo(
      controlPoint1.dx,
      controlPoint1.dy,
      endPoint.dx,
      endPoint.dy,
    );

    Offset controlPoint2 = Offset(size.width * 3 / 4, size.height);
    Offset endPoint2 = Offset(size.width, size.height - curveDepth);
    path.quadraticBezierTo(
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint2.dx,
      endPoint2.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// رسام نمط الخلفية للهيدر
class HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withAlpha(15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // رسم خطوط متقاطعة
    final double spacing = 20.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      // خطوط مائلة من اليسار إلى اليمين
      canvas.drawLine(Offset(0, i), Offset(i, 0), paint);

      // خطوط مائلة من اليمين إلى اليسار
      canvas.drawLine(Offset(size.width, i), Offset(size.width - i, 0), paint);
    }

    // رسم دوائر زخرفية
    final circlePaint =
        Paint()
          ..color = Colors.white.withAlpha(10)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final double radius = 10.0 + i * 20.0;
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.3),
        radius,
        circlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
