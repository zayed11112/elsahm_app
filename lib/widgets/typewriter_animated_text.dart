import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterAnimatedText extends StatefulWidget {
  final List<String> texts;
  final TextStyle? textStyle;
  final Duration typingSpeed;
  final Duration pauseDuration;
  final Duration deletingSpeed;
  final TextAlign textAlign;

  const TypewriterAnimatedText({
    super.key,
    required this.texts,
    this.textStyle,
    this.typingSpeed = const Duration(milliseconds: 70),
    this.pauseDuration = const Duration(seconds: 1),
    this.deletingSpeed = const Duration(milliseconds: 15),
    this.textAlign = TextAlign.center,
  });

  @override
  TypewriterAnimatedTextState createState() => TypewriterAnimatedTextState();
}

class TypewriterAnimatedTextState extends State<TypewriterAnimatedText> {
  late String _currentText;
  late int _currentIndex;
  late int _currentPosition;
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _currentPosition = 0;
    _currentText = '';
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      setState(() {
        if (!_isDeleting) {
          // نضيف حرف واحد في كل مرة
          final targetText = widget.texts[_currentIndex];
          if (_currentPosition < targetText.length) {
            _currentText = targetText.substring(0, _currentPosition + 1);
            _currentPosition++;
          } else {
            // تم الانتهاء من الكتابة - ننتظر قبل بدء المسح
            _isDeleting = false;
            _timer?.cancel();
            _timer = Timer(widget.pauseDuration, () {
              if (mounted) {
                setState(() {
                  _isDeleting = true;
                });
                _startDeleting();
              }
            });
          }
        }
      });
    });
  }

  void _startDeleting() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.deletingSpeed, (timer) {
      setState(() {
        if (_isDeleting) {
          if (_currentPosition > 0) {
            _currentPosition--;
            _currentText = widget.texts[_currentIndex].substring(
              0,
              _currentPosition,
            );
          } else {
            // تم مسح النص - الانتقال إلى النص التالي
            _isDeleting = false;
            _currentIndex = (_currentIndex + 1) % widget.texts.length;
            _timer?.cancel();
            _startTyping();
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _currentText,
        style: widget.textStyle ?? Theme.of(context).textTheme.titleMedium,
        textAlign: widget.textAlign,
      ),
    );
  }
}
