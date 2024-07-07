
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../../model/advertresponse.dart';
import '../device.dart';

class Unityinterstitialad extends GetxController {
  var screenUnitId;
  Unityinterstitialad(this.screenUnitId);

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

  final _isloading = false.obs;
  set isloading(value) => _isloading.value = value;
  get isloading => _isloading.value;

  final _currentIndex = 0.obs;
  set currentIndex(value) => _currentIndex.value = value;
  get currentIndex => _currentIndex.value;


  void createInterstitialAd({Function? show}) {
    print("Start Loading rewardedAd");
    if (currentIndex >= screenUnitId.length || isloading) {
      if(show != null){
        show();
      }
      return; // All ads have been loaded
    }
    isloading = true;
    // for(int i =0;i < (screenUnitId.length - intersAd1.length); i++ ) {
      var adunitid = screenUnitId[currentIndex];
      // if (screenUnitId.length != intersAd1.length) {
        UnityAds.load(
          placementId: adunitid,
          onComplete: (placementId) {
            debugPrint('Load Complete $placementId');
            isloading = false;
            intersAd1.add(placementId);
            numInterstitialLoadAttempts = 0;
            currentIndex++;
            if (currentIndex < screenUnitId.length) {
              createInterstitialAd(); // Load the next ad
            }
            if (show != null) {
              show();
            }
          },
          onFailed: (placementId, error, message) {
              debugPrint('Load Failed $placementId: $error $message');
              isloading = false;
              print("Failed to load rewarded ad: $placementId, error: $error");
              numInterstitialLoadAttempts += 1;
              if (numInterstitialLoadAttempts < maxFailedLoadAttempts) {
                // Retry loading the specific ad unit
                createInterstitialAd();
              } else {
                currentIndex++;
                if (currentIndex < intersAd1.length) {
                  createInterstitialAd(); // Load the next ad
                }
              }
          },

        );
      // }
    // }
  }


  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if(deviceallow.allow()) {
      createInterstitialAd();
    }
  }

  Advertresponse showAd(){
    if (intersAd1.isEmpty) {
      createInterstitialAd(show: showAd);
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      return Advertresponse.defaults();
    }
    UnityAds.showVideoAd(
      placementId: intersAd1[0],
      onComplete: (placementId) {
        debugPrint('Video Ad $placementId completed');
        addispose(placementId);
        return Advertresponse.showing();
      },
      onFailed: (placementId, error, message) {
        debugPrint('Video Ad $placementId failed: $error $message');
        addispose(placementId);
        return Advertresponse.defaults();
      },
      onStart: (placementId) {
        addispose(placementId);
        debugPrint('Video Ad $placementId started');
        return Advertresponse.defaults();
      },
      onClick: (placementId) {
        debugPrint('Video Ad $placementId click');
        return Advertresponse.defaults();
      },
      onSkipped: (placementId) {
        debugPrint('Video Ad $placementId skipped');
        addispose(placementId);
        return Advertresponse.defaults();
      },
    );
    return Advertresponse.showing();
  }


  void addispose(String ad) {
    intersAd1.removeAt(0);
    currentIndex--;
    createInterstitialAd(); // Load a new ad when one is disposed
  }
}