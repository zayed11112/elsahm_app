import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// مكون مخصص لعرض الصور مع قطع الجزء السفلي (حيث يوجد شريط حقوق النشر)
class CroppedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double bottomCropPercentage; // نسبة القطع من أسفل الصورة
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? height;
  final double? width;

  const CroppedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.bottomCropPercentage = 0.08, // قطع 8% من أسفل الصورة افتراضياً
    this.placeholder,
    this.errorWidget,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      // استخدام ClipRect مع CustomClipper لقطع الجزء السفلي من الصورة
      clipper: BottomCropClipper(bottomCropPercentage: bottomCropPercentage),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        height: height,
        width: width,
        placeholder: (context, url) => placeholder ?? 
          Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
        errorWidget: (context, url, error) => errorWidget ?? 
          Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          ),
      ),
    );
  }
}

/// مخصص قطع الصور من الأسفل
class BottomCropClipper extends CustomClipper<Rect> {
  final double bottomCropPercentage;

  BottomCropClipper({required this.bottomCropPercentage});

  @override
  Rect getClip(Size size) {
    // إنشاء مستطيل يقطع الجزء السفلي من الصورة
    return Rect.fromLTRB(
      0, 
      0, 
      size.width, 
      size.height * (1 - bottomCropPercentage)
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
} 