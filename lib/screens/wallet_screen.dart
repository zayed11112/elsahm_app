import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:provider/provider.dart'; // إضافة Provider
import '../models/user_profile.dart'; // إضافة نموذج UserProfile
import '../models/payment_method.dart'; // إضافة نموذج طرق الدفع
import '../services/firestore_service.dart'; // إضافة FirestoreService
import '../services/supabase_service.dart'; // إضافة SupabaseService
import '../services/payment_methods_service.dart'; // إضافة خدمة طرق الدفع
import '../providers/auth_provider.dart'; // إضافة AuthProvider
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import './payment_requests_screen.dart'; // استيراد صفحة طلبات الدفع
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';

// Re-export the theme constants for backward compatibility
// Using different variable names to avoid self-reference
const Color primarySkyBlue = Color(0xFF4FC3F7);
const Color accentBlue = Color(0xFF29B6F6);

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _universityIdController = TextEditingController();
  final TextEditingController _sourcePhoneController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();
  // استخدام مزود خدمة Supabase العام
  final SupabaseService _supabaseService = SupabaseService();

  String? _selectedPredefinedAmount;
  String? _selectedPaymentMethod;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;
  File? _imageFile;

  // طرق الدفع المتاحة
  final PaymentMethodsService _paymentMethodsService = PaymentMethodsService();
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoadingPaymentMethods = true;

  @override
  void initState() {
    super.initState();
    // تعبئة اسم المستخدم من الملف الشخصي إذا كان متاحاً
    _fillUserDetails();
    // تحميل طرق الدفع المتاحة من قاعدة البيانات
    _loadPaymentMethods();
  }

  // تحميل طرق الدفع من قاعدة البيانات
  Future<void> _loadPaymentMethods() async {
    try {
      setState(() {
        _isLoadingPaymentMethods = true;
      });

      final methods = await _paymentMethodsService.getPaymentMethods();

      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _isLoadingPaymentMethods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPaymentMethods = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في تحميل طرق الدفع: $e',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fillUserDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      final userProfile = await _firestoreService.getUserProfile(userId);
      if (userProfile != null && mounted) {
        setState(() {
          _nameController.text = userProfile.name;
          _universityIdController.text = userProfile.studentId;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _universityIdController.dispose();
    _sourcePhoneController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _selectPredefinedAmount(String amount) {
    setState(() {
      _amountController.text = amount;
      _selectedPredefinedAmount = amount;
      _amountFocusNode.unfocus();
    });
  }

  void _onAmountChanged(String value) {
    if (_selectedPredefinedAmount != null &&
        value != _selectedPredefinedAmount) {
      setState(() {
        _selectedPredefinedAmount = null;
      });
    }
  }

  void _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _imageFile = File(image.path);
        _uploadedImageUrl =
            null; // Reset the uploaded URL when a new image is picked
      });

      // Upload the image immediately
      _uploadImage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في اختيار الصورة: $e',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Try uploading with ImgBB first
      try {
        final String imageUrl = await _uploadToImgBB(_imageFile!);

        setState(() {
          _uploadedImageUrl = imageUrl;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم رفع الصورة بنجاح',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (imgbbError) {
        // If ImgBB fails, try with Freeimage.host as fallback
        try {
          final String imageUrl = await _uploadToFreeImage(_imageFile!);

          setState(() {
            _uploadedImageUrl = imageUrl;
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم رفع الصورة بنجاح (باستخدام الخادم البديل)',
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (freeimageError) {
          throw Exception('فشل في رفع الصورة على كلا الخادمين: $imgbbError، $freeimageError');
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في رفع الصورة: $e',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _uploadToImgBB(File imageFile) async {
    const String apiKey = '9acda31c4576aa648bc36802829b3b9d';
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonData = json.decode(responseData);

    if (response.statusCode == 200 && jsonData['success'] == true) {
      return jsonData['data']['url'];
    } else {
      throw Exception(
        'فشل في رفع الصورة: ${jsonData['error']?.toString() ?? 'خطأ غير معروف'}',
      );
    }
  }

  // طريقة الرفع البديلة باستخدام Freeimage.host API
  Future<String> _uploadToFreeImage(File imageFile) async {
    const String apiKey = '6d207e02198a847aa98d0a2a901485a5';
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
        'فشل في رفع الصورة: ${jsonData['status_txt'] ?? 'خطأ غير معروف'}',
      );
    }
  }

  Future<void> _submitRequest() async {
    // التحقق من اختيار طريقة دفع
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار طريقة دفع أولاً',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التحقق من إدخال المبلغ المراد شحنه
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال المبلغ المراد شحنه',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التحقق من إدخال رقم الهاتف أو اسم المستخدم
    if (_sourcePhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedPaymentMethod == 'إنستا باي'
                ? 'يرجى إدخال اسم المستخدم على إنستا باي'
                : 'يرجى إدخال الرقم الذي حولت منه',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // التحقق من رفع صورة التحويل
    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى رفع صورة إثبات التحويل',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // التحقق من باقي البيانات المطلوبة
    if (_nameController.text.isEmpty ||
        _universityIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إكمال جميع البيانات المطلوبة',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التحقق من صحة صيغة الإدخال حسب طريقة الدفع
    final String? validationError = _validateSourceField(
      _sourcePhoneController.text,
    );
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validationError,
            textAlign: TextAlign.center,
          ), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // الحصول على معرف المستخدم الحالي
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // الحصول على بيانات المستخدم الكاملة
      final userProfile = await _firestoreService.getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('لم يتم العثور على بيانات المستخدم');
      }

      // تنسيق اسم المستخدم على انستا باي باي إذا كانت طريقة الدفع هي إنستا باي
      String sourcePhoneOrUsername = _sourcePhoneController.text.trim();
      if (_selectedPaymentMethod == 'إنستا باي') {
        sourcePhoneOrUsername = _formatInstaPayUsername(sourcePhoneOrUsername);
      }

      // إعداد بيانات الطلب للحفظ في Supabase
      final Map<String, dynamic> requestData = {
        'userId': userId,
        'userName': _nameController.text.trim(),
        'userEmail': userProfile.email,
        'universityId': _universityIdController.text.trim(),
        'amount': double.parse(_amountController.text),
        'paymentMethod': _selectedPaymentMethod,
        'sourcePhone': sourcePhoneOrUsername,
        'paymentProofUrl': _uploadedImageUrl,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'faculty': userProfile.faculty,
        'branch': userProfile.branch,
        'currentBalance': userProfile.balance,
      };

      // حفظ البيانات في Supabase وFirebase (للتوافق الخلفي)
      final bool success = await _supabaseService.addPaymentRequest(
        requestData,
      );
      final String requestId = await _firestoreService.addWalletChargeRequest(
        requestData,
      );

      if (!success) {
        throw Exception('فشل في إرسال الطلب إلى Supabase');
      }

      if (mounted) {
        // إظهار رسالة شكر احترافية بدلاً من مجرد رسالة تأكيد
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final bgColor = isDarkMode 
                ? const Color(0xFF1F2937)  // Dark blue-gray for dark mode
                : LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                  );
            final textColor = isDarkMode 
                ? Colors.white 
                : const Color(0xFF2D3142);
            final subtextColor = isDarkMode 
                ? Colors.white70 
                : Colors.grey.shade700;
            final receiptBgColor = isDarkMode 
                ? Colors.grey.shade800 
                : Colors.grey.shade200;
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isDarkMode 
                      ? null 
                      : LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                        ),
                  color: isDarkMode ? const Color(0xFF1F2937) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF2D3748) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primarySkyBlue.withOpacity(isDarkMode ? 0.2 : 0.3),
                            spreadRadius: 2,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: primarySkyBlue,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "شكراً لك!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "تم استلام طلب الشحن الخاص بك بنجاح",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "سيتم مراجعة طلبك من فريق شركة السهم",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "سيتم إرسال إشعار لك عند التحقق من الدفع",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: receiptBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt,
                            size: 18,
                            color: primarySkyBlue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "رقم الطلب: $requestId",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primarySkyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();

                          // التوجه إلى صفحة طلبات الدفع بعد الإغلاق
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder:
                                  (context) => const PaymentRequestsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "متابعة طلباتي",
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
            );
          },
        );

        // إعادة تعيين النموذج
        setState(() {
          _amountController.clear();
          _universityIdController.clear();
          _sourcePhoneController.clear();
          _selectedPredefinedAmount = null;
          _selectedPaymentMethod = null;
          _uploadedImageUrl = null;
          _imageFile = null;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في إرسال الطلب: $e',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // التحقق من صحة رقم المصدر بناءً على طريقة الدفع المختارة
  String? _validateSourceField(String? value) {
    if (value == null || value.isEmpty) {
      return 'هذا الحقل مطلوب';
    }

    if (_selectedPaymentMethod == 'إنستا باي') {
      // تم تعديله للتحقق فقط من أن الاسم موجود، سنقوم بإضافة @instapay لاحقًا
      if (value.trim().isEmpty) {
        return 'يجب إدخال اسم المستخدم';
      }
    }

    return null;
  }

  // دالة جديدة لإضافة @instapay للاسم في حال لم تكن موجودة
  String _formatInstaPayUsername(String username) {
    username = username.trim();
    // إذا كان الاسم لا يحتوي على @instapay، نقوم بإضافته
    if (!username.endsWith('@instapay')) {
      // إزالة أي @ قد تكون في بداية الاسم
      if (username.startsWith('@')) {
        username = username.substring(1);
      }
      // التأكد من عدم وجود @instapay في وسط النص
      if (username.contains('@instapay')) {
        username = username.replaceAll('@instapay', '');
      }
      username = '$username@instapay';
    }
    return username;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    final shadowColor = isDarkMode ? Colors.black54 : Colors.black12;

    return Scaffold(
      appBar: AppBar(
        title: const Text('شحن المحفظة'),
        centerTitle: true,
        backgroundColor: primarySkyBlue,
        foregroundColor: Colors.white,
        elevation: 2.0,
      ),
      body: Column(
        children: [
          // Main content in scrollable area
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Current Balance Card
                    _buildBalanceCard(cardBgColor, textColor),
                    const SizedBox(height: 25),

                    // Payment Methods Title
                    Center(
                      child: Text(
                        'اختر طريقة الدفع المناسبة ليك',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Payment Methods Section
                    _buildSectionHeader('طرق الدفع المتاحة', Icons.payments),
                    const SizedBox(height: 10),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: cardBgColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child:
                            _isLoadingPaymentMethods
                                ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                                : _paymentMethods.isEmpty
                                ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.payment_outlined,
                                          size: 48,
                                          color: Colors.grey.withAlpha(150),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'لا توجد طرق دفع متاحة حالياً',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : Column(
                                  children:
                                      _paymentMethods
                                          .map(
                                            (method) => _buildPaymentMethodItem(
                                              method.name,
                                              method.paymentIdentifier,
                                              isDarkMode,
                                              method.name == _selectedPaymentMethod,
                                              () => setState(
                                                () =>
                                                    _selectedPaymentMethod =
                                                        method.name,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // رسالة تنبيه للمستخدم
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'قم بالتحويل على إحدى طرق الدفع أعلاه ثم أدخل بياناتك واختر صورة إيصال التحويل',
                              style: TextStyle(
                                color: isDarkMode ? Colors.amber.shade200 : Colors.amber.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Amount Input Section
                    _buildSectionHeader(
                      'المبلغ اللي شحنته',
                      Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 10),

                    // Center and constrain the TextField
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: TextField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            LengthLimitingTextInputFormatter(25), // Limit to 25 digits
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            labelText: 'المبلغ (بالجنيه)',
                            prefixIcon: Icon(
                              Icons.monetization_on,
                              color: primarySkyBlue.withOpacity(0.7),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: primarySkyBlue,
                                width: 2.0,
                              ),
                            ),
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: _onAmountChanged,
                          enabled: !_isSubmitting,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Predefined Amounts
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      alignment: WrapAlignment.center,
                      children:
                          ['1000', '2000', '4000', '6000']
                              .map((amount) => _buildPredefinedAmountButton(amount))
                              .toList(),
                    ),

                    const SizedBox(height: 25),

                    // User Info Section
                    _buildSectionHeader('ادخل بياناتك ', Icons.person),
                    const SizedBox(height: 10),

                    // اسم المستخدم
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'الاسم داخل التطبيق',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: primarySkyBlue.withOpacity(0.7),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: primarySkyBlue,
                                width: 2.0,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(40), // Limit to 40 characters
                          ],
                          textAlign: TextAlign.center,
                          enabled: !_isSubmitting,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // الرقم الجامعي
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: TextField(
                          controller: _universityIdController,
                          decoration: InputDecoration(
                            labelText: 'الرقم الجامعي',
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              color: primarySkyBlue.withOpacity(0.7),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: primarySkyBlue,
                                width: 2.0,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25), // Limit to 25 digits
                          ],
                          textAlign: TextAlign.center,
                          enabled: !_isSubmitting,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // الرقم الذي حوّلت منه
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: TextField(
                          controller: _sourcePhoneController,
                          decoration: InputDecoration(
                            labelText:
                                _selectedPaymentMethod == 'إنستا باي'
                                    ? 'اسم المستخدم على انستا باي'
                                    : 'الرقم الذي حوّلت منه',
                            hintText:
                                _selectedPaymentMethod == 'إنستا باي'
                                    ? 'فقط اكتب اسمك (سنضيف @instapay تلقائيًا)'
                                    : 'مثال: 01xxxxxxxxx',
                            suffixText:
                                _selectedPaymentMethod == 'إنستا باي'
                                    ? '@instapay'
                                    : null,
                            suffixStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primarySkyBlue,
                            ),
                            prefixIcon: Icon(
                              _selectedPaymentMethod == 'إنستا باي'
                                  ? Icons.alternate_email
                                  : Icons.phone,
                              color: primarySkyBlue.withOpacity(0.7),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: primarySkyBlue,
                                width: 2.0,
                              ),
                            ),
                          ),
                          textAlign: TextAlign.center,
                          keyboardType:
                              _selectedPaymentMethod == 'إنستا باي'
                                  ? TextInputType.text
                                  : TextInputType.phone,
                          inputFormatters:
                              _selectedPaymentMethod == 'إنستا باي'
                                  ? [
                                    // منع المستخدم من إدخال @
                                    FilteringTextInputFormatter.deny(RegExp(r'@')),
                                    LengthLimitingTextInputFormatter(25), // Limit to 25 characters
                                  ]
                                  : [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(25), // Update limit to 25 digits
                                  ],
                          enabled: !_isSubmitting,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Payment Proof Upload Section
                    _buildSectionHeader('إثبات التحويل', Icons.image),
                    const SizedBox(height: 10),

                    // صورة إثبات التحويل
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: cardBgColor,
                          child: InkWell(
                            onTap: _isSubmitting ? null : _pickImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      _uploadedImageUrl != null
                                          ? Colors.green.withOpacity(0.5)
                                          : Colors.grey.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: _isUploading
                                  ? const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            color: primarySkyBlue,
                                          ),
                                          SizedBox(height: 10),
                                          Text('جاري رفع الصورة...'),
                                        ],
                                      ),
                                    )
                                  : _imageFile != null
                                      ? Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(11),
                                              child: Image.file(
                                                _imageFile!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            ),
                                            if (_uploadedImageUrl != null)
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.8),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'تم الرفع',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.upload_file,
                                              size: 48,
                                              color: primarySkyBlue.withOpacity(0.7),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'انقر لرفع صورة إثبات التحويل',
                                              style: TextStyle(color: textColor),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '(سكرين شوت أو صورة إيصال)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textColor.withOpacity(0.7),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Verification note
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primarySkyBlue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: primarySkyBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'سيتم التحقق من التحويل وسيتم إرسال إشعار لك إذا كان التحويل صحيح',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Additional padding at the bottom to ensure space for the fixed button
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
          ),
          
          // Fixed button at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isSubmitting ? 'جاري الإرسال...' : 'إرسال الطلب',
                      ),
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: shadowColor,
                      ),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primarySkyBlue, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primarySkyBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(
    String name,
    String details,
    bool isDarkMode,
    bool isSelected,
    VoidCallback onTap,
  ) {
    // البحث عن طريقة الدفع في القائمة للحصول على الصورة
    final paymentMethod = _paymentMethods.firstWhere(
      (method) => method.name == name,
      orElse: () => PaymentMethod(
        id: '',
        name: name,
        paymentIdentifier: details,
        isActive: true,
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // استخدام صورة طريقة الدفع من قاعدة البيانات أو استخدام صورة افتراضية
    final String? imageUrl = paymentMethod.imageUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? primarySkyBlue.withAlpha(25) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primarySkyBlue : Colors.grey.withAlpha(76),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: primarySkyBlue)
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primarySkyBlue,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          name.contains('فودافون') ? Icons.phone_android : Icons.account_balance,
                          color: Colors.grey.shade500,
                        ),
                      )
                    : Icon(
                        name.contains('فودافون') ? Icons.phone_android : Icons.account_balance,
                        color: Colors.grey.shade500,
                      ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.content_copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: details)).then((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم نسخ $details إلى الحافظة',
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                });
              },
              tooltip: 'نسخ',
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Color cardBgColor, Color textColor) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firestoreService = FirestoreService();
    final userId = authProvider.user?.uid;

    return FutureBuilder<UserProfile?>(
      future: userId != null ? firestoreService.getUserProfile(userId) : null,
      builder: (context, snapshot) {
        String currentBalance = "0.00";

        if (snapshot.connectionState == ConnectionState.waiting) {
          currentBalance = "...";
        } else if (snapshot.hasData && snapshot.data != null) {
          final userProfile = snapshot.data!;
          if (userProfile.balance == userProfile.balance.toInt()) {
            currentBalance = userProfile.balance.toInt().toString();
          } else {
            currentBalance = userProfile.balance.toStringAsFixed(2);
          }
        }

        return Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: primarySkyBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "رصيدك الحالي",
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "$currentBalance جنيه",
                  style: const TextStyle(
                    color: primarySkyBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPredefinedAmountButton(String amount) {
    final bool isSelected = _selectedPredefinedAmount == amount;
    return OutlinedButton(
      onPressed: _isSubmitting ? null : () => _selectPredefinedAmount(amount),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : primarySkyBlue,
        backgroundColor:
            isSelected ? primarySkyBlue.withOpacity(0.8) : Colors.transparent,
        side: BorderSide(color: primarySkyBlue.withOpacity(0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      ),
      child: Text(
        amount,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
