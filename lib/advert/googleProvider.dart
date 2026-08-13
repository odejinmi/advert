import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../model/advertresponse.dart';
import '../model/google.dart';
import 'event_reporter.dart';
import 'googleads/bannerad.dart';
import 'googleads/interstitialad.dart';
import 'googleads/nativead.dart';
import 'googleads/rewardedad.dart';
import 'googleads/rewardedinterstitialad.dart';

class GoogleAdProvider {
  // Constants
  static const int MAX_RETRY_ATTEMPTS = 3;

  // Platform-specific app IDs
  static String get appId => Platform.isAndroid
      ? 'ca-app-pub-6117361441866120~5829948546'
      : 'ca-app-pub-6117361441866120~7211527566';

  // Private variables
  final Googlemodel _adConfig;
  final EventReporter _reporter;
  final Map<String, int> _showPositionMap = {};
  final Map<String, int> _retryAttemptsMap = {};

  // Ad managers
  final Map<String, InterstitialAdManager> _interstitialManagers = {};
  final Map<String, RewardedAdManager> _rewardedManagers = {};
  final Map<String, NativeAdManager> _nativeManagers = {};
  final Map<String, BannerAdManager> _bannerManagers = {};
  final Map<String, RewardedInterstitialAdManager> _rewardedInterstitialManagers = {};

  // Constructor
  GoogleAdProvider(this._adConfig, this._reporter) {
    MobileAds.instance.initialize();
    _initializeAdManagers();
  }

  /// Initializes all ad managers
  void _initializeAdManagers() {
    // Interstitials
    _interstitialManagers['interstitial_high'] =
        InterstitialAdManager(_adConfig.interstitialAdUnitId, _reporter, adType: 'Interstitial_High');
    _interstitialManagers['interstitial_low'] =
        InterstitialAdManager(_adConfig.interstitialAdUnitIdLow, _reporter, adType: 'Interstitial_Low');

    // Rewarded
    _rewardedManagers['rewarded_high'] =
        RewardedAdManager(_adConfig.rewardedAdUnitId, _reporter, adType: 'Rewarded_High');
    _rewardedManagers['rewarded_low'] =
        RewardedAdManager(_adConfig.rewardedAdUnitIdLow, _reporter, adType: 'Rewarded_Low');
    
    _rewardedManagers['spinAndWin_high'] =
        RewardedAdManager(_adConfig.spinAndWin, _reporter, adType: 'SpinAndWin_High');
    _rewardedManagers['spinAndWin_low'] =
        RewardedAdManager(_adConfig.spinAndWinLow, _reporter, adType: 'SpinAndWin_Low');

    _rewardedManagers['freemoney_high'] =
        RewardedAdManager(_adConfig.freemoney, _reporter, adType: 'Freemoney_High');
    _rewardedManagers['freemoney_low'] =
        RewardedAdManager(_adConfig.freemoneyLow, _reporter, adType: 'Freemoney_Low');

    // Native
    _nativeManagers['native_high'] =
        NativeAdManager(_adConfig.nativeAdUnitId, _reporter, adType: 'Native_High');
    _nativeManagers['native_low'] =
        NativeAdManager(_adConfig.nativeAdUnitIdLow, _reporter, adType: 'Native_Low');

    // Banner
    _bannerManagers['banner_high'] =
        BannerAdManager(_adConfig.bannerAdUnitId, _reporter, adType: 'Banner_High');
    _bannerManagers['banner_low'] =
        BannerAdManager(_adConfig.bannerAdUnitIdLow, _reporter, adType: 'Banner_Low');

    // Rewarded Interstitials
    _rewardedInterstitialManagers['rewardedInterstitial_high'] = 
        RewardedInterstitialAdManager(_adConfig.rewardedInterstitialAdUnitId, _reporter, adType: 'RewardedInterstitial_High');
    _rewardedInterstitialManagers['rewardedInterstitial_low'] = 
        RewardedInterstitialAdManager(_adConfig.rewardedInterstitialAdUnitIdLow, _reporter, adType: 'RewardedInterstitial_Low');
    
    // Special Interstitial fallbacks
    _interstitialManagers['freemoney_inters'] =
        InterstitialAdManager(_adConfig.freemoneyInterstitial, _reporter, adType: 'Freemoney_Inters');
  }

  // Getters
  bool hasInterstitialAdByType(String type) {
    return (_interstitialManagers['${type}_high']?.hasAds ?? false) || 
           (_interstitialManagers['${type}_low']?.hasAds ?? false);
  }
  bool get hasInterstitialAd => hasInterstitialAdByType('interstitial');
  
  bool hasRewardedAdByType(String type) {
    return (_rewardedManagers['${type}_high']?.hasAds ?? false) || 
           (_rewardedManagers['${type}_low']?.hasAds ?? false);
  }
  bool get hasRewardedAd => hasRewardedAdByType('rewarded');
  bool get hasspinAndWin => hasRewardedAdByType('spinAndWin');
  bool get hasfreemoney => hasRewardedAdByType('freemoney') || (_interstitialManagers['freemoney_inters']?.hasAds ?? false);
  
  bool hasNativeAdByType(String type) {
    return (_nativeManagers['${type}_high']?.isAdLoaded ?? false) || 
           (_nativeManagers['${type}_low']?.isAdLoaded ?? false);
  }
  bool get hasNativeAd => hasNativeAdByType('native');

  bool hasRewardedInterstitialAdByType(String type) {
    return (_rewardedInterstitialManagers['${type}_high']?.hasAds ?? false) || 
           (_rewardedInterstitialManagers['${type}_low']?.hasAds ?? false);
  }
  bool get hasRewardedInterstitialAd => hasRewardedInterstitialAdByType('rewardedInterstitial');

  int get adProviderCount => 2; 

  /// Preloads all ad types
  void preloadAllAds() {
    for (var manager in _interstitialManagers.values) manager.preloadAds();
    for (var manager in _rewardedManagers.values) manager.preloadAds();
    for (var manager in _nativeManagers.values) manager.loadAd();
    for (var manager in _bannerManagers.values) manager.loadAd();
    for (var manager in _rewardedInterstitialManagers.values) manager.preloadAds();
  }

  /// Loads a native ad
  void loadNativeAd({String type = 'native'}) {
    _nativeManagers['${type}_high']?.loadAd();
    _nativeManagers['${type}_low']?.loadAd();
  }

  /// Loads an interstitial ad
  void loadInterstitialAd({String type = 'interstitial'}) {
    _interstitialManagers['${type}_high']?.preloadAds();
    _interstitialManagers['${type}_low']?.preloadAds();
    if (type == 'freemoney') _interstitialManagers['freemoney_inters']?.preloadAds();
  }

  /// Loads a rewarded ad
  void loadRewardedAd({String? type}) {
    if (type != null) {
      _rewardedManagers['${type}_high']?.preloadAds();
      _rewardedManagers['${type}_low']?.preloadAds();
    } else {
      for (var manager in _rewardedManagers.values) {
        manager.preloadAds();
      }
    }
  }

  /// Loads a rewarded interstitial ad
  void loadRewardedInterstitialAd({String type = 'rewardedInterstitial'}) {
    _rewardedInterstitialManagers['${type}_high']?.preloadAds();
    _rewardedInterstitialManagers['${type}_low']?.preloadAds();
  }

  /// Loads all rewarded ad types
  void loadRewardAds() {
    loadRewardedAd();
    loadRewardedInterstitialAd();
    loadInterstitialAd(type: 'freemoney');
  }

  /// Shows a native ad
  Widget showNativeAd(BuildContext context, {String type = 'native'}) {
    if (_nativeManagers['${type}_high']?.isAdLoaded ?? false) {
      return _nativeManagers['${type}_high']!.buildAdWidget(context, autoClose: false);
    }
    return _nativeManagers['${type}_low']?.buildAdWidget(context, autoClose: false) ?? Container();
  }

  /// Shows an interstitial ad
  Advertresponse showInterstitialAd({
    String type = 'interstitial',
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
  }) {
    if (_interstitialManagers['${type}_high']?.hasAds ?? false) {
      return _interstitialManagers['${type}_high']!.showAd(
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onAdDismissed,
      );
    }
    return _interstitialManagers['${type}_low']?.showAd(
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      onAdDismissed: onAdDismissed,
    ) ?? Advertresponse.defaults();
  }

  /// Shows a rewarded ad with reward callback
  Advertresponse showRewardedAd({
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    final managerHigh = _rewardedManagers['${type}_high'];
    if (managerHigh != null && managerHigh.hasAds) {
      return managerHigh.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    final managerLow = _rewardedManagers['${type}_low'];
    if (managerLow != null && managerLow.hasAds) {
      return managerLow.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  /// Shows a rewarded ad with reward callback and fallbacks
  Advertresponse showmergeRewardedAd({
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    final managerHigh = _rewardedManagers['${type}_high'];
    if (managerHigh != null && managerHigh.hasAds) {
      return managerHigh.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }

    final managerLow = _rewardedManagers['${type}_low'];
    if (managerLow != null && managerLow.hasAds) {
      return managerLow.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }

    if (type == 'rewarded' && hasRewardedInterstitialAd) {
      return _rewardedInterstitialManagers['rewardedInterstitial_high']!.showAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }

    if (type == 'freemoney' && (_interstitialManagers['freemoney_inters']?.hasAds ?? false)) {
      return _interstitialManagers['freemoney_inters']!.showAd(
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onRewarded,
      );
    }

    return Advertresponse.defaults();
  }

  // Keep these for backward compatibility
  Advertresponse showspinAndWin({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) => showmergeRewardedAd(type: 'spinAndWin', onRewarded: onRewarded, onAdClicked: onAdClicked, onAdImpression: onAdImpression, customData: customData);

  Advertresponse showfreemoney({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) => showmergeRewardedAd(type: 'freemoney', onRewarded: onRewarded, onAdClicked: onAdClicked, onAdImpression: onAdImpression, customData: customData);

  /// Shows a rewarded interstitial ad with reward callback
  Advertresponse showRewardedInterstitialAd({
    String type = 'rewardedInterstitial',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) {
    return _rewardedInterstitialManagers[type]?.showAd(
      onRewarded: onRewarded,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      customData: customData,
    ) ?? Advertresponse.defaults();
  }

  /// Returns a banner ad widget
  Widget showBannerAd({String type = 'banner'}) {
    if (_bannerManagers['${type}_high']?.bannerReady ?? false) {
      return _bannerManagers['${type}_high']!.adWidget();
    }
    return _bannerManagers['${type}_low']?.adWidget() ?? Container();
  }

  void dispose() {
    for (var m in _interstitialManagers.values) m.dispose();
    for (var m in _rewardedManagers.values) m.dispose();
    for (var m in _nativeManagers.values) m.dispose();
    for (var m in _bannerManagers.values) m.dispose();
    for (var m in _rewardedInterstitialManagers.values) m.dispose();
  }
}
