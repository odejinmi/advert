import 'package:flutter/material.dart';
import 'package:hx_liftoff_ads/hx_liftoff_ads.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class VungleAppOpenAdManager {
  final List<String> placementIds;
  final EventReporter _reporter;
  final String _adType;

  AppOpenAd? _loadedAd;
  bool _isLoading = false;

  VungleAppOpenAdManager(this.placementIds, this._reporter, {String adType = 'Vungle_AppOpen'})
      : _adType = adType;

  bool get hasAds => _loadedAd != null && _loadedAd!.isLoaded && !_loadedAd!.isExpired;

  Future<void> loadAd() async {
    if (_isLoading || placementIds.isEmpty || hasAds) return;
    _isLoading = true;

    final placementId = placementIds.first;
    try {
      final ad = await AppOpenAd.load(
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
          onClosed: () {
            _loadedAd = null;
            loadAd();
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
            loadAd();
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

  Advertresponse showAd({Function? onAdDismissed}) {
    if (!hasAds) {
      loadAd();
      debugPrint('Warning: attempt to show Vungle App Open ad before loaded.');
      return Advertresponse.defaults(provider: 'Vungle');
    }

    final currentAd = _loadedAd!;
    _loadedAd = null;

    currentAd.show().catchError((e) {
      debugPrint('Error showing Vungle App Open ad: $e');
    });

    if (onAdDismissed != null) onAdDismissed();

    return Advertresponse.showing(provider: 'Vungle');
  }
}
