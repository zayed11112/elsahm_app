import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'dart:async'; // لإدارة المهلة الزمنية
import '../models/apartment.dart';

class PropertyServiceSupabase {
  final Logger _logger = Logger('PropertyServiceSupabase');
  // استخدام getter method للحصول على client عند الحاجة فقط
  SupabaseClient get _supabase => Supabase.instance.client;

  // تخزين مؤقت للبيانات
  final Map<String, List<Apartment>> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 10);
  final Map<String, DateTime> _cacheTimestamps = {};

  // زمن انتظار الطلبات
  final Duration _timeout = const Duration(seconds: 15);

  // الحد الأقصى لمحاولات إعادة الاتصال
  final int _maxRetries = 3;

  // مخزن مؤقت منفصل للأقسام والأماكن
  final Map<String, List<Map<String, dynamic>>> _cacheMaps = {};

  // جلب أحدث العقارات
  Future<List<Apartment>> getLatestProperties({int limit = 10}) async {
    const cacheKey = 'latest_properties';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey)) {
      _logger.info('استخدام البيانات المخزنة مؤقتاً للعقارات الحديثة');
      return _cache[cacheKey]!;
    }

    return _fetchWithRetry(() async {
      _logger.info('بدء جلب أحدث العقارات من Supabase...');

      try {
        // محاولة جلب البيانات مع تطبيق شرط is_available = true فقط
        final response = await _supabase
            .from('properties')
            .select()
            .eq('is_available', true)
            .order('created_at', ascending: false)
            .limit(limit)
            .timeout(_timeout);

        _logger.info('تم استلام ${response.length} عقار من Supabase');

        // تحويل البيانات إلى كائنات Apartment
        final apartments =
            response
                .map<Apartment>((data) => Apartment.fromSupabase(data))
                .toList();

        // تخزين البيانات مؤقتاً
        _cacheResponse(cacheKey, apartments);

        return apartments;
      } catch (e) {
        _logger.severe('خطأ في جلب أحدث العقارات: $e');
        // إعادة قائمة فارغة في حالة الخطأ
        return [];
      }
    });
  }

  // جلب العقارات حسب القسم
  Future<List<Apartment>> getPropertiesByCategory(
    String categoryName, {
    int limit = 10,
  }) async {
    final cacheKey = 'category_$categoryName';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey)) {
      _logger.info('استخدام البيانات المخزنة مؤقتاً للقسم: $categoryName');
      return _cache[cacheKey]!;
    }

    return _fetchWithRetry(() async {
      _logger.info('جلب العقارات من القسم: $categoryName');

      // أولاً، نحصل على معرف القسم من اسمه
      final categoryResponse = await _supabase
          .from('categories')
          .select('id')
          .eq('name', categoryName)
          .limit(1)
          .maybeSingle()
          .timeout(_timeout);

      // التحقق من وجود القسم
      if (categoryResponse == null) {
        _logger.warning('لم يتم العثور على القسم: $categoryName');
        return [];
      }

      final categoryId = categoryResponse['id'];

      // ثم نحصل على معرفات العقارات المرتبطة بهذا القسم
      // استخدام property_categories بدلاً من category_properties
      final response = await _supabase
          .from('property_categories')
          .select('property_id')
          .eq('category_id', categoryId)
          .limit(limit)
          .timeout(_timeout);

      if (response.isEmpty) {
        _logger.info('لا توجد عقارات مرتبطة بالقسم: $categoryName');
        return [];
      }

      // استخراج معرفات العقارات
      final propertyIds =
          response
              .map<String>((item) => item['property_id'] as String)
              .toList();

      // جلب تفاصيل العقارات المتاحة فقط
      final propertiesResponse = await _supabase
          .from('properties')
          .select()
          .inFilter('id', propertyIds)
          .eq('is_available', true)
          .timeout(_timeout);

      // تحويل البيانات إلى كائنات Apartment
      final apartments =
          propertiesResponse
              .map<Apartment>((data) => Apartment.fromSupabase(data))
              .toList();

      // تخزين البيانات مؤقتاً
      _cacheResponse(cacheKey, apartments);

      return apartments;
    });
  }

  // جلب عقار بواسطة المعرف
  Future<Apartment?> getPropertyById(String id) async {
    final cacheKey = 'property_$id';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      _logger.info('استخدام البيانات المخزنة مؤقتاً للعقار: $id');
      return _cache[cacheKey]!.first;
    }

    return _fetchWithRetry(() async {
      _logger.info('جلب العقار بالمعرف: $id');

      try {
        // 1. جلب بيانات العقار الأساسية
        final response = await _supabase
            .from('properties')
            .select()
            .eq('id', id)
            .maybeSingle()
            .timeout(_timeout);

        if (response == null) {
          _logger.warning('لم يتم العثور على العقار بالمعرف: $id');
          return null;
        }

        // 2. جلب الأقسام المرتبطة بالعقار
        final categoriesData = await getCategoriesForProperty(id);

        // 3. جلب الأماكن المرتبطة بالعقار
        final placesData = await getPlacesForProperty(id);

        // 4. دمج البيانات مع العقار
        final propertyWithRelations = {
          ...response,
          'categories': categoriesData,
          'places': placesData,
        };

        // تحويل البيانات إلى كائن Apartment
        final apartment = Apartment.fromSupabase(propertyWithRelations);

        // تخزين البيانات مؤقتاً
        _cacheResponse(cacheKey, [apartment]);

        return apartment;
      } catch (e) {
        _logger.severe('خطأ في جلب العقار مع العلاقات: $e');
        return null;
      }
    });
  }

  // البحث عن العقارات
  Future<List<Apartment>> searchProperties(
    String query, {
    int limit = 20,
  }) async {
    // لا نستخدم التخزين المؤقت لنتائج البحث لأنها قد تتغير بشكل متكرر

    return _fetchWithRetry(() async {
      _logger.info('البحث عن العقارات بالاستعلام: $query');

      final response = await _supabase
          .from('properties')
          .select()
          .eq('is_available', true)
          .or(
            'name.ilike.%$query%,address.ilike.%$query%,description.ilike.%$query%',
          )
          .limit(limit)
          .timeout(_timeout);

      return response
          .map<Apartment>((data) => Apartment.fromSupabase(data))
          .toList();
    });
  }

  // جلب العقارات حسب النوع
  Future<List<Apartment>> getPropertiesByType(
    String type, {
    int limit = 20,
  }) async {
    final cacheKey = 'type_$type';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey)) {
      _logger.info('استخدام البيانات المخزنة مؤقتاً للنوع: $type');
      return _cache[cacheKey]!;
    }

    return _fetchWithRetry(() async {
      _logger.info('جلب العقارات من النوع: $type');

      final response = await _supabase
          .from('properties')
          .select()
          .eq('type', type)
          .eq('is_available', true)
          .limit(limit)
          .timeout(_timeout);

      final apartments =
          response
              .map<Apartment>((data) => Apartment.fromSupabase(data))
              .toList();

      // تخزين البيانات مؤقتاً
      _cacheResponse(cacheKey, apartments);

      return apartments;
    });
  }

  // جلب العقارات المتاحة فقط
  Future<List<Apartment>> getAvailableProperties({int limit = 20}) async {
    const cacheKey = 'available_properties';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey)) {
      _logger.info('استخدام البيانات المخزنة مؤقتاً للعقارات المتاحة');
      return _cache[cacheKey]!;
    }

    return _fetchWithRetry(() async {
      _logger.info('جلب العقارات المتاحة...');

      try {
        final response = await _supabase
            .from('properties')
            .select()
            .eq('is_available', true)
            .order('created_at', ascending: false)
            .limit(limit)
            .timeout(_timeout);

        _logger.info('استجابة الخادم: $response');

        final apartments =
            response.map<Apartment>((data) {
              _logger.fine('بيانات العقار: $data');
              return Apartment.fromSupabase(data);
            }).toList();

        // تخزين البيانات مؤقتاً
        _cacheResponse(cacheKey, apartments);

        _logger.info('تم جلب ${apartments.length} عقار متاح');
        return apartments;
      } catch (e) {
        _logger.severe('خطأ في جلب العقارات المتاحة: $e');
        return [];
      }
    });
  }

  // جلب العقارات حسب نطاق السعر
  Future<List<Apartment>> getPropertiesByPriceRange(
    double minPrice,
    double maxPrice, {
    int limit = 20,
  }) async {
    final cacheKey = 'price_$minPrice-$maxPrice';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey)) {
      _logger.info(
        'استخدام البيانات المخزنة مؤقتاً لنطاق السعر: $minPrice - $maxPrice',
      );
      return _cache[cacheKey]!;
    }

    return _fetchWithRetry(() async {
      _logger.info('جلب العقارات في نطاق السعر: $minPrice - $maxPrice');

      final response = await _supabase
          .from('properties')
          .select()
          .eq('is_available', true)
          .gte('price', minPrice)
          .lte('price', maxPrice)
          .limit(limit)
          .timeout(_timeout);

      final apartments =
          response
              .map<Apartment>((data) => Apartment.fromSupabase(data))
              .toList();

      // تخزين البيانات مؤقتاً
      _cacheResponse(cacheKey, apartments);

      return apartments;
    });
  }

  // دالة مساعدة للتحقق من صلاحية التخزين المؤقت
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();
    return now.difference(timestamp) < _cacheDuration;
  }

  // دالة مساعدة لتخزين الاستجابة مؤقتاً
  void _cacheResponse(String key, List<Apartment> data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  // دالة مساعدة لمحاولة جلب البيانات مع إعادة المحاولة في حالة الفشل
  Future<T> _fetchWithRetry<T>(Future<T> Function() fetcher) async {
    int retries = 0;
    Duration delay = const Duration(milliseconds: 800);

    while (true) {
      try {
        return await fetcher();
      } catch (e) {
        retries++;
        _logger.warning('فشلت محاولة الجلب رقم $retries: $e');

        if (retries >= _maxRetries) {
          _logger.severe('فشلت عملية الجلب بعد $_maxRetries محاولات: $e');
          // إعادة القائمة الفارغة أو إعادة رمي الاستثناء حسب نوع الدالة
          if (T == Apartment) {
            return null as T;
          } else if (T == List<Apartment>) {
            return <Apartment>[] as T;
          } else {
            // محاولة إعادة قائمة فارغة في حالة كان النوع غير معروف
            try {
              return <Apartment>[] as T;
            } catch (_) {
              // إذا فشل التحويل، نعيد استثناء
              throw Exception('فشلت عملية جلب البيانات: $e');
            }
          }
        }

        _logger.warning(
          'إعادة المحاولة بعد ${delay.inMilliseconds} مللي ثانية',
        );
        await Future.delayed(delay);

        // زيادة وقت الانتظار بشكل تصاعدي، لكن مع حد أقصى 5 ثواني
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
        if (delay > const Duration(seconds: 5)) {
          delay = const Duration(seconds: 5);
        }
      }
    }
  }

  // تعديل دالة مسح التخزين المؤقت لتشمل المخزن المنفصل للأقسام والأماكن
  void clearCache({String? key}) {
    if (key != null) {
      _cache.remove(key);
      _cacheMaps.remove(key);
      _cacheTimestamps.remove(key);
      _logger.info('تم مسح التخزين المؤقت للمفتاح: $key');
    } else {
      _cache.clear();
      _cacheMaps.clear();
      _cacheTimestamps.clear();
      _logger.info('تم مسح جميع التخزين المؤقت');
    }
  }

  // جلب العقارات حسب القسم والمكان
  Future<List<Apartment>> getPropertiesByCategoryAndPlace(
    String categoryName,
    String placeName, {
    int limit = 10,
  }) async {
    final cacheKey = 'category_${categoryName}_place_$placeName';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey)) {
      _logger.info(
        'استخدام البيانات المخزنة مؤقتاً للقسم: $categoryName والمكان: $placeName',
      );
      return _cache[cacheKey]!;
    }

    return _fetchWithRetry(() async {
      _logger.info('جلب العقارات من القسم: $categoryName والمكان: $placeName');

      // أولاً، نحصل على معرف القسم من اسمه
      final categoryResponse = await _supabase
          .from('categories')
          .select('id')
          .eq('name', categoryName)
          .limit(1)
          .maybeSingle()
          .timeout(_timeout);

      // التحقق من وجود القسم
      if (categoryResponse == null) {
        _logger.warning('لم يتم العثور على القسم: $categoryName');
        return [];
      }

      final categoryId = categoryResponse['id'];

      // ثانياً، نحصل على معرف المكان من اسمه
      final placeResponse = await _supabase
          .from('available_places')
          .select('id')
          .eq('name', placeName)
          .limit(1)
          .maybeSingle()
          .timeout(_timeout);

      // التحقق من وجود المكان
      if (placeResponse == null) {
        _logger.warning('لم يتم العثور على المكان: $placeName');
        return [];
      }

      final placeId = placeResponse['id'];

      // أولاً نحصل على العقارات المرتبطة بالقسم المحدد
      final categoryPropertiesQuery = await _supabase
          .from('property_categories')
          .select('property_id')
          .eq('category_id', categoryId)
          .timeout(_timeout);

      if (categoryPropertiesQuery.isEmpty) {
        _logger.info('لا توجد عقارات مرتبطة بالقسم: $categoryName');
        return [];
      }

      // ثم نحصل على العقارات المرتبطة بالمكان المحدد
      final placePropertiesQuery = await _supabase
          .from('property_available_places')
          .select('property_id')
          .eq('place_id', placeId)
          .timeout(_timeout);

      if (placePropertiesQuery.isEmpty) {
        _logger.info('لا توجد عقارات مرتبطة بالمكان: $placeName');
        return [];
      }

      // استخراج معرفات العقارات للقسم المحدد
      final categoryPropertyIds =
          categoryPropertiesQuery
              .map<String>((item) => item['property_id'] as String)
              .toList();

      // استخراج معرفات العقارات للمكان المحدد
      final placePropertyIds =
          placePropertiesQuery
              .map<String>((item) => item['property_id'] as String)
              .toList();

      // الحصول على معرفات العقارات المشتركة (موجودة في القسم والمكان)
      final commonPropertyIds =
          categoryPropertyIds
              .where((id) => placePropertyIds.contains(id))
              .toList();

      if (commonPropertyIds.isEmpty) {
        _logger.info(
          'لا توجد عقارات مشتركة بين القسم: $categoryName والمكان: $placeName',
        );
        return [];
      }

      // جلب تفاصيل العقارات
      final propertiesResponse = await _supabase
          .from('properties')
          .select()
          .inFilter('id', commonPropertyIds)
          .eq('is_available', true)
          .limit(limit)
          .timeout(_timeout);

      // تحويل البيانات إلى كائنات Apartment
      final apartments =
          propertiesResponse
              .map<Apartment>((data) => Apartment.fromSupabase(data))
              .toList();

      // تخزين البيانات مؤقتاً
      _cacheResponse(cacheKey, apartments);

      return apartments;
    });
  }

  // جلب العقارات حسب المكان المتاح
  Future<List<Apartment>> getPropertiesByPlace(
    String placeName, {
    int limit = 20,
  }) async {
    final cacheKey = 'place_$placeName';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey)) {
      _logger.info('استخدام البيانات المخزنة مؤقتاً للمكان: $placeName');
      return _cache[cacheKey]!;
    }

    return _fetchWithRetry(() async {
      _logger.info('جلب العقارات من المكان: $placeName');

      // أولاً، نحصل على معرف المكان من اسمه
      final placeResponse = await _supabase
          .from('available_places')
          .select('id')
          .eq('name', placeName)
          .limit(1)
          .maybeSingle()
          .timeout(_timeout);

      // التحقق من وجود المكان
      if (placeResponse == null) {
        _logger.warning('لم يتم العثور على المكان: $placeName');
        return [];
      }

      final placeId = placeResponse['id'];

      // ثم نحصل على معرفات العقارات المرتبطة بهذا المكان
      final response = await _supabase
          .from('property_available_places')
          .select('property_id')
          .eq('place_id', placeId)
          .limit(limit)
          .timeout(_timeout);

      if (response.isEmpty) {
        _logger.info('لا توجد عقارات مرتبطة بالمكان: $placeName');
        return [];
      }

      // استخراج معرفات العقارات
      final propertyIds =
          response
              .map<String>((item) => item['property_id'] as String)
              .toList();

      // جلب تفاصيل العقارات
      final propertiesResponse = await _supabase
          .from('properties')
          .select()
          .inFilter('id', propertyIds)
          .eq('is_available', true)
          .timeout(_timeout);

      // تحويل البيانات إلى كائنات Apartment
      final apartments =
          propertiesResponse
              .map<Apartment>((data) => Apartment.fromSupabase(data))
              .toList();

      // تخزين البيانات مؤقتاً
      _cacheResponse(cacheKey, apartments);

      return apartments;
    });
  }

  // ربط عقار بقسم معين
  Future<bool> linkPropertyToCategory(
    String propertyId,
    String categoryId,
  ) async {
    try {
      _logger.info('ربط العقار $propertyId بالقسم $categoryId');

      await _supabase
          .from('property_categories')
          .insert({'property_id': propertyId, 'category_id': categoryId})
          .timeout(_timeout);

      // مسح التخزين المؤقت المتعلق بالعقارات
      clearCache();

      return true;
    } catch (e) {
      _logger.severe('فشل ربط العقار بالقسم: $e');
      return false;
    }
  }

  // ربط عقار بمكان متاح
  Future<bool> linkPropertyToPlace(String propertyId, String placeId) async {
    try {
      _logger.info('ربط العقار $propertyId بالمكان $placeId');

      await _supabase
          .from('property_available_places')
          .insert({'property_id': propertyId, 'place_id': placeId})
          .timeout(_timeout);

      // مسح التخزين المؤقت المتعلق بالعقارات
      clearCache();

      return true;
    } catch (e) {
      _logger.severe('فشل ربط العقار بالمكان: $e');
      return false;
    }
  }

  // إلغاء ربط عقار بقسم معين
  Future<bool> unlinkPropertyFromCategory(
    String propertyId,
    String categoryId,
  ) async {
    try {
      _logger.info('إلغاء ربط العقار $propertyId من القسم $categoryId');

      await _supabase
          .from('property_categories')
          .delete()
          .eq('property_id', propertyId)
          .eq('category_id', categoryId)
          .timeout(_timeout);

      // مسح التخزين المؤقت المتعلق بالعقارات
      clearCache();

      return true;
    } catch (e) {
      _logger.severe('فشل إلغاء ربط العقار من القسم: $e');
      return false;
    }
  }

  // إلغاء ربط عقار بمكان متاح
  Future<bool> unlinkPropertyFromPlace(
    String propertyId,
    String placeId,
  ) async {
    try {
      _logger.info('إلغاء ربط العقار $propertyId من المكان $placeId');

      await _supabase
          .from('property_available_places')
          .delete()
          .eq('property_id', propertyId)
          .eq('place_id', placeId)
          .timeout(_timeout);

      // مسح التخزين المؤقت المتعلق بالعقارات
      clearCache();

      return true;
    } catch (e) {
      _logger.severe('فشل إلغاء ربط العقار من المكان: $e');
      return false;
    }
  }

  // جلب الأقسام المرتبطة بعقار معين
  Future<List<Map<String, dynamic>>> getCategoriesForProperty(
    String propertyId,
  ) async {
    final cacheKey = 'property_${propertyId}_categories';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey) && _cacheMaps.containsKey(cacheKey)) {
      _logger.info(
        'استخدام البيانات المخزنة مؤقتاً للأقسام المرتبطة بالعقار: $propertyId',
      );
      return _cacheMaps[cacheKey]!;
    }

    try {
      _logger.info('جلب الأقسام المرتبطة بالعقار: $propertyId');

      // جلب معرفات الأقسام المرتبطة بالعقار
      final response = await _supabase
          .from('property_categories')
          .select('category_id')
          .eq('property_id', propertyId)
          .timeout(_timeout);

      if (response.isEmpty) {
        return [];
      }

      // استخراج معرفات الأقسام
      final categoryIds =
          response
              .map<String>((item) => item['category_id'] as String)
              .toList();

      // جلب تفاصيل الأقسام
      final categoriesResponse = await _supabase
          .from('categories')
          .select()
          .inFilter('id', categoryIds)
          .timeout(_timeout);

      // تحويل البيانات إلى قائمة من Map واضحة
      final List<Map<String, dynamic>> categories = [];
      for (var item in categoriesResponse) {
        categories.add(Map<String, dynamic>.from(item));
      }

      // تخزين البيانات في المخزن المؤقت المنفصل
      _cacheMaps[cacheKey] = categories;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return categories;
    } catch (e) {
      _logger.severe('فشل جلب الأقسام المرتبطة بالعقار: $e');
      return [];
    }
  }

  // جلب الأماكن المرتبطة بعقار معين
  Future<List<Map<String, dynamic>>> getPlacesForProperty(
    String propertyId,
  ) async {
    final cacheKey = 'property_${propertyId}_places';

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey) && _cacheMaps.containsKey(cacheKey)) {
      _logger.info(
        'استخدام البيانات المخزنة مؤقتاً للأماكن المرتبطة بالعقار: $propertyId',
      );
      return _cacheMaps[cacheKey]!;
    }

    try {
      _logger.info('جلب الأماكن المرتبطة بالعقار: $propertyId');

      // جلب معرفات الأماكن المرتبطة بالعقار
      final response = await _supabase
          .from('property_available_places')
          .select('place_id')
          .eq('property_id', propertyId)
          .timeout(_timeout);

      if (response.isEmpty) {
        return [];
      }

      // استخراج معرفات الأماكن
      final placeIds =
          response.map<String>((item) => item['place_id'] as String).toList();

      // جلب تفاصيل الأماكن
      final placesResponse = await _supabase
          .from('available_places')
          .select()
          .inFilter('id', placeIds)
          .timeout(_timeout);

      // تحويل البيانات إلى قائمة من Map واضحة
      final List<Map<String, dynamic>> places = [];
      for (var item in placesResponse) {
        places.add(Map<String, dynamic>.from(item));
      }

      // تخزين البيانات في المخزن المؤقت المنفصل
      _cacheMaps[cacheKey] = places;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return places;
    } catch (e) {
      _logger.severe('فشل جلب الأماكن المرتبطة بالعقار: $e');
      return [];
    }
  }

  // جلب العقارات المميزة (شقق السهم)
  Future<List<Apartment>> getFeaturedProperties({int limit = 10}) async {
    const cacheKey = 'featured_properties';
    const categoryId = '8'; // ID للقسم "شقق السهم"

    // فحص التخزين المؤقت أولاً
    if (_isCacheValid(cacheKey)) {
      _logger.info('استخدام البيانات المخزنة مؤقتاً للعقارات المميزة');
      return _cache[cacheKey]!;
    }

    return _fetchWithRetry(() async {
      _logger.info('جلب العقارات المميزة من قسم شقق السهم...');

      try {
        // أولاً نحصل على معرفات العقارات المرتبطة بقسم شقق السهم
        final categoryPropertiesQuery = await _supabase
            .from('property_categories')
            .select('property_id')
            .eq('category_id', categoryId)
            .timeout(_timeout);

        if (categoryPropertiesQuery.isEmpty) {
          _logger.info('لا توجد عقارات مرتبطة بقسم شقق السهم');
          return [];
        }

        // استخراج معرفات العقارات
        final propertyIds =
            categoryPropertiesQuery
                .map<String>((item) => item['property_id'] as String)
                .toList();

        // جلب تفاصيل العقارات المتاحة فقط
        final propertiesResponse = await _supabase
            .from('properties')
            .select()
            .inFilter('id', propertyIds)
            .eq('is_available', true)
            .limit(limit)
            .timeout(_timeout);

        // تحويل البيانات إلى كائنات Apartment
        final apartments =
            propertiesResponse
                .map<Apartment>((data) => Apartment.fromSupabase(data))
                .toList();

        // تخزين البيانات مؤقتاً
        _cacheResponse(cacheKey, apartments);

        return apartments;
      } catch (e) {
        _logger.severe('خطأ في جلب العقارات المميزة: $e');
        return [];
      }
    });
  }
}
