import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated gradient background widget
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFF3B82F6),
      Color(0xFFF97316),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ],
    this.duration = const Duration(seconds: 8),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_controller.value * 2 * math.pi),
                math.sin(_controller.value * 2 * math.pi),
              ),
              end: Alignment(
                math.cos(_controller.value * 2 * math.pi + math.pi),
                math.sin(_controller.value * 2 * math.pi + math.pi),
              ),
              colors: widget.colors
                  .map((color) => color.withOpacity(0.05))
                  .toList(),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
