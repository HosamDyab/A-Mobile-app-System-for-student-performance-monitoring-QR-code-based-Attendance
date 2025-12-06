import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Modern button with hover animation effects.
///
/// Features:
/// - Smooth scale and elevation animations on hover
/// - Gradient or outlined styles
/// - Icon support
/// - Loading state
/// - Theme-aware colors
class ModernHoverButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;

  const ModernHoverButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.width,
    this.height = 64,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
  });

  @override
  State<ModernHoverButton> createState() => _ModernHoverButtonState();
}

class _ModernHoverButtonState extends State<ModernHoverButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 8.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _handleHover(true),
          onExit: (_) => _handleHover(false),
          cursor: widget.onPressed != null && !widget.isLoading
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.isLoading ? null : widget.onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.width ?? double.infinity,
                height: widget.height,
                decoration: widget.isOutlined
                    ? BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.foregroundColor ?? colorScheme.primary,
                          width: _isHovered ? 3.0 : 2.5,
                        ),
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: (widget.foregroundColor ??
                                          colorScheme.primary)
                                      .withOpacity(0.3),
                                  blurRadius: _elevationAnimation.value,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      )
                    : BoxDecoration(
                        gradient: widget.gradient ?? AppColors.primaryGradient,
                        color: widget.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.backgroundColor ??
                                    AppColors.primaryBlue)
                                .withOpacity(0.4),
                            blurRadius: _elevationAnimation.value,
                            offset: Offset(0, _elevationAnimation.value / 2),
                            spreadRadius: _isHovered ? 2 : 1,
                          ),
                        ],
                      ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.isLoading ? null : widget.onPressed,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: widget.isLoading
                          ? Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.isOutlined
                                        ? (widget.foregroundColor ??
                                            colorScheme.primary)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    size: 26,
                                    color: widget.isOutlined
                                        ? (widget.foregroundColor ??
                                            colorScheme.primary)
                                        : Colors.white,
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Flexible(
                                  child: Text(
                                    widget.label,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: widget.isOutlined
                                          ? (widget.foregroundColor ??
                                              colorScheme.primary)
                                          : Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
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
