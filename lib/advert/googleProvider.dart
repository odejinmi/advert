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
  // var _reward = 0.obs;
  // set reward(value)=> _reward.value = value;
  // get reward => _reward.value;


  var maxfail = 3;

  var advertprovider = 2;

  var _instertialshowposition = 1.obs;
  set instertialshowposition(value) => _instertialshowposition.value = value;
  get instertialshowposition => _instertialshowposition.value;

  var _rewardshowposition = 1.obs;
  set rewardshowposition(value) => _rewardshowposition.value = value;
  get rewardshowposition => _rewardshowposition.value;

  var _instertialattempt = 0.obs;
  set instertialattempt(value) => _instertialattempt.value = value;
  get instertialattempt => _instertialattempt.value;

  var _rewardvideoattempt = 0.obs;
  set rewardvideoattempt(value) => _rewardvideoattempt.value = value;
  get rewardvideoattempt => _rewardvideoattempt.value;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    interstitiaad = Get.put(Interstitialad(googlemodel.screenUnitId), permanent: true);
    rewardedad = Get.put(Rewardedad(googlemodel.videoUnitId), permanent: true);
    nativead = Get.put(Nativead(googlemodel.nativeadUnitId), permanent: true);
    banner = Get.put(Bannerad(googlemodel.banneradadUnitId), permanent: true);
    rewardedinterstitialad = Get.put(Rewardedinterstitialad(googlemodel.rewardedinterstitialad), permanent: true);
    // counting();
  }

  loadnativead(){
    nativead.loadAd();
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

  loadrewardads(){
    loadrewardedad();
    loadrewardedinterstitialad();
  }

  get intersAd1{
    return interstitiaad.intersAd1.isNotEmpty;
  }

  get rewardedAd => rewardedad.rewardedAd.isNotEmpty;
  get rewardedinterstitialAd => rewardedinterstitialad.rewardedInterstitialAd.isNotEmpty;


  Widget shownative(){
    return nativead.showad();
  }

  Advertresponse showAd1(){
   return interstitiaad.showAd();
  }

  Advertresponse showRewardedAd(reward, Map<String, String>  customData){
    // if (rewardedinterstitialad.rewardedInterstitialAd.isEmpty ) {
    if (rewardedad.rewardedAd.isNotEmpty && rewardshowposition == 1) {
      print("rewardedad.rewardedAd.length");
      print(rewardedad.rewardedAd.length);
      rewardshowposition++;
      instertialattempt = 0;
     return rewardedad.showRewardedAd(reward, customData);
    // }else if (rewardedinterstitialad.rewardedInterstitialAd.isNotEmpty ){
    //   print("rewardedinterstitialad.rewardedInterstitialAd.length");
    //   print(rewardedinterstitialad.rewardedInterstitialAd.length);
    //   rewardshowposition ++;
    //   instertialattempt = 0;
    //  return rewardedinterstitialad.showad(reward,customData);
    }else{
      print("showRewardedAd error");
      print(instertialattempt);
      if(rewardshowposition == advertprovider) {
        rewardshowposition = 1;
      }else{
        rewardshowposition ++;
      }
      if (instertialattempt < maxfail) {
        instertialattempt ++;
        return showRewardedAd(reward,customData);
      }  else{
        instertialattempt = 0;
        return Advertresponse.defaults();
      }
    }
  }

  Advertresponse showRewardedinstertitialAd(reward, Map<String, String>  customData){
    if (rewardedad.rewardedAd.isNotEmpty) {
      return rewardedinterstitialad.showad(reward, customData);
    }else{
      print("showRewardedAd error");
      print(instertialattempt);
      if(rewardshowposition == advertprovider) {
        rewardshowposition = 1;
      }else{
        rewardshowposition ++;
      }
      if (instertialattempt < maxfail) {
        instertialattempt ++;
        return showRewardedinstertitialAd(reward,customData);
      }  else{
        instertialattempt = 0;
        return Advertresponse.defaults();
      }
    }
  }

  Widget googlebanner(){
    // return banner.bannerAds();
    return banner.adWidget();
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
