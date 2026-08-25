import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../event_reporter.dart';

class AppOpenAdManager {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 5;
  static const Duration adExpiration = Duration(hours: 4); // App open ads expire after 4 hours
  static const int TARGET_BUFFER_SIZE = 2;
  static const Duration initialRetryDelay = Duration(seconds: 5);
  static const Duration maxRetryDelay = Duration(seconds: 60);
  static const Duration minRequestInterval = Duration(seconds: 10);

  // Global tracker to prevent overlapping requests for the same ID
  static final Map<String, DateTime> _globalLastRequestTimes = {};

  final EventReporter _reporter;
  final String _adType;

  // Private variables
  final List<String> _adUnitIds;
  final List<_LoadedAppOpenAd> _loadedAds = [];
  final List<Function> _pendingCallbacks = [];
  int _currentLoadingIndex = 0;
  int _failedAttempts = 0;
  bool _isLoading = false;
  bool _isShowing = false;

  // Constructor
  AppOpenAdManager(this._adUnitIds, this._reporter, {String adType = 'AppOpen'})
      : _adType = adType {
    // Staggered initialization
    final jitter = Duration(milliseconds: Random().nextInt(2000));
    Future.delayed(jitter, preloadAds);
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get hasAds => _loadedAds.isNotEmpty;
  bool get isShowing => _isShowing;

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
      debugPrint('No ad unit IDs provided for AppOpenAd');
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

    // GLOBAL THROTTLING CHECK
    final now = DateTime.now();
    final lastRequest = _globalLastRequestTimes[adUnitId];
    if (lastRequest != null && now.difference(lastRequest) < minRequestInterval) {
      final waitTime = minRequestInterval - now.difference(lastRequest);
      debugPrint('Global Throttling (AppOpen): ID $adUnitId requested too recently. Waiting ${waitTime.inSeconds}s');
      _isLoading = false;
      Future.delayed(waitTime, () => _loadNextAd(onComplete: onComplete));
      return;
    }

    _globalLastRequestTimes[adUnitId] = now;

    if (_loadedAds.length >= TARGET_BUFFER_SIZE &&
        _loadedAds.any((adData) => adData.ad.adUnitId == adUnitId)) {
      _isLoading = false;
      _currentLoadingIndex++;
      _topUpBuffer();
      if (onComplete != null) onComplete();
      return;
    }

    debugPrint('Loading app open ad ${_currentLoadingIndex + 1}/${_adUnitIds.length}');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _onAdLoaded(ad);
          if (onComplete != null) onComplete();
        },
        onAdFailedToLoad: (error) {
          _onAdFailedToLoad(error, adUnitId);
          if (onComplete != null) onComplete();
        },
      ),
      // orientation: AppOpenAd.orientationPortrait,
    );
  }

  void _onAdLoaded(AppOpenAd ad) {
    debugPrint('App open ad loaded successfully: ${ad.adUnitId}');
    _loadedAds.add(_LoadedAppOpenAd(ad: ad, loadTime: DateTime.now()));
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

  void _onAdFailedToLoad(LoadAdError error, String placementId) {
    debugPrint('App open ad failed to load ($placementId): ${error.message}');
    
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
    final clampedSeconds = backoffSeconds.toInt().clamp(initialRetryDelay.inSeconds, maxRetryDelay.inSeconds);
    final actualDelay = Duration(seconds: clampedSeconds);

    debugPrint('Backing off (AppOpen: $_adType) for ${actualDelay.inSeconds}s due to failure');

    Future.delayed(actualDelay, () {
      if (_failedAttempts < MAX_FAILED_LOAD_ATTEMPTS) {
        _loadNextAd();
      } else {
        _failedAttempts = 0;
        _currentLoadingIndex++;
        _topUpBuffer();
      }
    });
  }

  void showAd({Function? onAdDismissed}) {
    if (_isShowing) {
      debugPrint('Warning: App open ad is already showing');
      return;
    }

    if (!hasAds) {
      debugPrint('Warning: No app open ads loaded');
      _pendingCallbacks.add(() => showAd(onAdDismissed: onAdDismissed));
      _loadNextAd();
      return;
    }

    // Mark as showing immediately to prevent race conditions
    _isShowing = true;

    // Clean up expired ads
    _loadedAds.removeWhere((adData) {
      if (_isAdExpired(adData.loadTime)) {
        adData.ad.dispose();
        return true;
      }
      return false;
    });

    if (!hasAds) {
      _isShowing = false; // Reset if we found no valid ads after expiration check
      showAd(onAdDismissed: onAdDismissed);
      return;
    }

    final adData = _loadedAds.removeAt(0);
    final ad = adData.ad;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('App open ad showed full screen content');
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Google',
          adType: _adType,
          placementId: ad.adUnitId,
        );
        _topUpBuffer();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('App open ad dismissed');
        _isShowing = false;
        _reporter.reportEvent(
          event: AdEvent.completed,
          adProvider: 'Google',
          adType: _adType,
          placementId: ad.adUnitId,
        );
        ad.dispose();
        if (onAdDismissed != null) onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App open ad failed to show: ${error.message}');
        _isShowing = false;
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Google',
          adType: _adType,
          placementId: ad.adUnitId,
          errorMessage: error.message,
        );
        ad.dispose();
        _topUpBuffer();
        if (onAdDismissed != null) onAdDismissed();
      },
      onAdClicked: (ad) {
        debugPrint('App open ad clicked');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Google',
          adType: _adType,
          placementId: ad.adUnitId,
        );
      },
    );

    ad.show();
  }

  void _topUpBuffer() {
    if (_loadedAds.length >= TARGET_BUFFER_SIZE) return;
    _loadNextAd();
  }

  bool _isAdExpired(DateTime adTime) {
    return DateTime.now().difference(adTime) > adExpiration;
  }
}

class _LoadedAppOpenAd {
  final AppOpenAd ad;
  final DateTime loadTime;

  _LoadedAppOpenAd({required this.ad, required this.loadTime});
}
