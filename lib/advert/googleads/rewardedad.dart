import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../model/advertresponse.dart';
import '../device.dart';


class Rewardedad extends GetxController {
  var videoUnitId;
  Rewardedad(this.videoUnitId);

  RxList<RewardedAd> _rewardedAd = <RewardedAd>[].obs;
  set rewardedAd(value) => _rewardedAd.value = value;
  List<RewardedAd> get rewardedAd => _rewardedAd.value;

  var _numRewardedLoadAttempts = 0.obs;
  set numRewardedLoadAttempts(value) => _numRewardedLoadAttempts.value = value;
  get numRewardedLoadAttempts => _numRewardedLoadAttempts.value;

  var _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value) => _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;

  final _givereward = false.obs;
  set givereward(value) => _givereward.value = value;
  get givereward => _givereward.value;

  final _isloading = false.obs;
  set isloading(value) => _isloading.value = value;
  get isloading => _isloading.value;

  final _currentIndex = 0.obs;
  set currentIndex(value) => _currentIndex.value = value;
  get currentIndex => _currentIndex.value;


  @override
  void onInit() {
    super.onInit();
    if (deviceallow.allow()) {
      createRewardedAd();
    }
  }

  void createRewardedAd({Function? show}) {
    print("Start Loading rewardedAd");
    if (currentIndex >= videoUnitId.length || isloading) {
      if(show != null){
        show();
      }
      return; // All ads have been loaded
    }
    isloading = true;
    print("Loading rewardedAd $currentIndex");
    var adUnitId = videoUnitId[currentIndex];
    RewardedAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          isloading = false;
          print("Rewarded ad loaded: $adUnitId");
          rewardedAd.add(ad);
          numRewardedLoadAttempts = 0;
          currentIndex++;
          if (currentIndex < videoUnitId.length) {
            createRewardedAd(); // Load the next ad
          }
          if (show != null) {
            show();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          isloading = false;
          print("Failed to load rewarded ad: $adUnitId, error: $error");
          numRewardedLoadAttempts += 1;
          if (numRewardedLoadAttempts < maxFailedLoadAttempts) {
            // Retry loading the specific ad unit
            createRewardedAd();
          } else {
            currentIndex++;
            if (currentIndex < videoUnitId.length) {
              createRewardedAd(); // Load the next ad
            }
          }
        },
      ),
    );
  }

  void addispose(RewardedAd ad) {
    rewardedAd.removeAt(0);
    currentIndex--;
    createRewardedAd(); // Load a new ad when one is disposed
  }

  Advertresponse showRewardedAd(Function? rewarded) {
    if (rewardedAd.isEmpty) {
      createRewardedAd(show: showRewardedAd);
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      return Advertresponse.defaults();
    }
    var rewarded0 = rewardedAd[0];
    rewarded0.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('Ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        if (rewarded != null && givereward) {
          rewarded();
        }
        addispose(ad);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        showRewardedAd(rewarded);
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        addispose(ad);
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
      ? 'ca-app-pub-6117361441866120~5829948546'
      : 'ca-app-pub-6117361441866120~7211527566';
}
