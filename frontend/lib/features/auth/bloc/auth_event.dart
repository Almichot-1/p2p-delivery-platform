import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String? phone;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });

  @override
  List<Object?> get props => [email, password, fullName, phone];
}

class AuthPhoneOTPRequested extends AuthEvent {
  final String phoneNumber;

  const AuthPhoneOTPRequested({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthPhoneOTPVerified extends AuthEvent {
  final String verificationId;
  final String otp;
  final String fullName;

  const AuthPhoneOTPVerified({
    required this.verificationId,
    required this.otp,
    required this.fullName,
  });

  @override
  List<Object?> get props => [verificationId, otp, fullName];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {}
