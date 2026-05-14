import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class InterstitialAdManager {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 3;
  static const int TARGET_BUFFER_SIZE = 2;

  final EventReporter _reporter;

  // Private variables
  final List<String> _adUnitIds;
  final List<InterstitialAd> _loadedAds = [];
  int _currentLoadingIndex = 0;
  int _failedAttempts = 0;
  bool _isLoading = false;

  // Constructor
  InterstitialAdManager(this._adUnitIds, this._reporter) {
    preloadAds();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get hasAds => _loadedAds.isNotEmpty;
  int get adsCount => _loadedAds.length;

  void dispose() {
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    _loadedAds.clear();
  }

  /// Preloads ads up to the number of ad unit IDs available
  void preloadAds() {
    _topUpBuffer();
  }

  /// Loads the next ad in the sequence
  void _loadNextAd() {
    if (_adUnitIds.isEmpty) {
      debugPrint('No ad unit IDs provided for Interstitial');
      return;
    }

    if (_currentLoadingIndex >= _adUnitIds.length) {
      _currentLoadingIndex = 0; // wrap to allow continuous loading
    }

    if (_isLoading) return;
    _isLoading = true;
    final adUnitId = _adUnitIds[_currentLoadingIndex];

    debugPrint(
        'Loading interstitial ad ${_currentLoadingIndex + 1}/${_adUnitIds.length}');

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
    _failedAttempts = 0;
    _currentLoadingIndex++;
    _isLoading = false;

    _topUpBuffer();
  }

  /// Callback when ad fails to load
  void _onAdFailedToLoad(LoadAdError error) {
    debugPrint('Interstitial ad failed to load: ${error.message}');
    
    _reporter.reportEvent(
      event: AdEvent.failed,
      adProvider: 'Google',
      adType: 'Interstitial',
      errorMessage: error.message,
    );

    _failedAttempts++;
    _isLoading = false;

    if (_failedAttempts < MAX_FAILED_LOAD_ATTEMPTS) {
      // Retry loading the same ad
      _loadNextAd();
    } else {
      // Move to next ad unit after max retries
      _failedAttempts = 0;
      _currentLoadingIndex++;
      _topUpBuffer();
    }
  }

  /// Shows an ad if available, returns the result
  Advertresponse showAd({
    Function? onAdClicked,
    Function? onAdImpression,
  }) {
    if (_loadedAds.isEmpty) {
      debugPrint('Warning: attempt to show interstitial ad before loaded.');
      preloadAds();
      return Advertresponse.defaults();
    }

    final ad = _loadedAds.removeAt(0);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        debugPrint('Interstitial ad showed full screen content');
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Google',
          adType: 'Interstitial',
          placementId: ad.adUnitId,
        );
        // Preload the next ad as soon as the current one is shown
        _loadReplacementAd();
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('Interstitial ad dismissed');
        _reporter.reportEvent(
          event: AdEvent.completed,
          adProvider: 'Google',
          adType: 'Interstitial',
          placementId: ad.adUnitId,
        );
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('Interstitial ad failed to show: ${error.message}');
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Google',
          adType: 'Interstitial',
          placementId: ad.adUnitId,
          errorMessage: error.message,
        );
        ad.dispose();
        // Preload a replacement ad (since show failed, we still need one)
        _loadReplacementAd();
      },
      onAdClicked: (InterstitialAd ad) {
        debugPrint('Interstitial ad clicked');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Google',
          adType: 'Interstitial',
          placementId: ad.adUnitId,
        );
        if (onAdClicked != null) onAdClicked();
      },
      onAdImpression: (InterstitialAd ad) {
        debugPrint('Interstitial ad impression');
        if (onAdImpression != null) onAdImpression();
      },
    );

    ad.setImmersiveMode(true);
    ad.show();

    return Advertresponse.showing();
  }

  /// Loads a replacement ad after one is shown or fails
  void _loadReplacementAd() {
    _topUpBuffer();
  }

  /// Ensures the buffer maintains the target number of preloaded ads
  void _topUpBuffer() {
    if (_loadedAds.length >= TARGET_BUFFER_SIZE) return;
    _loadNextAd();
  }
}
