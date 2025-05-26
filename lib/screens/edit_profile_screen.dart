import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart'; // Needed to get UID
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logging/logging.dart';

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
    _studentIdController = TextEditingController(text: widget.userProfile.studentId);
    _profileImageUrl = widget.userProfile.avatarUrl;

    // Initialize dropdown values, ensuring they exist in the options list
    _selectedFaculty = widget.userProfile.faculty.isNotEmpty && _facultyOptions.contains(widget.userProfile.faculty)
        ? widget.userProfile.faculty
        : null; // Default to null if not found or empty

    _selectedBranch = widget.userProfile.branch.isNotEmpty && _branchOptions.contains(widget.userProfile.branch)
        ? widget.userProfile.branch
        : null; // Default to null if not found or empty
        
    // Initialize status from existing value or default to first option
    _selectedStatus = widget.userProfile.status.isNotEmpty && _statusOptions.contains(widget.userProfile.status)
        ? widget.userProfile.status
        : _statusOptions.first; // Default to first option
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _studentIdController.dispose();
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
        const SnackBar(
          content: Text('خطأ: المستخدم غير مسجل الدخول.'),
          backgroundColor: Colors.red,
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
      await _firestoreService.updateUserProfileField(
        uid,
        {'avatarUrl': imageUrl},
      );

      // تحديث حالة الواجهة
      setState(() {
        _profileImageUrl = imageUrl;
      });

      // تحقق مرة أخرى من أن الويدجت لا يزال مثبتًا قبل استخدام context
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('تم تحديث صورة الملف الشخصي بنجاح'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      // تحقق من أن الويدجت لا يزال مثبتًا قبل استخدام context
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث الصورة: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
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
    const String apiKey = '9acda31c4576aa648bc36802829b3b9d'; // استخدام نفس مفتاح API
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

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
    const String apiKey = '6d207e02198a847aa98d0a2a901485a5'; // مفتاح API الخاص بـ Freeimage.host
    final uri = Uri.parse('https://freeimage.host/api/1/upload?key=$apiKey');
    
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('source', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonData = json.decode(responseData);

    if (response.statusCode == 200 && jsonData['status_code'] == 200) {
      return jsonData['image']['url'];
    } else {
      throw Exception('فشل رفع الصورة: ${jsonData['status_txt'] ?? 'خطأ غير معروف'}');
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
                  onTap: () => Navigator.of(context).pop(), // Tap background to close
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withAlpha(204),
                    child: Center(
                      child: Hero(
                        tag: 'profileImage',
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error, color: Colors.white, size: 40),
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
                    icon: const Icon(Icons.close, color: Colors.white, size: 26),
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
       if (_selectedFaculty == null || _selectedBranch == null || _selectedStatus == null) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('الرجاء إكمال جميع الحقول الإلزامية'),
             backgroundColor: Colors.orange,
           ),
         );
         return;
       }

      setState(() { _isLoading = true; });

      // الحصول على معلومات المستخدم قبل العمليات غير المتزامنة
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user?.uid;

      if (uid == null) {
         // Check if the widget is still mounted before using context
         if (!mounted) return;
         
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('خطأ: المستخدم غير مسجل الدخول.'), backgroundColor: Colors.red),
         );
         setState(() { _isLoading = false; });
         return;
      }

      // Prepare updated data map using selected dropdown values
      final updatedData = {
        'name': _nameController.text.trim(),
        'faculty': _selectedFaculty, // Use selected value
        'branch': _selectedBranch,   // Use selected value
        'batch': _batchController.text.trim(),
        'status': _selectedStatus,   // Use selected status
        'studentId': _studentIdController.text.trim(),
      };

      try {
        // حفظ البيانات في Firestore
        await _firestoreService.updateUserProfileField(uid, updatedData);
        
        // تحقق من أن الويدجت لا يزال مثبتًا
        if (!mounted) return;
        
        // عرض رسالة نجاح وإغلاق الشاشة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التغييرات بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
         _logger.severe("Error saving profile: $e");
         
         // تحقق من أن الويدجت لا يزال مثبتًا
         if (!mounted) return;
         
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('فشل حفظ التغييرات: $e'), backgroundColor: Colors.red),
         );
      } finally {
         // تحديث حالة التحميل فقط إذا كان الويدجت لا يزال مثبتًا
         if (mounted) {
           setState(() { _isLoading = false; });
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // أزيل المتغير المحلي غير المستخدم final theme = Theme.of(context);
    // Define colors for better design
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    
    // اكتشاف ما إذا كان الوضع الليلي مفعلا
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // ألوان متكيفة بناءً على وضع الشاشة
    final Color backgroundColor = isDarkMode ? const Color(0xFF121212) : Theme.of(context).scaffoldBackgroundColor;
    final Color cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color fieldBgColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    final Color borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final Color labelColor = isDarkMode ? Colors.blue.shade200 : primaryColor;
    final Color iconColor = isDarkMode ? Colors.blue.shade200 : primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'تعديل الملف الشخصي',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : null,
        flexibleSpace: !isDarkMode ? Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, accentColor],
            ),
          ),
        ) : null,
        actions: [
          IconButton(
            icon: _isLoading 
                ? const Text(
                    "ثانية واحدة",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            tooltip: 'حفظ',
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
                  // Profile section header
                  _buildSectionHeader(
                    title: 'المعلومات الشخصية',
                    icon: Icons.person,
                    color: labelColor,
                  ),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    color: cardBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.transparent,
                        width: isDarkMode ? 1 : 0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // صورة المستخدم في الأعلى
                          Center(
                            child: Stack(
                              children: [
                                // صورة المستخدم
                                GestureDetector(
                                  onTap: () => _viewProfileImage(context, _profileImageUrl),
                                  child: Hero(
                                    tag: 'profileImage',
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: fieldBgColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _isUploadingImage ? labelColor : borderColor,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(26),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: _isUploadingImage
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(labelColor),
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(7),
                                            child: _profileImageUrl.isNotEmpty
                                              ? Image.network(
                                                  _profileImageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.account_circle,
                                                      size: 80,
                                                      color: iconColor.withAlpha(179),
                                                    );
                                                  },
                                                )
                                              : Icon(
                                                  Icons.account_circle,
                                                  size: 80,
                                                  color: iconColor.withAlpha(179),
                                                ),
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // زر تغيير الصورة
                          ElevatedButton.icon(
                            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                            icon: Icon(Icons.camera_alt, size: 16),
                            label: Text("تغيير الصورة"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode ? Colors.blue.shade600 : primaryColor,
                              foregroundColor: Colors.white,
                              textStyle: TextStyle(fontSize: 14),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          
                          // نص توضيحي
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "انقر على الزر لتغيير الصورة الشخصية",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // حقول المعلومات الشخصية
                          _buildTextFormField(
                            controller: _nameController,
                            labelText: 'الاسم الكامل',
                            icon: Icons.person_outline,
                            isDarkMode: isDarkMode,
                            fieldBgColor: fieldBgColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            labelColor: labelColor,
                            iconColor: iconColor,
                            maxLength: 40,
                            validator: (value) => (value == null || value.isEmpty) 
                                ? 'الرجاء إدخال الاسم' : null,
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
                            labelColor: labelColor,
                            iconColor: iconColor,
                            onChanged: (value) => setState(() => _selectedStatus = value),
                            validator: (value) => (value == null) ? 'الرجاء اختيار الحالة' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _studentIdController,
                            labelText: 'الرقم التعريفي',
                            icon: Icons.badge_outlined,
                            isDarkMode: isDarkMode,
                            fieldBgColor: fieldBgColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            labelColor: labelColor,
                            iconColor: iconColor,
                            keyboardType: TextInputType.text,
                            maxLength: 15,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Academic section header
                  _buildSectionHeader(
                    title: 'المعلومات الأكاديمية',
                    icon: Icons.school,
                    color: labelColor,
                  ),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    color: cardBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.transparent,
                        width: isDarkMode ? 1 : 0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
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
                            labelColor: labelColor,
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
                            labelColor: labelColor,
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
                            labelColor: labelColor,
                            iconColor: iconColor,
                            keyboardType: TextInputType.number,
                            maxLength: 15,
                            validator: (value) => (value == null || value.isEmpty) 
                                ? 'الرجاء إدخال الدفعة' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Save button at the bottom
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.blue.shade600 : primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const Text(
                              "ثانية واحدة",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'حفظ التغييرات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title, 
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        children: [
          Icon(
            icon, 
            color: color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: labelColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDarkMode ? Colors.red.shade300 : Colors.red.shade300),
        ),
        filled: true,
        fillColor: fieldBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: maxLength != null ? '' : null,
      ),
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      enabled: !_isLoading,
      style: TextStyle(color: textColor),
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
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
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
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: labelColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDarkMode ? Colors.red.shade300 : Colors.red.shade300),
        ),
        filled: true,
        fillColor: fieldBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Theme.of(context).cardColor,
      isExpanded: true,
      style: TextStyle(color: textColor),
      hint: Text(hint, style: TextStyle(color: textColor.withAlpha(179))),
      icon: Icon(Icons.arrow_drop_down, color: iconColor),
    );
  }
}
