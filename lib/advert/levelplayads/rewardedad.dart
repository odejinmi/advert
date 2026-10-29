import 'package:flutter/material.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class LevelPlayRewardedAdManager implements LevelPlayRewardedAdListener {
  final List<String> adUnitIds;
  final EventReporter _reporter;
  final String _adType;

  LevelPlayRewardedAd? _rewardedAd;
  bool _isReady = false;
  bool _isLoading = false;
  Function? _pendingOnRewarded;

  LevelPlayRewardedAdManager(this.adUnitIds, this._reporter, {String adType = 'LevelPlay_Rewarded'})
      : _adType = adType;

  bool get hasAds => _isReady && _rewardedAd != null;

  void loadAd() {
    if (_isLoading || adUnitIds.isEmpty || _isReady) return;
    _isLoading = true;

    final adUnitId = adUnitIds.first;
    debugPrint('Loading LevelPlay Rewarded ad ($_adType) for adUnitId: $adUnitId');

    _rewardedAd = LevelPlayRewardedAd(adUnitId: adUnitId);
    _rewardedAd!.setListener(this);
    _rewardedAd!.loadAd();
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    _isReady = true;
    _isLoading = false;
    debugPrint('LevelPlay Rewarded ad loaded successfully ($_adType): ${adInfo.adUnitId}');
    _reporter.reportEvent(
      event: AdEvent.displayed,
      adProvider: 'LevelPlay',
      adType: _adType,
      placementId: adInfo.adUnitId,
    );
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    _isReady = false;
    _isLoading = false;
    debugPrint('LevelPlay Rewarded ad failed to load ($_adType): ${error.errorMessage}');
    _reporter.reportEvent(
      event: AdEvent.failed,
      adProvider: 'LevelPlay',
      adType: _adType,
      placementId: adUnitIds.first,
      errorMessage: error.errorMessage,
    );
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay Rewarded ad displayed ($_adType): ${adInfo.adUnitId}');
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay Rewarded ad display failed ($_adType): ${error.errorMessage}');
    _isReady = false;
    loadAd();
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay Rewarded ad clicked ($_adType): ${adInfo.adUnitId}');
    _reporter.reportEvent(
      event: AdEvent.clicked,
      adProvider: 'LevelPlay',
      adType: _adType,
      placementId: adInfo.adUnitId,
    );
  }

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay Rewarded ad rewarded ($_adType): ${reward.name} ${reward.amount}');
    _reporter.reportEvent(
      event: AdEvent.completed,
      adProvider: 'LevelPlay',
      adType: _adType,
      placementId: adInfo.adUnitId,
    );
    if (_pendingOnRewarded != null) {
      _invokeOnRewarded(_pendingOnRewarded, 'LevelPlay');
      _pendingOnRewarded = null;
    }
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay Rewarded ad closed ($_adType): ${adInfo.adUnitId}');
    _isReady = false;
    _rewardedAd = null;
    loadAd();
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}

  Advertresponse showAd(Function? onRewarded, Function? onClicked, {Function? onAdDismissed}) {
    if (!hasAds) {
      loadAd();
      debugPrint('Warning: attempt to show LevelPlay Rewarded ad before loaded.');
      return Advertresponse.defaults(provider: 'LevelPlay');
    }

    _pendingOnRewarded = onRewarded;

    if (onClicked != null) onClicked();

    debugPrint('Showing LevelPlay Rewarded ad ($_adType)');
    _rewardedAd!.showAd();

    if (onAdDismissed != null) onAdDismissed();

    return Advertresponse.showing(provider: 'LevelPlay');
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
