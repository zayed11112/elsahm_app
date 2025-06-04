import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';
import 'complaints_screen.dart';

// Define colors used in other screens for consistency
const Color primarySkyBlue = Color(0xFF4FC3F7);
const Color accentBlue = Color(0xFF29B6F6);

// Define app bar color to match the wallet screen
const Color appBarBlue = Color(0xFF1976d3);

// Animation durations
const Duration kCardAnimationDuration = Duration(milliseconds: 300);
const Duration kTabAnimationDuration = Duration(milliseconds: 200);

class PaymentRequestsScreen extends StatefulWidget {
  const PaymentRequestsScreen({super.key});

  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen>
    with SingleTickerProviderStateMixin {
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

  // التنسيقات الخاصة بحالات الطلبات
  final Map<String, String> _statusLabels = const {
    'pending': 'قيد المراجعة',
    'approved': 'تمت الموافقة',
    'rejected': 'تم الرفض',
  };

  // أيقونات حالات الطلبات
  final Map<String, IconData> _statusIcons = const {
    'pending': Icons.hourglass_top,
    'approved': Icons.check_circle,
    'rejected': Icons.cancel,
  };
  
  // Cache for request cards to avoid unnecessary rebuilds
  final Map<String, Widget> _requestCardCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen for tab changes to trigger animations
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // Clear card cache when changing tabs to ensure fresh data
      setState(() {
        _requestCardCache.clear();
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _streams.clear();
    _requestCardCache.clear();
    super.dispose();
  }

  // الحصول على استعلام مع التأكد من عدم تكرار إنشاء الاستعلامات
  Stream<List<Map<String, dynamic>>> _getStream(String userId, String status) {
    final key = '$userId-$status';
    if (!_streams.containsKey(key)) {
      _streams[key] = supabaseService.getUserPaymentRequestsStream(
        userId,
        status,
      );
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
  
  // Get request card with caching for performance
  Widget _getCachedRequestCard(Map<String, dynamic> request, bool isDarkMode) {
    final String requestId = request['id']?.toString() ?? '';
    final String cacheKey = '$requestId-${request['updatedAt'] ?? request['createdAt']}';
    
    if (!_requestCardCache.containsKey(cacheKey)) {
      _requestCardCache[cacheKey] = _buildRequestCard(request, isDarkMode);
    }
    
    return _requestCardCache[cacheKey]!;
  }
  
  // Clear all caches to refresh data
  Future<void> _refreshData() async {
    setState(() {
      _streams.clear();
      _requestCardCache.clear();
    });
    
    // Show refresh confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text('تم تحديث البيانات'),
            ],
          ),
          backgroundColor: primarySkyBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 1),
        ),
      );
    }
    
    // انتظار قليلاً لإعطاء شعور بالتحديث
    return Future.delayed(const Duration(milliseconds: 800));
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[200]!.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle,
                  size: 80,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'يرجى تسجيل الدخول لعرض طلبات الدفع',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
          strokeWidth: 3.0,
          displacement: 40,
          edgeOffset: 20,
          onRefresh: _refreshData,
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

              // Complaints button
              Positioned(
                bottom: 20,
                right: 0,
                left: 0,
                child: Center(
                  child: _buildComplaintsButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بناء شريط التطبيق المُحسن
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'طلبات الدفع',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: appBarBlue,
      elevation: 0, // Remove shadow for a more modern look
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Professional refresh button in app bar
        Container(
          margin: const EdgeInsets.only(left: 8, right: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: _refreshData,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: appBarBlue,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorSize: TabBarIndicatorSize.label, // More precise indicator
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            tabs: const [
              Tab(text: 'قيد المراجعة'),
              Tab(text: 'تمت الموافقة'),
              Tab(text: 'تم الرفض'),
            ],
          ),
        ),
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
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Modern loading indicator
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primarySkyBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: primarySkyBlue,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'جاري تحميل الطلبات...',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يتم استرجاع البيانات',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 60),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: rejectedColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: rejectedColor,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'حدث خطأ أثناء تحميل الطلبات',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            color: context.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _refreshData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primarySkyBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(emptyIcon, emptyMessage);
        }

        // Use a staggered animation for list items
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
                final shouldAnimate =
                    _tabController.index == _getTabIndexForStatus(status);
                
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: shouldAnimate ? 1 : 0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _getCachedRequestCard(requests[index], context.isDarkMode),
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
      case 'pending':
        return 0;
      case 'approved':
        return 1;
      case 'rejected':
        return 2;
      default:
        return 0;
    }
  }

  // بناء حالة فارغة بتصميم جذاب
  Widget _buildEmptyState(IconData icon, String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3, // Enough space for pull
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primarySkyBlue.withOpacity(0.1),
                      primarySkyBlue.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primarySkyBlue.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 70,
                  color: primarySkyBlue.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: context.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'اسحب للأسفل لتحديث البيانات',
                style: TextStyle(
                  fontSize: 14,
                  color: context.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // بناء بطاقة طلب بمظهر جديد أكثر احترافية
  Widget _buildRequestCard(Map<String, dynamic> request, bool isDarkMode) {
    final status = request['status'] as String;
    final statusColor = context.getStatusColor(status);
    final amount = '${request['amount']} جنيه';
    final date = _formatDate(request['createdAt']);

    // Get payment method icon
    IconData paymentIcon =
        request['paymentMethod'].toString().contains('فودافون')
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
              color: statusColor.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern amount display at the top with highlight
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.15),
                    statusColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.payments_outlined,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            amount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
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

                  // Status badge with improved design
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
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

            // Card content with improved styling
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment method with enhanced visual
                  _buildInfoRowEnhanced(
                    icon: paymentIcon,
                    label: 'طريقة الدفع',
                    value: request['paymentMethod'],
                    isDarkMode: isDarkMode,
                    iconColor: statusColor,
                  ),

                  const SizedBox(height: 12),

                  // User info if available
                  if (request['userName'] != null &&
                      request['userName'].toString().isNotEmpty)
                    _buildInfoRowEnhanced(
                      icon: Icons.person,
                      label: 'الاسم',
                      value: request['userName'],
                      isDarkMode: isDarkMode,
                      iconColor: statusColor,
                    ),

                  if (request['userName'] != null &&
                      request['userName'].toString().isNotEmpty)
                    const SizedBox(height: 12),

                  // University ID if available
                  if (request['universityId'] != null &&
                      request['universityId'].toString().isNotEmpty)
                    _buildInfoRowEnhanced(
                      icon: Icons.badge,
                      label: 'الرقم الجامعي',
                      value: request['universityId'],
                      isDarkMode: isDarkMode,
                      iconColor: statusColor,
                    ),

                  // Show rejection reason for rejected requests with improved styling
                  if (status == 'rejected' &&
                      request['rejectionReason'] != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            rejectedColor.withOpacity(0.1),
                            rejectedColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: rejectedColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: rejectedColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: rejectedColor,
                            ),
                          ),
                          const SizedBox(width: 10),
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

                  // View details button with improved design
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primarySkyBlue.withOpacity(0.2),
                              primarySkyBlue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton.icon(
                          onPressed: () => _showRequestDetails(request),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('عرض التفاصيل'),
                          style: TextButton.styleFrom(
                            foregroundColor: primarySkyBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
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

  // Enhanced info row with better visual styling
  Widget _buildInfoRowEnhanced({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // عرض تفاصيل الطلب بتصميم محسّن
  void _showRequestDetails(Map<String, dynamic> request) {
    final isDarkMode = context.isDarkMode;
    final status = request['status'] as String;
    final statusColor = context.getStatusColor(status);

    // Use const where possible for performance
    const Duration animationDuration = Duration(milliseconds: 400);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        duration: animationDuration,
        vsync: this,
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      const Color(0xFF1F1F1F),
                      const Color(0xFF121212),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF5F5F5),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
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
              // Status Header with animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.15),
                        statusColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'status_icon_${request['id']}',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _statusIcons[status],
                            color: statusColor,
                            size: 40,
                          ),
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
                      if (status == 'rejected' &&
                          request['rejectionReason'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                                  style: const TextStyle(color: rejectedColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card with amount
                      _buildAnimatedCard(
                        delay: 200,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primarySkyBlue.withOpacity(0.15),
                                primarySkyBlue.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primarySkyBlue.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primarySkyBlue.withOpacity(0.8),
                                      primarySkyBlue.withOpacity(0.6),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primarySkyBlue.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'المبلغ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: primarySkyBlue.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${request['amount']} جنيه',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // تفاصيل الطلب
                      _buildAnimatedCard(
                        delay: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                          ],
                        ),
                      ),

                      // معلومات المستخدم
                      if (request['userName'] != null &&
                              request['userName'].toString().isNotEmpty ||
                          request['universityId'] != null &&
                              request['universityId'].toString().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildAnimatedCard(
                          delay: 400,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailsSectionHeader(
                                title: 'معلومات المستخدم',
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),
                              if (request['userName'] != null &&
                                  request['userName'].toString().isNotEmpty)
                                _buildDetailItemCard(
                                  icon: Icons.person,
                                  title: 'الاسم داخل التطبيق',
                                  value: request['userName'],
                                  color: primarySkyBlue,
                                ),
                              if (request['universityId'] != null &&
                                  request['universityId'].toString().isNotEmpty)
                                _buildDetailItemCard(
                                  icon: Icons.badge,
                                  title: 'الرقم الجامعي',
                                  value: request['universityId'],
                                  color: primarySkyBlue,
                                ),
                            ],
                          ),
                        ),
                      ],

                      // إثبات الدفع
                      const SizedBox(height: 24),
                      _buildAnimatedCard(
                        delay: 500,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailsSectionHeader(
                              title: 'إثبات الدفع',
                              icon: Icons.image,
                            ),
                            const SizedBox(height: 16),
                            if (request['paymentProofUrl'] != null)
                              GestureDetector(
                                onTap: () => _showFullScreenImage(
                                  context,
                                  request['paymentProofUrl'],
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Hero(
                                          tag: 'payment_proof_${request['id']}',
                                          child: CachedNetworkImage(
                                            imageUrl: request['paymentProofUrl'],
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: isDarkMode
                                                  ? Colors.grey[850]
                                                  : Colors.grey[200],
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  color: primarySkyBlue,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) =>
                                                Container(
                                              color: isDarkMode
                                                  ? Colors.grey[850]
                                                  : Colors.grey[200],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.error,
                                                  color: rejectedColor,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Gradient overlay
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 80,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.7),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // View button
                                        Positioned(
                                          right: 12,
                                          bottom: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.fullscreen,
                                                  color: primarySkyBlue,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'تكبير الصورة',
                                                  style: TextStyle(
                                                    color: primarySkyBlue,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
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
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text('لا يوجد إثبات دفع'),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // معلومات إضافية للطلبات الموافق عليها
                      if (status == 'approved') ...[
                        const SizedBox(height: 24),
                        _buildAnimatedCard(
                          delay: 600,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailsSectionHeader(
                                title: 'معلومات الموافقة',
                                icon: Icons.verified,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      approvedColor.withOpacity(0.15),
                                      approvedColor.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: approvedColor.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: -5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                approvedColor.withOpacity(0.3),
                                                approvedColor.withOpacity(0.2),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: approvedColor.withOpacity(0.2),
                                                blurRadius: 10,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: approvedColor,
                                            size: 28,
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
                                          color: approvedColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
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

  // Helper to create animated cards in details view
  Widget _buildAnimatedCard({
    required int delay,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuart,
      // Add delay based on position in list
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // عرض الصورة بشكل كامل
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
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
                  placeholder:
                      (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  errorWidget:
                      (context, url, error) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 50,
                          ),
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
                    color: Colors.black.withValues(alpha: 0.6),
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
          Icon(icon, size: 18, color: color),
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
        Icon(icon, size: 20, color: darkTextSecondary),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  // بناء زر الشكوى
  Widget _buildComplaintsButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: primarySkyBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ComplaintsScreen(),
            ),
          );
        },
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.report_problem_outlined,
            size: 20,
            color: Colors.white,
          ),
        ),
        label: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'تقديم شكوى جديدة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySkyBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
