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
import '../viewmodels/edit_application_viewmodel.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';

class EditApplicationScreen extends ConsumerWidget {
  final String applicantId;

  const EditApplicationScreen({super.key, required this.applicantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantAsync = ref.watch(applicantDetailsProvider(applicantId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Review Application'),
      body: applicantAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
        error: (err, _) => EmptyErrorWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(applicantDetailsProvider(applicantId)),
        ),
        data: (applicantData) {
          return _EditApplicationForm(
            applicantId: applicantId,
            initialData: applicantData['applicant'] ?? applicantData,
          );
        },
      ),
    );
  }
}

// --- Stateful Form for Prepopulating Data ---
class _EditApplicationForm extends ConsumerStatefulWidget {
  final String applicantId;
  final Map<String, dynamic> initialData;

  const _EditApplicationForm({
    required this.applicantId,
    required this.initialData,
  });

  @override
  ConsumerState<_EditApplicationForm> createState() =>
      _EditApplicationFormState();
}

class _EditApplicationFormState extends ConsumerState<_EditApplicationForm> {
  // All Controllers
  final _regNumCtrl = TextEditingController();
  late TextEditingController _nameCtrl;
  late TextEditingController _fatherNameCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _marriageDateCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _educationCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _currentAddressCtrl;
  late TextEditingController _permanentAddressCtrl;
  late TextEditingController _officeAddressCtrl;
  late TextEditingController _regionCtrl;

  // Dropdown & Toggle States
  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _isFromRaipur = false;

  // Helper to format dates coming from the backend (removes the time portion)
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    if (dateStr.length >= 10) return dateStr.substring(0, 10);
    return dateStr;
  }

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    print('🟢 APPLICANT RAW JSON: $data');

    _nameCtrl = TextEditingController(text: data['fullName'] ?? '');
    _fatherNameCtrl = TextEditingController(text: data['fatherOrHusbandName'] ?? '');
    _dobCtrl = TextEditingController(text: _formatDate(data['dateOfBirth']));
    _marriageDateCtrl = TextEditingController(text: _formatDate(data['marriageDate']));
    _mobileCtrl = TextEditingController(text: data['mobileNumber'] ?? '');
    _emailCtrl = TextEditingController(text: data['email'] ?? '');
    _educationCtrl = TextEditingController(text: data['education'] ?? '');
    _occupationCtrl = TextEditingController(text: data['occupation'] ?? '');
    _currentAddressCtrl = TextEditingController(text: data['currentAddress'] ?? '');
    _permanentAddressCtrl = TextEditingController(text: data['permanentAddress'] ?? '');
    _officeAddressCtrl = TextEditingController(text: data['officeAddress'] ?? '');
    _regionCtrl = TextEditingController(text: data['region'] ?? '');

    _selectedGender = data['gender'];
    _selectedBloodGroup = data['bloodGroup'];
    _isFromRaipur = data['isFromRaipur'] == true || data['isFromRaipur'] == 'true';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _dobCtrl.dispose();
    _marriageDateCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _educationCtrl.dispose();
    _occupationCtrl.dispose();
    _currentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    _officeAddressCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _handleSave() async {
    final updateData = {
      'fullName': _nameCtrl.text.trim(),
      'fatherOrHusbandName': _fatherNameCtrl.text.trim(),
      'gender': _selectedGender,
      'dateOfBirth': _dobCtrl.text.trim(),
      'marriageDate': _marriageDateCtrl.text.trim(),
      'bloodGroup': _selectedBloodGroup,
      'education': _educationCtrl.text.trim(),
      'occupation': _occupationCtrl.text.trim(),
      'mobileNumber': _mobileCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'currentAddress': _currentAddressCtrl.text.trim(),
      'permanentAddress': _permanentAddressCtrl.text.trim(),
      'officeAddress': _officeAddressCtrl.text.trim(),
      'isFromRaipur': _isFromRaipur,
      'region': _isFromRaipur ? _regionCtrl.text.trim() : null,
    };

    final success = await ref
        .read(editAppViewModelProvider.notifier)
        .updateApplicant(widget.applicantId, updateData);

    if (success && mounted) {
      CustomSnackBar.showSuccess(context, 'Application updated successfully.');
      ref.invalidate(applicantsListProvider);
    } else if (mounted) {
      final error = ref.read(editAppViewModelProvider).error;
      CustomSnackBar.showError(
          context, error.toString().replaceAll('Exception: ', ''));
    }
  }

  void _handleReview(String action) async {
    // Action MUST be "APPROVE" or "REJECT" per backend DTO
    final success = await ref
        .read(editAppViewModelProvider.notifier)
        .reviewApplicant(widget.applicantId, action);

    if (success && mounted) {
      CustomSnackBar.showSuccess(context, 'Application ${action}D successfully.');
      ref.invalidate(applicantsListProvider);
      context.pop();
    } else if (mounted) {
      final error = ref.read(editAppViewModelProvider).error;
      CustomSnackBar.showError(
          context, error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handlePromote() async {
    final regNum = _regNumCtrl.text.trim();
    if (regNum.isEmpty || regNum.length > 50) {
      CustomSnackBar.showError(context, 'Please enter a valid Registration Number (Max 50 chars).');
      return;
    }

    final success = await ref.read(editAppViewModelProvider.notifier)
        .promoteApplicant(widget.initialData['id'], regNum);

    if (success && mounted) {
      CustomSnackBar.showSuccess(context, 'Applicant officially promoted to Member!');
      ref.invalidate(applicantsListProvider);
      ref.invalidate(membersListProvider);
      context.pop();
    } else if (mounted) {
      CustomSnackBar.showError(context, 'Failed to promote applicant.');
    }
  }

  String? _getFileUrl(String targetType) {
    final files = widget.initialData['files'] as List<dynamic>?;
    if (files == null) return null;

    for (var file in files) {
      // Check if the fileType matches (e.g., 'AADHAR_FRONT')
      if (file['fileType'] == targetType) {
        return file['minioUrl'];
      }
    }
    return null;
  }

  // --- Document Card Builder ---
  Widget _buildDocumentCard(String title, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 120.w,
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(8.r)),
        child: Center(child: Text('No $title\nProvided', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium)),
      );
    }

    // Ensure URL works on the Android Emulator (handles both MinIO absolute URLs and relative local paths)
    String fullUrl = imageUrl;
    if (fullUrl.contains('localhost')) {
      fullUrl = fullUrl.replaceAll('localhost', '10.0.2.2');
    } else if (!fullUrl.startsWith('http')) {
      fullUrl = 'http://10.0.2.2:9000$fullUrl';
    }

    return GestureDetector(
      onTap: () {
        // Show full screen image popup when tapped
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(16.w),
            child: InteractiveViewer( // Allows pinching to zoom!
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(fullUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 120.w,
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.w),
              color: Colors.grey,
              child: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editAppViewModelProvider).isLoading;
    final currentStatus = widget.initialData['status'];

    // --- SMART LOCK LOGIC ---
    // Admin can ONLY edit during their initial review, or right before final promotion (Payment Completed)
    final canEditForm = currentStatus == 'PENDING_ADMIN_REVIEW' || currentStatus == 'PAYMENT_COMPLETED';
    final isLocked = !canEditForm;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.kPrimaryLight,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.kPrimaryColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Status: $currentStatus',
                    style: AppTextStyles.labelBold.copyWith(color: AppColors.kPrimaryHover),
                  ),
                ),
              ],
            ),
          ),

          // Show warning at the top if locked
          if (isLocked) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
              child: Text(
                '🔒 Form is currently locked to prevent accidental changes. You can only edit details during the initial Admin Review or after the applicant completes their fee payment.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.orange),
              ),
            ),
          ],
          SizedBox(height: 24.h),

          // --- AbsorbPointer makes the entire form Read-Only if locked ---
          AbsorbPointer(
            absorbing: isLocked,
            child: Opacity(
              opacity: isLocked ? 0.7 : 1.0, // Dims the form slightly when locked
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Personal Details ---
                  Text('Personal Details', style: AppTextStyles.h2Bold.copyWith(color: AppColors.kPrimaryColor)),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'Full Name', controller: _nameCtrl),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'Father/Husband Name', controller: _fatherNameCtrl),
                  SizedBox(height: 16.h),

                  // Gender & Blood Group
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Gender'),
                          initialValue: _selectedGender,
                          items: const [
                            DropdownMenuItem(value: 'MALE', child: Text('Male')),
                            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                          ],
                          onChanged: (val) => setState(() => _selectedGender = val),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Blood Group'),
                          initialValue: _selectedBloodGroup,
                          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                              .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedBloodGroup = val),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, _dobCtrl),
                          child: IgnorePointer(
                            child: CustomTextField(
                              label: 'Date of Birth',
                              controller: _dobCtrl,
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, _marriageDateCtrl),
                          child: IgnorePointer(
                            child: CustomTextField(
                              label: 'Marriage Date',
                              controller: _marriageDateCtrl,
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // --- Contact Details ---
                  Text('Contact Details', style: AppTextStyles.h2Bold.copyWith(color: AppColors.kPrimaryColor)),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'Mobile Number', controller: _mobileCtrl, keyboardType: TextInputType.phone),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'Current Address', controller: _currentAddressCtrl, maxLines: 2),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'Permanent Address', controller: _permanentAddressCtrl, maxLines: 2),
                  SizedBox(height: 16.h),

                  // Raipur Region Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Is applicant from Raipur?', style: AppTextStyles.labelBold),
                    activeThumbColor: AppColors.kPrimaryColor,
                    value: _isFromRaipur,
                    onChanged: (val) {
                      setState(() {
                        _isFromRaipur = val;
                        if (!val) _regionCtrl.clear();
                      });
                    },
                  ),
                  if (_isFromRaipur) ...[
                    SizedBox(height: 8.h),
                    CustomTextField(label: 'Region', controller: _regionCtrl),
                  ],
                  SizedBox(height: 24.h),

                  // --- Professional Details ---
                  Text('Professional Details', style: AppTextStyles.h2Bold.copyWith(color: AppColors.kPrimaryColor)),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'Education', controller: _educationCtrl),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'Occupation', controller: _occupationCtrl),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'Office Address', controller: _officeAddressCtrl, maxLines: 2),
                ],
              ),
            ),
          ),

          SizedBox(height: 32.h),

          // Hide Save button if locked
          if (canEditForm) ...[
            CustomButton(
              text: 'Save Changes',
              isLoading: isProcessing,
              onPressed: _handleSave,
            ),
            SizedBox(height: 32.h),
            const Divider(),
            SizedBox(height: 24.h),
          ],

          // --- Uploaded Documents Viewer (Always Visible) ---
          Text('Uploaded Documents', style: AppTextStyles.h2Bold.copyWith(color: AppColors.kPrimaryColor)),
          SizedBox(height: 16.h),
          SizedBox(
            height: 140.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildDocumentCard('Applicant Photo', _getFileUrl('PHOTO') ?? _getFileUrl('APPLICANT_PHOTO')),
                _buildDocumentCard('Signature', _getFileUrl('SIGNATURE')),
                _buildDocumentCard('Aadhar Front', _getFileUrl('AADHAR_FRONT')),
                _buildDocumentCard('Aadhar Back', _getFileUrl('AADHAR_BACK')),
              ],
            ),
          ),

          // Admin Actions (Always visible so we can show contextual status boxes)
          SizedBox(height: 32.h),
          const Divider(),
          SizedBox(height: 16.h),
          Text('Admin Actions', style: AppTextStyles.h2Bold),
          SizedBox(height: 8.h),
          _buildSmartAdminActions(currentStatus, isProcessing),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  // --- Helper to draw a nice colorful box for statuses ---
  Widget _buildStatusBox(Color color, String message) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- Helper to show the correct buttons/messages based on workflow status ---
  Widget _buildSmartAdminActions(String? status, bool isProcessing) {

    if (status == 'PENDING_MEMBER_APPROVAL') {
      return _buildStatusBox(Colors.orange, '⏳ Waiting for the Proposer to verify this application.');
    }

    if (status == 'PENDING_PRESIDENT_APPROVAL') {
      // Replaced the ugly grey box with a nice blue one!
      return _buildStatusBox(Colors.blue, '👔 Waiting for the President to review and approve this application.');
    }

    if (status == 'PAYMENT_PENDING') {
      // Replaced the ugly grey box with a nice purple one!
      return _buildStatusBox(Colors.purple, '💳 President Approved! Waiting for the applicant to complete their fee payment.');
    }

    if (status == 'PENDING_ADMIN_REVIEW') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review the documents and details above. If everything is correct, approve the application to send it to the President.', style: AppTextStyles.bodyMedium),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Reject',
                  variant: ButtonVariant.outlined,
                  isLoading: isProcessing,
                  onPressed: () => _handleReview('REJECT'),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CustomButton(
                  text: 'Approve',
                  isLoading: isProcessing,
                  onPressed: () => _handleReview('APPROVE'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (status == 'PAYMENT_COMPLETED') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusBox(Colors.green, '✅ Payment Completed! This applicant is ready to become an official member.'),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Assign Registration Number',
            controller: _regNumCtrl,
            hintText: 'e.g. MM-2026-001',
          ),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Promote to Member',
            isLoading: isProcessing,
            onPressed: _handlePromote,
          ),
        ],
      );
    }

    // Default fallback for any weird states (like REJECTED)
    return _buildStatusBox(Colors.grey, 'No further actions available for the current status: $status');
  }
}