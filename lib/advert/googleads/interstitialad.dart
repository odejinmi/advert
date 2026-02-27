import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';

class InterstitialAdManager extends GetxController {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 3;

  // Private variables
  final List<String> _adUnitIds;
  final RxList<InterstitialAd> _loadedAds = <InterstitialAd>[].obs;
  final RxInt _currentLoadingIndex = 0.obs;
  final RxInt _failedAttempts = 0.obs;
  final RxBool _isLoading = false.obs;

  // Constructor
  InterstitialAdManager(this._adUnitIds);

  // Getters
  bool get isLoading => _isLoading.value;
  bool get hasAds => _loadedAds.isNotEmpty;
  int get adsCount => _loadedAds.length;

  @override
  void onInit() {
    super.onInit();
    // Start preloading ads
    preloadAds();
  }

  @override
  void onClose() {
    // Dispose all ads when controller is closed
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    _loadedAds.clear();
    super.onClose();
  }

  /// Preloads ads up to the number of ad unit IDs available
  void preloadAds() {
    // If we're already loading or have loaded all ads, don't start again
    if (_isLoading.value || _currentLoadingIndex.value >= _adUnitIds.length) {
      return;
    }

    _loadNextAd();
  }

  /// Loads the next ad in the sequence
  void _loadNextAd() {
    if (_currentLoadingIndex.value >= _adUnitIds.length) {
      _isLoading.value = false;
      return;
    }

    _isLoading.value = true;
    final adUnitId = _adUnitIds[_currentLoadingIndex.value];

    debugPrint(
        'Loading interstitial ad ${_currentLoadingIndex.value + 1}/${_adUnitIds.length}');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: _onAdLoaded,
        onAdFailedToLoad: _onAdFailedToLoad,
      ),
    );
  }

  /// Callback when ad is successfully loaded
  void _onAdLoaded(InterstitialAd ad) {
    debugPrint('Interstitial ad loaded successfully');
    _loadedAds.add(ad);
    _failedAttempts.value = 0;
    _currentLoadingIndex.value++;
    _isLoading.value = false;

    // Continue loading the next ad if there are more ad units
    if (_currentLoadingIndex.value < _adUnitIds.length) {
      _loadNextAd();
    }
  }

  /// Callback when ad fails to load
  void _onAdFailedToLoad(LoadAdError error) {
    debugPrint('Interstitial ad failed to load: ${error.message}');
    _failedAttempts.value++;
    _isLoading.value = false;

    if (_failedAttempts.value < MAX_FAILED_LOAD_ATTEMPTS) {
      // Retry loading the same ad
      _loadNextAd();
    } else {
      // Move to next ad unit after max retries
      _failedAttempts.value = 0;
      _currentLoadingIndex.value++;

      if (_currentLoadingIndex.value < _adUnitIds.length) {
        _loadNextAd();
      }
    }
  }

  /// Shows an ad if available, returns the result
  Advertresponse showAd() {
    if (_loadedAds.isEmpty) {
      debugPrint('Warning: attempt to show interstitial ad before loaded.');
      preloadAds();
      return Advertresponse.defaults();
    }

    final ad = _loadedAds.removeAt(0);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        debugPrint('Interstitial ad showed full screen content');
        // Preload the next ad as soon as the current one is shown
        _loadReplacementAd();
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('Interstitial ad dismissed');
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('Interstitial ad failed to show: ${error.message}');
        ad.dispose();
        // Preload a replacement ad (since show failed, we still need one)
        _loadReplacementAd();
      },
    );

    ad.setImmersiveMode(true);
    ad.show();

    return Advertresponse.showing();
  }

  /// Loads a replacement ad after one is shown or fails
  void _loadReplacementAd() {
    // Reset index if we've gone through all ad units
    if (_currentLoadingIndex.value >= _adUnitIds.length) {
      _currentLoadingIndex.value = 0;
    }

    _loadNextAd();
  }
}
