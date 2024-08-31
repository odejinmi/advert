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
  var _instertialshowposition = 1.obs;
  set instertialshowposition(value) => _instertialshowposition.value = value;
  get instertialshowposition => _instertialshowposition.value;

  var _rewardshowposition = 1.obs;
  set rewardshowposition(value) => _rewardshowposition.value = value;
  get rewardshowposition => _rewardshowposition.value;

  var maxfail = 3;
  var advertprovider = 3;

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

  Future<Advertresponse> showads() async {
    unity.loadinterrtitialad();
    googleadvert.loadinterrtitialad();
      if (unity!= null && unity.unityintersAd1) {
        instertialshowposition ++;
        return unity.showAd1();
      // } else if (await adcolony.isloaded() && adcolonyplayed.isFalse) {
      //   adcolony.show(null);
      //   advertshow.value = 2;
      //   unityplayed.value = false;
      //   googleplayed.value = false;
      //   adcolonyplayed.value = true;
      } else if (googleadvert!= null && googleadvert.intersAd1 ) {
        instertialshowposition ++;
        return googleadvert.showAd1();
      } else {
        if (instertialattempt < maxfail) {
          if(instertialshowposition == advertprovider) {
            instertialshowposition = 1;
          }else{
            instertialshowposition ++;
          }
            instertialattempt ++;
            await Future.delayed(Duration(seconds: 1));
          return showads();
        }  else{
          instertialattempt = 0;
          return Advertresponse.defaults();
        }
      }
  }

  Widget shownativeads(){
    return Container();
    googleadvert.loadnativead();
      return googleadvert.shownative();
  }

  Future<Advertresponse>  showreawardads(Function reward, Map<String, String>  customData, int interver) async {
    unity.loadrewardedad();
    googleadvert.loadrewardads();
      if (unity != null && unity.unityrewardedAd && rewardshowposition == 1) {
        rewardvideoattempt = 0;
        rewardshowposition ++;
        return unity.showRewardedAd(reward);
      } else if (googleadvert != null && googleadvert.rewardedAd && rewardshowposition == 2) {
        rewardvideoattempt = 0;
        rewardshowposition++;
        return googleadvert.showRewardedAd(reward,customData);
      // } else if (await adcolony.isloaded() && adcolonyplayed.isFalse) {
      //   adcolony.show(reward);
      //   advertrewardshow.value = 3;
      //   adcolonyplayed.value = true;
      //   unityplayed.value = false;
      //   googleplayed.value = false;
      } else {
        if (rewardvideoattempt <= maxfail) {
          print("instertialattempt $rewardvideoattempt");
          if(rewardshowposition == advertprovider) {
            rewardshowposition = 1;
          }else{
            rewardshowposition ++;
          }
          rewardvideoattempt ++;
          // Add a delay before retrying
          await Future.delayed(Duration(seconds: interver));
          return showreawardads(reward,customData, interver);
          // return Advertresponse.defaults(); // Indicate that an attempt is pending
        }  else{
          rewardvideoattempt = 0;
          return Advertresponse.defaults();
        }
      }

  }

  get isvideoready => googleadvert.rewardedAd ||unity?.rewardvideoloaded;
  Widget banner() {
      // return adcolony.banner();
      // switch (slideIndex.value) {
        // case 0:
        //   if(deviceallow.allow()) {
        //   return unity!.adWidget();
        //   }else{
        //     return const SizedBox.shrink();
        //   }
      // case 1:
      //     if(deviceallow.allow() && network.isonline.isTrue) {
      //   return adcolony.banner();
      //     }else{
      //       return SizedBox.shrink();
      //     }
      //   case 1:
      //   if(deviceallow.allow()) {
          return BannerAdmob(adUnitId: adsmodel.googlemodel!.banneradadUnitId,);
          // return googleadvert.googlebanner();
        // }else{
        //   return const SizedBox.shrink();
        // }
        // default:
        //   return const SizedBox.shrink();
      // }

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
