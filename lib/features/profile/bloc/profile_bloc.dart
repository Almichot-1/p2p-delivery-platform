import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/models/user_model.dart';
import '../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfilePhotoUpdateRequested>(_onPhotoUpdateRequested);

    on<_ProfileStreamUpdated>(_onProfileStreamUpdated);
    on<_ProfileStreamFailed>(_onProfileStreamFailed);
  }

  final ProfileRepository _profileRepository;

  StreamSubscription<UserModel?>? _profileSub;
  UserModel? _currentUser;
  String? _currentUid;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    _currentUid = event.uid;

    await _profileSub?.cancel();
    _profileSub = _profileRepository.getUserProfile(event.uid).listen(
      (user) {
        if (user == null) {
          add(const _ProfileStreamFailed('Profile not found'));
          return;
        }
        add(_ProfileStreamUpdated(user));
      },
      onError: (e) {
        add(_ProfileStreamFailed(e.toString()));
      },
    );
  }

  void _onProfileStreamUpdated(
    _ProfileStreamUpdated event,
    Emitter<ProfileState> emit,
  ) {
    _currentUser = event.user;
    emit(ProfileLoaded(event.user));
  }

  void _onProfileStreamFailed(
    _ProfileStreamFailed event,
    Emitter<ProfileState> emit,
  ) {
    emit(ProfileError(event.message.replaceFirst('Exception: ', '')));
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileUpdating());
    try {
      await _profileRepository.updateProfile(event.user);
      emit(const ProfileUpdated());
      emit(ProfileLoaded(event.user));
    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
      final user = _currentUser;
      if (user != null) emit(ProfileLoaded(user));
    }
  }

  Future<void> _onPhotoUpdateRequested(
    ProfilePhotoUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final uid = _currentUid ?? _currentUser?.uid;
    if (uid == null) {
      emit(const ProfileError('No user loaded'));
      return;
    }

    emit(const ProfilePhotoUploading());
    try {
      final url = await _profileRepository.updateProfilePhoto(event.photo, uid);
      emit(ProfilePhotoUploaded(url));
      final user = _currentUser;
      if (user != null) {
        final updated = user.copyWith(photoUrl: url);
        _currentUser = updated;
        emit(ProfileLoaded(updated));
      } else {
        add(ProfileLoadRequested(uid));
      }
    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
      final user = _currentUser;
      if (user != null) emit(ProfileLoaded(user));
    }
  }

  @override
  Future<void> close() async {
    await _profileSub?.cancel();
    return super.close();
  }
}

class _ProfileStreamUpdated extends ProfileEvent {
  const _ProfileStreamUpdated(this.user);

  final UserModel user;

  @override
  List<Object?> get props => <Object?>[user];
}

class _ProfileStreamFailed extends ProfileEvent {
  const _ProfileStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
