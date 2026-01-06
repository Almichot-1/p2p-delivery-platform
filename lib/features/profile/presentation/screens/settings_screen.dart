import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kPush = 'settings_push_notifications';
  static const _kDarkMode = 'settings_dark_mode';
  static const _kLanguage = 'settings_language';

  bool _loading = true;
  bool _push = true;
  bool _darkMode = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _push = prefs.getBool(_kPush) ?? true;
      _darkMode = prefs.getBool(_kDarkMode) ?? false;
      _language = prefs.getString(_kLanguage) ?? 'English';
      _loading = false;
    });
  }

  Future<void> _setPush(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPush, v);
    setState(() => _push = v);
  }

  Future<void> _setDarkMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, v);
    setState(() => _darkMode = v);
  }

  Future<void> _setLanguage(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, v);
    setState(() => _language = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _SectionHeader(title: 'Notifications'),
                SwitchListTile(
                  title: const Text('Push notifications'),
                  value: _push,
                  onChanged: _setPush,
                ),
                _SectionHeader(title: 'Appearance'),
                SwitchListTile(
                  title: const Text('Dark mode'),
                  value: _darkMode,
                  onChanged: _setDarkMode,
                ),
                _SectionHeader(title: 'Language'),
                ListTile(
                  title: const Text('App language'),
                  subtitle: Text(_language),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: const Text('Select language'),
                          children: [
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, 'English'),
                              child: const Text('English'),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, 'Amharic'),
                              child: const Text('Amharic'),
                            ),
                          ],
                        );
                      },
                    );
                    if (selected != null) {
                      await _setLanguage(selected);
                    }
                  },
                ),
                _SectionHeader(title: 'Privacy'),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  onTap: () => context.go(RoutePaths.forgotPassword),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy policy'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy policy (coming soon)')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of service'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of service (coming soon)')),
                    );
                  },
                ),
                _SectionHeader(title: 'About'),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('App version'),
                  subtitle: Text('0.1.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support (coming soon)')),
                    );
                  },
                ),
                _SectionHeader(title: 'Account'),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () => context.go(RoutePaths.profile),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  title: Text('Delete Account', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );

                    if (ok == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delete Account (not implemented)')),
                      );
                    }
                  },
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
