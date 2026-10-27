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
    debugPrint('Loading Vungle Interstitial ad ($_adType) for placement: $placementId');

    try {
      final ad = await InterstitialAd.load(
        placementId: placementId,
      );
      _loadedAd = ad;
      _isLoading = false;
      debugPrint('Vungle Interstitial ad loaded successfully ($_adType): $placementId');
    } catch (e) {
      _isLoading = false;
      debugPrint('Vungle Interstitial ad failed to load ($_adType: $placementId): $e');
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
      debugPrint('Warning: attempt to show Vungle Interstitial ad before loaded.');
      return Advertresponse.defaults(provider: 'Vungle');
    }

    final currentAd = _loadedAd!;
    _loadedAd = null;
    final placementId = currentAd.placementId;
    currentAd.listener = FullscreenAdListener(
      onShown: () {
        debugPrint('Vungle Interstitial ad shown ($_adType): $placementId');
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Vungle',
          adType: _adType,
          placementId: placementId,
        );
      },
      onClicked: () {
        debugPrint('Vungle Interstitial ad clicked ($_adType): $placementId');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Vungle',
          adType: _adType,
          placementId: placementId,
        );
        if (onClick != null) onClick();
      },
      onClosed: () {
        debugPrint('Vungle Interstitial ad closed ($_adType): $placementId');
        _loadedAd = null;
        loadNextAd();
      },
      onFailedToShow: (error) {
        debugPrint('Vungle Interstitial ad failed to show ($_adType: $placementId): ${error.message}');
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
    );

    debugPrint('Showing Vungle Interstitial ad ($_adType)');
    currentAd.show().catchError((e) {
      debugPrint('Error showing Vungle Interstitial ad ($_adType): $e');
    });

    return Advertresponse.showing(provider: 'Vungle');
  }
}
