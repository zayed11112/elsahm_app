import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/apartment.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_utils.dart';
import '../screens/property_details_screen.dart';

/// بطاقة عقار حديثة ومحسنة للاستخدام في الصفحة الرئيسية وغيرها
class PropertyCardWidget extends StatelessWidget {
  final Apartment apartment;
  final bool showFavoriteButton;
  final bool isCompact;

  const PropertyCardWidget({
    super.key,
    required this.apartment,
    this.showFavoriteButton = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة العقار
            Stack(
              children: [
                // الصورة
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: isCompact ? 150 : 180,
                    child: _buildPropertyImage(),
                  ),
                ),

                // شريط المعلومات
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                        stops: const [0.2, 1.0],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // سعر العقار
                        Text(
                          '${apartment.price.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        // حالة العقار
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: apartment.isAvailable
                                ? Colors.green
                                : Colors.red.shade600,
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

                // أيقونة المفضلة
                if (showFavoriteButton)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildFavoriteButton(context),
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

                  const SizedBox(height: 6),

                  // الموقع
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
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // المواصفات
                  _buildPropertyFeatures(theme, isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // صورة العقار
  Widget _buildPropertyImage() {
    return apartment.imageUrls.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: apartment.imageUrls[0],
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPropertyImagePlaceholder(context),
            errorWidget: (context, url, error) => _buildPropertyImageError(context),
            fadeInDuration: const Duration(milliseconds: 300),
          )
        : Builder(
            builder: (context) => _buildPropertyImageError(context),
          );
  }

  // مؤشر تحميل صورة العقار
  Widget _buildPropertyImagePlaceholder(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  // حالة خطأ صورة العقار
  Widget _buildPropertyImageError(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 40,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 6),
            Text(
              'لا توجد صورة',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // مواصفات العقار
  Widget _buildPropertyFeatures(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode
            ? theme.colorScheme.surface.withOpacity(0.3)
            : theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFeatureItem(
            theme,
            isDarkMode,
            Icons.bedroom_parent_outlined,
            '${apartment.rooms} غرف',
          ),
          _buildFeatureItem(
            theme, 
            isDarkMode,
            Icons.king_bed_outlined,
            '${apartment.bedrooms} سرير',
          ),
        ],
      ),
    );
  }

  // عنصر ميزة
  Widget _buildFeatureItem(
    ThemeData theme, 
    bool isDarkMode, 
    IconData icon, 
    String text
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  // زر المفضلة
  Widget _buildFavoriteButton(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final isFavorite = favoritesProvider.isFavorite(apartment.id);
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.6)
                : Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _toggleFavorite(context),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey<bool>(isFavorite),
                    color: isFavorite ? Colors.red : Colors.grey[700],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // إضافة أو إزالة من المفضلة
  void _toggleFavorite(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // التحقق من تسجيل الدخول
    if (!authProvider.isAuthenticated) {
      AuthUtils.showAuthRequiredDialog(context);
      return;
    }
    
    // تبديل حالة المفضلة
    try {
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
      final isNowFavorite = await favoritesProvider.toggleFavorite(apartment);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowFavorite
                ? 'تمت إضافة ${apartment.name} إلى المفضلة'
                : 'تمت إزالة ${apartment.name} من المفضلة',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      // التعامل مع الخطأ
    }
  }

  // الانتقال إلى تفاصيل العقار
  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsScreen(
          property: apartment,
          fromCategoriesScreen: false,
        ),
      ),
    );
  }
} 