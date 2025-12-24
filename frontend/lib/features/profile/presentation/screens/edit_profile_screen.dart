import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedImage;
  List<String> _selectedLanguages = [];
  final bool _isLoading = false;

  final List<String> _availableLanguages = [
    'English',
    'Amharic',
    'Oromiffa',
    'Tigrinya',
    'Arabic',
    'French',
    'German',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _bioController.text = user.bio ?? '';
      _selectedLanguages = List.from(user.languages);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Implement save profile logic
    Helpers.showSuccessSnackBar(context, 'Profile updated!');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile photo
                  Center(
                    child: Stack(
                      children: [
                        _selectedImage != null
                            ? CircleAvatar(
                                radius: 50,
                                backgroundImage: FileImage(_selectedImage!),
                              )
                            : UserAvatar(
                                imageUrl: user.photoUrl,
                                name: user.fullName,
                                size: 100,
                              ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name
                  CustomTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    prefixIcon: Icons.person,
                    validator: (v) => Validators.required(v, 'Name'),
                  ),
                  const SizedBox(height: 20),

                  // Phone
                  CustomTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  CustomTextField(
                    label: 'Bio',
                    hint: 'Tell us about yourself',
                    controller: _bioController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Languages
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Languages', style: AppTextStyles.labelLarge),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableLanguages.map((lang) {
                      final isSelected = _selectedLanguages.contains(lang);
                      return FilterChip(
                        label: Text(lang),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedLanguages.add(lang);
                            } else {
                              _selectedLanguages.remove(lang);
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withAlpha(51),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  CustomButton(
                    text: 'Save Changes',
                    onPressed: _saveProfile,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
