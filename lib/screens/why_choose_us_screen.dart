import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class WhyChooseUsScreen extends StatefulWidget {
  const WhyChooseUsScreen({super.key});

  @override
  State<WhyChooseUsScreen> createState() => _WhyChooseUsScreenState();
}

class _WhyChooseUsScreenState extends State<WhyChooseUsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Feature> features = [
    Feature(
      title: 'خبرة تثق بها',
      description:
          'نعرف سوق العريش من الداخل، ونوجهك بكل دقة نحو الخيار الأنسب لك.',
      animationPath: 'assets/animations/experience.json',
      icon: Icons.verified_user_outlined,
      color: Colors.blue,
    ),
    Feature(
      title: 'تشكيلة مميزة',
      description:
          'شقق، محلات، ومساحات استثمارية تناسب كل الأذواق والميزانيات.',
      animationPath: 'assets/animations/selection.json',
      icon: Icons.apps,
      color: Colors.orange,
    ),
    Feature(
      title: 'سرعة واحترافية',
      description: 'نلبي طلبك بسرعة واحترافية تستحقها.',
      animationPath: 'assets/animations/speed.json',
      icon: Icons.speed_outlined,
      color: Colors.green,
    ),
    Feature(
      title: 'ضمان ورعاية',
      description: 'نقدم لك خدمة ما بعد البيع والتأجير، ونضمن حقوقك دائماً.',
      animationPath: 'assets/animations/guarantee.json',
      icon: Icons.shield_outlined,
      color: Colors.purple,
    ),
    Feature(
      title: 'سهولة التواصل',
      description: 'فريقنا متاح دائماً للتواصل والرد على استفساراتك.',
      animationPath: 'assets/animations/communication.json',
      icon: Icons.support_agent,
      color: Colors.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لماذا تختار شركة السهم؟'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background animated pattern
          _buildBackgroundPattern(isDark),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(theme, isDark),

                // Features list
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      // Create staggered animation effect
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final delayedAnimation = Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: Interval(
                                (index * 0.02).clamp(0.0, 0.1),
                                ((index * 0.02) + 0.1).clamp(0.05, 0.3),
                                curve: Curves.fastOutSlowIn,
                              ),
                            ),
                          );
                          return FadeTransition(
                            opacity: delayedAnimation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.1, 0),
                                end: Offset.zero,
                              ).animate(delayedAnimation),
                              child: child,
                            ),
                          );
                        },
                        child: _buildFeatureCard(
                          feature: features[index],
                          theme: theme,
                          isDark: isDark,
                          index: index,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern(bool isDark) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: BackgroundPatternPainter(
              animation: _controller,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDark
                  ? [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ]
                  : [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'لماذا نحن الخيار الأمثل؟',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'نسعى دائماً لتقديم أفضل الخدمات العقارية في مدينة العريش',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required Feature feature,
    required ThemeData theme,
    required bool isDark,
    required int index,
  }) {
    final isEven = index.isEven;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: isEven ? Alignment.topLeft : Alignment.topRight,
              end: isEven ? Alignment.bottomRight : Alignment.bottomLeft,
              colors:
                  isDark
                      ? [
                        theme.cardColor,
                        theme.cardColor.withValues(alpha: 0.95),
                      ]
                      : [Colors.white, Colors.white],
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isEven) _buildFeatureImage(feature, isDark),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: feature.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                feature.icon,
                                color: feature.color,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          feature.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isEven) _buildFeatureImage(feature, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureImage(Feature feature, bool isDark) {
    // Try to load the Lottie animation, but fallback to icon if not available
    return Expanded(
      flex: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color:
              isDark ? Colors.black12 : feature.color.withValues(alpha: 0.05),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<bool>(
                // Simple check if animation exists - in a real app you'd handle this differently
                future: Future.delayed(Duration.zero, () => true),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!) {
                    try {
                      return Lottie.asset(
                        feature.animationPath,
                        // Fallback to icon if animation doesn't exist or fails to load
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              feature.icon,
                              size: 60,
                              color: feature.color,
                            ),
                      );
                    } catch (e) {
                      return Icon(feature.icon, size: 60, color: feature.color);
                    }
                  } else {
                    return Icon(feature.icon, size: 60, color: feature.color);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Class to hold feature data
class Feature {
  final String title;
  final String description;
  final String animationPath;
  final IconData icon;
  final Color color;

  Feature({
    required this.title,
    required this.description,
    required this.animationPath,
    required this.icon,
    required this.color,
  });
}

// Custom painter for animated background pattern
class BackgroundPatternPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;

  BackgroundPatternPainter({required this.animation, required this.isDark})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withValues(
            alpha: 0.02,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw animated circles
    for (int i = 1; i <= 8; i++) {
      final progress = (animation.value + i * 0.1) % 1.0;
      final radius = progress * size.width * 0.8;

      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }

    // Draw crossing lines
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi + animation.value * math.pi;
      final x1 = centerX + math.cos(angle) * size.width;
      final y1 = centerY + math.sin(angle) * size.height;
      final x2 = centerX + math.cos(angle + math.pi) * size.width;
      final y2 = centerY + math.sin(angle + math.pi) * size.height;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => true;
}
