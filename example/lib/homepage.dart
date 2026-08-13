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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              adsProv.preloadAllAds();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preloading all ads...')),
              );
            },
            tooltip: 'Preload All Ads',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
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
            const SizedBox(height: 20),
            
            _buildSection(
              title: "Interstitial Ads",
              children: [
                ElevatedButton(
                  onPressed: () => adsProv.showInterstitialAd(),
                  child: const Text("Show Default Interstitial"),
                ),
                OutlinedButton(
                  onPressed: () => adsProv.showInterstitialAd(type: 'CustomPlacement'),
                  child: const Text("Show Custom Type Interstitial"),
                ),
              ],
            ),

            _buildSection(
              title: "Waterfall / High Priority",
              children: [
                ElevatedButton(
                  onPressed: isShowing.value ? null : () => _startSequence('freemoney', "High Priority Waterfall", 3),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  child: const Text("Show Free Money (Waterfall)"),
                ),
                const Text(
                  "Attempts: High Rewarded -> Low Rewarded -> FM Interstitial",
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            _buildSection(
              title: "Rewarded Sequences",
              children: [
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildAdButton("Rewarded", () => _startSequence('rewarded', "Receive \$1", 1), isShowing.value),
                    _buildAdButton("Merge", () => _startSequence('mergeRewarded', "General Market", 1), isShowing.value),
                    _buildAdButton("Google Only", () => _startSequence('googleMergeRewarded', "Earn card", 1), isShowing.value),
                    _buildAdButton("Interstitial", () => _startSequence('rewardedInterstitial', "Earn Points", 1), isShowing.value),
                    _buildAdButton("Spin & Win (x5)", () => _startSequence('spinAndWin', "Earn \$100", 5), isShowing.value),
                  ],
                ),
                if (isShowing.value)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text("Progress: ${adsProv.adsWatched}/${adsProv.totalAds}"),
                      ],
                    ),
                  ),
              ],
            ),

            _buildSection(
              title: "Native & Banner Ads",
              children: [
                SwitchListTile(
                  title: const Text("Show Native Ad"),
                  value: _showNativeAd,
                  onChanged: (val) => setState(() => _showNativeAd = val),
                ),
                if (_showNativeAd) _buildNativeAdWidget(),
                
                SwitchListTile(
                  title: const Text("Show Banner Ad (Waterfall)"),
                  value: _showBannerAd,
                  onChanged: (val) => setState(() => _showBannerAd = val),
                ),
                if (_showBannerAd) 
                  Center(child: adsProv.showBannerAd()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAdButton(String label, VoidCallback onPressed, bool disabled) {
    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      child: Text(label),
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
}
