import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdMobNativeTemplateHelper {
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      // Use a test ad unit ID for development to avoid policy violations
      return 'ca-app-pub-4980093588441492/7977584365'; // Test Native Ad Unit ID
      // Replace with your actual ad unit ID for production
      // return 'ca-app-pub-4980093588441492/5093203059';
    }
    // Handle iOS or other platforms if needed
    return '';
  }

  // We are keeping this method for consistency, but the actual management
  // of the NativeAd object will happen within AdMobNativeTemplateWidget.
  static Widget createNativeTemplateAdWidget() {
    return const AdMobNativeTemplateWidget();
  }
}

// Global cache for NativeAd instances.
// This is a common pattern for ensuring single instance ads.
// Use with caution and ensure proper disposal if not needed for long.
// For a single ad at a fixed position, this is generally safe.
NativeAd? _cachedNativeAd;
bool _cachedNativeAdIsLoaded = false;
bool _cachedAdLoadFailed = false;

class AdMobNativeTemplateWidget extends StatefulWidget {
  const AdMobNativeTemplateWidget({super.key});

  @override
  State<AdMobNativeTemplateWidget> createState() => _AdMobNativeTemplateWidgetState();
}

class _AdMobNativeTemplateWidgetState extends State<AdMobNativeTemplateWidget> {
  // We'll manage the ad state directly through the global cache
  // and only update the local state to reflect that global state.

  @override
  void initState() {
    super.initState();
    // Only attempt to load the ad if it hasn't been loaded globally yet.
    // We defer the actual load operation to a separate method to ensure
    // context is available.
    if (!_cachedNativeAdIsLoaded && !_cachedAdLoadFailed && _cachedNativeAd == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAd();
      });
    }
  }

  void _loadAd() {
    if (AdMobNativeTemplateHelper.nativeAdUnitId.isEmpty) {
      debugPrint('AdMob Native Ad Unit ID is empty. Ad will not load.');
      if (mounted) setState(() => _cachedAdLoadFailed = true);
      return;
    }

    // Ensure previous ad is disposed if for some reason it was still active
    // before attempting to load a new one (e.g., if adUnitId changed, though unlikely here).
    _cachedNativeAd?.dispose();
    _cachedNativeAd = null;
    _cachedNativeAdIsLoaded = false;
    _cachedAdLoadFailed = false;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    _cachedNativeAd = NativeAd(
      adUnitId: AdMobNativeTemplateHelper.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('AdMob Native Template Ad loaded.');
          if (!mounted) {
            ad.dispose(); // Dispose if the widget is no longer in the tree
            return;
          }
          setState(() {
            _cachedNativeAd = ad as NativeAd;
            _cachedNativeAdIsLoaded = true;
            _cachedAdLoadFailed = false;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('AdMob Native Template Ad failed to load: $error');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _cachedNativeAdIsLoaded = false;
            _cachedAdLoadFailed = true;
            _cachedNativeAd = null; // Clear the reference on failure
          });
        },
        onAdOpened: (Ad ad) => debugPrint('Ad opened.'),
        onAdClosed: (Ad ad) => debugPrint('Ad closed.'),
        onAdImpression: (Ad ad) => debugPrint('Ad impression logged.'),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: colors.surface,
        callToActionTextStyle: NativeTemplateTextStyle(
          backgroundColor: colors.primary,
          textColor: colors.onPrimary,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: colors.onSurface,
          backgroundColor: colors.surface,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: colors.onSurfaceVariant,
          backgroundColor: colors.surface,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: colors.onSurface,
          backgroundColor: colors.surface,
          size: 12.0,
        ),
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_cachedNativeAdIsLoaded && _cachedNativeAd != null) {
      return Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 300,
            minHeight: 350,
            maxHeight: 400,
            maxWidth: 450,
          ),
          child: AdWidget(ad: _cachedNativeAd!),
        ),
      );
    } else if (_cachedAdLoadFailed) {
      // Show an empty box if ad load failed
      return const SizedBox.shrink();
    } else {
      // Show a loading indicator while the ad is being loaded for the first time
      return Container(
        alignment: Alignment.center,
        height: 60,
        color: colors.surfaceContainerHighest,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
        ),
      );
    }
  }

  @override
  void dispose() {
    // DO NOT dispose the _cachedNativeAd here if you want it to persist across
    // widget tree changes. The ad is managed globally.
    // You would only dispose _cachedNativeAd if the entire app is closing
    // or if you are completely done with this specific ad placement for its lifetime.
    super.dispose();
  }
}