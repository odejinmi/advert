import 'dart:io';

import 'package:advert/model/google.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../advert_platform_interface.dart';
import '../model/adsmodel.dart';
import '../model/unity.dart';
import 'adsProvider.dart';

/// Configuration constants for test ad units
class _AdConfig {
  // Android ad unit IDs
  static const List<String> androidBannerIds = ['ca-app-pub-3940256099942544/6300978111'];
  static const List<String> androidInterstitialIds = ['ca-app-pub-3940256099942544/1033173712'];
  static const List<String> androidNativeIds = ['ca-app-pub-3940256099942544/2247696110'];
  static const List<String> androidRewardedIds = ['ca-app-pub-3940256099942544/5224354917'];
  static const List<String> androidRewardedInterstitialIds = ['ca-app-pub-3940256099942544/5354046379'];
  
  // iOS ad unit IDs
  static const List<String> iosBannerIds = ['ca-app-pub-3940256099942544/2934735716'];
  static const List<String> iosInterstitialIds = ['ca-app-pub-3940256099942544/4411468910'];
  static const List<String> iosNativeIds = ['ca-app-pub-3940256099942544/3986624511'];
  static const List<String> iosRewardedIds = ['ca-app-pub-3940256099942544/1712485313'];
  static const List<String> iosRewardedInterstitialIds = ['ca-app-pub-3940256099942544/6978759866'];
  
  // Unity game IDs
  static const String androidGameId = "3717787";
  static const String iosGameId = "3717786";
  
  // Unity placement IDs
  static const List<String> androidBannerPlacements = ['newandroidbanner'];
  static const List<String> iosBannerPlacements = ['iOS_Banner'];
  static const List<String> interstitialPlacements = ['video', 'iOS_Interstitial'];
  static const List<String> rewardedPlacements = ['Android_Rewarded', 'rewardedVideo', 'iOS_Rewarded'];
}

class Advert {
  bool _sdkInitialized = false;
  // static late PlatformInfo platformInfo;
  Adsmodel _adsmodel = Adsmodel();
  Future<String?> getPlatformVersion() {
    return AdvertPlatform.instance.getPlatformVersion();
  }

  // Lazy-loaded ad unit IDs
  late final List<String> banneradUnitId;
  late final List<String> screenUnitId;
  late final List<String> _nativeadUnitId;
  late final List<String> videoUnitId;
  late final List<String> adUnitId;
  late final String gameid;
  late final List<String> bannerAdPlacementId;
  late final List<String> interstitialVideoAdPlacementId;
  late final List<String> rewardedVideoAdPlacementId;
  
  // Initialize ad unit IDs based on platform
  void _initializeAdUnits() {
    banneradUnitId = Platform.isAndroid 
        ? List.from(_AdConfig.androidBannerIds) 
        : List.from(_AdConfig.iosBannerIds);
        
    screenUnitId = Platform.isAndroid
        ? List.from(_AdConfig.androidInterstitialIds)
        : List.from(_AdConfig.iosInterstitialIds);
        
    _nativeadUnitId = Platform.isAndroid
        ? List.from(_AdConfig.androidNativeIds)
        : List.from(_AdConfig.iosNativeIds);
        
    videoUnitId = Platform.isAndroid
        ? List.from(_AdConfig.androidRewardedIds)
        : List.from(_AdConfig.iosRewardedIds);
        
    adUnitId = Platform.isAndroid
        ? List.from(_AdConfig.androidRewardedInterstitialIds)
        : List.from(_AdConfig.iosRewardedInterstitialIds);
        
    gameid = Platform.isAndroid ? _AdConfig.androidGameId : _AdConfig.iosGameId;
    
    bannerAdPlacementId = Platform.isAndroid 
        ? List.from(_AdConfig.androidBannerPlacements)
        : List.from(_AdConfig.iosBannerPlacements);
        
    interstitialVideoAdPlacementId = List.from(_AdConfig.interstitialPlacements);
    rewardedVideoAdPlacementId = List.from(_AdConfig.rewardedPlacements);
  }

  /// Initializes the ad plugin with the provided configuration.
  /// 
  /// [adsmodel] - Optional custom ad configuration model
  /// [testmode] - Whether to use test ad units
  /// [enableDebugLogging] - Whether to enable debug logging
  Future<void> initialize({
    Adsmodel? adsmodel, 
    required bool testmode,
    bool enableDebugLogging = kDebugMode,
  }) async {
    if (_sdkInitialized) {
      debugPrint('Advert SDK already initialized');
      return;
    }
    
    _initializeAdUnits();
    
    if (enableDebugLogging) {
      debugPrint('Initializing Advert SDK in ${testmode ? 'TEST' : 'PRODUCTION'} mode');
      debugPrint('Platform: ${Platform.operatingSystem}');
    }
    assert(() {
      Googlemodel googlemodel = Googlemodel()
        ..bannerAdUnitId = banneradUnitId
        ..nativeAdUnitId = _nativeadUnitId
        ..rewardedInterstitialAdUnitId = adUnitId
        ..rewardedAdUnitId = videoUnitId
        ..interstitialAdUnitId = screenUnitId;
      Unitymodel unitymodel = Unitymodel()
        ..gameId = gameid
        ..interstitialVideoAdPlacementId = interstitialVideoAdPlacementId
        ..rewardedVideoAdPlacementId = rewardedVideoAdPlacementId
        ..bannerAdPlacementId = bannerAdPlacementId;
      if (testmode) {
        adsmodel = Adsmodel(googlemodel: googlemodel, unitymodel: unitymodel);
      }
      if (adsmodel == null || adsmodel!.adsempty) {
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

  /// Gets the ad manager instance, initializing it if necessary
  AdManager get adsProv {
    validateSdkInitialized();
    return Get.put(
      AdManager(_adsmodel),
      tag: 'ad_manager',
    );
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
