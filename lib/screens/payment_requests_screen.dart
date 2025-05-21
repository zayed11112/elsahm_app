import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';
import '../utils/theme_utils.dart';
import '../widgets/themed_card.dart';
import 'package:url_launcher/url_launcher.dart';

// Define colors used in other screens for consistency
const Color primarySkyBlue = Color(0xFF4FC3F7);
const Color accentBlue = Color(0xFF29B6F6);

class PaymentRequestsScreen extends StatefulWidget {
  const PaymentRequestsScreen({super.key});

  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen> {
  // تخزين الاستعلامات المختلفة
  final Map<String, Stream<List<Map<String, dynamic>>>> _streams = {};
  
  // التنسيقات الخاصة بحالات الطلبات
  final Map<String, String> _statusLabels = {
    'pending': 'قيد المراجعة',
    'approved': 'تمت الدفع',
    'rejected': 'تم الرفض تواصل مع الدعم',
  };
  
  // أيقونات حالات الطلبات
  final Map<String, IconData> _statusIcons = {
    'pending': Icons.hourglass_top,
    'approved': Icons.check_circle,
    'rejected': Icons.cancel,
  };

  @override
  void dispose() {
    _streams.clear();
    super.dispose();
  }

  // الحصول على استعلام مع التأكد من عدم تكرار إنشاء الاستعلامات
  Stream<List<Map<String, dynamic>>> _getStream(String userId, String status) {
    final key = '$userId-$status';
    if (!_streams.containsKey(key)) {
      _streams[key] = supabaseService.getUserPaymentRequestsStream(userId, status);
    }
    return _streams[key]!;
  }

  // تنسيق التاريخ
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('yyyy/MM/dd - hh:mm a').format(date);
    } catch (e) {
      return 'تاريخ غير معروف';
    }
  }

  // فتح واتساب للتواصل مع الدعم الفني
  Future<void> _openWhatsApp() async {
    final phoneNumber = '+201093130120';
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
    
    try {
      if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
        // إذا فشل في فتح واتساب، يمكن استخدام رابط بديل
        final Uri fallbackUri = Uri.parse('https://api.whatsapp.com/send?phone=$phoneNumber');
        if (!await launchUrl(fallbackUri, mode: LaunchMode.externalApplication)) {
          _showErrorSnackBar();
        }
      }
    } catch (e) {
      _showErrorSnackBar();
    }
  }
  
  void _showErrorSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لا يمكن فتح واتساب. يرجى التأكد من تثبيت التطبيق.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;
    final isDarkMode = context.isDarkMode;
    
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('طلبات الدفع'),
          backgroundColor: primarySkyBlue,
        ),
        body: const Center(
          child: Text('يرجى تسجيل الدخول لعرض طلبات الدفع'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الدفع'),
        backgroundColor: primarySkyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: primarySkyBlue,
        onRefresh: () async {
          setState(() {
            // إعادة إنشاء الاستعلامات لتحديث البيانات
            _streams.clear();
          });
          // انتظار قليلاً لإعطاء شعور بالتحديث
          return Future.delayed(const Duration(milliseconds: 500));
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 16, 
                right: 16, 
                top: 16, 
                bottom: 100, // إضافة مساحة في الأسفل للزر
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم الطلبات المعلقة
                  _buildSectionHeader(
                    title: 'الطلبات قيد المراجعة',
                    icon: Icons.hourglass_top,
                    color: pendingColor,
                  ),
                  const SizedBox(height: 8),
                  
                  // قائمة الطلبات المعلقة
                  _buildRequestsSection(
                    userId: userId,
                    status: 'pending',
                    isDarkMode: isDarkMode,
                    emptyMessage: 'لا توجد طلبات قيد المراجعة حالياً',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // قسم سجل الطلبات
                  _buildSectionHeader(
                    title: 'سجل الطلبات',
                    icon: Icons.history,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(height: 8),
                  
                  // طلبات تمت الموافقة عليها
                  _buildCompletedRequestsSection(
                    userId: userId,
                    isDarkMode: isDarkMode,
                    title: 'الطلبات الموافق عليها',
                    icon: Icons.check_circle,
                    color: approvedColor,
                    status: 'approved',
                    emptyMessage: 'لا توجد طلبات موافق عليها',
                    collapsed: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // طلبات مرفوضة
                  _buildCompletedRequestsSection(
                    userId: userId,
                    isDarkMode: isDarkMode,
                    title: 'الطلبات المرفوضة',
                    icon: Icons.cancel,
                    color: rejectedColor,
                    status: 'rejected',
                    emptyMessage: 'لا توجد طلبات مرفوضة',
                    collapsed: true,
                  ),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
            
            // زر واتساب للتواصل مع الدعم الفني
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildWhatsAppButton(),
            ),
          ],
        ),
      ),
    );
  }

  // بناء ترويسة القسم
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // بناء قسم الطلبات المعلقة
  Widget _buildRequestsSection({
    required String userId,
    required String status,
    required bool isDarkMode,
    required String emptyMessage,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getStream(userId, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(color: primarySkyBlue),
                  SizedBox(height: 16),
                  Text('جاري تحميل الطلبات...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ThemedCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: rejectedColor, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'حدث خطأ أثناء تحميل الطلبات',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(() => _streams.clear()),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final requests = snapshot.data ?? [];
        
        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    status == 'pending' ? Icons.hourglass_empty : Icons.history,
                    size: 40,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    emptyMessage,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // عرض قائمة الطلبات
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index], isDarkMode);
          },
        );
      },
    );
  }

  // بناء قسم الطلبات المكتملة (الموافق عليها/المرفوضة) مع قابلية الطي
  Widget _buildCompletedRequestsSection({
    required String userId,
    required bool isDarkMode,
    required String title,
    required IconData icon,
    required Color color,
    required String status,
    required String emptyMessage,
    bool collapsed = false,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getStream(userId, status),
      builder: (context, snapshot) {
        // إظهار كارت بسيط يعرض عدد الطلبات ويمكن توسيعه
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return ThemedCard(
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: primarySkyBlue),
                ),
              ),
            ),
          );
        }

        final requests = snapshot.data ?? [];
        
        // كارت قابل للطي يحتوي على الطلبات
        return ExpansionTile(
          title: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${requests.length}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          initiallyExpanded: !collapsed,
          iconColor: color,
          collapsedIconColor: color.withOpacity(0.7),
          backgroundColor: Colors.transparent,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [
            if (requests.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    emptyMessage,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return _buildRequestCard(requests[index], isDarkMode);
                },
              ),
          ],
        );
      },
    );
  }

  // بناء بطاقة طلب بمظهر جديد أكثر احترافية
  Widget _buildRequestCard(Map<String, dynamic> request, bool isDarkMode) {
    final status = request['status'] as String;
    final statusColor = context.getStatusColor(status);
    final amount = '${request['amount']} جنيه';
    final date = _formatDate(request['createdAt']);
    
    return GestureDetector(
      onTap: () => _showRequestDetails(request),
      child: StatusCard(
        status: status,
        title: amount,
        subtitle: date,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  request['paymentMethod'].toString().contains('فودافون') 
                      ? Icons.phone_android 
                      : Icons.account_balance_wallet,
                  size: 16,
                  color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'طريقة الدفع: ${request['paymentMethod']}',
                  style: context.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (request['userName'] != null && request['userName'].toString().isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الاسم: ${request['userName']}',
                    style: context.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (request['universityId'] != null && request['universityId'].toString().isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.badge,
                    size: 16,
                    color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الرقم الجامعي: ${request['universityId']}',
                    style: context.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (status == 'rejected' && request['rejectionReason'] != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: rejectedColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سبب الرفض: ${request['rejectionReason']}',
                      style: context.bodySmall?.copyWith(
                        color: rejectedColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcons[status],
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabels[status]!,
                        style: context.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // عرض تفاصيل الطلب عند النقر على البطاقة
  void _showRequestDetails(Map<String, dynamic> request) {
    final isDarkMode = context.isDarkMode;
    final status = request['status'] as String;
    final statusColor = context.getStatusColor(status);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: context.backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Status Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _statusIcons[status],
                        color: statusColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusLabels[status]!,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (status == 'rejected' && request['rejectionReason'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'سبب الرفض: ${request['rejectionReason']}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: rejectedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // تفاصيل الطلب
                      Text(
                        'تفاصيل الطلب',
                        style: context.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildDetailItem(
                        icon: Icons.receipt,
                        title: 'رقم الطلب',
                        value: request['id'] ?? 'غير متوفر',
                      ),
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        title: 'تاريخ الطلب',
                        value: _formatDate(request['createdAt']),
                      ),
                      _buildDetailItem(
                        icon: Icons.account_balance_wallet,
                        title: 'المبلغ',
                        value: '${request['amount']} جنيه',
                      ),
                      _buildDetailItem(
                        icon: Icons.payment,
                        title: 'طريقة الدفع',
                        value: request['paymentMethod'],
                      ),
                      _buildDetailItem(
                        icon: Icons.phone,
                        title: 'رقم/حساب المصدر',
                        value: request['sourcePhone'],
                      ),
                      
                      // معلومات المستخدم
                      if (request['userName'] != null && request['userName'].toString().isNotEmpty)
                        _buildDetailItem(
                          icon: Icons.person,
                          title: 'الاسم داخل التطبيق',
                          value: request['userName'],
                        ),
                      
                      if (request['universityId'] != null && request['universityId'].toString().isNotEmpty)
                        _buildDetailItem(
                          icon: Icons.badge,
                          title: 'الرقم الجامعي',
                          value: request['universityId'],
                        ),
                      
                      // إثبات الدفع
                      const SizedBox(height: 25),
                      Text(
                        'إثبات الدفع',
                        style: context.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (request['paymentProofUrl'] != null)
                        GestureDetector(
                          onTap: () => _showFullScreenImage(context, request['paymentProofUrl']),
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primarySkyBlue.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: request['paymentProofUrl'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(color: primarySkyBlue),
                                ),
                                errorWidget: (context, url, error) => const Center(
                                  child: Icon(Icons.error, color: rejectedColor, size: 50),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Text('لا يوجد إثبات دفع'),
                          ),
                        ),
                      
                      // معلومات إضافية للطلبات الموافق عليها
                      if (status == 'approved')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 25),
                            Text(
                              'معلومات الموافقة',
                              style: context.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: approvedColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: approvedColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: approvedColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'تمت إضافة المبلغ إلى رصيدك',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: approvedColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (request['approvedAt'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 18,
                                            color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'تاريخ الموافقة: ${_formatDate(request['approvedAt'])}',
                                            style: TextStyle(
                                              color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // عنصر تفاصيل في صفحة تفاصيل الطلب
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: context.isDarkMode ? darkTextSecondary : lightTextSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.bodySmall?.copyWith(
                    color: context.isDarkMode ? darkTextSecondary : lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // عرض الصورة بشكل كامل
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.white, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'فشل تحميل الصورة: $error',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // بناء زر واتساب
  Widget _buildWhatsAppButton() {
    return ElevatedButton(
      onPressed: _openWhatsApp,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366), // لون واتساب الأخضر
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // أيقونة واتساب
          Image.asset(
            'assets/images/WhatsApp.svg.webp',
            width: 24,
            height: 24,
            color: Colors.white,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.chat, size: 24);
            },
          ),
          const SizedBox(width: 12),
          const Text(
            'تواصل مع الدعم الفني عبر واتساب',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
} 