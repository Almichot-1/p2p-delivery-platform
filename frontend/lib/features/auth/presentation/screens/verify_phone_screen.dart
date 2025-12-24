import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../widgets/auth_header.dart';
import '../widgets/otp_input_field.dart';

class VerifyPhoneScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String fullName;

  const VerifyPhoneScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.fullName,
  });

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  String _otp = '';
  int _resendSeconds = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _verifyOTP() {
    if (_otp.length != 6) {
      Helpers.showErrorSnackBar(context, 'Please enter the complete code');
      return;
    }

    context.read<AuthBloc>().add(
          AuthPhoneOTPVerified(
            verificationId: widget.verificationId,
            otp: _otp,
            fullName: widget.fullName,
          ),
        );
  }

  void _resendOTP() {
    if (!_canResend) return;

    context.read<AuthBloc>().add(
          AuthPhoneOTPRequested(phoneNumber: widget.phoneNumber),
        );
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(RouteConstants.home);
        } else if (state is AuthError) {
          Helpers.showErrorSnackBar(context, state.message);
        } else if (state is AuthPhoneOTPSent) {
          Helpers.showSuccessSnackBar(context, 'Code resent!');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'Verify Phone',
                  subtitle: 'Enter the 6-digit code sent to',
                ),
                const SizedBox(height: 8),
                Text(
                  widget.phoneNumber,
                  style: AppTextStyles.h5.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 40),

                // OTP Input
                OTPInputField(
                  onCompleted: (otp) {
                    setState(() {
                      _otp = otp;
                    });
                    _verifyOTP();
                  },
                  onChanged: (otp) {
                    setState(() {
                      _otp = otp;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Verify button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return CustomButton(
                      text: 'Verify',
                      onPressed: _otp.length == 6 ? _verifyOTP : null,
                      isLoading: state is AuthLoading,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Resend code
                Center(
                  child: _canResend
                      ? TextButton(
                          onPressed: _resendOTP,
                          child: Text(
                            'Resend Code',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Text(
                          'Resend code in ${_resendSeconds}s',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
