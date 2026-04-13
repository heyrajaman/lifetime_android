import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/empty_error_widget.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  // Helper to format camelCase keys (e.g., 'totalMembers' -> 'Total Members')
  String _formatKey(String key) {
    final formatted = key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  IconData _getIconForKey(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('revenue')) return Icons.currency_rupee;
    if (lowerKey.contains('member')) return Icons.people_alt;
    if (lowerKey.contains('pending') || lowerKey.contains('review')) return Icons.pending_actions;
    return Icons.bar_chart;
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(statsDateRangeProvider);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.kPrimaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // This will automatically trigger the dashboardStatsProvider to fetch new data!
      ref.read(statsDateRangeProvider.notifier).state = picked;
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final dateRange = ref.read(statsDateRangeProvider);

    String? start;
    String? end;

    if (dateRange != null) {
      start = dateRange.start.toIso8601String();
      end = dateRange.end.toIso8601String();
    }

    final bytes = await ref
        .read(exportReportViewModelProvider.notifier)
        .downloadReport(
      startDate: start,
      endDate: end,
    );

    if (!context.mounted) return;

    if (bytes != null && bytes.isNotEmpty) {
      try {
        final fileName =
            'Lifetime_Report_${DateTime.now().millisecondsSinceEpoch}.csv';

        // ✅ FIX: remove 'ext' and include extension in name
        final String? savedFilePath = await FileSaver.instance.saveAs(
          name: fileName,
          bytes: Uint8List.fromList(bytes),
          fileExtension: 'csv',
          mimeType: MimeType.csv,
        );

        if (!context.mounted) return;

        if (savedFilePath != null) {
          CustomSnackBar.showSuccess(
              context, 'Report saved successfully!');
        }
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Failed to download report or no data found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final dateRange = ref.watch(statsDateRangeProvider);
    final isDownloading = ref.watch(exportReportViewModelProvider).isLoading;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Analytics & Reports'),
      body: Column(
        children: [
          // --- FILTER BAR ---
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: AppColors.kSurfaceColor,
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: AppColors.kPrimaryColor, size: 24.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    dateRange == null
                        ? 'All Time'
                        : '${DateFormat('MMM d, yyyy').format(dateRange.start)} - ${DateFormat('MMM d, yyyy').format(dateRange.end)}',
                    style: AppTextStyles.labelBold,
                  ),
                ),
                TextButton(
                  onPressed: () => _pickDateRange(context, ref),
                  child: Text(
                    dateRange == null ? 'Filter Date' : 'Change Date',
                    style: const TextStyle(color: AppColors.kPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                if (dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.kErrorColor),
                    onPressed: () => ref.read(statsDateRangeProvider.notifier).state = null,
                  )
              ],
            ),
          ),
          const Divider(height: 1),

          // --- STATS GRID ---
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
              error: (err, _) => EmptyErrorWidget(
                message: err.toString(),
                onRetry: () => ref.refresh(dashboardStatsProvider),
              ),
              data: (statsData) {
                if (statsData.isEmpty) {
                  return const EmptyErrorWidget(message: 'No data available for this period.', icon: Icons.analytics_outlined);
                }

                return RefreshIndicator(
                  color: AppColors.kPrimaryColor,
                  onRefresh: () async {
                    ref.invalidate(dashboardStatsProvider);
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.all(16.w),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: statsData.length,
                    itemBuilder: (context, index) {
                      final key = statsData.keys.elementAt(index);
                      final value = statsData[key];

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () {
                            CustomSnackBar.showSuccess(
                                context, 'This shows the total ${_formatKey(key).toLowerCase()} for the selected period.');
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_getIconForKey(key), color: AppColors.kPrimaryColor, size: 28.sp),
                                SizedBox(height: 8.h),
                                Text(
                                  key.toLowerCase().contains('revenue') ? '₹$value' : value.toString(),
                                  style: AppTextStyles.h1Extrabold.copyWith(color: AppColors.kPrimaryColor),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _formatKey(key),
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kTextSecondary),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: CustomButton(
                text: 'Download CSV Report',
                isLoading: isDownloading,
                onPressed: () => _handleDownload(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }
}