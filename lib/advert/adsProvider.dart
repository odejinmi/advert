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
  var maxfail = 3;
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
    if (adsmodel.googlemodel != null) {
      googleadvert =
          Get.put(GoogleProvider(adsmodel.googlemodel!), permanent: true);
    }
    if (adsmodel.unitymodel!=null) {
      unity = Get.put(UnityProvider(adsmodel.unitymodel!), permanent: true);
    }
  }

  loadinterrtitialad(){
    googleadvert.loadinterrtitialad();
  }
  loadrewardedad(){
    googleadvert.loadrewardedad();
  }
  loadrewardedinterstitialad(){
    googleadvert.loadrewardedinterstitialad();
  }
  Advertresponse showads() {
      if (unity!= null && unity.unityintersAd1 && unityplayed.isFalse) {
        advertshow.value = 1;
        unityplayed.value = true;
        googleplayed.value = false;
        adcolonyplayed.value = false;
        return unity.showAd1();
      // } else if (await adcolony.isloaded() && adcolonyplayed.isFalse) {
      //   adcolony.show(null);
      //   advertshow.value = 2;
      //   unityplayed.value = false;
      //   googleplayed.value = false;
      //   adcolonyplayed.value = true;
      } else if (googleadvert!= null && googleadvert.intersAd1 && googleplayed.isFalse) {
        advertshow.value = 0;
        adcolonyplayed.value = false;
        unityplayed.value = false;
        googleplayed.value = true;
        return googleadvert.showAd1();
      } else {
        adcolonyplayed.value = false;
        unityplayed.value = false;
        googleplayed.value = false;
        advertshow.value = 0;
        if (instertialattempt < maxfail) {
            instertialattempt += 1;
          return showads();
        }  else{
          instertialattempt = 0;
          return Advertresponse.defaults();
        }
      }
  }

  Widget shownativeads(){
    return Container();
      return googleadvert.shownative();
  }

  Advertresponse  showreawardads(Function reward) {
      if (unity != null && unity.unityrewardedAd && unityplayed.isFalse) {
        advertrewardshow.value = 1;
        adcolonyplayed.value = false;
        unityplayed.value = true;
        googleplayed.value = false;
        return unity.showRewardedAd(reward);
      } else if (googleadvert != null && googleadvert.rewardedAd && googleplayed.isFalse) {
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
      } else {
        adcolonyplayed.value = false;
        unityplayed.value = false;
        googleplayed.value = false;
        advertrewardshow.value = 0;
        if (instertialattempt < maxfail) {
          instertialattempt += 1;
        return showreawardads(reward);
        }  else{
          instertialattempt = 0;
          return Advertresponse.defaults();
        }
      }

  }

  get isvideoready => googleadvert.rewardedAd ||unity?.rewardvideoloaded;
  Widget banner() {
      // return adcolony.banner();
      switch (slideIndex.value) {
        case 0:
          if(deviceallow.allow()) {
          return unity!.adWidget();
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
          // return BannerAdmob(adUnitId: adsmodel.googlemodel!.banneradadUnitId,);
          return googleadvert.googlebanner();
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
