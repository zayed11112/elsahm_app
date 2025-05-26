import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import 'main_navigation_screen.dart';
import 'privacy_policy_screen.dart';
import 'login_screen.dart';

// Import custom page route
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final RouteSettings settings;
  final bool rightToLeft;

  CustomPageRoute({
    required this.child,
    required this.settings,
    this.rightToLeft = true,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final begin = rightToLeft ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  static final Logger _logger = Logger('SignUpScreen');
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Add haptic feedback when submitting
      HapticFeedback.mediumImpact();
      
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      bool success = false;
      try {
        success = await authProvider.signUp(email, password);
        // No need to update profile with name since we removed that field
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }

      if (success && mounted) {
        navProvider.setIndex(4);
        _logger.info("تم إنشاء الحساب بنجاح - الانتقال إلى الشاشة الرئيسية");

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false, // Remove all previous routes
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          MainNavigationScreen.checkProfileCompletion();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تم إنشاء الحساب بنجاح!',
            ),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'فشل إنشاء الحساب. قد يكون البريد الإلكتروني مستخدماً بالفعل.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      // Add haptic feedback for invalid form
      HapticFeedback.lightImpact();
    }
  }

  // Custom input decoration
  InputDecoration _getInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey[800] 
          : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.background : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: isDarkMode ? Colors.white70 : Colors.grey),
          onPressed: () {
            // Add haptic feedback
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'إنشاء حساب جديد',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Icon with container
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: isDarkMode ? colorScheme.primary.withOpacity(0.2) : colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_alt_1,
                        size: 50,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: _getInputDecoration(
                        labelText: 'البريد الإلكتروني',
                        hintText: 'أدخل بريدك الإلكتروني',
                        prefixIcon: Icons.email_outlined,
                      ),
                      maxLength: 50,
                      buildCounter: (BuildContext context, {required int currentLength, required bool isFocused, required int? maxLength}) {
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'الرجاء إدخال بريد إلكتروني صالح';
                        }
                        if (value.length > 50) {
                          return 'البريد الإلكتروني لا يمكن أن يتجاوز 50 حرف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      maxLength: 50,
                      buildCounter: (BuildContext context, {required int currentLength, required bool isFocused, required int? maxLength}) {
                        return null;
                      },
                      decoration: _getInputDecoration(
                        labelText: 'كلمة المرور',
                        hintText: 'أدخل كلمة المرور',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
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
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        if (value.length > 50) {
                          return 'كلمة المرور لا يمكن أن تتجاوز 50 حرف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      maxLength: 50,
                      buildCounter: (BuildContext context, {required int currentLength, required bool isFocused, required int? maxLength}) {
                        return null;
                      },
                      decoration: _getInputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        hintText: 'أعد إدخال كلمة المرور',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: isDarkMode ? Colors.white70 : Colors.grey,  
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء تأكيد كلمة المرور';
                        }
                        if (value != _passwordController.text) {
                          return 'كلمتا المرور غير متطابقتين';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20.0),

                    // Terms and Conditions Checkbox with Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: _agreeToTerms,
                              activeColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                });
                                // Add haptic feedback
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                  children: <TextSpan>[
                                    const TextSpan(
                                      text: 'أوافق على ',
                                    ),
                                    TextSpan(
                                      text: 'شروط الاستخدام  ',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
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
                    const SizedBox(height: 24.0),

                    // Sign Up Button with elevated design
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _agreeToTerms && !_isLoading 
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                      ),
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_agreeToTerms)
                            ? null
                            : _signUp, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDarkMode 
                              ? Colors.grey[700] 
                              : Colors.grey[300],
                          disabledForegroundColor: isDarkMode 
                              ? Colors.grey[500] 
                              : Colors.grey[500],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDarkMode ? colorScheme.primary : Colors.white,
                                ),
                              )
                            : const Text(
                                'إنشاء حساب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Link to Login Screen with improved design
                    TextButton(
                      onPressed: () {
                        // Add haptic feedback
                        HapticFeedback.selectionClick();
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          // Use custom transition when replacing the route
                          Navigator.of(context).pushReplacement(
                            CustomPageRoute(
                              child: const LoginScreen(),
                              settings: const RouteSettings(name: '/login'),
                              rightToLeft: false, // Right to left for going back to login
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          children: <TextSpan>[
                            const TextSpan(
                              text: 'لديك حساب بالفعل؟ ',
                            ),
                            TextSpan(
                              text: 'تسجيل الدخول',
                              style: TextStyle(
                                color: colorScheme.secondary,
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
        ),
      ),
    );
  }
}
