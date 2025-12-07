import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_colors.dart';

/// Animated TextField with smooth color transitions, animated icons, and modern design
///
/// Features:
/// - Animated icon that pulses and rotates on focus
/// - Smooth border and glow transitions
/// - No label text (clean modern look)
/// - Gradient icon background
/// - Scale animation on focus
class AnimatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText; // Deprecated - kept for backward compatibility
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
  final bool animateIcon; // New: Enable icon animation
  final bool showLabel; // New: Control label visibility

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
    this.animateIcon = true,
    this.showLabel = false, // Default: no label for modern look
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _colorController;
  late AnimationController _iconController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Color?> _glowColorAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _iconRotation;
  late Animation<double> _iconScale;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    // Main color/scale animation controller
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Icon animation controller
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    // Icon animations
    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOutCubic,
    ));

    _iconScale = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOutBack,
    ));
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _colorController.forward();
      if (widget.animateIcon) {
        _iconController.forward();
      }
    } else {
      _colorController.reverse();
      if (widget.animateIcon) {
        _iconController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _colorController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = widget.primaryColor ?? AppColors.primaryBlue;
    final secondaryColor = widget.secondaryColor ?? AppColors.secondaryOrange;

    return AnimatedBuilder(
      animation: Listenable.merge([_colorController, _iconController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _glowColorAnimation.value ?? Colors.transparent,
                  blurRadius: 18 * _glowAnimation.value,
                  spreadRadius: 3 * _glowAnimation.value,
                  offset: const Offset(0, 4),
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
              style: widget.style ??
                  theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
              cursorColor: primaryColor,
              decoration: InputDecoration(
                // Show label only if showLabel is true
                labelText: widget.showLabel ? widget.labelText : null,
                labelStyle: TextStyle(
                  color: _isFocused
                      ? primaryColor
                      : colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),

                // Always show hint text
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),

                // Animated Icon
                prefixIcon: widget.prefixIcon != null
                    ? AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: widget.animateIcon ? _iconRotation.value : 0,
                            child: Transform.scale(
                              scale:
                                  widget.animateIcon ? _iconScale.value : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: widget.useGradientIcon
                                      ? LinearGradient(
                                          colors: _isFocused
                                              ? [primaryColor, secondaryColor]
                                              : [
                                                  primaryColor.withOpacity(0.8),
                                                  secondaryColor
                                                      .withOpacity(0.6),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: widget.useGradientIcon
                                      ? null
                                      : (_isFocused
                                          ? primaryColor
                                          : primaryColor.withOpacity(0.7)),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    bottomLeft: Radius.circular(24),
                                  ),
                                  boxShadow: _isFocused
                                      ? [
                                          BoxShadow(
                                            color:
                                                primaryColor.withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  widget.prefixIcon,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value ??
                        primaryColor.withOpacity(0.2),
                    width: _isFocused ? 3.0 : 2.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value ??
                        primaryColor.withOpacity(0.2),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value ?? primaryColor,
                    width: 3.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colorScheme.error,
                    width: 2.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colorScheme.error,
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
