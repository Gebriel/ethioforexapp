import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ethioforexapp/theme_notifier.dart';
import 'package:ethioforexapp/screens/main_screen.dart';
import 'package:ethioforexapp/screens/summary_screen.dart';
import 'package:ethioforexapp/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.checkAndRequestPermissions();

  // Set the callback that will be triggered when a notification is tapped
  notificationService.setNotificationTapCallback((payload) {
    if (payload == 'usd_summary') {
      notificationService.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const UsdSummaryScreen()),
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: MyApp(notificationService: notificationService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;
  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'EthioForex',
      debugShowCheckedModeBanner: false,
      navigatorKey: notificationService.navigatorKey, // ✅ required for navigation on tap
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: const MainScreen(),
    );
  }
}
