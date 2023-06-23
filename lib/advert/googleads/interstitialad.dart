import 'dart:io';

import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../device.dart';

import '../networks.dart';

class Interstitialad extends GetxController {
  var screenUnitId;
  Interstitialad(this.screenUnitId);


  var _intersAd1 = [].obs;
  set intersAd1(value)=> _intersAd1.value = value;
  get intersAd1 => _intersAd1.value;

  var _numInterstitialLoadAttempts = 0.obs;
  set numInterstitialLoadAttempts(value)=> _numInterstitialLoadAttempts.value = value;
  get numInterstitialLoadAttempts => _numInterstitialLoadAttempts.value;

  var _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value)=> _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;

  bool showAds = false;


  var network = Get.put(Networks());
  void createInterstitialAd() {
    for(int i =0;i < (screenUnitId.length - intersAd1.length); i++ ) {
      var adunitid = screenUnitId[i];
      if (screenUnitId.length != intersAd1.length) {
        InterstitialAd.load(
            adUnitId: adunitid,
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (InterstitialAd ad) {
                print("your interstitialad has been loaded");
                // Keep a reference to the ad so you can show it later.
                ad.fullScreenContentCallback = FullScreenContentCallback(
                  onAdShowedFullScreenContent: (InterstitialAd ad) {},
                  onAdDismissedFullScreenContent: (InterstitialAd ad) {
                    addispose(ad);
                  },
                  onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                    addispose(ad);
                  },
                );
                intersAd1.add(ad);
              },
              onAdFailedToLoad: (LoadAdError error) {
                // googleinstatialfailed = true;
                numInterstitialLoadAttempts += 1;
                if (numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
                  createInterstitialAd();
                }
              },
            ));
      }
    }
  }

  void addispose(InterstitialAd ad){
    intersAd1.remove(ad);
    ad.dispose();
    update();
    createInterstitialAd();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if(deviceallow.allow() && network.isonline.isTrue) {
      createInterstitialAd();
    }
  }

  void showAd1() async {
    if (intersAd1.isNotEmpty) {
      intersAd1.first.show();
    } else {
      createInterstitialAd();
      print("kindly check your network");
    }
  }

  static const AdRequest request = AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );

  // static AdsProvider instance(BuildContext context) =>
  //     Provider.of(context, listen: false);

  static String get appId => Platform.isAndroid
  // old
  // ? 'ca-app-pub-6117361441866120~5829948546'
  // ? 'ca-app-pub-1598206053668309~2044155939'
      ? 'ca-app-pub-6117361441866120~5829948546'
  // : 'ca-app-pub-3940256099942544~1458002511';
  // : 'ca-app-pub-1598206053668309~7710581439';
      : 'ca-app-pub-6117361441866120~7211527566';

  // get screenUnitId => Platform.isAndroid
  // // test
  // // ? 'ca-app-pub-3940256099942544/1033173712'
  // // ? 'ca-app-pub-1598206053668309/2841398135'
  //     ? ['ca-app-pub-6117361441866120/8563923098','ca-app-pub-6117361441866120/2544949196',
  //        'ca-app-pub-6117361441866120/8918785857','ca-app-pub-6117361441866120/7605704182',
  //        'ca-app-pub-6117361441866120/8727214165']
  // // : 'ca-app-pub-3940256099942544/4411468910';
  // // : 'ca-app-pub-1598206053668309/3579764737';
  //     : ['ca-app-pub-6117361441866120/8759030065','ca-app-pub-6117361441866120/2980063466',
  //        'ca-app-pub-6117361441866120/9050647790', 'ca-app-pub-6117361441866120/6424484457',
  //        'ca-app-pub-6117361441866120/8779185051'];
}