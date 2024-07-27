import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';

class Bannerad extends GetxController {
  var adUnitId;
  Bannerad(this.adUnitId);

  final _bannerAd = [].obs;
  set bannerAd(value) => _bannerAd.value = value;
  get bannerAd => _bannerAd.value;

  var _numRewardedLoadAttempts = 0.obs;
  set numRewardedLoadAttempts(value) => _numRewardedLoadAttempts.value = value;
  get numRewardedLoadAttempts => _numRewardedLoadAttempts.value;

  var _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value) => _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;

  // final adUnitId = Platform.isAndroid
  //     ? ['ca-app-pub-6117361441866120/3287545689','ca-app-pub-6117361441866120/2869480303',
  //   'ca-app-pub-6117361441866120/1364826947','ca-app-pub-6117361441866120/7738663604',
  //   'ca-app-pub-6117361441866120/8606427687']
  //     : ['ca-app-pub-6117361441866120/1488443500','ca-app-pub-6117361441866120/8620500430',
  //   'ca-app-pub-6117361441866120/3444195379','ca-app-pub-6117361441866120/7191868699',
  //   'ca-app-pub-6117361441866120/7445706489'];
  final _bannerReady = false.obs;
  set bannerReady(value) => _bannerReady.value = value;
  get bannerReady => _bannerReady.value;

  final _isloading = false.obs;
  set isloading(value) => _isloading.value = value;
  get isloading => _isloading.value;

  final _currentIndex = 0.obs;
  set currentIndex(value) => _currentIndex.value = value;
  get currentIndex => _currentIndex.value;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    listener = BannerAdListener(
        onAdLoaded: (ad) {
          isloading = false;
          print("Rewarded ad loaded: $ad");
          bannerAd.add(ad);
          numRewardedLoadAttempts = 0;
          currentIndex++;
          if (currentIndex < adUnitId.length) {
            loadAd(); // Load the next ad
          }

          if (kDebugMode) {
            print("your bannerad has been loaded");
          }
          bannerReady = true;
        },
        onAdOpened: (ad){
          addispose();
        },
        onAdFailedToLoad: (ad, err) {
          bannerReady = false;
          isloading = false;
          print("Failed to load rewarded ad: $ad, error: $err");
          numRewardedLoadAttempts += 1;
          if (numRewardedLoadAttempts < maxFailedLoadAttempts) {
            // Retry loading the specific ad unit
            loadAd();
          } else {
            currentIndex++;
            if (currentIndex < adUnitId.length) {
              loadAd(); // Load the next ad
            }
          }
        },
        onAdWillDismissScreen: (ad){
          addispose();
        },
        onAdClosed: (ad){
          addispose();
        }
    );
    // if(deviceallow.allow()) {
    //   loadAd();
    // }
  }

  void loadAd() {
    print("Start Loading rewardedAd");
    if (currentIndex >= adUnitId.length || isloading) {
      // if(show != null){
      //   show();
      // }
      return; // All ads have been loaded
    }
    isloading = true;
    print("Loading rewardedAd $currentIndex");
      var adunitid = adUnitId[currentIndex];
      BannerAd(
        adUnitId: adunitid,
        request: const AdRequest(),
        size: AdSize.largeBanner,
        listener: listener,
      ).load();
  }

  var _listener  = BannerAdListener().obs;
  set listener(value) => _listener.value = value;
  get listener => _listener.value;

  void addispose(){
    if(bannerAd.isNotEmpty) {
      if (kDebugMode) {
        print("dispose here");
      }
      // bannerAd.first.dispose();
      bannerAd.removeAt(0);
      currentIndex--;
      loadAd();
    }
  }

  Widget adWidget() {
    return Obx(() {
      if (bannerReady && deviceallow.allow()) {
        return SizedBox(
          height: bannerAd.first.size.height.toDouble(),
          child: AdWidget(ad: bannerAd.first),
        );
      } else {
        // return SizedBox.shrink();
        return const SizedBox.shrink();
      }
    });
  }

  Widget bannerAds({AdSize adsize = AdSize.banner}) {
    if(adUnitId.isNotEmpty) {
      var adunitid = adUnitId[0];
      var banner = BannerAd(
        adUnitId: adunitid,
        size: adsize,
        listener: listener,
        request: const AdRequest(),
      );
      return FutureBuilder(
        future: banner.load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            adUnitId.removeAt(0);
            adUnitId.add(adunitid);
            return SizedBox(
                height: banner.size.height.toDouble(),
                width: banner.size.width.toDouble(),
                child: AdWidget(ad: banner));
          } else {
            return const SizedBox.shrink();
          }
        },
      );
    } else{
      return SizedBox.shrink();
    }
  }

}