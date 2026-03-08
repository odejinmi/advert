import 'dart:async';
import 'dart:developer' as dev;

import 'package:advert/advert/advert.dart';
import 'package:advert/model/advertresponse.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _advertPlugin = Advert();

  bool _showNativeAd = false;
  bool _showBannerAd = false;
  bool _isShowingAds = false;

  @override
  void initState() {
    super.initState();
    _advertPlugin.initialize(testmode: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advert Plugin Example'),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _showInterstitialAd,
              child: const Text("Show Interstitial Ad"),
            ),
            TextButton(
              onPressed: _toggleNativeAd,
              child: Text("${_showNativeAd ? 'Hide' : 'Show'} Native Ad"),
            ),
            if (_showNativeAd) _buildNativeAdWidget(),
            TextButton(
              onPressed: _isShowingAds ? null : () => _showRewardAds(1),
              child: const Text("Show Rewarded Ad"),
            ),
            TextButton(
              onPressed: _isShowingAds ? null : () => _playAdsBeforeSpin(),
              child: const Text("Show SpinandWin Ad"),
            ),
            TextButton(
              onPressed: _isShowingAds ? null : () => _playAdsBeforeReward(),
              child: const Text("Show Multiple Rewarded Ads"),
            ),
            if (_isShowingAds)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 10),
                    Text("Showing ads..."),
                  ],
                ),
              ),
            TextButton(
              onPressed: _toggleBannerAd,
              child: Text("${_showBannerAd ? 'Hide' : 'Show'} Banner Ad"),
            ),
            if (_showBannerAd) _advertPlugin.adsProv.showBannerAd(),
          ],
        ),
      ),
    );
  }

  void _showInterstitialAd() {
    _advertPlugin.adsProv.showInterstitialAd();
  }

  void _toggleNativeAd() {
    setState(() {
      _showNativeAd = !_showNativeAd;
    });
  }

  Widget _buildNativeAdWidget() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 320,
        minHeight: 90,
        maxWidth: 400,
        maxHeight: 200,
      ),
      child: _advertPlugin.adsProv.showNativeAd(),
    );
  }

  void _toggleBannerAd() {
    setState(() {
      _showBannerAd = !_showBannerAd;
    });
  }

  Future<void> _showRewardAds(int maxAds) async {
    setState(() {
      _isShowingAds = true;
    });

    final customData = {"username": "", "platform": "", "type": ""};

    for (int i = 0; i < maxAds; i++) {
      final completer = Completer<void>();

      final Advertresponse response =
          await _advertPlugin.adsProv.showRewardedAd(() {
        // This is the onRewarded callback. We complete the future here.
        if (!completer.isCompleted) {
          completer.complete();
        }
      }, customData);

      if (response.status) {
        // If the ad started showing, wait for the reward callback to be called.
        // This future will complete when the onRewarded callback is executed.
        await completer.future;
      } else {
        // If the ad failed to show, log it and stop trying.
        debugPrint("Failed to show ad ${i + 1}. Stopping.");
        break;
      }
    }

    setState(() {
      _isShowingAds = false;
    });
  }

  static const int requiredAdsCount = 5;

  var _adsWatched = 0;
  var _isPlayingAds = false;

  void _showAdProgressDialog(int completed, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Watching Ads..."),
        content: Text("Ad $completed of $total"),
      ),
    );
  }

  void _playAdsBeforeSpin() async {
    _isPlayingAds = true;

    try {
      _showAdProgressDialog(_adsWatched + 1, requiredAdsCount);
      dev.log('Playing ad $_adsWatched/$requiredAdsCount...',
          name: 'SpinWinModule');

      var result = await _advertPlugin.adsProv.showspinAndWin(
        () {
          Navigator.of(context).pop();
          if (_adsWatched < requiredAdsCount - 1) {
            _adsWatched += 1;
            setState(() {});
            return _playAdsBeforeSpin();
          } else {
            print("multiple advert $_adsWatched finished");
            _adsWatched = 0;
            setState(() {});
          }
          dev.log('Ad $_adsWatched/$requiredAdsCount completed',
              name: 'SpinWinModule');
        },
        {"username": "", "platform": "mobile", "type": "spin_win"},
      );

      if (!result.status) {
        Navigator.of(context).pop();
      }
    } finally {
      _isPlayingAds = false;
    }
  }
  void _playAdsBeforeReward() async {
    _isPlayingAds = true;

    try {
      _showAdProgressDialog(_adsWatched + 1, requiredAdsCount);
      dev.log('Playing ad $_adsWatched/$requiredAdsCount...',
          name: 'SpinWinModule');

      var result = await _advertPlugin.adsProv.showRewardedAd(
        () {
          Navigator.of(context).pop();
          if (_adsWatched < requiredAdsCount - 1) {
            _adsWatched += 1;
            setState(() {});
            return _playAdsBeforeSpin();
          } else {
            print("multiple advert $_adsWatched finished");
            _adsWatched = 0;
            setState(() {});
          }
          dev.log('Ad $_adsWatched/$requiredAdsCount completed',
              name: 'SpinWinModule');
        },
        {"username": "", "platform": "mobile", "type": "spin_win"},
      );

      if (!result.status) {
        Navigator.of(context).pop();
      }
    } finally {
      _isPlayingAds = false;
    }
  }
}
