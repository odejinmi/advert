import 'dart:io';

// import 'package:chartboost/chartboost.dart';
import 'package:flutter/material.dart';

import '../model/advertresponse.dart';
import '../model/chartboost.dart';
import 'chartboostads/bannerad.dart';
import 'chartboostads/interstitialad.dart';
import 'chartboostads/rewardedad.dart';
import 'event_reporter.dart';

class ChartboostProvider {
  final Chartboostmodel chartboostmodel;
  final EventReporter _reporter;
  final bool testmode;
  bool _isInitialized = false;

  final Map<String, ChartboostInterstitialAdManager> _interstitialManagers = {};
  final Map<String, ChartboostRewardedAdManager> _rewardedManagers = {};

  ChartboostProvider(this.chartboostmodel, this._reporter, this.testmode) {
    if (Platform.isAndroid) {
      _initChartboost();
    } else {
      debugPrint('Chartboost 1.0.0 package only supports Android platform.');
    }
  }

  Future<void> _initChartboost() async {
    if (chartboostmodel.appId.isEmpty || chartboostmodel.appSignature.isEmpty) return;

    try {
      // await Chartboost.init(chartboostmodel.appId, chartboostmodel.appSignature);
      debugPrint('Chartboost Ads Initialized with App ID: ${chartboostmodel.appId}');
      _isInitialized = true;
      _initializeAdManagers();
      loadAllAds();
    } catch (e) {
      debugPrint('Chartboost Ads Initialization Error: $e');
    }
  }

  void _initializeAdManagers() {
    chartboostmodel.interstitialPlacements.forEach((type, locations) {
      _interstitialManagers[type] = ChartboostInterstitialAdManager(locations, _reporter, adType: 'Chartboost_Interstitial_$type');
    });

    chartboostmodel.rewardedPlacements.forEach((type, locations) {
      _rewardedManagers[type] = ChartboostRewardedAdManager(locations, _reporter, adType: 'Chartboost_Rewarded_$type');
    });
  }

  bool hasInterstitialAdByType(String type) => _interstitialManagers[type]?.hasAds ?? false;
  bool get hasInterstitialAd => hasInterstitialAdByType('interstitial');

  bool hasRewardedAdByType(String type) => _rewardedManagers[type]?.hasAds ?? false;
  bool get hasRewardedAd => hasRewardedAdByType('rewarded');

  void loadAllAds() {
    for (var manager in _rewardedManagers.values) {
      manager.cacheNextAd();
    }
    for (var manager in _interstitialManagers.values) {
      manager.cacheNextAd();
    }
  }

  Advertresponse showInterstitialAd(Function? onClick, {String type = 'interstitial'}) {
    return _interstitialManagers[type]?.showAd(onClick) ?? Advertresponse.defaults(provider: 'Chartboost');
  }

  Advertresponse showRewardedAd(Function? onRewarded, Function? onClick, {String type = 'rewarded', Function? onAdDismissed}) {
    return _rewardedManagers[type]?.showAd(onRewarded, onClick, onAdDismissed: onAdDismissed) ?? Advertresponse.defaults(provider: 'Chartboost');
  }

  Widget adWidget() {
    if (chartboostmodel.bannerAdPlacementId.isEmpty) {
      return const SizedBox.shrink();
    }
    return ChartboostBannerAdWidget(
      locations: chartboostmodel.bannerAdPlacementId,
      reporter: _reporter,
    );
  }
}
