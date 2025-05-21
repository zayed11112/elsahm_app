import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import '../models/available_place.dart';

class AvailablePlacesService {
  final Logger _logger = Logger('AvailablePlacesService');
  // استخدام getter للحصول على client عند الحاجة فقط
  SupabaseClient get _supabase => Supabase.instance.client;

  // الحصول على جميع الأماكن المتاحة
  Future<List<AvailablePlace>> getAllPlaces({int limit = 20}) async {
    try {
      _logger.info('جاري الحصول على الأماكن المتاحة...');

      final response = await _supabase
          .from('available_places')
          .select()
          .eq('is_active', true)
          .order('order_index', ascending: true)
          .limit(limit);

      _logger.info('تم الحصول على ${response.length} مكان متاح من Supabase');

      // تحويل البيانات إلى كائنات AvailablePlace
      return response.map<AvailablePlace>((data) => AvailablePlace.fromSupabase(data)).toList();
    } catch (e) {
      _logger.severe('خطأ في الحصول على الأماكن المتاحة من Supabase: $e');
      return [];
    }
  }

  // الحصول على مكان متاح بواسطة المعرف
  Future<AvailablePlace?> getPlaceById(int id) async {
    try {
      _logger.info('جاري الحصول على المكان المتاح بالمعرف: $id');

      final response = await _supabase
          .from('available_places')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        _logger.warning('لم يتم العثور على المكان المتاح بالمعرف: $id');
        return null;
      }

      return AvailablePlace.fromSupabase(response);
    } catch (e) {
      _logger.severe('خطأ في الحصول على المكان المتاح بالمعرف: $e');
      return null;
    }
  }

  // إضافة مكان متاح جديد
  Future<AvailablePlace?> addPlace(AvailablePlace place) async {
    try {
      _logger.info('جاري إضافة مكان متاح جديد: ${place.name}');

      final response = await _supabase
          .from('available_places')
          .insert(place.toSupabase())
          .select()
          .single();

      _logger.info('تم إضافة المكان المتاح بنجاح');

      return AvailablePlace.fromSupabase(response);
    } catch (e) {
      _logger.severe('خطأ في إضافة المكان المتاح: $e');
      return null;
    }
  }

  // تحديث مكان متاح
  Future<AvailablePlace?> updatePlace(AvailablePlace place) async {
    try {
      _logger.info('جاري تحديث المكان المتاح: ${place.name}');

      final response = await _supabase
          .from('available_places')
          .update(place.toSupabase())
          .eq('id', place.id)
          .select()
          .single();

      _logger.info('تم تحديث المكان المتاح بنجاح');

      return AvailablePlace.fromSupabase(response);
    } catch (e) {
      _logger.severe('خطأ في تحديث المكان المتاح: $e');
      return null;
    }
  }

  // حذف مكان متاح
  Future<bool> deletePlace(int id) async {
    try {
      _logger.info('جاري حذف المكان المتاح بالمعرف: $id');

      await _supabase
          .from('available_places')
          .delete()
          .eq('id', id);

      _logger.info('تم حذف المكان المتاح بنجاح');

      return true;
    } catch (e) {
      _logger.severe('خطأ في حذف المكان المتاح: $e');
      return false;
    }
  }

  // الحصول على مكان متاح بواسطة الاسم
  Future<AvailablePlace?> getPlaceByName(String name) async {
    try {
      _logger.info('جاري الحصول على المكان المتاح بالاسم: $name');

      final response = await _supabase
          .from('available_places')
          .select()
          .eq('name', name)
          .maybeSingle();

      if (response == null) {
        _logger.warning('لم يتم العثور على المكان المتاح بالاسم: $name');
        return null;
      }

      return AvailablePlace.fromSupabase(response);
    } catch (e) {
      _logger.severe('خطأ في الحصول على المكان المتاح بالاسم: $e');
      return null;
    }
  }
} 