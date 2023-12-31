import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/advertresponse.dart';
import '../model/google.dart';
import 'googleads/bannerad.dart';
import 'googleads/interstitialad.dart';
import 'googleads/nativead.dart';
import 'googleads/rewardedad.dart';
import 'googleads/rewardedinterstitialad.dart';

class GoogleProvider extends GetxController {
  Googlemodel googlemodel;
  GoogleProvider(this.googlemodel);

  var interstitiaad;
  var rewardedad;
  var nativead;
  var banner;
  var rewardedinterstitialad;
  var _reward = 0.obs;
  set reward(value)=> _reward.value = value;
  get reward => _reward.value;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    interstitiaad = Get.put(Interstitialad(googlemodel.screenUnitId), permanent: true);
    rewardedad = Get.put(Rewardedad(googlemodel.videoUnitId), permanent: true);
    nativead = Get.put(Nativead(googlemodel.nativeadUnitId), permanent: true);
    banner = Get.put(Bannerad(googlemodel.banneradadUnitId), permanent: true);
    rewardedinterstitialad = Get.put(Rewardedinterstitialad(googlemodel.adUnitId), permanent: true);
    // counting();
  }

  loadinterrtitialad(){
    interstitiaad.createInterstitialAd();
  }
  loadrewardedad(){
    rewardedad.createRewardedAd();
  }
  loadrewardedinterstitialad(){
    rewardedinterstitialad.loadAd();
  }
  get rewardedInterstitialAd{
    return rewardedinterstitialad.rewardedInterstitialAd;
  }

  get intersAd1{
    return interstitiaad.intersAd1.isNotEmpty;
  }

  get rewardedAd{
    if (rewardedad.rewardedAd != null) {
      return true;
    }  else if (rewardedinterstitialad.rewardedInterstitialAd.isNotEmpty) {
      return true;
    }  else {
      return false;
    }
  }

  Widget shownative(){
    return nativead.showad();
  }

  Advertresponse showAd1(){
   return interstitiaad.showAd();
  }

  Advertresponse showRewardedAd(reward){
    // if (rewardedinterstitialad.rewardedInterstitialAd.isEmpty ) {
    if (rewardedad.rewardedAd.isNotEmpty ) {
     return rewardedad.showRewardedAd(reward);
    }else if (rewardedinterstitialad.rewardedInterstitialAd.isNotEmpty ){
     return rewardedinterstitialad.showad(reward);
    }else{
      return Advertresponse.defaults();
    }
  }

  Advertresponse showRewardedinstertitialAd(reward){
   return rewardedinterstitialad.showad(reward);
  }

  Widget googlebanner(){
    return banner.bannerAds();
  }

  bool showAds = false;
  bool _footerBannerShow = false;
  dynamic _bannerAd;

  set footBannerShow(bool value) {
    _footerBannerShow = value;
    update();
  }

  // bool get footBannerShow => !showAds ? false : _footerBannerShow;

  get bannerIsAvailable => _bannerAd != null;

  // void removeBanner() {
  //   banner.addispose();
  // }


  static String get appId => Platform.isAndroid
      // old
      // ? 'ca-app-pub-6117361441866120~5829948546'
      // ? 'ca-app-pub-1598206053668309~2044155939'
      ? 'ca-app-pub-6117361441866120~5829948546'
      // : 'ca-app-pub-3940256099942544~1458002511';
      // : 'ca-app-pub-1598206053668309~7710581439';
      : 'ca-app-pub-6117361441866120~7211527566';

}
