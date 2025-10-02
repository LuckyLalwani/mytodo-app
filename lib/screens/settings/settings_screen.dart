import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

// Import from main.dart
import '../../main.dart' show themeNotifier;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (_isProcessing) const LinearProgressIndicator(),
          // User Info Section
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        _authService.userDisplayName.isNotEmpty
                            ? _authService.userDisplayName[0].toUpperCase()
                            : 'U',
                      ),
                    ),
                    title: Text(_authService.userDisplayName),
                    subtitle: Text(_authService.userEmail),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          // Theme Section
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, currentMode, _) {
                      return Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: const Text('System Default'),
                            subtitle: const Text('Follow system theme'),
                            value: ThemeMode.system,
                            groupValue: currentMode,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  themeNotifier.value = value;
                                  settingsBox.put('themeMode', 'system');
                                });
                              }
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('Light'),
                            subtitle: const Text('Light theme'),
                            value: ThemeMode.light,
                            groupValue: currentMode,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  themeNotifier.value = value;
                                  settingsBox.put('themeMode', 'light');
                                });
                              }
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('Dark'),
                            subtitle: const Text('Dark theme'),
                            value: ThemeMode.dark,
                            groupValue: currentMode,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  themeNotifier.value = value;
                                  settingsBox.put('themeMode', 'dark');
                                });
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Account Actions Section
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    subtitle: const Text('Sign out of your account'),
                    contentPadding: EdgeInsets.zero,
                    onTap: _isProcessing ? null : _showSignOutDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently delete your account and all data'),
                    contentPadding: EdgeInsets.zero,
                    onTap: _isProcessing ? null : _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
          ),

          // App Info Section
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('App Info'),
                    subtitle: const Text('MyTodo v1.0.0'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'MyTodo',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.task_alt),
                        children: const [
                          Text('A simple and elegant todo app built with Flutter and Firebase.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSignOutDialog() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      try {
        setState(() => _isProcessing = true);
        await _authService.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        setState(() => _isProcessing = true);

        // Delete remote tasks first
        await _firestoreService.deleteAllTasks();

        // Clear local task box if open
        if (Hive.isBoxOpen('tasks')) {
          try {
            await Hive.box('tasks').clear();
          } catch (_) {
            // Ignore errors when clearing local data
          }
        }

        // Keep theme settings but clear other settings if needed
        // (You might want to preserve user preferences)

        // Delete auth account
        await _authService.deleteAccount();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }
}