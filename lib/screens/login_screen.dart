import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:rive/rive.dart'; // Import Rive
import '../providers/auth_provider.dart'; // Import AuthProvider
import 'signup_screen.dart'; // Import SignUpScreen for navigation
import '../providers/navigation_provider.dart'; // Import NavigationProvider
import 'main_navigation_screen.dart'; // Import MainNavigationScreen
// Import FontAwesome for social icons
import '../utils/animation_enum.dart'; // Import Animation Enum

// Custom page route transition
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
            const begin = Offset(1.0, 0.0); // Start off-screen to the right
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Add state for loading indicator
  bool _rememberMe = false; // Add state for remember me checkbox

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Rive animation variables
  Artboard? riveArtboard;
  late RiveAnimationController controllerIdle;
  late RiveAnimationController controllerHandsUp;
  late RiveAnimationController controllerHandsDown;
  late RiveAnimationController controllerLookLeft;
  late RiveAnimationController controllerLookRight;
  late RiveAnimationController controllerSuccess;
  late RiveAnimationController controllerFail;

  bool isLookingLeft = false;
  bool isLookingRight = false;

  void removeAllControllers() {
    riveArtboard?.artboard.removeController(controllerIdle);
    riveArtboard?.artboard.removeController(controllerHandsUp);
    riveArtboard?.artboard.removeController(controllerHandsDown);
    riveArtboard?.artboard.removeController(controllerLookLeft);
    riveArtboard?.artboard.removeController(controllerLookRight);
    riveArtboard?.artboard.removeController(controllerSuccess);
    riveArtboard?.artboard.removeController(controllerFail);
    isLookingLeft = false;
    isLookingRight = false;
  }

  void addSpecifcAnimationAction(RiveAnimationController controller) {
    removeAllControllers();
    riveArtboard?.artboard.addController(controller);
    debugPrint('Animation changed to: ${controller.toString()}');
  }

  void checkForPasswordFocusNodeToChangeAnimationState() {
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        addSpecifcAnimationAction(controllerHandsUp);
      } else if (!_passwordFocusNode.hasFocus) {
        addSpecifcAnimationAction(controllerHandsDown);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize UI animation controller
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

    // Initialize Rive animation controllers
    controllerIdle = SimpleAnimation(AnimationEnum.idle.name);
    controllerHandsUp = SimpleAnimation(AnimationEnum.Hands_up.name);
    controllerHandsDown = SimpleAnimation(AnimationEnum.hands_down.name);
    controllerLookRight = SimpleAnimation(AnimationEnum.Look_down_right.name);
    controllerLookLeft = SimpleAnimation(AnimationEnum.Look_down_left.name);
    controllerSuccess = SimpleAnimation(AnimationEnum.success.name);
    controllerFail = SimpleAnimation(AnimationEnum.fail.name);

    loadRiveFileWithItsStates();
    checkForPasswordFocusNodeToChangeAnimationState();
    
    // Start UI animations
    _animationController.forward();
  }

  void loadRiveFileWithItsStates() {
    rootBundle
        .load('assets/animations/login_animation.riv')
        .then((data) {
          final file = RiveFile.import(data);
          final artboard = file.mainArtboard;
          artboard.addController(controllerIdle);
          setState(() {
            riveArtboard = artboard;
          });
          debugPrint('Rive file loaded successfully');
        })
        .catchError((error) {
          debugPrint('Failed to load Rive file: $error');
          // محاولة تحميل الملف من مسار بديل
          rootBundle
              .load('assets/login_animation.riv')
              .then((data) {
                final file = RiveFile.import(data);
                final artboard = file.mainArtboard;
                artboard.addController(controllerIdle);
                setState(() {
                  riveArtboard = artboard;
                });
                debugPrint('Rive file loaded from alternative path');
              })
              .catchError((error) {
                debugPrint('Failed to load Rive file from all paths: $error');
              });
        });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.removeListener(() {});
    _animationController.dispose();
    super.dispose();
  }

  void validateEmailAndPassword() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_formKey.currentState!.validate()) {
        addSpecifcAnimationAction(controllerSuccess);

        // بعد نجاح التحقق، قم بتسجيل الدخول
        _performLogin();
      } else {
        addSpecifcAnimationAction(controllerFail);
      }
    });
  }

  // دالة لعرض شاشة منبثقة لإعادة تعيين كلمة المرور
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('إعادة تعيين كلمة المرور'),
                  content: Form(
                    key: resetFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: resetEmailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            hintText: 'أدخل بريدك الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال البريد الإلكتروني';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'الرجاء إدخال بريد إلكتروني صالح';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (resetFormKey.currentState?.validate() ??
                                    false) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    final authProvider =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );

                                    // استدعاء دالة إعادة تعيين كلمة المرور
                                    await authProvider.resetPassword(
                                      resetEmailController.text.trim(),
                                    );

                                    if (!context.mounted) return;

                                    // إغلاق الشاشة المنبثقة
                                    Navigator.of(context).pop();

                                    // عرض رسالة نجاح
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    // عرض رسالة خطأ
                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'حدث خطأ: ${e.toString()}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );

                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('إرسال'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _performLogin() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      bool success = await authProvider.signIn(email, password);

      // يمكن استخدام قيمة _rememberMe هنا لحفظ بيانات المستخدم للمرة القادمة
      if (_rememberMe) {
        debugPrint('تم تفعيل خيار تذكرني: سيتم حفظ بيانات المستخدم');
        // هنا يمكن إضافة كود لحفظ بيانات المستخدم باستخدام shared_preferences أو غيرها
      }

      if (!mounted) return; // Check if the widget is still mounted

      if (success) {
        // Set the navigation index to 'More' (index 4)
        Provider.of<NavigationProvider>(context, listen: false).setIndex(4);
        
        print("تسجيل الدخول بنجاح - الانتقال إلى الشاشة الرئيسية");
        
        // Navigate to the MainNavigationScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
          ),
        );
        
        // طلب التحقق من اكتمال الملف الشخصي بعد فترة قصيرة
        Future.delayed(const Duration(milliseconds: 500), () {
          MainNavigationScreen.checkProfileCompletion();
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تم تسجيل الدخول بنجاح. يمكنك إكمال بيانات ملفك الشخصي إذا لزم الأمر.',
            ),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        // Show error message on failure
        addSpecifcAnimationAction(controllerFail);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'فشل تسجيل الدخول. تحقق من بريدك الإلكتروني وكلمة المرور.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle potential errors during sign-in (e.g., network issues)
      if (mounted) {
        addSpecifcAnimationAction(controllerFail);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
          _isLoading = false; // Hide loading indicator
        });
      }
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
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
                    // Rive Animation
                    SizedBox(
                      height: 150,
                      child: riveArtboard == null
                          ? const Center(child: CircularProgressIndicator())
                          : Rive(artboard: riveArtboard!, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 8.0),

                    Text(
                      'مرحباً بك مجدداً',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'سجل دخولك للوصول إلى حسابك',
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32.0),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      decoration: _getInputDecoration(
                        labelText: 'البريد الإلكتروني',
                        hintText: 'أدخل بريدك الإلكتروني',
                        prefixIcon: Icons.email_outlined,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        if (value.isNotEmpty &&
                            value.length < 16 &&
                            !isLookingLeft) {
                          addSpecifcAnimationAction(controllerLookLeft);
                          isLookingLeft = true;
                          isLookingRight = false;
                        } else if (value.isNotEmpty &&
                            value.length > 16 &&
                            !isLookingRight) {
                          addSpecifcAnimationAction(controllerLookRight);
                          isLookingLeft = false;
                          isLookingRight = true;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'الرجاء إدخال بريد إلكتروني صالح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: !_isPasswordVisible,
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 8.0),

                    // Remember Me Checkbox and Forgot Password
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[100]!.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                                // Add haptic feedback
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                          Text(
                            'تذكرني',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              _showForgotPasswordDialog();
                              // Add haptic feedback
                              HapticFeedback.selectionClick();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Login Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: !_isLoading 
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
                        onPressed: _isLoading
                            ? null
                            : () {
                                // Add haptic feedback
                                HapticFeedback.mediumImpact();
                                _passwordFocusNode.unfocus();
                                validateEmailAndPassword();
                              },
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
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12.0),
                            height: 1.0,
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.withAlpha(77),
                          ),
                        ),
                        Text(
                          'أو',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12.0),
                            height: 1.0,
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.withAlpha(77),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // Google Login Button with updated design
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode 
                                ? Colors.black.withOpacity(0.2) 
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          // Add haptic feedback
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );

                            final success =
                                await authProvider.signInWithGoogle();

                            if (!mounted) return;

                            if (success) {
                              if (!mounted) return;

                              // Set the navigation index to 'More' (index 4)
                              final navProvider =
                                  Provider.of<NavigationProvider>(
                                    context,
                                    listen: false,
                                  );
                              navProvider.setIndex(4);

                              print("تسجيل الدخول بنجاح عبر جوجل - الانتقال إلى الشاشة الرئيسية");
                              
                              // Navigate to the MainNavigationScreen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const MainNavigationScreen(),
                                ),
                              );
                              
                              // طلب التحقق من اكتمال الملف الشخصي بعد فترة قصيرة
                              Future.delayed(const Duration(milliseconds: 500), () {
                                MainNavigationScreen.checkProfileCompletion();
                              });

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'تم تسجيل الدخول بنجاح عبر جوجل',
                                  ),
                                  backgroundColor: colorScheme.tertiary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            } else {
                              if (!mounted) return;

                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('فشل تسجيل الدخول عبر جوجل'),
                                  backgroundColor: colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            // Show error message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('حدث خطأ: ${e.toString()}'),
                                  backgroundColor: colorScheme.error,
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
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF303030) : Colors.white,
                          foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDarkMode ? Colors.white70 : colorScheme.primary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 24,
                                  width: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: isDarkMode ? [] : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      )
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Image.asset(
                                    'assets/icons/google.png',
                                    height: 20,
                                    width: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'متابعة باستخدام حساب جوجل',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Link to Sign Up Screen
                    TextButton(
                      onPressed: () {
                        // Add haptic feedback
                        HapticFeedback.lightImpact();
                        
                        // Navigate to SignUpScreen with custom transition
                        Navigator.of(context).push(
                          CustomPageRoute(
                            child: const SignUpScreen(),
                            settings: const RouteSettings(name: '/signup'),
                          ),
                        );
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
                              text: 'ليس لديك حساب؟ ',
                            ),
                            TextSpan(
                              text: 'إنشاء حساب جديد',
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