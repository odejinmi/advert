import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';

class RewardedInterstitialAdManager extends GetxController {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 3;

  // Private variables
  final List<String> _adUnitIds;
  final RxList<RewardedInterstitialAd> _loadedAds =
      <RewardedInterstitialAd>[].obs;
  final RxInt _currentLoadingIndex = 0.obs;
  final RxInt _failedAttempts = 0.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _rewardEarned = false.obs;

  // Constructor
  RewardedInterstitialAdManager(this._adUnitIds);

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
  void _loadNextAd({Function? onComplete}) {
    if (_currentLoadingIndex.value >= _adUnitIds.length) {
      _isLoading.value = false;
      if (onComplete != null) onComplete();
      return;
    }

    _isLoading.value = true;
    final adUnitId = _adUnitIds[_currentLoadingIndex.value];

    // Check if an ad already exists for this ad unit ID
    if (_loadedAds.any((ad) => ad.adUnitId == adUnitId)) {
      debugPrint('Ad for adUnitId $adUnitId already exists');
      _isLoading.value = false;
      _currentLoadingIndex.value++;

      if (_currentLoadingIndex.value < _adUnitIds.length) {
        _loadNextAd(onComplete: onComplete);
      } else if (onComplete != null) {
        onComplete();
      }
      return;
    }

    debugPrint(
        'Loading rewarded interstitial ad ${_currentLoadingIndex.value + 1}/${_adUnitIds.length}');

    RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          debugPrint('Rewarded interstitial ad loaded successfully: $adUnitId');
          _loadedAds.add(ad);
          _failedAttempts.value = 0;
          _currentLoadingIndex.value++;
          _isLoading.value = false;

          // Continue loading the next ad if there are more ad units
          if (_currentLoadingIndex.value < _adUnitIds.length) {
            _loadNextAd(onComplete: onComplete);
          } else if (onComplete != null) {
            onComplete();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint(
              'Rewarded interstitial ad failed to load: ${error.message}');
          _failedAttempts.value++;
          _isLoading.value = false;

          if (_failedAttempts.value < MAX_FAILED_LOAD_ATTEMPTS) {
            // Retry loading the same ad
            _loadNextAd(onComplete: onComplete);
          } else {
            // Move to next ad unit after max retries
            _failedAttempts.value = 0;
            _currentLoadingIndex.value++;

            if (_currentLoadingIndex.value < _adUnitIds.length) {
              _loadNextAd(onComplete: onComplete);
            } else if (onComplete != null) {
              onComplete();
            }
          }
        },
      ),
    );
  }

  /// Shows a rewarded interstitial ad if available, returns the result
  Advertresponse showAd({
    Function? onRewarded,
    Map<String, String> customData = const {},
  }) {
    if (_loadedAds.isEmpty) {
      debugPrint(
          'Warning: attempt to show rewarded interstitial ad before loaded.');
      _loadNextAd(onComplete: () {
        if (_loadedAds.isNotEmpty) {
          showAd(onRewarded: onRewarded, customData: customData);
        }
      });
      return Advertresponse.defaults();
    }

    final ad = _loadedAds[0];
    _rewardEarned.value = false;

    // Set server-side verification options if custom data is provided
    if (customData.isNotEmpty) {
      final options = ServerSideVerificationOptions(
        customData: jsonEncode(customData),
      );
      ad.setServerSideOptions(options);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded interstitial ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded interstitial ad dismissed');
        _disposeCurrentAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded interstitial ad failed to show: ${error.message}');
        _disposeCurrentAd();

        // Try to show another ad after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (_loadedAds.isNotEmpty) {
            showAd(onRewarded: onRewarded, customData: customData);
          }
        });
      },
      onAdClicked: (ad) {
        debugPrint('Rewarded interstitial ad clicked');
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        _rewardEarned.value = true;
        if (onRewarded != null) {
          onRewarded();
        }
      },
    );

    return Advertresponse.showing();
  }

  /// Disposes the current ad and loads a replacement
  void _disposeCurrentAd() {
    if (_loadedAds.isNotEmpty) {
      final ad = _loadedAds.removeAt(0);
      ad.dispose();

      // Decrement the index to allow reloading this slot
      if (_currentLoadingIndex.value > 0) {
        _currentLoadingIndex.value--;
      }

      // Load a replacement ad
      _loadNextAd();
    }
  }
}
