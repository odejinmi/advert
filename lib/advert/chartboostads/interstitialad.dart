import 'dart:io';

// import 'package:chartboost/chartboost.dart';
import 'package:flutter/material.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class ChartboostInterstitialAdManager {
  final List<String> locations;
  final EventReporter _reporter;
  final String _adType;

  final Set<String> _cachedLocations = {};
  bool _isLoading = false;

  ChartboostInterstitialAdManager(this.locations, this._reporter, {String adType = 'Chartboost_Interstitial'})
      : _adType = adType;

  bool get hasAds => _cachedLocations.isNotEmpty;

  void cacheNextAd() async {
    if (!Platform.isAndroid || _isLoading || locations.isEmpty) return;
    _isLoading = true;

    final location = locations.first;
    debugPrint('Caching Chartboost Interstitial ad ($_adType) for location: $location');

    try {
      // await Chartboost.cacheInterstitial(location: location);
    } catch (e) {
      _isLoading = false;
      debugPrint('Chartboost Interstitial cache exception ($_adType): $e');
    }
  }

  void onAdCached(String location) {
    _cachedLocations.add(location);
    _isLoading = false;
    debugPrint('Chartboost Interstitial ad cached successfully ($_adType): $location');
  }

  void onAdFailedToLoad(String location, String error) {
    _isLoading = false;
    debugPrint('Chartboost Interstitial ad failed to load ($_adType: $location): $error');
    _reporter.reportEvent(
      event: AdEvent.failed,
      adProvider: 'Chartboost',
      adType: _adType,
      placementId: location,
      errorMessage: error,
    );
  }

  Advertresponse showAd(Function? onClick) {
    final location = locations.isNotEmpty ? locations.first : 'Default';

    if (onClick != null) onClick();

    debugPrint('Showing Chartboost Interstitial ad ($_adType) at location: $location');

    try {
      // Chartboost.showInterstitial(
      //   location: location,
      //   listener: (event) {
      //     debugPrint('Chartboost Interstitial event: $event');
      //     switch (event) {
      //       case ChartboostEventListener.didDisplayInterstitial:
      //         _reporter.reportEvent(
      //           event: AdEvent.displayed,
      //           adProvider: 'Chartboost',
      //           adType: _adType,
      //           placementId: location,
      //         );
      //       case ChartboostEventListener.didClickInterstitial:
      //         _reporter.reportEvent(
      //           event: AdEvent.clicked,
      //           adProvider: 'Chartboost',
      //           adType: _adType,
      //           placementId: location,
      //         );
      //       case ChartboostEventListener.didDismissInterstitial:
      //       case ChartboostEventListener.didCloseInterstitial:
      //         _cachedLocations.remove(location);
      //         cacheNextAd();
      //       default:
      //         break;
      //     }
      //   },
      // );
    } catch (e) {
      debugPrint('Error showing Chartboost Interstitial ad ($_adType): $e');
      return Advertresponse.defaults(provider: 'Chartboost');
    }

    return Advertresponse.showing(provider: 'Chartboost');
  }
}
