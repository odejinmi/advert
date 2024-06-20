import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../model/advertresponse.dart';
import '../model/unity.dart';
import 'unityads/interstitialad.dart';
import 'unityads/rewardedvideo.dart';


class UnityProvider extends GetxController {
  Unitymodel unitymodel;
  UnityProvider(this.unitymodel);
  // var prefs = GetStorage();
  bool showBanner = false;
  Map<String, bool> placements = {};

  static final _random = Random();
  var interstitiaad;
  var rewardedvideo;
  @override
  void onInit() {
    interstitiaad = Get.put(Unityinterstitialad(unitymodel.interstitialVideoAdPlacementId), permanent: true);
    rewardedvideo = Get.put(Rewardedvideo(unitymodel.rewardedVideoAdPlacementId), permanent: true);

    for(int i = 0; i < unitymodel.interstitialVideoAdPlacementId.length; i++){
      placements[unitymodel.interstitialVideoAdPlacementId[i]]= false;
    }
    for(int i = 0; i < unitymodel.rewardedVideoAdPlacementId.length; i++){
      placements[unitymodel.rewardedVideoAdPlacementId[i]]= false;
    }

    super.onInit();
  }

  bool _footerBannerShow = false;
  dynamic _bannerAd;

  get rewardvideoloaded => rewardedvideo.videoUnitId.isNotEmpty;

  set footBannerShow(bool value) {
    _footerBannerShow = value;
    update();
  }

  get bannerIsAvailable => _bannerAd != null;

  get unityintersAd1{
    return interstitiaad.intersAd1.isNotEmpty;
  }

  Advertresponse showAd1(){
    return interstitiaad.showAd();
  }

  get unityrewardedAd{
    return rewardedvideo.intersAd1.isNotEmpty;
  }

  Advertresponse showRewardedAd(rewarded){
    return rewardedvideo.showAd(rewarded);
  }

  Widget adWidget() {
    return UnityBannerAd(
      placementId: unitymodel.bannerAdPlacementId[0],
      onLoad: (placementId) => debugPrint('Banner loaded: $placementId'),
      onClick: (placementId) => debugPrint('Banner clicked: $placementId'),
      onFailed: (placementId, error, message) =>
          debugPrint('Banner Ad $placementId failed: $error $message'),
    );
    // return BannerAd(adUnitId: bannerId ?? banner1, adSize: adsize);
  }
}

// class AdManager {
//   static String get gameId {
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       return "3717787";
//     }
//     if (defaultTargetPlatform == TargetPlatform.iOS) {
//       return '3717786';
//     }
//     return '';
//   }
//
//   static String get bannerAdPlacementId {
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       return 'newandroidbanner';
//     }
//     if (defaultTargetPlatform == TargetPlatform.iOS) {
//       return 'iOS_Banner';
//     }
//     return 'newandroidbanner';
//   }
//
//   static String get interstitialVideoAdPlacementId {
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       return 'video';
//     }
//     if (defaultTargetPlatform == TargetPlatform.iOS) {
//       return 'iOS_Interstitial';
//     }
//     return 'video';
//   }
//
//   static String get rewardedVideoAdPlacementId {
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       return 'Android_Rewarded';
//     }
//     if (defaultTargetPlatform == TargetPlatform.iOS) {
//       return 'iOS_Rewarded';
//     }
//     return 'Android_Rewarded';
//   }
// }
