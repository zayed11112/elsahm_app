import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../services/firestore_service.dart';
import '../services/image_upload_service.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _responseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _responseController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Only proceed if text is entered or image is uploaded
        if (_responseController.text.trim().isNotEmpty ||
            _uploadedImageUrl != null) {
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
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('الرجاء إدخال نص أو إرفاق صورة'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
  }

  Future<void> _refreshComplaintDetails() async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        // إعادة بناء واجهة المستخدم فقط
        // StreamBuilder سيقوم بتحديث البيانات تلقائيًا
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول لعرض الشكاوى')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل الشكوى',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'close' ||
                  value == 'reopen' ||
                  value == 'inprogress') {
                String newStatus = 'open';
                if (value == 'close') newStatus = 'closed';
                if (value == 'inprogress') newStatus = 'in-progress';

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
                            Text(
                              'تم تحديث حالة الشكوى إلى ${_getStatusText(newStatus)}',
                            ),
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
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_vert,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'inprogress',
                    child: Row(
                      children: [
                        Icon(Icons.pending_actions, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('تحديث إلى قيد المعالجة'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'close',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Text('إغلاق الشكوى'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'reopen',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('إعادة فتح الشكوى'),
                      ],
                    ),
                  ),
                ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder(
        future: _firestoreService.getUserProfile(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError || !userSnapshot.hasData) {
            return Center(child: Text('حدث خطأ: ${userSnapshot.error}'));
          }

          final userName = userSnapshot.data!.name;

          return StreamBuilder<Complaint?>(
            stream: _complaintService.getComplaintById(widget.complaintId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('لم يتم العثور على الشكوى'));
              }

              final complaint = snapshot.data!;
              final statusColor = _getStatusColor(complaint.status);

              // After the data is loaded, scroll to bottom if there are responses
              if (complaint.responses.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
              }

              return Column(
                children: [
                  // Complaint header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                complaint.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(complaint.status),
                                    size: 16,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getStatusText(complaint.status),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              complaint.userName,
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateDetailed(complaint.createdAt),
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Responses section label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 18,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الردود (${complaint.responses.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color:
                                isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Messages/Responses section
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshComplaintDetails,
                      color: Theme.of(context).primaryColor,
                      child:
                          complaint.responses.isEmpty
                              ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 60,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'لا توجد ردود بعد',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (complaint.status != 'closed') ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            'أضف أول رد على هذه الشكوى',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount:
                                    complaint.responses.length +
                                    1, // +1 for complaint description
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    // First message is the complaint itself
                                    return _buildComplaintMessage(
                                      context,
                                      complaint,
                                    );
                                  } else {
                                    // Subsequent messages are responses
                                    final response =
                                        complaint.responses[index - 1];

                                    // Group consecutive messages by the same person
                                    bool showAvatar = true;
                                    bool showTime = true;

                                    if (index > 1) {
                                      final previousResponse =
                                          complaint.responses[index - 2];
                                      if (previousResponse.responderId ==
                                          response.responderId) {
                                        // Same sender, check time difference
                                        final timeDiff =
                                            response.createdAt
                                                .difference(
                                                  previousResponse.createdAt,
                                                )
                                                .inMinutes;
                                        if (timeDiff < 5) {
                                          showAvatar = false;
                                          showTime = false;
                                        }
                                      }
                                    }

                                    return _buildResponseItem(
                                      context,
                                      response,
                                      userId == response.responderId,
                                      showAvatar: showAvatar,
                                      showTime: showTime,
                                    );
                                  }
                                },
                              ),
                    ),
                  ),

                  // Selected image preview (if any)
                  if (_selectedImage != null)
                    Container(
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
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
                                              color:
                                                  isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87,
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
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Input section
                  if (complaint.status != 'closed')
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color:
                                        isDarkMode
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _responseController,
                                  decoration: InputDecoration(
                                    hintText: 'اكتب ردك هنا...',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        Icons.attach_file,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                      onPressed: _selectImage,
                                    ),
                                  ),
                                  validator: (value) {
                                    // Allow empty text if image is selected
                                    if ((value == null ||
                                            value.trim().isEmpty) &&
                                        _uploadedImageUrl == null) {
                                      return 'الرجاء إدخال رد أو إرفاق صورة';
                                    }
                                    return null;
                                  },
                                  maxLines: 4,
                                  minLines: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).primaryColor.withBlue(
                                      (Theme.of(context).primaryColor.b + 40)
                                          .clamp(0, 255)
                                          .toInt(),
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap:
                                      (_isSubmitting || _isUploadingImage)
                                          ? null
                                          : () => _addResponse(
                                            widget.complaintId,
                                            userId,
                                            userName,
                                          ),
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    alignment: Alignment.center,
                                    child:
                                        (_isSubmitting || _isUploadingImage)
                                            ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Icon(
                                              Icons.send,
                                              color: Colors.white,
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildComplaintMessage(BuildContext context, Complaint complaint) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.description, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "الشكوى الأصلية",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(complaint.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blueGrey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complaint.description,
                        style: TextStyle(
                          height: 1.4,
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[800],
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
    );
  }

  Widget _buildResponseItem(
    BuildContext context,
    ComplaintResponse response,
    bool isCurrentUser, {
    bool showAvatar = true,
    bool showTime = true,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = response.isAdmin;
    final bubbleColor =
        isCurrentUser
            ? Theme.of(context).primaryColor
            : (isAdmin
                ? Colors.purple
                : (isDarkMode ? Colors.grey[800] : Colors.grey[200]));
    final textColor =
        isCurrentUser || isAdmin
            ? Colors.white
            : (isDarkMode ? Colors.white : Colors.black87);

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
          if (!isCurrentUser && showAvatar)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isAdmin ? Colors.purple : Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

          if (!isCurrentUser && !showAvatar) SizedBox(width: 36),

          if (!isCurrentUser) const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                // Show name and admin badge if needed
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
                        if (!isCurrentUser && isAdmin)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.purple.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Text(
                              'الإدارة',
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),

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
                                        : Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        isCurrentUser
                            ? 16
                            : showAvatar
                            ? 16
                            : 4,
                      ),
                      topRight: Radius.circular(
                        isCurrentUser
                            ? showAvatar
                                ? 16
                                : 4
                            : 16,
                      ),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (response.responseText.isNotEmpty)
                        Text(
                          response.responseText,
                          style: TextStyle(color: textColor, height: 1.4),
                        ),

                      // Display image if there is one
                      if (response.imageUrl != null) ...[
                        if (response.responseText.isNotEmpty)
                          const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            response.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 150,
                                width: 200,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 100,
                                width: 200,
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: const Text(
                                  'تعذر تحميل الصورة',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      if (showTime) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            _formatTime(response.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  isCurrentUser || isAdmin
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isCurrentUser && !showAvatar) SizedBox(width: 36),

          if (isCurrentUser && showAvatar) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateDetailed(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'ar').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm a', 'ar').format(date);
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
}
