import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/apartment.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/auth_utils.dart';
import '../screens/checkout_screen.dart';
import 'main_navigation_screen.dart';

//  Create a Property model in lib/models/property.dart

class PropertyDetailsScreen extends StatefulWidget {
  final dynamic property;
  final bool fromCategoriesScreen;
  final bool fromMainScreen;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
    this.fromCategoriesScreen = false,
    this.fromMainScreen = false,
  });

  // Constructor that takes an Apartment object
  const PropertyDetailsScreen.fromApartment({
    super.key,
    required Apartment apartment,
    this.fromCategoriesScreen = false,
    this.fromMainScreen = false,
  }) : property = apartment;

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final Logger _logger = Logger('PropertyDetailsScreen');
  int _currentImageIndex = 0;
  final PageController _galleryPageController = PageController();
  bool _isNavigating = false; // Track navigation state

  // Get property from widget
  dynamic get property => widget.property;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _galleryPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final navigationProvider = Provider.of<NavigationProvider>(context);

    // Handle both Apartment and Property models
    final String propertyTitle =
        property is Apartment ? property.name : property.title;
    final String location = property.location;
    final String propertyType =
        property is Apartment ? property.category : property.category;
    final String beds =
        property is Apartment
            ? '${property.bedrooms} سرير'
            : '${property.bedrooms} سرير';
    final String rooms =
        property is Apartment
            ? '${property.rooms} غرف'
            : '${property.bedrooms} غرف';
    final String floor =
        property is Apartment ? '${property.floor}' : '${property.floor}';
    final String price =
        property is Apartment
            ? '${property.price.toStringAsFixed(0)} ج.م'
            : '${property.price} ج.م';
    final String priceType = // إضافة متغير لنوع السعر
        property is Apartment
            ? property.priceType ?? ''
            : property.priceType ?? '';
    final String description =
        property.description ?? 'لا يوجد وصف متاح لهذا العقار';
    // استخراج معلومات VIP إذا كانت متوفرة
    final String? infoVip = 
        property is Apartment
            ? property.infoVip
            : property is Map && property['info_vip'] != null
                ? property['info_vip']?.toString()
                : null;
    final bool isAvailable = property.isAvailable ?? true;
    final List<String> features =
        property is Apartment && property.features != null
            ? List<String>.from(property.features)
            : [];

    // استخراج العمولة إذا كانت متوفرة
    final double commission =
        property is Apartment && property.commission != null
            ? property.commission
            : 0.0;

    // استخراج العربون إذا كان متوفرًا
    final double deposit =
        property is Apartment && property.deposit != null
            ? property.deposit
            : 0.0;

    // Check if the property is in favorites
    final bool isFavorite =
        property is Apartment
            ? favoritesProvider.isFavorite(property.id)
            : false;

    final Widget content = Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. صور العقار (كاروسيل) مع أبار متحرك
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.primary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // Prevent multiple navigation attempts
                  if (_isNavigating) return;
                  _isNavigating = true;

                  // Use the safe navigation method instead of popUntil
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  } else {
                    // Fallback if we can't pop
                    Navigator.of(context).pushReplacementNamed('/');
                  }

                  // Reset the flag after navigation
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() => _isNavigating = false);
                    }
                  });
                },
              ),
            ),
            actions: [
              // زر الإضافة للمفضلة
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.black.withAlpha(64), // 0.25 opacity
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () async {
                    if (property is Apartment) {
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
                        // Store these values before awaiting
                        final String propertyName = property.name;
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        // Call async method
                        final isNowFavorite = await favoritesProvider
                            .toggleFavorite(property);
                        // Check if widget is still mounted after async call
                        if (mounted) {
                          scaffoldMessenger.hideCurrentSnackBar();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                isNowFavorite
                                    ? 'تم إضافة $propertyName إلى المفضلة'
                                    : 'تم إزالة $propertyName من المفضلة',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              behavior: SnackBarBehavior.fixed,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        _logger.severe('Error toggling favorite: $e');
                      }
                    }
                  },
                ),
              ),

              // زر المشاركة
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.black.withAlpha(64), // 0.25 opacity
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // استخراج البيانات المطلوبة
                    final String videoLinks = property is Apartment && property.videos.isNotEmpty
                        ? '🎬 فيديوهات العقار: ${property.videos.join("\n")}'
                        : '';

                    // العربون والعمولة
                    final double deposit = property is Apartment ? property.deposit : 0.0;
                    final double commission = property is Apartment ? property.commission : 0.0;
                    final String depositStr = deposit > 0 ? '💰 العربون: ${deposit.toStringAsFixed(0)} ج.م' : '';
                    final String commissionStr = commission > 0 ? '💸 العمولة: ${commission.toStringAsFixed(0)} ج.م' : '';
                    
                    // معلومات مميزة
                    final String infoVip = property is Apartment && property.infoVip != null && property.infoVip!.isNotEmpty
                        ? '✨ معلومات مميزة: ${property.infoVip}'
                        : '';
                    
                    // مميزات العقار
                    final String features = property is Apartment && property.features.isNotEmpty
                        ? '🏠 المميزات: ${property.features.join(" • ")}'
                        : '';

                    // إنشاء رسالة المشاركة المنسقة
                    String shareMessage = '''
🏢 ${propertyTitle}
📍 ${location}
💵 السعر: ${price} ${priceType.isNotEmpty ? '($priceType)' : ''}
$depositStr
$commissionStr
$infoVip

$features

${description.isNotEmpty ? '📝 الوصف: $description' : ''}

$videoLinks

📱 حمل تطبيق السهم للتسكين: https://elsahm.netlify.app/
''';

                    // مشاركة الرسالة
                    Share.share(
                      shareMessage,
                      subject: 'عقار مميز: $propertyTitle',
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => _openGallery(context),
                child: _buildImageCarousel(),
              ),
            ),
          ),

          // 2. تفاصيل العقار
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم العقار وحالة التوفر
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isAvailable
                                  ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.green[800]
                                      : Colors.green)
                                  : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.red[900]
                                      : Colors.red),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAvailable ? 'متاح' : 'غير متاح',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          propertyTitle,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // الموقع مع أيقونة
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          location,
                          style: textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // بطاقة السعر
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? colorScheme.primaryContainer.withAlpha(
                                51,
                              ) // 0.2 opacity
                              : colorScheme.primaryContainer.withAlpha(
                                51,
                              ), // 0.2 opacity
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? colorScheme.primaryContainer.withAlpha(
                                  178,
                                ) // 0.7 opacity
                                : colorScheme.primaryContainer,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // تعديل عرض السعر مع نوع السعر ليكونا بجانب بعضهما
                            Row(
                              children: [
                                // إظهار نوع السعر إذا كان موجوداً بجانب السعر (في البداية للغة العربية)
                                if (priceType.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      priceType,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Text(
                                  price,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'السعر',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // إظهار العمولة بشكل أكثر تميزاً
                        if (commission > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.amber.withAlpha(
                                        51,
                                      ) // 0.2 opacity
                                      : Colors.amber.withAlpha(
                                        51,
                                      ), // 0.2 opacity
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.amber[700]!
                                        : Colors.amber,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.amber[300]
                                          : Colors.amber,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'العمولة:',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${commission.toStringAsFixed(0)} ج.م',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.green[300]
                                            : Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // إظهار العربون بشكل أكثر تميزاً (مشابه للعمولة لكن بلون أزرق)
                        if (deposit > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blue.withAlpha(51) // 0.2 opacity
                                      : Colors.blue.withAlpha(
                                        51,
                                      ), // 0.2 opacity
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.blue[700]!
                                        : Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.blue[300]
                                          : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'العربون:',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${deposit.toStringAsFixed(0)} ج.م',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.lightBlue[300]
                                            : Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // زر طلب الحجز (أصبح عرضه كامل)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isAvailable ? () {
                              // Check if the user is authenticated before showing booking dialog
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              
                              if (!authProvider.isAuthenticated) {
                                // Show authentication required dialog if not logged in
                                AuthUtils.showAuthRequiredDialog(context);
                                return;
                              }
                              
                              // User is authenticated, show the booking dialog
                              _showBookingDialog();
                            } : null,
                            icon: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'طلب حجز',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        // إضافة ملاحظة الحجز أسفل الزر
                        if (isAvailable && (deposit > 0 || commission > 0))
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blue.withAlpha(40)
                                      : Colors.blue.withAlpha(20),
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blue.withAlpha(15)
                                      : Colors.blue.withAlpha(5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.blue.withAlpha(80)
                                        : Colors.blue.withAlpha(50),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withAlpha(
                                          30,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تفاصيل الحجز',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Payment details
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withAlpha(30),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.account_balance_wallet,
                                                  size: 16,
                                                  color: Colors.blue[700],
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'العربون',
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.blue[800],
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              deposit.toStringAsFixed(0),
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue[900],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 18,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withAlpha(30),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.monetization_on,
                                                  size: 16,
                                                  color: Colors.amber[700],
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'العمولة',
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Colors.amber[800],
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              commission.toStringAsFixed(0),
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber[900],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Total
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colorScheme.primary.withAlpha(50),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${(deposit + commission).toStringAsFixed(0)} ج.م",
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'الإجمالي',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
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

                  const SizedBox(height: 24),

                  // مواصفات العقار
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'مواصفات العقار',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // عرض المواصفات في شكل شبكة
                  _buildSpecificationsGrid(
                    propertyType: propertyType,
                    beds: beds,
                    rooms: rooms,
                    floor: floor,
                  ),

                  const SizedBox(height: 24),

                  // قسم معلومات VIP - قسم جديد بتصميم مميز وجذاب
                  if (infoVip != null && infoVip.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF3A1464)
                                : const Color(0xFFF0E6FF),
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2C1057)
                                : const Color(0xFFE6D9FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.purple.withAlpha(30)
                                : Colors.purple.withAlpha(20),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.purple[300]!.withAlpha(70)
                              : Colors.purple[200]!,
                          width: 1.5,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان القسم مع أيقونة مميزة
                          // تم حذف صف العنوان بالكامل

                          // محتوى المعلومات المميزة
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.purple[900]?.withAlpha(100)
                                  : Colors.white.withAlpha(180),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.purple[700]!
                                    : Colors.purple[100]!,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // أيقونة تمييز النص
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.format_quote,
                                      size: 20,
                                      color: Colors.purple[300],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        infoVip,
                                        style: textTheme.bodyLarge?.copyWith(
                                          height: 1.7,
                                          fontSize: 16,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // قسم فيديوهات الشقة
                  _buildVideosSection(),

                  const SizedBox(height: 24),

                  // المرافق المتاحة - قسم جديد احترافي
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey[50] ?? Colors.grey,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black.withAlpha(51) // 0.2 opacity
                                  : Colors.black.withAlpha(18), // 0.07 opacity
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800] ?? Colors.grey
                                : Colors.grey[200] ?? Colors.grey,
                        width: 1,
                      ),
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    padding: const EdgeInsets.only(
                      top: 20,
                      bottom: 24,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عنوان القسم مع أيقونة متحركة (من اليمين إلى اليسار)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withAlpha(25), // 0.1 opacity
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${features.length} مرفق',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white 
                                      : Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'المرافق المتاحة',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'مميزات وخدمات العقار',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 46,
                              height: 46,
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withAlpha(20), // 0.08 opacity
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                size: 30,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // عرض المرافق في شكل شبكة محسنة
                        _buildFeaturesGrid(features),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // وصف العقار
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey[50] ?? Colors.grey,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.07),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800] ?? Colors.grey
                                : Colors.grey[200] ?? Colors.grey,
                        width: 1,
                      ),
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    padding: const EdgeInsets.only(
                      top: 20,
                      bottom: 24,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // عنوان القسم مع أيقونة متحركة (من اليمين إلى اليسار)
                        Row(
                          children: [
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'وصف العقار',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'تفاصيل ومعلومات إضافية',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 46,
                              height: 46,
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                size: 30,
                                color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // وصف العقار
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800] ?? Colors.grey
                                      : Colors.grey[200] ?? Colors.grey,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.black.withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            description,
                            style: textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // قسم الأقسام والأماكن المتاحة
                  _buildCategoriesAndPlacesSection(),

                  // زر الحجز بتصميم احترافي في نهاية الصفحة
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: isAvailable ? () {
                        // Check if the user is authenticated before showing booking dialog
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        
                        if (!authProvider.isAuthenticated) {
                          // Show authentication required dialog if not logged in
                          AuthUtils.showAuthRequiredDialog(context);
                          return;
                        }
                        
                        // User is authenticated, show the booking dialog
                        _showBookingDialog();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: colorScheme.primary.withAlpha(
                          102,
                        ), // 0.4 opacity
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // زر الحجز الرئيسي
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'احجز الآن',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),

                          // نص إضافي في اليمين
                          if (isAvailable)
                            Positioned(
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(
                                    51,
                                  ), // 0.2 opacity
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'متاح الآن',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
      ),
    );

    // Check if we're already inside MainNavigationScreen to avoid duplicated navigation bars
    bool isAlreadyInMainNavigation = false;
    context.visitAncestorElements((element) {
      if (element.widget.toString().contains('MainNavigationScreen')) {
        isAlreadyInMainNavigation = true;
        return false; // Stop visiting
      }
      return true; // Continue visiting
    });

    // Only wrap with navigation bars if needed and we're not already in a MainNavigationScreen
    if ((widget.fromMainScreen || widget.fromCategoriesScreen) && !isAlreadyInMainNavigation) {
      return MainNavigationScreen.wrapWithBottomNav(
        context: context,
        child: content,
        selectedIndex: navigationProvider.selectedIndex,
      );
    }

    // Otherwise return the content directly
    return content;
  }

  // عرض صور العقار في كاروسيل
  Widget _buildImageCarousel() {
    final List<String> imageUrls = property.imageUrls ?? [];

    if (imageUrls.isEmpty) {
      return Image.asset(
        'assets/images/placeholder_property.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Stack(
      children: [
        // عرض الصور مع تعديل لتصحيح مشكلة التلاشي
        cs.CarouselSlider(
          options: cs.CarouselOptions(
            height: 300,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            enableInfiniteScroll: imageUrls.length > 1,
            autoPlay: imageUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items:
              imageUrls.map((url) {
                return Builder(
                  builder: (BuildContext context) {
                    return Stack(
                      children: [
                        // الصورة الأساسية
                        Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: const BoxDecoration(color: Colors.black),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Image.asset(
                                  'assets/images/placeholder_property.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                          ),
                        ),

                        // إضافة اللوجو بشفافية 100% (مرئي بالكامل)
                        Positioned(
                          bottom: 45, // أعلى قليلاً من نقاط التنقل
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Opacity(
                              opacity: 0.6, // شفافية 80%
                              child: Image.asset(
                                'assets/images/logo_new.webp',
                                height: 150,
                                width: 200,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }).toList(),
        ),

        // مؤشرات الصور (نقاط صغيرة أكثر أناقة في الأسفل)
        if (imageUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  imageUrls.asMap().entries.map((entry) {
                    return Container(
                      width: _currentImageIndex == entry.key ? 10.0 : 6.0,
                      height: _currentImageIndex == entry.key ? 10.0 : 6.0,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentImageIndex == entry.key
                                ? Colors.white
                                : Colors.white.withAlpha(128), // 0.5 opacity
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51), // 0.2 opacity
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  // فتح معرض الصور بملء الشاشة
  void _openGallery(BuildContext context) {
    final List<String> imageUrls = property.imageUrls ?? [];

    if (imageUrls.isEmpty) {
      // إذا لم تكن هناك صور، لا نفتح معرض الصور
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => _FullScreenGallery(
              imageUrls: imageUrls,
              initialIndex: _currentImageIndex,
            ),
      ),
    );
  }

  // عرض مواصفات العقار في شكل شبكة
  Widget _buildSpecificationsGrid({
    required String propertyType,
    required String beds,
    required String rooms,
    required String floor,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 2.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSpecificationItem(
          icon: Icons.category_outlined,
          title: 'النوع',
          value: propertyType,
        ),
        _buildSpecificationItem(
          icon: Icons.king_bed_outlined,
          title: 'الأسرّة',
          value: beds,
        ),
        _buildSpecificationItem(
          icon: Icons.meeting_room_outlined,
          title: 'الغرف',
          value: rooms,
        ),
        _buildSpecificationItem(
          icon: Icons.stairs_outlined,
          title: 'الدور',
          value: floor,
        ),
      ],
    );
  }

  // عنصر مواصفة واحدة
  Widget _buildSpecificationItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800] ?? Colors.grey : Colors.grey[300] ?? Colors.grey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon, 
                size: 18, 
                color: isDarkMode ? Colors.white : Theme.of(context).primaryColor
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  // عرض ميزات العقار
  Widget _buildFeaturesGrid(List<String> features) {
    // إضافة ميزات افتراضية إذا لم تكن الميزات متوفرة
    if (features.isEmpty) {
      features = ['ماء', 'كهرباء', 'واي فاي', 'مكيف', 'مفروش', 'مطبخ'];
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // 0.04 opacity
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 12.0,
          runSpacing: 16.0, // زيادة المسافة بين الصفوف للعناصر الطويلة
          children:
              features.map((feature) {
                // تحديد الأيقونة المناسبة للميزة
                IconData featureIcon = _getFeatureIcon(feature);

                return Container(
                  width:
                      MediaQuery.of(context).size.width *
                      0.30, // زيادة العرض قليلا
                  height: 60, // زيادة الارتفاع للنص الطويل
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isDarkMode
                              ? [
                                const Color(0xFF1A3A5A),
                                const Color(0xFF0D2845),
                              ]
                              : [Colors.blue[50]!, Colors.lightBlue[50]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8), // 0.03 opacity
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: Border.all(
                      color: isDarkMode ? Colors.blue[900]! : Colors.blue[100]!,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {}, // يمكن إضافة تفاعل عند النقر
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color:
                                      isDarkMode
                                          ? Colors.lightBlue[100]
                                          : Colors.blue[800],
                                ),
                                textAlign: TextAlign.right,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? const Color(0xFF2A2A2A)
                                        : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(
                                      13,
                                    ), // 0.05 opacity
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  featureIcon,
                                  size: 18,
                                  color:
                                      isDarkMode
                                          ? Colors.lightBlue[300]
                                          : Colors.blue[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  // تحديد الأيقونة المناسبة للميزة
  IconData _getFeatureIcon(String feature) {
    final String lowercaseFeature = feature.toLowerCase();

    if (lowercaseFeature.contains('ماء') || lowercaseFeature.contains('مياه')) {
      return Icons.water_drop_outlined;
    } else if (lowercaseFeature.contains('كهرباء')) {
      return Icons.electrical_services_outlined;
    } else if (lowercaseFeature.contains('واي فاي') ||
        lowercaseFeature.contains('انترنت')) {
      return Icons.wifi;
    } else if (lowercaseFeature.contains('مكيف') ||
        lowercaseFeature.contains('تكييف')) {
      return Icons.ac_unit_outlined;
    } else if (lowercaseFeature.contains('مفروش')) {
      return Icons.chair_outlined;
    } else if (lowercaseFeature.contains('مطبخ')) {
      return Icons.kitchen_outlined;
    } else if (lowercaseFeature.contains('غسالة')) {
      return Icons.local_laundry_service_outlined;
    } else if (lowercaseFeature.contains('ثلاجة')) {
      return Icons.kitchen_outlined;
    } else if (lowercaseFeature.contains('تلفزيون') ||
        lowercaseFeature.contains('تلفاز')) {
      return Icons.tv_outlined;
    } else if (lowercaseFeature.contains('حمام') ||
        lowercaseFeature.contains('مرحاض')) {
      return Icons.bathroom_outlined;
    } else if (lowercaseFeature.contains('سخان') ||
        lowercaseFeature.contains('ماء ساخن')) {
      return Icons.hot_tub_outlined;
    } else if (lowercaseFeature.contains('مواقف') ||
        lowercaseFeature.contains('جراج')) {
      return Icons.local_parking_outlined;
    } else if (lowercaseFeature.contains('أمن') ||
        lowercaseFeature.contains('حراسة')) {
      return Icons.security_outlined;
    } else if (lowercaseFeature.contains('مصعد')) {
      return Icons.elevator_outlined;
    } else if (lowercaseFeature.contains('حديقة')) {
      return Icons.park_outlined;
    } else {
      return Icons.check_circle_outline;
    }
  }

  // ظهور نافذة حوار الحجز
  void _showBookingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF262626) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]!
                      : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'طلب حجز العقار',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'نقلك لإتمام عملية الحجز',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property info summary
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.apartment,
                                size: 30,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property is Apartment ? property.name : property.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    property.location,
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        Divider(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[800] 
                              : Colors.grey[200],
                        ),
                        const SizedBox(height: 15),
                        
                        // Confirmation text
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'هل تريد طلب حجز هذا العقار؟',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 38.0),
                          child: Text(
                            'سيتم نقلك لصفحة استكمال بيانات الحجز.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              // إغلاق نافذة الحوار
                              Navigator.of(context).pop();

                              // الانتقال إلى صفحة إتمام الحجز
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CheckoutScreen(
                                        propertyId: property.id,
                                        propertyName:
                                            property is Apartment
                                                ? property.name
                                                : property.title,
                                        propertyPrice: property.price,
                                        imageUrl:
                                            property is Apartment &&
                                                    property.images != null &&
                                                    property.images.isNotEmpty
                                                ? property.images[0]
                                                : (property.imageUrls != null &&
                                                        property.imageUrls.isNotEmpty
                                                    ? property.imageUrls[0]
                                                    : null),
                                      ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'متابعة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                ),
                              ],
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
        );
      },
    );
  }

  // عرض قسم الفيديوهات بتصميم جديد احترافي
  Widget _buildVideosSection() {
    // تحقق مما إذا كان الكائن من نوع Apartment ويستخدم قائمة videos بدلاً من videoUrls
    List<String> videoIds = [];

    try {
      if (property is Apartment) {
        videoIds = (property as Apartment).videos;
      } else if (property.videoUrls != null) {
        // إذا كان الكائن من نوع آخر ويحتوي على خاصية videoUrls
        videoIds = property.videoUrls;
      }

      if (videoIds.isEmpty) {
        return const SizedBox.shrink(); // لا نعرض القسم إذا لم تكن هناك فيديوهات
      }

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.grey[50] ?? Colors.grey,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withAlpha(51) // 0.2 opacity
                      : Colors.black.withAlpha(18), // 0.07 opacity
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800] ?? Colors.grey
                    : Colors.grey[200] ?? Colors.grey,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        padding: const EdgeInsets.only(
          top: 24,
          bottom: 20,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم مع أيقونة متحركة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withAlpha(25), // 0.1 opacity
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${videoIds.length} فيديو',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'فيديوهات العقار',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'شاهد العقار من جميع الزوايا',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withAlpha(20), // 0.08 opacity
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.videocam_rounded,
                    size: 30,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // عرض الفيديوهات في مخطط رأسي (واحد تلو الآخر)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: videoIds.length,
              padding: const EdgeInsets.only(bottom: 5),
              itemBuilder: (context, index) {
                final videoId = videoIds[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildVideoThumbnail(videoId, index),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      _logger.severe('خطأ في إنشاء قسم الفيديوهات: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildVideoThumbnail(String videoId, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // الحصول على صور العقار
    List<String> imageUrls = property.imageUrls ?? [];
    // اختيار الصورة المناسبة للفيديو، إذا لم تكن متوفرة استخدم الصورة الأولى
    String backgroundImageUrl =
        imageUrls.isEmpty
            ? ''
            : imageUrls.length > index
            ? imageUrls[index]
            : imageUrls[0];

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20), // 0.08 opacity
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[800] ?? Colors.grey : Colors.grey[300] ?? Colors.grey,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFullScreenVideo(videoId, index),
          splashColor: Theme.of(
            context,
          ).primaryColor.withAlpha(25), // 0.1 opacity
          highlightColor: Theme.of(
            context,
          ).primaryColor.withAlpha(13), // 0.05 opacity
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة مصغرة للفيديو
              Stack(
                children: [
                  // خلفية من صورة العقار
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child:
                        backgroundImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: backgroundImageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Theme.of(
                                            context,
                                          ).primaryColor.withAlpha(25),
                                          Theme.of(
                                            context,
                                          ).primaryColor.withAlpha(76),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 42,
                                        color: Colors.white.withAlpha(178),
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Theme.of(
                                            context,
                                          ).primaryColor.withAlpha(25),
                                          Theme.of(
                                            context,
                                          ).primaryColor.withAlpha(76),
                                        ],
                                      ),
                                    ),
                                  ),
                            )
                            : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).primaryColor.withAlpha(25),
                                    Theme.of(
                                      context,
                                    ).primaryColor.withAlpha(76),
                                  ],
                                ),
                              ),
                            ),
                  ),

                  // طبقة شفافة داكنة للتباين
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(50), // 0.2 opacity
                          Colors.black.withAlpha(140), // 0.55 opacity
                        ],
                      ),
                    ),
                  ),

                  // أيقونة الفيديو كعلامة مائية
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.2,
                      child: Center(
                        child: Icon(
                          Icons.video_library,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // أيقونة التشغيل
                  SizedBox(
                    height: 160,
                    child: Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A).withAlpha(200)
                                  : Colors.white.withAlpha(229), // 0.9 opacity
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51), // 0.2 opacity
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 36,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),

                  // رقم الفيديو
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153), // 0.6 opacity
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withAlpha(51), // 0.2 opacity
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'فيديو ${index + 1}',
                            style: const TextStyle(
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

              // معلومات الفيديو - تم تبسيط هذا الجزء لتفادي التجاوز
              SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // زر المشاهدة
                      ElevatedButton.icon(
                        onPressed: () => _openFullScreenVideo(videoId, index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('اضغط للمشاهدة'),
                      ),
                      // عنوان الفيديو
                      Expanded(
                        child: Text(
                          'فيديو العقار ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // أيقونة فيديو
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).primaryColor.withAlpha(38)
                              : Theme.of(context).primaryColor.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.video_library,
                          size: 16,
                          color: Theme.of(context).primaryColor,
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
    );
  }

  void _openFullScreenVideo(String videoId, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => _FullScreenVideoPlayer(
              videoId: videoId,
              title: 'فيديو رقم ${index + 1}',
            ),
      ),
    );
  }

  // إضافة بناء قسم الأقسام والأماكن المتاحة
  Widget _buildCategoriesAndPlacesSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // التحقق من وجود أقسام وأماكن بأمان
    final hasCategories =
        widget.property.categories != null &&
        (widget.property.categories as List?)?.isNotEmpty == true;
    final hasPlaces =
        widget.property.places != null &&
        (widget.property.places as List?)?.isNotEmpty == true;

    if (!hasCategories && !hasPlaces) {
      return const SizedBox.shrink(); // لا يوجد محتوى للعرض
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الأقسام والأماكن المتاحة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // بناء رقائق الأقسام
              if (hasCategories)
                ...(widget.property.categories as List).map((category) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category is Map
                              ? (category['name'] ?? 'قسم')
                              : category.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              // بناء رقائق الأماكن المتاحة
              if (hasPlaces)
                ...(widget.property.places as List).map((place) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.green[900] : Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          place is Map
                              ? (place['name'] ?? 'مكان')
                              : place.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}

// معرض الصور بملء الشاشة
class _FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _currentIndex;
  late PageController _pageController;
  bool _isNavigating = false; // Track navigation state
  
  // Add zoom controller variables
  List<TransformationController> _transformationControllers = [];
  List<double> _currentScales = [];
  final double _minScale = 0.5;
  final double _maxScale = 4.0;
  final double _scaleInterval = 0.5;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Initialize transformation controllers for each image
    _transformationControllers = List.generate(
      widget.imageUrls.length,
      (_) => TransformationController(),
    );
    
    // Initialize scale values for each image
    _currentScales = List.generate(widget.imageUrls.length, (_) => 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    
    // Dispose all transformation controllers
    for (final controller in _transformationControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  // Reset zoom when page changes
  void _resetZoom() {
    _transformationControllers[_currentIndex].value = Matrix4.identity();
    _currentScales[_currentIndex] = 1.0;
    setState(() {});
  }

  // Zoom in function
  void _zoomIn() {
    if (_currentScales[_currentIndex] < _maxScale) {
      _currentScales[_currentIndex] += _scaleInterval;
      if (_currentScales[_currentIndex] > _maxScale) {
        _currentScales[_currentIndex] = _maxScale;
      }
      
      // Apply zoom transformation
      final scale = _currentScales[_currentIndex];
      final Matrix4 newMatrix = Matrix4.identity()..scale(scale, scale);
      _transformationControllers[_currentIndex].value = newMatrix;
      setState(() {});
    }
  }

  // Zoom out function
  void _zoomOut() {
    if (_currentScales[_currentIndex] > _minScale) {
      _currentScales[_currentIndex] -= _scaleInterval;
      if (_currentScales[_currentIndex] < _minScale) {
        _currentScales[_currentIndex] = _minScale;
      }
      
      // Apply zoom transformation
      final scale = _currentScales[_currentIndex];
      final Matrix4 newMatrix = Matrix4.identity()..scale(scale, scale);
      _transformationControllers[_currentIndex].value = newMatrix;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // معرض الصور مع إمكانية التكبير
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                // Reset zoom when changing to a different image
                _resetZoom();
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // الصورة الأساسية مع إمكانية التكبير/التصغير
                    Hero(
                      tag: 'image_${widget.imageUrls[index]}',
                      child: InteractiveViewer(
                        transformationController: _transformationControllers[index],
                        minScale: _minScale,
                        maxScale: _maxScale,
                        onInteractionEnd: (_) {
                          // Update current scale after manual zooming
                          final scale = _transformationControllers[index].value.getMaxScaleOnAxis();
                          _currentScales[index] = scale;
                        },
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrls[index],
                          fit: BoxFit.contain,
                          width: size.width,
                          height: size.height,
                          placeholder:
                              (context, url) => Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                  strokeWidth: 2.0,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.red[300],
                                    size: 50,
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'فشل تحميل الصورة',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),

                    // إضافة اللوجو بشفافية 20% (شفاف قليلاً)
                    Positioned.fill(
                      child: Center(
                        child: Opacity(
                          opacity: 0.2, // شفافية 20%
                          child: Image.asset(
                            'assets/images/logo_new.webp',
                            height: 120,
                            width: 120,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // شعار السهم ورقم الهاتف
          Positioned(
            top: topPadding + 20,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // شعار السهم
                Image.asset(
                  'assets/images/logo_dark.webp',
                  height: 50,
                  width: 50,
                ),
                // تم حذف رقم الهاتف
              ],
            ),
          ),

          // زر الرجوع
          Positioned(
            top: topPadding + 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () {
                  // Prevent multiple navigation attempts
                  if (_isNavigating) return;
                  _isNavigating = true;

                  // Use safe pop
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  } else {
                    // Fallback if we can't pop
                    Navigator.of(context).pushReplacementNamed('/');
                  }

                  // Reset the flag after navigation
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() => _isNavigating = false);
                    }
                  });
                },
              ),
            ),
          ),

          // زر السابق
          if (widget.imageUrls.length > 1)
            Positioned(
              left: 10,
              top: size.height / 2 - 25,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    if (_currentIndex > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // إذا كانت الصورة الأولى، اذهب إلى الصورة الأخيرة
                      _pageController.animateToPage(
                        widget.imageUrls.length - 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ),

          // زر التالي
          if (widget.imageUrls.length > 1)
            Positioned(
              right: 10,
              top: size.height / 2 - 25,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    if (_currentIndex < widget.imageUrls.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // إذا كانت الصورة الأخيرة، اذهب إلى الصورة الأولى
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ),

          // عرض مؤشر عدد الصور والصورة الحالية
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentIndex + 1}/${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // أزرار التكبير والتصغير (Zoom controls)
          Positioned(
            bottom: 65, // أقرب إلى الأسفل (كان 70)
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زر التكبير
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 36, // حجم أصغر (كان 42)
                      height: 36, // حجم أصغر (كان 42)
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20, // حجم أيقونة أصغر (كان 24)
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: _zoomIn,
                      ),
                    ),
                    
                    // زر التصغير
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 36, // حجم أصغر (كان 42)
                      height: 36, // حجم أصغر (كان 42)
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 20, // حجم أيقونة أصغر (كان 24)
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: _zoomOut,
                      ),
                    ),
                    
                    // زر إعادة الضبط
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 36, // حجم أصغر (كان 42)
                      height: 36, // حجم أصغر (كان 42)
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 18, // حجم أيقونة أصغر (كان 20)
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: _resetZoom,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// تحديث مشغل الفيديو باستخدام حزم video_player و chewie و webview كخيار احتياطي
class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoId;
  final String title;

  const _FullScreenVideoPlayer({
    required this.videoId,
    this.title = 'فيديو العقار',
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  final Logger _logger = Logger('VideoPlayer');
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = 'حدث خطأ غير معروف';
  bool _usingWebView = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _usingWebView = false;
    });

    try {
      // Check if the videoId is a Supabase URL
      final String videoUrl =
          widget.videoId.startsWith('http')
              ? widget.videoId
              : _getLegacyVideoUrl(widget.videoId);

      _logger.info('محاولة تشغيل الفيديو: $videoUrl');

      // التخلص من المشغل السابق إذا كان موجوداً
      if (_videoPlayerController != null) {
        await _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }

      if (_chewieController != null) {
        _chewieController!.dispose();
        _chewieController = null;
      }

      // تهيئة مشغل الفيديو
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      // إكمال التهيئة
      await _videoPlayerController!.initialize();

      if (_videoPlayerController!.value.hasError) {
        throw Exception('فشل تهيئة مشغل الفيديو');
      }

      if (!mounted) return;

      // إعداد مشغل Chewie مع تعطيل التدوير التلقائي للشاشة
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        allowMuting: true,
        allowFullScreen: true,
        showControls: true,
        errorBuilder: (context, errorMessage) {
          _logger.severe('خطأ Chewie: $errorMessage');
          return _buildErrorWidget();
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      _logger.severe('خطأ أثناء تشغيل الفيديو: $e');

      // Try WebView as fallback
      if (!_usingWebView && widget.videoId.startsWith('http')) {
        _initializeWebView(widget.videoId);
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'فشل تشغيل الفيديو: $e';
        });
      }
    }
  }

  String _getLegacyVideoUrl(String videoId) {
    // For backwards compatibility with the old format
    return 'https://vz-bb7a5bc7-153.b-cdn.net/$videoId/play.mp4';
  }

  // تهيئة WebView كخيار احتياطي للتشغيل
  void _initializeWebView(String url) {
    _logger.info('استخدام WebView لعرض الفيديو');

    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..loadRequest(Uri.parse(url))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                  });
                }
              },
              onPageFinished: (_) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _usingWebView = true;
                    _hasError = false;
                  });
                }
              },
              onWebResourceError: (error) {
                _logger.severe('خطأ WebView: ${error.description}');
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                    _errorMessage = 'فشل تحميل الفيديو: ${error.description}';
                  });
                }
              },
            ),
          );
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'جاري تحميل الفيديو...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "استغفر ربك ، فرب لحظة ذكر تغيّر لك كل شيء",
                              style: TextStyle(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_usingWebView)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'استخدام صفحة الويب للتشغيل',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                : _hasError
                ? _buildErrorWidget()
                : _usingWebView && _webViewController != null
                ? WebViewWidget(controller: _webViewController!)
                : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : _buildErrorWidget(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isSupabaseUrl = widget.videoId.startsWith('http');
    final displayErrorMessage =
        isSupabaseUrl
            ? 'فشل تشغيل الفيديو من Supabase: $_errorMessage'
            : _errorMessage;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 70),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                displayErrorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _usingWebView = false;
                });
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // تجربة استخدام WebView إذا كان الفيديو URL مباشر
            if (!_usingWebView && widget.videoId.startsWith('http'))
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _initializeWebView(widget.videoId);
                },
                icon: const Icon(Icons.web),
                label: const Text('استخدام صفحة الويب'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // زر لفتح الفيديو في المتصفح
            OutlinedButton.icon(
              onPressed: () {
                final url = Uri.parse(
                  widget.videoId.startsWith('http')
                      ? widget.videoId
                      : 'https://iframe.mediadelivery.net/embed/420087/${widget.videoId}',
                );
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('فتح في المتصفح'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Safe navigation back
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('العودة'),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
