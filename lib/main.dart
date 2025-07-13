import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ethioforexapp/theme_notifier.dart';
import 'package:ethioforexapp/screens/main_screen.dart';
import 'package:ethioforexapp/screens/summary_screen.dart';
import 'package:ethioforexapp/screens/notification_launched_summary_screen.dart';
import 'package:ethioforexapp/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.checkAndRequestPermissions();

  // Check if app was launched from notification
  final launchDetails = await notificationService.getNotificationAppLaunchDetails();
  String? initialRoute;

  if (launchDetails?.didNotificationLaunchApp == true) {
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload == 'usd_summary') {
      initialRoute = '/summary';
    }
  }

  // Set the callback that will be triggered when a notification is tapped (for when app is running)
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
      child: MyApp(
        notificationService: notificationService,
        initialRoute: initialRoute,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;
  final String? initialRoute;

  const MyApp({
    super.key,
    required this.notificationService,
    this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'EthioForex',
      debugShowCheckedModeBanner: false,
      navigatorKey: notificationService.navigatorKey,
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: _getInitialScreen(),
      routes: {
        '/summary': (context) => const UsdSummaryScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }

  Widget _getInitialScreen() {
    if (initialRoute == '/summary') {
      // When launched from notification, wrap in a custom screen
      // that handles back navigation properly
      return const NotificationLaunchedSummaryScreen();
    }
    return const MainScreen();
  }
}