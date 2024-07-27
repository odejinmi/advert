import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';

class BannerAdmob extends StatefulWidget {
  final  adUnitId;
  const BannerAdmob({Key? key, required this.adUnitId}) : super(key: key);

  @override
  BannerAdmobState createState() => BannerAdmobState();
}

class BannerAdmobState extends State<BannerAdmob> {


  final _bannerAd = [].obs;
  set bannerAd(value) => _bannerAd.value = value;
  get bannerAd => _bannerAd.value;

  var adUnitId;

  final _bannerloading = false.obs;
  set bannerloading(value) => _bannerloading.value = value;
  get bannerloading => _bannerloading.value;



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    adUnitId = widget.adUnitId;
    // if(deviceallow.allow()) {
    //   loadAd();
    // }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // if(deviceallow.allow()) {
    //   loadAd();
    // }
  }

  // @override
  // void didUpdateWidget(covariant BannerAdmob oldWidget) {
  //   // TODO: implement didUpdateWidget
  //   super.didUpdateWidget(oldWidget);
  //   addispose();
  // }

  var _numRewardedLoadAttempts = 0.obs;
  set numRewardedLoadAttempts(value) => _numRewardedLoadAttempts.value = value;
  get numRewardedLoadAttempts => _numRewardedLoadAttempts.value;

  var _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value) => _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;

  final _isloading = false.obs;
  set isLoading(value) => _isloading.value = value;
  get isLoading => _isloading.value;

  final _currentIndex = 0.obs;
  set currentIndex(value) => _currentIndex.value = value;
  get currentIndex => _currentIndex.value;

  void loadAd() {
    print("start loading banner");
    if (currentIndex >= adUnitId.length || isLoading) {
      print("some banner has been loaded");
      return; // Exit if all ads have been loaded
    }

    isLoading = true;
    var adUnitI = adUnitId[currentIndex];

    // Check if an ad already exists for the current ad unit
    if (bannerAd.any((ad) => ad.adUnitId == adUnitI)) {
      print("Ad for adUnitId $adUnitI already exists.");
      isLoading = false;
      return;
    }
      print("banner has started loading");
      var adunitid = adUnitI;
        bannerloading = true;
        BannerAd(
          adUnitId: adunitid,
          request: const AdRequest(),
          size: AdSize.largeBanner,
          listener: BannerAdListener(
              onAdLoaded: (_) {
                if (kDebugMode) {
                  print("your bannerad has been loaded");
                }
                bannerAd.add(_);
                bannerloading = false;
                currentIndex++;
                setState((){});
                // Check if there are more ads to load
                if (currentIndex < adUnitId.length) {
                  loadAd(); // Load the next ad
                }
              },
              onAdFailedToLoad: (ad, err) {
                bannerloading = false;
                numRewardedLoadAttempts += 1;
                // Retry loading the ad if the max attempts have not been reached
                if (numRewardedLoadAttempts < maxFailedLoadAttempts) {
                  loadAd();
                } else {
                  currentIndex++;

                  // Check if there are more ads to load
                  if (currentIndex < adUnitId.length) {
                    loadAd(); // Load the next ad
                  }
                }

                setState((){});
              },
              onAdWillDismissScreen: (ad){
                addispose();
              },
              onAdClosed: (ad){
                addispose();
              }
          ),
        ).load();
  }

  void addispose(){
    if(bannerAd.isNotEmpty) {
      if (kDebugMode) {
        print("dispose here");
      }
      bannerAd.first.dispose();
      bannerAd.removeAt(0);
      loadAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    if(deviceallow.allow()) {
      loadAd();
    }
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
      child: Obx(() {
        if (bannerAd.isNotEmpty && deviceallow.allow()) {
          return SizedBox(
            height: bannerAd.first.size.height.toDouble(),
            child: AdWidget(ad: bannerAd.first),
          );
        } else {
          // return SizedBox.shrink();
          return const SizedBox.shrink();
        }
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    addispose();
  }
}
