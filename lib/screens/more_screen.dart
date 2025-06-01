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

// ألوان الوضع الليلي متوافقة مع more_screen.dart
const Color darkBackgroundColor = Color(0xFF1A1A1A); // خلفية داكنة محسنة
const Color darkCardColor = Color(0xFF2D2D2D); // لون البطاقة/الزر الداكن محسن
const Color darkGradientStart = Color(0xFF1565C0); // بداية التدرج الداكن
const Color darkGradientEnd = Color(0xFF42A5F5); // نهاية التدرج الداكن
const Color darkTextPrimary = Color(0xFFE0E0E0); // نص أساسي داكن
const Color darkTextSecondary = Color(0xFFB0B0B0); // نص ثانوي داكن
const Color darkIconColor = Color(0xFF81D4FA); // لون الأيقونات في الوضع الليلي
const Color darkCardBorderColor = Color(0xFF3D3D3D); // لون حدود البطاقات في الوضع الليلي
const Color darkHighlightColor = Color(0xFF29B6F6); // لون التمييز في الوضع الليلي
const Color darkSurfaceColor = Color(0xFF252525); // لون خلفية العناصر في الوضع الليلي
const Color darkPrimaryButtonColor = Color(0xFF1976D2); // لون الأزرار الرئيسية في الوضع الليلي

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
    final bool isLoggedIn = userId != null;

    return Scaffold(
      backgroundColor: screenBgColor,
      body: isLoggedIn
          ? StreamBuilder<UserProfile?>(
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
                        isLoggedIn,
                      ),
                    ],
                  ), // Closes Column
                ); // Closes SingleChildScrollView return from builder
              }, // Closes StreamBuilder builder
            ) // Closes StreamBuilder
          : SingleChildScrollView(
              // Non-logged in user view
              child: Column(
                children: [
                  _buildGuestHeaderSection(context, headerGradient),
                  const SizedBox(height: 60), // Increased from 20 to 60
                  _buildActionGrid(
                    context,
                    cardBgColor,
                    cardTextColor,
                    primarySkyBlue,
                    isLoggedIn,
                  ),
                ],
              ),
            ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [darkGradientStart, darkGradientEnd],
                    )
                  : headerGradient,
            ),
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
                          "مرحباً بك", // تحسين النص
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
                      color: isDarkMode ? darkSurfaceColor : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.contact_support_outlined, // أيقونة شكاوى مناسبة
                      size: 30,
                      color: isDarkMode ? darkIconColor : accentBlue,
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
                              color: isDarkMode ? darkSurfaceColor : Colors.white,
                              borderRadius: BorderRadius.circular(
                                12.0,
                              ), // Slight rounding
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
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
                                  color: isDarkMode ? darkCardColor : Colors.grey.shade100,
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
                                            color: isDarkMode 
                                                ? darkIconColor.withOpacity(0.8)
                                                : accentBlue.withOpacity(0.8),
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
                                color: Colors.black.withOpacity(0.5),
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
                      color: isDarkMode ? darkSurfaceColor : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                          color: isDarkMode ? darkIconColor : accentBlue,
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
                                  color: isDarkMode ? darkSurfaceColor : Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
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

  // New section for user details with improved formatting
  Widget _buildUserDetailsSection(
    BuildContext context,
    UserProfile userProfile,
    Color cardBgColor,
    Color cardTextColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final detailIconColor = isDarkMode ? darkIconColor : primarySkyBlue;
    final detailLabelColor = isDarkMode ? darkTextSecondary : Colors.grey[600];
    final detailValueColor = isDarkMode ? darkTextPrimary : cardTextColor;
    final cardBackground = isDarkMode ? darkCardColor : Colors.white;
    final dividerColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1);

    // Helper to create each detail item row
    Widget buildDetailItem(IconData icon, String label, String value) {
      final displayValue = value.isNotEmpty ? value : "غير محدد"; 
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0), // Spacing between items
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: isDarkMode 
            ? Border.all(color: darkCardBorderColor, width: 1.0)
            : null,
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.person_outline,
                color: detailIconColor,
                size: 24,
              ),
              Text(
                "بيانات الحساب",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: detailValueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: dividerColor),
          buildDetailItem(
            Icons.verified_user_outlined,
            "الحالة",
            userProfile.status,
          ),
          Divider(color: dividerColor),
          buildDetailItem(
            Icons.badge_outlined,
            "رقم الطالب",
            userProfile.studentId,
          ),
          Divider(color: dividerColor),
          buildDetailItem(
            Icons.school_outlined,
            "الكلية",
            userProfile.faculty,
          ),
          Divider(color: dividerColor),
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
    final walletCardBg = isDarkMode ? darkCardColor : Colors.white;
    final walletTextColor = isDarkMode ? darkTextPrimary : Colors.black87;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final borderColor = isDarkMode ? darkCardBorderColor : primarySkyBlue.withOpacity(0.15);
    final walletHighlightColor = isDarkMode ? darkHighlightColor : primarySkyBlue;

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
                if (!isDarkMode)
                  BoxShadow(
                    color: primarySkyBlue.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
              ],
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "الرصيد المتاح",
                      style: TextStyle(
                        color: walletTextColor.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "المحفظة الاساسية", 
                          style: TextStyle(
                            color: walletTextColor.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.account_balance_wallet,
                          color: walletHighlightColor,
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? darkSurfaceColor : Colors.blue.shade50.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "جنيه مصري",
                          style: TextStyle(
                            color: walletTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentBalance,
                          style: TextStyle(
                            color: walletHighlightColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? darkPrimaryButtonColor : walletHighlightColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WalletScreen()),
                          );
                        },
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          "شحن محفظتي",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
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
    bool isLoggedIn,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // قائمة جميع الإجراءات
    final List<Map<String, dynamic>> actions = [
      {'icon': Icons.credit_card_rounded, 'text': 'شحن محفظتي', 'highlight': true, 'requiresAuth': true},
      {'icon': Icons.favorite_border, 'text': 'المفضلة', 'highlight': false, 'requiresAuth': true},
      {'icon': Icons.place_outlined, 'text': 'الاماكن المتاحة', 'highlight': false, 'requiresAuth': false},
      {'icon': Icons.category_outlined, 'text': 'الاقسام', 'highlight': false, 'requiresAuth': false},
      {'icon': Icons.support_agent_outlined, 'text': 'الشكاوى', 'highlight': false, 'requiresAuth': true},
      {'icon': Icons.request_page_outlined, 'text': 'طلبات الدفع', 'highlight': false, 'requiresAuth': true},
      {'icon': Icons.bookmark_outline, 'text': 'طلبات الحجز', 'highlight': false, 'requiresAuth': true},
      {'icon': Icons.groups_outlined, 'text': 'جروبات', 'highlight': false, 'requiresAuth': false},
      {'icon': Icons.settings_outlined, 'text': 'الإعدادات', 'highlight': false, 'requiresAuth': false},
      {'icon': Icons.info_outline, 'text': 'عن السهم', 'highlight': false, 'requiresAuth': false},
      {'icon': Icons.vpn_key_outlined, 'text': 'تغير كلمة المرور', 'highlight': false, 'requiresAuth': true},
      {'icon': Icons.phone_outlined, 'text': 'اتصل بنا', 'highlight': false, 'requiresAuth': false},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 12.0, top: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.apps_outlined,
                  size: 20,
                  color: isDarkMode ? darkIconColor : primarySkyBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  "الخدمات المتاحة",
                  style: TextStyle(
                    color: isDarkMode ? darkTextPrimary : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDarkMode ? darkSurfaceColor : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${actions.length} خدمة",
                    style: TextStyle(
                      color: isDarkMode ? darkIconColor : primarySkyBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 2.8,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              final bool isHighlighted = action['highlight'] as bool;
              final bool requiresAuth = action['requiresAuth'] as bool;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    if (isHighlighted)
                      BoxShadow(
                        color: isDarkMode
                            ? darkHighlightColor.withOpacity(0.3)
                            : primarySkyBlue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    else if (!isDarkMode)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: _buildActionButton(
                  context,
                  action['icon'] as IconData,
                  action['text'] as String,
                  isHighlighted 
                      ? (isDarkMode ? darkHighlightColor : primarySkyBlue)
                      : (isDarkMode ? darkCardColor : buttonColor),
                  isHighlighted ? Colors.white : (isDarkMode ? darkTextPrimary : textColor),
                  isHighlighted,
                  requiresAuth,
                  isLoggedIn,
                ),
              );
            },
          ),
          
          // حالة تسجيل الدخول
          const SizedBox(height: 25),
          if (isLoggedIn)
            _buildLogoutButton(context)
          else
            _buildLoginButton(context),
        ],
      ),
    );
  }

  // ويدجت مساعد لإنشاء كل زر إجراء مع فحص تسجيل الدخول
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String text,
    Color bgColor,
    Color contentColor,
    bool isHighlighted,
    bool requiresAuth,
    bool isLoggedIn,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // التحقق من حالة تسجيل الدخول وما إذا كان الإجراء يتطلب المصادقة
    final bool canAccess = !requiresAuth || isLoggedIn;
    final borderColor = isDarkMode ? darkCardBorderColor : primarySkyBlue.withOpacity(0.1);
    
    return ElevatedButton(
      onPressed: () async {
        // إذا كان الإجراء يتطلب تسجيل دخول ولكن المستخدم غير مسجل
        if (requiresAuth && !isLoggedIn) {
          _showLoginRequiredDialog(context);
          return;
        }

        // تنفيذ الإجراء لكل زر
        _logger.info("تم النقر على: $text");

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
            ),
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
                    scrollToAvailablePlaces: true,
                  ),
            ),
          );
        } else if (text == 'جروبات') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GroupsScreen()),
          );
        } else if (text == 'الاقسام') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => const CategoriesScreen(
                    fromMainScreen: false,
                    scrollToAvailablePlaces: false,
                  ),
            ),
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
        } else if (text == 'الإعدادات') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: canAccess ? bgColor : bgColor.withOpacity(0.7),
        foregroundColor: contentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: isHighlighted
                ? Colors.transparent
                : (isDarkMode ? borderColor : borderColor),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        elevation: isDarkMode ? 0 : 1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                color: canAccess ? contentColor : contentColor.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            icon, 
            size: 20, 
            color: canAccess 
                ? (isHighlighted ? Colors.white : (isDarkMode ? darkIconColor : primarySkyBlue))
                : contentColor.withOpacity(0.5)
          ),
          if (requiresAuth && !isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Icon(
                Icons.lock_outline, 
                size: 14, 
                color: contentColor.withOpacity(0.5)
              ),
            ),
        ],
      ),
    );
  }

  // إضافة زر تسجيل الدخول للمستخدمين غير المسجلين
  Widget _buildLoginButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final loginButtonColor = isDarkMode ? darkHighlightColor : accentBlue;
    final shadowColor = isDarkMode ? darkHighlightColor.withOpacity(0.3) : accentBlue.withOpacity(0.3);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        gradient: LinearGradient(
          colors: isDarkMode
              ? [darkGradientStart, darkGradientEnd]
              : [accentBlue.withOpacity(0.8), accentBlue],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15.0),
          onTap: () {
            // Add haptic feedback for better UX
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Right side: icon in a circle
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                // Center: text
                const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                // Left side: arrow icon
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

  // إضافة زر تسجيل الدخول للمستخدمين غير المسجلين
  Widget _buildLogoutButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final logoutGradientStart = isDarkMode ? Color(0xFF7F0000) : Colors.redAccent.shade200;
    final logoutGradientEnd = isDarkMode ? Color(0xFFC62828) : Colors.redAccent.shade400;
    final shadowColor = isDarkMode 
        ? Colors.red.shade900.withOpacity(0.3) 
        : Colors.redAccent.withOpacity(0.3);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        gradient: LinearGradient(
          colors: [
            logoutGradientStart,
            logoutGradientEnd,
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
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
            final bool? confirmLogout = await _showLogoutConfirmationDialog(context);
            
            if (confirmLogout == true) {
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
                    color: Colors.white.withOpacity(0.2),
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

  // Add logout confirmation dialog
  Future<bool?> _showLogoutConfirmationDialog(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? darkSurfaceColor : Colors.white;
    final textColor = isDarkMode ? darkTextPrimary : Colors.black87;
    final cancelButtonColor = isDarkMode ? darkCardColor : Colors.grey.shade200;
    final cancelTextColor = isDarkMode ? darkTextSecondary : Colors.grey.shade700;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: dialogBgColor,
          elevation: 24,
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'تأكيد تسجيل الخروج',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.9),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: cancelTextColor,
                backgroundColor: cancelButtonColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade500,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
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

  // Add a guest header section for non-logged in users
  Widget _buildGuestHeaderSection(BuildContext context, Gradient headerGradient) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // الخلفية المنحنية مع تدرج لوني
        ClipPath(
          clipper: HeaderCurveClipper(curveDepth: 65.0),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [darkGradientStart, darkGradientEnd],
                    )
                  : headerGradient,
            ),
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
                      color: Colors.white.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.15),
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
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),

                // نص الترحيب للزائر
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
                            colors: [Colors.white, Colors.white.withOpacity(0.8)],
                            tileMode: TileMode.mirror,
                          ).createShader(bounds);
                        },
                        child: Text(
                          "مرحباً بك في السهم",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // زر تسجيل الدخول
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text(
                          "تسجيل الدخول",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // شعار التطبيق في المنتصف
        Positioned(
          top: 148, // Moved lower on the screen
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDarkMode ? darkSurfaceColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: 'https://i.ibb.co/TDGcXVGY/sainai.jpg',
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? darkIconColor : accentBlue,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDarkMode ? darkHighlightColor : accentBlue,
                  child: Icon(
                    Icons.home_work_outlined,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // إظهار مربع حوار تسجيل الدخول المطلوب
  void _showLoginRequiredDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? darkSurfaceColor : Colors.white;
    final titleColor = isDarkMode ? darkTextPrimary : Colors.blue;
    final textColor = isDarkMode ? darkTextSecondary : Colors.black87;
    final iconBgColor = isDarkMode ? darkHighlightColor : const Color(0xFFFFD700);
    final buttonColor = isDarkMode ? darkHighlightColor : accentBlue;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: dialogBgColor,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon for attention
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBgColor,
                  ),
                  child: Icon(
                    Icons.priority_high,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  "تسجيل الدخول مطلوب",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 10),
                // Message
                Text(
                  "يجب عليك تسجيل الدخول أو إنشاء حساب للوصول إلى المحفظة وإدارة رصيدك",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: isDarkMode ? darkTextSecondary : Colors.grey,
                      ),
                      child: const Text("إلغاء"),
                    ),
                    // Login button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      child: const Text("تسجيل الدخول"),
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
