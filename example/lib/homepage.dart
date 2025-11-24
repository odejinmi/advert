import 'dart:async';

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
              onPressed: _isShowingAds ? null : () => _showRewardAds(3),
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
}
