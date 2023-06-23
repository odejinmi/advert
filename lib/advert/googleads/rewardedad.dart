import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../model/advertresponse.dart';
import '../device.dart';


class Rewardedad extends GetxController {
  var videoUnitId;
  Rewardedad(this.videoUnitId);

  RewardedAd? rewardedAde;
  RxList<RewardedAd> _rewardedAd = <RewardedAd>[].obs;
  set rewardedAd(value)=> _rewardedAd.value = value;
  List<RewardedAd> get rewardedAd => _rewardedAd.value;


  var _numRewardedLoadAttempts = 0.obs;
  set numRewardedLoadAttempts(value)=> _numRewardedLoadAttempts.value = value;
  get numRewardedLoadAttempts => _numRewardedLoadAttempts.value;

  var _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value)=> _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;

  bool showAds = false;

  final _givereward = false.obs;
  set givereward(value)=> _givereward.value = value;
  get givereward => _givereward.value;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if(deviceallow.allow()) {
      _createRewardedAd();
    }
  }
  void _createRewardedAd() {
    for(int i =0; i < (videoUnitId.length - rewardedAd.length); i++ ) {
      var adunitid = videoUnitId[i];
      if (rewardedAd.length != videoUnitId.length) {
        RewardedAd.load(
            adUnitId: adunitid,
            // request: request,
            request: AdRequest(),
            rewardedAdLoadCallback: RewardedAdLoadCallback(
              onAdLoaded: (RewardedAd ad) {
                print("your rewardedad has been loaded");
                rewardedAd.add(ad);
                numRewardedLoadAttempts = 0;
              },
              onAdFailedToLoad: (LoadAdError error) {
                numRewardedLoadAttempts += 1;
                if (numRewardedLoadAttempts < maxFailedLoadAttempts) {
                  _createRewardedAd();
                }
              },
            ));
      }
    }

  }

  void addispose(RewardedAd ad){
    rewardedAd.remove(ad);
    ad.dispose();
    _createRewardedAd();
  }

  Advertresponse showRewardedAd(Function? rewarded) {
    if (rewardedAd.isEmpty) {
      debugPrint('Warning: attempt to show rewarded before loaded.');
      return Advertresponse.defaults();
    }
    var rewarded0 = rewardedAd.first;
    rewarded0.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        addispose(ad);
        _createRewardedAd();
        if (rewarded != null && givereward) {
          rewarded();
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        addispose(ad);
        _createRewardedAd();
      },
    );

    rewarded0.setImmersiveMode(true);
    rewarded0.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      debugPrint('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
      givereward = true;
    });
    return Advertresponse.showing();
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