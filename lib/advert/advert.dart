
import 'dart:io';

import 'package:advert/model/google.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../model/adsmodel.dart';
import '../model/unity.dart';
import 'adsProvider.dart';
import '../advert_platform_interface.dart';

class Advert {

  bool _sdkInitialized = false;
  // static late PlatformInfo platformInfo;
  Adsmodel _adsmodel = Adsmodel();
  Future<String?> getPlatformVersion() {
    return AdvertPlatform.instance.getPlatformVersion();
  }

  final banneradUnitId = Platform.isAndroid
      ? ['ca-app-pub-3940256099942544/6300978111']
      : ['ca-app-pub-3940256099942544/2934735716'];

  get screenUnitId => Platform.isAndroid
      ? ['ca-app-pub-3940256099942544/1033173712']
      : ['ca-app-pub-3940256099942544/4411468910'];

  final  _nativeadUnitId = Platform.isAndroid
      ? ['ca-app-pub-3940256099942544/2247696110']
      : ['ca-app-pub-3940256099942544/3986624511'];

  final videoUnitId = Platform.isAndroid
  // ? 'ca-app-pub-3940256099942544/5224354917'
      ? ['ca-app-pub-3940256099942544/5224354917']
      : ['ca-app-pub-3940256099942544/1712485313'];

  // TODO: replace this test ad unit with your own ad unit.
  final adUnitId = Platform.isAndroid
      ? ['ca-app-pub-3940256099942544/5354046379']
      : ['ca-app-pub-3940256099942544/6978759866'];

  final gameid = Platform.isAndroid ? "3717787" : '3717786';
  final bannerAdPlacementId = Platform.isAndroid ? ['newandroidbanner'] : ['iOS_Banner'];
  final interstitialVideoAdPlacementId = Platform.isAndroid ? ['video'] : ['iOS_Interstitial'];
  final rewardedVideoAdPlacementId = Platform.isAndroid ? ['Android_Rewarded',"rewardedVideo"] : ['iOS_Rewarded'];


  initialize({Adsmodel? adsmodel, required bool testmode}) async {
    assert(() {
      Googlemodel googlemodel = Googlemodel()
        ..banneradadUnitId = banneradUnitId
        ..nativeadUnitId = _nativeadUnitId
        ..rewardedinterstitialad = adUnitId
        ..videoUnitId = videoUnitId
        ..screenUnitId = screenUnitId;
      Unitymodel unitymodel = Unitymodel()
        ..gameId = gameid
        ..interstitialVideoAdPlacementId = interstitialVideoAdPlacementId
        ..rewardedVideoAdPlacementId = rewardedVideoAdPlacementId
        ..bannerAdPlacementId = bannerAdPlacementId;
      if (testmode) {
        adsmodel = Adsmodel(googlemodel: googlemodel, unitymodel: unitymodel);
      }
      if (adsmodel == null ||adsmodel!.adsempty) {
        throw DuploException('you must supply atleast one adunit');
      // } else if (!publicKey.startsWith("pk_")) {
      //   throw DuploException(Utils.getKeyErrorMsg('public'));
      // } else if (secretKey.isEmpty) {
      //   throw DuploException('secretKey cannot be null or empty');
      // } else if (!secretKey.startsWith("sk_")) {
      //   throw DuploException(Utils.getKeyErrorMsg('secret'));
      } else {
        return true;
      }
    }());

    if (sdkInitialized) return;

    // publicKey = publicKey;

    // Using cascade notation to build the platform specific info
    try {
      // platformInfo = (await PlatformInfo.getinfo())!;
      _adsmodel = adsmodel!;
      // _screenUnitId = googlemodel.screenUnitId;
      // _videoUnitId = googlemodel.videoUnitId;
      // _adUnitId = googlemodel.adUnitId;
      // _nativeadUnitId = googlemodel.nativeadUnitId;
      // _banneradadUnitId = googlemodel.banneradadUnitId;
      _sdkInitialized = true;
    } on PlatformException {
      rethrow;
    }
  }

  AdsProv get adsProv {
    validateSdkInitialized();
      return Get.put(AdsProv(_adsmodel), permanent: true);
  }

  bool get sdkInitialized => _sdkInitialized;


  validateSdkInitialized() {
    if (!sdkInitialized) {
      throw DuploSdkNotInitializedException(
          'Advert SDK has not been initialized. The SDK has'
              ' to be initialized before use');
    }
  }


}

class DuploException implements Exception {
  String? message;

  DuploException(this.message);

  @override
  String toString() {
    if (message == null) return 'Unknown Error';
    return message!;
  }
}

class DuploSdkNotInitializedException extends DuploException {
  DuploSdkNotInitializedException(String message) : super(message);
}