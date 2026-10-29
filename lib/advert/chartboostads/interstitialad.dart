import 'package:chartboost_flutter/chartboost_flutter.dart';
import 'package:flutter/material.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class ChartboostInterstitialAdManager implements ChartboostInterstitialDelegate {
  final List<String> locations;
  final EventReporter _reporter;
  final String _adType;

  final Set<String> _cachedLocations = {};
  bool _isLoading = false;

  ChartboostInterstitialAdManager(this.locations, this._reporter, {String adType = 'Chartboost_Interstitial'})
      : _adType = adType {
    Chartboost.setInterstitialDelegate(this);
  }

  bool get hasAds => _cachedLocations.isNotEmpty;

  void cacheNextAd() async {
    if (_isLoading || locations.isEmpty) return;
    _isLoading = true;

    final location = locations.first;
    debugPrint('Caching Chartboost Interstitial ad ($_adType) for location: $location');

    try {
      await Chartboost.cacheInterstitial(location);
    } catch (e) {
      _isLoading = false;
      debugPrint('Chartboost Interstitial cache exception ($_adType): $e');
    }
  }

  @override
  void onInterstitialCached(String location, String? error) {
    _isLoading = false;
    if (error == null || error.isEmpty) {
      _cachedLocations.add(location);
      debugPrint('Chartboost Interstitial ad cached successfully ($_adType): $location');
    } else {
      debugPrint('Chartboost Interstitial ad failed to cache ($_adType: $location): $error');
      _reporter.reportEvent(
        event: AdEvent.failed,
        adProvider: 'Chartboost',
        adType: _adType,
        placementId: location,
        errorMessage: error,
      );
    }
  }

  @override
  void onInterstitialShown(String location, String? error) {
    if (error == null || error.isEmpty) {
      debugPrint('Chartboost Interstitial ad shown ($_adType): $location');
      _reporter.reportEvent(
        event: AdEvent.displayed,
        adProvider: 'Chartboost',
        adType: _adType,
        placementId: location,
      );
    } else {
      debugPrint('Chartboost Interstitial ad show error ($_adType: $location): $error');
      _reporter.reportEvent(
        event: AdEvent.failed,
        adProvider: 'Chartboost',
        adType: _adType,
        placementId: location,
        errorMessage: error,
      );
    }
  }

  @override
  void onInterstitialDismissed(String location) {
    debugPrint('Chartboost Interstitial ad dismissed ($_adType): $location');
    _cachedLocations.remove(location);
    cacheNextAd();
  }

  @override
  void onInterstitialClicked(String location, String? error) {
    debugPrint('Chartboost Interstitial ad clicked ($_adType): $location');
    _reporter.reportEvent(
      event: AdEvent.clicked,
      adProvider: 'Chartboost',
      adType: _adType,
      placementId: location,
    );
  }

  @override
  void onInterstitialImpressionRecorded(String location) {}

  Advertresponse showAd(Function? onClick) {
    final location = locations.isNotEmpty ? locations.first : 'Default';

    if (onClick != null) onClick();

    debugPrint('Showing Chartboost Interstitial ad ($_adType) at location: $location');

    try {
      Chartboost.showInterstitial(location);
    } catch (e) {
      debugPrint('Error showing Chartboost Interstitial ad ($_adType): $e');
      return Advertresponse.defaults(provider: 'Chartboost');
    }

    return Advertresponse.showing(provider: 'Chartboost');
  }
}
