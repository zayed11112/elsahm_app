import 'package:flutter/material.dart';

/// زر تحديث احترافي مع أنيميشن متحرك
class RefreshButton extends StatefulWidget {
  /// الدالة التي سيتم تنفيذها عند النقر
  final VoidCallback onPressed;

  /// نص الزر (اختياري)
  final String? text;

  /// لون خلفية الزر (اختياري)
  final Color? backgroundColor;

  /// لون النص (اختياري)
  final Color? textColor;

  /// حجم الزر (اختياري)
  final Size? size;

  /// سماكة الخط (اختياري)
  final FontWeight? fontWeight;

  /// مؤشر ما إذا كان في حالة تحميل
  final bool isLoading;

  const RefreshButton({
    super.key,
    required this.onPressed,
    this.text = 'تحديث',
    this.backgroundColor,
    this.textColor,
    this.size,
    this.fontWeight = FontWeight.bold,
    this.isLoading = false,
  });

  @override
  State<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ألوان الزر
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final textColor = widget.textColor ?? Colors.white;

    // حجم الزر
    final defaultSize = const Size(120, 44);
    final size = widget.size ?? defaultSize;

    // بناء الزر
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onPressed,
        onHover: (value) {
          setState(() {
            _isHovering = value;
            if (value) {
              _controller.repeat();
            } else {
              _controller.stop();
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color:
                widget.isLoading || _isHovering
                    ? backgroundColor.withValues(alpha: 0.85)
                    : backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.3),
                blurRadius: _isHovering ? 8 : 4,
                offset: const Offset(0, 2),
                spreadRadius: _isHovering ? 1 : 0,
              ),
            ],
            gradient:
                _isHovering
                    ? LinearGradient(
                      colors: [
                        backgroundColor,
                        backgroundColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة التحديث مع أنيميشن
                  widget.isLoading
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      )
                      : AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle:
                                _isHovering
                                    ? _controller.value * 2 * 3.14159
                                    : 0,
                            child: Icon(
                              Icons.refresh,
                              color: textColor,
                              size: 20,
                            ),
                          );
                        },
                      ),
                  if (widget.text != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.text!,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: widget.fontWeight,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
