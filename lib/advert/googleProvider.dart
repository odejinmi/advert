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
    _adConfig.interstitialHigh.forEach((type, ids) {
      _interstitialManagers['${type}_high'] =
          InterstitialAdManager(ids, _reporter, adType: '${type}_High');
      _interstitialManagers['${type}_low'] =
          InterstitialAdManager(_adConfig.interstitialLow[type] ?? [], _reporter, adType: '${type}_Low');
    });

    // Rewarded
    _adConfig.rewardedHigh.forEach((type, ids) {
      _rewardedManagers['${type}_high'] =
          RewardedAdManager(ids, _reporter, adType: '${type}_High');
      _rewardedManagers['${type}_low'] =
          RewardedAdManager(_adConfig.rewardedLow[type] ?? [], _reporter, adType: '${type}_Low');
    });

    // Native
    _adConfig.nativeHigh.forEach((type, ids) {
      _nativeManagers['${type}_high'] =
          NativeAdManager(ids, _reporter, adType: '${type}_High');
      _nativeManagers['${type}_low'] =
          NativeAdManager(_adConfig.nativeLow[type] ?? [], _reporter, adType: '${type}_Low');
    });

    // Banner
    _adConfig.bannerHigh.forEach((type, ids) {
      _bannerManagers['${type}_high'] =
          BannerAdManager(ids, _reporter, adType: '${type}_High');
      _bannerManagers['${type}_low'] =
          BannerAdManager(_adConfig.bannerLow[type] ?? [], _reporter, adType: '${type}_Low');
    });

    // Rewarded Interstitials
    _adConfig.rewardedInterstitialHigh.forEach((type, ids) {
      _rewardedInterstitialManagers['${type}_high'] =
          RewardedInterstitialAdManager(ids, _reporter, adType: '${type}_High');
      _rewardedInterstitialManagers['${type}_low'] =
          RewardedInterstitialAdManager(_adConfig.rewardedInterstitialLow[type] ?? [], _reporter, adType: '${type}_Low');
    });
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

  /// Shows a rewarded ad with reward callback and fallbacks (High -> Low -> Interstitial)
  Advertresponse showRewardedAd({
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    // 1. Try High Priority
    final managerHigh = _rewardedManagers['${type}_high'];
    if (managerHigh != null && managerHigh.hasAds) {
      return managerHigh.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }

    // 2. Try Low Priority
    final managerLow = _rewardedManagers['${type}_low'];
    if (managerLow != null && managerLow.hasAds) {
      return managerLow.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }

    // 3. Fallback to Rewarded Interstitial (if standard rewarded fails)
    if (type == 'rewarded' && hasRewardedInterstitialAd) {
      return _rewardedInterstitialManagers['rewardedInterstitial_high']!.showAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }

    // 4. Special case for 'freemoney': High -> Low -> Interstitial fallback
    if (type == 'freemoney' && (_interstitialManagers['freemoney_inters']?.hasAds ?? false)) {
      return _interstitialManagers['freemoney_inters']!.showAd(
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onRewarded,
      );
    }

    return Advertresponse.defaults();
  }

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
