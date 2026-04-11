import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/empty_error_widget.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';

class AdminRegionsScreen extends ConsumerWidget {
  const AdminRegionsScreen({super.key});

  void _showAddRegionDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
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
                  Icon(Icons.map_outlined, size: 60.sp, color: AppColors.kPrimaryColor),
                  SizedBox(height: 16.h),
                  Text(
                    'Add New Region',
                    style: AppTextStyles.h2Bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Enter the name of the new region to make it available in the applicant form.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  CustomTextField(
                    label: 'Region Name',
                    hintText: 'e.g., Raipur City',
                    controller: nameController,
                    prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.kTextHint),
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    text: 'Save Region',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final name = nameController.text.trim();

                      if (name.isEmpty) {
                        CustomSnackBar.showError(context, 'Please enter a region name');
                        return;
                      }

                      setState(() => isSubmitting = true);
                      final success = await ref.read(regionActionProvider.notifier).addRegion(name);
                      setState(() => isSubmitting = false);

                      if (success && context.mounted) {
                        Navigator.pop(context); // Close dialog
                        CustomSnackBar.showSuccess(context, 'Region added successfully!');
                        ref.invalidate(regionsListProvider); // Refresh the list
                      } else if (context.mounted) {
                        CustomSnackBar.showError(context, 'Failed to add region. It might already exist.');
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionsAsync = ref.watch(regionsListProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage Regions'),
      body: regionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
        error: (err, _) => EmptyErrorWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(regionsListProvider),
        ),
        data: (regions) {
          if (regions.isEmpty) {
            return const EmptyErrorWidget(
              message: 'No regions found. Add one below!',
                icon: Icons.location_off,
            );
          }

          return RefreshIndicator(
            color: AppColors.kPrimaryColor,
            onRefresh: () async {
              ref.invalidate(regionsListProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              itemCount: regions.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final region = regions[index];
                final bool isActive = region['isActive'] == true;

                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    leading: CircleAvatar(
                      backgroundColor: isActive ? AppColors.kPrimaryLight : Colors.grey.shade200,
                      child: Icon(
                        Icons.location_on,
                        color: isActive ? AppColors.kPrimaryColor : Colors.grey,
                      ),
                    ),
                    title: Text(region['name'] ?? 'Unknown', style: AppTextStyles.labelBold),
                    subtitle: Text(
                      isActive ? 'Active - Visible in Form' : 'Hidden - Not visible',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Switch(
                      value: isActive,
                      activeThumbColor: AppColors.kPrimaryColor,
                      onChanged: (val) async {
                        final success = await ref.read(regionActionProvider.notifier).toggleRegion(region['id']);
                        if (success && context.mounted) {
                          CustomSnackBar.showSuccess(context, 'Region status updated!');
                          ref.invalidate(regionsListProvider);
                        } else if (context.mounted) {
                          CustomSnackBar.showError(context, 'Failed to update region status.');
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Region', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddRegionDialog(context, ref),
      ),
    );
  }
}