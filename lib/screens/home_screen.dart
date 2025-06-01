import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart'; // Ensure no 'hide' directive here
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart'
    as cs; // Import with prefix 'cs'
import 'package:shimmer/shimmer.dart'; // Import shimmer package
import 'package:logging/logging.dart'; // Import logging package
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome for social icons
import 'package:url_launcher/url_launcher.dart'; // Import for URL launching
import 'package:auto_size_text/auto_size_text.dart'; // Import for auto-resizing text
import 'package:marquee_widget/marquee_widget.dart'; // Import for marquee text effect
import '../providers/navigation_provider.dart';
import '../providers/favorites_provider.dart'; // Import FavoritesProvider
import '../models/apartment.dart'; // Import the Apartment model
import '../models/banner.dart' as app_banner; // Import Banner model with prefix
import '../services/category_service.dart'; // Import CategoryService
import '../services/banner_service.dart'; // Import BannerService
import '../services/property_service_supabase.dart'; // Import PropertyServiceSupabase
import '../screens/categories_screen.dart'; // Import CategoriesScreen
import '../widgets/typewriter_animated_text.dart'; // Import the TypewriterAnimatedText widget
import '../widgets/cropped_network_image.dart'; // Import the cropped network image widget
import 'apartments_list_screen.dart'; // Import the apartments list screen
import 'property_details_screen.dart'; // Import the property details screen
import '../providers/auth_provider.dart'; // Importar AuthProvider
import '../utils/auth_utils.dart'; // Importar AuthUtils
import '../services/firestore_service.dart'; // Import FirestoreService
import '../screens/why_choose_us_screen.dart'; // Import WhyChooseUsScreen
import '../screens/login_screen.dart'; // Import LoginScreen
import 'featured_properties_screen.dart'; // إضافة استيراد للشاشة الجديدة

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

// جمل النص المتحرك - تم تقليلها إلى جملتين فقط
const List<String> animatedTexts = [
  "أكثر من 5 سنوات من الخبرة في خدمة الطلاب",
  " أسعار تنافسية تناسب كل الميزانيات",
  "مستوى عالٍ من الأمان والخصوصية",
  "بيئة آمنة وهادئة تساعدك على التركيز والدراسة",
  "دعم فني  متواصل لضمان راحتك",
  " احجز مكانك الآن قبل نفاد الأماكن!",
];

// Fallback banner images (for offline or error cases)
final List<String> fallbackBannerImages = [
  'assets/images/banners/banner1.png',
  'assets/images/banners/banner2.png',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // المتغيرات الثابتة والخدمات
  final PropertyServiceSupabase _propertyService = PropertyServiceSupabase();
  final CategoryService _categoryService = CategoryService();
  final BannerService _bannerService = BannerService();

  // متغيرات الحالة
  List<app_banner.Banner> _banners = [];
  List<Map<String, dynamic>> _categories = [];
  List<Apartment> _latestApartments = [];
  List<Apartment> _featuredProperties = []; // قائمة جديدة للعقارات المميزة
  bool _isLoading = true;
  bool _isCategoriesLoading = true;
  bool _isFeaturedLoading = true; // متغير جديد لحالة تحميل العقارات المميزة
  int _currentBannerIndex = 0;

  // استريم لمراقبة التغييرات في الشقق
  StreamSubscription<List<Apartment>>? _apartmentsStreamSubscription;

  @override
  void initState() {
    super.initState();
    // استخدام Future.microtask لإتاحة وقت للشاشة للبناء أولاً
    Future.microtask(() async {
      // جلب البانرات
      await _fetchBanners();

      // جلب الفئات أولاً لأنها أقل في الحجم
      await _fetchCategories();

      // ثم جلب الشقق
      await _fetchLatestApartments();

      // جلب العقارات المميزة
      await _fetchFeaturedProperties();

      // إعداد المستمع للتغييرات بعد تحميل البيانات الأولية
      _setupApartmentsListener();
    });
  }

  @override
  void dispose() {
    _apartmentsStreamSubscription?.cancel();
    super.dispose();
  }

  // Kept for future use but renamed to avoid unused warning
  @pragma('vm:prefer-inline')
  Color getTextColor(String colorString, bool isDarkMode) {
    // Basic mapping based on provided Tailwind-like classes
    // This needs refinement based on your actual theme colors
    if (isDarkMode) {
      switch (colorString) {
        case "text-blue-400":
          return Colors.blue[300]!;
        case "text-green-400":
          return Colors.green[300]!;
        case "text-purple-400":
          return Colors.purple[300]!;
        case "text-teal-400":
          return Colors.teal[300]!;
        case "text-orange-400":
          return Colors.orange[300]!;
        case "text-indigo-400":
          return Colors.indigo[300]!;
        case "text-pink-400":
          return Colors.pink[300]!;
        default:
          return Colors.white70;
      }
    } else {
      switch (colorString) {
        case "text-blue-600":
          return Colors.blue[700]!;
        case "text-green-600":
          return Colors.green[700]!;
        case "text-purple-600":
          return Colors.purple[700]!;
        case "text-teal-600":
          return Colors.teal[700]!;
        case "text-orange-600":
          return Colors.orange[700]!;
        case "text-indigo-600":
          return Colors.indigo[700]!;
        case "text-pink-600":
          return Colors.pink[700]!;
        default:
          return Colors.grey[700]!;
      }
    }
  }

  // دالة مساعدة للانتقال إلى صفحة الدردشة مع تأثير انتقال جميل - تم إزالتها

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 0),
          children: [
            // 1. Banner Carousel
            _buildBannerCarousel(),

            const SizedBox(height: 8.0),

            // 2. Typewriter Text Animation
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TypewriterAnimatedText(
                texts: animatedTexts,
                textStyle: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12.0),

            // Login promotion section - visible only when user is not logged in
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                // Show only if user is not authenticated
                if (!authProvider.isAuthenticated) {
                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 24.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          Color(0xFF0288D1), // A slightly lighter blue
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background decorative elements
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -15,
                          bottom: -15,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        // Content with improved responsive layout
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Determine if we need a compact layout
                              final bool isCompact = constraints.maxWidth < 350;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left section - Icon
                                  Container(
                                    width: isCompact ? 48 : 60,
                                    height: isCompact ? 48 : 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: isCompact ? 24 : 32,
                                    ),
                                  ),

                                  SizedBox(width: isCompact ? 12 : 20),

                                  // Middle section - Text with Expanded to ensure proper wrapping
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AutoSizeText(
                                          'سجل دخولك الآن',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 1,
                                          minFontSize: 14,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        AutoSizeText(
                                          'للوصول إلى مميزات حصرية',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                          maxLines: 2,
                                          minFontSize: 12,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: isCompact ? 10 : 16),

                                  // Right section - Login Button
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: colorScheme.primary,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isCompact ? 8 : 12,
                                        vertical: isCompact ? 10 : 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child:
                                        isCompact
                                            ? const Icon(Icons.login, size: 18)
                                            : const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.login, size: 18),
                                                SizedBox(width: 6),
                                                Text(
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
                  // Return empty container when user is logged in
                  return const SizedBox.shrink();
                }
              },
            ),

            // 3. Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Provider.of<NavigationProvider>(
                        context,
                        listen: false,
                      ).setIndex(2);
                    },
                    child: Text(
                      'عرض الكل',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'تصفح حسب الفئات',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),

            // بناء قسم التصنيفات - مع التحقق من حالة التحميل
            _buildCategoriesSection(),

            const SizedBox(height: 12.0),

            // 4. Recent Properties Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isLoading && _latestApartments.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ApartmentsListScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'عرض الكل',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    'أحدث العقارات',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),

            // بناء قسم الشقق - مع التحقق من حالة التحميل
            _buildApartmentsSection(),

            const SizedBox(height: 16.0),

            // 5. Featured Properties Section (العقارات المميزة)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // Navigate to featured properties screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const FeaturedPropertiesScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.arrow_back_ios,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            'المزيد',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'العقارات المميزة',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  SizedBox(
                    height: 240,
                    child:
                        !_isFeaturedLoading && _featuredProperties.isNotEmpty
                            ? ListView.builder(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                left: 16.0,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  _featuredProperties.length > 3
                                      ? 3
                                      : _featuredProperties.length,
                              itemBuilder: (context, index) {
                                final apartment = _featuredProperties[index];
                                return Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  margin: const EdgeInsets.only(right: 12.0),
                                  child: Stack(
                                    children: [
                                      _buildFeaturedPropertyCard(apartment),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                  77,
                                                ),
                                                spreadRadius: 1,
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'مميز',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                            : Center(
                              child:
                                  _isFeaturedLoading
                                      ? CircularProgressIndicator(
                                        color: theme.colorScheme.primary,
                                      )
                                      : Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.home_outlined,
                                              size: 48,
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.7),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'لا توجد عقارات مميزة متاحة حالياً',
                                              textAlign: TextAlign.center,
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.7),
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton(
                                              onPressed:
                                                  _fetchFeaturedProperties,
                                              child: Text('تحديث'),
                                            ),
                                          ],
                                        ),
                                      ),
                            ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            // 6. Why Choose Us Section (لماذا نحن الخيار الأفضل)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 16.0,
              ),
              margin: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                children: [
                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'لماذا نحن الخيار الأفضل',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8.0),

                  Text(
                    'نسعى دائماً لتقديم أفضل الخدمات العقارية في مدينة العريش',
                    style: textTheme.bodyMedium?.copyWith(
                      color:
                          theme.brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20.0),

                  // Features
                  _buildWhyChooseUsFeatures(),

                  const SizedBox(height: 16.0),

                  // View More Button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WhyChooseUsScreen(),
                        ),
                      );
                    },
                    icon: Text(
                      'عرض المزيد',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    label: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // 7. Contact Us Section (تواصل معنا)
            _buildContactUsSection(context),
          ],
        ),
      ),
    );
  }

  // دالة جديدة لبناء البانر بطريقة محسنة
  Widget _buildBannerCarousel() {
    // إذا كانت البانرات قيد التحميل، نعرض مؤشر تحميل
    if (_isLoading) {
      return Column(
        children: [
          _shimmerLoadingBanner(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.grey.withAlpha(102),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // تسجيل معلومات عن البانرات لتشخيص المشكلة
    if (kDebugMode) {
      final logger = Logger('HomeScreen');
      logger.info('عدد البانرات المحملة: ${_banners.length}');
      for (var banner in _banners) {
        logger.fine('بانر في الواجهة: ID=${banner.id}, URL=${banner.imageUrl}');
      }
    }

    // إذا لم تكن هناك بانرات، نستخدم الصور الاحتياطية ونضيف زر إعادة التحميل
    if (_banners.isEmpty) {
      final List<String> bannerSources = fallbackBannerImages;

      return Column(
        children: [
          Stack(
            children: [
              cs.CarouselSlider(
                options: cs.CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 20),
                  autoPlayAnimationDuration: const Duration(milliseconds: 600),
                  autoPlayCurve: Curves.easeInOutCubic,
                  enlargeCenterPage: true,
                  viewportFraction: 0.93,
                  aspectRatio: 1440 / 570,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentBannerIndex = index;
                    });
                  },
                ),
                items:
                    bannerSources
                        .map(
                          (item) => Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5.0,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(38),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: _shimmerBannerImage(imageAsset: item),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
              ),
            ],
          ),

          // مؤشرات البانر
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  bannerSources.asMap().entries.map((entry) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentBannerIndex == entry.key ? 18.0 : 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            .withAlpha(
                              _currentBannerIndex == entry.key
                                  ? 230
                                  : 102, // 0.9 * 255 = 230, 0.4 * 255 = 102
                            ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      );
    }

    // استخدام البانرات من Supabase
    final List<String> bannerSources =
        _banners.map((banner) => banner.imageUrl).toList();

    if (kDebugMode) {
      final logger = Logger('HomeScreen');
      logger.info('مصادر البانر: $bannerSources');
    }

    return Column(
      children: [
        Stack(
          children: [
            // تحسين تحميل البانر
            cs.CarouselSlider(
              options: cs.CarouselOptions(
                height: 200.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 20),
                autoPlayAnimationDuration: const Duration(milliseconds: 600),
                autoPlayCurve: Curves.easeInOutCubic,
                enlargeCenterPage: true,
                viewportFraction: 0.93,
                aspectRatio: 1440 / 570,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
              ),
              items:
                  bannerSources
                      .map(
                        (item) => Builder(
                          builder: (BuildContext context) {
                            // No need to get the banner object here

                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(38),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: _networkBannerImage(imageUrl: item),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
            ),
          ],
        ),

        // مؤشرات البانر
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                bannerSources.asMap().entries.map((entry) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentBannerIndex == entry.key ? 18.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withAlpha(
                            _currentBannerIndex == entry.key ? 230 : 102,
                          ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // دالة لبناء قسم التصنيفات
  Widget _buildCategoriesSection() {
    if (_isCategoriesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 3.0, // زيادة النسبة لإتاحة مساحة أكبر للنص
      ),
      itemCount: _categories.length > 6 ? 6 : _categories.length,
      itemBuilder: (context, index) {
        // حساب الفهرس المعكوس ليكون الترتيب من اليمين إلى اليسار
        final crossAxisCount = 2; // عدد الأعمدة ثابت هنا (2)
        final rowIndex = index ~/ crossAxisCount; // صف العنصر الحالي
        final rowStartIndex = rowIndex * crossAxisCount; // بداية الصف الحالي
        final reverseIndex =
            rowStartIndex + crossAxisCount - 1 - (index % crossAxisCount);

        // التأكد من أن الفهرس المعكوس في نطاق مقبول
        final maxIndex = _categories.length > 6 ? 6 : _categories.length;
        final safeIndex = reverseIndex < maxIndex ? reverseIndex : index;

        final category = _categories[safeIndex];
        return _buildCategoryCard(
          context,
          category['iconUrl'] ?? category['icon'],
          category['label'] as String,
        );
      },
    );
  }

  // دالة لبناء قسم الشقق
  Widget _buildApartmentsSection() {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_latestApartments.isEmpty) {
      final theme = Theme.of(context);
      final isDarkMode = theme.brightness == Brightness.dark;

      return Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? theme.colorScheme.surface.withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.apartment_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'لا توجد عقارات متاحة حالياً',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: () async {
                    // عرض مؤشر تقدم داخل الزر أثناء عملية التحديث
                    setState(() {
                      _isLoading = true;
                    });

                    // تحديث البيانات
                    await _fetchLatestApartments();

                    // إظهار رسالة نجاح
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('تم تحديث البيانات بنجاح'),
                          backgroundColor: theme.colorScheme.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('تحديث الآن'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 290,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: _latestApartments.length,
        itemBuilder: (context, index) {
          final apartment = _latestApartments[index];
          return Container(
            width: 240,
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildPropertyCard(apartment),
          );
        },
      ),
    );
  }

  // --- Helper Widgets --- (Keep existing helpers)
  Widget _buildCategoryCard(BuildContext context, dynamic icon, String label) {
    final theme = Theme.of(context);

    // التحقق من طول النص لتحديد ما إذا كان يحتاج إلى تأثير التمرير
    final bool isLongText = label.length > 7;

    return Card(
      margin: const EdgeInsets.all(4.0),
      elevation: 2.0,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          _selectCategory(label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // الأيقونة بحجم ثابت وموحد
              Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child:
                      icon is String && icon.startsWith('http')
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              icon,
                              width: 24.0,
                              height: 24.0,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.category,
                                    size: 24.0,
                                    color: Colors.blue,
                                  ),
                            ),
                          )
                          : Icon(
                            Icons.category,
                            size: 24.0,
                            color: theme.colorScheme.primary,
                          ),
                ),
              ),

              const SizedBox(width: 12.0), // مسافة موحدة بين الأيقونة والنص
              // النص بتنسيق وحجم ثابت
              Expanded(
                child: Container(
                  height: 22.0, // ارتفاع ثابت للنص
                  alignment: Alignment.centerRight, // دائمًا محاذاة لليمين
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
                                fontSize: 15.0, // حجم خط ثابت
                              ),
                            ),
                          )
                          : Text(
                            label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.0, // حجم خط ثابت
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

  // دالة لاختيار قسم معين
  void _selectCategory(String category) {
    if (kDebugMode) {
      print('تم اختيار القسم: $category');
    }

    // الانتقال مباشرة إلى شاشة القسم بدون تطبيق الفلتر في الصفحة الرئيسية
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriesScreen(initialCategory: category),
      ),
    );
  }

  Widget _buildPropertyCard(Apartment apartment) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PropertyDetailsScreen(
                  property: apartment,
                  fromCategoriesScreen: false,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.black.withAlpha(77) // ~0.3 opacity
                      : Colors.grey.withAlpha(38), // ~0.15 opacity
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة العقار - بعرض كامل للبطاقة
            Stack(
              children: [
                // صورة العقار
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: _buildOptimizedImageCarousel(
                      apartment.imageUrls.isNotEmpty
                          ? apartment.imageUrls[0]
                          : '',
                    ),
                  ),
                ),

                // شريط السعر
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // سعر العقار بالجنيه المصري
                          Text(
                            '${apartment.price.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          // حالة العقار
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  apartment.isAvailable
                                      ? Colors.green
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              apartment.isAvailable ? 'متاح' : 'غير متاح',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // نوع العقار
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? const Color(0xFF2A2A2A)
                              : Colors.white.withAlpha(230), // 0.9 opacity
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26), // 0.1 opacity
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, _) {
                        final isFavorite = favoritesProvider.isFavorite(
                          apartment.id,
                        );
                        return InkWell(
                          onTap: () async {
                            // Verificar si el usuario está autenticado
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            if (!authProvider.isAuthenticated) {
                              // Mostrar diálogo de autenticación requerida si no está autenticado
                              AuthUtils.showAuthRequiredDialog(context);
                              return;
                            }

                            // El usuario está autenticado, continuar con la operación
                            try {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              final isNowFavorite = await favoritesProvider
                                  .toggleFavorite(apartment);
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isNowFavorite
                                          ? 'تم إضافة ${apartment.name} إلى المفضلة'
                                          : 'تم إزالة ${apartment.name} من المفضلة',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (kDebugMode) {
                                final logger = Logger('HomeScreen');
                                logger.warning('Error toggling favorite: $e');
                              }
                            }
                          },
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color:
                                isFavorite
                                    ? Colors.red
                                    : isDarkMode
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            // معلومات العقار
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم العقار
                  Text(
                    apartment.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // العنوان
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          apartment.location,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // مواصفات العقار
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? theme.colorScheme.surface.withValues(alpha: 0.3)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // عدد الغرف
                        _buildFeatureWithCard(
                          Icons.bedroom_parent_outlined,
                          '${apartment.rooms} غرفة',
                        ),

                        // عدد الأسرّة
                        _buildFeatureWithCard(
                          Icons.king_bed_outlined,
                          '${apartment.bedrooms} سرير',
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
    );
  }

  // دالة لإنشاء وحدة معلومات بشكل أكثر جاذبية
  Widget _buildFeatureWithCard(IconData icon, String text) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color:
                  isDarkMode
                      ? theme.textTheme.bodyMedium?.color
                      : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // وظائف المساعدة للصور
  Widget _buildDefaultPropertyImage(ImageProvider? placeholderImage) {
    return Image.asset(
      'assets/images/placeholder_property.png',
      fit: BoxFit.cover,
      height: 220.0,
      errorBuilder:
          (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.home_outlined,
              size: 50,
              color: Colors.grey,
            ),
          ),
    );
  }

  Widget _buildImagePlaceholder(ImageProvider? placeholderImage) {
    return Container(
      color: Colors.grey[200],
      height: 220.0,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // وظيفة بناء عرض الصور بطريقة محسنة
  Widget _buildOptimizedImageCarousel(
    String imageUrl, {
    ImageProvider? placeholderImage,
  }) {
    return imageUrl.isEmpty
        ? _buildDefaultPropertyImage(placeholderImage)
        : CroppedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          bottomCropPercentage: 0.08,
          height: 220.0,
          placeholder: _buildImagePlaceholder(placeholderImage),
          errorWidget: _buildDefaultPropertyImage(placeholderImage),
        );
  }

  Future<void> _fetchLatestApartments() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // تسجيل حالة الاتصال الحالية
      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.info('بدء جلب العقارات الأخيرة...');
      }

      // محاولة مسح التخزين المؤقت قبل جلب البيانات الجديدة
      _propertyService.clearCache(key: 'latest_properties');
      _propertyService.clearCache(key: 'available_properties');

      // جلب الشقق من Supabase
      List<Apartment> apartments = [];

      try {
        // جلب أحدث العقارات بدون أي فلتر
        apartments = await _propertyService.getLatestProperties(limit: 10);
      } catch (innerError) {
        if (kDebugMode) {
          final logger = Logger('HomeScreen');
          logger.severe('خطأ في جلب العقارات: $innerError');
        }
        // في حالة الفشل، نحاول مرة أخرى بطريقة أخرى
        apartments = await _propertyService.getAvailableProperties(limit: 10);
      }

      if (!mounted) return;

      // تسجيل معلومات الشقق للتشخيص
      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        if (apartments.isEmpty) {
          logger.warning('لم يتم جلب أي شقق!');
        } else {
          logger.info('تم جلب ${apartments.length} شقة');

          for (var apartment in apartments) {
            logger.fine(
              'شقة: ${apartment.name}, صور: ${apartment.imageUrls.length}, متاحة: ${apartment.isAvailable}',
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _latestApartments.clear();
          _latestApartments = apartments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.severe('خطأ عام في جلب الشقق: $e');
      }

      // حتى في حالة الخطأ، نريد إنهاء حالة التحميل
      setState(() {
        _isLoading = false;
      });

      // عرض رسالة خطأ للمستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'حدث خطأ أثناء تحميل البيانات، يرجى المحاولة مرة أخرى لاحقًا',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;

    try {
      setState(() {
        _isCategoriesLoading = true;
      });

      final categories = await _categoryService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isCategoriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCategoriesLoading = false;
      });

      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.severe('خطأ في جلب الفئات: $e');
      }
    }
  }

  void _setupApartmentsListener() {
    // إلغاء الاشتراك السابق إن وجد
    _apartmentsStreamSubscription?.cancel();

    // استخدام منطق تأخير ديناميكي بناءً على توفر العقارات
    final Duration updateInterval =
        _latestApartments.isEmpty
            ? const Duration(
              minutes: 1,
            ) // إذا لم تكن هناك عقارات، نحاول تحديثها كل دقيقة
            : const Duration(
              minutes: 10,
            ); // إذا كانت هناك عقارات، نحاول تحديثها كل 10 دقائق

    if (kDebugMode) {
      final logger = Logger('HomeScreen');
      logger.info(
        'إعداد مستمع تحديث العقارات مع فاصل زمني: ${updateInterval.inMinutes} دقيقة',
      );
    }

    Timer.periodic(updateInterval, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        await _fetchLatestApartments();

        // تكييف الفاصل الزمني بناءً على النتائج
        if (_latestApartments.isNotEmpty && updateInterval.inMinutes < 10) {
          timer.cancel();
          // إعادة إعداد المستمع بفاصل زمني أطول
          _setupApartmentsListener();
        }
      } catch (e) {
        if (kDebugMode) {
          final logger = Logger('HomeScreen');
          logger.warning('فشل التحديث التلقائي للعقارات: $e');
        }
        // لا نقوم بإلغاء المؤقت، دعه يحاول مرة أخرى في المرة القادمة
      }
    });
  }

  // دالة لجلب البانرات من Supabase
  Future<void> _fetchBanners() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.info('بدء تحميل البانرات من Supabase...');
      }

      final banners = await _bannerService.getBanners();

      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.info('تم استلام ${banners.length} بانرات من Supabase');
      }

      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });

        // إذا كانت البانرات فارغة، نحاول مرة أخرى بعد تأخير قصير
        if (banners.isEmpty) {
          if (kDebugMode) {
            final logger = Logger('HomeScreen');
            logger.warning('لم يتم العثور على بانرات، محاولة إعادة التحميل...');
          }
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _tryFetchBannersAgain();
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.severe('خطأ في جلب البانرات: $e');
      }

      if (mounted) {
        setState(() {
          _banners = [];
          _isLoading = false;
        });
      }
    }
  }

  // محاولة جلب البانرات مرة أخرى
  Future<void> _tryFetchBannersAgain() async {
    if (kDebugMode) {
      final logger = Logger('HomeScreen');
      logger.info('محاولة جلب البانرات مرة أخرى...');
    }

    try {
      final banners = await _bannerService.getBanners();

      if (mounted) {
        setState(() {
          _banners = banners;
        });
        if (kDebugMode) {
          final logger = Logger('HomeScreen');
          logger.info('نتيجة المحاولة الثانية: ${banners.length} بانرات');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.severe('فشلت المحاولة الثانية: $e');
      }
    }
  }

  // تحديث جميع البيانات بما في ذلك بيانات المستخدم
  Future<void> _refreshAllData() async {
    if (!mounted) return;

    // Store context and providers before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // مسح التخزين المؤقت للخدمات
      _propertyService.clearCache();

      // تحديث العقارات
      await _fetchLatestApartments();

      // تحديث البانرات
      await _fetchBanners();

      // تحديث الفئات
      await _fetchCategories();

      // تحديث العقارات المميزة
      await _fetchFeaturedProperties();

      // تحديث بيانات المستخدم (سيؤدي إلى تحديث الرصيد في AppBar)
      if (authProvider.isAuthenticated) {
        // تحديث بيانات المستخدم من Firestore
        final firestoreService = FirestoreService();
        await firestoreService.refreshUserData(authProvider.user!.uid);

        if (kDebugMode) {
          final logger = Logger('HomeScreen');
          logger.info('تم تحديث بيانات المستخدم بما في ذلك الرصيد');
        }
      }

      // إعلام المستخدم بنجاح التحديث
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('تم تحديث البيانات بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.severe('خطأ أثناء تحديث البيانات: $e');
      }

      // إعلام المستخدم بفشل التحديث
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء تحديث البيانات'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Featured property card with improved design
  Widget _buildFeaturedPropertyCard(Apartment apartment) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(51),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PropertyDetailsScreen(
                    property: apartment,
                    fromCategoriesScreen: false,
                  ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image with gradient overlay
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child:
                      apartment.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: apartment.imageUrls[0],
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                          )
                          : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.home,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                ),

                // Gradient overlay for better text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(179),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Price tag
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${apartment.price.toInt()} جنيه',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Location
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        apartment.location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Property details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    apartment.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Features row - только два элемента: комнаты и кровати
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureChip(
                        icon: Icons.bedroom_parent_outlined,
                        label: '${apartment.rooms} غرف',
                        color: Colors.blue.shade100,
                        textColor: Colors.blue.shade800,
                      ),
                      _buildFeatureChip(
                        icon: Icons.bed,
                        label: '${apartment.bathrooms} سرير',
                        color: Colors.purple.shade100,
                        textColor: Colors.purple.shade800,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Feature chip with improved design
  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build Why Choose Us features
  Widget _buildWhyChooseUsFeatures() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final features = [
      _Feature(
        title: 'خبرة تثق بها',
        description:
            'نعرف سوق العريش من الداخل، ونوجهك بكل دقة نحو الخيار الأنسب لك.',
        icon: Icons.verified_user_outlined,
        color: Colors.blue,
      ),
      _Feature(
        title: 'تشكيلة مميزة',
        description:
            'شقق، محلات، ومساحات استثمارية تناسب كل الأذواق والميزانيات.',
        icon: Icons.apps,
        color: Colors.orange,
      ),
      _Feature(
        title: 'سرعة واحترافية',
        description: 'نلبي طلبك بسرعة واحترافية تستحقها.',
        icon: Icons.speed_outlined,
        color: Colors.green,
      ),
    ];

    return Column(
      children:
          features.map((feature) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: feature.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(feature.icon, color: feature.color, size: 24),
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
                          const SizedBox(height: 6),
                          Text(
                            feature.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  // Contact Us Section Widget
  Widget _buildContactUsSection(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section with gradient
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.contact_phone_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تواصل معنا',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'فريقنا جاهز لمساعدتك!',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contact options
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Contact cards
                _buildContactOption(
                  icon: Icons.phone,
                  title: 'اتصل بنا',
                  subtitle: '01093130120',
                  iconColor: Colors.green,
                  onTap: () => _launchURL('tel:01093130120'),
                ),

                const SizedBox(height: 12),

                _buildContactOption(
                  icon: FontAwesomeIcons.whatsapp,
                  title: 'واتساب',
                  subtitle: '+201093130120',
                  iconColor: const Color(0xFF25D366), // WhatsApp green
                  onTap: () => _launchURL('https://wa.me/201093130120'),
                ),

                const SizedBox(height: 12),

                _buildContactOption(
                  icon: FontAwesomeIcons.facebook,
                  title: 'فيسبوك',
                  subtitle: 'تابعنا على فيسبوك',
                  iconColor: const Color(0xFF1877F2), // Facebook blue
                  onTap:
                      () => _launchURL('https://www.facebook.com/elsahm.arish'),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
          ),

          // Designer info
          _buildPremiumDesignerCard(),
        ],
      ),
    );
  }

  // Method to launch URLs
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (kDebugMode) {
        print('Could not launch $url: $e');
      }
    }
  }

  // Contact option card widget
  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shimmer loading banner for placeholder
  Widget _shimmerLoadingBanner() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 200.0,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
    );
  }

  // Shimmer banner image for fallback banners
  Widget _shimmerBannerImage({required String imageAsset}) {
    return Image.asset(
      imageAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            color: Colors.white,
            width: double.infinity,
            height: 200.0,
          ),
        );
      },
    );
  }

  // Network banner image with shimmer loading effect
  Widget _networkBannerImage({required String imageUrl}) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          ),
      errorWidget: (context, url, error) {
        if (kDebugMode) {
          print('Error loading banner image: $error');
        }
        return Image.asset(
          'assets/images/banners/banner1.png',
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
        );
      },
    );
  }

  // A new premium designer card with modern style - smaller version
  Widget _buildPremiumDesignerCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors:
              isDark
                  ? [const Color(0xFF1A1F38), const Color(0xFF0D1321)]
                  : [const Color(0xFFF8FBFF), const Color(0xFFF0F7FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color:
              isDark
                  ? Colors.blue.shade800.withValues(alpha: 0.2)
                  : Colors.blue.shade300.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top section with blue gradient - reduced height
          Container(
            height: 80, // Reduced from 110
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF0288D1), const Color(0xFF0277BD)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Stack(
              children: [
                // Decorative elements - made smaller
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: 70, // Reduced from 100
                    height: 70, // Reduced from 100
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -10,
                  left: -10,
                  child: Container(
                    width: 40, // Reduced from 60
                    height: 40, // Reduced from 60
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Title content - simplified and centered
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    25,
                    0,
                  ), // تقليل تباعد الأعلى من 18 إلى 12
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.code,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تصميم وتطوير',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile information with reduced spacing
          SizedBox(
            height: 100, // Reduced from 110 to fix overflow
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Profile image - made smaller and positioned higher
                Positioned(
                  top: -30, // Moved higher up (تم تعديلها من -35 إلى -30)
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1F38) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0277BD).withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.asset(
                        'assets/images/Eslam_Zayed.jpg',
                        width: 70, // Reduced from 90
                        height: 70, // Reduced from 90
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color:
                                  isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                color: theme.colorScheme.primary,
                                size: 30,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),

                // Text elements - repositioned
                Positioned(
                  top: 45,
                  child: Column(
                    children: [
                      // Name
                      Text(
                        'م. اسلام زايد',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF0D47A1),
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Badge with profession
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0288D1),
                              const Color(0xFF0277BD),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0277BD,
                              ).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'مطور ومصمم تطبيقات',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 11, // Reduced from 13
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Social media buttons - smaller size and closer together
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCompactSocialButton(
                  icon: FontAwesomeIcons.phone,
                  gradient: const [Color(0xFF4CAF50), Color(0xFF388E3C)],
                  onTap: () => _launchURL('tel:01003193622'),
                ),
                const SizedBox(width: 12), // Reduced spacing
                _buildCompactSocialButton(
                  icon: FontAwesomeIcons.whatsapp,
                  gradient: const [Color(0xFF25D366), Color(0xFF128C7E)],
                  onTap: () => _launchURL('https://wa.me/201003193622'),
                ),
                const SizedBox(width: 12), // Reduced spacing
                _buildCompactSocialButton(
                  icon: FontAwesomeIcons.facebook,
                  gradient: const [Color(0xFF1877F2), Color(0xFF1554AF)],
                  onTap:
                      () => _launchURL('https://www.facebook.com/eslammosalah'),
                ),
                const SizedBox(width: 12), // Reduced spacing
                _buildCompactSocialButton(
                  icon: FontAwesomeIcons.instagram,
                  gradient: const [Color(0xFFE1306C), Color(0xFF833AB4)],
                  onTap:
                      () => _launchURL('https://www.instagram.com/eslamz11/'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Smaller social media button for the compact designer card
  Widget _buildCompactSocialButton({
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38, // Reduced from 50
        height: 38, // Reduced from 50
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: Colors.white,
            size: 18, // Reduced from 22
          ),
        ),
      ),
    );
  }

  // جلب العقارات المميزة
  Future<void> _fetchFeaturedProperties() async {
    if (!mounted) return;

    try {
      setState(() {
        _isFeaturedLoading = true;
      });

      // تسجيل حالة الاتصال الحالية
      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.info('بدء جلب العقارات المميزة...');
      }

      // محاولة مسح التخزين المؤقت قبل جلب البيانات الجديدة
      _propertyService.clearCache(key: 'featured_properties');

      // جلب الشقق المميزة من Supabase
      final properties = await _propertyService.getFeaturedProperties(
        limit: 10,
      );

      if (!mounted) return;

      // تسجيل معلومات الشقق للتشخيص
      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        if (properties.isEmpty) {
          logger.warning('لم يتم جلب أي عقارات مميزة!');
        } else {
          logger.info('تم جلب ${properties.length} عقار مميز');
        }
      }

      if (mounted) {
        setState(() {
          _featuredProperties = properties;
          _isFeaturedLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        final logger = Logger('HomeScreen');
        logger.severe('خطأ عام في جلب العقارات المميزة: $e');
      }

      // حتى في حالة الخطأ، نريد إنهاء حالة التحميل
      setState(() {
        _isFeaturedLoading = false;
      });
    }
  }
}
