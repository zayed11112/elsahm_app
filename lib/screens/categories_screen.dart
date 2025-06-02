import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logging/logging.dart';
import '../models/apartment.dart';
import '../models/available_place.dart';
import '../services/category_service.dart';
import '../services/property_service_supabase.dart';
import '../services/available_places_service.dart';
import '../utils/navigation_utils.dart';
import '../utils/loading_service.dart';
import '../providers/navigation_provider.dart';

import '../widgets/shimmer_loading_effect.dart';
import '../widgets/custom_tab_indicator.dart';
import '../widgets/empty_state_widget.dart';
import 'property_details_screen.dart';
import 'place_details_screen.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'main_navigation_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String? initialCategory;
  final bool fromMainScreen;
  final bool scrollToAvailablePlaces;

  const CategoriesScreen({
    super.key,
    this.initialCategory,
    this.fromMainScreen = true,
    this.scrollToAvailablePlaces = false,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();
  final PropertyServiceSupabase _propertyService = PropertyServiceSupabase();
  final AvailablePlacesService _placesService = AvailablePlacesService();
  final Logger _logger = Logger('CategoriesScreen');

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // State variables
  List<Map<String, dynamic>> _categories = [];
  List<Apartment> _apartments = [];
  List<AvailablePlace> _availablePlaces = [];
  String? _selectedCategory;

  // Loading states
  bool _isLoading = true;
  bool _isLoadingApartments = false;
  bool _isLoadingPlaces = false;

  // Navigation protection
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // If scrollToAvailablePlaces is true, switch to the second tab
    if (widget.scrollToAvailablePlaces) {
      _tabController.animateTo(1);
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadCategories(), _loadAvailablePlaces()]);

    // If there's an initial category, load its properties
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadApartmentsByCategory(widget.initialCategory!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);
      final categories = await _categoryService.getCategories();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
      _logger.info('تم تحميل ${categories.length} قسم');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _logger.severe('خطأ في تحميل الأقسام: $e');
    }
  }

  Future<void> _loadAvailablePlaces() async {
    try {
      setState(() => _isLoadingPlaces = true);
      final places = await _placesService.getAllPlaces(limit: 15);

      if (mounted) {
        setState(() {
          _availablePlaces = places;
          _isLoadingPlaces = false;
        });
      }
      _logger.info('تم تحميل ${places.length} مكان متاح');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlaces = false);
      }
      _logger.severe('خطأ في تحميل الأماكن المتاحة: $e');
    }
  }

  Future<void> _loadApartmentsByCategory(String category) async {
    try {
      // Set selected category and loading state
      setState(() {
        _selectedCategory = category;
        _isLoadingApartments = true;
      });

      // Set minimum loading time for better UX
      LoadingService.defaultMinimumLoadingTime = const Duration(seconds: 2);

      // Load properties for the category
      final propertiesData = await _propertyService.getPropertiesByCategory(
        category,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _apartments = propertiesData;
          _isLoadingApartments = false;
        });
      }
    } catch (e) {
      _logger.severe('خطأ في تحميل العقارات: $e');
      if (mounted) {
        setState(() => _isLoadingApartments = false);
      }
    }
  }

  // Handle safe navigation back
  void _safelyNavigateBack(BuildContext context) {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);
    try {
      if (_selectedCategory != null) {
        // Just update the state to show the categories list again
        // This ensures we stay in the same screen with nav bars
        setState(() => _selectedCategory = null);
      } else if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _logger.severe('خطأ في التنقل: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isNavigating = false);
      });
    }
  }

  // Handle safe navigation to home

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final navigationProvider = Provider.of<NavigationProvider>(context);

    // Show loading screen if initial data is loading
    if (_isLoading && _selectedCategory == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('الأقسام والأماكن المتاحة'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _safelyNavigateBack(context),
            tooltip: 'إغلاق',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final Widget content = PopScope(
      canPop: !_isNavigating && _selectedCategory == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_isNavigating) return;
        setState(() => _isNavigating = true);

        if (_selectedCategory != null) {
          // Just update state to show categories list, maintaining the same screen with navigation bars
          setState(() => _selectedCategory = null);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _isNavigating = false);
          });
        } else {
          setState(() => _isNavigating = false);
        }
      },
      child: Scaffold(
        extendBody: true, // Extend the body below the bottom navigation bar
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false, // Let content extend below bottom safe area
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true, // Remove bottom insets to avoid double padding
            child: Container(
              // Remove all bottom padding
              padding: EdgeInsets.zero,
              child:
                  _selectedCategory == null
                      ? _buildMainCategoriesScreen(theme, isDarkMode)
                      : _buildCategoryDetailsScreen(theme, isDarkMode),
            ),
          ),
        ),
      ),
    );

    // Only wrap with navigation when in detail view AND NOT coming from main screen
    // This prevents double wrapping which causes duplicated nav bars
    if (_selectedCategory != null && !widget.fromMainScreen) {
      // This ensures we maintain the bottom navigation bar when viewing category details
      // but only when we're not already inside the main navigation screen
      return MainNavigationScreen.wrapWithBottomNav(
        context: context,
        child: content,
        selectedIndex: navigationProvider.selectedIndex,
      );
    }

    // Otherwise just return the content directly
    return content;
  }

  // Main categories screen with tabbed interface
  Widget _buildMainCategoriesScreen(ThemeData theme, bool isDarkMode) {
    return SafeArea(
      bottom: false, // Don't add safe area at bottom, we'll handle it manually
      child: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                floating: false, // Changed to false to ensure it stays pinned
                snap: false, // Added to ensure proper pinning behavior
                automaticallyImplyLeading: false,
                title: const Text('الأقسام والأماكن المتاحة'),
                centerTitle: true,
                forceElevated:
                    innerBoxIsScrolled, // Add elevation when scrolled
                elevation:
                    innerBoxIsScrolled
                        ? 4.0
                        : 0.0, // Add elevation when scrolled
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(
                    52,
                  ), // Increase from 48 to 52
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          theme.appBarTheme.backgroundColor ??
                          theme.primaryColor,
                      border: Border(
                        bottom: BorderSide(
                          color:
                              isDarkMode
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        if (innerBoxIsScrolled)
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: CustomTabIndicator(
                        color: theme.colorScheme.primary,
                        radius: 4,
                        indicatorHeight: 3,
                      ),
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor:
                          isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      tabs: const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.0),
                          child: Tab(text: 'الأقسام'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.0),
                          child: Tab(text: 'الأماكن المتاحة'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCategoriesTab(theme, isDarkMode),
            _buildAvailablePlacesTab(theme, isDarkMode),
          ],
        ),
      ),
    );
  }

  // Categories tab content
  Widget _buildCategoriesTab(ThemeData theme, bool isDarkMode) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_categories.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.category_outlined,
        title: 'لا توجد أقسام متاحة حالياً',
        message: 'لم يتم العثور على أي أقسام',
        buttonText: 'تحديث الآن',
        onPressed: _loadCategories,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 20.0),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.25,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 24.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.category_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تصفح حسب الأقسام',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 4 : 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  // حساب الفهرس المعكوس ليكون الترتيب من اليمين إلى اليسار
                  final crossAxisCount =
                      MediaQuery.of(context).size.width > 600 ? 4 : 3;
                  final rowIndex = index ~/ crossAxisCount;
                  final rowStartIndex = rowIndex * crossAxisCount;
                  final reverseIndex =
                      rowStartIndex +
                      crossAxisCount -
                      1 -
                      (index % crossAxisCount);

                  // التأكد من أن الفهرس المعكوس في نطاق مقبول
                  final safeIndex =
                      reverseIndex < _categories.length ? reverseIndex : index;

                  final category = _categories[safeIndex];
                  return _buildCategoryCard(
                    context,
                    category['iconUrl'],
                    category['label'],
                    () => _loadApartmentsByCategory(category['label']),
                  );
                }, childCount: _categories.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Available places tab content
  Widget _buildAvailablePlacesTab(ThemeData theme, bool isDarkMode) {
    if (_isLoadingPlaces) {
      return _buildShimmerLoading();
    }

    if (_availablePlaces.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.location_city_outlined,
        title: 'لا توجد أماكن متاحة حالياً',
        message: 'لم يتم العثور على أي أماكن متاحة',
        buttonText: 'تحديث الآن',
        onPressed: _loadAvailablePlaces,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAvailablePlaces,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 20.0),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.secondary.withValues(alpha: 0.15),
                          theme.colorScheme.secondary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.25,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 24.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_city_rounded,
                            color: theme.colorScheme.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'الأماكن المتاحة للإقامة',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.secondary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 4 : 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  // حساب الفهرس المعكوس ليكون الترتيب من اليمين إلى اليسار
                  final crossAxisCount =
                      MediaQuery.of(context).size.width > 600 ? 4 : 3;
                  final rowIndex = index ~/ crossAxisCount;
                  final rowStartIndex = rowIndex * crossAxisCount;
                  final reverseIndex =
                      rowStartIndex +
                      crossAxisCount -
                      1 -
                      (index % crossAxisCount);

                  // التأكد من أن الفهرس المعكوس في نطاق مقبول
                  final safeIndex =
                      reverseIndex < _availablePlaces.length
                          ? reverseIndex
                          : index;

                  final place = _availablePlaces[safeIndex];
                  return _buildPlaceCard(
                    context,
                    place,
                    () => _navigateToPlaceDetails(place),
                  );
                }, childCount: _availablePlaces.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Category details screen
  Widget _buildCategoryDetailsScreen(ThemeData theme, bool isDarkMode) {
    // Show loading state
    if (_isLoadingApartments) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              "جاري تحميل العقارات...",
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // Build results screen
    return CustomScrollView(
      slivers: [
        // Header with category name and back button
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          title: Text(_selectedCategory ?? ""),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _safelyNavigateBack(context),
          ),
        ),

        // Empty state
        if (_apartments.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 80,
                    color: isDarkMode ? Colors.white30 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "لا توجد عقارات في هذا القسم",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed:
                        () => _loadApartmentsByCategory(_selectedCategory!),
                    icon: const Icon(Icons.refresh),
                    label: const Text("إعادة المحاولة"),
                  ),
                ],
              ),
            ),
          ),

        // List of apartments
        if (_apartments.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final apartment = _apartments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildApartmentCard(apartment, theme, isDarkMode),
                );
              }, childCount: _apartments.length),
            ),
          ),
      ],
    );
  }

  Widget _buildApartmentCard(
    Apartment apartment,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          NavigationUtils.navigateWithLoading(
            context: context,
            page: PropertyDetailsScreen(
              property: apartment,
              fromCategoriesScreen: true,
              fromMainScreen: widget.fromMainScreen,
            ),
            minimumLoadingTime: const Duration(milliseconds: 800),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة العقار مع شريط معلومات
            Stack(
              children: [
                // صورة العقار
                SizedBox(
                  height: 200,
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
                                (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey[500],
                                  ),
                                ),
                          )
                          : Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.apartment,
                              size: 40,
                              color: Colors.grey[500],
                            ),
                          ),
                ),

                // السعر في الأعلى اليمين
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${apartment.price.toInt()} جنيه',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // تصنيف العقار في الأسفل
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedCategory ?? 'شاليه',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // تفاصيل العقار
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم العقار
                  Text(
                    apartment.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // الموقع
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          apartment.location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // المميزات
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeatureChip(
                        theme,
                        Icons.meeting_room,
                        '${apartment.rooms} غرف',
                        isDarkMode,
                      ),
                      _buildFeatureChip(
                        theme,
                        Icons.bed,
                        '${apartment.bathrooms} سرير',
                        isDarkMode,
                      ),
                      if (apartment.type.isNotEmpty)
                        _buildFeatureChip(
                          theme,
                          _getFeatureIcon(apartment.type),
                          apartment.type,
                          isDarkMode,
                        ),
                      ...apartment.features
                          .take(3)
                          .map(
                            (feature) => _buildFeatureChip(
                              theme,
                              _getFeatureIcon(feature),
                              feature,
                              isDarkMode,
                            ),
                          ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // وصف مختصر
                  if (apartment.description.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'وصف العقار',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            apartment.description.length > 120
                                ? '${apartment.description.substring(0, 120)}...'
                                : apartment.description,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // أزرار التفاعل
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              () => _navigateToPropertyDetails(apartment),
                          icon: const Icon(Icons.visibility),
                          label: const Text('معلومات اكثر'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: Consumer<FavoritesProvider>(
                            builder: (context, favoritesProvider, _) {
                              final isFavorite = favoritesProvider.isFavorite(
                                apartment.id,
                              );

                              return InkWell(
                                onTap: () async {
                                  // احفظ السياق والحالة قبل العملية غير المتزامنة
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  final bool wasFavorite = isFavorite;
                                  final String propertyName = apartment.name;

                                  // Toggle favorite status
                                  await favoritesProvider.toggleFavorite(
                                    apartment,
                                  );

                                  // تحقق من أن الحالة ما زالت مرتبطة
                                  if (!mounted) return;

                                  // استخدم المتغيرات المحفوظة مسبقًا
                                  final message =
                                      wasFavorite
                                          ? 'تم إزالة $propertyName من المفضلة'
                                          : 'تم إضافة $propertyName إلى المفضلة';

                                  // Use the pre-captured ScaffoldMessenger
                                  scaffoldMessenger.hideCurrentSnackBar();
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        message,
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
                                },
                                child: Center(
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_outline,
                                    color:
                                        isFavorite ? Colors.red : Colors.white,
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
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
    );
  }

  // مكون لعرض ميزة العقار
  Widget _buildFeatureChip(
    ThemeData theme,
    IconData icon,
    String label,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDarkMode
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  isDarkMode
                      ? Colors.white
                      : theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // دالة للحصول على أيقونة مناسبة للميزة
  IconData _getFeatureIcon(String feature) {
    final String lowercaseFeature = feature.toLowerCase();
    if (lowercaseFeature.contains('مطبخ')) {
      return Icons.kitchen;
    } else if (lowercaseFeature.contains('تكييف') ||
        lowercaseFeature.contains('تبريد')) {
      return Icons.ac_unit;
    } else if (lowercaseFeature.contains('انترنت') ||
        lowercaseFeature.contains('واي فاي')) {
      return Icons.wifi;
    } else if (lowercaseFeature.contains('مسبح')) {
      return Icons.pool;
    } else if (lowercaseFeature.contains('غسالة')) {
      return Icons.local_laundry_service;
    } else if (lowercaseFeature.contains('تلفزيون')) {
      return Icons.tv;
    } else if (lowercaseFeature.contains('ثلاجة')) {
      return Icons.kitchen;
    } else {
      return Icons.check_circle;
    }
  }

  // Navigation to property details
  void _navigateToPropertyDetails(Apartment apartment) {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    NavigationUtils.navigateWithLoading(
      context: context,
      page: PropertyDetailsScreen(
        property: apartment,
        fromCategoriesScreen: true,
        fromMainScreen: widget.fromMainScreen,
      ),
    ).then((_) {
      if (mounted) setState(() => _isNavigating = false);
    });
  }

  // Navigation to place details
  void _navigateToPlaceDetails(AvailablePlace place) {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);
    _logger.info('جاري الانتقال إلى تفاصيل المكان: ${place.name}');

    try {
      _logger.info('فتح صفحة التفاصيل للمكان: ${place.name}');
      // Use direct navigation with the fromMainScreen flag set
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder:
                  (context) => PlaceDetailsScreen(
                    place: place,
                    fromMainScreen: widget.fromMainScreen,
                  ),
            ),
          )
          .then((_) {
            if (mounted) setState(() => _isNavigating = false);
          });
    } catch (e) {
      _logger.severe('خطأ في فتح صفحة التفاصيل: $e');
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  // Build category card with enhanced modern design
  Widget _buildCategoryCard(
    BuildContext context,
    String iconUrl,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_isNavigating) return;
            setState(() => _isNavigating = true);

            onTap();

            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _isNavigating = false);
            });
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    isDarkMode
                        ? [
                          Colors.grey[850]!.withValues(alpha: 0.95),
                          Colors.grey[900]!.withValues(alpha: 0.9),
                        ]
                        : [
                          Colors.white,
                          Colors.grey[50]!.withValues(alpha: 0.8),
                        ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : theme.colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.white.withValues(alpha: 0.9),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced icon container with modern design
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child:
                        iconUrl.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: CachedNetworkImage(
                                imageUrl: iconUrl,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.category_rounded,
                                        size: 28,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                              ),
                            )
                            : Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.category_rounded,
                                size: 28,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 10),

                // Enhanced text with better styling
                Container(
                  height: 20,
                  alignment: Alignment.center,
                  child:
                      label.length > 8
                          ? Marquee(
                            animationDuration: const Duration(seconds: 3),
                            backDuration: const Duration(milliseconds: 1200),
                            pauseDuration: const Duration(milliseconds: 1500),
                            direction: Axis.horizontal,
                            textDirection: TextDirection.rtl,
                            autoRepeat: true,
                            child: Text(
                              label,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                          : Text(
                            label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build place card with enhanced modern design
  Widget _buildPlaceCard(
    BuildContext context,
    AvailablePlace place,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _logger.info('تم الضغط على زر التفاصيل: ${place.name}');
            if (_isNavigating) return;
            setState(() => _isNavigating = true);

            try {
              _logger.info('فتح صفحة التفاصيل للمكان: ${place.name}');
              // Pass the fromMainScreen flag to ensure navigation bars are shown
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder:
                          (context) => PlaceDetailsScreen(
                            place: place,
                            fromMainScreen: widget.fromMainScreen,
                          ),
                    ),
                  )
                  .then((_) {
                    if (mounted) setState(() => _isNavigating = false);
                  });
            } catch (e) {
              _logger.severe('خطأ في فتح صفحة التفاصيل: $e');
              if (mounted) setState(() => _isNavigating = false);
            }
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
          highlightColor: theme.colorScheme.secondary.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    isDarkMode
                        ? [
                          Colors.grey[850]!.withValues(alpha: 0.95),
                          Colors.grey[900]!.withValues(alpha: 0.9),
                        ]
                        : [
                          Colors.white,
                          Colors.grey[50]!.withValues(alpha: 0.8),
                        ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : theme.colorScheme.secondary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : theme.colorScheme.secondary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.white.withValues(alpha: 0.9),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced icon container with modern design
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.secondary.withValues(alpha: 0.15),
                        theme.colorScheme.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.15,
                        ),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child:
                        place.iconUrl.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: CachedNetworkImage(
                                imageUrl: place.iconUrl,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.location_city_rounded,
                                        size: 28,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                              ),
                            )
                            : Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_city_rounded,
                                size: 28,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 10),

                // Enhanced text with better styling
                Container(
                  height: 20,
                  alignment: Alignment.center,
                  child:
                      place.name.length > 8
                          ? Marquee(
                            animationDuration: const Duration(seconds: 3),
                            backDuration: const Duration(milliseconds: 1200),
                            pauseDuration: const Duration(milliseconds: 1500),
                            direction: Axis.horizontal,
                            textDirection: TextDirection.rtl,
                            autoRepeat: true,
                            child: Text(
                              place.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                          : Text(
                            place.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Shimmer loading effect
  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return ShimmerLoadingEffect(
          height: 150,
          width: double.infinity,
          borderRadius: BorderRadius.circular(16),
        );
      },
    );
  }
}
