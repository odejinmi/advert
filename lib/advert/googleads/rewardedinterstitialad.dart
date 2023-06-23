import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../networks.dart';
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

  // TODO: replace this test ad unit with your own ad unit.
  // final adUnitId = Platform.isAndroid
  //     ? ['ca-app-pub-6117361441866120/4577116553','ca-app-pub-6117361441866120/8484737245',
  //   'ca-app-pub-6117361441866120/6343473849','ca-app-pub-6117361441866120/9711555987',
  //   'ca-app-pub-6117361441866120/1829513768']
  //     : ['ca-app-pub-6117361441866120/6040874481','ca-app-pub-6117361441866120/6516215303',
  //   'ca-app-pub-6117361441866120/7437063663','ca-app-pub-6117361441866120/7254581909',
  //   'ca-app-pub-6117361441866120/8558573648'];

  var network = Get.put(Networks());
  @override
  void onInit() {
    super.onInit();
    if(deviceallow.allow() && network.isonline.isTrue) {
      loadAd();
    }
  }

  void loadAd() {
    for(int i =0; i < (adUnitId.length - rewardedInterstitialAd.length); i++ ) {
      var adunitid = adUnitId[i];
      if (rewardedInterstitialAd.length != adUnitId.length) {
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
                      loadAd();
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
                      // Dispose the ad here to free resources.
                      addispose(ad);
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
      }
    }
  }


  void addispose(RewardedInterstitialAd ad){
    rewardedInterstitialAd.remove(ad);
    ad.dispose();
    loadAd();
  }

  void showad(Function? rewarded){
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
        print(rewardedInterstitialAd.length);
       rewarded0.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
              // Reward the user for watching an ad.
              givereward = true;
              if (rewarded != null && givereward) {
                rewarded();
              }
            });
    }else{
      loadAd();
      print("kindly check your network");
    }
  }
}