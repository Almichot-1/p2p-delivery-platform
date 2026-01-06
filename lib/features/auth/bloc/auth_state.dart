import 'package:equatable/equatable.dart';

import '../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserModel user;

  @override
  List<Object?> get props => <Object?>[user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent(this.email);

  final String email;

  @override
  List<Object?> get props => <Object?>[email];
}
