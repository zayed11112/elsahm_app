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
import '../utils/notification_utils.dart';
import '../widgets/property_card.dart';
import '../widgets/shimmer_loading_effect.dart';
import '../widgets/custom_tab_indicator.dart';
import '../widgets/empty_state_widget.dart';
import 'property_details_screen.dart';
import 'place_details_screen.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';

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

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
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

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
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
    await Future.wait([
      _loadCategories(),
      _loadAvailablePlaces(),
    ]);
    
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
    _searchController.dispose();
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
  void _safelyNavigateToHome(BuildContext context) {
    if (_isNavigating) return;
    
    setState(() => _isNavigating = true);
    try {
      // Navigate to the root/home screen by popping all routes
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _logger.severe('خطأ في العودة للرئيسية: $e');
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isNavigating = false);
      });
    }
  }
  
  // Filter apartments based on search query
  List<Apartment> get _filteredApartments {
    if (_searchQuery.isEmpty) return _apartments;
    
    return _apartments.where((apartment) {
      return apartment.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             apartment.location.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    
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

    return WillPopScope(
      onWillPop: () async {
        if (_isNavigating) return false;
        setState(() => _isNavigating = true);
        
        if (_selectedCategory != null) {
          setState(() => _selectedCategory = null);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _isNavigating = false);
          });
          return false;
        }
        
        setState(() => _isNavigating = false);
        return true;
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
              child: _selectedCategory == null 
                  ? _buildMainCategoriesScreen(theme, isDarkMode)
                  : _buildCategoryDetailsScreen(theme, isDarkMode),
            ),
          ),
        ),
      ),
    );
  }

  // Main categories screen with tabbed interface
  Widget _buildMainCategoriesScreen(ThemeData theme, bool isDarkMode) {
    return SafeArea(
      bottom: false, // Don't add safe area at bottom, we'll handle it manually
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _safelyNavigateBack(context),
            ),
            title: const Text('الأقسام والأماكن المتاحة'),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52), // Increase from 48 to 52
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode 
                        ? Colors.grey[800]! 
                        : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: CustomTabIndicator(
                    color: theme.colorScheme.primary,
                    radius: 4,
                    indicatorHeight: 3,
                  ),
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: isDarkMode 
                    ? Colors.grey[400] 
                    : Colors.grey[700],
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
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                child: Text(
                  'تصفح حسب الأقسام',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = _categories[index];
                    return _buildCategoryCard(
                      context,
                      category['iconUrl'],
                      category['label'],
                      () => _loadApartmentsByCategory(category['label']),
                    );
                  },
                  childCount: _categories.length,
                ),
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
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                child: Text(
                  'الأماكن المتاحة للإقامة',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final place = _availablePlaces[index];
                    return _buildPlaceCard(
                      context,
                      place,
                      () => _navigateToPlaceDetails(place),
                    );
                  },
                  childCount: _availablePlaces.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Category details screen
  Widget _buildCategoryDetailsScreen(ThemeData theme, bool isDarkMode) {
    return Scaffold(
      body: SafeArea(
        bottom: false, // Allow content to extend below bottom safe area
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              floating: true,
              title: Text(_selectedCategory!),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _safelyNavigateBack(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () => _safelyNavigateToHome(context),
                  tooltip: 'الرئيسية',
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث في ${_selectedCategory!}...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                        ? Colors.grey[800]
                        : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: _isLoadingApartments
            ? _buildShimmerLoading()
            : _buildApartmentsContent(theme, isDarkMode),
        ),
      ),
    );
  }
  
  // Apartments content
  Widget _buildApartmentsContent(ThemeData theme, bool isDarkMode) {
    if (_filteredApartments.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.apartment,
        title: 'لا توجد عقارات متاحة',
        message: _searchQuery.isNotEmpty
          ? 'لم يتم العثور على نتائج مطابقة لبحثك'
          : 'لا توجد عقارات متاحة في هذا القسم حالياً',
        buttonText: 'تحديث',
        onPressed: () => _loadApartmentsByCategory(_selectedCategory!),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadApartmentsByCategory(_selectedCategory!),
      child: Padding(
        // Remove bottom padding
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0),
        child: ListView.builder(
          // Remove bottom padding
          padding: EdgeInsets.zero,
          itemCount: _filteredApartments.length,
          itemBuilder: (context, index) {
            final apartment = _filteredApartments[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 3),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToPropertyDetails(apartment),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // صورة العقار مع شريط معلومات
                        Stack(
                          children: [
                            // صورة العقار
                            Container(
                              height: 200,
                              width: double.infinity,
                              child: apartment.imageUrls.isNotEmpty 
                                ? CachedNetworkImage(
                                    imageUrl: apartment.imageUrls[0],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.black.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
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
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                                  _buildFeatureChip(theme, Icons.meeting_room, '${apartment.rooms} غرف', isDarkMode),
                                  _buildFeatureChip(theme, Icons.bed, '${apartment.bathrooms} سرير', isDarkMode),
                                  if (apartment.type.isNotEmpty)
                                    _buildFeatureChip(theme, _getFeatureIcon(apartment.type), apartment.type, isDarkMode),
                                  ...apartment.features.take(3).map((feature) => 
                                    _buildFeatureChip(theme, _getFeatureIcon(feature), feature, isDarkMode)
                                  ).toList(),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // وصف مختصر
                              if (apartment.description.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? Colors.grey[850] 
                                        : Colors.grey[100],
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
                                      onPressed: () => _navigateToPropertyDetails(apartment),
                                      icon: const Icon(Icons.visibility),
                                      label: const Text('معلومات اكثر'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: BorderSide(
                                          color: theme.colorScheme.primary,
                                        ),
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
                                          color: theme.colorScheme.primary.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      clipBehavior: Clip.antiAlias,
                                      child: Consumer<FavoritesProvider>(
                                        builder: (context, favoritesProvider, _) {
                                          final isFavorite = favoritesProvider.isFavorite(apartment.id);
                                          
                                          return InkWell(
                                            onTap: () async {
                                              // Toggle favorite status
                                              await favoritesProvider.toggleFavorite(apartment);
                                              
                                              // Show appropriate message with centered text
                                              if (!mounted) return;
                                              
                                              // Use the utility class instead
                                              final message = isFavorite 
                                                ? 'تم إزالة ${apartment.name} من المفضلة' 
                                                : 'تم إضافة ${apartment.name} إلى المفضلة';
                                              
                                              NotificationUtils.showCenteredSnackBar(context, message);
                                            },
                                            child: Center(
                                              child: Icon(
                                                isFavorite ? Icons.favorite : Icons.favorite_outline,
                                                color: isFavorite ? Colors.red : Colors.white,
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // مكون لعرض ميزة العقار
  Widget _buildFeatureChip(ThemeData theme, IconData icon, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? theme.colorScheme.primary.withOpacity(0.2) 
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode 
              ? theme.colorScheme.primary.withOpacity(0.3) 
              : theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : theme.colorScheme.primary.withOpacity(0.8),
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
    } else if (lowercaseFeature.contains('تكييف') || lowercaseFeature.contains('تبريد')) {
      return Icons.ac_unit;
    } else if (lowercaseFeature.contains('انترنت') || lowercaseFeature.contains('واي فاي')) {
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
  
  // دالة لحساب الفترة منذ إنشاء العقار
  String _getDaysAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'بالأمس';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} يوم';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months شهر';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years سنة';
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
      // استخدام التنقل المباشر لضمان عمله
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlaceDetailsScreen(place: place),
        ),
      ).then((_) {
        if (mounted) setState(() => _isNavigating = false);
      });
    } catch (e) {
      _logger.severe('خطأ في فتح صفحة التفاصيل: $e');
      if (mounted) setState(() => _isNavigating = false);
    }
  }
  
  // Build category card
  Widget _buildCategoryCard(
    BuildContext context,
    String iconUrl,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (_isNavigating) return;
          setState(() => _isNavigating = true);
          
          onTap();
          
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _isNavigating = false);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                ? [
                    Colors.grey[850]!,
                    Colors.grey[900]!,
                  ]
                : [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: iconUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: CachedNetworkImage(
                          imageUrl: iconUrl,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.category,
                            size: 24,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.category,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build place card
  Widget _buildPlaceCard(
    BuildContext context,
    AvailablePlace place,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          _logger.info('تم الضغط على زر التفاصيل: ${place.name}');
          if (_isNavigating) return;
          setState(() => _isNavigating = true);
          
          try {
            _logger.info('فتح صفحة التفاصيل للمكان: ${place.name}');
            // استخدام التنقل المباشر لضمان عمله
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlaceDetailsScreen(place: place),
              ),
            ).then((_) {
              if (mounted) setState(() => _isNavigating = false);
            });
          } catch (e) {
            _logger.severe('خطأ في فتح صفحة التفاصيل: $e');
            if (mounted) setState(() => _isNavigating = false);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                ? [
                    Colors.grey[850]!,
                    Colors.grey[900]!,
                  ]
                : [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: place.iconUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: CachedNetworkImage(
                          imageUrl: place.iconUrl,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.location_city,
                            size: 24,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.location_city,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                place.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
