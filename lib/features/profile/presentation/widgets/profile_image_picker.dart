import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/cached_image.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';

class ProfileImagePicker extends StatefulWidget {
  const ProfileImagePicker({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.size = 110,
    this.onUrlChanged,
  });

  final String displayName;
  final String? imageUrl;
  final double size;
  final ValueChanged<String>? onUrlChanged;

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    Navigator.of(context).pop();

    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (xFile == null) return;

    final file = File(xFile.path);
    if (!mounted) return;

    context.read<ProfileBloc>().add(ProfilePhotoUpdateRequested(file));
  }

  void _showSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take Photo'),
                onTap: () => _pick(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => _pick(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (_, current) => current is ProfilePhotoUploaded,
      listener: (context, state) {
        if (state is ProfilePhotoUploaded) {
          widget.onUrlChanged?.call(state.url);
        }
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final uploading = state is ProfilePhotoUploading;

          return Stack(
            alignment: Alignment.center,
            children: [
              ProfileImage(
                displayName: widget.displayName,
                imageUrl: widget.imageUrl,
                size: widget.size,
              ),
              if (uploading)
                Container(
                  height: widget.size,
                  width: widget.size,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              Positioned(
                bottom: 2,
                right: 2,
                child: IconButton.filled(
                  onPressed: uploading ? null : _showSheet,
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Change photo',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
