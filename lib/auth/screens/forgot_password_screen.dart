import 'package:flutter/material.dart';
import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/animated_gradient_background.dart';
import '../../ustils/supabase_manager.dart';

import 'package:flutter/material.dart';
import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/animated_gradient_background.dart';
import '../../shared/widgets/loading_animation.dart';
import '../handlers/password_reset_handler.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String roleName;
  final String role; // 'student', 'faculty', 'teacher_assistant'

  const ForgotPasswordScreen({
    super.key,
    required this.roleName,
    required this.role,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  // Form keys
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0; // 0: Email, 1: OTP, 2: New Password

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final PasswordResetHandler _resetHandler = PasswordResetHandler();

  String get _userType {
    if (widget.role == 'teacher_assistant') return 'ta';
    return widget.role; // student | faculty
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // STEP 1: Send OTP to email
  Future<void> _sendOTP() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final emailOrId = _emailController.text.trim();
      final success = await _resetHandler.sendOTP(emailOrId, _userType);

      setState(() => _isLoading = false);

      if (success) {
        setState(() => _currentStep = 1);
        _showSnack('OTP sent to your email. Please check your inbox.');
      } else {
        _showSnack('Failed to send OTP. Please try again.', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: ${e.toString()}', isError: true);
    }
  }

  // STEP 2: Verify OTP
  Future<void> _verifyOTP() async {
    if (!_otpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    final isValid = _resetHandler.verifyOTP(_otpController.text.trim());

    setState(() => _isLoading = false);

    if (isValid) {
      setState(() => _currentStep = 2);
      _showSnack('OTP verified successfully!');
    } else {
      _showSnack('Invalid OTP. Please try again.', isError: true);
    }
  }

  // STEP 3: Reset Password
  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _resetHandler.resetPassword(_newPasswordController.text.trim());

      setState(() => _isLoading = false);

      if (mounted) {
        PasswordResetHandler.showSuccessDialog(context, () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Back to login
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to reset password: ${e.toString()}', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    PasswordResetHandler.showSnackBar(
      context,
      message: msg,
      backgroundColor: isError ? AppColors.accentRed : AppColors.accentGreen,
      icon: isError ? Icons.error_outline : Icons.check_circle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedGradientBackground(
        colors: AppColors.animatedGradientColors,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surface
                      : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Progress Indicator
                    _buildProgressIndicator(),
                    const SizedBox(height: 32),

                    // Animated Step Content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.2, 0),
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
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, 'Email'),
        _buildStepLine(0),
        _buildStepDot(1, 'OTP'),
        _buildStepLine(1),
        _buildStepDot(2, 'Password'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 36 : 32,
          height: isCurrent ? 36 : 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? AppColors.primaryGradient
                : null,
            color: isActive ? null : Colors.grey.withOpacity(0.3),
            border: Border.all(
              color: isActive ? AppColors.primaryBlue : Colors.grey,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive
                ? Icon(
              step < _currentStep ? Icons.check : Icons.circle,
              color: Colors.white,
              size: 16,
            )
                : Text(
              '${step + 1}',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.primaryBlue : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: isActive
            ? AppColors.primaryGradient
            : null,
        color: isActive ? null : Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOTPStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Enter Email or ID
  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey(0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.email_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enter Your Email or ID',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll send you a verification code',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email or ${widget.roleName} ID',
              hintText: 'Enter your email or ID',
              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            validator: (v) =>
            v == null || v.isEmpty ? 'Please enter your email or ID' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.send_rounded),
              label: _isLoading
                  ? const LoadingAnimation(size: 20, color: Colors.white)
                  : const Text('Send OTP', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Enter OTP
  Widget _buildOTPStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        key: const ValueKey(1),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.secondaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enter Verification Code',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check your email for the 6-digit code',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              labelText: 'OTP Code',
              hintText: '000000',
              prefixIcon: Icon(Icons.vpn_key_rounded, color: AppColors.secondaryOrange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.secondaryOrange, width: 2),
              ),
            ),
            validator: (v) =>
            (v == null || v.length != 6) ? 'Enter 6-digit OTP' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.verified_rounded),
              label: _isLoading
                  ? const LoadingAnimation(size: 20, color: Colors.white)
                  : const Text('Verify OTP', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : _sendOTP,
            child: const Text('Resend OTP'),
          ),
        ],
      ),
    );
  }

  // STEP 3: Set New Password
  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        key: const ValueKey(2),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentGreen, const Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create New Password',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a strong password',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_isNewPasswordVisible,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter new password',
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.accentGreen),
              suffixIcon: IconButton(
                icon: Icon(
                  _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.accentGreen, width: 2),
              ),
            ),
            validator: (v) =>
            (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter password',
              prefixIcon: Icon(Icons.lock_rounded, color: AppColors.accentGreen),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () => setState(
                        () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.accentGreen, width: 2),
              ),
            ),
            validator: (v) =>
            v != _newPasswordController.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.check_circle_rounded),
              label: _isLoading
                  ? const LoadingAnimation(size: 20, color: Colors.white)
                  : const Text('Reset Password', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
//
// class ForgotPasswordScreen extends StatefulWidget {
//   final String roleName;
//
//   const ForgotPasswordScreen({
//     super.key,
//     required this.roleName,
//   });
//
//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }
//
// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
//     with TickerProviderStateMixin {
//   // form keys
//   final _idFormKey = GlobalKey<FormState>();
//   final _passwordFormKey = GlobalKey<FormState>();
//
//   // controllers
//   final _idController = TextEditingController();
//   final _newPasswordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//
//   bool _isLoading = false;
//   int _currentStep = 0;
//
//   bool _isNewPasswordVisible = false;
//   bool _isConfirmPasswordVisible = false;
//
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   String _userType = "";
//
//   @override
//   void initState() {
//     super.initState();
//
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween(begin: 0.0, end: 1.0)
//         .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
//
//     _animationController.forward();
//
//     // convert roleName to DB type
//     if (widget.roleName.toLowerCase().contains("student")) _userType = "student";
//     if (widget.roleName.toLowerCase().contains("faculty")) _userType = "faculty";
//     if (widget.roleName.toLowerCase().contains("assistant")) _userType = "ta";
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _idController.dispose();
//     _newPasswordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _verifyId() async {
//     if (!_idFormKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     final supabase = SupabaseManager.client;
//
//     final creds = await supabase
//         .from("user_credentials")
//         .select("user_id")
//         .eq("user_id", _idController.text.trim())
//         .eq("user_type", _userType)
//         .maybeSingle();
//
//     setState(() => _isLoading = false);
//
//     if (creds == null) {
//       _showSnack("Account not found for this ID.", isError: true);
//       return;
//     }
//
//     setState(() => _currentStep = 1);
//     _showSnack("ID verified. You can now reset your password.");
//   }
//
//   Future<void> _resetPassword() async {
//     if (!_passwordFormKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       final supabase = SupabaseManager.client;
//
//       await supabase
//           .from("user_credentials")
//           .update({"hashed_password": _newPasswordController.text.trim()})
//           .eq("user_id", _idController.text.trim())
//           .eq("user_type", _userType);
//
//       setState(() => _isLoading = false);
//
//       _showSuccessDialog();
//     } catch (e) {
//       setState(() => _isLoading = false);
//       _showSnack("Failed to reset password: $e", isError: true);
//     }
//   }
//
//   void _showSnack(String msg, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(children: [
//           Icon(isError ? Icons.error_outline : Icons.check_circle,
//               color: Colors.white),
//           const SizedBox(width: 8),
//           Expanded(child: Text(msg, style: const TextStyle(color: Colors.white)))
//         ]),
//         backgroundColor: isError ? AppColors.accentRed : AppColors.accentGreen,
//       ),
//     );
//   }
//
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text("Password Reset Successful"),
//         content:
//         const Text("Your password has been updated. You can now log in."),
//         actions: [
//           TextButton(
//             child: const Text("OK"),
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context); // back to login
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Reset Password"),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_rounded),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: AnimatedGradientBackground(
//         colors: AppColors.animatedGradientColors,
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(28),
//               child: Container(
//                 width: 480,
//                 padding: const EdgeInsets.all(28),
//                 decoration: BoxDecoration(
//                   color: theme.colorScheme.surface.withOpacity(0.95),
//                   borderRadius: BorderRadius.circular(26),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.12),
//                       blurRadius: 20,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 400),
//                   child: _currentStep == 0
//                       ? _buildIdStep()
//                       : _buildPasswordStep(),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // STEP 1: ENTER ID
//   Widget _buildIdStep() {
//     return Form(
//       key: _idFormKey,
//       child: Column(
//         key: const ValueKey(0),
//         children: [
//           Text(
//             "Enter your ${widget.roleName} ID",
//             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//           TextFormField(
//             controller: _idController,
//             decoration: const InputDecoration(
//               labelText: "ID",
//               prefixIcon: Icon(Icons.badge_rounded),
//             ),
//             validator: (v) =>
//             v == null || v.isEmpty ? "Please enter your ID" : null,
//           ),
//           const SizedBox(height: 30),
//           ElevatedButton(
//             onPressed: _isLoading ? null : _verifyId,
//             style: ElevatedButton.styleFrom(
//               minimumSize: const Size(double.infinity, 48),
//               backgroundColor: AppColors.primaryBlue,
//             ),
//             child: _isLoading
//                 ? const CircularProgressIndicator(color: Colors.white)
//                 : const Text("Verify ID"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // STEP 2: SET NEW PASSWORD
//   Widget _buildPasswordStep() {
//     return Form(
//       key: _passwordFormKey,
//       child: Column(
//         key: const ValueKey(1),
//         children: [
//           const Text(
//             "Create New Password",
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//           TextFormField(
//             controller: _newPasswordController,
//             obscureText: !_isNewPasswordVisible,
//             decoration: InputDecoration(
//               labelText: "New Password",
//               prefixIcon: const Icon(Icons.lock_outline),
//               suffixIcon: IconButton(
//                 icon: Icon(_isNewPasswordVisible
//                     ? Icons.visibility
//                     : Icons.visibility_off),
//                 onPressed: () =>
//                     setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
//               ),
//             ),
//             validator: (v) =>
//             (v == null || v.length < 6) ? "At least 6 characters" : null,
//           ),
//           const SizedBox(height: 12),
//           TextFormField(
//             controller: _confirmPasswordController,
//             obscureText: !_isConfirmPasswordVisible,
//             decoration: InputDecoration(
//               labelText: "Confirm Password",
//               prefixIcon: const Icon(Icons.lock_reset_rounded),
//               suffixIcon: IconButton(
//                 icon: Icon(_isConfirmPasswordVisible
//                     ? Icons.visibility
//                     : Icons.visibility_off),
//                 onPressed: () => setState(
//                         () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
//               ),
//             ),
//             validator: (v) =>
//             v != _newPasswordController.text ? "Passwords do not match" : null,
//           ),
//           const SizedBox(height: 30),
//           ElevatedButton(
//             onPressed: _isLoading ? null : _resetPassword,
//             style: ElevatedButton.styleFrom(
//               minimumSize: const Size(double.infinity, 48),
//               backgroundColor: AppColors.primaryBlue,
//             ),
//             child: _isLoading
//                 ? const CircularProgressIndicator(color: Colors.white)
//                 : const Text("Reset Password"),
//           ),
//         ],
//       ),
//     );
//   }
// }
