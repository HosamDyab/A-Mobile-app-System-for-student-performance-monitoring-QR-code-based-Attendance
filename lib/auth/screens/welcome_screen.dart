import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../shared/utils/page_transitions.dart';
import '../../shared/widgets/animated_gradient_background.dart';
import '../../shared/widgets/modern_hover_button.dart';
import '../../shared/widgets/theme_toggle_button.dart';
import '../../shared/widgets/modern_logo_widget.dart';
import '../../shared/utils/app_colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _buttonsController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _buttonsFadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );
    _buttonsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: Curves.easeOut,
      ),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _buttonsController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedGradientBackground(
        colors: AppColors.animatedGradientColors,
        child: SafeArea(
          child: Stack(
            children: [
              // Theme toggle button in top-right corner
              Positioned(
                top: 16,
                right: 16,
                child: const ThemeToggleButton(),
              ),
              // Main content
              LayoutBuilder(
                builder: (context, constraints) {
                  // Check if mobile layout is needed
                  final isMobile = constraints.maxWidth < 600;

                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16.0 : 24.0,
                        vertical: isMobile ? 12.0 : 24.0,
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 24.0 : 40.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Modern Animated MTI Logo with floating QR icon
                              FadeTransition(
                                opacity: _logoFadeAnimation,
                                child: ScaleTransition(
                                  scale: _logoScaleAnimation,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Clean logo without box
                                      ModernLogoWidget(
                                        height: isMobile ? 120 : 160,
                                        showBackground: false,
                                        scaleAnimation: _logoScaleAnimation,
                                      ),
                                      // Animated floating QR icon
                                      Positioned(
                                        top: -10,
                                        right: isMobile ? 10 : 20,
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          duration: const Duration(
                                              milliseconds: 1500),
                                          curve: Curves.elasticOut,
                                          builder: (context, value, child) {
                                            final clampedOpacity =
                                                value.clamp(0.0, 1.0);
                                            return Transform.scale(
                                              scale: 0.8 + (0.3 * value),
                                              child: Opacity(
                                                opacity: clampedOpacity,
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      isMobile ? 8 : 12),
                                                  decoration: BoxDecoration(
                                                    gradient: AppColors
                                                        .primaryGradient,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppColors
                                                            .primaryBlue
                                                            .withOpacity(0.4),
                                                        blurRadius: 20,
                                                        offset:
                                                            const Offset(0, 6),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    Icons.qr_code_2_rounded,
                                                    size: isMobile ? 28 : 36,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: isMobile ? 24 : 32),
                              // Animated welcome text
                              FadeTransition(
                                opacity: _textFadeAnimation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _textController,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Welcome to',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: isMobile ? 18 : 22,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.8),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: isMobile ? 4 : 8),
                                      ShaderMask(
                                        shaderCallback: (bounds) => AppColors
                                            .primaryGradient
                                            .createShader(
                                          Rect.fromLTWH(0, 0, bounds.width,
                                              bounds.height),
                                        ),
                                        child: Text(
                                          'ClassTrack',
                                          style: theme.textTheme.displaySmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: isMobile ? 28 : 36,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: isMobile ? 8 : 16),
                              // Animated subtitle
                              FadeTransition(
                                opacity: _textFadeAnimation,
                                child: Text(
                                  'Smart QR-based attendance and performance monitoring system',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                    fontSize: isMobile ? 13 : 15,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: isMobile ? 28 : 40),
                              // Animated role buttons with staggered animation
                              _buildAnimatedRoleButton(
                                context: context,
                                label: 'Student',
                                role: 'student',
                                isOutlined: false,
                                icon: Icons.school_rounded,
                                delay: 0,
                                isMobile: isMobile,
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              _buildAnimatedRoleButton(
                                context: context,
                                label: 'Faculty',
                                role: 'faculty',
                                isOutlined: true,
                                icon: Icons.person_rounded,
                                delay: 150,
                                isMobile: isMobile,
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              _buildAnimatedRoleButton(
                                context: context,
                                label: 'Teacher Assistant',
                                role: 'teacher_assistant',
                                isOutlined: true,
                                icon: Icons.groups,
                                delay: 300,
                                isMobile: isMobile,
                              ),
                              SizedBox(height: isMobile ? 16 : 24),
                              // Animated footer
                              FadeTransition(
                                opacity: _buttonsFadeAnimation,
                                child: Text(
                                  '© 2025 ClassTrack • Smart Education Solutions',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                    fontSize: isMobile ? 10 : 12,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedRoleButton({
    required BuildContext context,
    required String label,
    required String role,
    required bool isOutlined,
    required IconData icon,
    required int delay,
    bool isMobile = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final clampedOpacity = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: clampedOpacity,
            child: ModernHoverButton(
              label: label,
              icon: icon,
              isOutlined: isOutlined,
              height: isMobile ? 60 : 64,
              onPressed: () {
                Navigator.push(
                  context,
                  AdvancedSlidePageRoute(
                    page: LoginScreen(
                      role: role,
                      roleName: label,
                    ),
                    direction: SlideDirection.right,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
