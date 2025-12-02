import 'package:flutter/material.dart';
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
  final String role;
  final String roleName;

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

    // Load saved email if Remember Me was enabled
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final savedEmail = await AuthService.getRememberedEmail(widget.role);
    if (savedEmail != null && mounted) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _containerController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Map<String, String> _extractUserInfo(String email) {
    final username = email.split('@')[0];

    if (widget.role == 'student') {
      final parts = username.split('.');
      String name = '';
      String id = '';

      if (parts.length >= 2) {
        name = parts[0];
        id = parts[1];
        name = name[0].toUpperCase() + name.substring(1);
      }

      return {'name': name, 'id': id, 'role': 'student'};
    } else if (widget.role == 'faculty') {
      String name = username.toLowerCase().startsWith('dr')
          ? username.substring(2)
          : username;
      name = name[0].toUpperCase() + name.substring(1);

      return {'name': 'Dr. $name', 'id': '', 'role': 'faculty'};
    } else if (widget.role == 'teacher_assistant') {
      final parts = username.split('.');
      String firstName = '';
      String lastName = '';

      if (parts.length >= 2) {
        firstName = parts[0][0].toUpperCase() + parts[0].substring(1);
        lastName = parts[1][0].toUpperCase() + parts[1].substring(1);
      }

      return {
        'name': '$firstName $lastName',
        'id': '',
        'role': 'teacher_assistant'
      };
    }

    return {'name': '', 'id': '', 'role': ''};
  }

  bool _isValidMTIEmail(String email) {
    if (widget.role == 'student') {
      final regex = RegExp(r'^[a-zA-Z]+\.\d+@cs\.mti\.edu\.eg$');
      return regex.hasMatch(email);
    } else if (widget.role == 'faculty') {
      final regex =
          RegExp(r'^dr[a-zA-Z]+@cs\.mti\.edu\.eg$', caseSensitive: false);
      return regex.hasMatch(email);
    } else if (widget.role == 'teacher_assistant') {
      final regex = RegExp(r'^[a-zA-Z]+\.[a-zA-Z]+@cs\.mti\.edu\.eg$');
      return regex.hasMatch(email);
    }
    return false;
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final supabase = SupabaseManager.client;

        print('🔐 Attempting login for: $email');

        final userResponse = await supabase
            .from('User')
            .select('UserId, Email, PasswordHash, FullName, Role, IsActive')
            .eq('Email', email)
            .maybeSingle();

        if (userResponse == null) {
          throw Exception('Invalid email or password.');
        }

        print('✅ User found: ${userResponse['FullName']}');

        final storedPasswordHash = userResponse['PasswordHash'];

        if (storedPasswordHash != password) {
          throw Exception('Invalid email or password.');
        }

        if (userResponse['IsActive'] != true) {
          throw Exception('Your account is inactive. Please contact support.');
        }

        final userRole = userResponse['Role'].toString().toLowerCase();
        if (widget.role == 'student' && userRole != 'student') {
          throw Exception('This email is not registered as a student.');
        } else if (widget.role == 'faculty' && userRole != 'faculty') {
          throw Exception('This email is not registered as faculty.');
        } else if (widget.role == 'teacher_assistant' &&
            userRole != 'teacherassistant') {
          throw Exception(
              'This email is not registered as a teacher assistant.');
        }

        final userId = userResponse['UserId'];

        if (widget.role == 'student') {
          final studentResponse = await supabase
              .from('Student')
              .select('StudentId, StudentCode')
              .eq('UserId', userId)
              .maybeSingle();

          if (studentResponse == null) {
            throw Exception('Student record not found.');
          }

          final studentId = studentResponse['StudentId'].toString();
          final studentName = userResponse['FullName'];

          print('✅ Student authenticated: $studentName (ID: $studentId)');

          await AuthService.saveLoginSession(
            email: email,
            role: 'student',
            userId: userId,
            userName: studentName,
            studentId: studentId,
          );

          // Save email if Remember Me is checked
          if (_rememberMe) {
            await AuthService.saveRememberedEmail(
                email: email, role: 'student');
          } else {
            await AuthService.clearRememberedEmail('student');
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            Navigator.pushReplacement(
              context,
              AdvancedSlidePageRoute(
                page: const StudentView(),
                direction: SlideDirection.left,
              ),
            );
          }
        } else if (widget.role == 'faculty') {
          final facultyResponse = await supabase
              .from('Faculty')
              .select('FacultyId, EmployeeCode, AcademicTitle')
              .eq('UserId', userId)
              .maybeSingle();

          if (facultyResponse == null) {
            throw Exception('Faculty record not found.');
          }

          final facultyId = facultyResponse['FacultyId'].toString();
          final facultyName = userResponse['FullName'];

          print('✅ Faculty authenticated: $facultyName (ID: $facultyId)');

          await AuthService.saveLoginSession(
            email: email,
            role: 'faculty',
            userId: userId,
            userName: facultyName,
            studentId: facultyId,
          );

          // Save email if Remember Me is checked
          if (_rememberMe) {
            await AuthService.saveRememberedEmail(
                email: email, role: 'faculty');
          } else {
            await AuthService.clearRememberedEmail('faculty');
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            Navigator.pushReplacement(
              context,
              AdvancedSlidePageRoute(
                page: TeacherView(
                  facultyName: facultyName,
                  facultyEmail: email,
                  facultyId: facultyId,
                  role: 'faculty',
                ),
                direction: SlideDirection.left,
              ),
            );
          }
        } else if (widget.role == 'teacher_assistant') {
          final taResponse = await supabase
              .from('TeacherAssistant')
              .select('TAId, EmployeeCode')
              .eq('UserId', userId)
              .maybeSingle();

          if (taResponse == null) {
            throw Exception('Teacher Assistant record not found.');
          }

          final taId = taResponse['TAId'].toString();
          final taName = userResponse['FullName'];

          print('✅ TA authenticated: $taName (ID: $taId)');

          await AuthService.saveLoginSession(
            email: email,
            role: 'teacher_assistant',
            userId: userId,
            userName: taName,
            studentId: taId,
          );

          // Save email if Remember Me is checked
          if (_rememberMe) {
            await AuthService.saveRememberedEmail(
                email: email, role: 'teacher_assistant');
          } else {
            await AuthService.clearRememberedEmail('teacher_assistant');
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            Navigator.pushReplacement(
              context,
              AdvancedSlidePageRoute(
                page: TeacherView(
                  facultyName: taName,
                  facultyEmail: email,
                  facultyId: taId,
                  role: 'teacher_assistant',
                ),
                direction: SlideDirection.left,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Login error: $e');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.toString().replaceAll('Exception: ', ''),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.accentRed,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  _handleLogin();
                },
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _containerAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _containerController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 50,
                          offset: const Offset(0, 25),
                          spreadRadius: 3,
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(44.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Advanced Animated MTI Logo
                            AnimatedBuilder(
                              animation: _logoScaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: Container(
                                    height: 140,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryBlue
                                              .withOpacity(0.1),
                                          AppColors.secondaryOrange
                                              .withOpacity(0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Image.asset(
                                      'lib/images/MTI Logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.school_rounded,
                                            size: 80,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 36),

                            // Advanced Animated Role Title
                            FadeTransition(
                              opacity: _textOpacityAnimation,
                              child: SlideTransition(
                                position: _textSlideAnimation,
                                child: Text(
                                  widget.roleName,
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 32,
                                    color: AppColors.tertiaryBlack,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Advanced Animated Welcome Title with Gradient
                            FadeTransition(
                              opacity: _textOpacityAnimation,
                              child: SlideTransition(
                                position: _textSlideAnimation,
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      AppColors.primaryGradient.createShader(
                                    Rect.fromLTWH(
                                        0, 0, bounds.width, bounds.height),
                                  ),
                                  blendMode: BlendMode.srcIn,
                                  child: Text(
                                    'Welcome Back',
                                    style:
                                        theme.textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Advanced Animated Subtitle
                            FadeTransition(
                              opacity: _textOpacityAnimation,
                              child: SlideTransition(
                                position: _textSlideAnimation,
                                child: Text(
                                  'Log in to continue your learning journey.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 17,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 44),

                            // Advanced Animated Email Field with Color Transitions
                            AnimatedBuilder(
                              animation: _fieldAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                      0, 30 * (1 - _fieldAnimation.value)),
                                  child: Opacity(
                                    opacity: _fieldAnimation.value,
                                    child: AnimatedTextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      hintText: 'Enter your MTI email',
                                      prefixIcon: Icons.email_outlined,
                                      primaryColor: AppColors.primaryBlue,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!_isValidMTIEmail(value)) {
                                          return 'Invalid MTI email format';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 22),

                            // Advanced Animated Password Field with Color Transitions
                            AnimatedBuilder(
                              animation: _fieldAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                      0, 30 * (1 - _fieldAnimation.value)),
                                  child: Opacity(
                                    opacity: _fieldAnimation.value,
                                    child: AnimatedTextField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      hintText: 'Enter your password',
                                      prefixIcon: Icons.lock_outline,
                                      primaryColor: AppColors.secondaryOrange,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          color: AppColors.tertiaryLightGray,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
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
                            const SizedBox(height: 18),

                            // Remember Me Checkbox and Forgot Password Link
                            AnimatedBuilder(
                              animation: _fieldAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                      0, 30 * (1 - _fieldAnimation.value)),
                                  child: Opacity(
                                    opacity: _fieldAnimation.value,
                                    child: Row(
                                      children: [
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(
                                            begin: _rememberMe ? 1.0 : 0.0,
                                            end: _rememberMe ? 1.0 : 0.0,
                                          ),
                                          duration:
                                              const Duration(milliseconds: 200),
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: 0.9 + (0.1 * value),
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _rememberMe =
                                                        value ?? false;
                                                  });
                                                },
                                                activeColor:
                                                    AppColors.primaryBlue,
                                                checkColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _rememberMe = !_rememberMe;
                                            });
                                          },
                                          child: Text(
                                            'Remember Me',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: AppColors.tertiaryBlack,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              AdvancedSlidePageRoute(
                                                page: ForgotPasswordScreen(
                                                  roleName: widget.roleName,
                                                ),
                                                direction: SlideDirection.right,
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.lock_reset_rounded,
                                            size: 16,
                                            color: AppColors.primaryBlue,
                                          ),
                                          label: Text(
                                            'Forgot Password?',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 36),

                            // Advanced Animated Login Button with Hover Effect
                            AnimatedBuilder(
                              animation: _fieldAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                      0, 30 * (1 - _fieldAnimation.value)),
                                  child: Opacity(
                                    opacity: _fieldAnimation.value,
                                    child: HoverScaleWidget(
                                      scale: 1.03,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      onTap: _isLoading ? null : _handleLogin,
                                      child: Container(
                                        width: double.infinity,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          gradient: AppColors.primaryGradient,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryBlue
                                                  .withOpacity(0.5),
                                              blurRadius: 25,
                                              offset: const Offset(0, 10),
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isLoading ? null : _handleLogin,
                                          icon: _isLoading
                                              ? const SizedBox.shrink()
                                              : const Icon(
                                                  Icons.login_rounded,
                                                  size: 26,
                                                  color: Colors.white,
                                                ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 28,
                                              vertical: 20,
                                            ),
                                          ),
                                          label: _isLoading
                                              ? LoadingAnimation(
                                                  size: 26,
                                                  color: Colors.white,
                                                )
                                              : Text(
                                                  'Log In',
                                                  style: theme
                                                      .textTheme.titleLarge
                                                      ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
