import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';
import '../event_reporter.dart';

class BannerAdManager {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 3;

  final EventReporter _reporter;

  // Private variables
  final List<String> _adUnitIds;
  final List<BannerAd> _loadedAds = [];
  int _currentLoadingIndex = 0;
  int _failedAttempts = 0;
  bool _isLoading = false;
  bool _bannerReady = false;

  // Constructor
  BannerAdManager(this._adUnitIds, this._reporter) {
    _initializeListener();
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
        debugPrint(
            'Banner ad loaded successfully: ${(ad as BannerAd).adUnitId}');
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Google',
          adType: 'Banner',
          placementId: (ad).adUnitId,
        );
        _loadedAds.add(ad);
        _bannerReady = true;
        _failedAttempts = 0;
        _isLoading = false;
        _currentLoadingIndex++;

        if (_currentLoadingIndex < _adUnitIds.length) {
          loadAd();
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('Banner ad failed to load: ${error.message}');
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Google',
          adType: 'Banner',
          placementId: (ad as BannerAd).adUnitId,
          errorMessage: error.message,
        );
        ad.dispose();
        _failedAttempts++;
        _isLoading = false;

        if (_failedAttempts < MAX_FAILED_LOAD_ATTEMPTS) {
          loadAd();
        } else {
          _failedAttempts = 0;
          _currentLoadingIndex++;

          if (_currentLoadingIndex < _adUnitIds.length) {
            loadAd();
          }
        }
      },
      onAdOpened: (ad) {
        debugPrint('Banner ad opened');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Google',
          adType: 'Banner',
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

    _isLoading = true;
    final adUnitId = _adUnitIds[_currentLoadingIndex];

    debugPrint(
        'Loading banner ad ${_currentLoadingIndex + 1}/${_adUnitIds.length}: $adUnitId');

    BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: _listener,
    ).load();
  }

  /// Refreshes an ad by disposing it and loading a new one
  void _refreshAd(BannerAd ad) {
    final index =
        _loadedAds.indexWhere((loadedAd) => loadedAd.adUnitId == ad.adUnitId);
    if (index != -1) {
      _loadedAds.removeAt(index);
      ad.dispose();

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
    _loadedAds.clear();
  }

  /// Returns a widget displaying the banner ad
  Widget adWidget() {
    if (bannerReady && deviceallow.allow()) {
      return Container(
        alignment: Alignment.center,
        width: _loadedAds.first.size.width.toDouble(),
        height: _loadedAds.first.size.height.toDouble(),
        child: AdWidget(ad: _loadedAds.first),
      );
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
        if (snapshot.connectionState == ConnectionState.done) {
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
