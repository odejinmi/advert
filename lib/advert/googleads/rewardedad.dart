import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class _LoadedAd {
  final RewardedAd ad;
  final DateTime loadTime;

  _LoadedAd({required this.ad, required this.loadTime});
}

class RewardedAdManager extends GetxController {
  // Constants
  static const int maxFailedLoadAttempts = 3;
  static const Duration adExpiration = Duration(hours: 1);
  static const int TARGET_BUFFER_SIZE = 3;

  final EventReporter _reporter = Get.find();

  // Private variables
  final List<String> _adUnitIds;
  final RxList<_LoadedAd> _loadedAds = <_LoadedAd>[].obs;
  final RxInt _currentLoadingIndex = 0.obs;
  final RxInt _failedAttempts = 0.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _rewardEarned = false.obs;
  final RxBool _isShowing = false.obs;
  final RxInt _pendingShowRequests = 0.obs;

  // Constructor
  RewardedAdManager(this._adUnitIds);

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
    _topUpBuffer();
  }

  void _loadNextAd({Function? onComplete}) {
    if (_currentLoadingIndex.value >= _adUnitIds.length) {
      _currentLoadingIndex.value = 0;
      if (onComplete != null) onComplete();
      return;
    }

    if (_isLoading.value) return;
    _isLoading.value = true;
    final adUnitId = _adUnitIds[_currentLoadingIndex.value];

    // Allow duplicates per ad unit when building buffer
    // Only skip if buffer is already satisfied and we already have one for this ad unit
    if (_loadedAds.length >= TARGET_BUFFER_SIZE &&
        _loadedAds.any((adData) => adData.ad.adUnitId == adUnitId)) {
      _handleAdAlreadyExists(adUnitId);
      if (onComplete != null) onComplete();
      return;
    }

    debugPrint(
        'Loading rewarded ad ${_currentLoadingIndex.value + 1}/${_adUnitIds.length}');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _onAdLoaded(ad);
          if (onComplete != null) onComplete();
        },
        onAdFailedToLoad: (error) {
          _onAdFailedToLoad(error);
          if (onComplete != null) onComplete();
        },
      ),
    );
  }

  void _onAdLoaded(RewardedAd ad) {
    debugPrint('Rewarded ad loaded successfully: ${ad.adUnitId}');
    _loadedAds.add(_LoadedAd(ad: ad, loadTime: DateTime.now()));
    _failedAttempts.value = 0;
    _currentLoadingIndex.value++;
    _isLoading.value = false;

    _topUpBuffer();
  }

  void _onAdFailedToLoad(LoadAdError error) {
    debugPrint('Rewarded ad failed to load: ${error.message}');
    
    _reporter.reportEvent(
      event: AdEvent.failed,
      adProvider: 'Google',
      adType: 'Rewarded',
      errorMessage: error.message,
    );

    _failedAttempts.value++;
    _isLoading.value = false;

    if (_failedAttempts.value < maxFailedLoadAttempts) {
      _loadNextAd();
    } else {
      _failedAttempts.value = 0;
      _currentLoadingIndex.value++;
      _topUpBuffer();
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
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    if (_isShowing.value) {
      _pendingShowRequests.value++;
      return Advertresponse.defaults();
    }
    if (_loadedAds.isEmpty) {
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      _loadNextAd(onComplete: () {
        if (_loadedAds.isNotEmpty) {
          showRewardedAd(
            onRewarded: onRewarded,
            onAdClicked: onAdClicked,
            onAdImpression: onAdImpression,
            customData: customData,
          );
        }
      });
      return Advertresponse.defaults();
    }

    final adData = _loadedAds[0];
    if (_isAdExpired(adData.loadTime)) {
      debugPrint('Ad expired, disposing and loading a new one');
      _disposeAd(adData.ad);
      if (_loadedAds.isNotEmpty) {
        return showRewardedAd(
          onRewarded: onRewarded,
          onAdClicked: onAdClicked,
          onAdImpression: onAdImpression,
          customData: customData,
        );
      } else {
        preloadAds();
        return Advertresponse.defaults();
      }
    }

    _configureAndShowAd(
        adData, onRewarded, onAdClicked, onAdImpression, customData);
    return Advertresponse.showing();
  }

  void _configureAndShowAd(
    _LoadedAd adData,
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData,
  ) {
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
          debugPrint('Rewarded ad showed full screen content ${ad.adUnitId}');
          _reporter.reportEvent(
            event: AdEvent.displayed,
            adProvider: 'Google',
            adType: 'Rewarded',
            placementId: ad.adUnitId,
          );
          // Preload the next ad as soon as the current one is shown
          _loadedAds.removeWhere((adData) => adData.ad == ad);
          _topUpBuffer();
          _isShowing.value = true;
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('Rewarded ad dismissed');
        _reporter.reportEvent(
          event: AdEvent.completed,
          adProvider: 'Google',
          adType: 'Rewarded',
          placementId: ad.adUnitId,
          extraData: {'rewardEarned': _rewardEarned.value},
        );
        if (onRewarded != null && _rewardEarned.value) {
          onRewarded();
        }
        _disposeAd(ad);
        _isShowing.value = false;
        if (_pendingShowRequests.value > 0) {
          _pendingShowRequests.value--;
          Future.microtask(() {
            showRewardedAd(
              onRewarded: onRewarded,
              onAdClicked: onAdClicked,
              onAdImpression: onAdImpression,
              customData: customData,
            );
          });
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('Rewarded ad failed to show: ${error.message}');
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Google',
          adType: 'Rewarded',
          placementId: ad.adUnitId,
          errorMessage: error.message,
        );
        _disposeAd(ad);
        // Attempt to show the next ad if available
        _isShowing.value = false;
        if (_loadedAds.isNotEmpty) {
          showRewardedAd(
            onRewarded: onRewarded,
            onAdClicked: onAdClicked,
            onAdImpression: onAdImpression,
            customData: customData,
          );
        } else if (_pendingShowRequests.value > 0) {
          _loadNextAd(onComplete: () {
            if (_loadedAds.isNotEmpty) {
              _pendingShowRequests.value--;
              showRewardedAd(
                onRewarded: onRewarded,
                onAdClicked: onAdClicked,
                onAdImpression: onAdImpression,
                customData: customData,
              );
            }
          });
        }
      },
      onAdClicked: (RewardedAd ad) {
        debugPrint('Rewarded ad clicked');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Google',
          adType: 'Rewarded',
          placementId: ad.adUnitId,
        );
        if (onAdClicked != null) onAdClicked();
      },
      onAdImpression: (RewardedAd ad) {
        debugPrint('Rewarded ad impression');
        if (onAdImpression != null) onAdImpression();
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
    // _loadedAds.removeWhere((adData) => adData.ad == ad);
    ad.dispose();
    // Removed _loadReplacementAd() from here as we now call it in onAdShowedFullScreenContent
  }

  void _topUpBuffer() {
    if (_loadedAds.length >= TARGET_BUFFER_SIZE) return;
    _loadNextAd();
  }

  bool _isAdExpired(DateTime adTime) {
    return DateTime.now().difference(adTime) > adExpiration;
  }
}
