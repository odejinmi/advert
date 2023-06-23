
import 'package:advert/model/google.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../model/adsmodel.dart';
import 'adsProvider.dart';
import '../advert_platform_interface.dart';

class Advert {

  bool _sdkInitialized = false;
  // static late PlatformInfo platformInfo;
  Adsmodel _adsmodel = Adsmodel();
  Future<String?> getPlatformVersion() {
    return AdvertPlatform.instance.getPlatformVersion();
  }

  initialize(Adsmodel adsmodel) async {
    assert(() {
      if (adsmodel.adsempty) {
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
      _adsmodel = adsmodel;
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
          'Duplo SDK has not been initialized. The SDK has'
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