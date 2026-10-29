import 'package:flutter/material.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../model/advertresponse.dart';
import '../model/levelplay.dart';
import 'event_reporter.dart';
import 'levelplayads/bannerad.dart';
import 'levelplayads/interstitialad.dart';
import 'levelplayads/rewardedad.dart';

class LevelPlayProvider implements LevelPlayInitListener {
  final Levelplaymodel levelplaymodel;
  final EventReporter _reporter;
  final bool testmode;
  bool _isInitialized = false;

  final Map<String, LevelPlayInterstitialAdManager> _interstitialManagers = {};
  final Map<String, LevelPlayRewardedAdManager> _rewardedManagers = {};

  LevelPlayProvider(this.levelplaymodel, this._reporter, this.testmode) {
    _initLevelPlay();
  }

  Future<void> _initLevelPlay() async {
    if (levelplaymodel.appKey.isEmpty) return;

    try {
      final initRequest = LevelPlayInitRequest(appKey: levelplaymodel.appKey);
      await LevelPlay.init(initRequest: initRequest, initListener: this);
    } catch (e) {
      debugPrint('LevelPlay Initialization Exception: $e');
    }
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    debugPrint('LevelPlay Initialization Complete');
    _isInitialized = true;
    _initializeAdManagers();
    loadAllAds();
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    debugPrint('LevelPlay Initialization Failed: ${error.errorMessage}');
  }

  void _initializeAdManagers() {
    levelplaymodel.interstitialPlacements.forEach((type, ids) {
      _interstitialManagers[type] = LevelPlayInterstitialAdManager(ids, _reporter, adType: 'LevelPlay_Interstitial_$type');
    });

    levelplaymodel.rewardedPlacements.forEach((type, ids) {
      _rewardedManagers[type] = LevelPlayRewardedAdManager(ids, _reporter, adType: 'LevelPlay_Rewarded_$type');
    });
  }

  bool hasInterstitialAdByType(String type) => _interstitialManagers[type]?.hasAds ?? false;
  bool get hasInterstitialAd => hasInterstitialAdByType('interstitial');

  bool hasRewardedAdByType(String type) => _rewardedManagers[type]?.hasAds ?? false;
  bool get hasRewardedAd => hasRewardedAdByType('rewarded');

  void loadAllAds() {
    for (var manager in _rewardedManagers.values) {
      manager.loadAd();
    }
    for (var manager in _interstitialManagers.values) {
      manager.loadAd();
    }
  }

  Advertresponse showInterstitialAd(Function? onClick, {String type = 'interstitial'}) {
    return _interstitialManagers[type]?.showAd(onClick) ?? Advertresponse.defaults(provider: 'LevelPlay');
  }

  Advertresponse showRewardedAd(Function? onRewarded, Function? onClick, {String type = 'rewarded', Function? onAdDismissed}) {
    return _rewardedManagers[type]?.showAd(onRewarded, onClick, onAdDismissed: onAdDismissed) ?? Advertresponse.defaults(provider: 'LevelPlay');
  }

  Widget adWidget() {
    if (levelplaymodel.bannerAdPlacementId.isEmpty) {
      return const SizedBox.shrink();
    }
    return LevelPlayBannerAdWidget(
      adUnitIds: levelplaymodel.bannerAdPlacementId,
      reporter: _reporter,
    );
  }
}
