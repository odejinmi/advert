import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';

class BannerAdmob extends StatefulWidget {
  final  adUnitId;
  const BannerAdmob({Key? key, required this.adUnitId}) : super(key: key);

  @override
  BannerAdmobState createState() => BannerAdmobState();
}

class BannerAdmobState extends State<BannerAdmob> {


  var _bannerAd = [].obs;
  set bannerAd(value) => _bannerAd.value = value;
  get bannerAd => _bannerAd.value;

  var adUnitId;

  var _bannerReady = false.obs;
  set bannerReady(value) => _bannerReady.value = value;
  get bannerReady => _bannerReady.value;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    adUnitId = widget.adUnitId;
    if(deviceallow.allow()) {
      loadAd();
    }
  }

  @override
  void didUpdateWidget(covariant BannerAdmob oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    addispose();
  }


  void loadAd() {
    for(int i =0;i < (adUnitId.length - bannerAd.length); i++ ) {
      var adunitid = adUnitId[i];
      if (bannerAd.length != adUnitId.length) {
        bannerAd.add(BannerAd(
          adUnitId: adunitid,
          request: const AdRequest(),
          size: AdSize.largeBanner,
          listener: BannerAdListener(
              onAdLoaded: (_) {

                print("your bannerad has been loaded");
                bannerReady = true;
              },
              onAdFailedToLoad: (ad, err) {
                bannerReady = false;
                loadAd();
              },
              onAdWillDismissScreen: (ad){
                addispose();
              },
              onAdClosed: (ad){
                addispose();
              }
          ),
        ));
        bannerAd[i].load();
      }
    }///08084490201 my airtel number
  }

  void addispose(){
    if(bannerAd.isNotEmpty) {
      print("dispose here");
      bannerAd.first.dispose();
      bannerAd.removeAt(0);
      loadAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
      child: Obx(() {
        if (bannerReady && deviceallow.allow()) {
          return SizedBox(
            height: bannerAd.first.size.height.toDouble(),
            child: AdWidget(ad: bannerAd.first),
          );
        } else {
          // return SizedBox.shrink();
          return const SizedBox.shrink();
        }
      }),
    );
  }
}
