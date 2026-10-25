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

  void loadAd() {
    if (placementIds.isNotEmpty) {
      debugPrint('Preparing Vungle Native ad ($_adType) for placement: ${placementIds.first}');
    }
  }

  Widget buildAdWidget(BuildContext context) {
    if (placementIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final placementId = placementIds.first;
    debugPrint('Building Vungle Native ad widget ($_adType) for placement: $placementId');

    return LiftoffNativeAd(
      placementId: placementId,
      onLoaded: () {
        debugPrint('Vungle Native ad loaded successfully ($_adType): $placementId');
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Vungle',
          adType: _adType,
          placementId: placementId,
        );
      },
      onClicked: () {
        debugPrint('Vungle Native ad clicked ($_adType): $placementId');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Vungle',
          adType: _adType,
          placementId: placementId,
        );
      },
      onFailedToLoad: (error) {
        debugPrint('Vungle Native ad failed to load ($_adType: $placementId): ${error.message}');
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
