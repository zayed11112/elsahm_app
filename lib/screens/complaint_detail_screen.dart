import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/auth_provider.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../services/image_upload_service.dart';
import '../constants/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Define app bar color to match the wallet screen
const Color appBarBlue = Color(0xFF1976d3);
const Color adminBubbleColor = Color(0xFF8E24AA);
const Color userBubbleColor = Color(0xFF2196F3);
const Color otherUserBubbleColor = Color(0xFFEEEEEE);
const Color darkUserBubbleColor = Color(0xFF2D3748);
const Color darkAdminBubbleColor = Color(0xFF6A1B9A);
const Color darkOtherUserBubbleColor = Color(0xFF424242);

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen>
    with TickerProviderStateMixin {
  final ComplaintService _complaintService = ComplaintService();
  final TextEditingController _responseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // Remove scroll listener that was affecting input focus
    // Add controller listener instead of using onChanged
    _responseController.addListener(_handleTextControllerChange);
  }

  @override
  void dispose() {
    _responseController.removeListener(_handleTextControllerChange);
    _responseController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleTextControllerChange() {
    // Only rebuild if we REALLY need to update something visual
    // Don't call setState during text input!
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _selectImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedImageUrl = null; // Reset previous upload URL
        });

        // Upload image immediately
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء اختيار الصورة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await ImageUploadService.uploadImage(_selectedImage!);

      if (imageUrl != null) {
        setState(() {
          _uploadedImageUrl = imageUrl;
          _isUploadingImage = false;
        });
      } else {
        // Upload failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل تحميل الصورة، الرجاء المحاولة مرة أخرى'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isUploadingImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل الصورة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _addResponse(
    String complaintId,
    String userId,
    String userName,
  ) async {
    // فحص بسيط للتأكد من وجود محتوى للإرسال (نص أو صورة)
    if (_responseController.text.trim().isEmpty && _uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال نص أو إرفاق صورة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _complaintService.addResponse(
        complaintId: complaintId,
        responseText: _responseController.text.trim(),
        responderId: userId,
        responderName: userName,
        isAdmin: false, // Regular user response
        imageUrl: _uploadedImageUrl,
      );

      if (mounted) {
        _responseController.clear();
        // Clear the image after sending
        _clearSelectedImage();

        // Slight delay to ensure the new response is loaded in the stream before scrolling
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });

        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('حدث خطأ: ${e.toString()}')),
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    final backgroundColor = isDarkMode ? darkBackground : Colors.grey[100];
    final appBarColor = appBarBlue;
    final appBarIconColor = Colors.white;

    if (userId == null) {
      return _buildAuthenticationRequiredScreen(
        isDarkMode,
        appBarColor,
        appBarIconColor,
      );
    }

    return StreamBuilder<Complaint?>(
      stream: _complaintService.getComplaintById(widget.complaintId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(isDarkMode, appBarColor, appBarIconColor);
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(
            snapshot.error,
            isDarkMode,
            appBarColor,
            appBarIconColor,
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildNotFoundScreen(isDarkMode, appBarColor, appBarIconColor);
        }

        final complaint = snapshot.data!;

        // Scroll to bottom after data is loaded if there are responses
        if (complaint.responses.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: _buildAppBar(
              complaint,
              isDarkMode,
              appBarColor,
              appBarIconColor,
              userId,
            ),
            body: _buildBody(complaint, isDarkMode, userId),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    Complaint complaint,
    bool isDarkMode,
    Color appBarColor,
    Color appBarIconColor,
    String userId,
  ) {
    final statusColor = _getStatusColor(complaint.status);

    return AppBar(
      elevation: 0,
      backgroundColor: appBarColor,
      foregroundColor: appBarIconColor,
      centerTitle: false,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تفاصيل الشكوى',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${widget.complaintId.substring(0, 6)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(complaint.status),
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusText(complaint.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: appBarIconColor, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Menu button
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'close' || value == 'reopen') {
              _updateComplaintStatus(value, complaint.status);
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.more_vert, color: appBarIconColor, size: 20),
          ),
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'close',
                  enabled: complaint.status != 'closed',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color:
                            complaint.status != 'closed'
                                ? Colors.green
                                : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إغلاق الشكوى',
                        style: TextStyle(
                          color:
                              complaint.status != 'closed' ? null : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'reopen',
                  enabled: complaint.status == 'closed',
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        color:
                            complaint.status == 'closed'
                                ? Colors.blue
                                : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إعادة فتح الشكوى',
                        style: TextStyle(
                          color:
                              complaint.status == 'closed' ? null : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _updateComplaintStatus(
    String action,
    String currentStatus,
  ) async {
    String newStatus = action == 'close' ? 'closed' : 'open';

    // If already in the requested state, do nothing
    if ((newStatus == 'closed' && currentStatus == 'closed') ||
        (newStatus == 'open' && currentStatus == 'open')) {
      return;
    }

    // Store ScaffoldMessenger before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _complaintService.updateComplaintStatus(
        widget.complaintId,
        newStatus,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('تم تحديث حالة الشكوى إلى ${_getStatusText(newStatus)}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('حدث خطأ: ${e.toString()}')),
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
    }
  }

  Widget _buildAuthenticationRequiredScreen(
    bool isDarkMode,
    Color appBarColor,
    Color appBarIconColor,
  ) {
    return Scaffold(
      backgroundColor: isDarkMode ? darkBackground : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text(
          'تفاصيل الشكوى',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarIconColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 70,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
            const SizedBox(height: 20),
            Text(
              'يرجى تسجيل الدخول لعرض الشكاوى',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: appBarColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(
    bool isDarkMode,
    Color appBarColor,
    Color appBarIconColor,
  ) {
    return Scaffold(
      backgroundColor: isDarkMode ? darkBackground : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text(
          'تفاصيل الشكوى',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarIconColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: appBarBlue),
            const SizedBox(height: 20),
            Text(
              'جاري تحميل تفاصيل الشكوى...',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
    Object? error,
    bool isDarkMode,
    Color appBarColor,
    Color appBarIconColor,
  ) {
    return Scaffold(
      backgroundColor: isDarkMode ? darkBackground : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text(
          'تفاصيل الشكوى',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarIconColor),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 70, color: Colors.red[400]),
              const SizedBox(height: 20),
              Text(
                'حدث خطأ أثناء تحميل البيانات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.red[300] : Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error?.toString() ?? 'خطأ غير معروف',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    // Refresh page
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appBarColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen(
    bool isDarkMode,
    Color appBarColor,
    Color appBarIconColor,
  ) {
    return Scaffold(
      backgroundColor: isDarkMode ? darkBackground : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text(
          'تفاصيل الشكوى',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarIconColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 70,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
            const SizedBox(height: 20),
            Text(
              'لم يتم العثور على الشكوى',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'قد تكون الشكوى غير موجودة أو تم حذفها',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('العودة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appBarColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Complaint complaint, bool isDarkMode, String userId) {
    return Column(
      children: [
        // Complaint header
        _buildComplaintHeader(complaint, isDarkMode),

        // Responses section
        Expanded(child: _buildResponsesSection(complaint, isDarkMode, userId)),

        // Selected image preview (if any)
        if (_selectedImage != null) _buildSelectedImagePreview(isDarkMode),

        // Input section
        if (complaint.status != 'closed')
          _buildInputSection(complaint, isDarkMode, userId),
      ],
    );
  }

  Widget _buildComplaintHeader(Complaint complaint, bool isDarkMode) {
    final cardColor = isDarkMode ? darkCard : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'بواسطة ${complaint.userName} • ${_formatDateDetailed(complaint.createdAt)}',
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: Text(
              complaint.description,
              style: TextStyle(
                height: 1.4,
                fontSize: 14,
                color: textColor.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesSection(
    Complaint complaint,
    bool isDarkMode,
    String userId,
  ) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Column(
      children: [
        // Responses header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.forum_outlined,
                size: 18,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                'الردود (${complaint.responses.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        // Responses list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshComplaintDetails,
            color: Theme.of(context).primaryColor,
            child:
                complaint.responses.isEmpty
                    ? _buildEmptyResponsesView(complaint, isDarkMode)
                    : _buildResponsesList(complaint, isDarkMode, userId),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyResponsesView(Complaint complaint, bool isDarkMode) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد ردود بعد',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (complaint.status != 'closed') ...[
                const SizedBox(height: 12),
                Text(
                  'أضف أول رد على هذه الشكوى',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponsesList(
    Complaint complaint,
    bool isDarkMode,
    String userId,
  ) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: complaint.responses.length,
      itemBuilder: (context, index) {
        final response = complaint.responses[index];

        // Group consecutive messages by the same person
        bool showAvatar = true;
        bool showTime = true;

        if (index > 0) {
          final previousResponse = complaint.responses[index - 1];
          if (previousResponse.responderId == response.responderId) {
            // Same sender, check time difference
            final timeDiff =
                response.createdAt
                    .difference(previousResponse.createdAt)
                    .inMinutes;
            if (timeDiff < 5) {
              showAvatar = false;
              showTime = false;
            }
          }
        }

        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 350),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildResponseItem(
                context,
                response,
                userId == response.responderId,
                showAvatar: showAvatar,
                showTime: showTime,
                isDarkMode: isDarkMode,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedImagePreview(bool isDarkMode) {
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child:
                _isUploadingImage
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            'جاري تحميل الصورة...',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: _clearSelectedImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(
    Complaint complaint,
    bool isDarkMode,
    String userId,
  ) {
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final inputBackgroundColor =
        isDarkMode ? Colors.grey[800] : Colors.grey[100];
    final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final hintColor = isDarkMode ? Colors.grey[500] : Colors.grey[400];

    // Simplified input section with minimal state updates
    return Material(
      color: backgroundColor,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Attachment button (outside the text field)
              IconButton(
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                onPressed: _selectImage,
                tooltip: 'إرفاق صورة',
                padding: const EdgeInsets.all(8),
              ),

              // Text input field
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: inputBackgroundColor,
                    borderRadius: BorderRadius.circular(4), // مستطيل
                    border: Border.all(color: inputBorderColor!, width: 1),
                  ),
                  child: TextField(
                    controller: _responseController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك هنا...',
                      hintStyle: TextStyle(color: hintColor, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                      suffixIcon:
                          _responseController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                                onPressed: () {
                                  _responseController.clear();
                                },
                              )
                              : null,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    cursorColor: Theme.of(context).primaryColor,
                    textAlignVertical: TextAlignVertical.center,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              Material(
                color:
                    (_isSubmitting || _isUploadingImage)
                        ? (isDarkMode ? Colors.grey[700] : Colors.grey[300])
                        : Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap:
                      (_isSubmitting || _isUploadingImage)
                          ? null
                          : () {
                            if (_responseController.text.trim().isNotEmpty ||
                                _uploadedImageUrl != null) {
                              _addResponse(
                                widget.complaintId,
                                userId,
                                Provider.of<AuthProvider>(
                                      context,
                                      listen: false,
                                    ).user?.email?.split('@').first ??
                                    "مستخدم",
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'الرجاء إدخال نص أو إرفاق صورة',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child:
                        (_isSubmitting || _isUploadingImage)
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
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

  Widget _buildResponseItem(
    BuildContext context,
    ComplaintResponse response,
    bool isCurrentUser, {
    required bool showAvatar,
    required bool showTime,
    required bool isDarkMode,
  }) {
    final isAdmin = response.isAdmin;

    // تحديد ألوان الفقاعات بناءً على نوع المستخدم والوضع (ليلي/نهاري)
    final bubbleColor =
        isCurrentUser
            ? (isDarkMode ? userBubbleColor : userBubbleColor)
            : isAdmin
            ? (isDarkMode ? darkAdminBubbleColor : adminBubbleColor)
            : (isDarkMode ? darkOtherUserBubbleColor : otherUserBubbleColor);

    final textColor =
        (isCurrentUser || isAdmin)
            ? Colors.white
            : (isDarkMode ? Colors.white : Colors.black87);

    final timeColor =
        (isCurrentUser || isAdmin)
            ? Colors.white.withOpacity(0.7)
            : (isDarkMode ? Colors.grey[400]! : Colors.grey[600]!);

    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        top: showAvatar ? 16 : 4,
        left: isCurrentUser ? 40 : 0,
        right: isCurrentUser ? 0 : 40,
      ),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users
          if (!isCurrentUser && showAvatar)
            _buildUserAvatar(isAdmin, isDarkMode)
          else if (!isCurrentUser && !showAvatar)
            const SizedBox(width: 36),

          if (!isCurrentUser) const SizedBox(width: 8),

          // Message bubble
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                // User name and badge
                if (showAvatar)
                  Padding(
                    padding: EdgeInsets.only(
                      left: isCurrentUser ? 0 : 4,
                      right: isCurrentUser ? 4 : 0,
                      bottom: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCurrentUser && isAdmin) _buildAdminBadge(),

                        Text(
                          isCurrentUser ? 'أنت' : response.responderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color:
                                isCurrentUser
                                    ? Theme.of(context).primaryColor
                                    : (isAdmin
                                        ? Colors.purple
                                        : isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Message container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        isCurrentUser ? 16 : (showAvatar ? 16 : 4),
                      ),
                      topRight: Radius.circular(
                        isCurrentUser ? (showAvatar ? 16 : 4) : 16,
                      ),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text message
                      if (response.responseText.isNotEmpty)
                        Text(
                          response.responseText,
                          style: TextStyle(
                            color: textColor,
                            height: 1.4,
                            fontSize: 15,
                          ),
                        ),

                      // Image if available
                      if (response.imageUrl != null) ...[
                        if (response.responseText.isNotEmpty)
                          const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _openImageViewer(response.imageUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: response.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              maxHeightDiskCache: 500,
                              placeholder:
                                  (context, url) => Container(
                                    height: 150,
                                    width: 200,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 100,
                                    width: 200,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[300],
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'تعذر تحميل الصورة',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ],

                      // Timestamp
                      if (showTime) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.access_time, size: 10, color: timeColor),
                            const SizedBox(width: 2),
                            Text(
                              _getTimeAgo(response.createdAt),
                              style: TextStyle(fontSize: 10, color: timeColor),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isCurrentUser) const SizedBox(width: 8),

          // Avatar for current user
          if (isCurrentUser && showAvatar)
            _buildUserAvatar(false, isDarkMode)
          else if (isCurrentUser && !showAvatar)
            const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(bool isAdmin, bool isDarkMode) {
    final backgroundColor =
        isAdmin
            ? (isDarkMode ? darkAdminBubbleColor : adminBubbleColor)
            : Theme.of(context).primaryColor;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          isAdmin
              ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/icons/app.png',
                  fit: BoxFit.cover,
                  width: 36,
                  height: 36,
                ),
              )
              : Center(
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.5)),
      ),
      child: const Text(
        'الإدارة',
        style: TextStyle(
          color: Colors.purple,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  void _openImageViewer(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.9),
        pageBuilder:
            (context, _, __) => Stack(
              children: [
                PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: CachedNetworkImageProvider(imageUrl),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained * 0.8,
                      maxScale: PhotoViewComputedScale.covered * 1.8,
                      heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
                    );
                  },
                  itemCount: 1,
                  loadingBuilder:
                      (context, event) => Center(
                        child: Container(
                          width: 60.0,
                          height: 60.0,
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }

  // Methods for formatting time and dates
  String _formatDateDetailed(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'ar').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm a', 'ar').format(date);
  }

  String _getTimeAgo(DateTime dateTime) {
    // استخدام مكتبة timeago للحصول على وقت نسبي (منذ ...)
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // إذا كان الوقت أقل من يوم، نعرض "منذ..."
    if (difference.inHours < 24) {
      // إعداد اللغة العربية للمكتبة
      timeago.setLocaleMessages('ar', timeago.ArMessages());
      return timeago.format(dateTime, locale: 'ar');
    } else {
      // إذا أكثر من يوم، نعرض التاريخ والوقت
      return _formatTime(dateTime);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'مفتوحة';
      case 'in-progress':
        return 'قيد المعالجة';
      case 'closed':
        return 'مغلقة';
      default:
        return '';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.fiber_new;
      case 'in-progress':
        return Icons.pending_actions;
      case 'closed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in-progress':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _refreshComplaintDetails() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {});
    }
  }
}
