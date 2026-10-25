import 'package:flutter/material.dart';
import 'package:hx_liftoff_ads/hx_liftoff_ads.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class VungleRewardedAdManager {
  final List<String> placementIds;
  final EventReporter _reporter;
  final String _adType;

  RewardedAd? _loadedAd;
  bool _isLoading = false;

  VungleRewardedAdManager(this.placementIds, this._reporter, {String adType = 'Vungle_Rewarded'})
      : _adType = adType;

  bool get hasAds => _loadedAd != null && _loadedAd!.isLoaded;

  Future<void> loadNextAd() async {
    if (_isLoading || placementIds.isEmpty || hasAds) return;
    _isLoading = true;

    final placementId = placementIds.first;
    try {
      final ad = await RewardedAd.load(
        placementId: placementId,
        listener: FullscreenAdListener(
          onShown: () {
            _reporter.reportEvent(
              event: AdEvent.displayed,
              adProvider: 'Vungle',
              adType: _adType,
              placementId: placementId,
            );
          },
          onClicked: () {
            _reporter.reportEvent(
              event: AdEvent.clicked,
              adProvider: 'Vungle',
              adType: _adType,
              placementId: placementId,
            );
          },
          onClosed: () {
            _loadedAd = null;
            loadNextAd();
          },
          onFailedToShow: (error) {
            _reporter.reportEvent(
              event: AdEvent.failed,
              adProvider: 'Vungle',
              adType: _adType,
              placementId: placementId,
              errorMessage: error.message,
            );
            _loadedAd = null;
            loadNextAd();
          },
        ),
      );
      _loadedAd = ad;
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _reporter.reportEvent(
        event: AdEvent.failed,
        adProvider: 'Vungle',
        adType: _adType,
        placementId: placementId,
        errorMessage: e.toString(),
      );
    }
  }

  Advertresponse showAd(Function? onRewarded, Function? onClicked, {Function? onAdDismissed}) {
    if (!hasAds) {
      loadNextAd();
      debugPrint('Warning: attempt to show Vungle rewarded ad before loaded.');
      return Advertresponse.defaults(provider: 'Vungle');
    }

    final currentAd = _loadedAd!;
    _loadedAd = null;

    if (onRewarded != null) {
      _invokeOnRewarded(onRewarded, 'Vungle');
    }

    if (onClicked != null) onClicked();

    currentAd.show().catchError((e) {
      debugPrint('Error showing Vungle Rewarded ad: $e');
    });

    if (onAdDismissed != null) {
      onAdDismissed();
    }

    return Advertresponse.showing(provider: 'Vungle');
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
