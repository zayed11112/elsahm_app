import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart'; // Needed to get UID
import '../constants/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logging/logging.dart';

// Define app bar color to match the wallet screen
const Color appBarBlue = Color(0xFF1976d3);

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger('EditProfileScreen');

  // Define options for dropdowns
  final List<String> _facultyOptions = [
    'حاسبات / تكنولوجيا معلومات (IT)',
    'هندسة (ENG)',
    'أسنان (DENT)',
    'صيدلة (PHARM)',
    'إعلام (MEDIA)',
    'بيزنس (BUS)',
    'علاج طبيعي (PT)',
    'أخرى', // Add an 'Other' option if needed
  ];
  final List<String> _branchOptions = ['فرع العريش', 'فرع القنطرة'];
  final List<String> _statusOptions = [
    'طالب',
    'وسيط',
    'امتياز',
    'صاحب عقار',
    'أخرى',
  ];

  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _batchController;
  late TextEditingController _studentIdController;
  late TextEditingController _phoneNumberController;

  // State variables for dropdowns
  String? _selectedFaculty;
  String? _selectedBranch;
  String? _selectedStatus;
  String _profileImageUrl = '';

  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _nameController = TextEditingController(text: widget.userProfile.name);
    _batchController = TextEditingController(text: widget.userProfile.batch);
    _studentIdController = TextEditingController(
      text: widget.userProfile.studentId,
    );
    _phoneNumberController = TextEditingController(
      text: widget.userProfile.phoneNumber,
    );
    _profileImageUrl = widget.userProfile.avatarUrl;

    // Initialize dropdown values, ensuring they exist in the options list
    _selectedFaculty =
        widget.userProfile.faculty.isNotEmpty &&
                _facultyOptions.contains(widget.userProfile.faculty)
            ? widget.userProfile.faculty
            : null; // Default to null if not found or empty

    _selectedBranch =
        widget.userProfile.branch.isNotEmpty &&
                _branchOptions.contains(widget.userProfile.branch)
            ? widget.userProfile.branch
            : null; // Default to null if not found or empty

    // Initialize status from existing value or default to first option
    _selectedStatus =
        widget.userProfile.status.isNotEmpty &&
                _statusOptions.contains(widget.userProfile.status)
            ? widget.userProfile.status
            : _statusOptions.first; // Default to first option
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _studentIdController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // دالة لاختيار وتحميل صورة جديدة
  void _pickAndUploadImage() async {
    // إضافة تأثير اهتزاز خفيف عند النقر
    HapticFeedback.lightImpact();

    // الحصول على معرف المستخدم الحالي قبل العمليات غير المتزامنة
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ: المستخدم غير مسجل الدخول.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
        ),
      );
      return;
    }
    final uid = authProvider.user!.uid;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // رفع الصورة إلى ImgBB
      final String imageUrl = await _uploadToImgBB(File(image.path));

      // تحقق من أن الويدجت لا يزال مثبتًا قبل استخدام setState و context
      if (!mounted) return;

      // تحديث رابط الصورة في Firestore
      await _firestoreService.updateUserProfileField(uid, {
        'avatarUrl': imageUrl,
      });

      // تحديث حالة الواجهة
      setState(() {
        _profileImageUrl = imageUrl;
      });

      // تحقق مرة أخرى من أن الويدجت لا يزال مثبتًا قبل استخدام context
      if (!mounted) return;
      
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث صورة الملف الشخصي بنجاح',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.fixed,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
        ),
      );
    } catch (e) {
      // تحقق من أن الويدجت لا يزال مثبتًا قبل استخدام context
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء تحديث الصورة',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
        ),
      );
    } finally {
      // تحديث حالة التحميل فقط إذا كان الويدجت لا يزال مثبتًا
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // دالة مساعدة لرفع الصورة إلى ImgBB
  Future<String> _uploadToImgBB(File imageFile) async {
    const String apiKey =
        '9acda31c4576aa648bc36802829b3b9d'; // استخدام نفس مفتاح API
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return jsonData['data']['url'];
      } else {
        _logger.warning('ImgBB upload failed. Trying fallback method...');
        // If ImgBB fails, try the fallback method
        return _uploadToFreeImage(imageFile);
      }
    } catch (e) {
      _logger.warning('Error during ImgBB upload: $e');
      // If there's an exception, try the fallback method
      return _uploadToFreeImage(imageFile);
    }
  }

  // دالة بديلة لرفع الصورة باستخدام Freeimage.host
  Future<String> _uploadToFreeImage(File imageFile) async {
    const String apiKey =
        '6d207e02198a847aa98d0a2a901485a5'; // مفتاح API الخاص بـ Freeimage.host
    final uri = Uri.parse('https://freeimage.host/api/1/upload?key=$apiKey');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('source', imageFile.path),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonData = json.decode(responseData);

    if (response.statusCode == 200 && jsonData['status_code'] == 200) {
      return jsonData['image']['url'];
    } else {
      throw Exception(
        'فشل رفع الصورة: ${jsonData['status_txt'] ?? 'خطأ غير معروف'}',
      );
    }
  }

  // عرض صورة الملف الشخصي في وضع العرض الكامل
  void _viewProfileImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return; // Don't show anything if there's no image

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full screen image with interactive viewer for zooming
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: GestureDetector(
                  onTap:
                      () =>
                          Navigator.of(
                            context,
                          ).pop(), // Tap background to close
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withAlpha(204),
                    child: Center(
                      child: Hero(
                        tag: 'profile_image_view',
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "فشل تحميل الصورة",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Close button positioned at the top
              Positioned(
                top: 30,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 26,
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Also validate dropdowns manually if needed (e.g., ensure a selection is made)
      if (_selectedFaculty == null ||
          _selectedBranch == null ||
          _selectedStatus == null) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'الرجاء إكمال جميع الحقول الإلزامية',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // الحصول على معلومات المستخدم قبل العمليات غير المتزامنة
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user?.uid;

      if (uid == null) {
        // Check if the widget is still mounted before using context
        if (!mounted) return;

        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: المستخدم غير مسجل الدخول.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Prepare updated data map using selected dropdown values
      final updatedData = {
        'name': _nameController.text.trim(),
        'faculty': _selectedFaculty, // Use selected value
        'branch': _selectedBranch, // Use selected value
        'batch': _batchController.text.trim(),
        'status': _selectedStatus, // Use selected status
        'studentId': _studentIdController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
      };

      try {
        // حفظ البيانات في Firestore
        await _firestoreService.updateUserProfileField(uid, updatedData);

        // تحقق من أن الويدجت لا يزال مثبتًا
        if (!mounted) return;

        // عرض رسالة نجاح وإغلاق الشاشة
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ التغييرات بنجاح!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
        );

        // Add a small delay to show the success message before popping
        await Future.delayed(const Duration(milliseconds: 800));

        // Use Navigator.pop with animated page transition
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        _logger.severe("Error saving profile: $e");

        // تحقق من أن الويدجت لا يزال مثبتًا
        if (!mounted) return;

        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'فشل حفظ التغييرات',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
        );
      } finally {
        // تحديث حالة التحميل فقط إذا كان الويدجت لا يزال مثبتًا
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors based on theme
    final backgroundColor = isDarkMode ? darkBackground : Colors.grey[100];
    final cardColor = isDarkMode ? darkCard : Colors.white;
    final textPrimaryColor = isDarkMode ? darkTextPrimary : Colors.black87;
    final iconColor = isDarkMode ? skyBlue : const Color(0xFF1976d3);
    final cardBorderColor = isDarkMode ? darkCardColor : Colors.transparent;
    final accentColor = const Color(0xFF1976d3);
    final sectionHeaderBgColor =
        isDarkMode ? darkSurface : const Color(0xFFE3F2FD);

    return WillPopScope(
      onWillPop: () async {
        // Custom back navigation with page transition
        Navigator.of(context).pop();
        return false; // We handled the back button
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1976d3),
          title: const Text(
            'تعديل الملف الشخصي',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              onPressed: _isLoading ? null : _saveProfile,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionCard(
                      title: 'المعلومات الشخصية',
                      icon: Icons.person,
                      isDarkMode: isDarkMode,
                      cardColor: cardColor,
                      textColor: textPrimaryColor,
                      iconColor: iconColor,
                      headerBgColor: sectionHeaderBgColor,
                      borderColor: cardBorderColor,
                      children: [
                        _buildProfileImageSection(isDarkMode, iconColor),
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? darkSurface
                                      : const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accentColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "انقر علي أيقونة الكاميرا لتغيير الصورة",
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildPersonalInfoFields(
                          isDarkMode,
                          textPrimaryColor,
                          iconColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Academic Information Section
                    _buildSectionCard(
                      title: 'المعلومات الأكاديمية',
                      icon: Icons.school,
                      isDarkMode: isDarkMode,
                      cardColor: cardColor,
                      textColor: textPrimaryColor,
                      iconColor: iconColor,
                      headerBgColor: sectionHeaderBgColor,
                      borderColor: cardBorderColor,
                      children: [
                        _buildAcademicInfoFields(
                          isDarkMode,
                          textPrimaryColor,
                          iconColor,
                        ),
                      ],
                    ),

                    // Save Button at bottom
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: accentColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "جاري الحفظ...",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.save, size: 22),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'حفظ التغييرات',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required Color cardColor,
    required Color textColor,
    required Color iconColor,
    required Color headerBgColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(bool isDarkMode, Color iconColor) {
    final bgColor = isDarkMode ? darkSurface : Colors.grey.shade50;

    return Center(
      child: Stack(
        children: [
          // Profile image
          GestureDetector(
            onTap: () => _viewProfileImage(context, _profileImageUrl),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Hero(
                    tag: 'profile_image',
                    flightShuttleBuilder: (
                      BuildContext flightContext,
                      Animation<double> animation,
                      HeroFlightDirection flightDirection,
                      BuildContext fromHeroContext,
                      BuildContext toHeroContext,
                    ) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    0.2 * animation.value,
                                  ),
                                  blurRadius: 12 * animation.value,
                                  spreadRadius: 2 * animation.value,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  _profileImageUrl.isNotEmpty
                                      ? Image.network(
                                        _profileImageUrl,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      )
                                      : Container(
                                        width: 120,
                                        height: 120,
                                        color: bgColor,
                                        child: Icon(
                                          Icons.account_circle,
                                          size: 80,
                                          color:
                                              isDarkMode
                                                  ? darkTextSecondary
                                                  : Colors.black87.withAlpha(
                                                    179,
                                                  ),
                                        ),
                                      ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? darkCardColor : Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDarkMode ? 40 : 26),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child:
                          _isUploadingImage
                              ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    iconColor,
                                  ),
                                ),
                              )
                              : ClipOval(
                                child:
                                    _profileImageUrl.isNotEmpty
                                        ? Image.network(
                                          _profileImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Icon(
                                              Icons.account_circle,
                                              size: 80,
                                              color:
                                                  isDarkMode
                                                      ? darkTextSecondary
                                                      : Colors.black87
                                                          .withAlpha(179),
                                            );
                                          },
                                        )
                                        : Icon(
                                          Icons.account_circle,
                                          size: 80,
                                          color:
                                              isDarkMode
                                                  ? darkTextSecondary
                                                  : Colors.black87.withAlpha(
                                                    179,
                                                  ),
                                        ),
                              ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Camera icon overlay with animation
          Positioned(
            bottom: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: GestureDetector(
                onTap: _pickAndUploadImage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoFields(
    bool isDarkMode,
    Color textColor,
    Color iconColor,
  ) {
    final fieldBgColor = isDarkMode ? darkSurface : Colors.grey.shade50;
    final borderColor = isDarkMode ? darkCardColor : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // حقول المعلومات الشخصية
        _buildTextFormField(
          controller: _nameController,
          labelText: 'الاسم الكامل',
          icon: Icons.person_outline,
          isDarkMode: isDarkMode,
          fieldBgColor: fieldBgColor,
          borderColor: borderColor,
          textColor: textColor,
          labelColor: textColor,
          iconColor: iconColor,
          maxLength: 40,
          validator:
              (value) =>
                  (value == null || value.isEmpty)
                      ? 'الرجاء إدخال الاسم'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownFormField(
          value: _selectedStatus,
          items: _statusOptions,
          labelText: 'الحالة',
          hint: 'اختر الحالة',
          icon: Icons.verified_user_outlined,
          isDarkMode: isDarkMode,
          fieldBgColor: fieldBgColor,
          borderColor: borderColor,
          textColor: textColor,
          labelColor: textColor,
          iconColor: iconColor,
          onChanged: (value) => setState(() => _selectedStatus = value),
          validator: (value) => (value == null) ? 'الرجاء اختيار الحالة' : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _studentIdController,
          labelText: '(ID) الرقم التعريفي  ',
          icon: Icons.badge_outlined,
          isDarkMode: isDarkMode,
          fieldBgColor: fieldBgColor,
          borderColor: borderColor,
          textColor: textColor,
          labelColor: textColor,
          iconColor: iconColor,
          keyboardType: TextInputType.text,
          maxLength: 15,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _phoneNumberController,
          labelText: 'رقم الهاتف',
          icon: Icons.phone_outlined,
          isDarkMode: isDarkMode,
          fieldBgColor: fieldBgColor,
          borderColor: borderColor,
          textColor: textColor,
          labelColor: textColor,
          iconColor: iconColor,
          keyboardType: TextInputType.phone,
          maxLength: 15,
        ),
      ],
    );
  }

  Widget _buildAcademicInfoFields(
    bool isDarkMode,
    Color textColor,
    Color iconColor,
  ) {
    final fieldBgColor = isDarkMode ? darkSurface : Colors.grey.shade50;
    final borderColor = isDarkMode ? darkCardColor : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Faculty Dropdown
        _buildDropdownFormField(
          value: _selectedFaculty,
          items: _facultyOptions,
          labelText: 'الكلية',
          hint: 'اختر الكلية',
          icon: Icons.school_outlined,
          isDarkMode: isDarkMode,
          fieldBgColor: fieldBgColor,
          borderColor: borderColor,
          textColor: textColor,
          labelColor: textColor,
          iconColor: iconColor,
          onChanged: (value) => setState(() => _selectedFaculty = value),
          validator: (value) => (value == null) ? 'الرجاء اختيار الكلية' : null,
        ),
        const SizedBox(height: 16),

        // Branch Dropdown
        _buildDropdownFormField(
          value: _selectedBranch,
          items: _branchOptions,
          labelText: 'الفرع',
          hint: 'اختر الفرع',
          icon: Icons.location_city_outlined,
          isDarkMode: isDarkMode,
          fieldBgColor: fieldBgColor,
          borderColor: borderColor,
          textColor: textColor,
          labelColor: textColor,
          iconColor: iconColor,
          onChanged: (value) => setState(() => _selectedBranch = value),
          validator: (value) => (value == null) ? 'الرجاء اختيار الفرع' : null,
        ),
        const SizedBox(height: 16),

        _buildTextFormField(
          controller: _batchController,
          labelText: 'الدفعة',
          icon: Icons.calendar_today_outlined,
          isDarkMode: isDarkMode,
          fieldBgColor: fieldBgColor,
          borderColor: borderColor,
          textColor: textColor,
          labelColor: textColor,
          iconColor: iconColor,
          keyboardType: TextInputType.number,
          maxLength: 15,
          validator:
              (value) =>
                  (value == null || value.isEmpty)
                      ? 'الرجاء إدخال الدفعة'
                      : null,
        ),
      ],
    );
  }

  // Helper for TextFormFields (Improved Styling)
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required bool isDarkMode,
    required Color fieldBgColor,
    required Color borderColor,
    required Color textColor,
    required Color labelColor,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode ? darkCard : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(color: labelColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: iconColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              filled: true,
              fillColor: fieldBgColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              counterText: maxLength != null ? '' : null,
            ),
            maxLength: maxLength,
            keyboardType: keyboardType,
            validator: validator,
            enabled: !_isLoading,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );
  }

  // Helper for DropdownButtonFormFields (Improved Styling)
  Widget _buildDropdownFormField({
    required String? value,
    required List<String> items,
    required String labelText,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    required Color fieldBgColor,
    required Color borderColor,
    required Color textColor,
    required Color labelColor,
    required Color iconColor,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode ? darkCard : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
            onChanged: _isLoading ? null : onChanged,
            validator: validator,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(color: labelColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: iconColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              filled: true,
              fillColor: fieldBgColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            dropdownColor: isDarkMode ? darkCard : Colors.white,
            isExpanded: true,
            style: TextStyle(color: textColor),
            hint: Text(hint, style: TextStyle(color: textColor.withAlpha(179))),
            icon: Icon(Icons.arrow_drop_down, color: iconColor),
          ),
        ),
      ],
    );
  }
}
