import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/adsmodel.dart';
import '../model/advertresponse.dart';
import 'adcolonyProvider.dart';
import 'googleProvider.dart';
import 'googleads/banner_admob.dart';
import 'unityprovider.dart';
import 'device.dart';

class AdsProv extends GetxController {
  Adsmodel adsmodel;
  AdsProv(this.adsmodel);
  // Future<InitializationStatus> initialization;
  // AdsProvider(this.initialization);
  // static var initFuture = MobileAds.instance.initialize();
  // static var adstate = AdsProvider(initFuture);

  var unity;
  var adcolony = Get.put(AdcolonyProvider(), permanent: true);
  var googleadvert;
  var advertshow = 0.obs;
  var advertrewardshow = 0.obs;
  var unityplayed = false.obs;
  var googleplayed = false.obs;
  var adcolonyplayed = false.obs;
  var unitybannerplayed = false.obs;
  var googlebannerplayed = false.obs;
  var adcolonybannerplayed = false.obs;
  
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if (adsmodel.googlemodel != null) {
      googleadvert =
          Get.put(GoogleProvider(adsmodel.googlemodel!), permanent: true);
    }
    if (adsmodel.unitymodel!=null) {
      unity = Get.put(UnityProvider(adsmodel.unitymodel!), permanent: true);
    }
  }

  Advertresponse showads() {
      // if (unity.placements[AdManager.rewardedVideoAdPlacementId] == true &&
      //     unityplayed.isFalse) {
      //   unity.showAd(AdManager.rewardedVideoAdPlacementId, null);
      //   advertshow.value = 1;
      //   unityplayed.value = true;
      //   googleplayed.value = false;
      //   adcolonyplayed.value = false;
      // } else if (await adcolony.isloaded() && adcolonyplayed.isFalse) {
      //   adcolony.show(null);
      //   advertshow.value = 2;
      //   unityplayed.value = false;
      //   googleplayed.value = false;
      //   adcolonyplayed.value = true;
      // } else if (googleadvert.intersAd1 && googleplayed.isFalse) {
        advertshow.value = 0;
        adcolonyplayed.value = false;
        unityplayed.value = false;
        googleplayed.value = true;
        return googleadvert.showAd1();
      // } else {
      //   adcolonyplayed.value = false;
      //   unityplayed.value = false;
      //   googleplayed.value = false;
      //   advertshow.value = 0;
      //   showads();
      // }
  }

  Widget shownativeads(){
      return googleadvert.shownative();
  }

  Advertresponse  showreawardads(Function reward) {
      // if (unity.placements[AdManager.rewardedVideoAdPlacementId] == true &&
      //     unityplayed.isFalse) {
      //   unity.showAd(AdManager.rewardedVideoAdPlacementId, reward);
      //   advertrewardshow.value = 1;
      //   adcolonyplayed.value = false;
      //   unityplayed.value = true;
      //   googleplayed.value = false;
      // } else if (googleadvert.rewardedAd && googleplayed.isFalse) {
        advertrewardshow.value = 2;
        adcolonyplayed.value = false;
        unityplayed.value = false;
        googleplayed.value = true;
        return googleadvert.showRewardedAd(reward);
      // } else if (await adcolony.isloaded() && adcolonyplayed.isFalse) {
      //   adcolony.show(reward);
      //   advertrewardshow.value = 3;
      //   adcolonyplayed.value = true;
      //   unityplayed.value = false;
      //   googleplayed.value = false;
      // } else {
      //   adcolonyplayed.value = false;
      //   unityplayed.value = false;
      //   googleplayed.value = false;
      //   advertrewardshow.value = 0;
      //   showreawardads(reward);
      // }

  }

  get isvideoready => googleadvert.rewardedAd ||unity.rewardvideoloaded;
  Widget banner() {
      // return adcolony.banner();
      switch (slideIndex.value) {
        case 0:
          if(deviceallow.allow()) {
          return unity.adWidget();
          }else{
            return const SizedBox.shrink();
          }
      // case 1:
      //     if(deviceallow.allow() && network.isonline.isTrue) {
      //   return adcolony.banner();
      //     }else{
      //       return SizedBox.shrink();
      //     }
        case 1:
        if(deviceallow.allow()) {
          return BannerAdmob();
        }else{
          return const SizedBox.shrink();
        }
        default:
          return const SizedBox.shrink();
      }

  }

  var slideIndex = 1.obs;

  void counting() {
    Future.delayed(const Duration(seconds: 30), () async {
      // if (unity.placements[AdManager.bannerAdPlacementId] == true &&
      //     unitybannerplayed.isFalse) {
      //   slideIndex.value = 1;
      //   adcolonybannerplayed.value = false;
      //   unitybannerplayed.value = true;
      //   googlebannerplayed.value = false;
      //   // } else if (await adcolony.isloaded() && adcolonybannerplayed.isFalse) {
      //   //   slideIndex.value = 2;
      //   //   adcolonybannerplayed.value = true;
      //   //   unitybannerplayed.value = false;
      //   //   googlebannerplayed.value = false;
      // } else if (googlebannerplayed.isFalse) {
      //   slideIndex.value = 0;
      //   adcolonybannerplayed.value = false;
      //   unitybannerplayed.value = false;
      //   googlebannerplayed.value = true;
      // }
      if (slideIndex.value == 1) {
        slideIndex.value = 0;
      } else {
        slideIndex.value += 1;
      }
      counting();
    });
  }

}
