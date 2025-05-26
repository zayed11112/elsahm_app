import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'dart:async';

class SupabaseService {
  static final Logger _logger = Logger('SupabaseService');
  // استخدام getter method للحصول على client عند الحاجة فقط
  SupabaseClient get _supabase => Supabase.instance.client;

  // الحصول على طلبات الدفع للمستخدم حسب الحالة
  Future<List<Map<String, dynamic>>> getUserPaymentRequests(
    String userId,
    String status,
  ) async {
    try {
      _logger.info(
        'Fetching payment requests from Supabase for user: $userId, status: $status',
      );

      final response = await _supabase
          .from('payment_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', status)
          .order('created_at', ascending: false);

      _logger.info('Supabase: Fetched ${response.length} payment requests');

      // تحويل البيانات إلى نفس الصيغة المستخدمة سابقًا
      return response.map<Map<String, dynamic>>((item) {
        return {
          'id': item['id'].toString(),
          'userId': item['user_id'],
          'status': item['status'],
          'createdAt': item['created_at'],
          'amount': item['amount'],
          'paymentMethod': item['payment_method'],
          'sourcePhone': item['source_phone'],
          'paymentProofUrl': item['payment_proof_url'],
          'rejectionReason': item['rejection_reason'],
          'approvedAt': item['approved_at'],
          'userName': item['user_name'] ?? '',
          'universityId': item['university_id'] ?? '',
        };
      }).toList();
    } catch (e) {
      _logger.severe('Error fetching payment requests from Supabase: $e');
      return [];
    }
  }

  // إضافة طلب دفع جديد
  Future<bool> addPaymentRequest(Map<String, dynamic> requestData) async {
    try {
      // تحويل البيانات إلى صيغة Supabase
      final supabaseData = {
        'user_id': requestData['userId'],
        'status': requestData['status'] ?? 'pending',
        'amount': requestData['amount'],
        'payment_method': requestData['paymentMethod'],
        'source_phone': requestData['sourcePhone'],
        'payment_proof_url': requestData['paymentProofUrl'],
        'user_name': requestData['userName'],
        'university_id': requestData['universityId'],
      };

      await _supabase.from('payment_requests').insert(supabaseData);
      _logger.info('Payment request added successfully to Supabase');
      return true;
    } catch (e) {
      _logger.severe('Error adding payment request to Supabase: $e');
      return false;
    }
  }

  // استريم بسيط لطلبات الدفع مع تحديث دوري
  Stream<List<Map<String, dynamic>>> getUserPaymentRequestsStream(
    String userId,
    String status,
  ) {
    // إنشاء تدفق للبيانات
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    // وظيفة لجلب البيانات وإضافتها إلى التدفق
    Future<void> fetchData() async {
      try {
        final requests = await getUserPaymentRequests(userId, status);
        if (!controller.isClosed) {
          controller.add(requests);
        }
      } catch (e) {
        _logger.severe('Error in fetchData: $e');
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }

    // جلب البيانات مباشرة
    fetchData();

    // إعداد مؤقت للتحديث الدوري (كل 5 ثوانٍ)
    final timer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchData();
    });

    // إغلاق المولّد والمؤقت عند إغلاق التدفق
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };

    return controller.stream;
  }
}

// إضافة مزود عمومي للوصول السهل إلى خدمة Supabase
final supabaseService = SupabaseService();
