import 'package:flutter/material.dart';
import 'package:hx_liftoff_ads/hx_liftoff_ads.dart';

import '../event_reporter.dart';

class VungleNativeAdManager {
  final List<String> placementIds;
  final EventReporter _reporter;
  final String _adType;

  VungleNativeAdManager(this.placementIds, this._reporter, {String adType = 'Vungle_Native'})
      : _adType = adType;

  bool get isAdLoaded => placementIds.isNotEmpty;

  void loadAd() {}

  Widget buildAdWidget(BuildContext context) {
    if (placementIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final placementId = placementIds.first;
    return LiftoffNativeAd(
      placementId: placementId,
      onLoaded: () {
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
      onFailedToLoad: (error) {
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Vungle',
          adType: _adType,
          placementId: placementId,
          errorMessage: error.message,
        );
      },
    );
  }
}
