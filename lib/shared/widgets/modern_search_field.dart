import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_colors.dart';

/// Modern animated search field with pulsing icon and smooth interactions
///
/// Features:
/// - Animated search icon that pulses
/// - Smooth focus animations
/// - Gradient background on icon
/// - No visible label (clean look)
/// - Auto-complete hint text
/// - Clear button when text is entered
class ModernSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Color? primaryColor;
  final Color? secondaryColor;
  final IconData icon;
  final bool autofocus;

  const ModernSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.primaryColor,
    this.secondaryColor,
    this.icon = Icons.search_rounded,
    this.autofocus = false,
  });

  @override
  State<ModernSearchField> createState() => _ModernSearchFieldState();
}

class _ModernSearchFieldState extends State<ModernSearchField>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _pulseController;
  late AnimationController _focusController;
  late AnimationController _iconRotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _iconRotation;
  
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);

    // Pulse animation for icon (continuous)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Focus animation
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeOutCubic,
    ));

    // Icon rotation animation
    _iconRotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _iconRotationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _focusController.forward();
      _iconRotationController.forward();
    } else {
      _focusController.reverse();
      _iconRotationController.reverse();
    }
  }

  void _onTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _pulseController.dispose();
    _focusController.dispose();
    _iconRotationController.dispose();
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = widget.primaryColor ?? AppColors.primaryBlue;
    final secondaryColor = widget.secondaryColor ?? AppColors.secondaryOrange;

    return AnimatedBuilder(
      animation: Listenable.merge([_focusController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15 * _glowAnimation.value),
                  blurRadius: 20 * _glowAnimation.value,
                  spreadRadius: 3 * _glowAnimation.value,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: primaryColor,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                
                // Animated Icon
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedBuilder(
                    animation: _iconRotation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _iconRotation.value,
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isFocused
                                    ? [primaryColor, secondaryColor]
                                    : [
                                        primaryColor.withOpacity(0.8),
                                        secondaryColor.withOpacity(0.8),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Clear Button
                suffixIcon: _hasText
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onSurface.withOpacity(0.6),
                          size: 22,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          if (widget.onClear != null) {
                            widget.onClear!();
                          }
                        },
                      )
                    : null,

                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: primaryColor,
                    width: 3,
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

