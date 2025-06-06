import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../constants/theme.dart';

class EnhancedBookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback? onCancelRequest;

  const EnhancedBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onCancelRequest,
  });

  @override
  State<EnhancedBookingCard> createState() => _EnhancedBookingCardState();
}

class _EnhancedBookingCardState extends State<EnhancedBookingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Format date
  String _formatDate(DateTime date) {
    try {
      return DateFormat('yyyy/MM/dd', 'ar').format(date);
    } catch (e) {
      return DateFormat('yyyy/MM/dd').format(date);
    }
  }

  // Get booking status color with improved dark mode support
  Color _getStatusColor(
    BookingStatus status,
    BuildContext context, {
    bool isBackground = false,
  }) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final opacity =
        isBackground ? (brightness == Brightness.light ? 0.12 : 0.35) : 1.0;

    switch (status) {
      case BookingStatus.pending:
        return isDarkMode
            ? Colors.amber[400]!.withValues(alpha: opacity)
            : Colors.amber.withValues(alpha: opacity);
      case BookingStatus.confirmed:
        return isDarkMode
            ? Colors.green[400]!.withValues(alpha: opacity)
            : Colors.green.withValues(alpha: opacity);
      case BookingStatus.cancelled:
        return isDarkMode
            ? Colors.red[400]!.withValues(alpha: opacity)
            : Colors.red.withValues(alpha: opacity);
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(widget.booking.status, context);
    final statusBgColor = _getStatusColor(
      widget.booking.status,
      context,
      isBackground: true,
    );

    // Enhanced card colors for better visual appeal
    final cardBgColor = isDarkMode ? const Color(0xFF2D3035) : Colors.white;

    // Define text colors for better readability
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[700];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardBgColor,
                isDarkMode ? const Color(0xFF353A47) : const Color(0xFFFAFBFC),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDarkMode
                        ? Colors.black.withValues(alpha: 0.4)
                        : primaryBlue.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color:
                    isDarkMode
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.8),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Column(
                children: [
                  // Enhanced status header with gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          statusBgColor,
                          statusBgColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getStatusIcon(widget.booking.status),
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            Booking.bookingStatusToString(
                              widget.booking.status,
                            ),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDate(widget.booking.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enhanced property info section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Enhanced property image with hero animation
                        Hero(
                          tag: 'booking_image_${widget.booking.id}',
                          child: Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryBlue.withValues(alpha: 0.1),
                                  primaryBlueLight.withValues(alpha: 0.05),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.apartment_rounded,
                              size: 40,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Enhanced property details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Property name with enhanced typography
                              Text(
                                widget.booking.apartmentName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryTextColor,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              // Enhanced price display with modern design
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryBlue.withValues(alpha: 0.1),
                                      primaryBlueLight.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryBlue.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.payments_rounded,
                                      size: 18,
                                      color: primaryBlue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.booking.totalPrice} جنيه',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Enhanced arrow indicator
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: secondaryTextColor,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enhanced notes section
                  if ((widget.booking.status == BookingStatus.confirmed ||
                          widget.booking.status == BookingStatus.cancelled) &&
                      widget.booking.notes != null &&
                      widget.booking.notes!.isNotEmpty)
                    _buildNotesSection(isDarkMode, secondaryTextColor),

                  // Enhanced action section for pending bookings
                  if (widget.booking.status == BookingStatus.pending &&
                      widget.onCancelRequest != null)
                    _buildActionSection(isDarkMode, primaryTextColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection(bool isDarkMode, Color? secondaryTextColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode
                ? const Color(0xFF383830)
                : Colors.amber.withValues(alpha: 0.08),
            isDarkMode
                ? const Color(0xFF3A3A2E)
                : Colors.amber.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.amber.withValues(alpha: 0.3)
                  : Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
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
          const SizedBox(height: 8),
          Text(
            widget.booking.notes!,
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(bool isDarkMode, Color primaryTextColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode
                ? const Color(0xFF382D2D)
                : Colors.red.withValues(alpha: 0.06),
            isDarkMode
                ? const Color(0xFF3A2F2F)
                : Colors.red.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1),
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
            onPressed: widget.onCancelRequest,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('طلب إلغاء'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
