import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../model/advertresponse.dart';
import '../device.dart';

class Rewardedinterstitialad extends GetxController {
  final adUnitId;
  Rewardedinterstitialad(this.adUnitId);

  RxList<RewardedInterstitialAd> _rewardedInterstitialAd = <RewardedInterstitialAd>[].obs;
  set rewardedInterstitialAd(value) => _rewardedInterstitialAd.value = value;
  List<RewardedInterstitialAd> get rewardedInterstitialAd => _rewardedInterstitialAd.value;

  var _numRewardedLoadAttempts = 0.obs;
  set numRewardedLoadAttempts(value) => _numRewardedLoadAttempts.value = value;
  get numRewardedLoadAttempts => _numRewardedLoadAttempts.value;

  var _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value) => _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;

  final _givereward = false.obs;
  set givereward(value) => _givereward.value = value;
  get givereward => _givereward.value;

  final _isshowed = false.obs;
  set isshowed(value) => _isshowed.value = value;
  get isshowed => _isshowed.value;

  final _isloading = false.obs;
  set isloading(value) => _isloading.value = value;
  get isloading => _isloading.value;

  final _currentIndex = 0.obs;
  set currentIndex(value) => _currentIndex.value = value;
  get currentIndex => _currentIndex.value;


  @override
  void onInit() {
    super.onInit();
    // if (deviceallow.allow()) {
    //   loadAd();
    // }
  }

  void loadAd({Function? show}) async {
    print("Start Loading rewardedInterstitialAd");
    if (currentIndex >= this.adUnitId.length) {
      if(show != null){
        show();
      }
      return; // All ads have been loaded
    }
    if ( isloading) {
      return; // All ads have been loaded
    }
    isloading = true;
    print("Loading rewardedInterstitialAd $currentIndex");
    var adUnitId = this.adUnitId[currentIndex];
    // Check if an ad already exists for the current ad unit
    if (rewardedInterstitialAd.any((ad) => ad.adUnitId == adUnitId)) {
      print("Ad for adUnitId $adUnitId already exists.");
      isloading = false;
      return;
    }
    await Future(() {
      RewardedInterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (show != null) {
              show();
            }
            isloading = false;
            print("RewardedInterstitialAd loaded: $adUnitId");
            rewardedInterstitialAd.add(ad);
            currentIndex++;
            // if (currentIndex < adUnitId.length) {
            //   loadAd(show: showad);
            // }
          },
          onAdFailedToLoad: (LoadAdError error) {
            isloading = false;
            debugPrint('RewardedInterstitialAd failed to load: $error');
            numRewardedLoadAttempts += 1;
            if (numRewardedLoadAttempts < maxFailedLoadAttempts) {
              loadAd(); // Retry loading the ad
            } else {
              currentIndex++;
              if (currentIndex < adUnitId.length) {
                loadAd();
              }
            }
          },
        ),
      );
    });
  }

  void addispose() {
    if (rewardedInterstitialAd.isNotEmpty) {
      rewardedInterstitialAd.removeAt(0);
      currentIndex --;
    }
    if (currentIndex < adUnitId.length) {
      loadAd(); // Load the next ad if there are more to load
    }
  }

  Advertresponse showad(Function? rewarded, Map<String, String>  customData) {
    if (rewardedInterstitialAd.isNotEmpty) {
      var rewarded0 = rewardedInterstitialAd[0];
      print("Showing rewardedInterstitialAd");
      // addispose();
      rewarded0.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          // if (rewarded != null && givereward) {
          //   rewarded();
          // }
          // givereward = false;
        },
        onAdShowedFullScreenContent: (ad) {
          // var customData = {
          //   "username": "",
          //   "platform": "",
          //   "type": ""
          // };
          ServerSideVerificationOptions options = ServerSideVerificationOptions(
            customData: jsonEncode(customData),
          );
          ad.setServerSideOptions(options);
        },
        onAdFailedToShowFullScreenContent: (ad,aderror) {
          debugPrint("rewardedInterstitialAd fail to show $ad");
          Future.delayed(Duration(seconds: 2), () {
            return showad(rewarded,customData);
          });
        },
        onAdClicked: (ad) {},
      );
      rewarded0.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          givereward = true;
          if (rewarded != null && givereward) {
            rewarded();
          }
        },
      );
      return Advertresponse.showing();
    } else {
      loadAd(show: showad);
      debugPrint("Please check your network");
      return Advertresponse.defaults();
    }
  }
}
