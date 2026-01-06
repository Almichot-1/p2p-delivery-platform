import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../auth/data/models/user_model.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested(this.uid);

  final String uid;

  @override
  List<Object?> get props => <Object?>[uid];
}

class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested(this.user);

  final UserModel user;

  @override
  List<Object?> get props => <Object?>[user];
}

class ProfilePhotoUpdateRequested extends ProfileEvent {
  const ProfilePhotoUpdateRequested(this.photo);

  final File photo;

  @override
  List<Object?> get props => <Object?>[photo.path];
}
