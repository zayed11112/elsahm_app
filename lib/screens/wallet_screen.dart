import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:provider/provider.dart'; // إضافة Provider
import '../models/user_profile.dart'; // إضافة نموذج UserProfile
import '../models/payment_method.dart'; // إضافة نموذج طرق الدفع
import '../services/firestore_service.dart'; // إضافة FirestoreService
import '../services/supabase_service.dart'; // إضافة SupabaseService
import '../services/payment_methods_service.dart'; // إضافة خدمة طرق الدفع
import '../providers/auth_provider.dart'; // إضافة AuthProvider
import '../utils/notification_utils.dart'; // إضافة خدمة الإشعارات
import '../constants/theme.dart'
    hide accentBlue; // Import theme constants but hide accentBlue
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import './payment_requests_screen.dart'; // استيراد صفحة طلبات الدفع

// Re-export the theme constants for backward compatibility
// Using different variable names to avoid self-reference
const Color appBarBlue = Color(0xFF1976d3); // New color for AppBar
const Color accentBlue = Color(
  0xFF29B6F6,
); // Local definition to avoid ambiguity

// The rest of the dark mode colors are now imported from theme.dart

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
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
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // تعبئة اسم المستخدم من الملف الشخصي إذا كان متاحاً
    _fillUserDetails();
    // تحميل طرق الدفع المتاحة من قاعدة البيانات
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    // Hide any displayed banners when the screen is disposed
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    }
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _nameController.dispose();
    _universityIdController.dispose();
    _sourcePhoneController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Hide banners when app is paused or inactive
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    }
  }

  // اضافة طريقة لإخفاء الإشعارات عند الانتقال للخلف
  void _hideNotificationsOnBack() {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    }
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

        NotificationUtils.showTopErrorBanner(
          context,
          'خطأ في تحميل طرق الدفع: $e',
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
      if (mounted) {
        NotificationUtils.showTopErrorBanner(
          context,
          'خطأ في اختيار الصورة: $e',
        );
      }
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

        if (mounted) {
          NotificationUtils.showTopSuccessBanner(
            context,
            'تم رفع الصورة بنجاح',
          );

          // Ensure banner is automatically hidden when leaving the screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              Future.delayed(const Duration(seconds: 4), () {
                // Check if widget is still mounted before accessing context
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                }
              });
            }
          });
        }
      } catch (imgbbError) {
        // If ImgBB fails, try with Freeimage.host as fallback
        try {
          final String imageUrl = await _uploadToFreeImage(_imageFile!);

          setState(() {
            _uploadedImageUrl = imageUrl;
            _isUploading = false;
          });

          if (mounted) {
            NotificationUtils.showTopSuccessBanner(
              context,
              'تم رفع الصورة بنجاح (باستخدام الخادم البديل)',
            );

            // Ensure banner is automatically hidden when leaving the screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                Future.delayed(const Duration(seconds: 4), () {
                  // Check if widget is still mounted before accessing context
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  }
                });
              }
            });
          }
        } catch (freeimageError) {
          throw Exception(
            'فشل في رفع الصورة على كلا الخادمين: $imgbbError، $freeimageError',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        NotificationUtils.showTopErrorBanner(context, 'فشل في رفع الصورة: $e');

        // Ensure error banner is automatically hidden when leaving the screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            Future.delayed(const Duration(seconds: 4), () {
              // Check if widget is still mounted before accessing context
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              }
            });
          }
        });
      }
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
      NotificationUtils.showTopErrorBanner(
        context,
        'يرجى اختيار طريقة دفع أولاً',
      );
      return;
    }

    // التحقق من إدخال المبلغ المراد شحنه
    if (_amountController.text.isEmpty) {
      NotificationUtils.showTopErrorBanner(
        context,
        'يرجى إدخال المبلغ المراد شحنه',
      );
      return;
    }

    // التحقق من إدخال رقم الهاتف أو اسم المستخدم
    if (_sourcePhoneController.text.isEmpty) {
      NotificationUtils.showTopErrorBanner(
        context,
        _selectedPaymentMethod == 'إنستا باي'
            ? 'يرجى إدخال اسم المستخدم على إنستا باي'
            : 'يرجى إدخال الرقم الذي حولت منه',
      );
      return;
    }

    // التحقق من رفع صورة التحويل
    if (_uploadedImageUrl == null) {
      NotificationUtils.showTopErrorBanner(
        context,
        'يرجى رفع صورة إثبات التحويل',
      );
      return;
    }

    // التحقق من باقي البيانات المطلوبة
    if (_nameController.text.isEmpty || _universityIdController.text.isEmpty) {
      NotificationUtils.showTopErrorBanner(
        context,
        'يرجى إكمال جميع البيانات المطلوبة',
      );
      return;
    }

    // التحقق من صحة صيغة الإدخال حسب طريقة الدفع
    final String? validationError = _validateSourceField(
      _sourcePhoneController.text,
    );
    if (validationError != null) {
      NotificationUtils.showTopErrorBanner(context, validationError);
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
            final textColor =
                isDarkMode ? Colors.white : const Color(0xFF2D3142);
            final subtextColor =
                isDarkMode ? Colors.white70 : Colors.grey.shade700;
            final receiptBgColor =
                isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              backgroundColor:
                  isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient:
                      isDarkMode
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
                        color:
                            isDarkMode ? const Color(0xFF2D3748) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: appBarBlue.withOpacity(
                              isDarkMode ? 0.2 : 0.3,
                            ),
                            spreadRadius: 2,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: appBarBlue,
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
                      style: TextStyle(fontSize: 16, color: subtextColor),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "سيتم مراجعة طلبك من فريق شركة السهم",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: subtextColor),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "سيتم إرسال إشعار لك عند التحقق من الدفع",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: subtextColor),
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
                            color: appBarBlue,
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
                          backgroundColor: appBarBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          _hideNotificationsOnBack();
                          Navigator.of(context).pop();
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
        NotificationUtils.showTopErrorBanner(context, 'فشل في إرسال الطلب: $e');

        // Ensure error banner is automatically hidden when leaving the screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            Future.delayed(const Duration(seconds: 4), () {
              // Check if widget is still mounted before accessing context
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              }
            });
          }
        });

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

    // Define colors based on theme
    final backgroundColor = isDarkMode ? darkBackground : Colors.white;
    final cardColor = isDarkMode ? darkCard : Colors.white;
    final textPrimaryColor = isDarkMode ? darkTextPrimary : Colors.black87;
    final textSecondaryColor =
        isDarkMode ? darkTextSecondary : Colors.grey.shade600;
    final iconColor = isDarkMode ? skyBlue : appBarBlue;
    final surfaceColor = isDarkMode ? darkSurface : Colors.grey.shade50;
    final buttonColor = isDarkMode ? primaryBlueDark : appBarBlue;

    return WillPopScope(
      onWillPop: () async {
        // Hide any displayed banners when user presses back button
        _hideNotificationsOnBack();
        return true;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'شحن المحفظة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: appBarBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 2.0,
        ),
        body: Column(
          children: [
            // Main content in scrollable area
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Balance Card
                      _buildBalanceCard(cardColor, textPrimaryColor),
                      const SizedBox(height: 20),

                      // Payment Methods Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'طريقة 2',
                              style: TextStyle(
                                color: appBarBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'طرق الدفع المتاحة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.payments_outlined,
                            color: iconColor,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // إضافة ملحوظة احترافية
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? Colors.blue.withOpacity(0.15)
                                  : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 18,
                              color: isDarkMode ? accentBlue : appBarBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'اضغط علي الطريقة اللي حولت من خلالها',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDarkMode
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Payment Methods Cards
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
                                    color: Colors.grey.withOpacity(0.6),
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
                                      (method) => _buildPaymentMethodItemNew(
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

                      const SizedBox(height: 16),

                      // رسالة تنبيه للمستخدم
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'قم بالتحويل على إحدى طرق الدفع أعلاه ثم أدخل بياناتك واختر صورة إيصال التحويل',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Amount Input Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'مبلغ الشحن',
                              style: TextStyle(
                                color: appBarBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'المبلغ المراد شحنه',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: iconColor,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل المبلغ أو اختر من المقترحات',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Amount input field
                      TextField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                          LengthLimitingTextInputFormatter(25),
                        ],
                        decoration: InputDecoration(
                          hintText: 'المبلغ (بالجنيه)',
                          prefixIcon: Icon(
                            Icons.monetization_on,
                            color: iconColor.withOpacity(0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                              color: appBarBlue,
                              width: 2.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
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

                      const SizedBox(height: 12),

                      // Predefined Amounts
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:
                            ['1000', '2000', '4000', '6000']
                                .map(
                                  (amount) =>
                                      _buildPredefinedAmountButtonNew(amount),
                                )
                                .toList(),
                      ),

                      const SizedBox(height: 24),

                      // User Info Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'بيانات شخصية',
                              style: TextStyle(
                                color: appBarBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'أدخل بياناتك',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.person_outline,
                            color: iconColor,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'البيانات المطلوبة للتحقق',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // اسم المستخدم
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            'الاسم داخل التطبيق',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey.shade500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                              color: appBarBlue,
                              width: 2.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        inputFormatters: [LengthLimitingTextInputFormatter(40)],
                        textAlign: TextAlign.start,
                        enabled: !_isSubmitting,
                      ),

                      const SizedBox(height: 16),

                      // الرقم الجامعي
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            'الرقم الجامعي',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _universityIdController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: Colors.grey.shade500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                              color: appBarBlue,
                              width: 2.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        inputFormatters: [LengthLimitingTextInputFormatter(25)],
                        textAlign: TextAlign.start,
                        enabled: !_isSubmitting,
                      ),

                      const SizedBox(height: 16),

                      // الرقم الذي حوّلت منه
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            _selectedPaymentMethod == 'إنستا باي'
                                ? 'الرقم الذي حولت منه'
                                : 'الرقم الذي حولت منه',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _sourcePhoneController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            _selectedPaymentMethod == 'إنستا باي'
                                ? Icons.alternate_email
                                : Icons.phone,
                            color: Colors.grey.shade500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                              color: appBarBlue,
                              width: 2.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          hintText:
                              _selectedPaymentMethod == 'إنستا باي'
                                  ? 'اسم المستخدم على انستا باي'
                                  : 'مثال: 01xxxxxxxxx',
                        ),
                        textAlign: TextAlign.start,
                        keyboardType:
                            _selectedPaymentMethod == 'إنستا باي'
                                ? TextInputType.text
                                : TextInputType.phone,
                        inputFormatters:
                            _selectedPaymentMethod == 'إنستا باي'
                                ? [
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'@'),
                                  ),
                                  LengthLimitingTextInputFormatter(25),
                                ]
                                : [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(25),
                                ],
                        enabled: !_isSubmitting,
                      ),

                      const SizedBox(height: 24),

                      // Payment Proof Upload Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'رفع صورة',
                              style: TextStyle(
                                color: appBarBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'إثبات التحويل',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.image_outlined,
                            color: iconColor,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'صورة أو سكرين شوت للإيصال',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // صورة إثبات التحويل
                      InkWell(
                        onTap: _isSubmitting ? null : _pickImage,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.0,
                            ),
                          ),
                          child:
                              _isUploading
                                  ? const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          color: appBarBlue,
                                        ),
                                        SizedBox(height: 10),
                                        Text('جاري رفع الصورة...'),
                                      ],
                                    ),
                                  )
                                  : _imageFile != null
                                  ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                      // زر تغيير الصورة
                                      Positioned(
                                        bottom: 12,
                                        right: 12,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                isDarkMode
                                                    ? Colors.black54
                                                    : Colors.white.withOpacity(
                                                      0.8,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap:
                                                  _isSubmitting
                                                      ? null
                                                      : _pickImage,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      size: 16,
                                                      color:
                                                          isDarkMode
                                                              ? Colors.white
                                                              : appBarBlue,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'تغيير',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                        color:
                                                            isDarkMode
                                                                ? Colors.white
                                                                : appBarBlue,
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
                                  )
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        size: 40,
                                        color: Colors.blue.shade300,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'انقر لرفع صورة إثبات التحويل',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '(سكرين شوت أو صورة إيصال)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // زر رفع الصورة
                                      ElevatedButton.icon(
                                        onPressed:
                                            _isSubmitting ? null : _pickImage,
                                        icon: const Icon(
                                          Icons.add_photo_alternate_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'اختيار صورة',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isDarkMode
                                                  ? Colors.blueGrey.shade700
                                                  : appBarBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Verification note
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'سيتم التحقق من التحويل وسيتم إرسال إشعار لك إذا كان التحويل صحيح',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isSubmitting
                            ? Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(left: 8),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(Icons.arrow_forward, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isSubmitting ? 'جاري الإرسال...' : 'إرسال الطلب',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors for this widget based on theme
    final cardBorderColor = isDarkMode ? darkCardColor : Colors.blue.shade100;
    final tagBgColor = isDarkMode ? darkSurface : Colors.blue.shade50;
    final iconColor = isDarkMode ? skyBlue : appBarBlue;
    final textSecondaryColor =
        isDarkMode ? darkTextSecondary : Colors.grey.shade600;
    final valueColor = isDarkMode ? accentBlue : appBarBlue;

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

        return Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          color: cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cardBorderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tagBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'رصيد حالي',
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "رصيدك الحالي",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "المبلغ المتاح للاستخدام",
                  style: TextStyle(fontSize: 14, color: textSecondaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  "$currentBalance جنيه",
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodItemNew(
    String name,
    String details,
    bool isDarkMode,
    bool isSelected,
    VoidCallback onTap,
  ) {
    // البحث عن طريقة الدفع في القائمة للحصول على الصورة
    final paymentMethod = _paymentMethods.firstWhere(
      (method) => method.name == name,
      orElse:
          () => PaymentMethod(
            id: '',
            name: name,
            paymentIdentifier: details,
            isActive: true,
            displayOrder: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
    );

    // استخدام صورة طريقة الدفع من قاعدة البيانات
    final String? imageUrl = paymentMethod.imageUrl;

    // Define colors for this widget based on theme
    final cardColor = isDarkMode ? darkCard : Colors.white;
    final borderColor =
        isSelected
            ? (isDarkMode ? accentBlue : appBarBlue)
            : (isDarkMode ? darkCardColor : Colors.grey.shade300);
    final textPrimaryColor = isDarkMode ? darkTextPrimary : Colors.black87;
    final textSecondaryColor =
        isDarkMode ? darkTextSecondary : Colors.grey.shade600;
    final loaderColor = isDarkMode ? accentBlue : appBarBlue;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Display image from database if available
              if (imageUrl != null && imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 40,
                  height: 40,
                  placeholder:
                      (context, url) => SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: loaderColor,
                            ),
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) =>
                          _getDefaultPaymentIcon(name, isDarkMode),
                )
              else
                _getDefaultPaymentIcon(name, isDarkMode),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: TextStyle(color: textSecondaryColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.content_copy,
                  size: 20,
                  color: isDarkMode ? skyBlue : Colors.grey.shade600,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: details));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ $details'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get default payment method icon
  Widget _getDefaultPaymentIcon(String name, bool isDarkMode) {
    if (name.contains('فودافون')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF2A1010) : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.phone_android, color: Colors.red.shade500, size: 24),
      );
    } else if (name.contains('إنستا')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF0A1A2A) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.account_balance,
          color: isDarkMode ? skyBlue : Colors.blue.shade500,
          size: 24,
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode ? darkSurface : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.payment,
          color: isDarkMode ? skyBlue : Colors.grey.shade600,
          size: 24,
        ),
      );
    }
  }

  Widget _buildPredefinedAmountButtonNew(String amount) {
    final bool isSelected = _selectedPredefinedAmount == amount;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors for this widget based on theme
    final selectedBgColor = isDarkMode ? accentBlue : appBarBlue;
    final selectedTextColor = Colors.white;
    // Always use white text in dark mode, even for unselected buttons
    final normalTextColor = isDarkMode ? Colors.white : Colors.black87;
    final borderColor =
        isSelected
            ? selectedBgColor
            : (isDarkMode ? darkCardColor : Colors.grey.shade300);

    return InkWell(
      onTap: _isSubmitting ? null : () => _selectPredefinedAmount(amount),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? selectedBgColor
                  : (isDarkMode ? darkCard : Colors.transparent),
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          amount,
          style: TextStyle(
            color: isSelected ? selectedTextColor : normalTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
