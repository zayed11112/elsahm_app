import 'package:flutter/material.dart';

/// Widget للنص المتحرك (Marquee Text)
class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration pauseDuration;
  final double velocity;
  final bool startAfter;
  final int maxLines;

  const ScrollingText({
    Key? key,
    required this.text,
    this.style,
    this.duration = const Duration(seconds: 3),
    this.pauseDuration = const Duration(seconds: 1),
    this.velocity = 50.0,
    this.startAfter = true,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ScrollController _scrollController;
  bool _needsScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollingNeeded();
    });
  }

  void _checkIfScrollingNeeded() {
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      if (maxScrollExtent > 0) {
        setState(() {
          _needsScrolling = true;
        });
        if (widget.startAfter) {
          _startScrolling();
        }
      }
    }
  }

  void _startScrolling() async {
    if (!_needsScrolling || !mounted) return;

    await Future.delayed(widget.pauseDuration);
    if (!mounted) return;

    _controller.repeat(reverse: true);
    
    _animation.addListener(() {
      if (_scrollController.hasClients && mounted) {
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        final targetOffset = maxScrollExtent * _animation.value;
        _scrollController.jumpTo(targetOffset);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
            ),
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: widget.maxLines,
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
          ),
        );
      },
    );
  }
}

/// Widget مبسط للنص المتحرك
class SimpleScrollingText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final Duration animationDuration;

  const SimpleScrollingText({
    Key? key,
    required this.text,
    this.style,
    this.maxLines = 1,
    this.animationDuration = const Duration(seconds: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: maxLines,
          textDirection: TextDirection.rtl,
        );
        textPainter.layout(maxWidth: double.infinity);

        final textWidth = textPainter.size.width;
        final containerWidth = constraints.maxWidth;

        // إذا كان النص أقصر من العرض المتاح، اعرضه عادي
        if (textWidth <= containerWidth) {
          return Text(
            text,
            style: style,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          );
        }

        // إذا كان النص أطول، استخدم التحريك
        return ScrollingText(
          text: text,
          style: style,
          maxLines: maxLines,
          duration: animationDuration,
          pauseDuration: const Duration(seconds: 2),
        );
      },
    );
  }
}
