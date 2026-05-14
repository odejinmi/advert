import 'dart:io';

import 'package:advert/advert/googleads/freemoney.dart';
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
import 'googleads/spinandwin.dart';

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
  int _rewardShowPosition = 1;
  int _spinAndWinShowPosition = 1;
  int _freemoneyShowPosition = 1;
  int _retryAttempts = 0;
  int _spinAndWinretryAttempts = 0;
  int _freemoneyretryAttempts = 0;

  // Ad managers
  late final InterstitialAdManager _interstitialAdManager;
  late final RewardedAdManager _rewardedAdManager;
  late final SpinAndWin _spinAndWin;
  late final Freemoney _freemoney;
  late final NativeAdManager _nativeAdManager;
  late final BannerAdManager _bannerAdManager;
  late final RewardedInterstitialAdManager _rewardedInterstitialAdManager;

  // Constructor
  GoogleAdProvider(this._adConfig, this._reporter) {
    MobileAds.instance.initialize();
    _initializeAdManagers();
  }

  /// Initializes all ad managers
  void _initializeAdManagers() {
    _interstitialAdManager =
        InterstitialAdManager(_adConfig.interstitialAdUnitId, _reporter);

    _rewardedAdManager =
        RewardedAdManager(_adConfig.rewardedAdUnitId, _reporter);

    _nativeAdManager =
        NativeAdManager(_adConfig.nativeAdUnitId, _reporter);

    _bannerAdManager =
        BannerAdManager(_adConfig.bannerAdUnitId, _reporter);

    _spinAndWin =
        SpinAndWin(_adConfig.spinAndWin, _reporter);

    _freemoney =
        Freemoney(_adConfig.freemoney, _reporter);

    _rewardedInterstitialAdManager = 
        RewardedInterstitialAdManager(_adConfig.rewardedInterstitialAdUnitId, _reporter);
  }

  // Getters
  bool get hasInterstitialAd => _interstitialAdManager.hasAds;
  bool get hasRewardedAd => _rewardedAdManager.hasAds;
  bool get hasspinAndWin => _spinAndWin.hasAds;
  bool get hasfreemoney => _freemoney.hasAds;
  bool get hasRewardedInterstitialAd => _rewardedInterstitialAdManager.hasAds;
  int get adProviderCount => 2; 

  /// Preloads all ad types
  void preloadAllAds() {
    loadInterstitialAd();
    loadRewardedAd();
    loadNativeAd();
    loadspinAndWin();
    loadfreemoney();
    loadRewardedInterstitialAd();
  }

  /// Loads a native ad
  void loadNativeAd() {
    _nativeAdManager.loadAd();
  }

  /// Loads an interstitial ad
  void loadInterstitialAd() {
    _interstitialAdManager.preloadAds();
  }

  /// Loads a rewarded ad
  void loadRewardedAd() {
    _rewardedAdManager.preloadAds();
  }

  /// Loads a spinAndWin ad
  void loadspinAndWin() {
    _spinAndWin.preloadAds();
  }

  /// Loads a spinAndWin ad
  void loadfreemoney() {
    _freemoney.preloadAds();
  }

  /// Loads a rewarded interstitial ad
  void loadRewardedInterstitialAd() {
    _rewardedInterstitialAdManager.preloadAds();
  }

  /// Loads all rewarded ad types
  void loadRewardAds() {
    loadRewardedAd();
    loadRewardedInterstitialAd();
    loadfreemoney();
    loadspinAndWin();
  }

  /// Shows a native ad
  Widget showNativeAd(BuildContext context) {
    return _nativeAdManager.buildAdWidget(context, autoClose: false);
  }

  /// Shows an interstitial ad
  Advertresponse showInterstitialAd() {
    return _interstitialAdManager.showAd();
  }

  /// Shows a rewarded ad with reward callback
  Advertresponse showRewardedAd({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    return _rewardedAdManager.showRewardedAd(
      onRewarded: onRewarded,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      customData: customData,
    );
  }

  /// Shows a rewarded ad with reward callback
  Advertresponse showmergeRewardedAd({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    // Reset retry counter if we're switching ad types
    if (_rewardShowPosition != 1) {
      _retryAttempts = 0;
    }

    // Try to show rewarded ad if available
    if (_rewardedAdManager.hasAds && _rewardShowPosition == 1) {
      debugPrint(
          'Showing rewarded ad (${_rewardedAdManager.adsCount} available)');
      _rewardShowPosition = 2; // Move to next ad type for next attempt
      _retryAttempts = 0;
      return _rewardedAdManager.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    // Try rewarded interstitial as fallback
    else if (_rewardedInterstitialAdManager.hasAds &&
        _rewardShowPosition == 2) {
      debugPrint(
          'Showing rewarded interstitial ad (${_rewardedInterstitialAdManager.adsCount} available)');
      _rewardShowPosition = 1; // Reset to first ad type for next attempt
      _retryAttempts = 0;
      return _rewardedInterstitialAdManager.showAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    // Handle case when no ads are available
    else {
      // Cycle through ad providers
      _rewardShowPosition =
          _rewardShowPosition % adProviderCount + 1;

      // Retry with limited attempts
      if (_retryAttempts < MAX_RETRY_ATTEMPTS) {
        _retryAttempts += 1;
        return showmergeRewardedAd(
          onRewarded: onRewarded,
          onAdClicked: onAdClicked,
          onAdImpression: onAdImpression,
          customData: customData,
        );
      } else {
        _retryAttempts = 0;
        return Advertresponse.defaults();
      }
    }
  }

  Advertresponse showspinAndWin({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    // Reset retry counter if we're switching ad types
    if (_spinAndWinShowPosition != 1) {
      _spinAndWinretryAttempts = 0;
    }

    // Try to show rewarded ad if available
    if (_spinAndWin.hasAds && _spinAndWinShowPosition == 1) {
      debugPrint('Showing rewarded ad (${_spinAndWin.adsCount} available)');
      _spinAndWinShowPosition =
          2; // Move to next ad type for next attempt
      _spinAndWinretryAttempts = 0;
      return _spinAndWin.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    // Handle case when no ads are available
    else {
      // Cycle through ad providers
      _spinAndWinShowPosition =
          _spinAndWinShowPosition % adProviderCount + 1;

      // Retry with limited attempts
      if (_spinAndWinretryAttempts < MAX_RETRY_ATTEMPTS) {
        _spinAndWinretryAttempts += 1;
        return showspinAndWin(
          onRewarded: onRewarded,
          onAdClicked: onAdClicked,
          onAdImpression: onAdImpression,
          customData: customData,
        );
      } else {
        _spinAndWinretryAttempts = 0;
        return Advertresponse.defaults();
      }
    }
  }

  Advertresponse showfreemoney({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    // Reset retry counter if we're switching ad types
    if (_freemoneyShowPosition != 1) {
      _freemoneyretryAttempts = 0;
    }

    // Try to show rewarded ad if available
    if (_freemoney.hasAds && _freemoneyShowPosition == 1) {
      debugPrint('Showing rewarded ad (${_freemoney.adsCount} available)');
      _freemoneyShowPosition =
          2; // Move to next ad type for next attempt
      _freemoneyretryAttempts = 0;
      return _freemoney.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    // Handle case when no ads are available
    else {
      debugPrint(
          'No fremoney ads new available, retrying (attempt ${_freemoneyretryAttempts + 1}/${MAX_RETRY_ATTEMPTS})');

      // Cycle through ad providers
      _freemoneyShowPosition =
          _freemoneyShowPosition % adProviderCount + 1;

      // Retry with limited attempts
      if (_freemoneyretryAttempts < MAX_RETRY_ATTEMPTS) {
        _freemoneyretryAttempts++;
        return showfreemoney(
          onRewarded: onRewarded,
          onAdClicked: onAdClicked,
          onAdImpression: onAdImpression,
          customData: customData,
        );
      } else {
        _freemoneyretryAttempts = 0;
        return Advertresponse.defaults();
      }
    }
  }

  /// Shows a rewarded interstitial ad with reward callback
  Advertresponse showRewardedInterstitialAd({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    return _rewardedInterstitialAdManager.showAd(
      onRewarded: onRewarded,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      customData: customData,
    );
  }

  /// Returns a banner ad widget
  Widget showBannerAd() {
    return _bannerAdManager.adWidget();
  }

  void dispose() {
    _interstitialAdManager.dispose();
    _rewardedAdManager.dispose();
    _spinAndWin.dispose();
    _freemoney.dispose();
    _nativeAdManager.dispose();
    _bannerAdManager.dispose();
    _rewardedInterstitialAdManager.dispose();
  }
}
