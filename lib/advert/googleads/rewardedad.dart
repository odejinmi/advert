import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../model/advertresponse.dart';
import '../device.dart';


class Rewardedad extends GetxController {
  var videoUnitId;
  Rewardedad(this.videoUnitId);

  RxList _rewardedAd = [].obs;
  set rewardedAd(value) => _rewardedAd.value = value;
  get rewardedAd => _rewardedAd.value;

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
  set isLoading(value) => _isloading.value = value;
  get isLoading => _isloading.value;

  final _currentIndex = 0.obs;
  set currentIndex(value) => _currentIndex.value = value;
  get currentIndex => _currentIndex.value;


  @override
  void onInit() {
    super.onInit();
    // if (deviceallow.allow()) {
    //   createRewardedAd();
    // }
  }

  void createRewardedAd({Function? show}) async {
    print("Start Loading rewardedAd");

    if (currentIndex >= videoUnitId.length) {
      if (show != null) {
        show();
      }
      return; // Exit if all ads have been loaded
    }

    if (isLoading) {
      return; // Prevent multiple concurrent loading attempts
    }

    isLoading = true;
    print("Loading rewardedAd $currentIndex");

    var adUnitId = videoUnitId[currentIndex];

    // Check if an ad already exists for the current ad unit
    if (rewardedAd.any((ad) => ad.adUnitId == adUnitId)) {
      print("Ad for adUnitId $adUnitId already exists.");
      isLoading = false;
      return;
    }

    await Future(() {
      RewardedAd.load(
        adUnitId: adUnitId,
        request: AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            isLoading = false;
            print("Rewarded ad loaded: $adUnitId");

            // Add the loaded ad to the rewardedAd list
            rewardedAd.add({"advert": ad, "time": DateTime.now()});
            numRewardedLoadAttempts = 0;
            currentIndex++;

            // Check if there are more ads to load
            if (currentIndex < videoUnitId.length) {
              createRewardedAd(); // Load the next ad
            }

            if (show != null) {
              show();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            isLoading = false;
            print("Failed to load rewarded ad: $adUnitId, error: $error");
            numRewardedLoadAttempts += 1;

            // Retry loading the ad if the max attempts have not been reached
            if (numRewardedLoadAttempts < maxFailedLoadAttempts) {
              createRewardedAd();
            } else {
              currentIndex++;

              // Check if there are more ads to load
              if (currentIndex < videoUnitId.length) {
                createRewardedAd(); // Load the next ad
              }
            }
          },
        ),
      );
    });
  }


  void addispose(RewardedAd ad) {
    ad.dispose();
    rewardedAd.removeWhere((element) => element['advert'] == ad);
    // rewardedAd.removeAt(0);
    currentIndex--;
    createRewardedAd(); // Load a new ad when one is disposed
  }

  Advertresponse showRewardedAd(Function? rewarded, Map<String, String>  customData) {
    if (rewardedAd.isEmpty) {
      createRewardedAd(show: showRewardedAd);
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      return Advertresponse.defaults();
    }else if(isMoreThanOneHourPast(rewardedAd[0]["time"])){
      addispose(rewardedAd[0]["advert"]);
      return showRewardedAd(rewarded, customData);
    }
    var rewarded0 = rewardedAd[0]["advert"];
    rewarded0.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
          debugPrint('Ad onAdShowedFullScreenContent.');
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
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        if (rewarded != null && givereward) {
          rewarded();
        }
        addispose(ad);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        Future.delayed(Duration(seconds: 2), () {
          showRewardedAd(rewarded, customData);
        });
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

  bool isMoreThanOneHourPast(DateTime givenTime) {
    // Get the current time
    DateTime currentTime = DateTime.now();

    // Calculate the difference in hours
    Duration difference = currentTime.difference(givenTime);

    // Check if the difference is more than 1 hour
    return difference.inHours > 1;
  }

}
