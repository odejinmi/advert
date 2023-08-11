
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../../model/advertresponse.dart';
import '../device.dart';

class Rewardedvideo extends GetxController {
  var videoUnitId;
  Rewardedvideo(this.videoUnitId);

  final _intersAd1 = [].obs;
  set intersAd1(value)=> _intersAd1.value = value;
  get intersAd1 => _intersAd1.value;

  final _numInterstitialLoadAttempts = 0.obs;
  set numInterstitialLoadAttempts(value)=> _numInterstitialLoadAttempts.value = value;
  get numInterstitialLoadAttempts => _numInterstitialLoadAttempts.value;

  final _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value)=> _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;

  bool showAds = false;

  void createInterstitialAd() {
    for(int i =0;i < (videoUnitId.length - intersAd1.length); i++ ) {
      print("we are loading");
      var adunitid = videoUnitId[i];
      if (videoUnitId.length != intersAd1.length) {
        UnityAds.load(
          placementId: adunitid,
          onComplete: (placementId) {
            debugPrint('Load Complete $placementId');
            intersAd1.add(placementId);
            update();
          },
          onFailed: (placementId, error, message) =>
              debugPrint('Load Failed $placementId: $error $message'),
        );
      }
    }
  }


  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if(deviceallow.allow()) {
      createInterstitialAd();
    }
  }

  Advertresponse showAd(Function? rewarded){
    if (intersAd1.isNotEmpty) {
      UnityAds.showVideoAd(
        placementId: intersAd1.first,
        onComplete: (placementId) {
          debugPrint('Video Ad $placementId completed');
          createInterstitialAd();
          if (rewarded != null) {
            rewarded();
          }
          return Advertresponse.showing();
        },
        onFailed: (placementId, error, message) {
          debugPrint('Video Ad $placementId failed: $error $message');
          createInterstitialAd();
          return Advertresponse.defaults();
        },
        onStart: (placementId) {
          debugPrint('Video Ad $placementId started');
          return Advertresponse.defaults();
        },
        onClick: (placementId) {
          debugPrint('Video Ad $placementId click');
          return Advertresponse.defaults();
        },
        onSkipped: (placementId) {
          debugPrint('Video Ad $placementId skipped');
          createInterstitialAd();
          return Advertresponse.defaults();
        },
      );
      return Advertresponse.showing();
    } else {
      createInterstitialAd();
      return Advertresponse.defaults();
    }
  }


  static String get appId => Platform.isAndroid
  // old
  // ? 'ca-app-pub-6117361441866120~5829948546'
  // ? 'ca-app-pub-1598206053668309~2044155939'
      ? 'ca-app-pub-6117361441866120~5829948546'
  // : 'ca-app-pub-3940256099942544~1458002511';
  // : 'ca-app-pub-1598206053668309~7710581439';
      : 'ca-app-pub-6117361441866120~7211527566';

// static String get videoUnitId => Platform.isAndroid
// // ? 'ca-app-pub-3940256099942544/5224354917'
// // ? 'ca-app-pub-1598206053668309/5275989781'
//     ? 'ca-app-pub-6117361441866120/4412338366'
// // : 'ca-app-pub-1598206053668309/3667378733';
//     : 'ca-app-pub-6117361441866120/2609953488';
}