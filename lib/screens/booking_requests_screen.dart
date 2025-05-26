import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
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

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger('BookingRequestsScreen');
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _logger.info('BookingRequestsScreen initialized');
    initializeDateFormatting('ar', null);
  }

  // Filter bookings by status
  List<Booking> _filterBookings(List<Booking> bookings) {
    return bookings;
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

  // Get booking status color
  Color _getStatusColor(BookingStatus status, BuildContext context, {bool isBackground = false}) {
    final brightness = Theme.of(context).brightness;
    final opacity = isBackground ? (brightness == Brightness.light ? 0.12 : 0.2) : 1.0;
    
    switch (status) {
      case BookingStatus.pending:
        return Colors.amber.withOpacity(opacity);
      case BookingStatus.confirmed:
        return Colors.green.withOpacity(opacity);
      case BookingStatus.cancelled:
        return Colors.red.withOpacity(opacity);
    }
  }

  // Get booking status icon
  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.hourglass_empty;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'طلبات الحجز',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode 
          ? Theme.of(context).scaffoldBackgroundColor 
          : Theme.of(context).primaryColor,
        foregroundColor: isDarkMode
          ? Theme.of(context).primaryColor
          : Colors.white,
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
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          Column(
            children: [
              // Header section with subtle gradient
              Container(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? Theme.of(context).scaffoldBackgroundColor 
                    : Theme.of(context).primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Text(
                  'لإلغاء الحجز واسترداد الرصيد، يُرجى تقديم شكوى',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
              
              // Main content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: Theme.of(context).primaryColor,
                  child: StreamBuilder<List<Booking>>(
                    stream: _bookingService.getUserBookingsStream(),
                    builder: (context, snapshot) {
                      if (_isRefreshing) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState(context);
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      final filteredBookings = _filterBookings(snapshot.data!);
                      if (filteredBookings.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return _buildBookingCard(context, booking);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          
          // Complaint button positioned at bottom left
          Positioned(
            left: 20,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: isDarkMode ? const Color(0xFF2D3035) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ComplaintsScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تقديم شكوى',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 70,
              color: Colors.red[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'حدث خطأ أثناء تحميل البيانات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.home_work_outlined,
              size: 80,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد طلبات حجز حتى الآن',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'اكتشف الوحدات المتاحة وقم بحجز وحدتك الآن',
              style: TextStyle(
                fontSize: 14,
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
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(booking.status, context);
    final bgColor = isDarkMode ? Colors.grey[850] : Colors.white;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
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
              // Property info section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property image with status indicator
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Hero(
                          tag: 'booking_image_${booking.id}',
                          child: Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              image: const DecorationImage(
                                image: AssetImage('assets/icons/icon_real-estate.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black54 : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(booking.status),
                                color: statusColor,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                Booking.bookingStatusToString(booking.status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Property details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'booking_title_${booking.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                booking.apartmentName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Booking details row
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(booking.createdAt),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          
                          // Price with custom formatting
                          Row(
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                    ? Theme.of(context).primaryColor.withOpacity(0.9)
                                    : Theme.of(context).primaryColor,
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
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
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
                      ? Colors.grey[800]!.withOpacity(0.4) 
                      : Colors.amber.withOpacity(0.07),
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode 
                          ? Colors.grey[700]! 
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
                                color: isDarkMode ? Colors.amber[300] : Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          booking.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Action section (separate from the clickable area)
              if (booking.status == BookingStatus.pending)
                Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status, context, isBackground: true),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'هل تريد إلغاء هذا الحجز؟',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _showCancelConfirmationDialog(
                                context,
                                booking.id,
                              );
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('طلب إلغاء'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              backgroundColor: Colors.red.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Show dialog to confirm booking cancellation
  void _showCancelConfirmationDialog(BuildContext context, String bookingId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded, 
                color: Colors.amber,
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
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                // Get the booking details
                final booking = await _bookingService.getBookingById(bookingId);
                
                // Hide loading indicator
                Navigator.of(context, rootNavigator: true).pop();
                
                if (booking != null) {
                  // Navigate to complaints screen with the booking data
                  if (!mounted) return;
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ComplaintsScreen(
                        bookingToCancel: booking,
                      ),
                    ),
                  );
                } else {
                  // Show error message
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('حدث خطأ أثناء تحميل بيانات الحجز'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('متابعة'),
            ),
          ],
        );
      },
    );
  }
}
