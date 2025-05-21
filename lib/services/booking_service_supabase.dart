import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

class BookingServiceSupabase {
  final Logger _logger = Logger('BookingServiceSupabase');
  // استخدام getter method للحصول على client عند الحاجة فقط
  SupabaseClient get _supabase => Supabase.instance.client;

  // إضافة طلب حجز جديد
  Future<void> addBookingRequest(Map<String, dynamic> bookingData) async {
    try {
      _logger.info('إضافة طلب حجز جديد: ${bookingData['property_name']}');
      
      await _supabase.from('booking_requests').insert(bookingData);
      
      _logger.info('تم إضافة طلب الحجز بنجاح');
    } catch (e) {
      _logger.severe('خطأ في إضافة طلب الحجز: $e');
      rethrow;
    }
  }

  // الحصول على طلبات الحجز للمستخدم
  Future<List<Map<String, dynamic>>> getUserBookingRequests(String userId) async {
    try {
      _logger.info('جلب طلبات الحجز للمستخدم: $userId');
      
      final response = await _supabase
          .from('booking_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('خطأ في جلب طلبات الحجز للمستخدم: $e');
      return [];
    }
  }

  // الحصول على طلبات الحجز للعقار
  Future<List<Map<String, dynamic>>> getPropertyBookingRequests(String propertyId) async {
    try {
      _logger.info('جلب طلبات الحجز للعقار: $propertyId');
      
      final response = await _supabase
          .from('booking_requests')
          .select()
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('خطأ في جلب طلبات الحجز للعقار: $e');
      return [];
    }
  }

  // تحديث حالة طلب الحجز
  Future<void> updateBookingRequestStatus(String requestId, String status) async {
    try {
      _logger.info('تحديث حالة طلب الحجز $requestId إلى $status');
      
      await _supabase
          .from('booking_requests')
          .update({'status': status})
          .eq('id', requestId);
      
      _logger.info('تم تحديث حالة طلب الحجز بنجاح');
    } catch (e) {
      _logger.severe('خطأ في تحديث حالة طلب الحجز: $e');
      rethrow;
    }
  }

  // حذف طلب حجز
  Future<void> deleteBookingRequest(String requestId) async {
    try {
      _logger.info('حذف طلب الحجز: $requestId');
      
      await _supabase
          .from('booking_requests')
          .delete()
          .eq('id', requestId);
      
      _logger.info('تم حذف طلب الحجز بنجاح');
    } catch (e) {
      _logger.severe('خطأ في حذف طلب الحجز: $e');
      rethrow;
    }
  }
}
