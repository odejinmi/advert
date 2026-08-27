import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';
import '../event_reporter.dart';

class BannerAdManager {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 5;
  static const Duration initialRetryDelay = Duration(seconds: 5);
  static const Duration maxRetryDelay = Duration(seconds: 60);
  static const Duration minRequestInterval = Duration(seconds: 10);

  // Global tracker
  static final Map<String, DateTime> _globalLastRequestTimes = {};

  final EventReporter _reporter;
  final String _adType;

  // Private variables
  final List<String> _adUnitIds;
  final List<BannerAd> _loadedAds = [];
  final List<BannerAd> _loadingAds = []; // Keep reference to ads while they load
  int _currentLoadingIndex = 0;
  int _failedAttempts = 0;
  bool _isLoading = false;
  bool _bannerReady = false;

  // Cache for the ad widget to prevent recreation on UI rebuilds
  Widget? _cachedAdWidget;
  BannerAd? _lastAdUsedForWidget;

  // Constructor
  BannerAdManager(this._adUnitIds, this._reporter, {String adType = 'Banner'})
      : _adType = adType {
    _initializeListener();
    final jitter = Duration(milliseconds: Random().nextInt(2000));
    Future.delayed(jitter, loadAd);
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get bannerReady => _bannerReady && _loadedAds.isNotEmpty;
  bool get hasAds => _loadedAds.isNotEmpty;

  // Banner ad listener
  late final BannerAdListener _listener;

  void dispose() {
    _disposeAllAds();
  }

  /// Initializes the banner ad listener
  void _initializeListener() {
    _listener = BannerAdListener(
      onAdLoaded: (ad) {
        final bannerAd = ad as BannerAd;
        debugPrint(
            'Banner ad loaded successfully: ${bannerAd.adUnitId}');
        
        _loadingAds.remove(bannerAd); // Move from loading to loaded
        
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Google',
          adType: _adType,
          placementId: bannerAd.adUnitId,
        );
        _loadedAds.add(bannerAd);
        _bannerReady = true;
        _failedAttempts = 0;
        _isLoading = false;
        _currentLoadingIndex++;

        if (_currentLoadingIndex < _adUnitIds.length) {
          loadAd();
        }
      },
      onAdFailedToLoad: (ad, error) {
        final bannerAd = ad as BannerAd;
        debugPrint('Banner ad failed to load: ${error.message}');
        
        _loadingAds.remove(bannerAd);
        
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Google',
          adType: _adType,
          placementId: bannerAd.adUnitId,
          errorMessage: error.message,
        );
        bannerAd.dispose();
        _failedAttempts++;
        _isLoading = false;

        // Exponential Backoff
        final backoffMultiplier = pow(2, min(_failedAttempts - 1, 4)).toDouble();
        final backoffSeconds = backoffMultiplier * initialRetryDelay.inSeconds;
        final clampedSeconds = backoffSeconds.toInt().clamp(initialRetryDelay.inSeconds, maxRetryDelay.inSeconds);
        final actualDelay = Duration(seconds: clampedSeconds);

        debugPrint('Backing off (Banner: $_adType) for ${actualDelay.inSeconds}s due to failure');

        Future.delayed(actualDelay, () {
          if (_failedAttempts < MAX_FAILED_LOAD_ATTEMPTS) {
            loadAd();
          } else {
            _failedAttempts = 0;
            _currentLoadingIndex++;

            if (_currentLoadingIndex < _adUnitIds.length) {
              loadAd();
            }
          }
        });
      },
      onAdOpened: (ad) {
        debugPrint('Banner ad opened');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Google',
          adType: _adType,
          placementId: (ad as BannerAd).adUnitId,
        );
      },
      onAdClosed: (ad) {
        debugPrint('Banner ad closed');
        _refreshAd(ad as BannerAd);
      },
      onAdWillDismissScreen: (ad) {
        debugPrint('Banner ad will dismiss screen');
        _refreshAd(ad as BannerAd);
      },
      onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
      onPaidEvent: (ad, valueMicros, precision, currencyCode) =>
          debugPrint('Banner ad paid event: $currencyCode $valueMicros'),
    );
  }

  /// Loads a banner ad using the current ad unit ID
  void loadAd() {
    if (_adUnitIds.isEmpty) {
      debugPrint('No banner ad unit IDs provided');
      return;
    }

    if (_isLoading) {
      debugPrint('Banner ad load already in progress');
      return;
    }

    if (_currentLoadingIndex >= _adUnitIds.length) {
      debugPrint('All banner ad units attempted');
      return;
    }

    final adUnitId = _adUnitIds[_currentLoadingIndex];

    // GLOBAL THROTTLING CHECK
    final now = DateTime.now();
    final lastRequest = _globalLastRequestTimes[adUnitId];
    if (lastRequest != null && now.difference(lastRequest) < minRequestInterval) {
      final waitTime = minRequestInterval - now.difference(lastRequest);
      debugPrint('Global Throttling (Banner): ID $adUnitId requested too recently. Waiting ${waitTime.inSeconds}s');
      Future.delayed(waitTime, loadAd);
      return;
    }

    _globalLastRequestTimes[adUnitId] = now;
    _isLoading = true;

    debugPrint(
        'Loading banner ad ${_currentLoadingIndex + 1}/${_adUnitIds.length}: $adUnitId');

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: _listener,
    );
    
    _loadingAds.add(bannerAd); // Keep reference
    bannerAd.load();
  }

  /// Refreshes an ad by disposing it and loading a new one
  void _refreshAd(BannerAd ad) {
    final index =
        _loadedAds.indexWhere((loadedAd) => loadedAd.adUnitId == ad.adUnitId);
    if (index != -1) {
      _loadedAds.removeAt(index);
      ad.dispose();

      // Clear cache if this was the cached ad
      if (_lastAdUsedForWidget == ad) {
        _cachedAdWidget = null;
        _lastAdUsedForWidget = null;
      }

      if (_currentLoadingIndex > 0) {
        _currentLoadingIndex--;
      }

      loadAd();
    }
  }

  /// Disposes all loaded ads
  void _disposeAllAds() {
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    for (final ad in _loadingAds) {
      ad.dispose();
    }
    _loadedAds.clear();
    _loadingAds.clear();
    _cachedAdWidget = null;
    _lastAdUsedForWidget = null;
  }

  /// Returns a widget displaying the banner ad
  Widget adWidget() {
    if (bannerReady && deviceallow.allow()) {
      final ad = _loadedAds.first;

      // Return cached widget if it exists for this ad to prevent "Ad not loaded" on rebuilds
      if (_cachedAdWidget != null && _lastAdUsedForWidget == ad) {
        return _cachedAdWidget!;
      }

      _lastAdUsedForWidget = ad;
      // Use a UniqueKey to ensure the AdWidget is correctly recreated if the underlying ad instance changes
      _cachedAdWidget = Container(
        key: UniqueKey(),
        alignment: Alignment.center,
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      );

      return _cachedAdWidget!;
    } else {
      return const SizedBox.shrink();
    }
  }

  /// Creates and returns a banner ad widget with specified size
  Widget bannerAdWithSize({AdSize adSize = AdSize.banner}) {
    if (_adUnitIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final adUnitId = _adUnitIds.first;

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      listener: _listener,
      request: const AdRequest(),
    );

    return FutureBuilder(
      future: banner.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
          // Double check if ad is actually loaded, as some errors might not throw
          // but result in an unloaded ad.
          
          _adUnitIds.removeAt(0);
          _adUnitIds.add(adUnitId);

          return Container(
            alignment: Alignment.center,
            width: banner.size.width.toDouble(),
            height: banner.size.height.toDouble(),
            child: AdWidget(ad: banner),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
