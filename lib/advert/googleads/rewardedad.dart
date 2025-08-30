import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';

class RewardedAdManager extends GetxController {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 3;
  static const Duration AD_EXPIRATION = Duration(hours: 1);

  // Private variables
  final List<String> _adUnitIds;
  final RxList<Map<String, dynamic>> _loadedAds = <Map<String, dynamic>>[].obs;
  final RxInt _currentLoadingIndex = 0.obs;
  final RxInt _failedAttempts = 0.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _rewardEarned = false.obs;

  // Constructor
  RewardedAdManager(this._adUnitIds);

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
    for (final adData in _loadedAds) {
      (adData['advert'] as RewardedAd).dispose();
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

    // Check if an ad already exists for this ad unit ID
    if (_loadedAds
        .any((ad) => (ad['advert'] as RewardedAd).adUnitId == adUnitId)) {
      debugPrint('Ad for adUnitId $adUnitId already exists');
      _isLoading.value = false;
      _currentLoadingIndex.value++;

      if (_currentLoadingIndex.value < _adUnitIds.length) {
        _loadNextAd();
      }
      return;
    }

    debugPrint(
        'Loading rewarded ad ${_currentLoadingIndex.value + 1}/${_adUnitIds.length}');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('Rewarded ad loaded successfully: $adUnitId');
          _loadedAds.add({
            'advert': ad,
            'time': DateTime.now(),
          });
          _failedAttempts.value = 0;
          _currentLoadingIndex.value++;
          _isLoading.value = false;

          // Continue loading the next ad if there are more ad units
          if (_currentLoadingIndex.value < _adUnitIds.length) {
            _loadNextAd();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
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
        },
      ),
    );
  }

  /// Shows a rewarded ad if available, returns the result
  Advertresponse showRewardedAd({
    Function? onRewarded,
    Map<String, String> customData = const {},
  }) {
    if (_loadedAds.isEmpty) {
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      preloadAds();
      return Advertresponse.defaults();
    }

    // Check if the ad is expired
    final adData = _loadedAds[0];
    final adTime = adData['time'] as DateTime;
    if (_isAdExpired(adTime)) {
      debugPrint('Ad expired, disposing and loading a new one');
      _disposeAd(adData['advert']);
      return showRewardedAd(onRewarded: onRewarded, customData: customData);
    }

    final ad = adData['advert'] as RewardedAd;
    _rewardEarned.value = false;

    // Set server-side verification options if custom data is provided
    if (customData.isNotEmpty) {
      final options = ServerSideVerificationOptions(
        customData: jsonEncode(customData),
      );
      ad.setServerSideOptions(options);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        debugPrint('Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('Rewarded ad dismissed');
        if (onRewarded != null && _rewardEarned.value) {
          onRewarded();
        }
        _disposeAd(ad);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('Rewarded ad failed to show: ${error.message}');
        _disposeAd(ad);

        // Try to show another ad after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (_loadedAds.isNotEmpty) {
            showRewardedAd(onRewarded: onRewarded, customData: customData);
          }
        });
      },
    );

    ad.setImmersiveMode(true);
    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        _rewardEarned.value = true;
      },
    );

    return Advertresponse.showing();
  }

  /// Disposes an ad and loads a replacement
  void _disposeAd(RewardedAd ad) {
    _loadedAds.removeWhere((adData) => adData['advert'] == ad);
    ad.dispose();

    // Load a replacement ad
    _loadReplacementAd();
  }

  /// Loads a replacement ad after one is shown or disposed
  void _loadReplacementAd() {
    // Reset index if we've gone through all ad units
    if (_currentLoadingIndex.value >= _adUnitIds.length) {
      _currentLoadingIndex.value = 0;
    }

    _loadNextAd();
  }

  /// Checks if an ad is expired (older than AD_EXPIRATION)
  bool _isAdExpired(DateTime adTime) {
    final currentTime = DateTime.now();
    final difference = currentTime.difference(adTime);
    return difference > AD_EXPIRATION;
  }
}
