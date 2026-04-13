import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/empty_error_widget.dart';
import '../viewmodels/approval_viewmodel.dart';

class ApprovalScreen extends ConsumerStatefulWidget {
  final String role;
  final String? token;

  const ApprovalScreen({
    super.key,
    required this.role,
    this.token,
  });

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen> {
  bool _isActionComplete = false;
  String _completeMessage = '';

  void _handleAction(String action) async {
    if (widget.token == null) return;

    final success = await ref.read(approvalSubmitProvider.notifier).submitAction(
      widget.role,
      widget.token!,
      action,
    );

    if (success && mounted) {
      setState(() {
        _isActionComplete = true;
        _completeMessage = action == 'APPROVE'
            ? 'Application successfully approved.'
            : 'Application has been rejected.';
      });
    } else if (mounted) {
      final errorState = ref.read(approvalSubmitProvider).error;
      CustomSnackBar.showError(context, errorState.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null || widget.token!.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: '${widget.role.toUpperCase()} Approval'),
        body: const EmptyErrorWidget(message: 'Invalid access token.'),
      );
    }

    if (_isActionComplete) {
      return Scaffold(
        appBar: CustomAppBar(title: '${widget.role.toUpperCase()} Approval'),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 80.sp),
                SizedBox(height: 16.h),
                Text(
                  _completeMessage,
                  style: AppTextStyles.h2Bold,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final params = ApprovalParams(widget.token!, widget.role);
    final detailsAsync = ref.watch(approvalDetailsProvider(params));
    final isSubmitting = ref.watch(approvalSubmitProvider).isLoading;

    return Scaffold(
      appBar: CustomAppBar(title: 'Review Application'),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
        error: (err, _) => EmptyErrorWidget(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.refresh(approvalDetailsProvider(params)),
        ),
        data: (data) {
          // The API might return applicant under 'applicant' key based on the backend structure
          final applicant = data['applicant'] ?? data;

          return SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Applicant Details', style: AppTextStyles.h2Bold.copyWith(color: AppColors.kPrimaryColor)),
                SizedBox(height: 16.h),

                _buildInfoRow('Name', applicant['fullName']),
                _buildInfoRow('Father/Husband', applicant['fatherOrHusbandName']),
                _buildInfoRow('Gender', applicant['gender']),
                _buildInfoRow('Mobile', applicant['mobileNumber']),
                _buildInfoRow('Email', applicant['email']),
                _buildInfoRow('Current Address', applicant['currentAddress']),
                _buildInfoRow('Occupation', applicant['occupation']),

                SizedBox(height: 32.h),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Reject',
                        variant: ButtonVariant.outlined,
                        isLoading: isSubmitting,
                        onPressed: () => _handleAction('REJECT'),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomButton(
                        text: 'Approve',
                        isLoading: isSubmitting,
                        onPressed: () => _handleAction('APPROVE'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(label, style: AppTextStyles.labelBold.copyWith(color: AppColors.kTextHint)),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}