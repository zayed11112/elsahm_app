import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

class CategoryService {
  final Logger _logger = Logger('CategoryService');
  // استخدام getter method للحصول على client عند الحاجة فقط
  SupabaseClient get _supabase => Supabase.instance.client;

  // جلب جميع الأقسام
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      _logger.info('بدء جلب الأقسام من Supabase...');

      final response = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('order_index');

      _logger.info('تم استلام الاستجابة من Supabase: ${response.length} قسم');

      // تحويل البيانات إلى الصيغة المطلوبة
      return response.map<Map<String, dynamic>>((item) {
        return {
          'id': item['id'].toString(),
          'label': item['name'] ?? 'غير معروف',
          'icon': _getIconNameFromUrl(item['icon_url']),
          'iconUrl': item['icon_url'] ?? '',
        };
      }).toList();
    } catch (e) {
      _logger.severe('خطأ في جلب الأقسام من Supabase: $e');
      // إرجاع قائمة فارغة في حالة الخطأ
      return [];
    }
  }

  // جلب العقارات حسب القسم
  Future<List<Map<String, dynamic>>> getPropertiesByCategory(
    String categoryName, {
    int limit = 10,
  }) async {
    try {
      _logger.info('جلب العقارات من القسم: $categoryName');

      // أولاً، نحصل على معرف القسم من اسمه
      final categoryResponse =
          await _supabase
              .from('categories')
              .select('id')
              .eq('name', categoryName)
              .limit(1)
              .maybeSingle();

      // التحقق من وجود القسم
      if (categoryResponse == null) {
        _logger.warning('لم يتم العثور على القسم: $categoryName');
        return [];
      }

      final categoryId = categoryResponse['id'];

      // ثم نحصل على معرفات العقارات المرتبطة بهذا القسم
      final response = await _supabase
          .from('category_properties')
          .select('property_id')
          .eq('category_id', categoryId)
          .limit(limit);

      if (response.isEmpty) {
        _logger.info('لا توجد عقارات مرتبطة بالقسم: $categoryName');
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
          .inFilter('id', propertyIds);

      // تحويل البيانات إلى الصيغة المطلوبة
      return propertiesResponse.map<Map<String, dynamic>>((property) {
        return {
          'id': property['id'],
          'name': property['name'] ?? '',
          'location': property['address'] ?? '',
          'price': property['price'] ?? 0,
          'imageUrls': property['images'] ?? [],
          'bedrooms': property['bedrooms'] ?? 0,
          'bathrooms': property['beds'] ?? 0,
          'isAvailable': property['is_available'] ?? true,
        };
      }).toList();
    } catch (e) {
      _logger.severe('خطأ في جلب العقارات من القسم: $e');
      return [];
    }
  }

  // إضافة قسم جديد
  Future<bool> addCategory(
    String name,
    String iconUrl, {
    int orderIndex = 0,
  }) async {
    try {
      await _supabase.from('categories').insert({
        'name': name,
        'icon_url': iconUrl,
        'order_index': orderIndex,
        'is_active': true,
      });
      _logger.info('تم إضافة قسم جديد: $name');
      return true;
    } catch (e) {
      _logger.severe('خطأ في إضافة قسم جديد: $e');
      return false;
    }
  }

  // تحديث قسم
  Future<bool> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('categories').update(data).eq('id', id);
      _logger.info('تم تحديث القسم بنجاح: $id');
      return true;
    } catch (e) {
      _logger.severe('خطأ في تحديث القسم: $e');
      return false;
    }
  }

  // حذف قسم
  Future<bool> deleteCategory(int id) async {
    try {
      await _supabase.from('categories').delete().eq('id', id);
      _logger.info('تم حذف القسم بنجاح: $id');
      return true;
    } catch (e) {
      _logger.severe('خطأ في حذف القسم: $e');
      return false;
    }
  }

  // ربط عقار بقسم
  Future<bool> linkPropertyToCategory(String propertyId, int categoryId) async {
    try {
      await _supabase.from('category_properties').insert({
        'property_id': propertyId,
        'category_id': categoryId,
      });
      _logger.info('تم ربط العقار $propertyId بالقسم $categoryId بنجاح');
      return true;
    } catch (e) {
      _logger.severe('خطأ في ربط العقار بالقسم: $e');
      return false;
    }
  }

  // إلغاء ربط عقار بقسم
  Future<bool> unlinkPropertyFromCategory(
    String propertyId,
    int categoryId,
  ) async {
    try {
      await _supabase
          .from('category_properties')
          .delete()
          .eq('property_id', propertyId)
          .eq('category_id', categoryId);
      _logger.info(
        'تم إلغاء ربط العقار $propertyId من القسم $categoryId بنجاح',
      );
      return true;
    } catch (e) {
      _logger.severe('خطأ في إلغاء ربط العقار من القسم: $e');
      return false;
    }
  }

  // تحويل رابط الأيقونة إلى اسم الأيقونة (لم يعد مستخدمًا)
  String _getIconNameFromUrl(String? iconUrl) {
    // نعيد الرابط كما هو لاستخدامه مباشرة في التطبيق
    return iconUrl ?? '';
  }
}
