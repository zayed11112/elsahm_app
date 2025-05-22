import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart'; // Import NavigationProvider
import 'main_navigation_screen.dart'; // Import MainNavigationScreen
// No need to import LoginScreen here if we just pop

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true); // Show loading indicator
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final navProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      ); // Get NavigationProvider
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      bool success = false;
      try {
        success = await authProvider.signUp(email, password);

        // إذا نجح التسجيل، قم بتحديث الملف الشخصي بالاسم الكامل
        if (success && mounted) {
          // تحديث الملف الشخصي بالاسم الكامل
          await authProvider.updateUserProfile(fullName);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false); // Hide loading indicator
        }
      }

      if (success && mounted) {
        // Navigate to MainNavigationScreen and select the 'More' tab (index 4)
        // Pop all routes until the root (or a specific point if needed) and push MainNavigationScreen
        navProvider.setIndex(4); // Set the index for the 'More' screen
        
        print("تم إنشاء الحساب بنجاح - الانتقال إلى الشاشة الرئيسية");
        
        // Navigate to MainNavigationScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainNavigationScreen()),
          (route) => false, // Remove all previous routes
        );
        
        // طلب التحقق من اكتمال الملف الشخصي بعد فترة قصيرة
        Future.delayed(const Duration(milliseconds: 500), () {
          MainNavigationScreen.checkProfileCompletion();
        });

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء الحساب بنجاح! تم حفظ اسمك في قاعدة البيانات.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!success && mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'فشل إنشاء الحساب. قد يكون البريد الإلكتروني مستخدماً بالفعل.',
            ), // Sign up failed. Email might be in use.
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة تسجيل الدخول عبر جوجل
  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final navProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      );

      final success = await authProvider.signInWithGoogle();

      if (!mounted) return;

      if (success) {
        // إذا كان هناك اسم كامل مدخل، قم بتحديث الملف الشخصي
        final fullName = _fullNameController.text.trim();
        if (fullName.isNotEmpty) {
          await authProvider.updateUserProfile(fullName);
        }

        if (!mounted) return;

        // Navigate to MainNavigationScreen
        Navigator.of(context).popUntil((route) => route.isFirst);
        navProvider.setIndex(4);
        
        print("تسجيل الدخول بنجاح عبر جوجل - الانتقال إلى الشاشة الرئيسية");
        
        // Navigate to MainNavigationScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainNavigationScreen()),
          (route) => false, // Remove all previous routes
        );
        
        // طلب التحقق من اكتمال الملف الشخصي بعد فترة قصيرة
        Future.delayed(const Duration(milliseconds: 500), () {
          MainNavigationScreen.checkProfileCompletion();
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الدخول بنجاح عبر جوجل'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تسجيل الدخول عبر جوجل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Add AppBar with close button
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'إنشاء حساب جديد',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Icon Placeholder (as seen in the mockup)
                Icon(
                  Icons.person_add_alt_1,
                  size: 60,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16.0),

                // Name Field
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم', // Name
                    hintText: 'أدخل اسمك', // Enter your name
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم'; // Please enter name
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني', // Email
                    hintText: 'أدخل بريدك الإلكتروني', // Enter your email
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني'; // Please enter email
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'الرجاء إدخال بريد إلكتروني صالح'; // Please enter a valid email
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور', // Password
                    hintText: 'أدخل كلمة المرور', // Enter your password
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور'; // Please enter password
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'; // Password must be at least 6 characters
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور', // Confirm Password
                    hintText: 'أعد إدخال كلمة المرور', // Re-enter your password
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء تأكيد كلمة المرور'; // Please confirm password
                    }
                    if (value != _passwordController.text) {
                      return 'كلمتا المرور غير متطابقتين'; // Passwords do not match
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // Sign Up Button
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _signUp, // Disable button when loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'إنشاء حساب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ), // Create Account
                ),
                const SizedBox(height: 20.0),

                // OR Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0),
                        height: 1.0,
                        color: Colors.grey.withAlpha(77), // ~0.3 opacity
                      ),
                    ),
                    Text(
                      'أو',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0),
                        height: 1.0,
                        color: Colors.grey.withAlpha(77), // ~0.3 opacity
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Social Login Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Changed from spaceEvenly to center
                  children: [
                    // Google Login Button
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7, // Adjusted width to be wider since it's the only button now
                      child: ElevatedButton.icon(
                        onPressed: _isGoogleLoading ? null : _signUpWithGoogle,
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: Colors.red,
                          size: 20,
                        ),
                        label:
                            _isGoogleLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black54,
                                    ),
                                  ),
                                )
                                : const Text('جوجل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Link to Login Screen
                TextButton(
                  onPressed: () {
                    // Navigate back to LoginScreen
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      // Fallback if it cannot pop (e.g., pushed directly)
                      // في حالة عدم القدرة على العودة، يمكن إضافة منطق بديل هنا
                      // مثل التنقل إلى شاشة تسجيل الدخول باستخدام pushReplacement
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium,
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'لديك حساب بالفعل؟ ',
                        ), // Already have an account?
                        TextSpan(
                          text: 'تسجيل الدخول', // Login
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
}
