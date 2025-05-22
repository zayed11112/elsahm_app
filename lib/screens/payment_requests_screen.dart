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
import 'dart:math' as math;

// Define colors used in other screens for consistency
const Color primarySkyBlue = Color(0xFF4FC3F7);
const Color accentBlue = Color(0xFF29B6F6);

// Animation durations
const Duration kCardAnimationDuration = Duration(milliseconds: 300);
const Duration kTabAnimationDuration = Duration(milliseconds: 200);

class PaymentRequestsScreen extends StatefulWidget {
  const PaymentRequestsScreen({super.key});

  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen> with SingleTickerProviderStateMixin {
  // تخزين الاستعلامات المختلفة
  final Map<String, Stream<List<Map<String, dynamic>>>> _streams = {};
  
  // Tab controller for switching between request types
  late TabController _tabController;
  
  // Animation for card reveal
  final List<GlobalKey<AnimatedListState>> _listKeys = [
    GlobalKey<AnimatedListState>(),
    GlobalKey<AnimatedListState>(),
    GlobalKey<AnimatedListState>(),
  ];

  // Current tab index
  int _currentTabIndex = 0;
  
  // التنسيقات الخاصة بحالات الطلبات
  final Map<String, String> _statusLabels = {
    'pending': 'قيد المراجعة',
    'approved': 'تمت الموافقة',
    'rejected': 'تم الرفض',
  };
  
  // أيقونات حالات الطلبات
  final Map<String, IconData> _statusIcons = {
    'pending': Icons.hourglass_top,
    'approved': Icons.check_circle,
    'rejected': Icons.cancel,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          centerTitle: true,
          backgroundColor: primarySkyBlue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 70,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'يرجى تسجيل الدخول لعرض طلبات الدفع',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _buildAppBar(),
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
              TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Pending requests tab
                  _buildRequestsTab(
                    userId: userId, 
                    status: 'pending',
                    emptyMessage: 'لا توجد طلبات قيد المراجعة حالياً',
                    emptyIcon: Icons.hourglass_empty,
                    listKey: _listKeys[0],
                  ),
                  
                  // Approved requests tab
                  _buildRequestsTab(
                    userId: userId, 
                    status: 'approved',
                    emptyMessage: 'لا توجد طلبات موافق عليها',
                    emptyIcon: Icons.check_circle_outline,
                    listKey: _listKeys[1],
                  ),
                  
                  // Rejected requests tab
                  _buildRequestsTab(
                    userId: userId, 
                    status: 'rejected',
                    emptyMessage: 'لا توجد طلبات مرفوضة',
                    emptyIcon: Icons.cancel_outlined,
                    listKey: _listKeys[2],
                  ),
                ],
              ),
              
              // WhatsApp support button
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildWhatsAppButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بناء شريط التطبيق المُحسن
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('طلبات الدفع'),
      centerTitle: true,
      backgroundColor: primarySkyBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: [
          Tab(
            icon: const Icon(Icons.hourglass_top),
            text: 'قيد المراجعة',
            iconMargin: const EdgeInsets.only(bottom: 2),
          ),
          Tab(
            icon: const Icon(Icons.check_circle),
            text: 'الموافق عليها',
            iconMargin: const EdgeInsets.only(bottom: 2),
          ),
          Tab(
            icon: const Icon(Icons.cancel),
            text: 'المرفوضة',
            iconMargin: const EdgeInsets.only(bottom: 2),
          ),
        ],
      ),
    );
  }

  // بناء محتوى التاب
  Widget _buildRequestsTab({
    required String userId,
    required String status,
    required String emptyMessage,
    required IconData emptyIcon,
    required GlobalKey<AnimatedListState> listKey,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getStream(userId, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primarySkyBlue),
                SizedBox(height: 16),
                Text('جاري تحميل الطلبات...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ThemedCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: rejectedColor, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'حدث خطأ أثناء تحميل الطلبات',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(
                          color: context.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _streams.clear()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primarySkyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final requests = snapshot.data ?? [];
        
        if (requests.isEmpty) {
          return _buildEmptyState(emptyIcon, emptyMessage);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 96, // Extra space for the WhatsApp button
          ),
          itemCount: requests.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            // Add staggered animation effect
            return AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                // Only animate if this is the current tab
                final shouldAnimate = _tabController.index == _getTabIndexForStatus(status);
                
                return AnimatedOpacity(
                  opacity: shouldAnimate ? 1.0 : 0.0, 
                  duration: kCardAnimationDuration,
                  curve: Curves.easeInOut,
                  child: AnimatedSlide(
                    offset: shouldAnimate 
                      ? Offset.zero 
                      : const Offset(0, 0.05),
                    duration: kCardAnimationDuration,
                    curve: Interval(
                      index * 0.1, 
                      math.min(1.0, index * 0.1 + 0.5),
                      curve: Curves.easeOutQuart,
                    ),
                    child: AnimatedScale(
                      scale: shouldAnimate ? 1.0 : 0.95,
                      duration: kCardAnimationDuration,
                      curve: Curves.easeOutBack,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildRequestCard(requests[index], context.isDarkMode),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper to get tab index from status
  int _getTabIndexForStatus(String status) {
    switch (status) {
      case 'pending': return 0;
      case 'approved': return 1;
      case 'rejected': return 2;
      default: return 0;
    }
  }

  // بناء حالة فارغة بتصميم جذاب
  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.isDarkMode 
                ? Colors.grey[800]!.withOpacity(0.3) 
                : Colors.grey[200]!.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: context.isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: context.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // بناء بطاقة طلب بمظهر جديد أكثر احترافية
  Widget _buildRequestCard(Map<String, dynamic> request, bool isDarkMode) {
    final status = request['status'] as String;
    final statusColor = context.getStatusColor(status);
    final amount = '${request['amount']} جنيه';
    final date = _formatDate(request['createdAt']);
    
    // Get payment method icon
    IconData paymentIcon = request['paymentMethod'].toString().contains('فودافون')
        ? Icons.phone_android
        : Icons.account_balance_wallet;

    return GestureDetector(
      onTap: () => _showRequestDetails(request),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card header with status indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Amount with circled icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.payments_outlined,
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            amount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcons[status],
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabels[status]!,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment method
                  _buildInfoRow(
                    icon: paymentIcon,
                    label: 'طريقة الدفع',
                    value: request['paymentMethod'],
                    isDarkMode: isDarkMode,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // User info if available
                  if (request['userName'] != null && request['userName'].toString().isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'الاسم',
                      value: request['userName'],
                      isDarkMode: isDarkMode,
                    ),
                    
                  if (request['userName'] != null && request['userName'].toString().isNotEmpty)
                    const SizedBox(height: 12),
                    
                  // University ID if available
                  if (request['universityId'] != null && request['universityId'].toString().isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.badge,
                      label: 'الرقم الجامعي',
                      value: request['universityId'],
                      isDarkMode: isDarkMode,
                    ),
                    
                  // Show rejection reason for rejected requests
                  if (status == 'rejected' && request['rejectionReason'] != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: rejectedColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: rejectedColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: rejectedColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'سبب الرفض',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: rejectedColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  request['rejectionReason'],
                                  style: const TextStyle(
                                    color: rejectedColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // View details
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _showRequestDetails(request),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('عرض التفاصيل'),
                      style: TextButton.styleFrom(
                        foregroundColor: primarySkyBlue,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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
  
  // بناء صف معلومات داخل بطاقة الطلب
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? darkTextSecondary : lightTextSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  // عرض تفاصيل الطلب بتصميم محسّن
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
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 16),
                    Text(
                      _statusLabels[status]!,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    if (status == 'rejected' && request['rejectionReason'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: rejectedColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: rejectedColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: rejectedColor,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'سبب الرفض',
                                    style: TextStyle(
                                      color: rejectedColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                request['rejectionReason'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: rejectedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card with amount
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primarySkyBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primarySkyBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primarySkyBlue.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: primarySkyBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'المبلغ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primarySkyBlue,
                                  ),
                                ),
                                Text(
                                  '${request['amount']} جنيه',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // تفاصيل الطلب
                      _buildDetailsSectionHeader(
                        title: 'تفاصيل الطلب',
                        icon: Icons.receipt_long,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetailItemCard(
                        icon: Icons.receipt,
                        title: 'رقم الطلب',
                        value: request['id'] ?? 'غير متوفر',
                        color: primarySkyBlue,
                      ),
                      
                      _buildDetailItemCard(
                        icon: Icons.calendar_today,
                        title: 'تاريخ الطلب',
                        value: _formatDate(request['createdAt']),
                        color: primarySkyBlue,
                      ),
                      
                      _buildDetailItemCard(
                        icon: Icons.payment,
                        title: 'طريقة الدفع',
                        value: request['paymentMethod'],
                        color: primarySkyBlue,
                      ),
                      
                      _buildDetailItemCard(
                        icon: Icons.phone,
                        title: 'رقم/حساب المصدر',
                        value: request['sourcePhone'],
                        color: primarySkyBlue,
                      ),
                      
                      // معلومات المستخدم
                      if (request['userName'] != null && request['userName'].toString().isNotEmpty ||
                          request['universityId'] != null && request['universityId'].toString().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildDetailsSectionHeader(
                          title: 'معلومات المستخدم',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      if (request['userName'] != null && request['userName'].toString().isNotEmpty)
                        _buildDetailItemCard(
                          icon: Icons.person,
                          title: 'الاسم داخل التطبيق',
                          value: request['userName'],
                          color: primarySkyBlue,
                        ),
                      
                      if (request['universityId'] != null && request['universityId'].toString().isNotEmpty)
                        _buildDetailItemCard(
                          icon: Icons.badge,
                          title: 'الرقم الجامعي',
                          value: request['universityId'],
                          color: primarySkyBlue,
                        ),
                      
                      // إثبات الدفع
                      const SizedBox(height: 24),
                      _buildDetailsSectionHeader(
                        title: 'إثبات الدفع',
                        icon: Icons.image,
                      ),
                      const SizedBox(height: 16),
                      
                      if (request['paymentProofUrl'] != null)
                        GestureDetector(
                          onTap: () => _showFullScreenImage(context, request['paymentProofUrl']),
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: primarySkyBlue.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: request['paymentProofUrl'],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(color: primarySkyBlue),
                                    ),
                                    errorWidget: (context, url, error) => const Center(
                                      child: Icon(Icons.error, color: rejectedColor, size: 50),
                                    ),
                                  ),
                                  // View overlay
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.fullscreen,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'تكبير الصورة',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('لا يوجد إثبات دفع'),
                              ],
                            ),
                          ),
                        ),
                      
                      // معلومات إضافية للطلبات الموافق عليها
                      if (status == 'approved') ...[
                        const SizedBox(height: 24),
                        _buildDetailsSectionHeader(
                          title: 'معلومات الموافقة',
                          icon: Icons.verified,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: approvedColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: approvedColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: approvedColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: approvedColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'تمت إضافة المبلغ إلى رصيدك',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: approvedColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (request['approvedAt'] != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: approvedColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: approvedColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'تاريخ الموافقة: ${_formatDate(request['approvedAt'])}',
                                        style: const TextStyle(
                                          color: approvedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      
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
  Widget _buildDetailItemCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء عنوان مقطع تفاصيل الطلب
  Widget _buildDetailsSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: darkTextSecondary,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
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