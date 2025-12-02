import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Animated TextField with smooth color transitions on focus/cursor changes
class AnimatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Color? primaryColor;
  final Color? secondaryColor;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? style;
  final bool useGradientIcon;

  const AnimatedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.primaryColor,
    this.secondaryColor,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
    this.useGradientIcon = true,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _colorController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Color?> _glowColorAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final primaryColor = widget.primaryColor ?? AppColors.primaryBlue;

    _borderColorAnimation = ColorTween(
      begin: primaryColor.withOpacity(0.2),
      end: primaryColor,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOutCubic,
    ));

    _glowColorAnimation = ColorTween(
      begin: primaryColor.withOpacity(0.0),
      end: primaryColor.withOpacity(0.3),
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOutCubic,
    ));
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _colorController.forward();
    } else {
      _colorController.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? AppColors.primaryBlue;

    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _glowColorAnimation.value ?? Colors.transparent,
                  blurRadius: 15 * _glowAnimation.value,
                  spreadRadius: 2 * _glowAnimation.value,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              onChanged: widget.onChanged,
              maxLength: widget.maxLength,
              textAlign: widget.textAlign,
              style: widget.style,
              cursorColor: primaryColor,
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                prefixIcon: widget.prefixIcon != null
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: widget.useGradientIcon
                              ? (_isFocused
                                  ? LinearGradient(
                                      colors: [
                                        primaryColor,
                                        primaryColor.withOpacity(0.8),
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        primaryColor.withOpacity(0.7),
                                        primaryColor.withOpacity(0.5),
                                      ],
                                    ))
                              : null,
                          color: widget.useGradientIcon
                              ? null
                              : (_isFocused
                                  ? primaryColor
                                  : primaryColor.withOpacity(0.6)),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: Icon(
                          widget.prefixIcon,
                          color: widget.useGradientIcon ? Colors.white : null,
                          size: 22,
                        ),
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value ??
                        primaryColor.withOpacity(0.2),
                    width: _isFocused ? 3.0 : 1.8,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value ??
                        primaryColor.withOpacity(0.2),
                    width: _isFocused ? 3.0 : 1.8,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value ?? primaryColor,
                    width: 3.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


