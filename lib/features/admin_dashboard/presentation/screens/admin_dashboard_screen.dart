import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'admin_analytics_screen.dart';
import 'admin_regions_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/empty_error_widget.dart';
import '../../../admin_auth/data/admin_auth_repository.dart';
import '../../../admin_auth/presentation/viewmodels/admin_auth_viewmodel.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const _ApplicantsTab(),
    const _MembersTab(),
    const _SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Admin Dashboard',
        showBackButton: false,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.logout, color: AppColors.kErrorColor),
                onPressed: () async {
                  await ref.read(adminAuthRepositoryProvider).logout();
                  if (context.mounted) context.go('/admin/login');
                },
              );
            },
          )
        ],
      ),
      body: SafeArea(child: _tabs[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.kPrimaryColor,
        unselectedItemColor: AppColors.kTextHint,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_add_alt_1), label: 'Applicants'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// --- TAB WIDGETS ---

class _ApplicantsTab extends ConsumerWidget {
  const _ApplicantsTab();

  String _formatStatus(String? status) {
    if (status == null) return 'Pending';
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsState = ref.watch(applicantsListProvider);

    return Column(
      children: [
        // --- NEW: Analytics Button Header ---
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.kSurfaceColor,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: CustomButton(
            text: 'View Analytics & Reports',
            variant: ButtonVariant.outlined, // Makes it look clean and secondary
            onPressed: () {
              // Navigate to the new Analytics Screen
              // You can use standard Navigation or GoRouter depending on your setup
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminAnalyticsScreen()),
              );
            },
          ),
        ),

        // --- EXISTING: Applicants List ---
        Expanded(
          child: applicantsState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimaryColor),
            ),
            error: (err, _) => EmptyErrorWidget(
              message: err.toString(),
              onRetry: () => ref.refresh(applicantsListProvider),
            ),
            data: (applicants) {
              if (applicants.isEmpty) {
                return const EmptyErrorWidget(
                  message: 'No pending applicants.',
                  icon: Icons.inbox,
                );
              }
              return RefreshIndicator(
                color: AppColors.kPrimaryColor,
                onRefresh: () async {
                  ref.invalidate(applicantsListProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  itemCount: applicants.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> applicant = applicants[index];
                    return ListTile(
                      tileColor: AppColors.kSurfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      title: Text(
                        applicant['fullName'] ?? 'Unknown',
                        style: AppTextStyles.labelBold,
                      ),
                      subtitle: Text(
                        _formatStatus(applicant['status']),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.kPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.kPrimaryColor,
                      ),
                      onTap: () => context.push('/edit-application/${applicant['id']}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab();

  void _showMemberDetails(BuildContext context, Map<String, dynamic> member) {
    final name = member['name'] ?? member['fullName'] ?? 'Unknown';
    final email = member['email'] ?? 'N/A';
    final mobile = member['mobileNumber'] ?? 'N/A';

    String dob = member['dateOfBirth'] ?? 'N/A';
    if (dob.length >= 10) dob = dob.substring(0, 10);

    final bloodGroup = member['bloodGroup'] ?? 'N/A';
    final role = member['role'] ?? 'MEMBER';
    final currentAddress = member['currentAddress'] ?? 'N/A';
    final permanentAddress = member['permanentAddress'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          title: Row(
            children: [
              const Icon(Icons.person, color: AppColors.kPrimaryColor),
              SizedBox(width: 8.w),
              Expanded(child: Text(name, style: AppTextStyles.h2Bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Role', role),
                _buildDetailRow('Mobile Number', mobile),
                _buildDetailRow('Email Address', email),
                _buildDetailRow('Date of Birth', dob),
                _buildDetailRow('Blood Group', bloodGroup),
                const Divider(height: 24),
                _buildDetailRow('Current Address', currentAddress),
                _buildDetailRow('Permanent Address', permanentAddress),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.kPrimaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
          SizedBox(height: 4.h),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersState = ref.watch(membersListProvider);

    return membersState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.kPrimaryColor),
      ),
      error: (err, _) => EmptyErrorWidget(
        message: err.toString(),
        onRetry: () => ref.refresh(membersListProvider),
      ),
      data: (members) {
        if (members.isEmpty) {
          return const EmptyErrorWidget(
            message: 'No members found.',
            icon: Icons.group_off,
          );
        }
        return RefreshIndicator(
          color: AppColors.kPrimaryColor,
          onRefresh: () async {
            ref.invalidate(membersListProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            itemCount: members.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final Map<String, dynamic> member = members[index];

              final name = member['fullName'] ?? member['name'] ?? 'Unknown Member';
              final mobile = member['mobileNumber'] ?? 'No Number';
              final role = member['role'] ?? 'MEMBER';
              final isActive = member['isActive'] == true || member['status'] == 'ACTIVE';

              return Card(
                margin: EdgeInsets.only(bottom: 0), // Removed margin since we use separated list
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                child: ListTile(
                  title: Text(name, style: AppTextStyles.labelBold),
                  subtitle: Text('$mobile  •  Role: $role', style: AppTextStyles.bodyMedium),
                  trailing: Switch(
                    value: isActive,
                    activeThumbColor: AppColors.kPrimaryColor,
                    onChanged: (bool newValue) async {
                      final success = await ref.read(memberActionProvider.notifier).toggleStatus(member['id']);
                      if (success && context.mounted) {
                        CustomSnackBar.showSuccess(context, 'Member status updated!');
                        ref.invalidate(membersListProvider);
                      } else if (context.mounted) {
                        CustomSnackBar.showError(context, 'Failed to update member status.');
                      }
                    },
                  ),
                  onTap: () {
                    _showMemberDetails(context, member);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  void _showUpdateFeeDialog(BuildContext context, WidgetRef ref) {
    final feeController = TextEditingController();
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
                  Icon(Icons.currency_rupee, size: 60.sp, color: AppColors.kPrimaryColor),
                  SizedBox(height: 16.h),
                  Text(
                    'Update Fee',
                    style: AppTextStyles.h2Bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Set the new Lifetime Membership fee amount.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  CustomTextField(
                    label: 'New Amount (₹)',
                    hintText: 'e.g., 5000',
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.kTextHint),
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    text: 'Update Amount',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final amountText = feeController.text.trim();
                      final amount = double.tryParse(amountText);

                      if (amount == null || amount <= 0) {
                        CustomSnackBar.showError(context, 'Please enter a valid amount greater than 0');
                        return;
                      }

                      setState(() => isSubmitting = true);
                      final success = await ref.read(feeUpdateViewModelProvider.notifier).updateFee(amount);
                      setState(() => isSubmitting = false);

                      if (success && context.mounted) {
                        Navigator.pop(context); // Close dialog
                        CustomSnackBar.showSuccess(context, 'Membership fee updated successfully!');
                      } else if (context.mounted) {
                        CustomSnackBar.showError(context, 'Failed to update fee.');
                      }
                    },
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextHint)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController(); // NEW CONTROLLER
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            elevation: 10,
            child: SingleChildScrollView( // Added scroll view to prevent overflow when keyboard opens
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_person_outlined, size: 60.sp, color: AppColors.kPrimaryColor),
                    SizedBox(height: 16.h),
                    Text(
                      'Change Password',
                      style: AppTextStyles.h2Bold,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Update your admin dashboard password for security.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    CustomTextField(
                      label: 'Current Password',
                      hintText: 'Enter current password',
                      controller: currentPasswordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.kTextHint),
                    ),
                    SizedBox(height: 16.h),
                    CustomTextField(
                      label: 'New Password',
                      hintText: 'Enter new password',
                      controller: newPasswordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_reset, color: AppColors.kTextHint),
                    ),
                    SizedBox(height: 16.h),
                    // NEW: Confirm Password Field
                    CustomTextField(
                      label: 'Confirm New Password',
                      hintText: 'Re-enter new password',
                      controller: confirmPasswordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.verified_user_outlined, color: AppColors.kTextHint),
                    ),
                    SizedBox(height: 24.h),
                    CustomButton(
                      text: 'Update Password',
                      isLoading: isSubmitting,
                      onPressed: () async {
                        final currentPass = currentPasswordController.text.trim();
                        final newPass = newPasswordController.text.trim();
                        final confirmPass = confirmPasswordController.text.trim();

                        // 1. Check if any fields are empty
                        if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                          CustomSnackBar.showError(context, 'Please fill all fields');
                          return;
                        }

                        // 2. Check if the new passwords match locally
                        if (newPass != confirmPass) {
                          CustomSnackBar.showError(context, 'New passwords do not match!');
                          return;
                        }

                        // 3. Send ONLY currentPass and newPass to backend
                        setState(() => isSubmitting = true);
                        final success = await ref.read(adminAuthViewModelProvider.notifier).changePassword(currentPass, newPass);
                        setState(() => isSubmitting = false);

                        if (success && context.mounted) {
                          Navigator.pop(context); // Close dialog
                          CustomSnackBar.showSuccess(context, 'Password changed successfully!');
                        } else if (context.mounted) {
                          CustomSnackBar.showError(context, 'Failed to change password. Please check your current password.');
                        }
                      },
                    ),
                    SizedBox(height: 8.h),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextHint)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      color: AppColors.kSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: AppColors.kBorderColor, width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.kPrimaryColor, size: 24.sp),
        ),
        title: Text(title, style: AppTextStyles.labelBold),
        subtitle: Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextSecondary)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16.sp, color: AppColors.kTextHint),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Settings', style: AppTextStyles.h2Bold),
          SizedBox(height: 8.h),
          Text(
            'Manage app configurations and security preferences.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextSecondary),
          ),
          SizedBox(height: 32.h),

          _buildSettingTile(
            context,
            title: 'Update Membership Fee',
            subtitle: 'Change the lifetime registration cost',
            icon: Icons.currency_rupee,
            onTap: () => _showUpdateFeeDialog(context, ref),
          ),
          SizedBox(height: 16.h),

          _buildSettingTile(
            context,
            title: 'Manage Regions',
            subtitle: 'Add or toggle regions for the applicant form',
            icon: Icons.map_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminRegionsScreen()),
              );
            },
          ),
          SizedBox(height: 16.h),

          _buildSettingTile(
            context,
            title: 'Change Password',
            subtitle: 'Update your admin portal password',
            icon: Icons.security_outlined,
            onTap: () => _showChangePasswordDialog(context, ref),
          ),
        ],
      ),
    );
  }
}