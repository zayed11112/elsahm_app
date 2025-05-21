import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom transition animation for banners
class BannerTransition extends PageRouteBuilder {
  final Widget page;
  final String heroTag;
  
  BannerTransition({required this.page, required this.heroTag})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = Curves.easeInOutCubic;
            var curveTween = CurveTween(curve: curve);
            
            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(animation.drive(curveTween));
            
            var scaleAnimation = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(animation.drive(curveTween));
            
            return Hero(
              tag: heroTag,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}

/// A custom carousel transition for banner sliders
class CustomBannerTransformer extends PageTransformer {
  final double scale;
  final double fade;
  
  CustomBannerTransformer({this.scale = 0.92, this.fade = 0.4});
  
  @override
  Widget transform(Widget child, TransformInfo info) {
    double position = info.position;
    double scaleFactor = (1 - position.abs()) * (1 - scale);
    double gauss = math.exp(-(math.pow((position.abs() - 0.5), 2) / 0.08));
    
    return Transform.scale(
      scale: scale + scaleFactor,
      child: Opacity(
        opacity: fade + (1 - fade) * gauss,
        child: child,
      ),
    );
  }
}

/// Stub class to make the above code compile without implementing the actual PageTransformer
abstract class PageTransformer {
  Widget transform(Widget child, TransformInfo info);
}

class TransformInfo {
  final double position;
  TransformInfo({required this.position});
} 