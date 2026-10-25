import 'package:flutter/material.dart';
import 'package:hx_liftoff_ads/hx_liftoff_ads.dart';

import '../model/advertresponse.dart';
import '../model/vungle.dart';
import 'event_reporter.dart';
import 'vungleads/appopenad.dart';
import 'vungleads/bannerad.dart';
import 'vungleads/interstitialad.dart';
import 'vungleads/nativead.dart';
import 'vungleads/rewardedad.dart';

class VungleProvider {
  final Vunglemodel vunglemodel;
  final EventReporter _reporter;
  final bool testmode;
  bool _isInitialized = false;

  final Map<String, VungleInterstitialAdManager> _interstitialManagers = {};
  final Map<String, VungleRewardedAdManager> _rewardedManagers = {};
  final Map<String, VungleNativeAdManager> _nativeManagers = {};
  final Map<String, VungleAppOpenAdManager> _appOpenManagers = {};

  VungleProvider(this.vunglemodel, this._reporter, this.testmode) {
    _initVungle();
  }

  Future<void> _initVungle() async {
    if (vunglemodel.appId.isEmpty) return;

    try {
      await LiftoffAds.instance.initialize(
        appId: vunglemodel.appId,
      );
      debugPrint('Liftoff/Vungle Ads Initialized with App ID: ${vunglemodel.appId}');
      _isInitialized = true;
      _initializeAdManagers();
      loadAllAds();
    } catch (e) {
      debugPrint('Liftoff/Vungle Ads Initialization Error: $e');
    }
  }

  void _initializeAdManagers() {
    vunglemodel.interstitialPlacements.forEach((type, ids) {
      _interstitialManagers[type] = VungleInterstitialAdManager(ids, _reporter, adType: 'Vungle_Interstitial_$type');
    });

    vunglemodel.rewardedPlacements.forEach((type, ids) {
      _rewardedManagers[type] = VungleRewardedAdManager(ids, _reporter, adType: 'Vungle_Rewarded_$type');
    });

    vunglemodel.nativePlacements.forEach((type, ids) {
      _nativeManagers[type] = VungleNativeAdManager(ids, _reporter, adType: 'Vungle_Native_$type');
    });

    vunglemodel.appOpenPlacements.forEach((type, ids) {
      _appOpenManagers[type] = VungleAppOpenAdManager(ids, _reporter, adType: 'Vungle_AppOpen_$type');
    });
  }

  bool hasInterstitialAdByType(String type) => _interstitialManagers[type]?.hasAds ?? false;
  bool get hasInterstitialAd => hasInterstitialAdByType('interstitial');

  bool hasRewardedAdByType(String type) => _rewardedManagers[type]?.hasAds ?? false;
  bool get hasRewardedAd => hasRewardedAdByType('rewarded');

  bool hasNativeAdByType(String type) => _nativeManagers[type]?.isAdLoaded ?? false;
  bool get hasNativeAd => hasNativeAdByType('native');

  bool hasAppOpenAdByType(String type) => _appOpenManagers[type]?.hasAds ?? false;
  bool get hasAppOpenAd => hasAppOpenAdByType('appOpen');

  void loadAllAds() {
    for (var manager in _rewardedManagers.values) {
      manager.loadNextAd();
    }
    for (var manager in _interstitialManagers.values) {
      manager.loadNextAd();
    }
    for (var manager in _nativeManagers.values) {
      manager.loadAd();
    }
    for (var manager in _appOpenManagers.values) {
      manager.loadAd();
    }
  }

  void loadNativeAd({String type = 'native'}) {
    _nativeManagers[type]?.loadAd();
  }

  void loadAppOpenAd({String type = 'appOpen'}) {
    _appOpenManagers[type]?.loadAd();
  }

  Advertresponse showInterstitialAd(Function? onClick, {String type = 'interstitial'}) {
    return _interstitialManagers[type]?.showAd(onClick) ?? Advertresponse.defaults(provider: 'Vungle');
  }

  Advertresponse showRewardedAd(Function? onRewarded, Function? onClick, {String type = 'rewarded', Function? onAdDismissed}) {
    return _rewardedManagers[type]?.showAd(onRewarded, onClick, onAdDismissed: onAdDismissed) ?? Advertresponse.defaults(provider: 'Vungle');
  }

  Widget showNativeAd(BuildContext context, {String type = 'native'}) {
    return _nativeManagers[type]?.buildAdWidget(context) ?? const SizedBox.shrink();
  }

  Advertresponse showAppOpenAd({String type = 'appOpen', Function? onAdDismissed}) {
    return _appOpenManagers[type]?.showAd(onAdDismissed: onAdDismissed) ?? Advertresponse.defaults(provider: 'Vungle');
  }

  Widget adWidget() {
    if (vunglemodel.bannerAdPlacementId.isEmpty) {
      return const SizedBox.shrink();
    }
    return VungleBannerAdWidget(
      placementIds: vunglemodel.bannerAdPlacementId,
      reporter: _reporter,
    );
  }
}
