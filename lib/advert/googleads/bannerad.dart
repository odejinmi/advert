import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';
import '../networks.dart';

class Bannerad extends GetxController {
  var adUnitId;
  Bannerad(this.adUnitId);
  var _bannerAd = [].obs;
  set bannerAd(value) => _bannerAd.value = value;
  get bannerAd => _bannerAd.value;

  // final adUnitId = Platform.isAndroid
  //     ? ['ca-app-pub-6117361441866120/3287545689','ca-app-pub-6117361441866120/2869480303',
  //   'ca-app-pub-6117361441866120/1364826947','ca-app-pub-6117361441866120/7738663604',
  //   'ca-app-pub-6117361441866120/8606427687']
  //     : ['ca-app-pub-6117361441866120/1488443500','ca-app-pub-6117361441866120/8620500430',
  //   'ca-app-pub-6117361441866120/3444195379','ca-app-pub-6117361441866120/7191868699',
  //   'ca-app-pub-6117361441866120/7445706489'];
  var _bannerReady = false.obs;
  set bannerReady(value) => _bannerReady.value = value;
  get bannerReady => _bannerReady.value;

  var network = Get.put(Networks());
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if(deviceallow.allow() && network.isonline.isTrue) {
      loadAd();
    }
  }

  void loadAd() {
    for(int i =0;i < (adUnitId.length - bannerAd.length); i++ ) {
      var adunitid = adUnitId[i];
      if (bannerAd.length != adUnitId.length) {
        bannerAd.add(BannerAd(
          adUnitId: adunitid,
          request: const AdRequest(),
          size: AdSize.largeBanner,
          listener: BannerAdListener(
            onAdLoaded: (_) {

              print("your bannerad has been loaded");
                bannerReady = true;
            },
            onAdFailedToLoad: (ad, err) {
                bannerReady = false;
                loadAd();
            },
            onAdWillDismissScreen: (ad){
              addispose();
            },
            onAdClosed: (ad){
              addispose();
        }
          ),
        ));
        bannerAd[i].load();
      }
    }///08084490201 my airtel number
  }

  void addispose(){
    if(bannerAd.isNotEmpty) {
      print("dispose here");
      bannerAd.first.dispose();
      bannerAd.removeAt(0);
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
}