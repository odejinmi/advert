import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';
import '../device.dart';

class Rewardedinterstitialad extends GetxController {
  final adUnitId ;
  Rewardedinterstitialad(this.adUnitId);

  RxList<RewardedInterstitialAd> _rewardedInterstitialAd = <RewardedInterstitialAd>[].obs;
  set rewardedInterstitialAd(value)=> _rewardedInterstitialAd.value = value;
  List<RewardedInterstitialAd> get rewardedInterstitialAd => _rewardedInterstitialAd.value;

  var _numRewardedLoadAttempts = 0.obs;
  set numRewardedLoadAttempts(value)=> _numRewardedLoadAttempts.value = value;
  get numRewardedLoadAttempts => _numRewardedLoadAttempts.value;

  var _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value)=> _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;


  final _givereward = false.obs;
  set givereward(value)=> _givereward.value = value;
  get givereward => _givereward.value;

  final _isshowed = false.obs;
  set isshowed(value)=> _isshowed.value = value;
  get isshowed => _isshowed.value;


  @override
  void onInit() {
    super.onInit();
    // if(deviceallow.allow()) {
    //   loadAd();
    // }
  }

  void loadAd() {
    // for(int i =0; i < (adUnitId.length - rewardedInterstitialAd.length); i++ ) {
      var adunitid = adUnitId[0];
      // if (rewardedInterstitialAd.length != adUnitId.length) {
        RewardedInterstitialAd.load(
            adUnitId: adunitid,
            request: const AdRequest(),
            rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
              // Called when an ad is successfully received.
              onAdLoaded: (ad) {
                print("your rewardedinterstitialad has been loaded");
                ad.fullScreenContentCallback = FullScreenContentCallback(
                  // Called when the ad showed the full screen content.
                    onAdShowedFullScreenContent: (ad) {
                      debugPrint('RewardedInterstitialAd had a show: ${ad
                          .onUserEarnedRewardCallback}');
                      // loadAd();
                    },
                    // Called when an impression occurs on the ad.
                    onAdImpression: (ad) {
                      debugPrint('RewardedInterstitialAd had a impression: ${ad
                          .onUserEarnedRewardCallback}');
                    },
                    // Called when the ad failed to show full screen content.
                    onAdFailedToShowFullScreenContent: (ad, err) {
                      // Dispose the ad here to free resources.
                      debugPrint('RewardedInterstitialAd had failed to show: ${ad
                          .onUserEarnedRewardCallback}');
                      addispose(ad);
                    },
                    // Called when the ad dismissed full screen content.
                    onAdDismissedFullScreenContent: (ad) {
                      // // Dispose the ad here to free resources.
                      // addispose(ad);
                    });
                debugPrint('$ad loaded.');
                // Keep a reference to the ad so you can show it later.
                rewardedInterstitialAd.add(ad);
              },
              // Called when an ad request failed.
              onAdFailedToLoad: (LoadAdError error) {
                debugPrint('RewardedInterstitialAd failed to load: $error');
                numRewardedLoadAttempts += 1;
                if (numRewardedLoadAttempts < maxFailedLoadAttempts) {
                  loadAd();
                }
              },
            ));
    //   }
    // }
  }


  void addispose(RewardedInterstitialAd ad){
    rewardedInterstitialAd.remove(ad);
    ad.dispose();
    loadAd();
  }

  Advertresponse showad(Function? rewarded){
    if (rewardedInterstitialAd.isNotEmpty) {
       var rewarded0 = rewardedInterstitialAd.first;
       print("rewardedinterstitialadmpose");
       rewarded0.fullScreenContentCallback = FullScreenContentCallback(
            // Called when the ad dismissed full screen content.
            onAdDismissedFullScreenContent: (ad) {
              // Dispose the ad here to free resources.

              if (rewarded != null && givereward) {
                rewarded();
              }
              givereward = false;
            },
            // Called when a click is recorded for an ad.
            onAdClicked: (ad) {});
       rewarded0.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
              // Reward the user for watching an ad.
              givereward = true;
              if (rewarded != null && givereward) {
                rewarded();
              }
            });
       return Advertresponse.showing();
    }else{
      loadAd();
      debugPrint("kindly check your network");
      return Advertresponse.defaults();
    }
  }
}