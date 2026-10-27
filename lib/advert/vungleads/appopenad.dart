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
    debugPrint('Loading Vungle App Open ad ($_adType) for placement: $placementId');

    try {
      final ad = await AppOpenAd.load(
        placementId: placementId,
      );
      _loadedAd = ad;
      _isLoading = false;
      debugPrint('Vungle App Open ad loaded successfully ($_adType): $placementId');
    } catch (e) {
      _isLoading = false;
      debugPrint('Vungle App Open ad failed to load ($_adType: $placementId): $e');
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
    final placementId = currentAd.placementId;
    currentAd.listener = FullscreenAdListener(
      onShown: () {
        debugPrint('Vungle App Open ad shown ($_adType): $placementId');
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Vungle',
          adType: _adType,
          placementId: placementId,
        );
      },
      onClosed: () {
        debugPrint('Vungle App Open ad closed ($_adType): $placementId');
        _loadedAd = null;
        loadAd();

        if (onAdDismissed != null) onAdDismissed();
      },
      onFailedToShow: (error) {
        debugPrint('Vungle App Open ad failed to show ($_adType: $placementId): ${error.message}');
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
    );

    debugPrint('Showing Vungle App Open ad ($_adType)');
    currentAd.show().catchError((e) {
      debugPrint('Error showing Vungle App Open ad ($_adType): $e');
    });

    return Advertresponse.showing(provider: 'Vungle');
  }
}
