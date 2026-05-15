import 'dart:developer' as dev;

import 'package:advert/advert/advert.dart';
import 'package:flutter/material.dart';
import 'device_management_page.dart';

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
    _advertPlugin.initialize(testmode: true).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _startSequence(String type, String reason, int total) {
    _advertPlugin.adsProv.startAdSequence(
      context,
      total: total,
      adType: type,
      reason: reason,
      customData: {"username": "test_user", "platform": "mobile", "type": "sequence"},
      onComplete: () {
        dev.log("Sequence: $type ads finished");
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_advertPlugin.sdkInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final adsProv = _advertPlugin.adsProv;
    final isShowing = adsProv.isShowingAds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advert Plugin Example'),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeviceManagementPage()),
                  ),
                  icon: const Icon(Icons.devices),
                  label: const Text("Device Management"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const Divider(),
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
                onPressed: isShowing ? null : () => _startSequence('mergeRewarded', "Use general Market",1),
                child: const Text("Show mergeRewarded Ad"),
              ),
              TextButton(
                onPressed: isShowing ? null : () => _startSequence('googleMergeRewarded', "Earn card",1),
                child: const Text("Show googlemergeRewarded Ad"),
              ),
              TextButton(
                onPressed: isShowing ? null : () => _startSequence('rewarded', "Receive \$1",1),
                child: const Text("Show Rewarded Ad"),
              ),
              TextButton(
                onPressed: isShowing ? null : () => _startSequence('rewardedInterstitial', "Earn \#6",2),
                child: const Text("Show Rewarded Insterstitial Ad"),
              ),
              TextButton(
                onPressed: isShowing ? null : () => _startSequence('spinAndWin', "Earn \$100",5),
                child: const Text("Show SpinandWin Ad"),
              ),
              
              if (isShowing)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text("Ad Sequence: ${adsProv.adsWatched}/${adsProv.totalAds} completed"),
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
        ),
      ),
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
      child: _advertPlugin.adsProv.showNativeAd(context),
    );
  }

  void _toggleBannerAd() {
    setState(() {
      _showBannerAd = !_showBannerAd;
    });
  }
}
