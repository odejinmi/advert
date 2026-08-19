import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class _LoadedAd {
  final RewardedAd ad;
  final DateTime loadTime;

  _LoadedAd({required this.ad, required this.loadTime});
}

class RewardedAdManager {
  // Constants
  static const int maxFailedLoadAttempts = 5; // Increased slightly for more robust retries
  static const Duration adExpiration = Duration(hours: 1);
  static const int TARGET_BUFFER_SIZE = 3;
  static const Duration initialRetryDelay = Duration(seconds: 5);
  static const Duration maxRetryDelay = Duration(seconds: 60);
  static const Duration minRequestInterval = Duration(seconds: 10);

  // Global tracker to prevent overlapping requests for the same ID across all instances
  static final Map<String, DateTime> _globalLastRequestTimes = {};

  final EventReporter _reporter;
  final String _adType;

  // Private variables
  final List<String> _adUnitIds;
  final List<_LoadedAd> _loadedAds = [];
  final List<Function> _pendingCallbacks = [];
  int _currentLoadingIndex = 0;
  int _failedAttempts = 0;
  bool _isLoading = false;
  bool _rewardEarned = false;
  bool _isShowing = false;
  int _pendingShowRequests = 0;

  // Constructor
  RewardedAdManager(this._adUnitIds, this._reporter, {String adType = 'Rewarded'})
      : _adType = adType {
    // Staggered initialization to avoid "thundering herd" effect on startup
    final jitter = Duration(milliseconds: Random().nextInt(2000));
    Future.delayed(jitter, preloadAds);
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get hasAds => _loadedAds.isNotEmpty;
  int get adsCount => _loadedAds.length;

  void dispose() {
    for (final adData in _loadedAds) {
      adData.ad.dispose();
    }
    _loadedAds.clear();
  }

  void preloadAds() {
    _topUpBuffer();
  }

  void _loadNextAd({Function? onComplete}) {
    if (_adUnitIds.isEmpty) {
      debugPrint('No ad unit IDs provided for RewardedAd');
      if (onComplete != null) onComplete();
      return;
    }

    if (_currentLoadingIndex >= _adUnitIds.length) {
      _currentLoadingIndex = 0;
      if (onComplete != null) onComplete();
      return;
    }

    if (_isLoading) return;
    _isLoading = true;
    final adUnitId = _adUnitIds[_currentLoadingIndex];

    // GLOBAL THROTTLING CHECK: Ensure any single ID is not requested more than once per interval
    final now = DateTime.now();
    final lastRequest = _globalLastRequestTimes[adUnitId];
    if (lastRequest != null && now.difference(lastRequest) < minRequestInterval) {
      final waitTime = minRequestInterval - now.difference(lastRequest);
      debugPrint('Global Throttling (Rewarded): ID $adUnitId requested too recently. Waiting ${waitTime.inSeconds}s');
      _isLoading = false;
      Future.delayed(waitTime, () => _loadNextAd(onComplete: onComplete));
      return;
    }

    _globalLastRequestTimes[adUnitId] = now;

    if (_loadedAds.length >= TARGET_BUFFER_SIZE &&
        _loadedAds.any((adData) => adData.ad.adUnitId == adUnitId)) {
      _handleAdAlreadyExists(adUnitId);
      if (onComplete != null) onComplete();
      return;
    }

    debugPrint(
        'Loading rewarded ad ${_currentLoadingIndex + 1}/${_adUnitIds.length}');

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
    _failedAttempts = 0;
    _currentLoadingIndex++;
    _isLoading = false;

    _triggerPendingCallbacks();
    _topUpBuffer();
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

  void _onAdFailedToLoad(LoadAdError error) {
    debugPrint('Rewarded ad failed to load: ${error.message}');
    
    _reporter.reportEvent(
      event: AdEvent.failed,
      adProvider: 'Google',
      adType: _adType,
      errorMessage: error.message,
    );

    _failedAttempts++;
    _isLoading = false;

    // Exponential Backoff: initialDelay * 2^(failedAttempts-1)
    final backoffMultiplier = pow(2, min(_failedAttempts - 1, 4)).toDouble();
    final backoffSeconds = backoffMultiplier * initialRetryDelay.inSeconds;
    final clampedSeconds = backoffSeconds.toInt().clamp(initialRetryDelay.inSeconds, maxRetryDelay.inSeconds);
    final actualDelay = Duration(seconds: clampedSeconds);

    debugPrint('Backing off (Rewarded: $_adType) for ${actualDelay.inSeconds}s due to failure');

    Future.delayed(actualDelay, () {
      if (_failedAttempts < maxFailedLoadAttempts) {
        _loadNextAd();
      } else {
        _failedAttempts = 0;
        _currentLoadingIndex++;
        _topUpBuffer();
      }
    });
  }

  void _handleAdAlreadyExists(String adUnitId) {
    debugPrint('Ad for adUnitId $adUnitId already exists');
    _isLoading = false;
    _currentLoadingIndex++;

    if (_currentLoadingIndex < _adUnitIds.length) {
      _loadNextAd();
    }
  }

  Advertresponse showRewardedAd({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Map<String, String> customData = const {},
  }) {
    if (_isShowing) {
      _pendingShowRequests++;
      return Advertresponse.defaults();
    }
    if (_loadedAds.isEmpty) {
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      _pendingCallbacks.add(() => showRewardedAd(
            onRewarded: onRewarded,
            onAdClicked: onAdClicked,
            onAdImpression: onAdImpression,
            customData: customData,
          ));
      _loadNextAd();
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
    _rewardEarned = false;

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
            adType: _adType,
            placementId: ad.adUnitId,
          );
          _loadedAds.removeWhere((adData) => adData.ad == ad);
          _topUpBuffer();
          _isShowing = true;
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('Rewarded ad dismissed');
        _reporter.reportEvent(
          event: AdEvent.completed,
          adProvider: 'Google',
          adType: _adType,
          placementId: ad.adUnitId,
          extraData: {'rewardEarned': _rewardEarned},
        );
        if (onRewarded != null && _rewardEarned) {
          onRewarded();
        }
        _disposeAd(ad);
        _isShowing = false;
        if (_pendingShowRequests > 0) {
          _pendingShowRequests--;
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
          adType: _adType,
          placementId: ad.adUnitId,
          errorMessage: error.message,
        );
        _disposeAd(ad);
        _isShowing = false;
        if (_loadedAds.isNotEmpty) {
          showRewardedAd(
            onRewarded: onRewarded,
            onAdClicked: onAdClicked,
            onAdImpression: onAdImpression,
            customData: customData,
          );
        } else if (_pendingShowRequests > 0) {
          _loadNextAd(onComplete: () {
            if (_loadedAds.isNotEmpty) {
              _pendingShowRequests--;
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
          adType: _adType,
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
        _rewardEarned = true;
      },
    );
  }

  void _disposeAd(RewardedAd ad) {
    ad.dispose();
  }

  void _topUpBuffer() {
    if (_loadedAds.length >= TARGET_BUFFER_SIZE) return;
    _loadNextAd();
  }

  bool _isAdExpired(DateTime adTime) {
    return DateTime.now().difference(adTime) > adExpiration;
  }
}
