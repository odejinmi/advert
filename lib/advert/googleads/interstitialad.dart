import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../model/advertresponse.dart';
import '../device.dart';


class Interstitialad extends GetxController {
  var screenUnitId;
  Interstitialad(this.screenUnitId);


  var _intersAd1 = [].obs;
  set intersAd1(value)=> _intersAd1.value = value;
  get intersAd1 => _intersAd1.value;

  var _numInterstitialLoadAttempts = 0.obs;
  set numInterstitialLoadAttempts(value)=> _numInterstitialLoadAttempts.value = value;
  get numInterstitialLoadAttempts => _numInterstitialLoadAttempts.value;

  var _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value)=> _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;

  final _currentIndex = 0.obs;
  set currentIndex(value) => _currentIndex.value = value;
  get currentIndex => _currentIndex.value;

  final _isloading = false.obs;
  set isloading(value) => _isloading.value = value;
  get isloading => _isloading.value;

  bool showAds = false;

  void createInterstitialAd({Function? show}) {
    if (currentIndex >= screenUnitId.length || isloading) {
      if(show != null){
        show();
      }
      return; // All ads have been loaded
    }
    isloading = true;
    print("Loading rewardedAd $currentIndex");
      var adunitid = screenUnitId[currentIndex];
      InterstitialAd.load(
            adUnitId: adunitid,
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (InterstitialAd ad) {
                isloading = false;
                print("your interstitialad has been loaded");
                intersAd1.add(ad);
                numInterstitialLoadAttempts = 0;
                currentIndex++;
                if (currentIndex < screenUnitId.length) {
                  createInterstitialAd(); // Load the next ad
                }
              },
              onAdFailedToLoad: (LoadAdError error) {
                isloading = false;
                // googleinstatialfailed = true;
                numInterstitialLoadAttempts += 1;
                if (numInterstitialLoadAttempts < maxFailedLoadAttempts) {
                  createInterstitialAd();
                } else {
                  currentIndex++;
                  if (currentIndex < screenUnitId.length) {
                    createInterstitialAd(); // Load the next ad
                  }
                }
              },
            ));

  }

  void addispose(InterstitialAd ad){
    // intersAd1.remove(ad);
    intersAd1.removeAt(0);
    currentIndex--;
    ad.dispose();
    createInterstitialAd();
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

    var intersAd0 = intersAd1[0];
    // Keep a reference to the ad so you can show it later.
    intersAd0.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {},
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        intersAd1.remove(ad);
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        addispose(ad);
      },
    );

    intersAd0.setImmersiveMode(true);
    intersAd0.show();

      return Advertresponse.showing();
  }

}