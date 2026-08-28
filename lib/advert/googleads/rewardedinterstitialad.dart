import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class RewardedInterstitialAdManager {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 5;
  static const int TARGET_BUFFER_SIZE = 2;
  static const Duration initialRetryDelay = Duration(seconds: 5);
  static const Duration maxRetryDelay = Duration(seconds: 60);
  static const Duration minRequestInterval = Duration(seconds: 10);

  // Global tracker
  static final Map<String, DateTime> _globalLastRequestTimes = {};

  final EventReporter _reporter;
  final String _adType;

  // Private variables
  final List<String> _adUnitIds;
  final List<RewardedInterstitialAd> _loadedAds = [];
  final List<RewardedInterstitialAd> _loadingAds = []; // Strong reference during load
  final List<Function> _pendingCallbacks = [];
  int _currentLoadingIndex = 0;
  int _failedAttempts = 0;
  bool _isLoading = false;
  bool _rewardEarned = false;

  // Constructor
  RewardedInterstitialAdManager(this._adUnitIds, this._reporter, {String adType = 'RewardedInterstitial'})
      : _adType = adType {
    final jitter = Duration(milliseconds: Random().nextInt(2000));
    Future.delayed(jitter, preloadAds);
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get hasAds => _loadedAds.isNotEmpty;
  int get adsCount => _loadedAds.length;

  void dispose() {
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    for (final ad in _loadingAds) {
      ad.dispose();
    }
    _loadedAds.clear();
    _loadingAds.clear();
  }

  /// Preloads ads up to the number of ad unit IDs available
  void preloadAds() {
    _topUpBuffer();
  }

  /// Loads the next ad in the sequence
  void _loadNextAd({Function? onComplete}) {
    if (_adUnitIds.isEmpty) {
      debugPrint('No ad unit IDs provided for RewardedInterstitial');
      if (onComplete != null) onComplete();
      return;
    }

    if (_currentLoadingIndex >= _adUnitIds.length) {
      _currentLoadingIndex = 0; // wrap for continuous loading
    }

    if (_isLoading) return;
    _isLoading = true;
    final adUnitId = _adUnitIds[_currentLoadingIndex];

    // GLOBAL THROTTLING CHECK
    final now = DateTime.now();
    final lastRequest = _globalLastRequestTimes[adUnitId];
    if (lastRequest != null && now.difference(lastRequest) < minRequestInterval) {
      final waitTime = minRequestInterval - now.difference(lastRequest);
      debugPrint('Global Throttling (RewardedInters): ID $adUnitId requested too recently. Waiting ${waitTime.inSeconds}s');
      _isLoading = false;
      Future.delayed(waitTime, () => _loadNextAd(onComplete: onComplete));
      return;
    }

    _globalLastRequestTimes[adUnitId] = now;

    // Check if an ad already exists for this ad unit ID
    if (_loadedAds.length >= TARGET_BUFFER_SIZE &&
        _loadedAds.any((ad) => ad.adUnitId == adUnitId)) {
      debugPrint('Ad for adUnitId $adUnitId already exists');
      _isLoading = false;
      _currentLoadingIndex++;

      _topUpBuffer();
      return;
    }

    debugPrint(
        'Loading rewarded interstitial ad ${_currentLoadingIndex + 1}/${_adUnitIds.length}');

    final loadCallback = RewardedInterstitialAdLoadCallback(
      onAdLoaded: (RewardedInterstitialAd ad) {
        debugPrint('Rewarded interstitial ad loaded successfully: $adUnitId');
        _loadingAds.remove(ad);
        _onAdLoaded(ad);
        _triggerPendingCallbacks();
        _topUpBuffer();
        if (onComplete != null) onComplete();
      },
      onAdFailedToLoad: (LoadAdError error) {
        _onAdFailedToLoad(error, adUnitId, onComplete);
      },
    );

    RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: loadCallback,
    );
  }

  void _onAdLoaded(RewardedInterstitialAd ad) {
    _loadedAds.add(ad);
    _failedAttempts = 0;
    _currentLoadingIndex++;
    _isLoading = false;
  }

  void _triggerPendingCallbacks() {
    if (_pendingCallbacks.isNotEmpty) {
      final callbacks = List<Function>.from(_pendingCallbacks);
      _pendingCallbacks.clear();
      for (var cb in callbacks) {
        cb();
      }
    }
  }

  void _onAdFailedToLoad(LoadAdError error, String placementId, Function? onComplete) {
    debugPrint(
        'Rewarded interstitial ad failed to load ($placementId): ${error.message}');
    
    _reporter.reportEvent(
      event: AdEvent.failed,
      adProvider: 'Google',
      adType: _adType,
      placementId: placementId,
      errorMessage: error.message,
    );

    _failedAttempts++;
    _isLoading = false;

    // Exponential Backoff
    final backoffMultiplier = pow(2, min(_failedAttempts - 1, 4)).toDouble();
    final backoffSeconds = backoffMultiplier * initialRetryDelay.inSeconds;
    final clampedSeconds =
        backoffSeconds.toInt().clamp(initialRetryDelay.inSeconds, maxRetryDelay.inSeconds);
    final actualDelay = Duration(seconds: clampedSeconds);

    debugPrint('Backing off (RewardedInters: $_adType) for ${actualDelay.inSeconds}s due to failure');

    Future.delayed(actualDelay, () {
      if (_failedAttempts < MAX_FAILED_LOAD_ATTEMPTS) {
        // Retry loading the same ad
        _loadNextAd(onComplete: onComplete);
      } else {
        // Move to next ad unit after max retries
        _failedAttempts = 0;
        _currentLoadingIndex++;

        _topUpBuffer();
        if (onComplete != null) onComplete();
      }
    });
  }

  /// Shows a rewarded interstitial ad if available, returns the result
  Advertresponse showAd({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    if (_loadedAds.isEmpty) {
      debugPrint(
          'Warning: attempt to show rewarded interstitial ad before loaded.');
      _pendingCallbacks.add(() => showAd(
            onRewarded: onRewarded,
            onAdClicked: onAdClicked,
            onAdImpression: onAdImpression,
            customData: customData,
          ));
      _loadNextAd();
      return Advertresponse.defaults();
    }

    final ad = _loadedAds[0];
    _rewardEarned = false;

    // Set server-side verification options if custom data is provided
    if (customData.isNotEmpty) {
      final options = ServerSideVerificationOptions(
        customData: jsonEncode(customData),
      );
      ad.setServerSideOptions(options);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _loadedAds.removeWhere((adData) => adData == ad);
        debugPrint('Rewarded interstitial ad showed full screen content');
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Google',
          adType: _adType,
          placementId: ad.adUnitId,
        );
        _topUpBuffer();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded interstitial ad dismissed');
        _reporter.reportEvent(
          event: AdEvent.completed,
          adProvider: 'Google',
          adType: _adType,
          placementId: ad.adUnitId,
          extraData: {'rewardEarned': _rewardEarned},
        );
        _disposeCurrentAd(ad);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded interstitial ad failed to show: ${error.message}');
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Google',
          adType: _adType,
          placementId: ad.adUnitId,
          errorMessage: error.message,
        );
        _disposeCurrentAd(ad);

        // Try to show another ad after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (_loadedAds.isNotEmpty) {
            showAd(
              onRewarded: onRewarded,
              onAdClicked: onAdClicked,
              onAdImpression: onAdImpression,
              customData: customData,
            );
          }
        });
      },
      onAdClicked: (ad) {
        debugPrint('Rewarded interstitial ad clicked');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Google',
          adType: _adType,
          placementId: ad.adUnitId,
        );
        if (onAdClicked != null) onAdClicked();
      },
      onAdImpression: (ad) {
        debugPrint('Rewarded interstitial ad impression');
        if (onAdImpression != null) onAdImpression();
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        _rewardEarned = true;
        if (onRewarded != null) {
          onRewarded();
        }
      },
    );

    return Advertresponse.showing();
  }

  /// Disposes the current ad and loads a replacement
  void _disposeCurrentAd(ad) {
    ad.dispose();
    _topUpBuffer();
  }

  void _topUpBuffer() {
    if (_loadedAds.length >= TARGET_BUFFER_SIZE) return;
    _loadNextAd();
  }
}
