import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';
import 'enhanced_card.dart';
import 'enhanced_loading.dart';

/// Enhanced Category Card with modern design and animations
class EnhancedCategoryCard extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? width;
  final double? height;

  const EnhancedCategoryCard({
    Key? key,
    required this.category,
    this.onTap,
    this.isSelected = false,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<EnhancedCategoryCard> createState() => _EnhancedCategoryCardState();
}

class _EnhancedCategoryCardState extends State<EnhancedCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: normalAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final categoryName = widget.category['name'] ?? 'فئة';
    final categoryCount = widget.category['count'] ?? 0;
    final categoryIcon = _getCategoryIcon(categoryName);
    final categoryColor = _getCategoryColor(categoryName);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 140,
              margin: const EdgeInsets.all(smallPadding),
              child: EnhancedCard(
                onTap: () {
                  _animationController.forward().then((_) {
                    _animationController.reverse();
                  });
                  widget.onTap?.call();
                },
                gradient: widget.isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor,
                          categoryColor.withOpacity(0.8),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withOpacity(0.1),
                          categoryColor.withOpacity(0.05),
                        ],
                      ),
                border: widget.isSelected
                    ? Border.all(color: categoryColor, width: 2)
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category Icon with animated background
                    AnimatedContainer(
                      duration: fastAnimation,
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.2)
                            : categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(largeBorderRadius),
                        boxShadow: widget.isSelected ? lightShadow : [],
                      ),
                      child: Icon(
                        categoryIcon,
                        size: 30,
                        color: widget.isSelected
                            ? Colors.white
                            : categoryColor,
                      ),
                    ),

                    const SizedBox(height: defaultPadding),

                    // Category Name
                    Text(
                      categoryName,
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected
                            ? Colors.white
                            : (isDarkMode ? darkTextPrimary : lightTextPrimary),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: smallPadding),

                    // Property Count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: smallPadding,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.2)
                            : categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(smallBorderRadius),
                      ),
                      child: Text(
                        '$categoryCount عقار',
                        style: context.bodySmall?.copyWith(
                          color: widget.isSelected
                              ? Colors.white
                              : (isDarkMode ? darkTextSecondary : lightTextSecondary),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      case 'أراضي':
      case 'lands':
        return Icons.landscape;
      case 'استوديوهات':
      case 'studios':
        return Icons.home_work;
      default:
        return Icons.home;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'شقق':
      case 'apartments':
        return primaryBlue;
      case 'فيلات':
      case 'villas':
        return secondaryTeal;
      case 'مكاتب':
      case 'offices':
        return secondaryPurple;
      case 'محلات':
      case 'shops':
        return secondaryOrange;
      case 'مستودعات':
      case 'warehouses':
        return warningColor;
      case 'أراضي':
      case 'lands':
        return successColor;
      case 'استوديوهات':
      case 'studios':
        return accentBlue;
      default:
        return primaryBlue;
    }
  }
}

/// Enhanced Category Grid with loading and empty states
class EnhancedCategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Function(Map<String, dynamic>)? onCategoryTap;
  final bool isLoading;
  final int crossAxisCount;
  final double childAspectRatio;
  final String? selectedCategoryId;

  const EnhancedCategoryGrid({
    Key? key,
    required this.categories,
    this.onCategoryTap,
    this.isLoading = false,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.2,
    this.selectedCategoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    if (isLoading) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(defaultPadding),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: defaultPadding,
            mainAxisSpacing: defaultPadding,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: 6, // Show 6 shimmer items
          itemBuilder: (context, index) => const ShimmerListItem(height: 140),
        ),
      );
    }

    if (categories.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(defaultPadding),
        child: EnhancedCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 60,
                color: isDarkMode ? darkTextTertiary : lightTextTertiary,
              ),
              const SizedBox(height: defaultPadding),
              Text(
                'لا توجد فئات متاحة',
                style: context.titleMedium?.copyWith(
                  color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                ),
              ),
              const SizedBox(height: smallPadding),
              Text(
                'سيتم إضافة فئات جديدة قريباً',
                style: context.bodyMedium?.copyWith(
                  color: isDarkMode ? darkTextTertiary : lightTextTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: defaultPadding,
          mainAxisSpacing: defaultPadding,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryId == category['id']?.toString();

          return EnhancedCategoryCard(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategoryTap?.call(category),
          );
        },
      ),
    );
  }
}

/// Enhanced Category List (horizontal scrolling)
class EnhancedCategoryList extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Function(Map<String, dynamic>)? onCategoryTap;
  final bool isLoading;
  final String? selectedCategoryId;
  final double height;

  const EnhancedCategoryList({
    Key? key,
    required this.categories,
    this.onCategoryTap,
    this.isLoading = false,
    this.selectedCategoryId,
    this.height = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          itemCount: 5,
          itemBuilder: (context, index) => Container(
            width: 100,
            margin: const EdgeInsets.only(right: smallPadding),
            child: const ShimmerListItem(),
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: EnhancedLoading(
            style: LoadingStyle.dots,
            message: 'جاري تحميل الفئات...',
            showMessage: true,
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryId == category['id']?.toString();

          return EnhancedCategoryCard(
            category: category,
            isSelected: isSelected,
            width: 100,
            height: height,
            onTap: () => onCategoryTap?.call(category),
          );
        },
      ),
    );
  }
}
