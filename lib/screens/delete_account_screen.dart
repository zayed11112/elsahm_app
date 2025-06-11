import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/theme.dart';
import 'dart:async';

// Define app bar color to match the wallet screen
const Color appBarBlue = Color(0xFF1976d3);

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isLoading = false;
  bool _confirmDelete = false;
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // Ensure we have a scaffold messenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // ignore: unused_local_variable
    final navigator = Navigator.of(context);
    
    if (!_confirmDelete) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تأكيد حذف الحساب بالضغط على زر التأكيد',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'يرجى إدخال كلمة المرور للتأكيد',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteAccount(_passwordController.text);
      
      if (success) {
        // عرض رسالة نجاح قبل إغلاق التطبيق
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                'تم حذف الحساب بنجاح، سيتم إغلاق التطبيق...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.fixed,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // إضافة تأخير بسيط ليرى المستخدم رسالة النجاح قبل إغلاق التطبيق
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // إغلاق التطبيق
          SystemNavigator.pop();
        }
      } else {
        // Handle error if mounted
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                'فشل حذف الحساب. يرجى التأكد من كلمة المرور',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    } catch (e) {
      // Handle error if mounted
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: ${e.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } finally {
      // Update loading state if mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Define colors based on theme
    final backgroundColor = isDarkMode ? darkBackground : Colors.grey[100];
    final cardColor = isDarkMode ? darkCard : Colors.white;
    final textColor = isDarkMode ? darkTextPrimary : Colors.black87;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBlue,
        title: const Text(
          'حذف الحساب',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning Card
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'تحذير: إجراء لا يمكن التراجع عنه',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'حذف حسابك سيؤدي إلى إزالة جميع بياناتك الشخصية والحجوزات والمراسلات من النظام بشكل نهائي. لا يمكن استعادة هذه البيانات بعد الحذف.',
                        style: TextStyle(
                          color: textColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Consequences Card
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ماذا يعني حذف حسابك:',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildConsequenceItem(
                        context,
                        icon: Icons.person_off_outlined,
                        text: 'سيتم حذف ملفك الشخصي وبياناتك الشخصية',
                        isDarkMode: isDarkMode,
                      ),
                      _buildConsequenceItem(
                        context,
                        icon: Icons.message_outlined,
                        text: 'سيتم حذف جميع رسائلك والمحادثات',
                        isDarkMode: isDarkMode,
                      ),
                      _buildConsequenceItem(
                        context,
                        icon: Icons.bookmark_border,
                        text: 'سيتم إلغاء جميع الحجوزات الحالية',
                        isDarkMode: isDarkMode,
                      ),
                      _buildConsequenceItem(
                        context,
                        icon: Icons.access_time,
                        text: 'سيتم حذف سجل النشاطات والمعاملات',
                        isDarkMode: isDarkMode,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                
                // Password Confirmation
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تأكيد الحذف',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          hintText: 'أدخل كلمة المرور للتأكيد',
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: appBarBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _confirmDelete,
                            onChanged: (value) {
                              setState(() {
                                _confirmDelete = value ?? false;
                              });
                            },
                            activeColor: Colors.red,
                          ),
                          Expanded(
                            child: Text(
                              'أؤكد أنني أرغب في حذف حسابي نهائياً وأنني أدرك أن هذا الإجراء لا يمكن التراجع عنه',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Delete Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _deleteAccount(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.red.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'جاري حذف الحساب...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'حذف الحساب نهائياً',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildConsequenceItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool isDarkMode,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Divider(
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
