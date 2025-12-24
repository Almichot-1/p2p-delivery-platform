import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _imagePicker = ImagePicker();
  File? _selectedDocument;
  String _documentType = 'passport';

  final List<Map<String, dynamic>> _documentTypes = [
    {'value': 'passport', 'label': 'Passport', 'icon': Icons.book},
    {'value': 'national_id', 'label': 'National ID', 'icon': Icons.badge},
    {
      'value': 'drivers_license',
      'label': "Driver's License",
      'icon': Icons.drive_eta
    },
  ];

  Future<void> _pickDocument() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedDocument = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedDocument = File(pickedFile.path);
      });
    }
  }

  void _submitVerification() {
    if (_selectedDocument == null) {
      Helpers.showErrorSnackBar(context, 'Please select a document');
      return;
    }

    context.read<ProfileBloc>().add(
          ProfileVerificationRequested(
            document: _selectedDocument!,
            documentType: _documentType,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>(),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileVerificationSubmitted) {
            Helpers.showSuccessSnackBar(
              context,
              'Verification submitted! We will review your document.',
            );
            context.pop();
          } else if (state is ProfileError) {
            Helpers.showErrorSnackBar(context, state.message);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Verification'),
          ),
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is! AuthAuthenticated) {
                return const Center(child: CircularProgressIndicator());
              }

              final user = authState.user;

              if (user.verificationStatus == VerificationStatus.verified) {
                return _buildVerifiedView();
              }

              if (user.verificationStatus == VerificationStatus.pending) {
                return _buildPendingView();
              }

              return _buildUploadView();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                size: 60,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'re Verified!',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 12),
            Text(
              'Your identity has been verified. You now have access to all features.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Back to Profile',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty,
                size: 60,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verification Pending',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 12),
            Text(
              'Your documents are being reviewed. This usually takes 1-2 business days.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Back to Profile',
              type: ButtonType.outline,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withAlpha(77),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verify your identity to build trust with other users and unlock all features.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Document type selection
          const Text('Select Document Type', style: AppTextStyles.h6),
          const SizedBox(height: 12),
          ...List.generate(_documentTypes.length, (index) {
            final type = _documentTypes[index];
            final isSelected = _documentType == type['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _documentType = type['value'];
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withAlpha(26)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      color: isSelected ? AppColors.primary : AppColors.grey600,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      type['label'] as String,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Document upload
          const Text('Upload Document', style: AppTextStyles.h6),
          const SizedBox(height: 12),

          if (_selectedDocument != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedDocument!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDocument = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.grey300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload your document',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDocument,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Guidelines
          const Text('Guidelines', style: AppTextStyles.h6),
          const SizedBox(height: 12),
          _buildGuideline(
            icon: Icons.image,
            text: 'Upload a clear, high-quality image',
          ),
          _buildGuideline(
            icon: Icons.crop_free,
            text: 'Ensure all corners of the document are visible',
          ),
          _buildGuideline(
            icon: Icons.lightbulb,
            text: 'Good lighting, no glare or shadows',
          ),
          _buildGuideline(
            icon: Icons.security,
            text: 'Your document is encrypted and secure',
          ),
          const SizedBox(height: 32),

          // Submit button
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return CustomButton(
                text: 'Submit for Verification',
                onPressed:
                    _selectedDocument != null ? _submitVerification : null,
                isLoading: state is ProfileLoading,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuideline({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
