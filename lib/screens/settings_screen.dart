import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_notifier.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = false;
  bool isLoading = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    loadNotificationPref();
  }

  Future<void> loadNotificationPref() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    setState(() {
      notificationsEnabled = enabled;
    });
  }

  Future<void> toggleNotifications(bool value) async {
    setState(() {
      isLoading = true;
    });

    try {
      if (value) {
        await _notificationService.enableNotifications();
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily notifications enabled at 9:00 AM'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _notificationService.disableNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily notifications disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      setState(() {
        notificationsEnabled = value;
      });
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBottomSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(content, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Settings Cards Section
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Settings Options
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text("Dark Mode"),
                            value: isDarkMode,
                            onChanged: (_) => themeNotifier.toggleTheme(),
                          ),
                          Divider(height: 1, color: theme.dividerColor),
                          SwitchListTile(
                            title: const Text("Daily Notifications"),
                            subtitle: const Text("Get USD exchange rates at 9:00 AM daily"),
                            value: notificationsEnabled,
                            onChanged: isLoading ? null : toggleNotifications,
                            secondary: isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : null,
                          ),
                          if (notificationsEnabled) ...[
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              title: const Text("Test Notification"),
                              subtitle: const Text("Send a test notification now"),
                              leading: const Icon(Icons.notifications_active),
                              onTap: _testNotification,
                              trailing: const Icon(Icons.send),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Notification Info Section
                if (notificationsEnabled)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Daily Notification Schedule",
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Every day at 9:00 AM",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Information Section
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text("Privacy Policy"),
                              leading: const Icon(Icons.privacy_tip_outlined),
                              onTap: () => _showBottomSheet("Privacy Policy", _privacyText),
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              title: const Text("About Us"),
                              leading: const Icon(Icons.info_outline),
                              onTap: () => _showBottomSheet("About Us", _aboutText),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final String _privacyText = '''
Your privacy and data security are our top priorities.

We collect only essential data such as usage patterns to improve app performance. We use Google AdMob to serve ads. No personal data is sold or shared.

Notifications are stored locally on your device and are not sent to external servers.

For any questions, contact us at privacy@ethio.forex.
''';

  final String _aboutText = '''
EthioForex helps you compare Ethiopian bank exchange rates for foreign currencies in real-time.

We aim to make it easy for you to make informed financial decisions. Built with love by a team of developers and financial experts.

Daily notifications help you stay updated with the latest USD exchange rates every morning at 9:00 AM.

Contact: contact@ethio.forex
''';
}