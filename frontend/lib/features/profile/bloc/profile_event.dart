import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../auth/data/models/user_model.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String userId;

  const ProfileLoadRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class ProfileUpdateRequested extends ProfileEvent {
  final UserModel user;

  const ProfileUpdateRequested(this.user);

  @override
  List<Object> get props => [user];
}

class ProfilePhotoUpdateRequested extends ProfileEvent {
  final File photo;

  const ProfilePhotoUpdateRequested(this.photo);

  @override
  List<Object> get props => [photo];
}

class ProfileVerificationRequested extends ProfileEvent {
  final File document;
  final String documentType;

  const ProfileVerificationRequested({
    required this.document,
    required this.documentType,
  });

  @override
  List<Object> get props => [document, documentType];
}

class ProfileRoleUpdateRequested extends ProfileEvent {
  final UserRole role;

  const ProfileRoleUpdateRequested(this.role);

  @override
  List<Object> get props => [role];
}
