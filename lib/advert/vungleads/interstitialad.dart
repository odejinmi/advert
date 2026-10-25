import 'package:flutter/material.dart';
import 'package:hx_liftoff_ads/hx_liftoff_ads.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class VungleInterstitialAdManager {
  final List<String> placementIds;
  final EventReporter _reporter;
  final String _adType;

  InterstitialAd? _loadedAd;
  bool _isLoading = false;

  VungleInterstitialAdManager(this.placementIds, this._reporter, {String adType = 'Vungle_Interstitial'})
      : _adType = adType;

  bool get hasAds => _loadedAd != null && _loadedAd!.isLoaded;

  Future<void> loadNextAd() async {
    if (_isLoading || placementIds.isEmpty || hasAds) return;
    _isLoading = true;

    final placementId = placementIds.first;
    try {
      final ad = await InterstitialAd.load(
        placementId: placementId,
        listener: FullscreenAdListener(
          onShown: () {
            _reporter.reportEvent(
              event: AdEvent.displayed,
              adProvider: 'Vungle',
              adType: _adType,
              placementId: placementId,
            );
          },
          onClicked: () {
            _reporter.reportEvent(
              event: AdEvent.clicked,
              adProvider: 'Vungle',
              adType: _adType,
              placementId: placementId,
            );
          },
          onClosed: () {
            _loadedAd = null;
            loadNextAd();
          },
          onFailedToShow: (error) {
            _reporter.reportEvent(
              event: AdEvent.failed,
              adProvider: 'Vungle',
              adType: _adType,
              placementId: placementId,
              errorMessage: error.message,
            );
            _loadedAd = null;
            loadNextAd();
          },
        ),
      );
      _loadedAd = ad;
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _reporter.reportEvent(
        event: AdEvent.failed,
        adProvider: 'Vungle',
        adType: _adType,
        placementId: placementId,
        errorMessage: e.toString(),
      );
    }
  }

  Advertresponse showAd(Function? onClick) {
    if (!hasAds) {
      loadNextAd();
      debugPrint('Warning: attempt to show Vungle interstitial ad before loaded.');
      return Advertresponse.defaults(provider: 'Vungle');
    }

    final ad = _loadedAd!;
    _loadedAd = null;

    if (onClick != null) onClick();
    ad.show().catchError((e) {
      debugPrint('Error showing Vungle Interstitial ad: $e');
    });

    return Advertresponse.showing(provider: 'Vungle');
  }
}
