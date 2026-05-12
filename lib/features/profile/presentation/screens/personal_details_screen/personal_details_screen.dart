import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/presentation/providers/profile_provider.dart';

class PersonalDetailsScreen extends ConsumerStatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  ConsumerState<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends ConsumerState<PersonalDetailsScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();

  File? _pickedImage;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _initials(String fullName) {
    final parts =
        fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatJoinedDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final xFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (xFile != null) {
      setState(() => _pickedImage = File(xFile.path));
    }
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primaryGreen),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primaryGreen),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();

    if (fullName.isEmpty) {
      _showSnackBar('Full name cannot be empty', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final result = await ref.read(profileNotifierProvider.notifier).updateProfile(
          fullName: fullName,
          email: email.isEmpty ? null : email,
          imagePath: _pickedImage?.path,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    switch (result) {
      case Success():
        _showSnackBar('Profile updated successfully');
        setState(() => _pickedImage = null); // clear local pick; state has new data
      case Failure(:final exception):
        final msg = exception is AppException
            ? exception.message
            : 'Something went wrong. Please try again.';
        _showSnackBar(msg, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : AppColors.primaryGreen,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final profileState = ref.watch(profileNotifierProvider);

    if (profileState is ProfileSuccess && !_initialized) {
      _fullNameController.text = profileState.response.fullName;
      _emailController.text = profileState.response.email;
      _initialized = true;
    }

    final phoneNumber =
        profileState is ProfileSuccess ? profileState.response.phoneNumber : '';
    final employeeCode =
        profileState is ProfileSuccess ? profileState.response.employeeCode : '';
    final joinedDate = profileState is ProfileSuccess
        ? _formatJoinedDate(profileState.response.createdAt)
        : '';
    final serverImage = profileState is ProfileSuccess
        ? profileState.response.profileImage
        : null;
    final avatarInitials = profileState is ProfileSuccess
        ? _initials(profileState.response.fullName)
        : '?';

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: _isSaving ? null : () => context.pop(),
        ),
        title: Text(
          'Personal Details',
          style: AppTextStyles.labelR(context).copyWith(
            fontSize: AppResponsive.sp(context, 16),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          _isSaving
              ? Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: AppTextStyles.labelR(context).copyWith(
                      fontSize: AppResponsive.sp(context, 15),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.cardWhite,
              padding: EdgeInsets.symmetric(
                vertical: AppResponsive.r(context, 24),
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildAvatar(
                      context,
                      initials: avatarInitials,
                      serverImage: serverImage,
                      pickedImage: _pickedImage,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isSaving ? null : _pickImage,
                        child: Container(
                          width: AppResponsive.r(context, 30),
                          height: AppResponsive.r(context, 30),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cardWhite,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: AppResponsive.r(context, 14),
                            color: AppColors.cardWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Form fields ───────────────────────────────────────────────
            Container(
              color: AppColors.cardWhite,
              padding: EdgeInsets.fromLTRB(
                hPad,
                AppResponsive.r(context, 4),
                hPad,
                AppResponsive.r(context, 20),
              ),
              child: Column(
                children: [
                  _buildEditableField(
                    context,
                    label: 'Full Name',
                    controller: _fullNameController,
                    hint: 'Enter your full name',
                  ),
                  _buildReadOnlyField(
                    context,
                    label: 'Mobile Number',
                    value: phoneNumber,
                  ),
                  _buildEditableField(
                    context,
                    label: 'Email Address',
                    controller: _emailController,
                    hint: 'Enter email address',
                    keyboardType: TextInputType.emailAddress,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Employment Details ─────────────────────────────────────────
            Container(
              margin: EdgeInsets.symmetric(horizontal: hPad),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              padding: EdgeInsets.all(AppResponsive.r(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employment Details',
                    style: AppTextStyles.labelR(context).copyWith(
                      fontSize: AppResponsive.sp(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: AppResponsive.r(context, 16)),
                  _buildEmploymentRow(context, 'Employee ID', employeeCode),
                  SizedBox(height: AppResponsive.r(context, 12)),
                  _buildEmploymentRow(context, 'Joined', joinedDate),
                  SizedBox(height: AppResponsive.r(context, 12)),
                  _buildEmploymentRow(context, 'Region', 'Kathmandu Zone'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Update button ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: SizedBox(
                width: double.infinity,
                height: AppResponsive.r(context, 52),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.cardWhite,
                    disabledBackgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.cardWhite,
                          ),
                        )
                      : Text(
                          'Update Information',
                          style: AppTextStyles.buttonTextR(context),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────────

  Widget _buildAvatar(
    BuildContext context, {
    required String initials,
    String? serverImage,
    File? pickedImage,
  }) {
    final radius = AppResponsive.r(context, 42);

    ImageProvider? imageProvider;
    if (pickedImage != null) {
      imageProvider = FileImage(pickedImage);
    } else if (serverImage != null && serverImage.isNotEmpty) {
      final url = serverImage.startsWith('http')
          ? serverImage
          : '${ApiConstant.baseUrl}/$serverImage';
      imageProvider = NetworkImage(url);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.lightGreenCircle,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              initials,
              style: AppTextStyles.heading1R(context).copyWith(
                fontSize: AppResponsive.sp(context, 28),
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            )
          : null,
    );
  }

  Widget _buildEditableField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String hint = '',
    TextInputType? keyboardType,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppResponsive.r(context, 16)),
        Text(
          label,
          style: AppTextStyles.labelR(context).copyWith(
            fontSize: AppResponsive.sp(context, 12),
            color: AppColors.textGray,
            fontWeight: FontWeight.w400,
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: !_isSaving,
          style: AppTextStyles.inputTextR(context).copyWith(
            fontSize: AppResponsive.sp(context, 14),
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputHintR(context).copyWith(
              fontSize: AppResponsive.sp(context, 14),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: AppResponsive.r(context, 8),
            ),
            isDense: true,
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppResponsive.r(context, 16)),
        Text(
          label,
          style: AppTextStyles.labelR(context).copyWith(
            fontSize: AppResponsive.sp(context, 12),
            color: AppColors.textGray,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: AppResponsive.r(context, 8)),
        Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? '+977 98XX XXXX XX' : value,
                style: AppTextStyles.inputTextR(context).copyWith(
                  fontSize: AppResponsive.sp(context, 14),
                  color:
                      value.isEmpty ? AppColors.textLight : AppColors.textDark,
                ),
              ),
            ),
            Icon(
              Icons.lock_outline,
              size: AppResponsive.r(context, 18),
              color: AppColors.textGray,
            ),
          ],
        ),
        SizedBox(height: AppResponsive.r(context, 8)),
        const Divider(height: 1, thickness: 1, color: AppColors.inputBorder),
      ],
    );
  }

  Widget _buildEmploymentRow(
      BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.labelR(context).copyWith(
            fontSize: AppResponsive.sp(context, 13),
            color: AppColors.textGray,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value.isEmpty ? '—' : value,
          style: AppTextStyles.labelR(context).copyWith(
            fontSize: AppResponsive.sp(context, 13),
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
