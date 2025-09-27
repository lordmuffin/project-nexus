import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/components.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    print('⚙️ SettingsScreen initializing...');
    print('⚙️ SettingsScreen initialization complete');
  }

  @override
  Widget build(BuildContext context) {
    print('⚙️ SettingsScreen building UI...');
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Section
          const SectionHeader(
            title: 'Appearance',
            subtitle: 'Customize how the app looks',
          ),
          
          NexusCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    _getThemeIcon(themeMode),
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(_getThemeLabel(themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeSelector(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Privacy Section
          const SectionHeader(
            title: 'Privacy & Security',
            subtitle: 'Control your data and privacy',
          ),
          
          NexusCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.security,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Data Storage'),
                  subtitle: const Text('All data is stored locally'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Secure',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const Divider(height: 1),
                
                ListTile(
                  leading: const Icon(
                    Icons.cloud_off,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Offline Mode'),
                  subtitle: const Text('No internet required'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Storage Section
          const SectionHeader(
            title: 'Storage',
            subtitle: 'Manage app data and storage',
          ),
          
          NexusCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.storage,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Storage Usage'),
                  subtitle: const Text('View data usage statistics'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showStorageInfo(context),
                ),
                
                const Divider(height: 1),
                
                ListTile(
                  leading: const Icon(
                    Icons.cleaning_services,
                    color: AppColors.warning,
                  ),
                  title: const Text('Clear Cache'),
                  subtitle: const Text('Free up storage space'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearCacheDialog(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          const SectionHeader(
            title: 'About',
            subtitle: 'App information and support',
          ),
          
          NexusCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Version'),
                  subtitle: Text(AppConstants.appVersion),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Latest',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const Divider(height: 1),
                
                ListTile(
                  leading: const Icon(
                    Icons.description,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Read our privacy policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrivacyPolicy(context),
                ),
                
                const Divider(height: 1),
                
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Get help and contact support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showHelpDialog(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Development Section (will be removed in production)
          const SectionHeader(
            title: 'Development',
            subtitle: 'Development tools and information',
          ),
          
          NexusCard(
            color: AppColors.warning.withOpacity(0.05),
            child: ListTile(
              leading: const Icon(
                Icons.build,
                color: AppColors.warning,
              ),
              title: const Text('Development Mode'),
              subtitle: const Text('Sprint 2 - Navigation & UI Components'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeLabel(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Theme',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...ThemeMode.values.map((mode) {
              return ListTile(
                leading: Icon(_getThemeIcon(mode)),
                title: Text(_getThemeLabel(mode)),
                trailing: ref.watch(themeProvider) == mode
                    ? const Icon(Icons.check, color: AppColors.success)
                    : null,
                onTap: () async {
                  await ThemeNotifier.setTheme(ref, mode);
                  Navigator.pop(context);
                },
              );
            }),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showStorageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Storage information will be implemented in a future sprint.'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.3,
              backgroundColor: AppColors.neutral200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
            const SizedBox(height: 8),
            const Text('~150 MB used of 1 GB available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear temporary files and cached data. Your notes and meetings will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            label: 'Clear Cache',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache clearing will be implemented in a future sprint'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Nexus is built with privacy in mind:\n\n'
            '• All data is stored locally on your device\n'
            '• No data is sent to external servers\n'
            '• No analytics or tracking\n'
            '• You have full control over your data\n\n'
            'Full privacy policy will be available in the production version.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'This is a development version of Nexus.\n\n'
          'For support and feedback, please contact the development team.\n\n'
          'Help documentation will be available in the production version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}