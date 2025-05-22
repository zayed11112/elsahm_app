import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:rive/rive.dart'; // Import Rive
import '../providers/auth_provider.dart'; // Import AuthProvider
import 'signup_screen.dart'; // Import SignUpScreen for navigation
import '../providers/navigation_provider.dart'; // Import NavigationProvider
import 'main_navigation_screen.dart'; // Import MainNavigationScreen
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome for social icons
import '../utils/animation_enum.dart'; // Import Animation Enum

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Add state for loading indicator
  bool _rememberMe = false; // Add state for remember me checkbox

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
    controllerIdle = SimpleAnimation(AnimationEnum.idle.name);
    controllerHandsUp = SimpleAnimation(AnimationEnum.Hands_up.name);
    controllerHandsDown = SimpleAnimation(AnimationEnum.hands_down.name);
    controllerLookRight = SimpleAnimation(AnimationEnum.Look_down_right.name);
    controllerLookLeft = SimpleAnimation(AnimationEnum.Look_down_left.name);
    controllerSuccess = SimpleAnimation(AnimationEnum.success.name);
    controllerFail = SimpleAnimation(AnimationEnum.fail.name);

    loadRiveFileWithItsStates();
    checkForPasswordFocusNodeToChangeAnimationState();
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
          MaterialPageRoute(builder: (context) => MainNavigationScreen()),
        );
        
        // طلب التحقق من اكتمال الملف الشخصي بعد فترة قصيرة
        Future.delayed(const Duration(milliseconds: 500), () {
          MainNavigationScreen.checkProfileCompletion();
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تسجيل الدخول بنجاح. يمكنك إكمال بيانات ملفك الشخصي إذا لزم الأمر.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message on failure
        addSpecifcAnimationAction(controllerFail);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'فشل تسجيل الدخول. تحقق من بريدك الإلكتروني وكلمة المرور.',
            ),
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          // Allows scrolling if content overflows
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Rive Animation - Reduced height to move content up
                SizedBox(
                  height: 150, // Reduced from 200 to move content up
                  child:
                      riveArtboard == null
                          ? const Center(child: CircularProgressIndicator())
                          : Rive(artboard: riveArtboard!, fit: BoxFit.contain),
                ),
                const SizedBox(height: 8.0), // Reduced spacing

                Text(
                  'مرحباً بك مجدداً', // Welcome back
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'سجل دخولك للوصول إلى حسابك', // Log in to access your account
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني', // Email
                    hintText: 'أدخل بريدك الإلكتروني', // Enter your email
                    prefixIcon: Icon(Icons.email_outlined),
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
                  focusNode: _passwordFocusNode,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور', // Password (Corrected spelling)
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
                    // Add more password validation if needed (e.g., length)
                    return null;
                  },
                ),
                const SizedBox(height: 8.0),

                // Remember Me Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: colorScheme.primary,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text('تذكرني'), // Remember me
                    const Spacer(),
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text(
                        'نسيت كلمة المرور؟',
                      ), // Forgot password?
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Login Button
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            _passwordFocusNode.unfocus();
                            validateEmailAndPassword();
                          },
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
                            // Show progress indicator when loading
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ), // Login
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
                        onPressed: () async {
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
                                      (context) => MainNavigationScreen(),
                                ),
                              );
                              
                              // طلب التحقق من اكتمال الملف الشخصي بعد فترة قصيرة
                              Future.delayed(const Duration(milliseconds: 500), () {
                                MainNavigationScreen.checkProfileCompletion();
                              });

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'تم تسجيل الدخول بنجاح عبر جوجل',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              if (!mounted) return;

                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('فشل تسجيل الدخول عبر جوجل'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            // Show error message
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
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: Colors.red,
                          size: 20,
                        ),
                        label: const Text('جوجل'),
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

                // Link to Sign Up Screen
                TextButton(
                  onPressed: () {
                    // Navigate to SignUpScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium,
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'ليس لديك حساب؟ ',
                        ), // Don't have an account?
                        TextSpan(
                          text: 'إنشاء حساب جديد', // Create new account
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
