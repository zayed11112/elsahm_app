import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:shimmer/shimmer.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'booking_details_screen.dart';
import 'apartments_list_screen.dart';
import 'complaints_screen.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger('BookingRequestsScreen');
  bool _isRefreshing = false;
  late TabController _tabController;
  late PageController _pageController;

  // Filter options
  List<String> _filterOptions = ['الكل', 'قيد الانتظار', 'مؤكد', 'ملغى'];
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _logger.info('BookingRequestsScreen initialized');
    initializeDateFormatting('ar', null);
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _pageController = PageController(initialPage: _selectedFilterIndex);
    
    // Listen to tab changes to update page view
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilterIndex = _tabController.index;
        });
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Filter bookings by status
  List<Booking> _filterBookings(List<Booking> bookings, int filterIndex) {
    if (filterIndex == 0) {
      return bookings;
    }

    BookingStatus statusFilter;
    switch (filterIndex) {
      case 1:
        statusFilter = BookingStatus.pending;
        break;
      case 2:
        statusFilter = BookingStatus.confirmed;
        break;
      case 3:
        statusFilter = BookingStatus.cancelled;
        break;
      default:
        return bookings;
    }

    return bookings.where((booking) => booking.status == statusFilter).toList();
  }

  // Format date
  String _formatDate(DateTime date) {
    try {
      return DateFormat('yyyy/MM/dd', 'ar').format(date);
    } catch (e) {
      _logger.warning('Error formatting date: $e');
      return DateFormat('yyyy/MM/dd').format(date);
    }
  }

  // Get booking status color with improved dark mode support
  Color _getStatusColor(BookingStatus status, BuildContext context, {bool isBackground = false}) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final opacity = isBackground ? (brightness == Brightness.light ? 0.12 : 0.35) : 1.0;
    
    switch (status) {
      case BookingStatus.pending:
        return isDarkMode
          ? Colors.amber[400]!.withOpacity(opacity)
          : Colors.amber.withOpacity(opacity);
      case BookingStatus.confirmed:
        return isDarkMode
          ? Colors.green[400]!.withOpacity(opacity)
          : Colors.green.withOpacity(opacity);
      case BookingStatus.cancelled:
        return isDarkMode
          ? Colors.red[400]!.withOpacity(opacity)
          : Colors.red.withOpacity(opacity);
    }
  }

  // Get booking status icon
  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.hourglass_top_rounded;
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  // Manual refresh of data
  Future<void> _refreshData() async {
    _logger.info('Manual refresh requested');
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('Building BookingRequestsScreen');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    // Define theme-specific colors
    final backgroundColor = isDarkMode 
        ? const Color(0xFF1A1C1E) // Slightly lighter than pure black
        : Colors.white;
    final dividerColor = isDarkMode 
        ? Colors.grey[700] 
        : Colors.grey[300];
    final secondaryTextColor = isDarkMode 
        ? Colors.grey[300] 
        : Colors.grey[700];
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'طلبات الحجز',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: _filterOptions.map((String filter) {
            return Tab(text: filter);
          }).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'معلومات الحجز',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ApartmentsListScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'حجز جديد',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: StreamBuilder<List<Booking>>(
          stream: _bookingService.getUserBookingsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
              return _buildLoadingState(context);
            }

            if (snapshot.hasError) {
              return _buildErrorState(context);
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(context);
            }

            final allBookings = snapshot.data!;
            
            // Use PageView for swipeable tabs
            return PageView.builder(
              controller: _pageController,
              physics: const PageScrollPhysics(),
              onPageChanged: (index) {
                // Update tab when page changes
                setState(() {
                  _selectedFilterIndex = index;
                  _tabController.animateTo(index);
                });
              },
              itemCount: _filterOptions.length,
              itemBuilder: (context, tabIndex) {
                final filteredBookings = _filterBookings(allBookings, tabIndex);
                
                if (filteredBookings.isEmpty) {
                  return _buildNoMatchingBookingsState(context);
                }
                
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: primaryColor,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return _buildBookingCard(context, booking);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ComplaintsScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode 
                ? const Color(0xFF38332A) // Warmer dark color for complaints button
                : const Color(0xFFFFF3E0),
            foregroundColor: Colors.orange[500],
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDarkMode
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          icon: Icon(
            Icons.report_problem_outlined,
            color: isDarkMode ? Colors.orange[500] : Colors.orange[700],
            size: 22,
          ),
          label: const Text(
            'تقديم شكوى',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // Show information dialog explaining the booking process
  void _showInfoDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2D3035) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 10),
              const Text('معلومات الحجز'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(
                context,
                icon: Icons.hourglass_top_rounded,
                color: isDarkMode ? Colors.amber[400]! : Colors.amber,
                title: 'قيد الانتظار',
                description: 'حجزك في انتظار التأكيد من الإدارة.',
              ),
              const Divider(),
              _buildInfoItem(
                context,
                icon: Icons.check_circle_rounded,
                color: isDarkMode ? Colors.green[400]! : Colors.green,
                title: 'مؤكد',
                description: 'تم تأكيد الحجز وهو جاهز للاستخدام.',
              ),
              const Divider(),
              _buildInfoItem(
                context,
                icon: Icons.cancel_rounded,
                color: isDarkMode ? Colors.red[400]! : Colors.red,
                title: 'ملغى',
                description: 'تم إلغاء الحجز لسبب ما، يرجى مراجعة القسم المختص.',
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('حسناً، فهمت'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[400] 
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? const Color(0xFF353840) : Colors.grey[300]!;
    final highlightColor = isDarkMode ? const Color(0xFF2D3035) : Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ListView.builder(
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ أثناء تحميل البيانات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.red[400] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 64,
                color: primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'لا توجد طلبات حجز حتى الآن',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'اكتشف الوحدات المتاحة وقم بحجز وحدتك الآن',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApartmentsListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('استكشاف الوحدات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchingBookingsState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_rounded,
                size: 56,
                color: Colors.amber[700],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد طلبات بهذه الحالة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'جرب تغيير الفلتر أو إنشاء حجز جديد',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _tabController.animateTo(0); // Switch to "All" tab
              },
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('عرض الكل'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(booking.status, context);
    final statusBgColor = _getStatusColor(booking.status, context, isBackground: true);
    
    // Improved card colors for dark mode
    final cardBgColor = isDarkMode 
        ? const Color(0xFF2D3035) // Lighter than background for better contrast
        : Colors.white;
        
    // Define text colors for better readability
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[700];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 8,
            spreadRadius: isDarkMode ? 0 : 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(
                  bookingId: booking.id,
                ),
              ),
            );
          },
          child: Column(
            children: [
              // Status header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(booking.status),
                      color: statusColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Booking.bookingStatusToString(booking.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(booking.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Property info section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Property image
                    Hero(
                      tag: 'booking_image_${booking.id}',
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDarkMode ? const Color(0xFF353840) : Colors.grey[200],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: const DecorationImage(
                            image: AssetImage('assets/icons/home-button.webp'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Property details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property name
                          Text(
                            booking.apartmentName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: primaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Price with custom formatting
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_money,
                                      size: 16,
                                      color: isDarkMode
                                          ? Theme.of(context).primaryColor.withOpacity(0.9)
                                          : Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${booking.totalPrice} جنيه',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Theme.of(context).primaryColor.withOpacity(0.9)
                                            : Theme.of(context).primaryColor,
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
                    
                    // Arrow indicator for details
                    Icon(
                      Icons.arrow_forward_ios,
                      color: secondaryTextColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
              
              // Notes section for confirmed or cancelled bookings
              if ((booking.status == BookingStatus.confirmed || 
                  booking.status == BookingStatus.cancelled) && 
                  booking.notes != null && booking.notes!.isNotEmpty)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode 
                      ? const Color(0xFF383830) // Warm dark tone for notes
                      : Colors.amber.withOpacity(0.07),
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode 
                          ? Colors.amber.withOpacity(0.3) 
                          : Colors.amber.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              size: 18,
                              color: isDarkMode ? Colors.amber[400] : Colors.amber[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ملاحظات',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDarkMode ? Colors.amber[400] : Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          booking.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Action section for pending bookings
              if (booking.status == BookingStatus.pending)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? const Color(0xFF382D2D) // Dark reddish tone for cancel section
                        : Colors.red.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.red.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'هل تريد إلغاء هذا الحجز؟',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showCancelConfirmationDialog(
                            context,
                            booking.id,
                          );
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('طلب إلغاء'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Show dialog to confirm booking cancellation with improved dark mode
  void _showCancelConfirmationDialog(BuildContext context, String bookingId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDarkMode ? const Color(0xFF2D3035) : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded, 
                color: Colors.amber[isDarkMode ? 400 : 700],
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text('إلغاء الحجز'),
            ],
          ),
          content: const Text(
            'لإلغاء الحجز، يجب تقديم شكوى توضح سبب طلب الإلغاء. هل تريد الانتقال إلى صفحة الشكاوى؟'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDarkMode ? const Color(0xFF2D3035) : Colors.white,
                    content: Row(
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 20),
                        const Text('جاري التحميل...'),
                      ],
                    ),
                  ),
                );
                
                // Get the booking details
                final booking = await _bookingService.getBookingById(bookingId);
                
                // Hide loading indicator
                Navigator.of(context, rootNavigator: true).pop();
                
                if (booking != null) {
                  // Navigate to complaints screen with the booking data
                  if (!context.mounted) return;
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ComplaintsScreen(
                        bookingToCancel: booking,
                      ),
                    ),
                  );
                } else {
                  // Show error message
                  if (!context.mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('حدث خطأ أثناء جلب بيانات الحجز'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(8),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('انتقال للشكاوى'),
            ),
          ],
        );
      },
    );
  }
}
