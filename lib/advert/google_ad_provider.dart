import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/advertresponse.dart';
import '../model/google.dart';
import 'googleads/bannerad.dart';
import 'googleads/interstitialad.dart';
import 'googleads/nativead.dart';
import 'googleads/rewardedad.dart';
import 'googleads/rewardedinterstitialad.dart';

class GoogleAdProvider extends GetxController {
  // Constants
  static const int maxRetryAttempts = 3;

  // Platform-specific app IDs
  static String get appId => Platform.isAndroid
      ? 'ca-app-pub-6117361441866120~5829948546'
      : 'ca-app-pub-6117361441866120~7211527566';

  // Private variables
  final Googlemodel _adConfig;
  final RxInt _rewardShowPosition = 1.obs;
  final RxInt _retryAttempts = 0.obs;

  // Ad managers
  late final InterstitialAdManager _interstitialAdManager;
  late final RewardedAdManager _rewardedAdManager;
  late final NativeAdManager _nativeAdManager;
  late final BannerAdManager _bannerAdManager;
  late final RewardedInterstitialAdManager _rewardedInterstitialAdManager;

  // Constructor
  GoogleAdProvider(this._adConfig);

  // Getters
  bool get hasInterstitialAd => _interstitialAdManager.hasAds;
  bool get hasRewardedAd => _rewardedAdManager.hasAds;
  bool get hasRewardedInterstitialAd => _rewardedInterstitialAdManager.hasAds;
  int get adProviderCount =>
      2; // Number of ad providers (rewarded and rewarded interstitial)

  @override
  void onInit() {
    super.onInit();
    _initializeAdManagers();
  }

  /// Initializes all ad managers
  void _initializeAdManagers() {
    _interstitialAdManager =
        Get.put(InterstitialAdManager(_adConfig.interstitialAdUnitId), permanent: true);

    _rewardedAdManager =
        Get.put(RewardedAdManager(_adConfig.rewardedAdUnitId), permanent: true);

    _nativeAdManager =
        Get.put(NativeAdManager(_adConfig.nativeAdUnitId), permanent: true);

    _bannerAdManager =
        Get.put(BannerAdManager(_adConfig.bannerAdUnitId), permanent: true);

    _rewardedInterstitialAdManager = Get.put(
        RewardedInterstitialAdManager(_adConfig.rewardedInterstitialAdUnitId),
        permanent: true);
  }

  /// Preloads all ad types
  void preloadAllAds() {
    loadInterstitialAd();
    loadRewardedAd();
    loadNativeAd();
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

  /// Loads a rewarded interstitial ad
  void loadRewardedInterstitialAd() {
    _rewardedInterstitialAdManager.preloadAds();
  }

  /// Loads all rewarded ad types
  void loadRewardAds() {
    loadRewardedAd();
    loadRewardedInterstitialAd();
  }

  /// Shows a native ad
  Widget showNativeAd() {
    return _nativeAdManager.buildAdWidget();
  }

  /// Shows an interstitial ad
  Advertresponse showInterstitialAd() {
    return _interstitialAdManager.showAd();
  }

  /// Shows a rewarded ad with reward callback
  Advertresponse showRewardedAd(
      Function? onRewarded, Map<String, String> customData) {
    // Reset retry counter if we're switching ad types
    if (_rewardShowPosition.value != 1) {
      _retryAttempts.value = 0;
    }

    // Try to show rewarded ad if available
    if (_rewardedAdManager.hasAds && _rewardShowPosition.value == 1) {
      debugPrint(
          'Showing rewarded ad (${_rewardedAdManager.adsCount} available)');
      _rewardShowPosition.value = 2; // Move to next ad type for next attempt
      _retryAttempts.value = 0;
      return _rewardedAdManager.showRewardedAd(
        onRewarded: onRewarded,
        customData: customData,
      );
    }
    // Try rewarded interstitial as fallback
    else if (_rewardedInterstitialAdManager.hasAds &&
        _rewardShowPosition.value == 2) {
      debugPrint(
          'Showing rewarded interstitial ad (${_rewardedInterstitialAdManager.adsCount} available)');
      _rewardShowPosition.value = 1; // Reset to first ad type for next attempt
      _retryAttempts.value = 0;
      return _rewardedInterstitialAdManager.showAd(
        onRewarded: onRewarded,
        customData: customData,
      );
    }
    // Handle case when no ads are available
    else {
      debugPrint(
          'No rewarded ads available, retrying (attempt ${_retryAttempts.value + 1}/$maxRetryAttempts)');

      // Cycle through ad providers
      _rewardShowPosition.value =
          _rewardShowPosition.value % adProviderCount + 1;

      // Retry with limited attempts
      if (_retryAttempts.value < maxRetryAttempts) {
        _retryAttempts.value++;
        return showRewardedAd(onRewarded, customData);
      } else {
        _retryAttempts.value = 0;
        return Advertresponse.defaults();
      }
    }
  }

  /// Shows a rewarded interstitial ad with reward callback
  Advertresponse showRewardedInterstitialAd(
      Function? onRewarded, Map<String, String> customData) {
    if (_rewardedInterstitialAdManager.hasAds) {
      return _rewardedInterstitialAdManager.showAd(
        onRewarded: onRewarded,
        customData: customData,
      );
    } else {
      // Fall back to regular rewarded ad if rewarded interstitial is not available
      return showRewardedAd(onRewarded, customData);
    }
  }

  /// Returns a banner ad widget
  Widget showBannerAd() {
    return _bannerAdManager.adWidget();
  }

  @override
  void onClose() {
    // No need to manually dispose ad managers as they're handled by GetX
    super.onClose();
  }
}
