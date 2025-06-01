import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/theme.dart';
import '../extensions/theme_extensions.dart';

/// Enhanced Text Field with modern design
class EnhancedTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const EnhancedTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: fastAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _borderColorAnimation = ColorTween(
      begin: Colors.grey.shade300,
      end: primaryBlue,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
    if (hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: context.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        _isFocused
                            ? primaryBlue
                            : (isDarkMode
                                ? darkTextSecondary
                                : lightTextSecondary),
                  ),
                ),
                const SizedBox(height: smallPadding),
              ],

              // Text Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(defaultBorderRadius),
                  boxShadow: _isFocused ? lightShadow : [],
                ),
                child: Focus(
                  onFocusChange: _onFocusChange,
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    onChanged: widget.onChanged,
                    onFieldSubmitted: widget.onSubmitted,
                    validator: widget.validator,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    maxLines: widget.maxLines,
                    maxLength: widget.maxLength,
                    enabled: widget.enabled,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
                    textCapitalization: widget.textCapitalization,
                    style: TextStyle(
                      color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        color:
                            isDarkMode ? darkTextTertiary : lightTextTertiary,
                      ),
                      prefixIcon: widget.prefixIcon,
                      suffixIcon: widget.suffixIcon,
                      filled: true,
                      fillColor: isDarkMode ? darkCard : lightCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          defaultBorderRadius,
                        ),
                        borderSide: BorderSide(
                          color:
                              isDarkMode ? darkTextTertiary : lightTextTertiary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          defaultBorderRadius,
                        ),
                        borderSide: BorderSide(
                          color:
                              isDarkMode ? darkTextTertiary : lightTextTertiary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          defaultBorderRadius,
                        ),
                        borderSide: BorderSide(
                          color: _borderColorAnimation.value ?? primaryBlue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          defaultBorderRadius,
                        ),
                        borderSide: const BorderSide(
                          color: errorColor,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          defaultBorderRadius,
                        ),
                        borderSide: const BorderSide(
                          color: errorColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: defaultPadding,
                        vertical: defaultPadding,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Enhanced Dropdown Field
class EnhancedDropdownField<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final bool enabled;

  const EnhancedDropdownField({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  State<EnhancedDropdownField<T>> createState() =>
      _EnhancedDropdownFieldState<T>();
}

class _EnhancedDropdownFieldState<T> extends State<EnhancedDropdownField<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: fastAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: context.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        _isFocused
                            ? primaryBlue
                            : (isDarkMode
                                ? darkTextSecondary
                                : lightTextSecondary),
                  ),
                ),
                const SizedBox(height: smallPadding),
              ],

              // Dropdown
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(defaultBorderRadius),
                  boxShadow: _isFocused ? lightShadow : [],
                ),
                child: DropdownButtonFormField<T>(
                  value: widget.value,
                  items: widget.items,
                  onChanged: widget.enabled ? widget.onChanged : null,
                  validator: widget.validator,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: isDarkMode ? darkTextTertiary : lightTextTertiary,
                    ),
                    prefixIcon: widget.prefixIcon,
                    filled: true,
                    fillColor: isDarkMode ? darkCard : lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultBorderRadius),
                      borderSide: BorderSide(
                        color:
                            isDarkMode ? darkTextTertiary : lightTextTertiary,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultBorderRadius),
                      borderSide: BorderSide(
                        color:
                            isDarkMode ? darkTextTertiary : lightTextTertiary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultBorderRadius),
                      borderSide: const BorderSide(
                        color: primaryBlue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding,
                      vertical: defaultPadding,
                    ),
                  ),
                  dropdownColor: isDarkMode ? darkCard : lightCard,
                  style: TextStyle(
                    color: isDarkMode ? darkTextPrimary : lightTextPrimary,
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: isDarkMode ? darkTextSecondary : lightTextSecondary,
                  ),
                  onTap: () {
                    setState(() => _isFocused = true);
                    _animationController.forward();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Enhanced Checkbox with label
class EnhancedCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool?)? onChanged;
  final bool enabled;

  const EnhancedCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return InkWell(
      borderRadius: BorderRadius.circular(smallBorderRadius),
      onTap: enabled ? () => onChanged?.call(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: smallPadding),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: primaryBlue,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: smallPadding),
            Expanded(
              child: Text(
                label,
                style: context.bodyMedium?.copyWith(
                  color:
                      enabled
                          ? (isDarkMode ? darkTextPrimary : lightTextPrimary)
                          : (isDarkMode ? darkTextTertiary : lightTextTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Radio Button with label
class EnhancedRadio<T> extends StatelessWidget {
  final String label;
  final T value;
  final T? groupValue;
  final Function(T?)? onChanged;
  final bool enabled;

  const EnhancedRadio({
    super.key,
    required this.label,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return InkWell(
      borderRadius: BorderRadius.circular(smallBorderRadius),
      onTap: enabled ? () => onChanged?.call(value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: smallPadding),
        child: Row(
          children: [
            Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: enabled ? onChanged : null,
              activeColor: primaryBlue,
            ),
            const SizedBox(width: smallPadding),
            Expanded(
              child: Text(
                label,
                style: context.bodyMedium?.copyWith(
                  color:
                      enabled
                          ? (isDarkMode ? darkTextPrimary : lightTextPrimary)
                          : (isDarkMode ? darkTextTertiary : lightTextTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
