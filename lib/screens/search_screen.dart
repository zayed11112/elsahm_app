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
              height: _showFilters ? null : 0, // Remove fixed height to allow content to determine height
              constraints: _showFilters 
                ? null 
                : const BoxConstraints(maxHeight: 0),
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

            // Results Counter and Loading Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'النتائج: ${_searchResults.length}',
                    style: textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            // Search Results Grid
            _isLoading
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                : _searchResults.isEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('لا توجد نتائج', style: textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          'حاول تغيير معايير البحث',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : GridView.builder(
                  key: ValueKey(_searchResults.length),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final apartment = _searchResults[index];
                    return _buildPropertyCard(apartment);
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Apartment apartment) {
    // تحضير بطاقة العقار
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(property: apartment),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section - تم تبسيطه لعرض الصورة الأولى فقط
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 140,
                  child:
                      apartment.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl:
                                apartment.imageUrls[0], // عرض الصورة الأولى فقط
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                ),
                          )
                          : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.home,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                ),

                // زر المفضلة
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, _) {
                      final bool isFavorite = favoritesProvider.isFavorite(
                        apartment.id,
                      );
                      return GestureDetector(
                        onTap: () async {
                          // التحقق من حالة تسجيل الدخول
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          if (!authProvider.isAuthenticated) {
                            // عرض رسالة تنبيه بضرورة تسجيل الدخول
                            AuthUtils.showAuthRequiredDialog(context);
                            return;
                          }

                          // المستخدم مسجل الدخول، يمكن إضافة/إزالة العقار من المفضلة
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
                            _logger.severe('خطأ في تبديل حالة المفضلة: $e');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2A2A2A)
                                    : Colors.white.withAlpha(204),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color:
                                isFavorite
                                    ? Colors.red
                                    : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.grey,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Property Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    apartment.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          apartment.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    '${apartment.price.toStringAsFixed(0)} جنيه',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
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

  // محتوى الفلتر منفصل عن حاوية الفلتر للتنظيم
  Widget _buildFilterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Make the column take minimum required space
      children: [
        // Header with swapped positions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة ضبط'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              'تصفية النتائج',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),

        // First filter: Housing Category (القسم)
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'القسم',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8), // Reduced from 12 to 8
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
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
                        style: const TextStyle(fontSize: 16),
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
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
              ),
              dropdownColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16), // Reduced from 24 to 16

        // Second filter: Area (المنطقة)
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'المنطقة',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8), // Reduced from 12 to 8
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
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
                        style: const TextStyle(fontSize: 16),
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
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
              ),
              dropdownColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
            ),
          ),
        ),
        // No bottom spacing here
      ],
    );
  }

  // تعديل تصميم زر الفلتر ليكون أكثر جاذبية
  Widget _buildFilterToggleButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color:
            _showFilters
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _showFilters = !_showFilters;
            });

            // لا نقوم بإعادة تحميل العقارات عند الضغط على زر الفلتر
            // فقط نعرض أو نخفي قسم الفلتر
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color:
                      _showFilters
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _showFilters ? 'إخفاء الفلاتر' : 'عرض الفلاتر',
                  style: TextStyle(
                    color:
                        _showFilters
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        maxLength: 50, // Limit text to 50 characters
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(), // Hide the counter
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });

          // Clear results if search is empty
          if (value.isEmpty) {
            _loadInitialProperties();
            return;
          }

          // Only search if text has meaningful content
          if (value.length >= 2) {
            _performSearch(value);
          }
        },
        onSubmitted: (value) => _performSearch(value),
        decoration: InputDecoration(
          hintText: 'ابحث عن شقة، موقع، نوع سكن...',
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon:
              _searchText.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchText = '';
                      });
                      _loadInitialProperties();
                    },
                  )
                  : null,
          suffixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
            size: 26,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
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
