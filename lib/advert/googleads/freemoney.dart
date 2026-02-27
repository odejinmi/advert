import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';


class _LoadedAd {
  final RewardedAd ad;
  final DateTime loadTime;

  _LoadedAd({required this.ad, required this.loadTime});
}


class Freemoney extends GetxController {

  Freemoney(this._adUnitIds);

  // Constants
  static const int maxFailedLoadAttempts = 3;
  static const Duration adExpiration = Duration(hours: 1);

  // Private variables
  final List<String> _adUnitIds;
  final RxList<_LoadedAd> _loadedAds = <_LoadedAd>[].obs;
  final RxInt _currentLoadingIndex = 0.obs;
  final RxInt _failedAttempts = 0.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _rewardEarned = false.obs;
  // Getters
  bool get isLoading => _isLoading.value;
  bool get hasAds => _loadedAds.isNotEmpty;
  int get adsCount => _loadedAds.length;

  @override
  void onInit() {
    super.onInit();
    preloadAds();
  }

  @override
  void onClose() {
    for (final adData in _loadedAds) {
      adData.ad.dispose();
    }
    _loadedAds.clear();
    super.onClose();
  }

  void preloadAds() {
    if (_isLoading.value || _currentLoadingIndex.value >= _adUnitIds.length) {
      return;
    }
    _loadNextAd();
  }

  void _loadNextAd() {
    if (_currentLoadingIndex.value >= _adUnitIds.length) {
      _isLoading.value = false;
      return;
    }

    _isLoading.value = true;
    final adUnitId = _adUnitIds[_currentLoadingIndex.value];

    if (_loadedAds.any((adData) => adData.ad.adUnitId == adUnitId)) {
      _handleAdAlreadyExists(adUnitId);
      return;
    }

    debugPrint(
        'Loading freemoney ad ${_currentLoadingIndex.value + 1}/${_adUnitIds.length}');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: _onAdLoaded,
        onAdFailedToLoad: _onAdFailedToLoad,
      ),
    );
  }

  void _onAdLoaded(RewardedAd ad) {
    debugPrint('Freemoney ad loaded successfully: ${ad.adUnitId}');
    _loadedAds.add(_LoadedAd(ad: ad, loadTime: DateTime.now()));
    _failedAttempts.value = 0;
    _currentLoadingIndex.value++;
    _isLoading.value = false;

    if (_currentLoadingIndex.value < _adUnitIds.length) {
      _loadNextAd();
    }
  }

  void _onAdFailedToLoad(LoadAdError error) {
    debugPrint('Freemoney ad failed to load: ${error.message}');
    _failedAttempts.value++;
    _isLoading.value = false;

    if (_failedAttempts.value < maxFailedLoadAttempts) {
      _loadNextAd();
    } else {
      _failedAttempts.value = 0;
      _currentLoadingIndex.value++;
      if (_currentLoadingIndex.value < _adUnitIds.length) {
        _loadNextAd();
      }
    }
  }

  void _handleAdAlreadyExists(String adUnitId) {
    debugPrint('Ad for adUnitId $adUnitId already exists');
    _isLoading.value = false;
    _currentLoadingIndex.value++;

    if (_currentLoadingIndex.value < _adUnitIds.length) {
      _loadNextAd();
    }
  }

  Advertresponse showRewardedAd({
    Function? onRewarded,
    Map<String, String> customData = const {},
  }) {
    if (_loadedAds.isEmpty) {
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      preloadAds();
      return Advertresponse.defaults();
    }

    final adData = _loadedAds[0];
    if (_isAdExpired(adData.loadTime)) {
      debugPrint('Ad expired, disposing and loading a new one');
      _disposeAd(adData.ad);
      if (_loadedAds.isNotEmpty) {
        return showRewardedAd(onRewarded: onRewarded, customData: customData);
      } else {
        preloadAds(); // Preload if no ads are available
        return Advertresponse.defaults();
      }
    }

    _configureAndShowAd(adData, onRewarded, customData);
    return Advertresponse.showing();
  }

  void _configureAndShowAd(
      _LoadedAd adData, Function? onRewarded, Map<String, String> customData) {
    final ad = adData.ad;
    _rewardEarned.value = false;

    if (customData.isNotEmpty) {
      final options = ServerSideVerificationOptions(
        customData: jsonEncode(customData),
      );
      ad.setServerSideOptions(options);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
          debugPrint('Freemoney ad showed full screen content ${ad.adUnitId}');
          // Preload the next ad as soon as the current one is shown
          _loadedAds.removeWhere((adData) => adData.ad == ad);
          _loadReplacementAd();
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('Freemoney ad dismissed');
        if (onRewarded != null && _rewardEarned.value) {
          onRewarded();
        }
        _disposeAd(ad);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('Freemoney ad failed to show: ${error.message}');
        _loadedAds.removeWhere((adData) => adData.ad == ad);
        _disposeAd(ad);
        // Attempt to show the next ad if available
        if (_loadedAds.isNotEmpty) {
          showRewardedAd(onRewarded: onRewarded, customData: customData);
        }
      },
    );

    ad.setImmersiveMode(true);
    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        _rewardEarned.value = true;
      },
    );
  }

  void _disposeAd(RewardedAd ad) {
    ad.dispose();
    // Removed _loadReplacementAd() from here as we now call it in onAdShowedFullScreenContent
  }

  void _loadReplacementAd() {
    if (_currentLoadingIndex.value >= _adUnitIds.length) {
      _currentLoadingIndex.value = 0;
    }
    _loadNextAd();
  }

  bool _isAdExpired(DateTime adTime) {
    return DateTime.now().difference(adTime) > adExpiration;
  }
}