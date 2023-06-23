import 'dart:io';

// import 'package:adcolony_flutter/adcolony_flutter.dart';
// import 'package:adcolony_flutter/banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdcolonyProvider extends GetxController {
  var adcolonyready = false.obs;
  var adcolonyreward = false.obs;
  static List<String> get zones => Platform.isIOS
      ? ['vz5e0c866b461a4296b1', 'vz5e0c866b461a4296b1', 'vz8e7a2890d9d14e45bc']
      // : [
      //     'vz56ab037b9de94019a5',
      //     'vzf820a7e23fd1454c88',
      //     'vza27ce2e27d1a4b3098'
      //   ];
      : [
          'vz9c4386eadee3475d85',
          'vz4bed309cad844555b3',
          'vzf201d4d3300d420b99'
        ];

  static String get adcolonyappid =>
      Platform.isIOS ? 'app50b1e16399444d259c' : 'appc29d105cd9a54d4091';

  adcolonyinit() {
    // AdColony.init(AdColonyOptions(adcolonyappid, '0', zones));
  }

  // listener(AdColonyAdListener? event, int? reward) async {
  //   if (event == AdColonyAdListener.onRequestFilled) {
  //     if (await AdColony.isLoaded()) {
  //       adcolonyready.value = true;
  //     }
  //   }
  //   if (event == AdColonyAdListener.onReward) {
  //     debugPrint('ADCOLONY: $reward');
  //     adcolonyreward.value = true;
  //   }
  // }

  Future<bool> isloaded() async {
    // return await AdColony.isLoaded();
    return false;
  }

  void request() {
    // AdColony.request(zones[0], listener);
  }

  void show(Function? reward) {
    // AdColony.show();
  }

  Widget banner() {
    // return BannerView(listener, BannerSizes.banner, zones[2],
    //     onCreated: (BannerController controller) {});
    return Container();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    adcolonyinit();
  }
}
