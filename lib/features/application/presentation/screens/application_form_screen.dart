import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/file_picker_box.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../data/application_repository.dart';
import '../viewmodels/application_viewmodel.dart';

class ApplicationFormScreen extends ConsumerStatefulWidget {
  const ApplicationFormScreen({super.key});

  @override
  ConsumerState<ApplicationFormScreen> createState() =>
      _ApplicationFormScreenState();
}

class _ApplicationFormScreenState
    extends ConsumerState<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _marriageDateCtrl = TextEditingController();
  final _permAddressCtrl = TextEditingController();
  final _currAddressCtrl = TextEditingController();
  final _eduCtrl = TextEditingController();
  final _occCtrl = TextEditingController();
  final _officeAddressCtrl = TextEditingController();

  // Dropdown States
  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _isFromRaipur = false;
  String? _selectedRegion;

  // Proposer State
  Map<String, dynamic>? _selectedProposer;
  final _proposerSearchCtrl = TextEditingController();

  // File States
  File? _applicantPhoto;
  File? _applicantSignature;
  File? _aadharFront;
  File? _aadharBack;

  bool _agreedToDeclaration = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _marriageDateCtrl.dispose();
    _permAddressCtrl.dispose();
    _currAddressCtrl.dispose();
    _eduCtrl.dispose();
    _occCtrl.dispose();
    _officeAddressCtrl.dispose();
    _proposerSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990), // Default starting year
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.kPrimaryColor, // Orange header
              onPrimary: Colors.white,
              onSurface: AppColors.kTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Formats date as YYYY-MM-DD
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage(void Function(File?) onPicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => onPicked(File(pickedFile.path)));
    }
  }

  Future<void> _pickFileOrImage(void Function(File?) onPicked) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => onPicked(File(result.files.single.path!)));
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_applicantPhoto == null ||
        _applicantSignature == null ||
        _aadharFront == null ||
        _aadharBack == null) {
      CustomSnackBar.showError(
          context, 'Please upload all required photos and documents.');
      return;
    }

    if (_selectedGender == null) {
      CustomSnackBar.showError(context, 'Please select your gender.');
      return;
    }

    if (_isFromRaipur && _selectedRegion == null) {
      CustomSnackBar.showError(
          context, 'Please select a region since you are from Raipur.');
      return;
    }

    if (_selectedProposer == null) {
      CustomSnackBar.showError(
          context, 'Please search and select a proposer member.');
      return;
    }

    if (!_agreedToDeclaration) {
      CustomSnackBar.showError(
          context, 'You must agree to the terms and declaration.');
      return;
    }

    // FIX 1: Added null assertion (!) on _selectedProposer — safe here because
    // we already returned early above if _selectedProposer == null.
    final data = {
      'full_name': _fullNameCtrl.text.trim(),
      'father_or_husband_name': _fatherNameCtrl.text.trim(),
      'gender': _selectedGender,
      'date_of_birth': _dobCtrl.text.trim(),
      'marriage_date': _marriageDateCtrl.text.trim(),
      'blood_group': _selectedBloodGroup,
      'mobile_number': _mobileCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'permanent_address': _permAddressCtrl.text.trim(),
      'current_address': _currAddressCtrl.text.trim(),
      'is_from_raipur': _isFromRaipur.toString(),
      'region': _isFromRaipur ? _selectedRegion : '',
      'education': _eduCtrl.text.trim(),
      'occupation': _occCtrl.text.trim(),
      'office_address': _officeAddressCtrl.text.trim(),
      'proposer_member_id': _selectedProposer!['id'],  // FIX 1 applied here
      'declaration': 'true',
    };

    final success =
    await ref.read(applicationSubmitProvider.notifier).submitForm(
      textData: data,
      applicantPhoto: _applicantPhoto!,
      applicantSignature: _applicantSignature!,
      aadharFront: _aadharFront!,
      aadharBack: _aadharBack!,
    );

    if (success && mounted) {
      context.go('/success');
    } else if (mounted) {
      final errorState = ref.read(applicationSubmitProvider).error;
      CustomSnackBar.showError(
          context, errorState.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(applicationSubmitProvider).isLoading;
    final regionsAsync = ref.watch(regionsProvider);

    return Scaffold(
      appBar:
      const CustomAppBar(title: 'Membership Application', showBackButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal Details',
                    style: AppTextStyles.h2Bold
                        .copyWith(color: AppColors.kPrimaryColor)),
                SizedBox(height: 16.h),

                CustomTextField(
                  label: 'Full Name *',
                  controller: _fullNameCtrl,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  label: 'Father/Husband Name *',
                  controller: _fatherNameCtrl,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),

                // Gender Dropdown
                // FIX 3: Replaced deprecated `value` with `initialValue`.
                // Since we need controlled state (setState on change), we keep
                // `value` as the source of truth and pass it to `initialValue`
                // only for the initial render. Use a Key to force rebuild when
                // _selectedGender changes externally if needed.
                Text('Gender *', style: AppTextStyles.labelBold),
                SizedBox(height: 6.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,  // FIX 3: was `value:`
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => _selectedGender = val),
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, _dobCtrl),
                        child: IgnorePointer(
                          child: CustomTextField(
                            label: 'Date of Birth *',
                            hintText: 'YYYY-MM-DD', // Updated hint
                            suffixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.kTextHint), // Added calendar icon
                            controller: _dobCtrl,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
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
                            hintText: 'YYYY-MM-DD', // Updated hint
                            suffixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.kTextHint), // Added calendar icon
                            controller: _marriageDateCtrl,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                Text('Blood Group *', style: AppTextStyles.labelBold),
                SizedBox(height: 6.h),
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: const InputDecoration(),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((bg) {
                    return DropdownMenuItem(value: bg, child: Text(bg));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBloodGroup = val),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                SizedBox(height: 24.h),

                Text('Contact & Address',
                    style: AppTextStyles.h2Bold
                        .copyWith(color: AppColors.kPrimaryColor)),
                SizedBox(height: 16.h),

                CustomTextField(
                  label: 'Mobile Number *',
                  controller: _mobileCtrl,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                  v!.length != 10 ? 'Enter valid 10 digit number' : null,
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  label: 'Email Address *',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  v!.isEmpty || !v.contains('@') ? 'Enter valid email' : null,
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  label: 'Current Address *',
                  controller: _currAddressCtrl,
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  label: 'Permanent Address *',
                  controller: _permAddressCtrl,
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),

                // FIX 4: Replaced deprecated `activeColor` with `activeThumbColor`
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title:
                  Text('Are you from Raipur? *', style: AppTextStyles.labelBold),
                  activeThumbColor: AppColors.kPrimaryColor, // FIX 4 applied
                  value: _isFromRaipur,
                  onChanged: (val) {
                    setState(() {
                      _isFromRaipur = val;
                      if (!val) _selectedRegion = null;
                    });
                  },
                ),

                if (_isFromRaipur) ...[
                  SizedBox(height: 8.h),
                  Text('Region *', style: AppTextStyles.labelBold),
                  SizedBox(height: 6.h),
                  regionsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Failed to load regions', style: AppTextStyles.errorText),
                    data: (regions) {
                      // ADDED: Check if the backend returned an empty list
                      if (regions.isEmpty) {
                        return Text('No regions found in database. Please add them in the backend.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.kErrorColor));
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedRegion,
                        decoration: const InputDecoration(),
                        items: regions.map((r) => DropdownMenuItem<String>(
                          value: r['name'] as String,
                          child: Text(r['name'] as String),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedRegion = val),
                      );
                    },
                  ),
                ],
                SizedBox(height: 24.h),

                CustomTextField(
                  label: 'Education *',
                  controller: _eduCtrl,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  label: 'Occupation *',
                  controller: _occCtrl,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  label: 'Office Address',
                  controller: _officeAddressCtrl,
                  maxLines: 2,
                  hintText: 'Optional',
                ),
                SizedBox(height: 24.h),

                Text('Documents & Proposer',
                    style: AppTextStyles.h2Bold
                        .copyWith(color: AppColors.kPrimaryColor)),
                SizedBox(height: 16.h),

                // Proposer Autocomplete
                Text('Search Proposer Member *', style: AppTextStyles.labelBold),
                SizedBox(height: 6.h),
                Autocomplete<Map<String, dynamic>>(
                  // Show Name and Mobile Number in the selected text box
                  displayStringForOption: (option) {
                    final name = option['fullName'] ?? option['name'] ?? 'Unknown';
                    final mobile = option['mobileNumber'] ?? 'No Number';
                    return '$name - $mobile';
                  },
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.length < 2) {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }

                    // 1. Fetch results from backend
                    final results = await ref
                        .read(applicationRepositoryProvider)
                        .searchMembers(textEditingValue.text);

                    // 2. Enforce Strict Prefix Search (Starts With)
                    final typed = textEditingValue.text.toLowerCase();
                    final filteredResults = results.where((user) {
                      final name = (user['fullName'] ?? user['name'] ?? '').toString().toLowerCase();
                      final mobile = (user['mobileNumber'] ?? '').toString().toLowerCase();

                      // Only keep users whose name OR mobile starts with the exact typed letters
                      return name.startsWith(typed) || mobile.startsWith(typed);
                    }).toList();

                    return filteredResults.cast<Map<String, dynamic>>();
                  },
                  onSelected: (selection) {
                    setState(() => _selectedProposer = selection);
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Type member name or number...',
                        prefixIcon: Icon(Icons.search, color: AppColors.kTextHint),
                      ),
                    );
                  },
                  // Custom UI for the dropdown list to show Name (title) and Mobile (subtitle)
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 200.h, maxWidth: 300.w),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              final name = option['fullName'] ?? option['name'] ?? 'Unknown';
                              final mobile = option['mobileNumber'] ?? 'No Number';
                              return ListTile(
                                title: Text(name as String, style: AppTextStyles.labelBold),
                                subtitle: Text(mobile as String, style: AppTextStyles.bodyMedium),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

                if (_selectedProposer != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Selected: ${_selectedProposer!['fullName'] ?? _selectedProposer!['name']} - ${_selectedProposer!['mobileNumber'] ?? 'No Number'}',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.green),
                    ),
                  ),
                SizedBox(height: 24.h),

                Row(
                  children: [
                    Expanded(
                      child: FilePickerBox(
                        label: 'Applicant Photo *',
                        file: _applicantPhoto,
                        onTap: () => _pickImage((f) => _applicantPhoto = f),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: FilePickerBox(
                        label: 'Signature *',
                        file: _applicantSignature,
                        onTap: () =>
                            _pickImage((f) => _applicantSignature = f),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: FilePickerBox(
                        label: 'Aadhar Front *',
                        file: _aadharFront,
                        onTap: () =>
                            _pickFileOrImage((f) => _aadharFront = f),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: FilePickerBox(
                        label: 'Aadhar Back *',
                        file: _aadharBack,
                        onTap: () =>
                            _pickFileOrImage((f) => _aadharBack = f),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.kPrimaryColor,
                  title: Text(
                    'I agree to the rules of the Maharashtra Mandal.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  value: _agreedToDeclaration,
                  onChanged: (val) =>
                      setState(() => _agreedToDeclaration = val ?? false),
                ),
                SizedBox(height: 32.h),

                CustomButton(
                  text: 'Submit Application',
                  isLoading: isLoading,
                  onPressed: _submitForm,
                ),

                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/admin/login'),
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
                    label: const Text(
                      'Admin Login',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 48.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}