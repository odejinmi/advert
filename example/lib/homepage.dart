import 'dart:developer' as dev;

import 'package:advert/advert/advert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _advertPlugin = Advert();

  bool _showNativeAd = false;
  bool _showBannerAd = false;

  @override
  void initState() {
    super.initState();
    _advertPlugin.initialize(testmode: true);
  }

  void _startSequence(String type, String reason) {
    _advertPlugin.adsProv.startAdSequence(
      context,
      total: 6,
      adType: type,
      reason: reason,
      customData: {"username": "test_user", "platform": "mobile", "type": "sequence"},
      onComplete: () {
        dev.log("Sequence: $type ads finished");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advert Plugin Example'),
      ),
      body: Obx(() {
        if (!_advertPlugin.sdkInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final adsProv = _advertPlugin.adsProv;
        final isShowing = adsProv.isShowingAds.value;

        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => adsProv.showInterstitialAd(),
                child: const Text("Show Interstitial Ad"),
              ),
              TextButton(
                onPressed: _toggleNativeAd,
                child: Text("${_showNativeAd ? 'Hide' : 'Show'} Native Ad"),
              ),
              if (_showNativeAd) _buildNativeAdWidget(),
              
              TextButton(
                onPressed: isShowing ? null : () => _startSequence('mergeRewarded', "Use general Market"),
                child: const Text("Show mergeRewarded Ad"),
              ),
              TextButton(
                onPressed: isShowing ? null : () => _startSequence('googleMergeRewarded', "Earn card"),
                child: const Text("Show googlemergeRewarded Ad"),
              ),
              TextButton(
                onPressed: isShowing ? null : () => _startSequence('rewarded', "Receive \$1"),
                child: const Text("Show Rewarded Ad"),
              ),
              TextButton(
                onPressed: isShowing ? null : () => _startSequence('rewardedInterstitial', "Earn \#6"),
                child: const Text("Show Rewarded Insterstitial Ad"),
              ),
              TextButton(
                onPressed: isShowing ? null : () => _startSequence('spinAndWin', "Earn \$100"),
                child: const Text("Show SpinandWin Ad"),
              ),
              
              if (isShowing)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text("Ad Sequence: ${adsProv.adsWatched.value}/${adsProv.totalAds.value} completed"),
                    ],
                  ),
                ),
              TextButton(
                onPressed: _toggleBannerAd,
                child: Text("${_showBannerAd ? 'Hide' : 'Show'} Banner Ad"),
              ),
              if (_showBannerAd) adsProv.showBannerAd(),
            ],
          ),
        );
      }),
    );
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
}
