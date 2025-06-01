import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';
import 'enhanced_card.dart';
import 'enhanced_button.dart';
import 'enhanced_loading.dart';

/// Enhanced Search Bar with modern design
class EnhancedSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;
  final bool showFilter;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const EnhancedSearchBar({
    Key? key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.controller,
    this.showFilter = true,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: fastAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
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

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(defaultPadding),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? darkCard : lightCard,
                      borderRadius: BorderRadius.circular(defaultBorderRadius),
                      boxShadow: _isFocused ? mediumShadow : lightShadow,
                      border: Border.all(
                        color: _isFocused 
                            ? primaryBlue 
                            : (isDarkMode ? darkTextTertiary : lightTextTertiary),
                        width: _isFocused ? 2 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      onTap: () {
                        setState(() => _isFocused = true);
                        _animationController.forward();
                      },
                      onEditingComplete: () {
                        setState(() => _isFocused = false);
                        _animationController.reverse();
                      },
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? 'ابحث عن العقارات...',
                        hintStyle: TextStyle(
                          color: isDarkMode ? darkTextTertiary : lightTextTertiary,
                        ),
                        prefixIcon: widget.prefixIcon ?? Icon(
                          Icons.search,
                          color: _isFocused 
                              ? primaryBlue 
                              : (isDarkMode ? darkTextSecondary : lightTextSecondary),
                        ),
                        suffixIcon: widget.suffixIcon,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: defaultPadding,
                          vertical: defaultPadding,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                      ),
                    ),
                  ),
                ),
                
                // Filter Button
                if (widget.showFilter) ...[
                  const SizedBox(width: smallPadding),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(defaultBorderRadius),
                      boxShadow: lightShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(defaultBorderRadius),
                        onTap: widget.onFilterTap,
                        child: Container(
                          padding: const EdgeInsets.all(defaultPadding),
                          child: const Icon(
                            Icons.tune,
                            color: Colors.white,
                            size: defaultIconSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced Filter Chip with modern design
class EnhancedFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;

  const EnhancedFilterChip({
    Key? key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final effectiveSelectedColor = selectedColor ?? primaryBlue;

    return AnimatedContainer(
      duration: fastAnimation,
      margin: const EdgeInsets.only(right: smallPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(largeBorderRadius),
          onTap: onTap,
          child: AnimatedContainer(
            duration: fastAnimation,
            padding: const EdgeInsets.symmetric(
              horizontal: defaultPadding,
              vertical: smallPadding,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? effectiveSelectedColor 
                  : (isDarkMode ? darkCard : lightCard),
              borderRadius: BorderRadius.circular(largeBorderRadius),
              border: Border.all(
                color: isSelected 
                    ? effectiveSelectedColor 
                    : (isDarkMode ? darkTextTertiary : lightTextTertiary),
                width: 1,
              ),
              boxShadow: isSelected ? lightShadow : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected 
                        ? Colors.white 
                        : (isDarkMode ? darkTextSecondary : lightTextSecondary),
                  ),
                  const SizedBox(width: smallPadding / 2),
                ],
                Text(
                  label,
                  style: context.bodyMedium?.copyWith(
                    color: isSelected 
                        ? Colors.white 
                        : (isDarkMode ? darkTextPrimary : lightTextPrimary),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced Search Results List
class EnhancedSearchResults extends StatelessWidget {
  final List<dynamic> results;
  final bool isLoading;
  final String? emptyMessage;
  final Widget Function(dynamic item, int index) itemBuilder;
  final VoidCallback? onRetry;

  const EnhancedSearchResults({
    Key? key,
    required this.results,
    required this.itemBuilder,
    this.isLoading = false,
    this.emptyMessage,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    if (isLoading) {
      return const Center(
        child: EnhancedLoading(
          style: LoadingStyle.dots,
          message: 'جاري البحث...',
          showMessage: true,
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: EnhancedCard(
          margin: const EdgeInsets.all(largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: isDarkMode ? darkTextTertiary : lightTextTertiary,
              ),
              const SizedBox(height: defaultPadding),
              Text(
                emptyMessage ?? 'لم يتم العثور على نتائج',
                style: context.titleMedium?.copyWith(
                  color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: smallPadding),
              Text(
                'جرب تغيير كلمات البحث أو المرشحات',
                style: context.bodyMedium?.copyWith(
                  color: isDarkMode ? darkTextTertiary : lightTextTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: defaultPadding),
                PrimaryButton(
                  text: 'إعادة المحاولة',
                  onPressed: onRetry,
                  icon: Icons.refresh,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutBack,
          child: itemBuilder(results[index], index),
        );
      },
    );
  }
}

/// Enhanced Search Suggestions
class EnhancedSearchSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String)? onSuggestionTap;

  const EnhancedSearchSuggestions({
    Key? key,
    required this.suggestions,
    this.onSuggestionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اقتراحات البحث',
            style: context.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? darkTextPrimary : lightTextPrimary,
            ),
          ),
          const SizedBox(height: smallPadding),
          ...suggestions.map((suggestion) => Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(smallBorderRadius),
              onTap: () => onSuggestionTap?.call(suggestion),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: smallPadding,
                  horizontal: smallPadding,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 16,
                      color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                    ),
                    const SizedBox(width: smallPadding),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: context.bodyMedium?.copyWith(
                          color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.north_west,
                      size: 16,
                      color: isDarkMode ? darkTextTertiary : lightTextTertiary,
                    ),
                  ],
                ),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}
