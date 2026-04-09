import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/empty_error_widget.dart';
import '../../../admin_auth/data/admin_auth_repository.dart';
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

    return applicantsState.when(
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
            // This forces Riverpod to fetch fresh data from the Node.js backend
            ref.invalidate(applicantsListProvider);
            // Optional delay to ensure the UI shows the spinner briefly
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            // AlwaysScrollable ensures Pull-to-Refresh works even if there's only 1 item
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
                  _formatStatus(applicant['status']), // Using our new beautiful formatter
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.kPrimaryColor, // Adding a little color to the status
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

class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab();

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  final _feeController = TextEditingController();

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feeState = ref.watch(feeUpdateViewModelProvider);

    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Settings', style: AppTextStyles.h2Bold),
          SizedBox(height: 24.h),
          CustomTextField(
            label: 'Update Membership Fee (₹)',
            controller: _feeController,
            keyboardType: TextInputType.number,
            hintText: 'e.g. 5000',
          ),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Save Changes',
            isLoading: feeState.isLoading,
            onPressed: () async {
              final amount = double.tryParse(_feeController.text);
              if (amount == null) {
                CustomSnackBar.showError(
                    context, 'Please enter a valid amount');
                return;
              }
              final success = await ref
                  .read(feeUpdateViewModelProvider.notifier)
                  .updateFee(amount);

              if (success && context.mounted) {
                CustomSnackBar.showSuccess(
                    context, 'Fee updated successfully!');
                _feeController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}