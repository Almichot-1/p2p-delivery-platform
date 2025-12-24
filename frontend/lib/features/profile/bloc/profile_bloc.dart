import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  StreamSubscription? _profileSubscription;

  ProfileBloc(this._profileRepository) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfilePhotoUpdateRequested>(_onProfilePhotoUpdateRequested);
    on<ProfileVerificationRequested>(_onProfileVerificationRequested);
    on<ProfileRoleUpdateRequested>(_onProfileRoleUpdateRequested);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    await _profileSubscription?.cancel();
    _profileSubscription =
        _profileRepository.getUserProfile(event.userId).listen(
      (user) {
        if (user != null) {
          emit(ProfileLoaded(user));
        } else {
          emit(const ProfileError('User not found'));
        }
      },
      onError: (error) => emit(ProfileError(error.toString())),
    );
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      await _profileRepository.updateProfile(event.user);
      emit(ProfileUpdated());
      emit(ProfileLoaded(event.user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onProfilePhotoUpdateRequested(
    ProfilePhotoUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final photoUrl = await _profileRepository.updateProfilePhoto(event.photo);
      emit(ProfilePhotoUpdated(photoUrl));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onProfileVerificationRequested(
    ProfileVerificationRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      await _profileRepository.uploadVerificationDocument(event.document);
      emit(ProfileVerificationSubmitted());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onProfileRoleUpdateRequested(
    ProfileRoleUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _profileRepository.updateUserRole(event.role);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
