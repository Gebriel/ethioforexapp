import 'package:flutter/material.dart';

import 'adhelper_admob.dart';
// IMPORTANT: Make sure this path correctly points to your adhelper_admob.dart



// The AdLoadState enum can be removed if it's not used by any other part of your
// application after being removed from this file. If AdMobNativeTemplateHelper
// or other components use it, you might need to keep it or move it to a more
// shared location. For this file, it's no longer directly used.
// enum AdLoadState {
//   none, // No ad loaded yet or after dispose
//   loading, // Ad is currently loading
//   loaded, // Ad loaded successfully
//   failed, // Ad failed to load
// }

/// A widget that loads and displays a Google AdMob Native Template Ad.
///
/// This widget encapsulates the ad display logic for an AdMob Native Template Ad,
/// relying on `AdMobNativeTemplateHelper` to manage the actual ad loading and
/// rendering lifecycle.
class AdFallbackDisplay extends StatefulWidget {
  const AdFallbackDisplay({super.key});

  @override
  State<AdFallbackDisplay> createState() => _AdFallbackDisplayState();
}

class _AdFallbackDisplayState extends State<AdFallbackDisplay> {
  // The _adLoadState field has been removed as this widget now directly
  // delegates the display and state management to AdMobNativeTemplateHelper.

  @override
  void initState() {
    super.initState();
    // It's good practice to log when this widget initializes,
    // even if the core ad loading logic is delegated.
    _initiateAdDisplay();
  }

  @override
  void dispose() {
    // No specific ad instance to dispose here directly, as AdMobNativeTemplateHelper
    // (and the widget it creates) should handle its own ad instance disposal.
    debugPrint('AdFallbackDisplay disposed.');
    super.dispose();
  }

  /// Logs the attempt to display the Google AdMob Native Template Ad.
  /// The actual ad loading and state management are handled by the widget
  /// created by `AdMobNativeTemplateHelper.createNativeTemplateAdWidget()`.
  void _initiateAdDisplay() {
    debugPrint(
        'AdFallbackDisplay: Attempting to display Google AdMob Native Template Ad via AdMobNativeTemplateHelper.');
    // No setState is needed here as this widget itself doesn't change its own UI
    // based on an internal ad load state anymore. The child widget handles its state.
  }

  @override
  Widget build(BuildContext context) {
    // Directly return the widget provided by AdMobNativeTemplateHelper.
    // This helper is responsible for creating a widget that will handle
    // its own loading, display, and error states for the native ad.
    return AdMobNativeTemplateHelper.createNativeTemplateAdWidget();
  }
}
