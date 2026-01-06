import 'package:equatable/equatable.dart';

import '../../auth/data/models/user_model.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => const <Object?>[];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.user);

  final UserModel user;

  @override
  List<Object?> get props => <Object?>[user];
}

class ProfileUpdating extends ProfileState {
  const ProfileUpdating();
}

class ProfileUpdated extends ProfileState {
  const ProfileUpdated();
}

class ProfilePhotoUploading extends ProfileState {
  const ProfilePhotoUploading();
}

class ProfilePhotoUploaded extends ProfileState {
  const ProfilePhotoUploaded(this.url);

  final String url;

  @override
  List<Object?> get props => <Object?>[url];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
