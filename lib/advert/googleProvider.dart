import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../model/advertresponse.dart';
import '../model/google.dart';
import 'event_reporter.dart';
import 'googleads/appopenad.dart';
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
  final Map<String, AppOpenAdManager> _appOpenManagers = {};

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

    // App Open
    _adConfig.appOpenHigh.forEach((type, ids) {
      _appOpenManagers['${type}_high'] =
          AppOpenAdManager(ids, _reporter, adType: '${type}_High');
      _appOpenManagers['${type}_low'] =
          AppOpenAdManager(_adConfig.appOpenLow[type] ?? [], _reporter, adType: '${type}_Low');
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

  bool hasAppOpenAdByType(String type) {
    return (_appOpenManagers['${type}_high']?.hasAds ?? false) || 
           (_appOpenManagers['${type}_low']?.hasAds ?? false);
  }
  bool get hasAppOpenAd => hasAppOpenAdByType('appOpen');

  int get adProviderCount => 2; 

  /// Preloads all ad types
  void preloadAllAds() {
    for (var manager in _interstitialManagers.values) {
      manager.preloadAds();
    }
    for (var manager in _rewardedManagers.values) {
      manager.preloadAds();
    }
    for (var manager in _nativeManagers.values) {
      manager.loadAd();
    }
    for (var manager in _bannerManagers.values) {
      manager.loadAd();
    }
    for (var manager in _rewardedInterstitialManagers.values) {
      manager.preloadAds();
    }
    for (var manager in _appOpenManagers.values) {
      manager.preloadAds();
    }
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

  /// Loads an app open ad
  void loadAppOpenAd({String type = 'appOpen'}) {
    _appOpenManagers['${type}_high']?.preloadAds();
    _appOpenManagers['${type}_low']?.preloadAds();
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

  /// Shows a rewarded ad with reward callback and fallbacks (High -> Low -> Interstitial)
  Advertresponse showRewardedAd({
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
    Map<String, String> customData = const {},
  }) {
    // 1. Try High Priority
    final resHigh = showHighRewardedAd(
      type: type,
      onRewarded: onRewarded,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      onAdDismissed: onAdDismissed,
      customData: customData,
    );
    if (resHigh.status) return resHigh;

    // 2. Try Low Priority
    final resLow = showLowRewardedAd(
      type: type,
      onRewarded: onRewarded,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      onAdDismissed: onAdDismissed,
      customData: customData,
    );
    if (resLow.status) return resLow;

    // 3. Fallback to Rewarded Interstitial (if standard rewarded fails)
    if (type == 'rewarded' && hasRewardedInterstitialAd) {
      return _rewardedInterstitialManagers['rewardedInterstitial_high']!.showAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }

    return Advertresponse.defaults();
  }

  /// Shows only the high priority rewarded ad
  Advertresponse showHighRewardedAd({
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
    Map<String, String> customData = const {},
  }) {
    final manager = _rewardedManagers['${type}_high'];
    if (manager != null && manager.hasAds) {
      return manager.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onAdDismissed,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  /// Shows only the low priority rewarded ad
  Advertresponse showLowRewardedAd({
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
    Map<String, String> customData = const {},
  }) {
    final manager = _rewardedManagers['${type}_low'];
    if (manager != null && manager.hasAds) {
      return manager.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onAdDismissed,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  /// Shows an interstitial ad with fallback (High -> Low)
  Advertresponse showInterstitialAd({
    String type = 'interstitial',
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
  }) {
    final resHigh = showHighInterstitialAd(
      type: type,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      onAdDismissed: onAdDismissed,
    );
    if (resHigh.status) return resHigh;

    return showLowInterstitialAd(
      type: type,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      onAdDismissed: onAdDismissed,
    );
  }

  /// Shows only the high priority interstitial ad
  Advertresponse showHighInterstitialAd({
    String type = 'interstitial',
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
  }) {
    final manager = _interstitialManagers['${type}_high'];
    if (manager != null && manager.hasAds) {
      return manager.showAd(
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onAdDismissed,
      );
    }
    return Advertresponse.defaults();
  }

  /// Shows only the low priority interstitial ad
  Advertresponse showLowInterstitialAd({
    String type = 'interstitial',
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
  }) {
    final manager = _interstitialManagers['${type}_low'];
    if (manager != null && manager.hasAds) {
      return manager.showAd(
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onAdDismissed,
      );
    }
    return Advertresponse.defaults();
  }

  /// Shows a rewarded interstitial ad with fallback (High -> Low)
  Advertresponse showRewardedInterstitialAd({
    String type = 'rewardedInterstitial',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) {
    final resHigh = showHighRewardedInterstitialAd(
      type: type,
      onRewarded: onRewarded,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      customData: customData,
    );
    if (resHigh.status) return resHigh;

    return showLowRewardedInterstitialAd(
      type: type,
      onRewarded: onRewarded,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      customData: customData,
    );
  }

  /// Shows only the high priority rewarded interstitial ad
  Advertresponse showHighRewardedInterstitialAd({
    String type = 'rewardedInterstitial',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) {
    final manager = _rewardedInterstitialManagers['${type}_high'];
    if (manager != null && manager.hasAds) {
      return manager.showAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  /// Shows only the low priority rewarded interstitial ad
  Advertresponse showLowRewardedInterstitialAd({
    String type = 'rewardedInterstitial',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) {
    final manager = _rewardedInterstitialManagers['${type}_low'];
    if (manager != null && manager.hasAds) {
      return manager.showAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  /// Shows an app open ad with fallback (High -> Low)
  void showAppOpenAd({
    String type = 'appOpen',
    Function? onAdDismissed,
  }) {
    final managerHigh = _appOpenManagers['${type}_high'];
    if (managerHigh != null && managerHigh.hasAds) {
      managerHigh.showAd(onAdDismissed: onAdDismissed);
      return;
    }

    final managerLow = _appOpenManagers['${type}_low'];
    if (managerLow != null && managerLow.hasAds) {
      managerLow.showAd(onAdDismissed: onAdDismissed);
      return;
    }
  }

  /// Returns a banner ad widget with fallback (High -> Low)
  Widget showBannerAd({String type = 'banner'}) {
    final highBanner = showHighBannerAd(type: type);
    if (highBanner is! SizedBox) return highBanner;

    return showLowBannerAd(type: type);
  }

  /// Returns only the high priority banner ad widget
  Widget showHighBannerAd({String type = 'banner'}) {
    final manager = _bannerManagers['${type}_high'];
    if (manager != null && manager.bannerReady) {
      return manager.adWidget();
    }
    return const SizedBox.shrink();
  }

  /// Returns only the low priority banner ad widget
  Widget showLowBannerAd({String type = 'banner'}) {
    final manager = _bannerManagers['${type}_low'];
    if (manager != null && manager.bannerReady) {
      return manager.adWidget();
    }
    return const SizedBox.shrink();
  }

  void dispose() {
    for (var m in _interstitialManagers.values) {
      m.dispose();
    }
    for (var m in _rewardedManagers.values) {
      m.dispose();
    }
    for (var m in _nativeManagers.values) {
      m.dispose();
    }
    for (var m in _bannerManagers.values) {
      m.dispose();
    }
    for (var m in _rewardedInterstitialManagers.values) {
      m.dispose();
    }
    for (var m in _appOpenManagers.values) {
      m.dispose();
    }
  }
}
