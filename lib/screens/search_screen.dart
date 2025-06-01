import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import '../models/apartment.dart';

import '../services/property_service_supabase.dart';
import '../services/category_service.dart';
import '../services/available_places_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_utils.dart';
import 'property_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Filter state variables
  String? _selectedHousingCategory;
  String? _selectedArea;
  RangeValues _priceRange = const RangeValues(0, 20000);

  // Search results
  List<Apartment> _searchResults = [];
  bool _isLoading = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  // Categories will be loaded dynamically
  final List<String> _housingCategories = ['الكل'];

  // Areas will be loaded dynamically from available_places table
  final List<String> _areas = ['الكل'];

  bool _showFilters = false;
  final PropertyServiceSupabase _propertyService = PropertyServiceSupabase();
  final CategoryService _categoryService = CategoryService();
  final AvailablePlacesService _placesService = AvailablePlacesService();
  final Logger _logger = Logger('SearchScreen');

  @override
  void initState() {
    super.initState();
    _logger.info('بدء تحميل شاشة البحث');
    _loadInitialProperties();
    _loadCategories(); // Load categories from Supabase
    _loadAvailablePlaces(); // Load available places from Supabase
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear search when returning to this screen
    _clearSearchOnReturn();
  }

  // Clear search text and reset state when returning to search screen
  void _clearSearchOnReturn() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      setState(() {
        _searchText = '';
        // Reset filters to default
        _selectedHousingCategory = null;
        _selectedArea = null;
        _priceRange = const RangeValues(0, 20000);
      });
      _loadInitialProperties();
      _logger.info('تم مسح البحث وإعادة تعيين الحالة عند العودة للصفحة');
    }
  }

  // تحميل الأماكن المتاحة من قاعدة البيانات
  Future<void> _loadAvailablePlaces() async {
    try {
      _logger.info('جاري تحميل الأماكن المتاحة من قاعدة البيانات...');

      // الحصول على الأماكن المتاحة من خدمة الأماكن
      final places = await _placesService.getAllPlaces();

      if (mounted) {
        setState(() {
          // إعادة تعيين قائمة المناطق مع الاحتفاظ بخيار "الكل"
          _areas.clear();
          _areas.add('الكل');

          // إضافة أسماء الأماكن المتاحة إلى قائمة المناطق
          for (var place in places) {
            _logger.info('إضافة مكان متاح: ${place.name}');
            _areas.add(place.name);
          }
        });
      }

      _logger.info('تم تحميل ${places.length} مكان متاح للبحث');
    } catch (e) {
      _logger.severe('خطأ في تحميل الأماكن المتاحة: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialProperties() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      _logger.info('تحميل العقارات الأولية');
      // الحصول على العقارات المتاحة بحد أقصى أكبر
      final properties = await _propertyService.getAvailableProperties(
        limit: 200,
      );

      _logger.info('تم استرجاع ${properties.length} عقار من السيرفر');

      if (mounted) {
        setState(() {
          _searchResults = properties;
          _isLoading = false;
        });
      }

      _logger.info('تم تحميل ${properties.length} عقار أولي');
    } catch (e) {
      _logger.severe('خطأ في تحميل العقارات الأولية: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    _logger.info('بدء البحث بالنص: "$query"');

    if (mounted) {
      setState(() {
        _searchText = query;
        _isLoading = true;
      });
    }

    try {
      // الحصول على جميع العقارات المتاحة
      final allProperties = await _propertyService.getAvailableProperties(
        limit: 200,
      );
      _logger.info('تم استرجاع ${allProperties.length} عقار للبحث');

      List<Apartment> searchResults = [];

      // إذا كان النص فارغاً، أظهر كل العقارات
      if (query.isEmpty) {
        searchResults = List.from(allProperties);
        _logger.info(
          'نص البحث فارغ، عرض جميع العقارات: ${searchResults.length}',
        );
      } else {
        // تطبيق البحث النصي
        final searchWords =
            query
                .toLowerCase()
                .trim()
                .split(' ')
                .where((word) => word.isNotEmpty)
                .toList();

        if (searchWords.isNotEmpty) {
          _logger.info('كلمات البحث: ${searchWords.join(', ')}');

          searchResults =
              allProperties.where((apt) {
                // التحقق من جميع الحقول ذات الصلة
                final nameWords = apt.name.toLowerCase();
                final locationWords = apt.location.toLowerCase();
                final descriptionWords = apt.description.toLowerCase();
                final typeWords = apt.type.toLowerCase();
                final categoryWords = apt.category.toLowerCase();

                // دمج النصوص للبحث بسهولة
                final allText =
                    '$nameWords $locationWords $descriptionWords $typeWords $categoryWords';

                // التحقق مما إذا كانت أي كلمة بحث موجودة في أي حقل
                for (final word in searchWords) {
                  if (allText.contains(word)) {
                    return true;
                  }
                }

                // التحقق من الميزات بشكل منفصل
                for (final feature in apt.features) {
                  final featureText = feature.toLowerCase();
                  for (final word in searchWords) {
                    if (featureText.contains(word)) {
                      return true;
                    }
                  }
                }

                return false;
              }).toList();

          _logger.info(
            'تم العثور على ${searchResults.length} نتيجة بحث مطابقة',
          );
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = searchResults;
          _isLoading = false;
        });

        // تطبيق أي فلاتر نشطة
        if (_selectedHousingCategory != null ||
            _selectedArea != null ||
            _priceRange != const RangeValues(0, 20000)) {
          _logger.info('توجد فلاتر نشطة، تطبيقها الآن');
          _applyFilters();
        }
      }

      _logger.info('اكتمل البحث: ${searchResults.length} نتيجة');
    } catch (e) {
      _logger.severe('خطأ في إجراء البحث: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyFilters() async {
    if (_searchResults.isEmpty) {
      _logger.info('لا توجد نتائج للتصفية، جاري تحميل العقارات أولاً');
      await _loadInitialProperties();
      if (_searchResults.isNotEmpty) {
        await _applyFiltersInternal();
      }
      return;
    }

    await _applyFiltersInternal();
  }

  Future<void> _applyFiltersInternal() async {
    _logger.info(
      'بدء تطبيق الفلاتر الداخلية على ${_searchResults.length} عقار',
    );
    _logger.info('القسم: $_selectedHousingCategory، المنطقة: $_selectedArea');

    // نسخة جديدة من نتائج البحث الحالية
    List<Apartment> filteredResults = List.from(_searchResults);
    _logger.info('نسخة جديدة من النتائج: ${filteredResults.length} عقار');

    // تصفية حسب القسم (الفئة)
    if (_selectedHousingCategory != null &&
        _selectedHousingCategory != 'الكل') {
      _logger.info('تطبيق فلتر القسم: $_selectedHousingCategory');

      try {
        // الحصول على العقارات المرتبطة بالقسم المحدد من قاعدة البيانات
        final propertiesByCategory = await _propertyService
            .getPropertiesByCategory(_selectedHousingCategory!, limit: 200);
        _logger.info(
          'تم العثور على ${propertiesByCategory.length} عقار مرتبط بالقسم: $_selectedHousingCategory',
        );

        // تصفية النتائج الحالية للحصول فقط على العقارات المرتبطة بالقسم المحدد
        final propertyIds = propertiesByCategory.map((p) => p.id).toSet();
        filteredResults =
            filteredResults
                .where((apartment) => propertyIds.contains(apartment.id))
                .toList();
      } catch (e) {
        _logger.severe('خطأ في تطبيق فلتر القسم: $e');
        // في حالة حدوث خطأ، نستخدم الطريقة القديمة للتصفية بناءً على حقل category
        _logger.info('استخدام الطريقة البديلة للتصفية بناءً على حقل category');

        if (filteredResults.isNotEmpty) {
          _logger.info(
            'فئات العقارات المتاحة: ${filteredResults.take(5).map((a) => a.category).toSet().join(', ')}',
          );
        }

        filteredResults =
            filteredResults.where((apartment) {
              // تحقق مما إذا كانت الفئة المحددة موجودة في فئة العقار
              bool exactMatch =
                  apartment.category.toLowerCase() ==
                  _selectedHousingCategory!.toLowerCase();
              bool containsMatch = apartment.category.toLowerCase().contains(
                _selectedHousingCategory!.toLowerCase(),
              );

              if (exactMatch || containsMatch) {
                _logger.info(
                  'تطابق وجد: ${apartment.name} (${apartment.category})',
                );
                return true;
              }
              return false;
            }).toList();
      }

      _logger.info('بعد فلتر القسم: ${filteredResults.length} نتيجة');
    }

    // تصفية حسب المنطقة (الأماكن المتاحة)
    if (_selectedArea != null && _selectedArea != 'الكل') {
      _logger.info('تطبيق فلتر المنطقة (المكان المتاح): $_selectedArea');

      try {
        // الحصول على العقارات المرتبطة بالمكان المتاح المحدد
        final propertiesByPlace = await _propertyService.getPropertiesByPlace(
          _selectedArea!,
          limit: 200,
        );
        _logger.info(
          'تم العثور على ${propertiesByPlace.length} عقار مرتبط بالمكان: $_selectedArea',
        );

        // تصفية النتائج الحالية للحصول فقط على العقارات المرتبطة بالمكان المحدد
        final propertyIds = propertiesByPlace.map((p) => p.id).toSet();
        filteredResults =
            filteredResults
                .where((apartment) => propertyIds.contains(apartment.id))
                .toList();
      } catch (e) {
        _logger.severe('خطأ في تطبيق فلتر المنطقة: $e');
        // في حالة حدوث خطأ، نستخدم الطريقة القديمة للتصفية بناءً على الموقع
        filteredResults =
            filteredResults.where((apartment) {
              return apartment.location.toLowerCase().contains(
                _selectedArea!.toLowerCase(),
              );
            }).toList();
      }

      _logger.info('بعد فلتر المنطقة: ${filteredResults.length} نتيجة');
    }

    // تصفية حسب نطاق السعر
    _logger.info('تطبيق فلتر السعر: ${_priceRange.start} - ${_priceRange.end}');
    filteredResults =
        filteredResults.where((apartment) {
          final price = apartment.price;
          return price >= _priceRange.start && price <= _priceRange.end;
        }).toList();
    _logger.info('بعد فلتر السعر: ${filteredResults.length} نتيجة');

    // تحديث واجهة المستخدم
    setState(() {
      _searchResults = filteredResults;
    });

    _logger.info('اكتملت الفلترة: ${filteredResults.length} نتيجة نهائية');
  }

  // Reset all filters
  void _resetFilters() {
    _logger.info('إعادة ضبط الفلاتر');
    setState(() {
      _selectedHousingCategory = null;
      _selectedArea = null;
      _priceRange = const RangeValues(0, 20000);
    });

    // إعادة تحميل العقارات
    _loadInitialProperties();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث', textAlign: TextAlign.center),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern Search Bar with rounded corners and shadow
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchBar(),
            ),

            // Filter Toggle Button
            Center(child: _buildFilterToggleButton()),

            // Filter Section
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height:
                  _showFilters
                      ? null
                      : 0, // Remove fixed height to allow content to determine height
              constraints:
                  _showFilters ? null : const BoxConstraints(maxHeight: 0),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    _showFilters
                        ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                        : [],
              ),
              child:
                  _showFilters
                      ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildFilterContent(),
                      )
                      : const SizedBox(),
            ),

            // Enhanced Search Results Grid
            _isLoading
                ? Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey[850]!.withValues(alpha: 0.5)
                            : Colors.grey[50]!.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'جاري البحث...',
                        style: textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                : _searchResults.isEmpty
                ? Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                        theme.colorScheme.primary.withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 60,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'لا توجد نتائج',
                        style: textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'حاول تغيير معايير البحث أو الفلاتر',
                        style: textTheme.bodyLarge?.copyWith(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    key: ValueKey(_searchResults.length),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final apartment = _searchResults[index];
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        curve: Curves.easeOutBack,
                        child: _buildPropertyCard(apartment),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Apartment apartment) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [
                    Colors.grey[850]!.withValues(alpha: 0.9),
                    Colors.grey[900]!.withValues(alpha: 0.8),
                  ]
                  : [Colors.white, Colors.grey[50]!.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.9),
            blurRadius: 8,
            offset: const Offset(0, -2),
            spreadRadius: 0,
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
                builder:
                    (context) => PropertyDetailsScreen(property: apartment),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section - with improved aspect ratio and error handling
              AspectRatio(
                aspectRatio: 1.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    apartment.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: apartment.imageUrls[0],
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color:
                                    isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color:
                                    isDarkMode
                                        ? Colors.grey[850]
                                        : Colors.grey[100],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.home_work_outlined,
                                      size: 40,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'لا توجد صورة',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        )
                        : Container(
                          color:
                              isDarkMode ? Colors.grey[850] : Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_work_outlined,
                                size: 40,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'لا توجد صورة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                    // Price badge overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Text(
                          '${apartment.price.toStringAsFixed(0)} جنيه',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, _) {
                          final bool isFavorite = favoritesProvider.isFavorite(
                            apartment.id,
                          );
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                // التحقق من حالة تسجيل الدخول
                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                if (!authProvider.isAuthenticated) {
                                  AuthUtils.showAuthRequiredDialog(context);
                                  return;
                                }

                                try {
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
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
                                  _logger.severe(
                                    'خطأ في تبديل حالة المفضلة: $e',
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black38
                                          : Colors.white.withAlpha(225),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      isFavorite
                                          ? Colors.red
                                          : isDarkMode
                                          ? Colors.white
                                          : Colors.grey[700],
                                  size: 22,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Property Info with improved layout
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with better styling
                    Text(
                      apartment.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Location with improved icon alignment
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            apartment.location,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Add a subtle separator
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with enhanced design
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.1),
                theme.colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? Colors.grey[800]!.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: TextButton.icon(
                  onPressed: _resetFilters,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    'إعادة ضبط',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.filter_alt_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تصفية النتائج',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // First filter: Housing Category (القسم)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.grey[800]!.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'القسم',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDarkMode
                            ? [
                              Colors.grey[700]!.withValues(alpha: 0.8),
                              Colors.grey[800]!.withValues(alpha: 0.6),
                            ]
                            : [Colors.white, Colors.grey[50]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedHousingCategory ?? 'الكل',
                    items:
                        _housingCategories.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedHousingCategory = value;
                        _applyFilters();
                      });
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Second filter: Area (المنطقة)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.grey[800]!.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'المنطقة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDarkMode
                            ? [
                              Colors.grey[700]!.withValues(alpha: 0.8),
                              Colors.grey[800]!.withValues(alpha: 0.6),
                            ]
                            : [Colors.white, Colors.grey[50]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedArea ?? 'الكل',
                    items:
                        _areas.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedArea = value;
                        _applyFilters();
                      });
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterToggleButton() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient:
              _showFilters
                  ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  )
                  : LinearGradient(
                    colors:
                        isDarkMode
                            ? [
                              Colors.grey[800]!.withValues(alpha: 0.9),
                              Colors.grey[850]!.withValues(alpha: 0.8),
                            ]
                            : [Colors.white, Colors.grey[50]!],
                  ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _showFilters
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  _showFilters
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _showFilters ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _showFilters ? Icons.tune_rounded : Icons.tune_rounded,
                      color:
                          _showFilters
                              ? Colors.white
                              : theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _showFilters ? 'إخفاء الفلاتر' : 'عرض الفلاتر',
                    style: TextStyle(
                      color:
                          _showFilters
                              ? Colors.white
                              : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
                  : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isDarkMode
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 2,
        ),
        boxShadow: [
          // Primary shadow for depth
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          // Secondary shadow for glow effect
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
          // Inner highlight
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.9),
            blurRadius: 1,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Clear button (left side)
          if (_searchText.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                    _loadInitialProperties();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.grey[700]!.withValues(alpha: 0.6)
                              : Colors.grey[200]!.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDarkMode
                                ? Colors.grey[600]!.withValues(alpha: 0.3)
                                : Colors.grey[300]!.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

          // Search input field
          Expanded(
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLength: 50,
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => const SizedBox.shrink(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : const Color(0xFF1D1D1F),
                letterSpacing: 0.3,
                height: 1.2,
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });

                if (value.isEmpty) {
                  _loadInitialProperties();
                  return;
                }

                if (value.length >= 2) {
                  _performSearch(value);
                }
              },
              onSubmitted: (value) => _performSearch(value),
              decoration: InputDecoration(
                hintText: 'ابحث عن شقة، موقع، نوع سكن...',
                hintTextDirection: TextDirection.rtl,
                hintStyle: TextStyle(
                  color:
                      isDarkMode
                          ? Colors.grey[400]!.withValues(alpha: 0.8)
                          : Colors.grey[500]!.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),

          // Search icon (right side)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _performSearch(_searchText),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Load categories from the CategoryService
  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();

      if (mounted) {
        setState(() {
          // Update the housing categories list - start fresh
          _housingCategories.clear();
          _housingCategories.add('الكل');

          _logger.info('تم استلام ${categories.length} قسم من قاعدة البيانات');

          // تم استخدام حقل label لأنه يحتوي على قيمة name من قاعدة البيانات (كما رأينا في كود خدمة الفئات)
          for (var category in categories) {
            if (category['label'] != null) {
              _logger.info('إضافة قسم: ${category['label']}');
              _housingCategories.add(category['label']);
            }
          }
        });
      }
      _logger.info('تم تحميل ${categories.length} قسم للبحث');
    } catch (e) {
      _logger.severe('خطأ في تحميل الأقسام: $e');
    }
  }
}
