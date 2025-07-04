import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    loadNotificationPref();
  }

  Future<void> loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> saveNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
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
                            value: notificationsEnabled,
                            onChanged: (val) {
                              setState(() => notificationsEnabled = val);
                              saveNotificationPref(val);
                              // TODO: implement daily notification logic
                            },
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

For any questions, contact us at privacy@ethio.forex.
''';

  final String _aboutText = '''
EthioForex helps you compare Ethiopian bank exchange rates for foreign currencies in real-time.

We aim to make it easy for you to make informed financial decisions. Built with love by a team of developers and financial experts.

Contact: contact@ethio.forex
''';
}