import 'package:flutter/material.dart';
import 'package:ethioforexapp/screens/main_screen.dart';
import 'package:ethioforexapp/screens/summary_screen.dart';

class NotificationLaunchedSummaryScreen extends StatelessWidget {
  const NotificationLaunchedSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          // When back is pressed, navigate to MainScreen instead of exiting
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      },
      child: UsdSummaryScreen(
        // Add a custom back button handler
        onBackPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        },
      ),
    );
  }
}