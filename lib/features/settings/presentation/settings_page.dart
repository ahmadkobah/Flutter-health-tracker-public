import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../profile/data/profile_service.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/services/biometric_service.dart';

// -------------------- SETTINGS PAGE --------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _profileService = ProfileService();
  final _biometricService = BiometricService();
  AppPreferences? _preferences;
  bool _isLoading = true;
  Map<String, dynamic>? _biometricStatus;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final status = await _biometricService.getBiometricStatus();
    if (mounted) {
      setState(() => _biometricStatus = status);
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final profile = await _profileService.getCurrentProfile();
      setState(() {
        _preferences = profile?.preferences ?? AppPreferences();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _preferences = AppPreferences();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            GradientHeaderSliver(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSettingsContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    if (_preferences == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationSettings(),
            const SizedBox(height: 24),
            _buildAppearanceSettings(),
            const SizedBox(height: 24),
            _buildSecuritySettings(),
            const SizedBox(height: 24),
            _buildDataSettings(),
            const SizedBox(height: 24),
            _buildLanguageSettings(),
            const SizedBox(height: 24),
            _buildAboutSection(),
            const SizedBox(height: 24),
            _buildDangerZone(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsSection(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      children: [
        _buildSwitchTile(
          title: 'Push Notifications',
          subtitle: 'Receive medication reminders',
          value: _preferences!.notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(
                notificationsEnabled: value,
              );
            });
            _savePreferences();
          },
        ),
        _buildSwitchTile(
          title: 'Reminder Sounds',
          subtitle: 'Play sound with notifications',
          value: _preferences!.reminderSounds,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(reminderSounds: value);
            });
            _savePreferences();
          },
          enabled: _preferences!.notificationsEnabled,
        ),
        _buildSliderTile(
          title: 'Default Reminder Time',
          subtitle: '${_preferences!.reminderInterval} minutes before dose',
          value: _preferences!.reminderInterval.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(
                reminderInterval: value.round(),
              );
            });
            _savePreferences();
          },
          enabled: _preferences!.notificationsEnabled,
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildSettingsSection(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      children: [
        _buildListTile(
          title: 'Theme',
          subtitle: _getThemeName(_preferences!.themeMode),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showThemeSelector,
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    final isAvailable = _biometricStatus?['isAvailable'] as bool? ?? false;
    final biometricTypes =
        _biometricStatus?['biometricTypes'] as String? ?? 'Not available';

    return _buildSettingsSection(
      title: 'Security & Privacy',
      icon: Icons.security_outlined,
      children: [
        _buildSwitchTile(
          title: 'Biometric Authentication',
          subtitle: isAvailable ? biometricTypes : 'Not available on this device',
          value: _preferences!.biometricAuth,
          enabled: isAvailable,
          onChanged: (value) async {
            if (value && isAvailable) {
              // Show email and password input dialog
              await _showBiometricSetupDialog();
            } else {
              // Disable biometric
              setState(() {
                _preferences = _preferences!.copyWith(biometricAuth: false);
              });
              await _biometricService.disableBiometricLogin();
              _savePreferences();
            }
          },
        ),
        _buildListTile(
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPrivacyPolicy(),
        ),
        _buildListTile(
          title: 'Terms of Service',
          subtitle: 'View terms and conditions',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showTermsOfService(),
        ),
      ],
    );
  }

  Future<void> _showBiometricSetupDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Setup Biometric Login'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your credentials to enable biometric login.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    hintText: 'Email',
                    errorText: errorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _preferences = _preferences!.copyWith(biometricAuth: false));
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (email.isEmpty || password.isEmpty) {
                  setState(() => errorMessage = 'Email and password required');
                  return;
                }

                try {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                  _showLoadingDialog('Setting up biometric login...');

                  await _biometricService.enableBiometricLogin(
                    email: email,
                    password: password,
                  );

                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); // Close loading dialog
                  setState(() {
                    _preferences = _preferences!.copyWith(biometricAuth: true);
                  });
                  _savePreferences();
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric login enabled successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); // Close loading dialog
                  setState(() {
                    _preferences = _preferences!.copyWith(biometricAuth: false);
                  });
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5AE0),
              ),
              child: const Text(
                'Enable',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSettings() {
    return _buildSettingsSection(
      title: 'Data Management',
      icon: Icons.storage_outlined,
      children: [
        _buildSwitchTile(
          title: 'Auto Backup',
          subtitle: 'Automatically backup your data',
          value: _preferences!.autoBackup,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(autoBackup: value);
            });
            _savePreferences();
          },
        ),
        _buildListTile(
          title: 'Export Data',
          subtitle: 'Download your data',
          trailing: const Icon(Icons.download),
          onTap: _exportData,
        ),
        _buildListTile(
          title: 'Import Data',
          subtitle: 'Restore from backup',
          trailing: const Icon(Icons.upload),
          onTap: _importData,
        ),
      ],
    );
  }

  Widget _buildLanguageSettings() {
    return _buildSettingsSection(
      title: 'Language & Region',
      icon: Icons.language_outlined,
      children: [
        _buildListTile(
          title: 'Language',
          subtitle: _getLanguageName(_preferences!.language),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showLanguageSelector,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsSection(
      title: 'About',
      icon: Icons.info_outline,
      children: [
        _buildListTile(title: 'App Version', subtitle: '1.0.0', trailing: null),
        _buildListTile(
          title: 'Help & Support',
          subtitle: 'Get help or contact support',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showHelpSupport(),
        ),
        _buildListTile(
          title: 'Rate App',
          subtitle: 'Leave a review',
          trailing: const Icon(Icons.star_outline),
          onTap: () => _rateApp(),
        ),
        _buildListTile(
          title: 'Share App',
          subtitle: 'Tell others about MediCare+',
          trailing: const Icon(Icons.share),
          onTap: () => _shareApp(),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _buildSettingsSection(
      title: 'Danger Zone',
      icon: Icons.warning_outlined,
      titleColor: Colors.red,
      children: [
        _buildListTile(
          title: 'Clear All Data',
          subtitle: 'Remove all medications and profile data',
          titleColor: Colors.red,
          trailing: const Icon(Icons.delete, color: Colors.red),
          onTap: _showClearDataDialog,
        ),
        _buildListTile(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          titleColor: Colors.red,
          trailing: const Icon(Icons.delete_forever, color: Colors.red),
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? titleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: titleColor ?? const Color(0xFF6A5AE0), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: titleColor ?? const Color(0xFF2E2E2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? const Color(0xFF2E2E2E) : const Color(0xFF9BA1AB),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? const Color(0xFF6A6A6A) : const Color(0xFF9BA1AB),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: const Color(0xFF6A5AE0),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? const Color(0xFF2E2E2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6A6A6A)),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    bool enabled = true,
  }) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: enabled
                  ? const Color(0xFF2E2E2E)
                  : const Color(0xFF9BA1AB),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: enabled
                  ? const Color(0xFF6A6A6A)
                  : const Color(0xFF9BA1AB),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: enabled ? onChanged : null,
            activeColor: const Color(0xFF6A5AE0),
          ),
        ),
      ],
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      default:
        return 'English';
    }
  }

  void _savePreferences() async {
    try {
      await _profileService.updateAppPreferences(_preferences!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile<ThemeMode>(
              title: 'Light',
              value: ThemeMode.light,
              groupValue: _preferences!.themeMode,
              onChanged: (value) async {
                setState(() {
                  _preferences = _preferences!.copyWith(themeMode: value);
                });
                _savePreferences();
                // Update ThemeProvider
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                final themeProvider = Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                );
                await themeProvider.setThemeMode(value);
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
            ),
            _buildRadioTile<ThemeMode>(
              title: 'Dark',
              value: ThemeMode.dark,
              groupValue: _preferences!.themeMode,
              onChanged: (value) async {
                setState(() {
                  _preferences = _preferences!.copyWith(themeMode: value);
                });
                _savePreferences();
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                final themeProvider = Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                );
                await themeProvider.setThemeMode(value);
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
            ),
            _buildRadioTile<ThemeMode>(
              title: 'System',
              value: ThemeMode.system,
              groupValue: _preferences!.themeMode,
              onChanged: (value) async {
                setState(() {
                  _preferences = _preferences!.copyWith(themeMode: value);
                });
                _savePreferences();
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                final themeProvider = Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                );
                await themeProvider.setThemeMode(value);
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    const languages = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) {
            return _buildRadioTile<String>(
              title: entry.value,
              value: entry.key,
              groupValue: _preferences!.language,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(language: value);
                });
                _savePreferences();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // New helper method to replace deprecated RadioListTile
  Widget _buildRadioTile<T>({
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            // ignore: deprecated_member_use
            Radio<T>(
              value: value,
              groupValue: groupValue, // ignore: deprecated_member_use
              // ignore: deprecated_member_use
              onChanged: (T? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF6A5AE0);
                }
                return Colors.grey;
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() async {
    try {
      final data = await _profileService.createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported (${data.length} items)'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () {
                // In a real app, this would share the exported data
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _importData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This feature allows you to restore data from a backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Import functionality would be implemented here',
                  ),
                ),
              );
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _InfoPage(
          title: 'Privacy Policy',
          content:
              'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your information...',
        ),
      ),
    );
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _InfoPage(
          title: 'Terms of Service',
          content:
              'By using this app, you agree to these terms and conditions...',
        ),
      ),
    );
  }

  void _showHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _InfoPage(
          title: 'Help & Support',
          content:
              'Need help? Here are some common questions and answers:\n\n• How do I add a medication?\n• How do I set reminders?\n• How do I backup my data?\n\nFor more support, contact us at support@medicare.com',
        ),
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rate app functionality would open app store'),
      ),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share app functionality would open share dialog'),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your medications and profile data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data cleared'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion would be processed'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

// Simple info page for displaying text content
class _InfoPage extends StatelessWidget {
  final String title;
  final String content;

  const _InfoPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
      ),
    );
  }
}
