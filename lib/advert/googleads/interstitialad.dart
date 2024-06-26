import 'dart:async';
import 'dart:io';

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

  bool showAds = false;

  void createInterstitialAd() {
    for(int i =0;i < screenUnitId.length; i++ ) {
      var adunitid = screenUnitId[i];
      InterstitialAd.load(
            adUnitId: adunitid,
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (InterstitialAd ad) {
                print("your interstitialad has been loaded");
                // Keep a reference to the ad so you can show it later.
                ad.fullScreenContentCallback = FullScreenContentCallback(
                  onAdShowedFullScreenContent: (InterstitialAd ad) {},
                  onAdDismissedFullScreenContent: (InterstitialAd ad) {
                    intersAd1.remove(ad);
                    ad.dispose();
                  },
                  onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                    addispose(ad);
                  },
                );
                intersAd1.add(ad);
              },
              onAdFailedToLoad: (LoadAdError error) {
                // googleinstatialfailed = true;
                numInterstitialLoadAttempts += 1;
                if (numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
                  createInterstitialAd();
                }
              },
            ));
    }
  }

  void addispose(InterstitialAd ad){
    intersAd1.remove(ad);
    ad.dispose();
    update();
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
    if (intersAd1.isNotEmpty) {
      intersAd1.first.show();
      return Advertresponse.showing();
    } else {
      createInterstitialAd();
      return Advertresponse.defaults();
    }
  }

}