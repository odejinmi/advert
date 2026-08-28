import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../model/advertresponse.dart';
import '../model/unity.dart';
import 'event_reporter.dart';
import 'unityads/interstitialad.dart';
import 'unityads/rewardedvideo.dart';

class UnityProvider {
  final Unitymodel unitymodel;
  final EventReporter _reporter;
  final bool testmode;
  bool _isInitialized = false;

  UnityProvider(this.unitymodel, this._reporter, this.testmode) {
    _initUnity();
  }

  final Map<String, Unityinterstitialad> _interstitialManagers = {};
  final Map<String, Rewardedvideo> _rewardedManagers = {};

  void _initUnity() {
    UnityAds.init(
      gameId: unitymodel.gameId,
      testMode: testmode,
      onComplete: () {
        debugPrint('Unity Ads Initialization Complete');
        _isInitialized = true;
        _initializeAdManagers();
        loadAllAds();
      },
      onFailed: (error, message) {
        debugPrint('Unity Ads Initialization Failed: $error $message');
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Unity',
          adType: 'Initialization',
          errorMessage: '$error: $message',
        );
      },
    );
  }

  void _initializeAdManagers() {
    // Interstitials
    unitymodel.interstitialPlacements.forEach((type, ids) {
      _interstitialManagers[type] = Unityinterstitialad(ids, _reporter, adType: 'Unity_Interstitial_$type');
    });

    // Rewarded
    unitymodel.rewardedPlacements.forEach((type, ids) {
      _rewardedManagers[type] = Rewardedvideo(ids, _reporter, adType: 'Unity_Rewarded_$type');
    });
  }

  bool hasInterstitialAdByType(String type) => _interstitialManagers[type]?.intersAd1.isNotEmpty ?? false;
  get unityintersAd1 => hasInterstitialAdByType('interstitial');

  bool hasRewardedAdByType(String type) => _rewardedManagers[type]?.intersAd1.isNotEmpty ?? false;
  get unityrewardedAd => hasRewardedAdByType('rewarded');

  Advertresponse showAd1(Function? onclick, {String type = 'interstitial'}) {
    return _interstitialManagers[type]?.showAd(onclick) ?? Advertresponse.defaults();
  }

  void loadAllAds() {
    for (var manager in _rewardedManagers.values) {
      manager.createRewardedvideoAd();
    }
    for (var manager in _interstitialManagers.values) {
      manager.createInterstitialAd();
    }
  }

  void loadrewardedad({String? type}) {
    if (!_isInitialized) return;
    if (type != null) {
      _rewardedManagers[type]?.createRewardedvideoAd();
    } else {
      for (var manager in _rewardedManagers.values) {
        manager.createRewardedvideoAd();
      }
    }
  }

  void loadinterrtitialad({String? type}) {
    if (!_isInitialized) return;
    if (type != null) {
      _interstitialManagers[type]?.createInterstitialAd();
    } else {
      for (var manager in _interstitialManagers.values) {
        manager.createInterstitialAd();
      }
    }
  }

  Advertresponse showRewardedAd(rewarded, Function? onclick, {String type = 'rewarded'}) {
    return _rewardedManagers[type]?.showAd(rewarded, onclick) ?? Advertresponse.defaults();
  }

  Widget adWidget() {
    return Container();
  }
}
