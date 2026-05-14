import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../model/advertresponse.dart';
import '../model/unity.dart';
import 'event_reporter.dart';
import 'unityads/interstitialad.dart';
import 'unityads/rewardedvideo.dart';


class UnityProvider {
  Unitymodel unitymodel;
  final EventReporter _reporter;

  UnityProvider(this.unitymodel, this._reporter) {
    UnityAds.init(
      gameId: unitymodel.gameId,
      testMode: true,
      onComplete: () {
        print('Initialization Complete');
        loadinterrtitialad();
        loadrewardedad();
      },
      onFailed: (error, message) =>
          print('Initialization Failed: $error $message'),
    );
    interstitiaad = Unityinterstitialad(unitymodel.interstitialVideoAdPlacementId, _reporter);
    rewardedvideo = Rewardedvideo(unitymodel.rewardedVideoAdPlacementId, _reporter);

    for(int i = 0; i < unitymodel.interstitialVideoAdPlacementId.length; i++){
      placements[unitymodel.interstitialVideoAdPlacementId[i]]= false;
    }
    for(int i = 0; i < unitymodel.rewardedVideoAdPlacementId.length; i++){
      placements[unitymodel.rewardedVideoAdPlacementId[i]]= false;
    }
  }

  Map<String, bool> placements = {};
  late Unityinterstitialad interstitiaad;
  late Rewardedvideo rewardedvideo;

  get rewardvideoloaded => rewardedvideo.intersAd1.isNotEmpty;

  get unityintersAd1{
    return interstitiaad.intersAd1.isNotEmpty;
  }

  Advertresponse showAd1(Function? onclick){
    return interstitiaad.showAd(onclick);
  }

  get unityrewardedAd{
    return rewardedvideo.intersAd1.isNotEmpty;
  }

  loadrewardedad(){
    rewardedvideo.createInterstitialAd();
  }
  loadinterrtitialad(){
    interstitiaad.createInterstitialAd();
  }
  Advertresponse showRewardedAd(rewarded,Function? onclick){
    return rewardedvideo.showAd(rewarded, onclick);
  }

  Widget adWidget() {
    return UnityBannerAd(
      placementId: unitymodel.bannerAdPlacementId[0],
      onLoad: (placementId) => debugPrint('Banner loaded: $placementId'),
      onClick: (placementId) => debugPrint('Banner clicked: $placementId'),
      onFailed: (placementId, error, message) =>
          debugPrint('Banner Ad $placementId failed: $error $message'),
    );
  }
}
