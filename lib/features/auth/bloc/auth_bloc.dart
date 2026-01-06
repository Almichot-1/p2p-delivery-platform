import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);

    _profileSub = _authRepository.userProfileStream.listen((profile) {
      final authUser = _authRepository.getCurrentUser();

      if (authUser == null || profile == null) {
        add(const AuthCheckRequested());
        return;
      }

      add(_ProfileUpdated(profile));
    });

    on<_ProfileUpdated>(_onProfileUpdated);
  }

  final AuthRepository _authRepository;
  StreamSubscription<UserModel?>? _profileSub;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    try {
      final profile = await _authRepository.getUserById(user.uid);
      if (profile == null) {
        await _authRepository.logout();
        emit(const AuthUnauthenticated());
        return;
      }
      emit(AuthAuthenticated(profile));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.loginWithEmail(event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.registerWithEmail(
        event.email,
        event.password,
        event.fullName,
        event.phone,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _authRepository.logout();
    await _profileSub?.cancel();
    _profileSub = null;
    emit(const AuthUnauthenticated());
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetSent(event.email));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      emit(const AuthUnauthenticated());
    }
  }

  void _onProfileUpdated(_ProfileUpdated event, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(event.user));
  }

  @override
  Future<void> close() async {
    await _profileSub?.cancel();
    return super.close();
  }
}

class _ProfileUpdated extends AuthEvent {
  const _ProfileUpdated(this.user);

  final UserModel user;

  @override
  List<Object?> get props => <Object?>[user];
}
