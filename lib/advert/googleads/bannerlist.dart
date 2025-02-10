import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';

class Bannerlist extends StatefulWidget {
  final  adUnitId;
      final int advtno;
  const Bannerlist({Key? key, required this.adUnitId, required this.advtno}) : super(key: key);

  @override
  _BannerlistState createState() => _BannerlistState();
}

class _BannerlistState extends State<Bannerlist> {


  final _bannerAd = [].obs;
  set bannerAd(value) => _bannerAd.value = value;
  get bannerAd => _bannerAd.value;

  var adUnitId;




  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    adUnitId = widget.adUnitId;
    currentIndex = 0;
    // if(deviceallow.allow()) {
    //   loadAd();
    // }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // if(deviceallow.allow()) {
    //   loadAd();
    // }
  }

  // @override
  // void didUpdateWidget(covariant BannerAdmob oldWidget) {
  //   // TODO: implement didUpdateWidget
  //   super.didUpdateWidget(oldWidget);
  //   addispose();
  // }

  var _numRewardedLoadAttempts = 0.obs;
  set numRewardedLoadAttempts(value) => _numRewardedLoadAttempts.value = value;
  get numRewardedLoadAttempts => _numRewardedLoadAttempts.value;

  var _maxFailedLoadAttempts = 3.obs;
  set maxFailedLoadAttempts(value) => _maxFailedLoadAttempts.value = value;
  get maxFailedLoadAttempts => _maxFailedLoadAttempts.value;

  final _isloading = false.obs;
  set isLoading(value) => _isloading.value = value;
  get isLoading => _isloading.value;

  final _currentIndex = 0.obs;
  set currentIndex(value) => _currentIndex.value = value;
  get currentIndex => _currentIndex.value;


  ScrollController scrollController = ScrollController();
  Timer? _timer;
  bool _scrollUp = true;

  void loadAd() {
    print("start loading banner");
    if (adUnitId.length >= widget.advtno ) {
      print("some banner has been loaded");
      currentIndex = 0;
      // return; // Exit if all ads have been loaded
    }
    if (currentIndex >= adUnitId.length) {
      print("start all over again");
      currentIndex = 0;
      // return; // Exit if all ads have been loaded
    }
    if ( isLoading) {
      print("some banner still loading");
      return; // Exit if all ads have been loaded
    }

    isLoading = true;
    print("currentIndex   $currentIndex");
    var adUnitI = adUnitId[currentIndex];

    // Check if an ad already exists for the current ad unit
    if (bannerAd.any((ad) => ad.adUnitId == adUnitI)) {
      print("Ad for adUnitId $adUnitI already exists.");
      isLoading = false;
      return;
    }
    print("banner has started loading");
    BannerAd(
      adUnitId: adUnitI,
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: BannerAdListener(
          onAdLoaded: (_) {
            if (kDebugMode) {
              print("your bannerad has been loaded");
            }
            bannerAd.add(_);
            isLoading = false;
            currentIndex++;
            setState((){});
            // Check if there are more ads to load
            if (currentIndex < adUnitId.length) {
              loadAd(); // Load the next ad
            }
          },
          onAdFailedToLoad: (ad, err) async {
            isLoading = false;
            numRewardedLoadAttempts += 1;
            // Retry loading the ad if the max attempts have not been reached
            if (numRewardedLoadAttempts < maxFailedLoadAttempts) {
              await Future.delayed(Duration(seconds: 3));
              loadAd();
            } else {
              currentIndex++;
              // Check if there are more ads to load
              if (currentIndex < adUnitId.length) {
                loadAd(); // Load the next ad
              }else{
                currentIndex= 0;
                await Future.delayed(Duration(seconds: 60));
                loadAd();
              }
            }
            setState((){});
          },
          onAdWillDismissScreen: (ad){
            addispose();
          },
          onAdClosed: (ad){
            addispose();
          }
      ),
    ).load();
  }

  void addispose(){
    if(bannerAd.isNotEmpty) {
      if (kDebugMode) {
        print("dispose here");
      }
      for (int i = 0; i < widget.advtno; i++) {
        bannerAd.first.dispose();
        bannerAd.removeAt(0);
      }
      loadAd();
    }
  }


  void startAutoScroll() {
    // Wakelock.enable();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (scrollController.hasClients) {
        if (_scrollUp) {
          scrollController.animateTo(
            scrollController.position.minScrollExtent,
            duration: Duration(seconds: 2),
            curve: Curves.easeInOut,
          );
          _scrollUp = false;
        } else {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(seconds: 2),
            curve: Curves.easeInOut,
          );
          _scrollUp = true;
        }
      }
    });
  }
  @override
  void dispose() {
    super.dispose();
    addispose();
    currentIndex = 0;
    scrollController.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if(deviceallow.allow()) {
      loadAd();
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: widget.advtno,
      itemBuilder: (context, index) {
        Obx(() {
          if (bannerAd.isNotEmpty && deviceallow.allow()) {
            return SizedBox(
              height: bannerAd[index].size.height.toDouble(),
              child: AdWidget(ad: bannerAd[index]),
            );
          } else {
            // return SizedBox.shrink();
            return const SizedBox.shrink();
          }
        });
        return null;
      },
    );
  }
}
