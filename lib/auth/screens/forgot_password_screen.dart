import 'package:flutter/material.dart';

import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/animated_gradient_background.dart';
import '../handlers/password_reset_handler.dart';
import '../utils/email_validator.dart';
import '../widgets/password_reset_email_step.dart';
import '../widgets/password_reset_new_password_step.dart';
import '../widgets/password_reset_otp_step.dart';
import '../widgets/password_reset_step_indicator.dart';

/// Screen for resetting forgotten passwords via OTP verification.
///
/// Three-step process:
/// 1. Enter email address
/// 2. Verify OTP code sent to email
/// 3. Set new password
class ForgotPasswordScreen extends StatefulWidget {
  final String roleName;

  const ForgotPasswordScreen({
    super.key,
    required this.roleName,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  // Form keys for each step
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Text controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Password reset handler
  final _passwordResetHandler = PasswordResetHandler();

  // UI state
  bool _isLoading = false;
  int _currentStep = 0; // 0: Email, 1: OTP, 2: New Password
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _stepController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  /// Initialize animation controllers and animations.
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _stepController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stepController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Sends OTP to the user's email address.
  Future<void> _sendOTP() async {
    if (_emailFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final emailSent =
          await _passwordResetHandler.sendOTP(_emailController.text);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (emailSent) {
        _stepController.forward(from: 0.0);
        setState(() => _currentStep = 1);

        PasswordResetHandler.showSnackBar(
          context,
          message: 'OTP has been sent to your Outlook email!',
          backgroundColor: AppColors.accentGreen,
          icon: Icons.check_circle_rounded,
        );
      } else {
        PasswordResetHandler.showSnackBar(
          context,
          message: 'Failed to send OTP. Please try again.',
          backgroundColor: AppColors.accentRed,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  /// Verifies the OTP entered by the user.
  Future<void> _verifyOTP() async {
    if (_otpFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (_passwordResetHandler.verifyOTP(_otpController.text.trim())) {
        _stepController.forward(from: 0.0);
        setState(() => _currentStep = 2);

        PasswordResetHandler.showSnackBar(
          context,
          message: 'OTP verified successfully!',
          backgroundColor: AppColors.accentGreen,
          icon: Icons.check_circle_rounded,
        );
      } else {
        PasswordResetHandler.showSnackBar(
          context,
          message: 'Invalid OTP. Please check your email and try again.',
          backgroundColor: AppColors.accentRed,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  /// Resets the user's password.
  Future<void> _resetPassword() async {
    if (_passwordFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        await _passwordResetHandler.resetPassword(_newPasswordController.text);

        if (!mounted) return;

        setState(() => _isLoading = false);

        PasswordResetHandler.showSuccessDialog(context, () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Return to login
        });
      } catch (e) {
        print('❌ Error resetting password: $e');

        if (!mounted) return;

        setState(() => _isLoading = false);

        PasswordResetHandler.showSnackBar(
          context,
          message: 'Failed to reset password: ${e.toString()}',
          backgroundColor: AppColors.accentRed,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: AnimatedGradientBackground(
        colors: AppColors.animatedGradientColors,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildPasswordResetCard(colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the app bar.
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon:
            Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Reset Password',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main password reset card.
  Widget _buildPasswordResetCard(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step Indicator
                PasswordResetStepIndicator(
                  currentStep: _currentStep,
                  controller: _stepController,
                ),
                const SizedBox(height: 40),

                // Display current step with animations
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the current step widget based on [_currentStep].
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return PasswordResetEmailStep(
          key: const ValueKey(0),
          formKey: _emailFormKey,
          emailController: _emailController,
          fadeAnimation: _fadeAnimation,
          animationController: _animationController,
          isLoading: _isLoading,
          onSendOTP: _sendOTP,
          onBackToLogin: () => Navigator.pop(context),
          emailValidator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!EmailValidator.isValidMTIEmail(value, 'student') &&
                !EmailValidator.isValidMTIEmail(value, 'faculty') &&
                !EmailValidator.isValidMTIEmail(value, 'teacher_assistant')) {
              return 'Invalid MTI email format';
            }
            return null;
          },
        );
      case 1:
        return PasswordResetOTPStep(
          key: const ValueKey(1),
          formKey: _otpFormKey,
          otpController: _otpController,
          email: _emailController.text,
          fadeAnimation: _fadeAnimation,
          animationController: _animationController,
          isLoading: _isLoading,
          onVerifyOTP: _verifyOTP,
          onResendOTP: () {
            _otpController.clear();
            _sendOTP();
          },
          otpValidator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter OTP code';
            }
            if (value.length != 6) {
              return 'OTP must be 6 digits';
            }
            return null;
          },
        );
      case 2:
        return PasswordResetNewPasswordStep(
          key: const ValueKey(2),
          formKey: _passwordFormKey,
          newPasswordController: _newPasswordController,
          confirmPasswordController: _confirmPasswordController,
          fadeAnimation: _fadeAnimation,
          animationController: _animationController,
          isNewPasswordVisible: _isNewPasswordVisible,
          isConfirmPasswordVisible: _isConfirmPasswordVisible,
          onToggleNewPasswordVisibility: () {
            setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
          },
          onToggleConfirmPasswordVisibility: () {
            setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
          },
          isLoading: _isLoading,
          onResetPassword: _resetPassword,
          newPasswordValidator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter new password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
          confirmPasswordValidator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
