import 'package:flutter/material.dart';
import '../../logger.dart';
import 'forgot_password_screen.dart';
import '../../Student/presentaion/screens/StudentView.dart';
import '../../Teacher/TeacherView.dart';
import '../../ustils/supabase_manager.dart';
import '../../services/auth_service.dart';
import '../../shared/utils/page_transitions.dart';
import '../../shared/widgets/loading_animation.dart';
import '../../shared/widgets/animated_gradient_background.dart';
import '../../shared/widgets/hover_scale_widget.dart';
import '../../shared/widgets/animated_text_field.dart';
import '../../shared/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final String role;      // student | faculty | teacher_assistant
  final String roleName;  // Student | Faculty | Teacher Assistant

  const LoginScreen({
    super.key,
    required this.role,
    required this.roleName,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // 🔹 نستخدم الـ ID بدل الإيميل، لكن نحافظ على 2 حقول: ID + Password
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _containerController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _containerAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _fieldAnimation;

  String get _idLabel {
    if (widget.role == 'student') return 'Student ID';
    if (widget.role == 'faculty') return 'Faculty SN';
    return 'TA SN';
  }

  String get _idHint {
    if (widget.role == 'student') return 'Enter your Student ID';
    if (widget.role == 'faculty') return 'Enter your Faculty SN';
    return 'Enter your TA SN';
  }

  String get _userTypeForDb {
    // مطابقة role في الـ DB
    if (widget.role == 'teacher_assistant') return 'ta';
    return widget.role; // student | faculty
  }

  @override
  void initState() {
    super.initState();

    _containerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _containerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _containerController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutExpo),
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));

    _fieldAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _containerController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _containerController.forward();
    });

    _loadSavedId();
  }

  Future<void> _loadSavedId() async {
    // نستخدم نفس AuthService لكن نخزن الـ ID بدل الإيميل
    final saved = await AuthService.getRememberedEmail(widget.role);
    if (saved != null && mounted) {
      setState(() {
        _idController.text = saved;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _containerController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

// ==========================================
// STEP 1: Add this to your login_screen.dart
// ==========================================

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = SupabaseManager.client;
      final loginInput = _idController.text.trim();
      final password = _passwordController.text.trim();

      // Convert role to database format
      String userTypeForDb = widget.role;
      if (widget.role == 'teacher_assistant') userTypeForDb = 'ta';

      // ✅ Determine if input is email or ID
      final bool isEmail = loginInput.contains('@');

      String userId = loginInput;
      String userEmail = '';

      // If email, get the actual user ID first
      if (isEmail) {
        if (widget.role == 'student') {
          final student = await supabase
              .from('student')
              .select('studentid, email')
              .eq('email', loginInput)
              .maybeSingle();

          if (student == null) {
            throw Exception('No account found with this email.');
          }
          userId = student['studentid'];
          userEmail = student['email'];

        } else if (widget.role == 'faculty') {
          final fac = await supabase
              .from('faculty')
              .select('facultysnn, email')
              .eq('email', loginInput)
              .maybeSingle();

          if (fac == null) {
            throw Exception('No account found with this email.');
          }
          userId = fac['facultysnn'];
          userEmail = fac['email'];

        } else if (widget.role == 'teacher_assistant') {
          final ta = await supabase
              .from('ta')
              .select('tasnn, email')
              .eq('email', loginInput)
              .maybeSingle();

          if (ta == null) {
            throw Exception('No account found with this email.');
          }
          userId = ta['tasnn'];
          userEmail = ta['email'];
        }
      }

      // ✅ STEP 1: Check credentials
      final creds = await supabase
          .from('user_credentials')
          .select('user_id, user_type, hashed_password')
          .eq('user_id', userId)
          .eq('user_type', userTypeForDb)
          .maybeSingle();

      if (creds == null) {
        await SystemLogger.logFailedLogin(
          userId: userId,
          userType: userTypeForDb,
          reason: 'User not found',
        );
        throw Exception('Invalid credentials.');
      }

      // ✅ STEP 2: Check password
      if (creds['hashed_password'] != password) {
        await SystemLogger.logFailedLogin(
          userId: userId,
          userType: userTypeForDb,
          reason: 'Incorrect password',
        );
        throw Exception('Invalid credentials.');
      }

      // ✅ STEP 3: Get user details (if not already fetched)
      String fullName = '';
      String entityId = userId;

      if (!isEmail || userEmail.isEmpty) {
        if (widget.role == 'student') {
          final student = await supabase
              .from('student')
              .select('studentid, fullname, email')
              .eq('studentid', userId)
              .maybeSingle();

          if (student == null) throw Exception('Student not found.');
          fullName = student['fullname'];
          entityId = student['studentid'];
          userEmail = student['email'];

        } else if (widget.role == 'faculty') {
          final fac = await supabase
              .from('faculty')
              .select('facultysnn, fullname, email')
              .eq('facultysnn', userId)
              .maybeSingle();

          if (fac == null) throw Exception('Faculty not found.');
          fullName = fac['fullname'];
          entityId = fac['facultysnn'];
          userEmail = fac['email'];

        } else if (widget.role == 'teacher_assistant') {
          final ta = await supabase
              .from('ta')
              .select('tasnn, fullname, email')
              .eq('tasnn', userId)
              .maybeSingle();

          if (ta == null) throw Exception('TA not found.');
          fullName = ta['fullname'];
          entityId = ta['tasnn'];
          userEmail = ta['email'];
        }
      } else {
        // Get full name if we only have email
        if (widget.role == 'student') {
          final student = await supabase
              .from('student')
              .select('fullname')
              .eq('studentid', userId)
              .maybeSingle();
          fullName = student?['fullname'] ?? '';

        } else if (widget.role == 'faculty') {
          final fac = await supabase
              .from('faculty')
              .select('fullname')
              .eq('facultysnn', userId)
              .maybeSingle();
          fullName = fac?['fullname'] ?? '';

        } else if (widget.role == 'teacher_assistant') {
          final ta = await supabase
              .from('ta')
              .select('fullname')
              .eq('tasnn', userId)
              .maybeSingle();
          fullName = ta?['fullname'] ?? '';
        }
      }

      // ✅ STEP 4: LOG SUCCESSFUL LOGIN
      await SystemLogger.logLogin(
        userId: entityId,
        userType: userTypeForDb,
        userName: fullName,
      );

      // ✅ STEP 5: Save session
      await AuthService.saveLoginSession(
        email: userEmail,
        role: widget.role,
        userId: entityId,
        userName: fullName,
        studentId: entityId,
      );

      // Remember Me
      if (_rememberMe) {
        await AuthService.saveRememberedEmail(
          email: loginInput,
          role: widget.role,
        );
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // ✅ STEP 6: Navigate to dashboard
      if (widget.role == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentView()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherView(
              facultyName: fullName,
              facultyEmail: userEmail,
              facultyId: entityId,
              role: widget.role,
            ),
          ),
        );
      }

    } catch (e) {
      print('❌ Login error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 600;
        final bool isDesktop = constraints.maxWidth >= 1000;

        final size = MediaQuery.of(context).size;
        final double logoHeight = size.height * 0.35;
        final double horizontalPadding =
        isDesktop ? 40 : (isTablet ? 32 : 24);
        final double cardMaxWidth =
        isDesktop ? 650 : (isTablet ? 560 : 500);

        final double roleTitleSize =
        isDesktop ? 38 : (isTablet ? 34 : 32);
        final double subtitleSize =
        isDesktop ? 20 : (isTablet ? 18 : 17);

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: SafeArea(
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: FadeTransition(
                    opacity: _containerAnimation,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.login_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.roleName} Login',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  centerTitle: false,
                ),
              ),
            ),
          ),
          body: AnimatedGradientBackground(
            colors: AppColors.animatedGradientColors,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardMaxWidth),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          AnimatedBuilder(
                            animation: _logoScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: Container(
                                  height: logoHeight,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 0,
                                    ),
                                  ),
                                  child: Image.asset(
                                    'lib/images/MTI Logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.school_rounded,
                                        size: 120,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 32 : 24),

                          // Role Title
                          FadeTransition(
                            opacity: _textOpacityAnimation,
                            child: SlideTransition(
                              position: _textSlideAnimation,
                              child: Text(
                                widget.roleName,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: roleTitleSize,
                                  color: AppColors.tertiaryBlack,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Subtitle
                          FadeTransition(
                            opacity: _textOpacityAnimation,
                            child: SlideTransition(
                              position: _textSlideAnimation,
                              child: Text(
                                'Log in to continue your learning journey.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: subtitleSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ID Field (بدل Email)
                                AnimatedBuilder(
                                  animation: _fieldAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                          0,
                                          20 * (1 - _fieldAnimation.value)),
                                      child: Opacity(
                                        opacity: _fieldAnimation.value,
                                        child: AnimatedTextField(
                                          controller: _idController,
                                          keyboardType: TextInputType.text,
                                          hintText: _idHint,
                                          prefixIcon: Icons.badge_outlined,
                                          primaryColor: AppColors.primaryBlue,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Please enter your ID';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Password
                                AnimatedBuilder(
                                  animation: _fieldAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                          0,
                                          20 * (1 - _fieldAnimation.value)),
                                      child: Opacity(
                                        opacity: _fieldAnimation.value,
                                        child: AnimatedTextField(
                                          controller: _passwordController,
                                          obscureText: !_isPasswordVisible,
                                          hintText: 'Password',
                                          prefixIcon: Icons.lock_outline,
                                          primaryColor:
                                          AppColors.secondaryOrange,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility_rounded
                                                  : Icons
                                                  .visibility_off_rounded,
                                              color: AppColors
                                                  .tertiaryLightGray,
                                              size: 18,
                                            ),
                                            onPressed: () => setState(() =>
                                            _isPasswordVisible =
                                            !_isPasswordVisible),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),

                                // Remember Me + Reset Password
                                AnimatedBuilder(
                                  animation: _fieldAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                          0,
                                          20 * (1 - _fieldAnimation.value)),
                                      child: Opacity(
                                        opacity: _fieldAnimation.value,
                                        child: Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Checkbox(
                                                  value: _rememberMe,
                                                  onChanged: (value) =>
                                                      setState(() =>
                                                      _rememberMe =
                                                          value ?? false),
                                                  activeColor:
                                                  AppColors.primaryBlue,
                                                  checkColor: Colors.white,
                                                  visualDensity:
                                                  VisualDensity.compact,
                                                ),
                                                GestureDetector(
                                                  onTap: () => setState(() =>
                                                  _rememberMe =
                                                  !_rememberMe),
                                                  child: Text(
                                                    'Remember Me',
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: AppColors
                                                          .tertiaryBlack,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  AdvancedSlidePageRoute(
                                                    page:
                                                    ForgotPasswordScreen(
                                                      role: widget.role,
                                                      roleName:
                                                      widget.roleName,
                                                     ),
                                                    direction:
                                                    SlideDirection.right,
                                                  ),
                                                );
                                              },
                                              icon: Icon(
                                                Icons.lock_reset_rounded,
                                                size: 14,
                                                color: AppColors.primaryBlue,
                                              ),
                                              label: Text(
                                                'Reset Password',
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: AppColors.primaryBlue,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Login Button
                                AnimatedBuilder(
                                  animation: _fieldAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                          0,
                                          20 * (1 - _fieldAnimation.value)),
                                      child: Opacity(
                                        opacity: _fieldAnimation.value,
                                        child: HoverScaleWidget(
                                          scale: 1.02,
                                          duration:
                                          const Duration(milliseconds: 250),
                                          onTap:
                                          _isLoading ? null : _handleLogin,
                                          child: Container(
                                            width: double.infinity,
                                            height: isTablet ? 50 : 46,
                                            decoration: BoxDecoration(
                                              gradient:
                                              AppColors.primaryGradient,
                                              borderRadius:
                                              BorderRadius.circular(
                                                  isTablet ? 20 : 18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryBlue
                                                      .withOpacity(0.4),
                                                  blurRadius:
                                                  isTablet ? 16 : 12,
                                                  offset: Offset(
                                                      0, isTablet ? 6 : 4),
                                                  spreadRadius: 1.5,
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton.icon(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _handleLogin,
                                              icon: _isLoading
                                                  ? const SizedBox.shrink()
                                                  : Icon(
                                                Icons.login_rounded,
                                                size: isTablet ? 18 : 16,
                                                color: Colors.white,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                Colors.transparent,
                                                foregroundColor: Colors.white,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      isTablet ? 20 : 18),
                                                ),
                                                padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10),
                                              ),
                                              label: _isLoading
                                                  ? LoadingAnimation(
                                                size: 16,
                                                color: Colors.white,
                                              )
                                                  : Text(
                                                'Log In',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight:
                                                  FontWeight.w700,
                                                  fontSize: isTablet
                                                      ? 16
                                                      : 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                              ],
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
