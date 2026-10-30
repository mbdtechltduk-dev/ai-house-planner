import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../di/service_locator.dart';

/// Drop this at the bottom of any screen (e.g. as `bottomNavigationBar` or
/// the last child of a `Column`) to show a banner ad. Automatically hides
/// itself for Premium users and handles its own ad lifecycle, so screens
/// never need to manage a `BannerAd` instance directly.
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _startioFallback = false;

  @override
  void initState() {
    super.initState();
    if (!sl.premiumService.isPremium) {
      print('APP BANNER: INIT');

      _bannerAd = sl.adsService.createBannerAd(
        onFailed: () {
          if (mounted && Platform.isIOS && !sl.premiumService.isPremium) {
            setState(() => _startioFallback = true);
          }
        },
        onLoaded: (_) {
          print('APP BANNER: STATE UPDATED');
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
      );
    } else {
      print('APP BANNER: PREMIUM - HIDDEN');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (sl.premiumService.isPremium) {
      return const SizedBox.shrink();
    }

    if (_startioFallback && Platform.isIOS) {
      return const SafeArea(
        top: false,
        child: SizedBox(
          width: 320,
          height: 50,
          child: UiKitView(viewType: 'startio-banner'),
        ),
      );
    }

    final ad = _bannerAd;
    if (ad == null || !_isLoaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
