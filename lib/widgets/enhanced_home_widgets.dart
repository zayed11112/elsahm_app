import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';
import 'enhanced_card.dart';
import 'enhanced_loading.dart';

/// Enhanced Banner Carousel with modern design
class EnhancedBannerCarousel extends StatefulWidget {
  final List<String> bannerUrls;
  final double height;
  final Function(int)? onBannerTap;

  const EnhancedBannerCarousel({
    Key? key,
    required this.bannerUrls,
    this.height = 200,
    this.onBannerTap,
  }) : super(key: key);

  @override
  State<EnhancedBannerCarousel> createState() => _EnhancedBannerCarouselState();
}

class _EnhancedBannerCarouselState extends State<EnhancedBannerCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    if (widget.bannerUrls.isEmpty) {
      return Container(
        height: widget.height,
        margin: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: isDarkMode ? darkCard : lightCard,
          borderRadius: BorderRadius.circular(largeBorderRadius),
          boxShadow: lightShadow,
        ),
        child: const Center(
          child: EnhancedLoading(
            style: LoadingStyle.shimmer,
            size: 60,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          // Carousel
          ClipRRect(
            borderRadius: BorderRadius.circular(largeBorderRadius),
            child: cs.CarouselSlider(
              options: cs.CarouselOptions(
                height: widget.height,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: normalAnimation,
                enlargeCenterPage: true,
                viewportFraction: 1.0,
                onPageChanged: (index, reason) {
                  setState(() => _currentIndex = index);
                },
              ),
              items: widget.bannerUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                
                return GestureDetector(
                  onTap: () => widget.onBannerTap?.call(index),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(largeBorderRadius),
                      boxShadow: mediumShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(largeBorderRadius),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDarkMode ? darkCard : lightElevated,
                          child: const Center(
                            child: EnhancedLoading(
                              style: LoadingStyle.shimmer,
                              size: 50,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDarkMode ? darkCard : lightElevated,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: isDarkMode ? darkTextTertiary : lightTextTertiary,
                              ),
                              const SizedBox(height: smallPadding),
                              Text(
                                'تعذر تحميل الصورة',
                                style: context.bodyMedium?.copyWith(
                                  color: isDarkMode ? darkTextTertiary : lightTextTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Indicators
          if (widget.bannerUrls.length > 1) ...[
            const SizedBox(height: defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.bannerUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final isActive = index == _currentIndex;
                
                return AnimatedContainer(
                  duration: fastAnimation,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? primaryBlue 
                        : (isDarkMode ? darkTextTertiary : lightTextTertiary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Enhanced Category Grid with modern design
class EnhancedCategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Function(Map<String, dynamic>)? onCategoryTap;
  final int crossAxisCount;

  const EnhancedCategoryGrid({
    Key? key,
    required this.categories,
    this.onCategoryTap,
    this.crossAxisCount = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    if (categories.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(defaultPadding),
        child: const Center(
          child: EnhancedLoading(
            style: LoadingStyle.dots,
            message: 'جاري تحميل الفئات...',
            showMessage: true,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: defaultPadding,
          mainAxisSpacing: defaultPadding,
          childAspectRatio: 1.2,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          
          return EnhancedCard(
            onTap: () => onCategoryTap?.call(category),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryBlue.withOpacity(0.1),
                accentBlue.withOpacity(0.05),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Category Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(largeBorderRadius),
                  ),
                  child: Icon(
                    _getCategoryIcon(category['name'] ?? ''),
                    size: 30,
                    color: primaryBlue,
                  ),
                ),
                
                const SizedBox(height: defaultPadding),
                
                // Category Name
                Text(
                  category['name'] ?? '',
                  style: context.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Property Count
                if (category['count'] != null) ...[
                  const SizedBox(height: smallPadding),
                  Text(
                    '${category['count']} عقار',
                    style: context.bodySmall?.copyWith(
                      color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'شقق':
      case 'apartments':
        return Icons.apartment;
      case 'فيلات':
      case 'villas':
        return Icons.villa;
      case 'مكاتب':
      case 'offices':
        return Icons.business;
      case 'محلات':
      case 'shops':
        return Icons.store;
      case 'مستودعات':
      case 'warehouses':
        return Icons.warehouse;
      default:
        return Icons.home;
    }
  }
}

/// Enhanced Property Card with modern design
class EnhancedPropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const EnhancedPropertyCard({
    Key? key,
    required this.property,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final imageUrl = property['image_url'] ?? property['imageUrl'] ?? '';
    final title = property['title'] ?? property['name'] ?? 'عقار';
    final price = property['price'] ?? property['rent_price'] ?? 0;
    final location = property['location'] ?? property['address'] ?? '';

    return EnhancedCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: smallPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDarkMode ? darkCard : lightElevated,
                            child: const Center(
                              child: EnhancedLoading(
                                style: LoadingStyle.shimmer,
                                size: 40,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDarkMode ? darkCard : lightElevated,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: isDarkMode ? darkTextTertiary : lightTextTertiary,
                            ),
                          ),
                        )
                      : Container(
                          color: isDarkMode ? darkCard : lightElevated,
                          child: Icon(
                            Icons.home,
                            size: 40,
                            color: isDarkMode ? darkTextTertiary : lightTextTertiary,
                          ),
                        ),
                ),
              ),
              
              // Favorite Button
              Positioned(
                top: smallPadding,
                right: smallPadding,
                child: GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Container(
                    padding: const EdgeInsets.all(smallPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: lightShadow,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? errorColor : lightTextSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: defaultPadding),
          
          // Property Details
          Text(
            title,
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? darkTextPrimary : lightTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: smallPadding),
          
          if (location.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: context.bodySmall?.copyWith(
                      color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: smallPadding),
          ],
          
          // Price
          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 16,
                color: primaryBlue,
              ),
              Text(
                '$price جنية',
                style: context.titleSmall?.copyWith(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
