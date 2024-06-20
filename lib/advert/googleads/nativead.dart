
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';

class Nativead extends GetxController {
var nativeadUnitId;
Nativead(this.nativeadUnitId);
  NativeAd? _nativeAd;
  bool nativeAdIsLoaded = false;

  // TODO: replace this test ad unit with your own ad unit.
  // final String _adUnitId = Platform.isAndroid
  //     ? 'ca-app-pub-6117361441866120/7557970286'
  //     : 'ca-app-pub-6117361441866120/5123378631';


  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if(deviceallow.allow()) {
      loadAd();
    }
  }

  /// Loads a native ad.
  void loadAd() {
    if(nativeadUnitId.isNotEmpty) {
      _nativeAd = NativeAd(
          adUnitId: nativeadUnitId[0],
          // Factory ID registered by your native ad factory implementation.
          factoryId: 'adFactoryExample',
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              print("your nativead has been loaded");
              print('$NativeAd loaded.');
              nativeAdIsLoaded = true;
              update();
            },
            onAdFailedToLoad: (ad, error) {
              // Dispose the ad here to free resources.
              print('$NativeAd failedToLoad: $error');
              ad.dispose();
            },
            // Called when a click is recorded for a NativeAd.
            onAdClicked: (ad) {},
            // Called when an impression occurs on the ad.
            onAdImpression: (ad) {},
            // Called when an ad removes an overlay that covers the screen.
            onAdClosed: (ad) {},
            // Called when an ad opens an overlay that covers the screen.
            onAdOpened: (ad) {},
            // For iOS only. Called before dismissing a full screen view
            onAdWillDismissScreen: (ad) {},
            // Called when an ad receives revenue value.
            onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
          ),
          request: const AdRequest(),
          // Optional: Pass custom options to your native ad factory implementation.
          customOptions: {'custom-option-1': "custom-value-1"}
      );
      _nativeAd!.load();
    }
  }

  void closead(){
    Get.back();
    _nativeAd!.dispose();
    loadAd();
  }

  Widget showad(){
    if (_nativeAd != null) {
      Future.delayed(const Duration(seconds: 20)).then((value) {
        closead();
      });
      return AdWidget(ad: _nativeAd!);
    } else {
      return SizedBox.shrink();
    }
  }
}