import 'package:flutter/material.dart';
import 'package:hx_liftoff_ads/hx_liftoff_ads.dart';

import '../event_reporter.dart';

class VungleBannerAdWidget extends StatelessWidget {
  final List<String> placementIds;
  final EventReporter reporter;

  const VungleBannerAdWidget({
    super.key,
    required this.placementIds,
    required this.reporter,
  });

  @override
  Widget build(BuildContext context) {
    if (placementIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final placementId = placementIds.first;

    return LiftoffBannerAd(
      placementId: placementId,
      onLoaded: () {
        reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Vungle',
          adType: 'Banner',
          placementId: placementId,
        );
      },
      onClicked: () {
        reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Vungle',
          adType: 'Banner',
          placementId: placementId,
        );
      },
      onFailedToLoad: (error) {
        reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Vungle',
          adType: 'Banner',
          placementId: placementId,
          errorMessage: error.message,
        );
      },
    );
  }
}
