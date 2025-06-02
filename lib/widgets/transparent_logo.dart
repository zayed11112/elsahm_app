import 'package:flutter/material.dart';

class TransparentLogo extends StatelessWidget {
  final double height;
  final Color? color;

  const TransparentLogo({super.key, this.height = 110.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // الظل خلف اللوجو
        if (color == null)
          Container(
            height: height,
            width: height * 2.5,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(30),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

        // اللوجو نفسه
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors:
                  color != null
                      ? [color!, color!]
                      : [Colors.white, Colors.white],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Image.asset(
            'assets/images/logo_dark.webp',
            height: height,
            color: Colors.white, // استخدام اللون الأبيض كقناع
          ),
        ),

        // تأثير لمعان خفيف
        if (color == null)
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withAlpha(100),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Image.asset(
              'assets/images/logo_dark.webp',
              height: height,
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}
