import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../widgets/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Conditions to continue.')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text,
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseConfigured = Firebase.apps.isNotEmpty;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(RoutePaths.home);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: 'Create Account',
                    subtitle: 'Join Diaspora Delivery in minutes.',
                  ),
                  if (!firebaseConfigured) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Firebase is not configured for Android yet. Add android/app/google-services.json to enable real login/register.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _nameCtrl,
                    label: 'Full name',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Email is required';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _phoneCtrl,
                    label: 'Phone (optional)',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      final value = (v ?? '');
                      if (value.isEmpty) return 'Password is required';
                      if (value.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _confirmCtrl,
                    label: 'Confirm password',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Confirm your password';
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _acceptedTerms,
                    onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                    title: const Text('I accept Terms & Conditions'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final loading = state is AuthLoading;
                      return CustomButton(
                        label: 'Register',
                        isLoading: loading,
                        onPressed: loading ? null : _submit,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have account? '),
                      TextButton(
                        onPressed: () => context.go(RoutePaths.login),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
