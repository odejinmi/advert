import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/adsmodel.dart';
import '../model/advertresponse.dart';
import 'adcolonyProvider.dart';
import 'googleProvider.dart';
import 'googleads/banner_admob.dart';
import 'googleads/bannerlist.dart';
import 'unityprovider.dart';

class AdManager extends GetxController {
  // Constants
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const Duration DEFAULT_RETRY_DELAY = Duration(seconds: 1);

  // Configuration
  final Adsmodel _adsConfig;

  // Ad providers
  UnityProvider? _unityProvider;
  GoogleAdProvider? _googleProvider;
  final AdcolonyProvider _adcolonyProvider =
      Get.put(AdcolonyProvider(), permanent: true);

  // State variables
  final RxInt _interstitialProviderIndex = 1.obs;
  final RxInt _rewardedProviderIndex = 1.obs;
  final RxInt _interstitialRetryAttempts = 0.obs;
  final RxInt _rewardedRetryAttempts = 0.obs;
  final RxInt _bannerProviderIndex = 1.obs;

  // Constructor
  AdManager(this._adsConfig);

  // Getters
  int get providerCount => _getAvailableProviderCount();
  bool get isRewardedAdReady => _isAnyRewardedAdReady();

  @override
  void onInit() {
    super.onInit();
    _initializeAdProviders();
    _startBannerRotation();
  }

  /// Initializes all available ad providers
  void _initializeAdProviders() {
    // Initialize Google provider if config exists
    if (_adsConfig.googlemodel != null) {
      _googleProvider =
          Get.put(GoogleAdProvider(_adsConfig.googlemodel!), permanent: true);
    }

    // Initialize Unity provider if config exists
    if (_adsConfig.unitymodel != null) {
      _unityProvider =
          Get.put(UnityProvider(_adsConfig.unitymodel!), permanent: true);
    }
  }

  /// Returns the number of available ad providers
  int _getAvailableProviderCount() {
    int count = 0;
    if (_unityProvider != null) count++;
    if (_googleProvider != null) count++;
    if (_adcolonyProvider != null) count++;
    return count > 0 ? count : 1; // At least 1 to avoid division by zero
  }

  /// Checks if any rewarded ad is ready
  bool _isAnyRewardedAdReady() {
    return (_unityProvider?.unityrewardedAd == true) ||
        (_googleProvider?.hasRewardedAd == true);
  }

  /// Preloads all ad types across all providers
  void preloadAllAds() {
    _preloadInterstitialAds();
    _preloadRewardedAds();
  }

  /// Preloads interstitial ads from all providers
  void _preloadInterstitialAds() {
    if (_unityProvider != null) _unityProvider!.loadinterrtitialad();
    if (_googleProvider != null) _googleProvider!.loadInterstitialAd();
  }

  /// Preloads rewarded ads from all providers
  void _preloadRewardedAds() {
    if (_unityProvider != null) _unityProvider!.loadrewardedad();
    if (_googleProvider != null) _googleProvider!.loadRewardAds();
  }

  /// Shows an interstitial ad, cycling through available providers
  Future<Advertresponse> showInterstitialAd() async {
    // Ensure ads are preloaded
    _preloadInterstitialAds();

    // Try Unity provider
    if (_unityProvider != null &&
        _unityProvider!.unityintersAd1 &&
        _interstitialProviderIndex.value == 1) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts.value = 0;
      return _unityProvider!.showAd1();
    }

    // Try Google provider
    else if (_googleProvider != null &&
        _googleProvider!.hasInterstitialAd &&
        _interstitialProviderIndex.value == 2) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts.value = 0;
      return _googleProvider!.showInterstitialAd();
    }

    // Try AdColony provider (if implemented)
    // else if (_adcolonyProvider.isloaded() && _interstitialProviderIndex.value == 3) {
    //   _advanceInterstitialProvider();
    //   _interstitialRetryAttempts.value = 0;
    //   return _adcolonyProvider.show(null);
    // }

    // No ad available, try next provider
    else {
      return await _handleInterstitialRetry();
    }
  }

  /// Handles retry logic for interstitial ads
  Future<Advertresponse> _handleInterstitialRetry() async {
    if (_interstitialRetryAttempts.value < MAX_RETRY_ATTEMPTS) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts.value++;
      debugPrint(
          'Retrying interstitial ad with provider ${_interstitialProviderIndex.value} (attempt ${_interstitialRetryAttempts.value}/$MAX_RETRY_ATTEMPTS)');
      await Future.delayed(DEFAULT_RETRY_DELAY);
      return showInterstitialAd();
    } else {
      _interstitialRetryAttempts.value = 0;
      return Advertresponse.defaults();
    }
  }

  /// Advances to the next interstitial ad provider
  void _advanceInterstitialProvider() {
    _interstitialProviderIndex.value =
        _interstitialProviderIndex.value % providerCount + 1;
  }

  /// Shows a rewarded ad, cycling through available providers
  Future<Advertresponse> showRewardedAd(
      Function? onRewarded, Map<String, String> customData,
      [int retryDelaySeconds = 1]) async {
    // Ensure ads are preloaded
    _preloadRewardedAds();

    // Try Unity provider
    if (_unityProvider != null &&
        _unityProvider!.unityrewardedAd &&
        _rewardedProviderIndex.value == 1) {
      _advanceRewardedProvider();
      _rewardedRetryAttempts.value = 0;
      return _unityProvider!.showRewardedAd(onRewarded);
    }

    // Try Google provider
    else if (_googleProvider != null &&
        _googleProvider!.hasRewardedAd &&
        _rewardedProviderIndex.value == 2) {
      _advanceRewardedProvider();
      _rewardedRetryAttempts.value = 0;
      return _googleProvider!.showRewardedAd(onRewarded, customData);
    }

    // Try AdColony provider (if implemented)
    // else if (_adcolonyProvider.isloaded() && _rewardedProviderIndex.value == 3) {
    //   _advanceRewardedProvider();
    //   _rewardedRetryAttempts.value = 0;
    //   return _adcolonyProvider.show(onRewarded);
    // }

    // No ad available, try next provider or check if any provider has an ad
    else {
      return await _handleRewardedRetry(
          onRewarded, customData, retryDelaySeconds);
    }
  }

  /// Shows a rewarded ad, cycling through available providers
  Future<Advertresponse> showspinAndWin(
      Function? onRewarded, Map<String, String> customData,
      [int retryDelaySeconds = 1]) async {
    // Ensure ads are preloaded
    _preloadRewardedAds();

    // Try Google provider
    if (_googleProvider != null &&
        _googleProvider!.hasspinAndWin &&
        _rewardedProviderIndex.value == 2) {
      _advanceRewardedProvider();
      _rewardedRetryAttempts.value = 0;
      return _googleProvider!.showspinAndWin(onRewarded, customData);
    }

    // Try AdColony provider (if implemented)
    // else if (_adcolonyProvider.isloaded() && _rewardedProviderIndex.value == 3) {
    //   _advanceRewardedProvider();
    //   _rewardedRetryAttempts.value = 0;
    //   return _adcolonyProvider.show(onRewarded);
    // }

    // No ad available, try next provider or check if any provider has an ad
    else {
      return await _handleRewardedRetry(
          onRewarded, customData, retryDelaySeconds);
    }
  }

  /// Handles retry logic for rewarded ads with smart fallback
  Future<Advertresponse> _handleRewardedRetry(Function? onRewarded,
      Map<String, String> customData, int retryDelaySeconds) async {
    // Check if any provider has an ad ready regardless of rotation order
    if (_unityProvider?.unityrewardedAd == true) {
      _rewardedRetryAttempts.value = 0;
      return _unityProvider!.showRewardedAd(onRewarded);
    }

    if (_googleProvider?.hasRewardedAd == true) {
      _rewardedRetryAttempts.value = 0;
      return _googleProvider!.showRewardedAd(onRewarded, customData);
    }

    // No ads available, try standard rotation retry
    if (_rewardedRetryAttempts.value < MAX_RETRY_ATTEMPTS) {
      _advanceRewardedProvider();
      _rewardedRetryAttempts.value++;
      debugPrint(
          'Retrying rewarded ad with provider ${_rewardedProviderIndex.value} (attempt ${_rewardedRetryAttempts.value}/$MAX_RETRY_ATTEMPTS)');
      await Future.delayed(Duration(seconds: retryDelaySeconds));
      return showRewardedAd(onRewarded, customData, retryDelaySeconds);
    } else {
      _rewardedRetryAttempts.value = 0;
      return Advertresponse.defaults();
    }
  }

  /// Advances to the next rewarded ad provider
  void _advanceRewardedProvider() {
    _rewardedProviderIndex.value =
        _rewardedProviderIndex.value % providerCount + 1;
  }

  /// Shows a rewarded interstitial ad
  Future<Advertresponse> showRewardedInterstitialAd(
      Function? onRewarded, Map<String, String> customData,
      [int retryDelaySeconds = 1]) async {
    // Ensure ads are preloaded
    _preloadRewardedAds();

    // Try Unity provider
    if (_unityProvider != null &&
        _unityProvider!.unityrewardedAd &&
        _rewardedProviderIndex.value == 1) {
      _advanceRewardedProvider();
      _rewardedRetryAttempts.value = 0;
      return _unityProvider!.showRewardedAd(onRewarded);
    }

    // Try Google rewarded interstitial provider
    else if (_googleProvider != null &&
        _googleProvider!.hasRewardedInterstitialAd &&
        _rewardedProviderIndex.value == 2) {
      _advanceRewardedProvider();
      _rewardedRetryAttempts.value = 0;
      return _googleProvider!
          .showRewardedInterstitialAd(onRewarded, customData);
    }

    // No ad available, try next provider or check if any provider has an ad
    else {
      return await _handleRewardedRetry(
          onRewarded, customData, retryDelaySeconds);
    }
  }

  /// Shows a native ad
  Widget showNativeAd() {
    if (_googleProvider != null) {
      _googleProvider!.loadNativeAd();
      return _googleProvider!.showNativeAd();
    }
    return Container();
  }

  /// Returns a banner ad widget
  Widget showBannerAd() {
    if (_googleProvider != null && _adsConfig.googlemodel != null) {
      return BannerAdWidget(
        adUnitIds: _adsConfig.googlemodel!.bannerAdUnitId,
      );
    }
    return const SizedBox.shrink();
  }

  /// Returns a scrolling banner list widget
  Widget showBannerListAd(int numberOfAds) {
    if (_googleProvider != null && _adsConfig.googlemodel != null) {
      return BannerListWidget(
        adUnitIds: _adsConfig.googlemodel!.bannerAdUnitId,
        numberOfAdsToShow: numberOfAds,
      );
    }
    return const SizedBox.shrink();
  }

  /// Starts the banner rotation timer
  void _startBannerRotation() {
    Future.delayed(const Duration(seconds: 30), () {
      _rotateBannerProvider();
      _startBannerRotation();
    });
  }

  /// Rotates to the next banner provider
  void _rotateBannerProvider() {
    _bannerProviderIndex.value = _bannerProviderIndex.value % providerCount + 1;
    update(); // Notify listeners to rebuild
  }
}
