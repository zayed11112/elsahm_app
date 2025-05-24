import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:logging/logging.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'booking_details_screen.dart';
import 'apartments_list_screen.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger('BookingRequestsScreen');
  bool _isRefreshing = false;
  bool _isDateFormattingInitialized = false;
  
  // Status filter
  String _selectedStatusFilter = 'الكل';
  final List<String> _statusFilters = ['الكل', 'قيد الانتظار', 'مؤكد', 'ملغى'];
  
  @override
  void initState() {
    super.initState();
    _logger.info('BookingRequestsScreen initialized');
    initializeDateFormatting('ar', null).then((_) {
      setState(() {
        _isDateFormattingInitialized = true;
      });
    });
  }

  // Filter bookings by status
  List<Booking> _filterBookings(List<Booking> bookings) {
    if (_selectedStatusFilter == 'الكل') {
      return bookings;
    }
    
    BookingStatus statusFilter;
    switch (_selectedStatusFilter) {
      case 'قيد الانتظار':
        statusFilter = BookingStatus.pending;
        break;
      case 'مؤكد':
        statusFilter = BookingStatus.confirmed;
        break;
      case 'ملغى':
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

  // Get booking status color
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.amber;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
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
      default:
        return Icons.info_outline;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الحجز',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Add refresh button to app bar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // الانتقال إلى شاشة العقارات المتاحة بدلاً من الشاشة الرئيسية
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => const ApartmentsListScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('حجز جديد'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          // Status filter
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedStatusFilter,
                items: _statusFilters.map((String filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontWeight: filter == _selectedStatusFilter
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatusFilter = newValue;
                    });
                  }
                },
                icon: const Icon(Icons.filter_list),
                hint: const Text('تصفية حسب الحالة'),
              ),
            ),
          ),
          
          // Bookings list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: StreamBuilder<List<Booking>>(
                stream: _bookingService.getUserBookingsStream(),
                builder: (context, snapshot) {
                  // Log the current state of the stream
                  _logger.info('Stream state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
                  if (snapshot.hasError) {
                    _logger.severe('Stream error: ${snapshot.error}');
                  }
                  if (snapshot.hasData) {
                    _logger.info('Stream data count: ${snapshot.data!.length}');
                  }
                  
                  if (_isRefreshing) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData) {
                    _logger.warning('No data in snapshot');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'لا توجد بيانات للعرض',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'يرجى المحاولة مرة أخرى',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final bookings = snapshot.data!;
                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'لا توجد طلبات حجز حتى الآن',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ستظهر طلبات الحجز الخاصة بك هنا',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 70,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ أثناء تحميل البيانات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final filteredBookings = _filterBookings(bookings);
                  _logger.info('Filtered bookings count: ${filteredBookings.length}');
                  
                  if (filteredBookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_list, size: 70, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات حجز بالحالة: $_selectedStatusFilter',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'جرب تصفية أخرى أو اختر "الكل"',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      _logger.info('Rendering booking: ${booking.id}, name: ${booking.apartmentName}');
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Column(
                          children: [
                            // Property info
                            Row(
                              children: [
                                // Property image (placeholder for now)
                                Container(
                                  height: 100,
                                  width: 100,
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[200],
                                  ),
                                  child: const Icon(Icons.home, size: 40, color: Colors.grey),
                                ),
                                
                                // Property details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.apartmentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'تاريخ الطلب: ${_formatDate(booking.createdAt)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'السعر: ${booking.totalPrice} جنيه',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Divider
                            const Divider(height: 1),
                            
                            // Status section
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(booking.status).withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(booking.status),
                                        color: _getStatusColor(booking.status),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'الحالة: ${Booking.bookingStatusToString(booking.status)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(booking.status),
                                        ),
                                      ),
                                    ],
                                  ),
                                  booking.status == BookingStatus.pending
                                      ? TextButton(
                                          onPressed: () {
                                            _showCancelConfirmationDialog(context, booking.id);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            backgroundColor: Colors.red.withOpacity(0.1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text('إلغاء الحجز'),
                                        )
                                      : ElevatedButton(
                                          onPressed: () {
                                            // Navigate to booking details
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => BookingDetailsScreen(
                                                  bookingId: booking.id,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            backgroundColor: Theme.of(context).primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('التفاصيل'),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to confirm booking cancellation
  void _showCancelConfirmationDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الإلغاء'),
          content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الحجز؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('لا'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                
                // Show loading indicator
                _showLoadingDialog(context);
                
                // Cancel the booking
                final success = await _bookingService.cancelBooking(bookingId);
                
                // Hide loading indicator
                Navigator.of(context).pop();
                
                // Show result
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'تم إلغاء الحجز بنجاح' : 'حدث خطأ أثناء إلغاء الحجز',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('نعم، إلغاء الحجز'),
            ),
          ],
        );
      },
    );
  }

  // Show loading dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('جاري المعالجة...'),
            ],
          ),
        );
      },
    );
  }
} 