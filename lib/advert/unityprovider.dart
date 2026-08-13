import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../model/advertresponse.dart';
import '../model/unity.dart';
import 'event_reporter.dart';
import 'unityads/interstitialad.dart';
import 'unityads/rewardedvideo.dart';


class UnityProvider {
  Unitymodel unitymodel;
  final EventReporter _reporter;
  final bool testmode;

  UnityProvider(this.unitymodel, this._reporter, this.testmode) {
    _initializeAdManagers();
  }

  final Map<String, Unityinterstitialad> _interstitialManagers = {};
  final Map<String, Rewardedvideo> _rewardedManagers = {};

  void _initializeAdManagers() {
    _interstitialManagers['interstitial'] =
        Unityinterstitialad(unitymodel.interstitialVideoAdPlacementId, _reporter, adType: 'Interstitial');
    
    _rewardedManagers['rewarded'] =
        Rewardedvideo(unitymodel.rewardedVideoAdPlacementId, _reporter, adType: 'Rewarded');
  }

  bool hasInterstitialAdByType(String type) => _interstitialManagers[type]?.intersAd1.isNotEmpty ?? false;
  get unityintersAd1 => hasInterstitialAdByType('interstitial');

  bool hasRewardedAdByType(String type) => _rewardedManagers[type]?.intersAd1.isNotEmpty ?? false;
  get unityrewardedAd => hasRewardedAdByType('rewarded');

  Advertresponse showAd1(Function? onclick, {String type = 'interstitial'}) {
    return _interstitialManagers[type]?.showAd(onclick) ?? Advertresponse.defaults();
  }

  void loadrewardedad({String? type}) {
    if (type != null) {
      _rewardedManagers[type]?.createInterstitialAd();
    } else {
      for (var manager in _rewardedManagers.values) {
        manager.createInterstitialAd();
      }
    }
  }

  void loadinterrtitialad({String? type}) {
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
