import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../constants/theme.dart';
import '../widgets/enhanced_booking_card.dart';
import '../widgets/enhanced_loading.dart';
import 'booking_details_screen.dart';
import 'apartments_list_screen.dart';
import 'complaints_screen.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger('BookingRequestsScreen');
  bool _isRefreshing = false;

  // Filter options
  final List<String> _filterOptions = ['الكل', 'قيد الانتظار', 'مؤكد', 'ملغى'];
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _logger.info('BookingRequestsScreen initialized');
    initializeDateFormatting('ar', null);
  }

  // Filter bookings by status
  List<Booking> _filterBookings(List<Booking> bookings, int filterIndex) {
    _logger.info(
      'Filtering bookings: filterIndex=$filterIndex, total bookings=${bookings.length}',
    );

    // Debug: Print all booking statuses
    for (int i = 0; i < bookings.length; i++) {
      _logger.info(
        'Booking $i: status=${bookings[i].status}, name=${bookings[i].apartmentName}',
      );
    }

    if (filterIndex == 0) {
      _logger.info('Returning all bookings (filterIndex=0)');
      return bookings;
    }

    BookingStatus statusFilter;
    String filterName;
    switch (filterIndex) {
      case 1:
        statusFilter = BookingStatus.pending;
        filterName = 'pending';
        break;
      case 2:
        statusFilter = BookingStatus.confirmed;
        filterName = 'confirmed';
        break;
      case 3:
        statusFilter = BookingStatus.cancelled;
        filterName = 'cancelled';
        break;
      default:
        _logger.warning(
          'Unknown filterIndex: $filterIndex, returning all bookings',
        );
        return bookings;
    }

    final filteredBookings =
        bookings.where((booking) => booking.status == statusFilter).toList();
    _logger.info(
      'Filter $filterName: found ${filteredBookings.length} bookings',
    );

    return filteredBookings;
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

    // Enhanced theme-specific colors
    final backgroundColor = isDarkMode ? darkBackground : lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlueDark, primaryBlue],
            ),
          ),
        ),
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
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
              onPressed: () => _showInfoDialog(context),
              tooltip: 'معلومات الحجز',
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryBlue, primaryBlueLight],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ApartmentsListScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: const Text(
            'حجز جديد',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            // Filter buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? const Color(0xFF1E1E1E).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.9),
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      _filterOptions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final filter = entry.value;
                        final isSelected = _selectedFilterIndex == index;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilterIndex = index;
                              });
                            },
                            backgroundColor:
                                isDarkMode
                                    ? const Color(0xFF2D2D2D)
                                    : Colors.grey[100],
                            selectedColor:
                                isDarkMode
                                    ? primaryColor.withValues(alpha: 0.3)
                                    : primaryColor.withValues(alpha: 0.2),
                            checkmarkColor:
                                isDarkMode ? Colors.white : primaryColor,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? (isDarkMode
                                          ? Colors.white
                                          : primaryColor)
                                      : (isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700]),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? primaryColor
                                        : (isDarkMode
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            elevation: isSelected ? 2 : 0,
                            shadowColor:
                                isDarkMode
                                    ? primaryColor.withValues(alpha: 0.3)
                                    : Colors.black26,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            // Content
            Expanded(
              child: StreamBuilder<List<Booking>>(
                stream: _bookingService.getUserBookingsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !_isRefreshing) {
                    return const EnhancedLoading(
                      style: LoadingStyle.shimmer,
                      size: 60,
                      message: 'جاري تحميل طلبات الحجز...',
                      showMessage: true,
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(context);
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  final allBookings = snapshot.data!;
                  final filteredBookings = _filterBookings(
                    allBookings,
                    _selectedFilterIndex,
                  );

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
                        return EnhancedBookingCard(
                          booking: booking,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BookingDetailsScreen(
                                      bookingId: booking.id,
                                    ),
                              ),
                            );
                          },
                          onCancelRequest:
                              booking.status == BookingStatus.pending
                                  ? () => _showCancelConfirmationDialog(
                                    context,
                                    booking.id,
                                  )
                                  : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
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
              backgroundColor:
                  isDarkMode
                      ? const Color(
                        0xFF2D2416,
                      ) // Darker warm color for dark mode
                      : const Color(0xFFFFF3E0),
              foregroundColor:
                  isDarkMode ? Colors.orange[400] : Colors.orange[700],
              elevation: isDarkMode ? 2 : 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      isDarkMode
                          ? Colors.orange.withValues(alpha: 0.4)
                          : Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              shadowColor:
                  isDarkMode
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.transparent,
            ),
            icon: Icon(
              Icons.report_problem_outlined,
              color: isDarkMode ? Colors.orange[400] : Colors.orange[700],
              size: 22,
            ),
            label: Text(
              'تقديم شكوى',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDarkMode ? Colors.orange[400] : Colors.orange[700],
              ),
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
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          elevation: isDarkMode ? 8 : 4,
          shadowColor:
              isDarkMode ? Colors.black.withValues(alpha: 0.5) : Colors.black26,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات الحجز',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                description:
                    'تم إلغاء الحجز لسبب ما، يرجى مراجعة القسم المختص.',
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: isDarkMode ? 4 : 2,
                  shadowColor:
                      isDarkMode
                          ? Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.5)
                          : Colors.black26,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'حسناً، فهمت',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
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
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
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
                    color:
                        Theme.of(context).brightness == Brightness.dark
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
                color: Colors.red.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 64,
                color: primaryColor.withValues(alpha: 0.7),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
                color: Colors.amber.withValues(alpha: 0.1),
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
                setState(() {
                  _selectedFilterIndex = 0; // Switch to "All" filter
                });
              },
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('عرض الكل'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

  // Show dialog to confirm booking cancellation with improved dark mode
  void _showCancelConfirmationDialog(BuildContext context, String bookingId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: isDarkMode ? 8 : 4,
          shadowColor:
              isDarkMode ? Colors.black.withValues(alpha: 0.5) : Colors.black26,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber[isDarkMode ? 400 : 700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إلغاء الحجز',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'لإلغاء الحجز، يجب تقديم شكوى توضح سبب طلب الإلغاء. هل تريد الانتقال إلى صفحة الشكاوى؟',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              fontSize: 16,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close the dialog
                    },
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop(); // Close the dialog

                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (context) => AlertDialog(
                              backgroundColor:
                                  isDarkMode
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[700]!
                                          : Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              content: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Theme.of(context).primaryColor,
                                      strokeWidth: 3,
                                    ),
                                    const SizedBox(width: 20),
                                    Text(
                                      'جاري التحميل...',
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      );

                      // Get the booking details
                      final booking = await _bookingService.getBookingById(
                        bookingId,
                      );

                      // Hide loading indicator
                      if (!context.mounted) return;
                      Navigator.of(context, rootNavigator: true).pop();

                      if (booking != null) {
                        // Navigate to complaints screen with the booking data
                        if (!context.mounted) return;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ComplaintsScreen(bookingToCancel: booking),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'انتقال للشكاوى',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
