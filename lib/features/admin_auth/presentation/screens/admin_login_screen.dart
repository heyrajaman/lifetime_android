import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../viewmodels/admin_auth_viewmodel.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Call the ViewModel to perform login
    final success = await ref.read(adminAuthViewModelProvider.notifier).login(
      _phoneController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.showSuccess(context, 'Login Successful!');
      context.go('/admin/dashboard'); // Navigate to the protected dashboard
    } else {
      // The error message is automatically stored in the state by the ViewModel
      final errorState = ref.read(adminAuthViewModelProvider).error;
      CustomSnackBar.showError(context, errorState.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth state to determine if we are currently loading
    final authState = ref.watch(adminAuthViewModelProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.admin_panel_settings, size: 80.sp, color: AppColors.kPrimaryColor),
                  SizedBox(height: 24.h),
                  Text(
                    'Admin Portal',
                    style: AppTextStyles.h1Extrabold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Login to manage lifetime memberships.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 48.h),

                  CustomTextField(
                    label: 'Phone Number',
                    hintText: 'Enter admin phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.kTextHint),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                        return 'Enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  CustomTextField(
                    label: 'Password',
                    hintText: 'Enter your password',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.kTextHint),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32.h),

                  CustomButton(
                    text: 'Login',
                    isLoading: isLoading,
                    onPressed: _handleLogin,
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      _showForgotPasswordDialog(context, ref);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue, // Or use your AppColors
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            elevation: 10,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.mark_email_read_outlined, size: 60.sp, color: AppColors.kPrimaryColor),
                  SizedBox(height: 16.h),
                  Text(
                    'Reset Password',
                    style: AppTextStyles.h2Bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Enter your registered email address to receive an OTP.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  CustomTextField(
                    label: 'Email Address',
                    hintText: 'admin@example.com',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.kTextHint),
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    text: 'Send OTP',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        CustomSnackBar.showError(context, 'Please enter an email');
                        return;
                      }

                      setState(() => isSubmitting = true);
                      final success = await ref.read(adminAuthViewModelProvider.notifier).forgotPassword(email);
                      setState(() => isSubmitting = false);

                      if (success && context.mounted) {
                        Navigator.pop(context); // Close dialog
                        CustomSnackBar.showSuccess(context, 'OTP sent to email (if it exists).');
                        _showResetPasswordDialog(context, ref, email); // Open Next Dialog
                      } else if (context.mounted) {
                        CustomSnackBar.showError(context, 'Failed to send OTP. Please try again.');
                      }
                    },
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextHint),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, WidgetRef ref, String email) {
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            elevation: 10,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_reset, size: 60.sp, color: AppColors.kPrimaryColor),
                  SizedBox(height: 16.h),
                  Text(
                    'Create New Password',
                    style: AppTextStyles.h2Bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Enter the 6-digit OTP sent to $email and your new password.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  CustomTextField(
                    label: 'OTP',
                    hintText: 'Enter 6-digit OTP',
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    prefixIcon: const Icon(Icons.message_outlined, color: AppColors.kTextHint),
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    label: 'New Password',
                    hintText: 'Enter new password',
                    controller: newPasswordController,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.kTextHint),
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    text: 'Verify & Reset',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final otp = otpController.text.trim();
                      final newPass = newPasswordController.text.trim();

                      if (otp.isEmpty || newPass.isEmpty) {
                        CustomSnackBar.showError(context, 'Please fill all fields');
                        return;
                      }

                      setState(() => isSubmitting = true);
                      final success = await ref.read(adminAuthViewModelProvider.notifier).resetPassword(email, otp, newPass);
                      setState(() => isSubmitting = false);

                      if (success && context.mounted) {
                        Navigator.pop(context);
                        CustomSnackBar.showSuccess(context, 'Password reset successfully! You can now log in.');
                      } else if (context.mounted) {
                        CustomSnackBar.showError(context, 'Invalid OTP or failed to reset password.');
                      }
                    },
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextHint),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}