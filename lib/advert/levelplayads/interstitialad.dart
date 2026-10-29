import 'package:flutter/material.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class LevelPlayInterstitialAdManager implements LevelPlayInterstitialAdListener {
  final List<String> adUnitIds;
  final EventReporter _reporter;
  final String _adType;

  LevelPlayInterstitialAd? _interstitialAd;
  bool _isReady = false;
  bool _isLoading = false;

  LevelPlayInterstitialAdManager(this.adUnitIds, this._reporter, {String adType = 'LevelPlay_Interstitial'})
      : _adType = adType;

  bool get hasAds => _isReady && _interstitialAd != null;

  void loadAd() {
    if (_isLoading || adUnitIds.isEmpty || _isReady) return;
    _isLoading = true;

    final adUnitId = adUnitIds.first;
    debugPrint('Loading LevelPlay Interstitial ad ($_adType) for adUnitId: $adUnitId');

    _interstitialAd = LevelPlayInterstitialAd(adUnitId: adUnitId);
    _interstitialAd!.setListener(this);
    _interstitialAd!.loadAd();
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    _isReady = true;
    _isLoading = false;
    debugPrint('LevelPlay Interstitial ad loaded successfully ($_adType): ${adInfo.adUnitId}');
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
    debugPrint('LevelPlay Interstitial ad failed to load ($_adType): ${error.errorMessage}');
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
    debugPrint('LevelPlay Interstitial ad displayed ($_adType): ${adInfo.adUnitId}');
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay Interstitial ad display failed ($_adType): ${error.errorMessage}');
    _isReady = false;
    loadAd();
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay Interstitial ad clicked ($_adType): ${adInfo.adUnitId}');
    _reporter.reportEvent(
      event: AdEvent.clicked,
      adProvider: 'LevelPlay',
      adType: _adType,
      placementId: adInfo.adUnitId,
    );
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay Interstitial ad closed ($_adType): ${adInfo.adUnitId}');
    _isReady = false;
    _interstitialAd = null;
    loadAd();
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}

  Advertresponse showAd(Function? onClick) {
    if (!hasAds) {
      loadAd();
      debugPrint('Warning: attempt to show LevelPlay Interstitial ad before loaded.');
      return Advertresponse.defaults(provider: 'LevelPlay');
    }

    if (onClick != null) onClick();

    debugPrint('Showing LevelPlay Interstitial ad ($_adType)');
    _interstitialAd!.showAd();

    return Advertresponse.showing(provider: 'LevelPlay');
  }
}
