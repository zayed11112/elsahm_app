import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import '../services/checkout_service.dart';

class CheckoutListScreen extends StatefulWidget {
  const CheckoutListScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutListScreen> createState() => _CheckoutListScreenState();
}

class _CheckoutListScreenState extends State<CheckoutListScreen> {
  final Logger _logger = Logger('CheckoutListScreen');
  final CheckoutService _checkoutService = CheckoutService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _checkoutRequests = [];
  String? _errorMessage;
  bool _needsLogin = false;

  @override
  void initState() {
    super.initState();
    _loadCheckoutRequests();
  }

  Future<void> _loadCheckoutRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _needsLogin = false;
      });

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        _checkoutRequests = await _checkoutService.getUserCheckoutRequests(user.id);
      } else {
        _checkoutRequests = [];
        setState(() {
          _needsLogin = true;
        });
      }
    } catch (e) {
      _logger.severe('خطأ في تحميل طلبات إتمام الحجز: $e');
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_needsLogin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب عليك تسجيل الدخول لعرض طلبات إتمام الحجز'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _needsLogin = false;
        });
      }
      
      if (_errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _errorMessage = null;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات إتمام الحجز'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCheckoutRequests,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checkoutRequests.isEmpty
              ? _buildEmptyState()
              : _buildCheckoutRequestsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد طلبات إتمام حجز',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ستظهر هنا جميع طلبات إتمام الحجز التي قمت بإنشائها',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checkoutRequests.length,
      itemBuilder: (context, index) {
        final request = _checkoutRequests[index];
        
        // تحديد لون حالة الطلب
        Color statusColor;
        switch (request['status']) {
          case 'مؤكد':
            statusColor = Colors.green;
            break;
          case 'ملغي':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.orange;
            break;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معلومات العقار
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صورة العقار (يمكن إضافتها لاحقاً)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.grey,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // تفاصيل العقار
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['property_name'] ?? 'عقار غير محدد',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request['customer_name'] ?? 'غير محدد',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request['customer_phone'] ?? 'غير محدد',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // حالة الطلب
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request['status'] ?? 'جاري المعالجة',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // تفاصيل إضافية
                _buildInfoRow('الرقم الجامعي', request['university_id'] ?? 'غير محدد'),
                _buildInfoRow('الكلية', request['college'] ?? 'غير محدد'),
                _buildInfoRow('العمولة', '${request['commission'] ?? '0'} ريال'),
                _buildInfoRow('العربون', '${request['deposit'] ?? '0'} ريال'),
                _buildInfoRow(
                  'تاريخ الطلب',
                  request['created_at'] != null
                      ? _formatDate(DateTime.parse(request['created_at']))
                      : 'غير محدد',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // بناء صف معلومات
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 