import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart'; // Ensure no 'hide' directive here
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart'
    as cs; // Import with prefix 'cs'
import 'package:shimmer/shimmer.dart'; // Import shimmer package
import 'package:logging/logging.dart'; // Import logging package
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome for social icons
import 'package:url_launcher/url_launcher.dart'; // Import for URL launching
import 'package:url_launcher/url_launcher_string.dart'; // Import for legacy URL launching methods
// Import for auto-resizing text
import 'package:marquee_widget/marquee_widget.dart'; // Import for marquee text effect
// ignore: unused_import
import 'package:permission_handler/permission_handler.dart'; // Import for permission handling
import 'package:onesignal_flutter/onesignal_flutter.dart'; // Import for OneSignal notifications
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences
import '../providers/navigation_provider.dart';
// Import FavoritesProvider
import '../models/apartment.dart'; // Import the Apartment model
import '../models/banner.dart' as app_banner; // Import Banner model with prefix
import '../models/app_update.dart'; // Import the new AppUpdate model
import '../services/category_service.dart'; // Import CategoryService
import '../services/banner_service.dart'; // Import BannerService
import '../services/property_service_supabase.dart'; // Import PropertyServiceSupabase
import '../services/update_service.dart'; // Import the UpdateService
import '../services/available_places_service.dart'; // Import AvailablePlacesService
import '../screens/categories_screen.dart'; // Import CategoriesScreen
import '../widgets/typewriter_animated_text.dart'; // Import the TypewriterAnimatedText widget
// Import the cropped network image widget
import '../widgets/property_card_widget.dart'; // إضافة استيراد ويدجيت العقار الجديد
import 'apartments_list_screen.dart'; // Import the apartments list screen
import 'place_details_screen.dart'; // استيراد شاشة تفاصيل الأماكن
// Import the property details screen
import '../providers/auth_provider.dart'; // Importar AuthProvider
// Importar AuthUtils
// Import FirestoreService
import '../screens/login_screen.dart'; // Import LoginScreen
// إضافة استيراد للشاشة الجديدة

// Feature class for Why Choose Us section - moved outside of _HomeScreenState
class _Feature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// جمل النص المتحرك - تم تحسينها لتكون أكثر جاذبية وتسويقية
const List<String> animatedTexts = [
  "✓ أكثر من 5 سنوات من الخبرة في خدمة الطلاب",
  "✓ أسعار تنافسية تناسب احتياجاتك وميزانيتك",
  "✓ مستوى عالٍ من الأمان والخصوصية",
  "✓ بيئة هادئة ومريحة للتركيز والدراسة",
  "✓ دعم فني على مدار الساعة لراحتك",
  "✓ فرصتك الآن - احجز قبل نفاد الأماكن!",
];

// صور البانر الاحتياطية (للحالات غير المتصلة أو عند حدوث أخطاء)
final List<String> fallbackBannerImages = [
  'assets/images/banners/banner1.webp',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // الخدمات المستخدمة في الشاشة
  final PropertyServiceSupabase _propertyService = PropertyServiceSupabase();
  final CategoryService _categoryService = CategoryService();
  final BannerService _bannerService = BannerService();
  final AvailablePlacesService _placesService = AvailablePlacesService(); // إضافة خدمة الأماكن
  final UpdateService _updateService = UpdateService(); // إضافة خدمة التحديثات
  final Logger _logger = Logger('HomeScreen');

  // متغيرات البيانات
  List<app_banner.Banner> _banners = [];
  List<Map<String, dynamic>> _categories = [];
  List<Apartment> _latestApartments = [];
  List<Apartment> _featuredProperties = [];
  List<dynamic> _availablePlaces = []; // إضافة متغير للأماكن المتاحة
  AppUpdate? _appUpdate; // متغير بيانات التحديث

  // متغيرات حالة التحميل
  bool _isLoading = true;
  bool _isCategoriesLoading = true;
  bool _isFeaturedLoading = true;
  bool _isAvailablePlacesLoading = true; // حالة تحميل الأماكن المتاحة
  bool _isUpdateLoading = true; // حالة تحميل بيانات التحديث
  int _currentBannerIndex = 0;

  // متغيرات إدارة أذونات الإشعارات
  bool _notificationPermissionGranted = false;
  bool _isCheckingNotificationPermission = true;

  // متغيرات التحكم في التحديثات
  StreamSubscription<List<Apartment>>? _apartmentsStreamSubscription;
  late ScrollController _scrollController;

  // توقيت لإعادة جلب البيانات - للتحكم في عدد الطلبات
  Timer? _refreshTimer;

  // تحسين الأداء من خلال تخزين القيم السابقة

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeData();
  }

  // دالة جديدة لتنظيم وتسلسل تهيئة البيانات
  void _initializeData() {
    Future.microtask(() async {
      // الترتيب الأمثل للتحميل:
      // 1. البانرات (صغيرة وسريعة)
      // 2. الفئات (صغيرة وضرورية)
      // 3. العقارات المميزة (محدودة وذات أولوية عالية)
      // 4. أحدث العقارات (قد تكون أكثر عدداً)
      // 5. فحص أذونات الإشعارات

      try {
        await Future.wait([
          _fetchBanners(),
          _fetchCategories(),
          _fetchAppUpdate(), // إضافة استدعاء دالة جلب بيانات التحديث
          _checkNotificationPermission(), // فحص أذونات الإشعارات
        ]);

        if (!mounted) return;

        // تحديث الواجهة بعد تحميل البانرات والفئات
        setState(() {});

        // استكمال التحميل بشكل متوازٍ
        await Future.wait([
          _fetchFeaturedProperties(),
          _fetchLatestApartments(),
          _fetchAvailablePlaces(), // إضافة استدعاء دالة جلب الأماكن المتاحة
        ]);

        if (mounted) {
          _setupApartmentsListener();
          _setupRefreshTimer();
        }
      } catch (e) {
        if (kDebugMode) {
          _logger.severe('خطأ عام في تهيئة البيانات: $e');
        }
        // التأكد من إخفاء مؤشرات التحميل حتى في حالة الخطأ
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isCategoriesLoading = false;
            _isFeaturedLoading = false;
            _isUpdateLoading = false;
            _isCheckingNotificationPermission = false;
          });
        }
      }
    });
  }

  // إعداد مؤقت لتحديث البيانات تلقائياً بشكل دوري
  void _setupRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15), // كل 15 دقيقة تحديث في الخلفية
      (_) => _refreshNonVisibleContent(),
    );
  }

  // تحديث المحتوى غير المرئي في الخلفية دون إظهار مؤشرات التحميل
  Future<void> _refreshNonVisibleContent() async {
    try {
      // حساب موضع العناصر المرئية حالياً
      final offset = _scrollController.offset;
      final screenHeight = MediaQuery.of(context).size.height;

      // البانرات: تحديث إذا كان المستخدم لا يشاهدها حالياً
      if (offset > 250) {
        await _fetchBanners(silent: true);
      }

      // الفئات: تحديث إذا كان المستخدم لا يشاهدها حالياً
      if (offset > 400 || offset < 100) {
        await _fetchCategories(silent: true);
      }

      // العقارات المميزة والأحدث: تحديث بناءً على موضع التمرير
      if (offset > screenHeight || offset < screenHeight / 2) {
        await _fetchFeaturedProperties(silent: true);
        await _fetchLatestApartments(silent: true);
      }
    } catch (e) {
      // تسجيل الخطأ فقط إذا كنا في وضع التصحيح دون إزعاج المستخدم
      if (kDebugMode) {
        _logger.fine('تحديث البيانات في الخلفية: $e');
      }
    }
  }

  @override
  void dispose() {
    // إلغاء جميع الاشتراكات والمؤقتات لتجنب تسرب الذاكرة
    _apartmentsStreamSubscription?.cancel();
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 0),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // 1. البانر الدوار - أول ما يراه المستخدم (أهم انطباع بصري)
            _buildBannerCarousel(),

            const SizedBox(height: 8.0),

            // 2. النص المتحرك - لعرض الميزات والترويج
            _buildAnimatedTextSection(),

            // 3. قسم تحديث التطبيق - للإشعار بالتحديثات الجديدة
            _buildAppUpdateSection(),

            // 4. بنر تسجيل الدخول - للمستخدمين غير المسجلين
            _buildLoginPromotionBanner(),

            const SizedBox(height: 12.0),

            // 5. قسم تفعيل الإشعارات - يظهر فقط عند عدم تفعيل الإشعارات
            _buildNotificationPromptSection(),

            // 6. قسم التصنيفات - بتصميم جديد أكثر جاذبية
            _buildCategoriesHeader(),
            _buildCategoriesSection(),

            // 6. قسم أحدث العقارات
            _buildLatestPropertiesSectionHeader(),
            _buildApartmentsSection(),

            const SizedBox(height: 16.0),

            // 7. قسم العقارات المميزة - بتأثيرات جديدة للتمييز
            _buildFeaturedPropertiesSection(),

            const SizedBox(height: 24.0),

            // 8. قسم الأماكن المتاحة
            _buildAvailablePlacesSection(),
            
            const SizedBox(height: 24.0),
            
            // 9. قسم لماذا نحن الخيار الأفضل
            _buildWhyChooseUsSection(),

            const SizedBox(height: 16.0),

            // 10. قسم معلومات المصمم - معلومات المطور
            _buildDesignerInfoSection(),

            const SizedBox(height: 24.0),

            // 11. قسم تواصل معنا - تصميم عصري ومتجاوب
            _buildContactUsSection(),
          ],
        ),
      ),
    );
  }

  // --- أقسام الواجهة المقسمة لتسهيل الصيانة ---

  // قسم تفعيل الإشعارات - يظهر فقط عند عدم تفعيل الإشعارات
  Widget _buildNotificationPromptSection() {
    // إخفاء القسم إذا كانت الإشعارات مفعلة أو قيد الفحص
    if (_notificationPermissionGranted || _isCheckingNotificationPermission) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.orange.shade600, Colors.orange.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // عناصر زخرفية في الخلفية
          Positioned(
            right: -15,
            top: -15,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // محتوى القسم
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isCompact = constraints.maxWidth < 350;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // أيقونة الإشعارات
                    Container(
                      width: isCompact ? 48 : 56,
                      height: isCompact ? 48 : 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: isCompact ? 24 : 28,
                      ),
                    ),

                    SizedBox(width: isCompact ? 12 : 16),

                    // النص التوضيحي
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'فعّل الإشعارات',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 16 : 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'احصل على إشعارات فورية بأحدث العقارات والعروض المميزة',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isCompact ? 13 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: isCompact ? 8 : 12),

                    // زر التفعيل
                    ElevatedButton(
                      onPressed: _requestNotificationPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange.shade700,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 16,
                          vertical: 12,
                        ),
                        elevation: 3,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_on_rounded,
                            size: isCompact ? 16 : 18,
                          ),
                          if (!isCompact) const SizedBox(width: 6),
                          if (!isCompact)
                            const Text(
                              'تفعيل',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // قسم النص المتحرك المحسن
  Widget _buildAnimatedTextSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: TypewriterAnimatedText(
          texts: animatedTexts,
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // عنوان قسم الفئات - تم تحسينه بإضافة رموز وتأثيرات
  Widget _buildCategoriesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              Provider.of<NavigationProvider>(
                context,
                listen: false,
              ).setIndex(2);
            },
            icon: Icon(
              Icons.grid_view_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              'عرض الكل',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                'تصفح حسب الفئات',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.category_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // عنوان أحدث العقارات - تصميم جديد أكثر وضوحاً
  Widget _buildLatestPropertiesSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_isLoading && _latestApartments.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApartmentsListScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                'عرض الكل',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Row(
            children: [
              Text(
                'أحدث العقارات',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- دوال جلب البيانات المحسنة ---

  // سيتم لاحقاً تنفيذ بقية دوال جلب البيانات وبناء الأقسام المختلفة

  // دالة البانر المُحسنة
  Widget _buildBannerCarousel() {
    // إذا كانت البانرات قيد التحميل، نعرض مؤشر تحميل محسن
    if (_isLoading) {
      return Column(
        children: [
          _buildShimmerLoadingBanner(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.grey.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // تحضير مصادر البانر (من API أو استخدام الصور الاحتياطية)
    final List<String> bannerSources =
        _banners.isNotEmpty
            ? _banners.map((banner) => banner.imageUrl).toList()
            : fallbackBannerImages;

    // تصميم محسن للبانر مع تأثيرات انتقالية
    return Column(
      children: [
        SizedBox(
          height: 200.0,
          child: cs.CarouselSlider(
            options: cs.CarouselOptions(
              height: 200.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 8),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              viewportFraction: 0.93,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
            ),
            items:
                bannerSources.map((item) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // الصورة الأساسية
                              _buildOptimizedBannerImage(
                                imageUrl: item,
                                isAsset: !item.startsWith('http'),
                              ),

                              // طبقة تظليل تدريجية لتحسين قراءة النصوص
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.0),
                                      Colors.black.withOpacity(0.4),
                                    ],
                                    stops: const [0.7, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
          ),
        ),

        // نقاط تحديد البانر الحالي
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                bannerSources.asMap().entries.map((entry) {
                  return Container(
                    width: _currentBannerIndex == entry.key ? 24.0 : 12.0,
                    height: 6.0,
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3.0),
                      color:
                          _currentBannerIndex == entry.key
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withOpacity(0.3),
                      boxShadow:
                          _currentBannerIndex == entry.key
                              ? [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                              : null,
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // بنر ترويجي لتسجيل الدخول مع تصميم محسن
  Widget _buildLoginPromotionBanner() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // عرض البنر فقط إذا لم يكن المستخدم مسجلاً
        if (!authProvider.isAuthenticated) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // عناصر زخرفية في الخلفية
                Positioned(
                  right: -15,
                  top: -15,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // محتوى البنر
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // تحديد ما إذا كنا نحتاج إلى تصميم مضغوط
                      final bool isCompact = constraints.maxWidth < 350;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: isCompact ? 48 : 56,
                            height: isCompact ? 48 : 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: isCompact ? 24 : 28,
                            ),
                          ),

                          SizedBox(width: isCompact ? 12 : 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'سجل دخولك الآن',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isCompact ? 16 : 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'واستمتع بمزايا حصرية تنتظرك',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: isCompact ? 13 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: isCompact ? 8 : 12),

                          ElevatedButton(
                            onPressed: () => _navigateToLogin(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 12 : 16,
                                vertical: 12,
                              ),
                              elevation: 3,
                              shadowColor: Colors.black.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  size: isCompact ? 16 : 18,
                                ),
                                if (!isCompact) const SizedBox(width: 6),
                                if (!isCompact)
                                  const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          // عدم عرض أي شيء للمستخدمين المسجلين
          return const SizedBox.shrink();
        }
      },
    );
  }

  // --- Helper widgets for banner section ---

  // تحميل الصور بطريقة محسنة للبانر
  Widget _buildOptimizedBannerImage({
    required String imageUrl,
    bool isAsset = false,
  }) {
    if (isAsset) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildBannerErrorWidget(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) {
        if (kDebugMode) {
          _logger.warning('خطأ في تحميل صورة البانر: $url - $error');
        }
        return _buildBannerErrorWidget();
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      memCacheHeight: (200 * MediaQuery.of(context).devicePixelRatio).round(),
    );
  }

  // Widget for shimmer loading effect
  Widget _buildShimmerLoadingBanner() {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
      highlightColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[100]!,
      child: Container(
        height: 200.0,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
        ),
      ),
    );
  }

  // Widget for shimmer placeholder
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
      highlightColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[100]!,
      child: Container(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
      ),
    );
  }

  // Widget for banner error state
  Widget _buildBannerErrorWidget() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'لا يمكن تحميل الصورة',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // التنقل إلى شاشة تسجيل الدخول
  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // تحديث بانرات تطبيقنا
  Future<void> _fetchBanners({bool silent = false}) async {
    if (!mounted) return;

    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
        });
      }

      // تسجيل بداية تحميل البانرات
      if (kDebugMode) {
        _logger.info('بدء تحميل البانرات...');
      }

      // جلب البانرات من الخدمة
      final banners = await _bannerService.getBanners();

      if (kDebugMode) {
        _logger.info('تم استلام ${banners.length} بانر');
      }

      if (mounted) {
        setState(() {
          _banners = banners;
          if (!silent) {
            _isLoading = false;
          }
        });

        // إذا لم تتوفر بانرات، نحاول مرة أخرى بعد تأخير قصير
        if (banners.isEmpty && !silent) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _fetchBanners(silent: true);
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.warning('خطأ في جلب البانرات: $e');
      }

      if (mounted && !silent) {
        setState(() {
          _banners = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCategories({bool silent = false}) async {
    if (!mounted) return;

    try {
      if (!silent) {
        setState(() {
          _isCategoriesLoading = true;
        });
      }

      final categories = await _categoryService.getCategories();

      if (!mounted) return;

      if (kDebugMode) {
        _logger.info('تم جلب ${categories.length} فئة');
      }

      setState(() {
        _categories = categories;
        if (!silent) {
          _isCategoriesLoading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        _logger.warning('خطأ في جلب الفئات: $e');
      }

      setState(() {
        if (!silent) {
          _isCategoriesLoading = false;
        }
      });
    }
  }

  // إضافة دالة مساعدة لإظهار الإشعارات مع نص مركزي
  void _showCenteredTextMessage(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!mounted) return;

    // إلغاء أي إشعارات سابقة
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color backgroundColor;
    if (isError) {
      backgroundColor = Colors.red.shade600;
    } else if (isSuccess) {
      backgroundColor = Colors.green.shade600;
    } else {
      backgroundColor = Theme.of(context).colorScheme.secondary;
    }

    // إظهار الإشعار الجديد في أسفل الشاشة مع نص مركزي
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isSuccess ? 5 : 3),
        elevation: 8,
        action:
            isSuccess
                ? SnackBarAction(
                  label: '✓',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                )
                : null,
      ),
    );
  }

  // تعديل دالة تبديل المفضلة لاستخدام الإشعار المركزي

  Future<void> _fetchLatestApartments({bool silent = false}) async {
    if (!mounted) return;

    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
        });
      }

      // تسجيل بداية الطلب
      if (kDebugMode) {
        _logger.info('بدء جلب أحدث العقارات...');
      }

      // مسح التخزين المؤقت
      _propertyService.clearCache(key: 'latest_properties');

      // جلب البيانات - تحديد العدد بـ 10 عقارات فقط
      List<Apartment> apartments = [];

      try {
        apartments = await _propertyService.getLatestProperties(limit: 10);
      } catch (innerError) {
        if (kDebugMode) {
          _logger.warning(
            'خطأ في جلب أحدث العقارات. محاولة جلب العقارات المتاحة: $innerError',
          );
        }

        // جلب العقارات المتاحة كخيار بديل - أيضاً 10 عقارات فقط
        apartments = await _propertyService.getAvailableProperties(limit: 10);
      }

      if (!mounted) return;

      if (kDebugMode) {
        _logger.info('تم جلب ${apartments.length} عقار');
      }

      setState(() {
        _latestApartments = apartments;
        if (!silent) {
          _isLoading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        _logger.warning('خطأ في جلب العقارات: $e');
      }

      setState(() {
        if (!silent) {
          _isLoading = false;
        }
      });

      if (!silent && mounted) {
        _showCenteredTextMessage(
          'حدث خطأ أثناء تحميل البيانات، يرجى المحاولة مرة أخرى',
          isError: true,
        );
      }
    }
  }

  Future<void> _fetchFeaturedProperties({bool silent = false}) async {
    if (!mounted) return;

    try {
      if (!silent) {
        setState(() {
          _isFeaturedLoading = true;
        });
      }

      if (kDebugMode) {
        _logger.info('بدء جلب العقارات المميزة...');
      }

      // تحديد العدد بـ 10 عقارات فقط للعقارات المميزة
      final featuredProperties = await _propertyService.getFeaturedProperties(
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        _featuredProperties = featuredProperties;
        if (!silent) {
          _isFeaturedLoading = false;
        }
      });

      if (kDebugMode) {
        _logger.info('تم جلب ${featuredProperties.length} عقار مميز');
      }
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        _logger.warning('خطأ في جلب العقارات المميزة: $e');
      }

      setState(() {
        if (!silent) {
          _isFeaturedLoading = false;
        }
      });
    }
  }

  void _setupApartmentsListener() {
    // سيتم تنفيذها لاحقاً
  }

  // --- دوال إدارة أذونات الإشعارات ---

  // فحص حالة أذونات الإشعارات
  Future<void> _checkNotificationPermission() async {
    if (!mounted) return;

    try {
      setState(() {
        _isCheckingNotificationPermission = true;
      });

      // فحص أذونات OneSignal
      final permission = OneSignal.Notifications.permission;

      if (kDebugMode) {
        _logger.info('حالة أذونات الإشعارات: $permission');
      }

      if (mounted) {
        setState(() {
          _notificationPermissionGranted = permission;
          _isCheckingNotificationPermission = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.warning('خطأ في فحص أذونات الإشعارات: $e');
      }

      if (mounted) {
        setState(() {
          _notificationPermissionGranted = false;
          _isCheckingNotificationPermission = false;
        });
      }
    }
  }

  // طلب أذونات الإشعارات مع تحسينات إضافية
  Future<void> _requestNotificationPermission() async {
    if (!mounted) return;

    try {
      if (kDebugMode) {
        _logger.info('طلب أذونات الإشعارات...');
      }

      // إظهار مؤشر التحميل أثناء طلب الأذونات
      setState(() {
        _isCheckingNotificationPermission = true;
      });

      // إضافة تأخير قصير لإظهار مؤشر التحميل
      await Future.delayed(const Duration(milliseconds: 500));

      // طلب الأذونات من OneSignal
      final granted = await OneSignal.Notifications.requestPermission(true);

      if (kDebugMode) {
        _logger.info('نتيجة طلب الأذونات: $granted');
      }

      if (mounted) {
        setState(() {
          _notificationPermissionGranted = granted;
          _isCheckingNotificationPermission = false;
        });

        // إظهار رسالة للمستخدم مع تأثيرات بصرية محسنة
        if (granted) {
          _showCenteredTextMessage(
            '🎉 تم تفعيل الإشعارات بنجاح!\nستصلك إشعارات فورية بأحدث العقارات والعروض المميزة',
            isSuccess: true,
          );

          // إضافة تأثير اهتزاز خفيف للتأكيد
          HapticFeedback.lightImpact();

          // حفظ حالة الموافقة محلياً
          await _saveNotificationPreference(true);
        } else {
          _showCenteredTextMessage(
            '⚠️ لم يتم تفعيل الإشعارات\nيمكنك تفعيلها لاحقاً من إعدادات التطبيق',
            isError: true,
          );

          // حفظ حالة الرفض محلياً
          await _saveNotificationPreference(false);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.severe('خطأ في طلب أذونات الإشعارات: $e');
      }

      if (mounted) {
        setState(() {
          _isCheckingNotificationPermission = false;
        });

        _showCenteredTextMessage(
          '❌ حدث خطأ أثناء طلب أذونات الإشعارات\nيرجى المحاولة مرة أخرى',
          isError: true,
        );
      }
    }
  }

  // حفظ تفضيلات الإشعارات محلياً
  Future<void> _saveNotificationPreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_permission_requested', true);
      await prefs.setBool('notification_permission_granted', enabled);

      if (kDebugMode) {
        _logger.info('تم حفظ تفضيلات الإشعارات: $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.warning('خطأ في حفظ تفضيلات الإشعارات: $e');
      }
    }
  }

  // دالة جلب الأماكن المتاحة
  Future<void> _fetchAvailablePlaces({bool silent = false}) async {
    if (!mounted) return;

    try {
      if (!silent) {
        setState(() {
          _isAvailablePlacesLoading = true;
        });
      }

      // جلب أول 4 أماكن متاحة فقط
      final places = await _placesService.getAllPlaces(limit: 4);

      if (!mounted) return;

      if (kDebugMode) {
        _logger.info('تم جلب ${places.length} مكان متاح');
      }

      setState(() {
        _availablePlaces = places;
        if (!silent) {
          _isAvailablePlacesLoading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        _logger.warning('خطأ في جلب الأماكن المتاحة: $e');
      }

      setState(() {
        if (!silent) {
          _isAvailablePlacesLoading = false;
        }
      });
    }
  }

  // تعديل دالة تحديث البيانات لتشمل تحديث معلومات التحديث
  Future<void> _refreshAllData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _isCategoriesLoading = true;
        _isFeaturedLoading = true;
        _isAvailablePlacesLoading = true;
        _isUpdateLoading = true;
      });

      // تنفيذ عمليات التحديث بالتوازي
      await Future.wait([
        _fetchBanners(),
        _fetchCategories(),
        _fetchLatestApartments(),
        _fetchFeaturedProperties(),
        _fetchAvailablePlaces(),
        _fetchAppUpdate(),
      ]);

      if (!mounted) return;

      _showCenteredTextMessage('تم تحديث البيانات بنجاح');
    } catch (e) {
      if (kDebugMode) {
        _logger.severe('خطأ في تحديث البيانات: $e');
      }

      if (mounted) {
        _showCenteredTextMessage(
          'حدث خطأ أثناء تحديث البيانات، يرجى المحاولة مرة أخرى',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCategoriesLoading = false;
          _isFeaturedLoading = false;
          _isAvailablePlacesLoading = false;
          _isUpdateLoading = false;
        });
      }
    }
  }

  // --- قسم الفئات ---

  // قسم الفئات المحسن
  Widget _buildCategoriesSection() {
    if (_isCategoriesLoading) {
      return _buildCategoriesLoadingSection();
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 3.0,
      ),
      itemCount: _categories.length > 6 ? 6 : _categories.length,
      itemBuilder: (context, index) {
        // حساب الفهرس المعكوس للترتيب من اليمين إلى اليسار
        final crossAxisCount = 2;
        final rowIndex = index ~/ crossAxisCount;
        final rowStartIndex = rowIndex * crossAxisCount;
        final reverseIndex =
            rowStartIndex + crossAxisCount - 1 - (index % crossAxisCount);

        // التأكد من أن الفهرس المعكوس في نطاق مقبول
        final maxIndex = _categories.length > 6 ? 6 : _categories.length;
        final safeIndex = reverseIndex < maxIndex ? reverseIndex : index;

        final category = _categories[safeIndex];
        return _buildCategoryCard(
          category['iconUrl'] ?? category['icon'],
          category['label'] as String,
        );
      },
    );
  }

  // واجهة تحميل الفئات
  Widget _buildCategoriesLoadingSection() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 3.0,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => _buildCategoryShimmerCard(),
    );
  }

  // بطاقة فئة محسنة
  Widget _buildCategoryCard(dynamic icon, String label) {
    final theme = Theme.of(context);
    final bool isLongText = label.length > 7;

    return Card(
      margin: const EdgeInsets.all(4.0),
      elevation: 2.0,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.0),
        onTap: () => _navigateToCategory(label),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // أيقونة الفئة
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Center(child: _buildCategoryIcon(icon)),
              ),

              const SizedBox(width: 12.0),

              // نص الفئة
              Expanded(
                child: Container(
                  height: 22.0,
                  alignment: Alignment.centerRight,
                  child:
                      isLongText
                          ? Marquee(
                            animationDuration: const Duration(seconds: 2),
                            backDuration: const Duration(milliseconds: 1000),
                            pauseDuration: const Duration(milliseconds: 1000),
                            direction: Axis.horizontal,
                            textDirection: TextDirection.rtl,
                            autoRepeat: true,
                            child: Text(
                              label,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                              ),
                            ),
                          )
                          : Text(
                            label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تحميل بطاقة فئة
  Widget _buildCategoryShimmerCard() {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
      highlightColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(child: Container(height: 22.0, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // أيقونة الفئة
  Widget _buildCategoryIcon(dynamic icon) {
    if (icon is String && icon.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: CachedNetworkImage(
          imageUrl: icon,
          width: 24.0,
          height: 24.0,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          errorWidget:
              (context, url, error) => Icon(
                Icons.category_rounded,
                size: 24.0,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
    }

    return Icon(
      Icons.category_rounded,
      size: 24.0,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  // التنقل إلى فئة محددة
  void _navigateToCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriesScreen(initialCategory: category),
      ),
    );
  }

  // قسم أحدث العقارات
  Widget _buildApartmentsSection() {
    if (_isLoading) {
      return _buildApartmentsLoadingSection();
    }

    if (_latestApartments.isEmpty) {
      return _buildEmptyApartmentsSection();
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        scrollDirection: Axis.horizontal,
        itemCount: _latestApartments.length,
        itemBuilder: (context, index) {
          final apartment = _latestApartments[index];
          return Container(
            width: 260,
            margin: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 10.0),
            child: PropertyCardWidget(
              apartment: apartment,
              showFavoriteButton: true,
            ),
          );
        },
      ),
    );
  }

  // واجهة تحميل العقارات
  Widget _buildApartmentsLoadingSection() {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 260,
            margin: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 10.0),
            child: _buildPropertyShimmerCard(),
          );
        },
      ),
    );
  }

  // واجهة عندما لا توجد عقارات
  Widget _buildEmptyApartmentsSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.07),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [
                    theme.colorScheme.surface.withOpacity(0.8),
                    theme.colorScheme.surface,
                  ]
                  : [Colors.white, theme.colorScheme.surface.withOpacity(0.05)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? theme.colorScheme.primary.withOpacity(0.12)
                        : theme.colorScheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 46,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد عقارات متاحة حالياً',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                await _fetchLatestApartments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة تحميل العقار
  Widget _buildPropertyShimmerCard() {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
      highlightColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة متلألئة
            Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.white,
              ),
            ),

            // معلومات متلألئة
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان المتلألئ
                  Container(width: 150, height: 20, color: Colors.white),

                  const SizedBox(height: 10),

                  // الموقع المتلألئ
                  Container(width: 200, height: 14, color: Colors.white),

                  const SizedBox(height: 15),

                  // المميزات المتلألئة
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // قسم العقارات المميزة
  Widget _buildFeaturedPropertiesSection() {
    if (_isFeaturedLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      'العقارات المميزة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(
                    left: 6.0,
                    right: 6.0,
                    bottom: 10.0,
                  ),
                  child: _buildPropertyShimmerCard(),
                );
              },
            ),
          ),
        ],
      );
    }

    if (_featuredProperties.isEmpty) {
      return const SizedBox.shrink(); // لا نظهر القسم إذا لم توجد عقارات مميزة
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    'العقارات المميزة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            scrollDirection: Axis.horizontal,
            itemCount: _featuredProperties.length,
            itemBuilder: (context, index) {
              final property = _featuredProperties[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(
                  left: 6.0,
                  right: 6.0,
                  bottom: 10.0,
                ),
                child: PropertyCardWidget(
                  apartment: property,
                  showFavoriteButton: true,
                  isCompact: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // قسم الأماكن المتاحة
  Widget _buildAvailablePlacesSection() {
    if (_isAvailablePlacesLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      'الأماكن المتاحة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_city,
                        size: 18,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(
                    left: 6.0,
                    right: 6.0,
                    bottom: 10.0,
                  ),
                  child: _buildPlaceShimmerCard(),
                );
              },
            ),
          ),
        ],
      );
    }

    if (_availablePlaces.isEmpty) {
      return const SizedBox.shrink(); // لا نظهر القسم إذا لم توجد أماكن
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(
                        scrollToAvailablePlaces: true,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                label: Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'الأماكن المتاحة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_city,
                      size: 18,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            scrollDirection: Axis.horizontal,
            itemCount: _availablePlaces.length,
            itemBuilder: (context, index) {
              // احسب الفهرس المعكوس للعرض من اليمين إلى اليسار
              final reverseIndex = _availablePlaces.length - 1 - index;
              final place = _availablePlaces[reverseIndex];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(
                  left: 6.0,
                  right: 6.0,
                  bottom: 10.0,
                ),
                child: _buildPlaceCard(place),
              );
            },
          ),
        ),
      ],
    );
  }

  // بناء بطاقة المكان
  Widget _buildPlaceCard(dynamic place) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.grey[850]!.withOpacity(0.95),
                  Colors.grey[900]!.withOpacity(0.9),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!.withOpacity(0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : theme.colorScheme.tertiary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.tertiary.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailsScreen(place: place),
              ),
            );
          },
          child: Column(
            children: [
              // أيقونة المكان
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.tertiary.withOpacity(0.15),
                        theme.colorScheme.tertiary.withOpacity(0.08),
                      ],
                    ),
                  ),
                  child: Center(
                    child: place.iconUrl != null && place.iconUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: place.iconUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.location_city,
                              size: 40,
                              color: theme.colorScheme.tertiary,
                            ),
                          )
                        : Icon(
                            Icons.location_city,
                            size: 40,
                            color: theme.colorScheme.tertiary,
                          ),
                  ),
                ),
              ),
              
              // اسم المكان
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
                ),
                child: Text(
                  place.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.tertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بطاقة تحميل المكان
  Widget _buildPlaceShimmerCard() {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
      highlightColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // منطقة الأيقونة
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            
            // شريط الاسم
            Container(
              width: double.infinity,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // قسم "لماذا نحن"
  Widget _buildWhyChooseUsSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // قائمة المميزات
    final List<_Feature> features = [
      _Feature(
        title: 'جودة عالية',
        description: 'نقدم لك أفضل العقارات بأعلى معايير الجودة',
        icon: Icons.grade_rounded,
        color: Colors.amber,
      ),
      _Feature(
        title: 'أسعار تنافسية',
        description: 'أسعارنا مناسبة لكافة الميزانيات',
        icon: Icons.attach_money_rounded,
        color: Colors.green,
      ),
      _Feature(
        title: 'موقع ممتاز',
        description: 'عقاراتنا تقع في أفضل المناطق',
        icon: Icons.location_on_rounded,
        color: Colors.redAccent,
      ),
      _Feature(
        title: 'أمان وخصوصية',
        description: 'نوفر بيئة آمنة وخاصة لجميع العملاء',
        icon: Icons.security_rounded,
        color: Colors.indigo,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? theme.colorScheme.surface.withOpacity(0.5)
                : theme.colorScheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDarkMode
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.primary.withOpacity(0.05),
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // العنوان
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'لماذا نحن الخيار الأفضل',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // المميزات
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? theme.cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: feature.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          feature.icon,
                          color: feature.color,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature.description,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // قسم تواصل معنا
  Widget _buildContactUsSection() {
    final theme = Theme.of(context);

    // وسائل التواصل الاجتماعي
    final socialMedia = [
      {
        'icon': FontAwesomeIcons.whatsapp,
        'color': const Color(0xFF25D366),
        'url': 'https://wa.me/+201093130120',
      },
      {
        'icon': FontAwesomeIcons.facebook,
        'color': const Color(0xFF1877F2),
        'url': 'https://www.facebook.com/elsahm.arish',
      },
      {
        'icon': FontAwesomeIcons.envelope,
        'color': const Color(0xFFEA4335),
        'url': 'mailto:elsahm.arish@gmail.com',
      },
      {
        'icon': FontAwesomeIcons.phone,
        'color': const Color(0xFF34B7F1),
        'url': 'tel:+201093130120',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [theme.colorScheme.secondary, theme.colorScheme.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'تواصل معنا',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'نحن هنا لمساعدتك في العثور على العقار المناسب',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // أزرار وسائل التواصل الاجتماعي
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                socialMedia.map((social) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: InkWell(
                      onTap: () async {
                        try {
                          final url = social['url'] as String;
                          final Uri uri = Uri.parse(url);

                          if (kDebugMode) {
                            _logger.info('محاولة فتح الرابط: $url');
                          }

                          if (await canLaunchUrl(uri)) {
                            final bool launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );

                            if (!launched) {
                              throw 'فشل في فتح الرابط';
                            }

                            if (kDebugMode) {
                              _logger.info('تم فتح الرابط بنجاح: $url');
                            }
                          } else {
                            throw 'لا يمكن فتح هذا النوع من الروابط';
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            _logger.warning('خطأ في فتح رابط التواصل: $e');
                          }

                          if (mounted) {
                            _showCenteredTextMessage(
                              'لا يمكن فتح الرابط. تأكد من وجود التطبيق المناسب.',
                              isError: true,
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: FaIcon(
                            social['icon'] as IconData,
                            color: social['color'] as Color,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // قسم معلومات المصمم
  Widget _buildDesignerInfoSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // وسائل التواصل الاجتماعي الجديدة
    final socialMedia = [
      {
        'icon': FontAwesomeIcons.phone,
        'color': const Color(0xFF34B7F1),
        'url': 'tel:+201003193622',
      },
      {
        'icon': FontAwesomeIcons.whatsapp,
        'color': const Color(0xFF25D366),
        'url': 'https://wa.me/+201003193622',
      },
      {
        'icon': FontAwesomeIcons.facebook,
        'color': const Color(0xFF1877F2),
        'url': 'https://www.facebook.com/eslammosalah',
      },
      {
        'icon': FontAwesomeIcons.instagram,
        'color': const Color(0xFFE4405F),
        'url': 'https://www.instagram.com/eslamz11',
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // إطار الصورة الاحترافي
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.5),
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                'assets/images/Eslam_Zayed.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تطوير وتصميم',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Eng : Eslam Zayed',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // وسائل التواصل الاجتماعي المحدثة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                socialMedia.map((social) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      onTap: () async {
                        try {
                          final url = social['url'] as String;
                          final Uri uri = Uri.parse(url);

                          if (kDebugMode) {
                            _logger.info('محاولة فتح الرابط: $url');
                          }

                          if (await canLaunchUrl(uri)) {
                            final bool launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );

                            if (!launched) {
                              throw 'فشل في فتح الرابط';
                            }

                            if (kDebugMode) {
                              _logger.info('تم فتح الرابط بنجاح: $url');
                            }
                          } else {
                            throw 'لا يمكن فتح هذا النوع من الروابط';
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            _logger.warning('خطأ في فتح رابط التواصل: $e');
                          }

                          if (mounted) {
                            _showCenteredTextMessage(
                              'لا يمكن فتح الرابط. تأكد من وجود التطبيق المناسب.',
                              isError: true,
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(21),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: (social['color'] as Color).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: FaIcon(
                            social['icon'] as IconData,
                            color: social['color'] as Color,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} السهم - جميع الحقوق محفوظة',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // دالة جلب بيانات تحديث التطبيق
  Future<void> _fetchAppUpdate({bool silent = false}) async {
    if (!mounted) return;

    try {
      if (!silent) {
        setState(() {
          _isUpdateLoading = true;
        });
      }

      final update = await _updateService.getLatestUpdate();

      if (!mounted) return;

      if (kDebugMode) {
        _logger.info(
          'تم جلب بيانات التحديث: ${update != null ? 'متاح' : 'غير متاح'}',
        );
      }

      setState(() {
        _appUpdate = update;
        if (!silent) {
          _isUpdateLoading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        _logger.warning('خطأ في جلب بيانات التحديث: $e');
      }

      setState(() {
        if (!silent) {
          _isUpdateLoading = false;
        }
      });
    }
  }

  // قسم تحديث التطبيق
  Widget _buildAppUpdateSection() {
    // لا نعرض القسم إذا كان التحديث قيد التحميل أو غير متاح أو غير نشط
    if (_isUpdateLoading || _appUpdate == null || !_appUpdate!.isActive) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(int.parse('0xFF${_appUpdate!.primaryColor ?? '3498db'}')),
            Color(int.parse('0xFF${_appUpdate!.secondaryColor ?? '2980b9'}')),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(
              int.parse('0xFF${_appUpdate!.primaryColor ?? '3498db'}'),
            ).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // عناصر زخرفية في الخلفية
          Positioned(
            right: -15,
            top: -15,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // الأيقونة المتحركة
          Positioned(
            left: 15,
            top: 10,
            child: Transform.rotate(
              angle: 0.1,
              child: Icon(
                Icons.system_update,
                size: 28,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // أيقونة التحديث
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // نص التحديث
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'v${_appUpdate!.version}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تحديث جديد متاح!',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _appUpdate!.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // زر التحميل
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final url = _appUpdate!.downloadUrl;

                      if (kDebugMode) {
                        _logger.info('محاولة فتح الرابط: $url');
                      }

                      // التأكد من أن الرابط يحتوي على بروتوكول
                      final Uri uri = Uri.parse(
                        url.startsWith('http') ? url : 'https://$url',
                      );

                      // استخدام الطرق الحديثة للتحقق وفتح الروابط
                      if (await canLaunchUrl(uri)) {
                        final bool launched = await launchUrl(
                          uri,
                          mode:
                              LaunchMode
                                  .externalApplication, // إجبار الفتح في متصفح خارجي
                        );

                        if (!launched) {
                          throw 'فشل في فتح الرابط';
                        }
                      } else {
                        throw 'لا يمكن فتح هذا النوع من الروابط';
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        _logger.severe('خطأ في فتح رابط التحديث: $e');
                      }
                      _showCenteredTextMessage(
                        'لا يمكن فتح رابط التحديث',
                        isError: true,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(
                      int.parse('0xFF${_appUpdate!.primaryColor ?? '3498db'}'),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'تحميل',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
