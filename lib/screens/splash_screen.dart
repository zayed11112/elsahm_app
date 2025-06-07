import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:elsahm_app/screens/main_navigation_screen.dart';
import 'package:elsahm_app/main.dart' show MainScreenExitConfirmationWrapper;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger('SplashScreen');
  String _displayedSlogan = "";
  final String _fullSlogan = "احجز ....أوفر أسهل أسرع";
  int _currentCharIndex = 0;
  Timer? _typingTimer;
  Timer? _navigationTimer;

  // أنيميشن الظهور والخروج
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;
  late AnimationController _slideController;

  // تم إزالة مشغل الصوت لتحسين الأداء

  // تحميل التطبيق في الخلفية
  bool _isAppLoaded = false;
  final int _splashDurationSeconds = 4; // تقليل المدة لتحسين UX

  // Easter Egg Variables
  bool _easterEggActivated = false;
  int _logoTapCount = 0;
  final int _tapsToActivate = 3;
  final List<Color> _partyColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];
  Timer? _colorTimer;
  Color _currentColor = Colors.white;

  bool _showSecretMessage = false;

  @override
  void initState() {
    super.initState();

    // بدء تحميل التطبيق في الخلفية
    _loadAppInBackground();

    // إعداد أنيميشن التلاشي - تم تبسيط المدة
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // إعداد أنيميشن التكبير والتصغير - تم تبسيط المنحنى
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.1), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    // إعداد أنيميشن الدوران - تم تبسيط المنحنى
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05, // دوران بسيط فقط للتأثير
    ).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    // إعداد أنيميشن الانزلاق - تم تبسيط المنحنى
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // تشغيل الأنيميشن بالتتابع
    _startLogoAnimation();

    _startTypingAnimation();
    _scheduleNavigation();
  }

  // دالة لتشغيل أنيميشن اللوجو بالتتابع - تم تبسيطها
  void _startLogoAnimation() {
    // تشغيل جميع الأنيميشن بالتتابع بطريقة أكثر استقرارًا
    Future.microtask(() {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();

        // تأخير قصير قبل تشغيل أنيميشن التكبير
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _scaleController.forward();
          }
        });

        // تشغيل أنيميشن الدوران قبل الانتهاء
        Future.delayed(
          Duration(milliseconds: (_splashDurationSeconds * 1000) - 800),
          () {
            if (mounted && !_easterEggActivated) {
              _rotateController.forward();
            }
          },
        );
      }
    });
  }

  // دالة لتحميل التطبيق في الخلفية - تم تحسينها
  Future<void> _loadAppInBackground() async {
    // استخدام compute أو isolate للعمليات الثقيلة إذا لزم الأمر

    try {
      // تقليل مدة التحميل لتجنب التجميد
      await Future.delayed(Duration(seconds: _splashDurationSeconds - 1));

      if (mounted) {
        setState(() {
          _isAppLoaded = true;
        });

        // التحقق من حالة المصادقة بعد اكتمال التحميل
        _checkAuthState();
      }
    } catch (e) {
      // التعامل مع الأخطاء
      _logger.severe('Error loading app: $e');
      if (mounted) {
        setState(() {
          _isAppLoaded = true; // نضمن الانتقال حتى في حالة حدوث خطأ
        });
      }
    }
  }

  void _startTypingAnimation() {
    const typingSpeed = Duration(milliseconds: 90); // أسرع قليلاً
    const pauseBetweenLoops = Duration(milliseconds: 400);

    _typingTimer = Timer.periodic(typingSpeed, (timer) {
      if (_currentCharIndex < _fullSlogan.length) {
        setState(() {
          _displayedSlogan += _fullSlogan[_currentCharIndex];
          _currentCharIndex++;
        });
      } else {
        // عند الانتهاء من كتابة النص بالكامل
        timer.cancel();

        // انتظر قليلاً ثم ابدأ من جديد
        Future.delayed(pauseBetweenLoops, () {
          if (mounted) {
            setState(() {
              _displayedSlogan = "";
              _currentCharIndex = 0;
            });

            // إعادة تشغيل الحلقة إذا كانت شاشة البداية لا تزال ظاهرة
            if (!_isAppLoaded) {
              _startTypingAnimation();
            }
          }
        });
      }
    });
  }

  void _scheduleNavigation() {
    // تعيين مؤقت للانتقال بعد مدة محددة (8 ثواني)
    _navigationTimer = Timer(Duration(seconds: _splashDurationSeconds), () {
      if (mounted && !_easterEggActivated) {
        // الانتقال فقط إذا كان التطبيق جاهزًا
        if (_isAppLoaded) {
          _navigateToMainScreen();
        } else {
          // إذا لم يكتمل التحميل بعد، انتظر حتى يكتمل
          setState(() {
            // تحديث واجهة المستخدم لإظهار أن التطبيق لا يزال يتم تحميله
          });
        }
      }
    });
  }

  void _triggerEasterEgg() {
    // Cancel navigation timer
    _navigationTimer?.cancel();

    setState(() {
      _easterEggActivated = true;
      _showSecretMessage = true;
    });

    // Start color cycling
    _colorTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _currentColor = _partyColors[Random().nextInt(_partyColors.length)];
        });
      }
    });

    // Reset after 3 seconds and continue to main screen
    Timer(const Duration(seconds: 3), () {
      _colorTimer?.cancel();
      if (mounted) {
        if (_isAppLoaded) {
          _navigateToMainScreen();
        } else {
          // إذا لم يكتمل التحميل بعد، انتظر حتى يكتمل
          _scheduleNavigation();
        }
      }
    });
  }

  void _handleLogoTap() {
    setState(() {
      _logoTapCount++;
      if (_logoTapCount >= _tapsToActivate && !_easterEggActivated) {
        _triggerEasterEgg();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _navigationTimer?.cancel();
    _colorTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _slideController.dispose();
    // _audioPlayer.dispose(); // تم إزالة مشغل الصوت
    super.dispose();
  }

  // إيقاف جميع الأنيميشن عند الانتقال إلى الشاشة التالية
  void _stopAnimations() {
    _typingTimer?.cancel();
    _fadeController.stop();
    _scaleController.stop();
    _rotateController.stop();
    _slideController.stop();
    // تم إزالة إيقاف مشغل الصوت
  }

  Future<void> _checkAuthState() async {
    // التحقق أولاً مما إذا كان الـ widget لا يزال مثبتًا
    if (!mounted) return;

    // تم إزالة التحقق من حالة المصادقة لأنه غير مستخدم حاليًا

    // تعيين حالة التحميل إلى مكتمل
    setState(() {
      _isAppLoaded = true;
    });
  }

  // دالة للانتقال إلى الشاشة الرئيسية
  void _navigateToMainScreen() {
    if (!mounted) return;

    // إيقاف جميع الحلقات قبل الانتقال
    _stopAnimations();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => const MainScreenExitConfirmationWrapper(
              child: MainNavigationScreen(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrond_app.webp'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Add a subtle overlay for better text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Subtle background pattern (optional but keeps the existing style)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: GridPainter()),
              ),
            ),

            // Centered Logo and Loading Text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // الشعار مع أنيميشن مميز
                  GestureDetector(
                    onTap: _handleLogoTap,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: RotationTransition(
                        turns: _rotateAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            height: 150,
                            width: 150,
                            child: Image.asset(
                              'assets/images/logo_new.webp',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Animated Slogan Text
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: _easterEggActivated ? _currentColor : Colors.white,
                      fontFamily: 'Cairo',
                      shadows: [
                        Shadow(
                          color:
                              _easterEggActivated
                                  ? _currentColor.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _displayedSlogan,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),

                  // Secret Easter Egg Message
                  if (_showSecretMessage)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        "🎉 مفاجأة سعيدة! 🎉",
                        style: TextStyle(
                          color: _currentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Loading Indicator - Enhanced
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child:
                          _easterEggActivated
                              ? RotationTransition(
                                turns: Tween(begin: 0.0, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: AnimationController(
                                      duration: const Duration(seconds: 1),
                                      vsync: this,
                                    )..repeat(),
                                    curve: Curves.linear,
                                  ),
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: _currentColor,
                                  size: 24,
                                ),
                              )
                              : CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Hotline Information - Improved
            Positioned(
              bottom: 30.0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    "رقم التواصل",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.0,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w500,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),

                  // Phone number with subtle glow
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_android,
                          color:
                              _easterEggActivated
                                  ? _currentColor
                                  : Colors.white,
                          size: 18.0,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "01093130120",
                          style: TextStyle(
                            color:
                                _easterEggActivated
                                    ? _currentColor
                                    : Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            letterSpacing: 1.1,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
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

// Background grid pattern
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 0.5;

    const spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// تأثيرات الإضاءة في الخلفية
class LightEffectPainter extends CustomPainter {
  final double progress;

  LightEffectPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // رسم تأثيرات الإضاءة المتحركة
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.blue.withValues(alpha: 0.7 * progress),
              Colors.lightBlue.withValues(alpha: 0.5 * progress),
              Colors.transparent,
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.width * progress, size.height / 2),
              width: size.width * 0.8,
              height: size.height * 2,
            ),
          );

    // رسم مسار الضوء
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // إضافة نقاط ضوء متوهجة
    final sparkPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8 * progress)
          ..style = PaintingStyle.fill;

    // رسم نقاط الضوء المتوهجة
    final random = Random(42); // ثابت للحصول على نفس النمط في كل مرة
    for (int i = 0; i < 20; i++) {
      final x = size.width * (progress * 1.2 - 0.2 + random.nextDouble() * 0.2);
      final y = size.height * random.nextDouble();
      final radius = 1.0 + random.nextDouble() * 2.0;

      if (x > 0 && x < size.width) {
        canvas.drawCircle(Offset(x, y), radius, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LightEffectPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
