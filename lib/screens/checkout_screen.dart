import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import '../services/checkout_service.dart';
import '../models/checkout_request.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:elsahm_app/screens/wallet_screen.dart';
import 'package:lottie/lottie.dart';
import '../services/booking_service.dart';
import 'booking_requests_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  final double propertyPrice;
  final String? imageUrl;

  const CheckoutScreen({
    Key? key,
    required this.propertyId,
    required this.propertyName,
    required this.propertyPrice,
    this.imageUrl,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final Logger _logger = Logger('CheckoutScreen');
  final CheckoutService _checkoutService = CheckoutService();
  final FirestoreService _firestoreService = FirestoreService();
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  // حقول النموذج
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _universityIdController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();

  String _status = 'جاري المعالجة';
  bool _isLoading = false;
  
  // معلومات العقار من قاعدة البيانات
  Map<String, dynamic>? _propertyDetails;
  double _propertyCommission = 0.0;
  double _propertyDeposit = 0.0;

  // معلومات المستخدم الحالي
  String? _userId;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _loadPropertyDetails();
  }

  // التحقق من المستخدم الحالي وجلب بياناته
  Future<void> _checkCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      
      if (firebaseUser != null) {
        _logger.info('المستخدم مسجل الدخول في Firebase - المعرف: ${firebaseUser.uid}, البريد: ${firebaseUser.email}');
        
        setState(() {
          _userId = firebaseUser.uid;
          _userEmail = firebaseUser.email;
        });

        // جلب بيانات المستخدم من Firestore
        await _loadUserProfileFromFirestore(firebaseUser.uid);
      } else {
        _logger.warning('لا يوجد مستخدم مسجل دخوله في Firebase');
      }
    } catch (e) {
      _logger.warning('خطأ في الحصول على معلومات المستخدم: $e');
    }
  }

  // جلب بيانات المستخدم من Firestore
  Future<void> _loadUserProfileFromFirestore(String userId) async {
    try {
      _logger.info('جلب بيانات المستخدم من Firestore: $userId');
      
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        _logger.info('تم جلب بيانات المستخدم بنجاح: ${userData.keys.toList()}');
        
        setState(() {
          // ملء بيانات المستخدم في حقول النموذج
          _nameController.text = userData['name'] ?? '';
          _universityIdController.text = userData['studentId'] ?? '';
          _collegeController.text = userData['faculty'] ?? '';
        });
      } else {
        _logger.warning('لم يتم العثور على بيانات المستخدم في Firestore');
      }
    } catch (e) {
      _logger.severe('خطأ في جلب بيانات المستخدم من Firestore: $e');
    }
  }

  // الحصول على معلومات العقار من قاعدة البيانات
  Future<void> _loadPropertyDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      _logger.info('جلب معلومات العقار بالمعرف: ${widget.propertyId}');
      
      // جلب معلومات العقار من Supabase
      final propertyDetails = await _checkoutService.getPropertyDetails(widget.propertyId);
      
      if (propertyDetails != null) {
        _logger.info('تم استلام بيانات العقار: $propertyDetails');
        
        // طباعة جميع مفاتيح الكائن للتشخيص
        _logger.info('مفاتيح العقار المستلمة: ${propertyDetails.keys.toList()}');
        
        // طباعة قيم العمولة والعربون كما وردت من قاعدة البيانات
        _logger.info('قيمة العمولة الخام: ${propertyDetails['commission']}');
        _logger.info('نوع قيمة العمولة: ${propertyDetails['commission']?.runtimeType}');
        _logger.info('قيمة العربون الخام: ${propertyDetails['deposit']}');
        _logger.info('نوع قيمة العربون: ${propertyDetails['deposit']?.runtimeType}');
        
        // استخراج قيم العمولة والعربون بشكل آمن
        double? commission;
        double? deposit;
        
        // استخراج العمولة
        try {
          if (propertyDetails.containsKey('commission')) {
            var commissionValue = propertyDetails['commission'];
            if (commissionValue != null) {
              if (commissionValue is int) {
                commission = commissionValue.toDouble();
              } else if (commissionValue is double) {
                commission = commissionValue;
              } else if (commissionValue is String) {
                commission = double.tryParse(commissionValue);
              } else if (commissionValue is num) {
                commission = commissionValue.toDouble();
              }
              _logger.info('تم استخراج العمولة بنجاح: $commission');
            } else {
              _logger.info('قيمة العمولة غير موجودة (null)');
            }
          } else {
            _logger.info('حقل العمولة غير موجود في بيانات العقار');
          }
        } catch (e) {
          _logger.severe('خطأ في استخراج العمولة: $e');
        }
        
        // استخراج العربون 
        try {
          if (propertyDetails.containsKey('deposit')) {
            var depositValue = propertyDetails['deposit'];
            if (depositValue != null) {
              if (depositValue is int) {
                deposit = depositValue.toDouble();
              } else if (depositValue is double) {
                deposit = depositValue;
              } else if (depositValue is String) {
                deposit = double.tryParse(depositValue);
              } else if (depositValue is num) {
                deposit = depositValue.toDouble();
              }
              _logger.info('تم استخراج العربون بنجاح: $deposit');
            } else {
              _logger.info('قيمة العربون غير موجودة (null)');
            }
          } else {
            _logger.info('حقل العربون غير موجود في بيانات العقار');
          }
        } catch (e) {
          _logger.severe('خطأ في استخراج العربون: $e');
        }
        
        setState(() {
          _propertyDetails = propertyDetails;
          
          // تعيين العمولة والعربون من بيانات العقار إن وجدت
          _propertyCommission = commission ?? 0.0;
          _propertyDeposit = deposit ?? 0.0;
          
          // تعبئة حقول العمولة والعربون تلقائياً
          _commissionController.text = _propertyCommission > 0 ? _propertyCommission.toString() : '';
          _depositController.text = _propertyDeposit > 0 ? _propertyDeposit.toString() : '';
        });
      } else {
        _logger.warning('لم يتم العثور على بيانات للعقار بالمعرف: ${widget.propertyId}');
      }
    } catch (e) {
      _logger.severe('خطأ في جلب معلومات العقار: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // التحقق من التوقيع على الشروط
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _universityIdController.dispose();
    _collegeController.dispose();
    _depositController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  // إرسال النموذج
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // إذا المستخدم غير مسجل دخول
      if (_userId == null) {
        // عرض رسالة تنبيه
        _showErrorDialog('يجب عليك تسجيل الدخول أولاً لإتمام عملية الحجز');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // حساب المبلغ الإجمالي المطلوب
        final double totalAmount = _propertyDeposit + _propertyCommission;
        
        // التحقق من رصيد المحفظة قبل المتابعة
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
        if (!userDoc.exists) {
          _showErrorDialog('لم يتم العثور على بيانات المستخدم');
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        // استخراج رصيد المحفظة
        final userData = userDoc.data() as Map<String, dynamic>;
        double userBalance = 0.0;
        
        if (userData.containsKey('balance')) {
          dynamic rawBalance = userData['balance'];
          if (rawBalance is num) {
            userBalance = rawBalance.toDouble();
          } else if (rawBalance is String) {
            userBalance = double.tryParse(rawBalance) ?? 0.0;
          }
        }
        
        _logger.info('رصيد المحفظة: $userBalance | المبلغ المطلوب: $totalAmount');
        
        // التحقق من كفاية الرصيد
        if (userBalance < totalAmount) {
          setState(() {
            _isLoading = false;
          });
          
          // عرض رسالة خطأ عدم كفاية الرصيد
          _showInsufficientBalanceDialog(userBalance, totalAmount);
          return;
        }
        
        // إذا كان الرصيد كافي، عرض مربع حوار التأكيد
        setState(() {
          _isLoading = false;
        });
        
        // عرض مربع حوار التأكيد
        bool confirmed = await _showConfirmationDialog(totalAmount);
        
        if (!confirmed) {
          // إذا ألغى المستخدم العملية
          return;
        }
        
        setState(() {
          _isLoading = true;
        });

        // استخدام البيانات من قاعدة البيانات إذا كانت متوفرة
        final String propertyName = _propertyDetails != null && _propertyDetails!['name'] != null 
            ? _propertyDetails!['name'] 
            : widget.propertyName;
            
        final double propertyPrice = _propertyDetails != null && _propertyDetails!['price'] != null 
            ? (_propertyDetails!['price'] is num ? _propertyDetails!['price'].toDouble() : 0.0)
            : widget.propertyPrice;
            
        // إنشاء كائن طلب الحجز
        final checkoutData = {
          'user_id': _userId,
          'property_id': widget.propertyId,
          'property_name': propertyName,
          'customer_name': _nameController.text,
          'customer_phone': _phoneController.text,
          'university_id': _universityIdController.text,
          'college': _collegeController.text,
          'status': _status,
          'commission': double.tryParse(_commissionController.text) ?? _propertyCommission,
          'deposit': double.tryParse(_depositController.text) ?? _propertyDeposit,
          'property_price': propertyPrice,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        bool isSuccess = false;
        
        // إرسال البيانات إلى Supabase
        try {
          _logger.info('محاولة إرسال البيانات إلى Supabase');
          await _checkoutService.addCheckoutRequest(checkoutData);
          _logger.info('تم إرسال البيانات بنجاح إلى Supabase');
          
          // خصم المبلغ من رصيد المستخدم في Firestore
          await _updateUserBalance(totalAmount);
          
          isSuccess = true;
        } catch (e) {
          _logger.severe('خطأ في إرسال البيانات إلى Supabase: $e');
          
          // محاولة حفظ البيانات في Firestore كنسخة احتياطية
          try {
            _logger.info('محاولة حفظ البيانات في Firestore كنسخة احتياطية');
            await FirebaseFirestore.instance.collection('checkout_requests_backup').add(checkoutData);
            _logger.info('تم حفظ البيانات بنجاح في Firestore');
            
            // خصم المبلغ من رصيد المستخدم في Firestore
            await _updateUserBalance(totalAmount);
            
            isSuccess = true;
          } catch (backupError) {
            _logger.severe('فشل النسخة الاحتياطية أيضًا: $backupError');
            isSuccess = false;
          }
        }
        
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });
        
        if (isSuccess) {
          // عرض رسالة نجاح الحجز ثم العودة للشاشة الرئيسية
          _showSuccessAndReturnHome();
        } else {
          _showErrorDialog('حدث خطأ أثناء إرسال طلب الحجز، يرجى المحاولة مرة أخرى');
        }
      } catch (e) {
        _logger.severe('خطأ في إرسال النموذج: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog('حدث خطأ أثناء إرسال طلب الحجز، يرجى المحاولة مرة أخرى');
        }
      }
    }
  }

  // عرض مربع حوار عدم كفاية الرصيد
  void _showInsufficientBalanceDialog(double currentBalance, double requiredAmount) {
    final formattedCurrentBalance = formatCurrency(currentBalance);
    final formattedRequiredAmount = formatCurrency(requiredAmount);
    final formattedMissingAmount = formatCurrency(requiredAmount - currentBalance);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text('رصيد غير كافي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'رصيد محفظتك لا يكفي لإتمام عملية الحجز',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'رصيدك الحالي:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '$formattedCurrentBalance جنيه',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المبلغ المطلوب:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '$formattedRequiredAmount جنيه',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المبلغ الناقص:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$formattedMissingAmount جنيه',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'يرجى شحن محفظتك بمبلغ كافٍ لإتمام عملية الحجز.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق الحوار
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق الحوار
              // الانتقال إلى شاشة شحن الرصيد
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalletScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('شحن المحفظة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  // عرض رسالة خطأ
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // عرض مربع حوار التأكيد قبل إتمام الحجز
  Future<bool> _showConfirmationDialog(double totalAmount) async {
    // المبلغ المطلوب بتنسيق مناسب
    final String formattedAmount = formatCurrency(totalAmount);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // يجب على المستخدم الاختيار
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text('تأكيد الحجز'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هل أنت متأكد من إتمام عملية الحجز؟',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'سيتم خصم المبلغ الإجمالي ($formattedAmount جنيه) من رصيد محفظتك.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // إلغاء
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // تأكيد
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('تأكيد الحجز'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actionsAlignment: MainAxisAlignment.spaceBetween,
        );
      },
    ) ?? false; // إذا تم إغلاق مربع الحوار بدون اختيار، نعتبرها إلغاء
  }

  // دالة مساعدة لتنسيق القيم النقدية - إزالة الأصفار بعد النقطة العشرية
  String formatCurrency(num value) {
    if (value == value.toInt()) {
      // إذا كانت القيمة عدد صحيح (بدون كسور)
      return value.toInt().toString();
    } else {
      // إذا كانت القيمة تحتوي على كسور
      return value.toString();
    }
  }

  // تحديث رصيد المستخدم بعد إتمام الحجز
  Future<void> _updateUserBalance(double amountToDeduct) async {
    try {
      _logger.info('بدء تحديث رصيد المستخدم - خصم $amountToDeduct جنيه');
      
      if (_userId == null) {
        _logger.severe('لا يمكن تحديث الرصيد: معرف المستخدم غير موجود');
        return;
      }
      
      // الحصول على بيانات المستخدم الحالية
      final docRef = FirebaseFirestore.instance.collection('users').doc(_userId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        _logger.severe('لا يمكن تحديث الرصيد: بيانات المستخدم غير موجودة');
        return;
      }
      
      // استخراج الرصيد الحالي
      final userData = docSnapshot.data() as Map<String, dynamic>;
      double currentBalance = 0.0;
      
      if (userData.containsKey('balance')) {
        dynamic rawBalance = userData['balance'];
        if (rawBalance is num) {
          currentBalance = rawBalance.toDouble();
        } else if (rawBalance is String) {
          currentBalance = double.tryParse(rawBalance) ?? 0.0;
        }
      }
      
      // حساب الرصيد الجديد
      final newBalance = currentBalance - amountToDeduct;
      
      // تحديث الرصيد في Firestore
      await docRef.update({
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      _logger.info('تم تحديث رصيد المستخدم بنجاح. الرصيد القديم: $currentBalance، الرصيد الجديد: $newBalance');
    } catch (e) {
      _logger.severe('خطأ في تحديث رصيد المستخدم: $e');
      throw Exception('فشل تحديث رصيد المستخدم: $e');
    }
  }

  // عرض رسالة نجاح الحجز ثم العودة للشاشة الرئيسية
  void _showSuccessAndReturnHome() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "تم الحجز بنجاح",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "يمكنك متابعة حالة الحجز من صفحة طلبات الحجز",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text("حسناً"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        // انتقل إلى شاشة طلبات الحجز
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookingRequestsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("متابعة الحجوزات"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // إرسال طلب الحجز
  Future<bool> _submitRequest() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      _logger.info('بدء إرسال طلب الحجز للعقار: ${widget.propertyName}');
      
      // تحضير بيانات الطلب
      final Map<String, dynamic> requestData = {
        'property_id': widget.propertyId,
        'property_name': widget.propertyName,
        'property_price': widget.propertyPrice,
        'customer_name': _nameController.text,
        'customer_phone': _phoneController.text,
        'university_id': _universityIdController.text,
        'college': _collegeController.text,
        'deposit': _propertyDeposit > 0 ? _propertyDeposit : double.tryParse(_depositController.text) ?? 0.0,
        'commission': _propertyCommission > 0 ? _propertyCommission : double.tryParse(_commissionController.text) ?? 0.0,
        'status': _status,
        'user_id': _userId ?? '',
        'user_email': _userEmail ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      _logger.info('بيانات طلب الحجز: $requestData');
      
      // إرسال الطلب إلى Supabase
      await _checkoutService.addCheckoutRequest(requestData);
      
      // إنشاء حجز في Firestore
      final bookingService = BookingService();
      final bookingId = await bookingService.createBooking(
        apartmentId: widget.propertyId,
        apartmentName: widget.propertyName,
        totalPrice: widget.propertyPrice,
        startDate: DateTime.now(), // يمكن تعديل هذه القيم حسب احتياجات التطبيق
        endDate: DateTime.now().add(const Duration(days: 365)), // سنة كاملة كافتراضي
        notes: 'تم الحجز من خلال صفحة الحجز',
        imageUrl: widget.imageUrl,
      );
      
      _logger.info('تم إنشاء الحجز في Firestore بنجاح، المعرف: $bookingId');
      
      return true;
    } catch (e) {
      _logger.severe('خطأ في إرسال طلب الحجز: $e');
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // التحقق من المستخدم الحالي في Firebase بدلاً من Supabase
    final firebaseUser = _firebaseAuth.currentUser;
    final bool isLoggedIn = firebaseUser != null;
    
    // سجل معلومات المستخدم للتشخيص
    if (firebaseUser != null) {
      _logger.info('المستخدم مسجل الدخول في Firebase - المعرف: ${firebaseUser.uid}, البريد: ${firebaseUser.email}');
      
      // تأكد من أن معرف المستخدم محدث في الحالة
      if (_userId != firebaseUser.uid) {
        _userId = firebaseUser.uid;
        _userEmail = firebaseUser.email;
      }
    } else {
      _logger.warning('لا يوجد مستخدم مسجل دخوله في Firebase');
    }

    if (!isLoggedIn) {
      // إذا لم يكن المستخدم مسجل دخوله، نعرض شاشة تسجيل الدخول
      return Scaffold(
        appBar: AppBar(
          title: const Text('إتمام الحجز'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'تسجيل الدخول مطلوب',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'لإتمام عملية الحجز، يرجى تسجيل الدخول أولاً',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // معلومات العقار
                if (_propertyDetails != null) ...[
                  Text(
                    'معلومات العقار',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _propertyDetails!['name'] ?? widget.propertyName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.payments,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'العمولة: ${_propertyCommission > 0 ? "${_propertyCommission.toStringAsFixed(2)} جنيه" : "بدون تحديد"}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.money,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'العربون: ${_propertyDeposit > 0 ? "${_propertyDeposit.toStringAsFixed(2)} جنيه" : "بدون تحديد"}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // التنقل إلى شاشة تسجيل الدخول
                    Navigator.pushNamed(context, '/login').then((_) {
                      // بعد العودة من شاشة تسجيل الدخول، نتحقق إذا كان المستخدم قد سجل دخوله
                      setState(() {
                        // سيتم إعادة بناء الواجهة وسيتم التحقق من المستخدم مرة أخرى
                      });
                    });
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('تسجيل الدخول'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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

    // المستخدم مسجل دخوله، عرض الشاشة الأصلية
    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الحجز'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عرض معلومات العقار
                    _buildPropertyInfo(context),
                    
                    const SizedBox(height: 24),
                    
                    // إضافة عرض رصيد المحفظة
                    _buildWalletBalance(context),
                    
                    const SizedBox(height: 24),
                    
                    // إضافة قسم رسالة توضيحية للحجز
                    _buildBookingInfoMessage(context),
                    
                    const SizedBox(height: 24),
                    
                    // نموذج الحجز
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'بيانات الحجز',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // حقل الاسم
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'الاسم',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال اسمك';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // حقل رقم الهاتف
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'رقم الهاتف',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال رقم الهاتف';
                                  }
                                  if (value.length < 10) {
                                    return 'رقم الهاتف غير صحيح';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // حقل الرقم الجامعي
                              TextFormField(
                                controller: _universityIdController,
                                decoration: InputDecoration(
                                  labelText: 'الرقم الجامعي',
                                  prefixIcon: const Icon(Icons.school),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال الرقم الجامعي';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // حقل الكلية
                              TextFormField(
                                controller: _collegeController,
                                decoration: InputDecoration(
                                  labelText: 'الكلية',
                                  prefixIcon: const Icon(Icons.account_balance),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال الكلية';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // حقل العمولة
                              TextFormField(
                                controller: _commissionController,
                                decoration: InputDecoration(
                                  labelText: 'العمولة',
                                  prefixIcon: const Icon(Icons.monetization_on),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                enabled: false,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // حقل العربون
                              TextFormField(
                                controller: _depositController,
                                decoration: InputDecoration(
                                  labelText: 'العربون',
                                  prefixIcon: const Icon(Icons.payment),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                enabled: false,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // إظهار إجمالي المبلغ المطلوب بطريقة احترافية
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary.withOpacity(0.7),
                                      colorScheme.primary.withOpacity(0.4),
                                    ],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ملخص الدفع',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'العربون:',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${formatCurrency(_propertyDeposit)} جنيه',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'العمولة:',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${formatCurrency(_propertyCommission)} جنيه',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Divider(
                                        color: Colors.white,
                                        thickness: 0.5,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'المجموع:',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${formatCurrency(_propertyDeposit + _propertyCommission)} جنيه',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // زر تأكيد الحجز
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'تأكيد الحجز',
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
                  ],
                ),
              ),
            ),
    );
  }

  // بناء قسم معلومات العقار
  Widget _buildPropertyInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات العقار',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // صورة العقار مع تفاصيله
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة العقار
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.imageUrl != null
                      ? Image.network(
                          widget.imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.home,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // تفاصيل العقار
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _propertyDetails != null 
                          ? _propertyDetails!['name'] ?? widget.propertyName 
                          : widget.propertyName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _propertyDetails != null
                              ? '${formatCurrency(_propertyDetails!['price'])} جنيه'
                              : '${formatCurrency(widget.propertyPrice)} جنيه',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.payments,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'العمولة: ${_propertyCommission > 0 ? "${_propertyCommission.toStringAsFixed(2)} جنيه" : "بدون تحديد"}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'العربون: ${_propertyDeposit > 0 ? "${_propertyDeposit.toStringAsFixed(2)} جنيه" : "بدون تحديد"}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // بناء قسم رصيد المحفظة
  Widget _buildWalletBalance(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final walletCardBg = isDarkMode ? const Color(0xFF2C3E50) : Colors.white;
    final walletTextColor = isDarkMode ? Colors.white70 : Colors.black87;
    final primarySkyBlue = const Color(0xFF4FC3F7);

    // التحقق من المستخدم الحالي مباشرة من Firebase
    final firebaseUser = _firebaseAuth.currentUser;
    final String? currentUserId = firebaseUser?.uid;

    // التحقق من وجود معرف المستخدم
    if (currentUserId == null) {
      _logger.warning('لا يمكن عرض رصيد المحفظة: لا يوجد مستخدم مسجل الدخول');
      return const SizedBox.shrink();
    }

    _logger.info('جلب رصيد المحفظة للمستخدم: $currentUserId');

    // دالة للانتقال إلى صفحة شحن الرصيد
    void _navigateToTopUpScreen() {
      _logger.info('الانتقال إلى صفحة شحن الرصيد');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WalletScreen(),
        ),
      ).then((_) {
        // عند العودة من صفحة الشحن، يمكن تحديث الرصيد تلقائياً
        setState(() {
          // سيؤدي إلى إعادة بناء الواجهة وتحديث الرصيد
        });
      });
    }

    // استخدام Firestore للتحقق من رصيد المحفظة
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        String currentBalance = "...";
        bool isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        if (snapshot.hasError) {
          _logger.severe('خطأ في جلب رصيد المحفظة: ${snapshot.error}');
          currentBalance = "خطأ في جلب البيانات";
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          _logger.info('تم جلب بيانات المستخدم من Firestore');
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          
          if (userData != null) {
            _logger.info('مفاتيح بيانات المستخدم: ${userData.keys.toList()}');
            
            if (userData.containsKey('balance')) {
              dynamic rawBalance = userData['balance'];
              _logger.info('رصيد المحفظة الخام: $rawBalance (النوع: ${rawBalance.runtimeType})');
              
              // محاولة استخراج قيمة الرصيد
              double balance = 0.0;
              
              if (rawBalance is num) {
                balance = rawBalance.toDouble();
              } else if (rawBalance is String) {
                balance = double.tryParse(rawBalance) ?? 0.0;
              }
              
              currentBalance = formatCurrency(balance);
              _logger.info('تم تحويل الرصيد إلى: $currentBalance');
            } else {
              _logger.warning('لا يوجد حقل رصيد في بيانات المستخدم');
              currentBalance = "0";
            }
          } else {
            _logger.warning('بيانات المستخدم فارغة');
            currentBalance = "0";
          }
        }
        
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // الجزء العلوي من البطاقة (الرصيد)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'رصيد المحفظة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Text(
                                '$currentBalance',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            const SizedBox(width: 4),
                            Text(
                              'جنيه',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // زر شحن الرصيد
                    ElevatedButton.icon(
                      onPressed: _navigateToTopUpScreen,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('شحن الرصيد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // بناء قسم رسالة توضيحية للحجز
  Widget _buildBookingInfoMessage(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    // حساب إجمالي المبلغ المطلوب (العربون + العمولة)
    final double totalAmount = _propertyDeposit + _propertyCommission;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // عنوان القسم مع أيقونة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'معلومات هامة',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // رسالة الترحيب
            Text(
              'أهلا بك في شركة السهم',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // معلومات الحجز
            Text(
              'لتأكيد الحجز، يرجى التأكد من شحن رصيد محفظتك لإتمام عملية الحجز بنجاح.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // شرح آلية الدفع
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'الحجز يتضمن دفع العربون (${formatCurrency(_propertyDeposit)} جنيه) وهو يذهب للمالك كتأكيد للحجز، بالإضافة إلى العمولة (${formatCurrency(_propertyCommission)} جنيه) وهي خاصة بشركة السهم.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            
            // إظهار إجمالي المبلغ المطلوب
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'إجمالي المبلغ المطلوب: ',
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    '${formatCurrency(totalAmount)} جنيه',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 