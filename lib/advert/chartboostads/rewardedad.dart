import 'dart:io';

import 'package:chartboost/chartboost.dart';
import 'package:flutter/material.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class ChartboostRewardedAdManager {
  final List<String> locations;
  final EventReporter _reporter;
  final String _adType;

  final Set<String> _cachedLocations = {};
  bool _isLoading = false;

  ChartboostRewardedAdManager(this.locations, this._reporter, {String adType = 'Chartboost_Rewarded'})
      : _adType = adType;

  bool get hasAds => _cachedLocations.isNotEmpty;

  void cacheNextAd() async {
    if (!Platform.isAndroid || _isLoading || locations.isEmpty) return;
    _isLoading = true;

    final location = locations.first;
    debugPrint('Caching Chartboost Rewarded ad ($_adType) for location: $location');

    try {
      await Chartboost.cacheInterstitial(location: location);
    } catch (e) {
      _isLoading = false;
      debugPrint('Chartboost Rewarded cache exception ($_adType): $e');
    }
  }

  void onAdCached(String location) {
    _cachedLocations.add(location);
    _isLoading = false;
    debugPrint('Chartboost Rewarded ad cached successfully ($_adType): $location');
  }

  void onAdFailedToLoad(String location, String error) {
    _isLoading = false;
    debugPrint('Chartboost Rewarded ad failed to load ($_adType: $location): $error');
    _reporter.reportEvent(
      event: AdEvent.failed,
      adProvider: 'Chartboost',
      adType: _adType,
      placementId: location,
      errorMessage: error,
    );
  }

  Advertresponse showAd(Function? onRewarded, Function? onClicked, {Function? onAdDismissed}) {
    final location = locations.isNotEmpty ? locations.first : 'Default';

    if (onClicked != null) onClicked();

    debugPrint('Showing Chartboost Rewarded ad ($_adType) at location: $location');

    try {
      Chartboost.showInterstitial(
        location: location,
        listener: (event) {
          debugPrint('Chartboost Rewarded event: $event');
          switch (event) {
            case ChartboostEventListener.didDisplayRewardedVideo:
            case ChartboostEventListener.didDisplayInterstitial:
              _reporter.reportEvent(
                event: AdEvent.displayed,
                adProvider: 'Chartboost',
                adType: _adType,
                placementId: location,
              );
            case ChartboostEventListener.didClickRewardedVideo:
            case ChartboostEventListener.didClickInterstitial:
              _reporter.reportEvent(
                event: AdEvent.clicked,
                adProvider: 'Chartboost',
                adType: _adType,
                placementId: location,
              );
            case ChartboostEventListener.didCompleteRewardedVideo:
              _reporter.reportEvent(
                event: AdEvent.completed,
                adProvider: 'Chartboost',
                adType: _adType,
                placementId: location,
              );
              if (onRewarded != null) {
                _invokeOnRewarded(onRewarded, 'Chartboost');
              }
            case ChartboostEventListener.didDismissRewardedVideo:
            case ChartboostEventListener.didCloseRewardedVideo:
            case ChartboostEventListener.didDismissInterstitial:
            case ChartboostEventListener.didCloseInterstitial:
              _cachedLocations.remove(location);
              if (onAdDismissed != null) onAdDismissed();
              cacheNextAd();
            default:
              break;
          }
        },
      );
    } catch (e) {
      debugPrint('Error showing Chartboost Rewarded ad ($_adType): $e');
      return Advertresponse.defaults(provider: 'Chartboost');
    }

    return Advertresponse.showing(provider: 'Chartboost');
  }
}

void _invokeOnRewarded(Function? callback, [dynamic provider]) {
  if (callback == null) return;
  if (provider is String) {
    if (callback is void Function(String?)) {
      callback(provider);
      return;
    }
    if (callback is void Function(String)) {
      callback(provider);
      return;
    }
    if (callback is void Function(Advertresponse)) {
      callback(Advertresponse.loaded(provider: provider));
      return;
    }
  } else if (provider is Advertresponse) {
    if (callback is void Function(Advertresponse)) {
      callback(provider);
      return;
    }
    if (callback is void Function(String?)) {
      callback(provider.provider);
      return;
    }
    if (callback is void Function(String)) {
      callback(provider.provider ?? '');
      return;
    }
  }

  if (callback is void Function()) {
    callback();
    return;
  }

  try {
    (callback as dynamic)(provider);
  } catch (_) {
    try {
      (callback as dynamic)();
    } catch (_) {}
  }
}
