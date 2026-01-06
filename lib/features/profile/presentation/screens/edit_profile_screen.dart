import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../widgets/profile_image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final Set<String> _languages = <String>{};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _loadFrom(UserModel user) {
    _nameCtrl.text = user.fullName;
    _phoneCtrl.text = user.phone ?? '';
    _bioCtrl.text = user.bio ?? '';
    _languages
      ..clear()
      ..addAll(user.languages);
  }

  void _save(UserModel current) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final updated = current.copyWith(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      languages: _languages.toList(growable: false),
    );

    context.read<ProfileBloc>().add(ProfileUpdateRequested(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Please log in to edit your profile.')),
          );
        }

        final uid = authState.user.uid;

        return BlocProvider<ProfileBloc>(
          create: (_) => GetIt.instance<ProfileBloc>()..add(ProfileLoadRequested(uid)),
          child: BlocConsumer<ProfileBloc, ProfileState>(
            listenWhen: (_, current) => current is ProfileError || current is ProfileUpdated,
            listener: (context, state) {
              if (state is ProfileError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
              if (state is ProfileUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved')),
                );
                context.pop();
              }
            },
            builder: (context, state) {
              final user = state is ProfileLoaded ? state.user : null;
              if (user == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (_nameCtrl.text.isEmpty && _phoneCtrl.text.isEmpty && _bioCtrl.text.isEmpty && _languages.isEmpty) {
                _loadFrom(user);
              }

              final saving = state is ProfileUpdating;

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Edit Profile'),
                  actions: [
                    TextButton(
                      onPressed: saving ? null : () => _save(user),
                      child: const Text('Save'),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: ProfileImagePicker(
                              displayName: user.fullName,
                              imageUrl: user.photoUrl,
                              size: 120,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v ?? '').trim().isEmpty ? 'Full name is required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number (optional)',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bioCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Bio (optional)',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Languages', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final lang in const <String>['English', 'Amharic', 'Oromiffa', 'Tigrinya', 'Arabic'])
                                FilterChip(
                                  label: Text(lang),
                                  selected: _languages.contains(lang),
                                  onSelected: (v) => setState(() {
                                    if (v) {
                                      _languages.add(lang);
                                    } else {
                                      _languages.remove(lang);
                                    }
                                  }),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: saving ? null : () => _save(user),
                            child: saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
