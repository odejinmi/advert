import 'package:flutter/material.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../event_reporter.dart';

class LevelPlayBannerAdWidget extends StatelessWidget {
  final List<String> adUnitIds;
  final EventReporter reporter;

  const LevelPlayBannerAdWidget({
    super.key,
    required this.adUnitIds,
    required this.reporter,
  });

  @override
  Widget build(BuildContext context) {
    if (adUnitIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final adUnitId = adUnitIds.first;
    debugPrint('Building LevelPlay Banner ad widget for adUnitId: $adUnitId');

    return Container(
      alignment: Alignment.center,
      height: 50,
      child: LevelPlayBannerAdView(
        key: GlobalKey<LevelPlayBannerAdViewState>(),
        adUnitId: adUnitId,
        adSize: LevelPlayAdSize.BANNER,
        listener: _BannerListener(reporter, adUnitId),
      ),
    );
  }
}

class _BannerListener implements LevelPlayBannerAdViewListener {
  final EventReporter reporter;
  final String adUnitId;

  _BannerListener(this.reporter, this.adUnitId);

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    reporter.reportEvent(
      event: AdEvent.displayed,
      adProvider: 'LevelPlay',
      adType: 'Banner',
      placementId: adInfo.adUnitId,
    );
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    reporter.reportEvent(
      event: AdEvent.failed,
      adProvider: 'LevelPlay',
      adType: 'Banner',
      placementId: adUnitId,
      errorMessage: error.errorMessage,
    );
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    reporter.reportEvent(
      event: AdEvent.clicked,
      adProvider: 'LevelPlay',
      adType: 'Banner',
      placementId: adInfo.adUnitId,
    );
  }

  @override
  void onAdCollapsed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error) {}

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdExpanded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLeftApplication(LevelPlayAdInfo adInfo) {}
}
