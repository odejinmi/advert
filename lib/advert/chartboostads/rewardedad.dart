import 'package:chartboost_flutter/chartboost_flutter.dart';
import 'package:flutter/material.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class ChartboostRewardedAdManager implements ChartboostRewardedDelegate {
  final List<String> locations;
  final EventReporter _reporter;
  final String _adType;

  final Set<String> _cachedLocations = {};
  bool _isLoading = false;
  Function? _pendingOnRewarded;
  Function? _pendingOnDismissed;

  ChartboostRewardedAdManager(this.locations, this._reporter, {String adType = 'Chartboost_Rewarded'})
      : _adType = adType {
    Chartboost.setRewardedDelegate(this);
  }

  bool get hasAds => _cachedLocations.isNotEmpty;

  void cacheNextAd() async {
    if (_isLoading || locations.isEmpty) return;
    _isLoading = true;

    final location = locations.first;
    debugPrint('Caching Chartboost Rewarded ad ($_adType) for location: $location');

    try {
      await Chartboost.cacheRewarded(location);
    } catch (e) {
      _isLoading = false;
      debugPrint('Chartboost Rewarded cache exception ($_adType): $e');
    }
  }

  @override
  void onRewardedCached(String location, String? error) {
    _isLoading = false;
    if (error == null || error.isEmpty) {
      _cachedLocations.add(location);
      debugPrint('Chartboost Rewarded ad cached successfully ($_adType): $location');
    } else {
      debugPrint('Chartboost Rewarded ad failed to cache ($_adType: $location): $error');
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
  void onRewardedShown(String location, String? error) {
    if (error == null || error.isEmpty) {
      debugPrint('Chartboost Rewarded ad shown ($_adType): $location');
      _reporter.reportEvent(
        event: AdEvent.displayed,
        adProvider: 'Chartboost',
        adType: _adType,
        placementId: location,
      );
    } else {
      debugPrint('Chartboost Rewarded ad show error ($_adType: $location): $error');
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
  void onRewardEarned(String location, int rewardAmount) {
    debugPrint('Chartboost Rewarded ad reward earned ($_adType): $rewardAmount');
    _reporter.reportEvent(
      event: AdEvent.completed,
      adProvider: 'Chartboost',
      adType: _adType,
      placementId: location,
    );
    if (_pendingOnRewarded != null) {
      _invokeOnRewarded(_pendingOnRewarded, 'Chartboost');
      _pendingOnRewarded = null;
    }
  }

  @override
  void onRewardedDismissed(String location) {
    debugPrint('Chartboost Rewarded ad dismissed ($_adType): $location');
    _cachedLocations.remove(location);
    if (_pendingOnDismissed != null) {
      _pendingOnDismissed!();
      _pendingOnDismissed = null;
    }
    cacheNextAd();
  }

  @override
  void onRewardedClicked(String location, String? error) {
    debugPrint('Chartboost Rewarded ad clicked ($_adType): $location');
    _reporter.reportEvent(
      event: AdEvent.clicked,
      adProvider: 'Chartboost',
      adType: _adType,
      placementId: location,
    );
  }

  @override
  void onRewardedImpressionRecorded(String location) {}

  Advertresponse showAd(Function? onRewarded, Function? onClicked, {Function? onAdDismissed}) {
    final location = locations.isNotEmpty ? locations.first : 'Default';

    _pendingOnRewarded = onRewarded;
    _pendingOnDismissed = onAdDismissed;

    if (onClicked != null) onClicked();

    debugPrint('Showing Chartboost Rewarded ad ($_adType) at location: $location');

    try {
      Chartboost.showRewarded(location);
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
