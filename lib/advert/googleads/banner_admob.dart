import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';

class BannerAdWidget extends StatefulWidget {
  final List<String> adUnitIds;
  final AdSize adSize;
  final Duration retryDelay;

  const BannerAdWidget({
    Key? key,
    required this.adUnitIds,
    this.adSize = AdSize.largeBanner,
    this.retryDelay = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  BannerAdWidgetState createState() => BannerAdWidgetState();
}

class BannerAdWidgetState extends State<BannerAdWidget> {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 3;

  // Ad management variables
  final RxList<BannerAd> _loadedAds = <BannerAd>[].obs;
  final RxInt _currentIndex = 0.obs;
  final RxInt _failedAttempts = 0.obs;
  final RxBool _isLoading = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get hasAds => _loadedAds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (deviceallow.allow()) {
      _loadAd();
    }
  }

  @override
  void didUpdateWidget(BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If ad unit IDs changed, reload ads
    if (!listEquals(widget.adUnitIds, oldWidget.adUnitIds) ||
        widget.adSize != oldWidget.adSize) {
      _disposeAllAds();
      _currentIndex.value = 0;
      _failedAttempts.value = 0;
      if (deviceallow.allow()) {
        _loadAd();
      }
    }
  }

  /// Loads a banner ad using the current ad unit ID
  void _loadAd() {
    // Don't load if we have no ad unit IDs or device is not allowed
    if (widget.adUnitIds.isEmpty || !deviceallow.allow()) {
      return;
    }

    // Don't start a new load if one is in progress
    if (_isLoading.value) {
      debugPrint('Banner ad load already in progress');
      return;
    }

    // Don't load more ads if we've gone through all ad unit IDs
    if (_currentIndex.value >= widget.adUnitIds.length) {
      debugPrint('All banner ad units attempted');
      return;
    }

    _isLoading.value = true;
    final adUnitId = widget.adUnitIds[_currentIndex.value];

    debugPrint(
        'Loading banner ad ${_currentIndex.value + 1}/${widget.adUnitIds.length}: $adUnitId');

    // Check if this ad unit ID is already loaded
    // if (_loadedAds.any((ad) => ad.adUnitId == adUnitId)) {
    //   debugPrint('Banner ad for $adUnitId already exists');
    //   _isLoading.value = false;
    //   _currentIndex.value++;

    //   if (_currentIndex.value < widget.adUnitIds.length) {
    //     _loadAd();
    //   }
    //   return;
    // }

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully: ${ad.adUnitId}');
          _loadedAds.add(ad as BannerAd);
          _isLoading.value = false;
          _failedAttempts.value = 0;
          _currentIndex.value++;

          // Force UI update
          if (mounted) setState(() {});

          // Try to load the next ad if available
          if (_currentIndex.value < widget.adUnitIds.length) {
            _loadAd();
          } else {
             // We've loaded all ads for this round
             debugPrint('All banner ads loaded for this cycle');
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          _isLoading.value = false;
          _failedAttempts.value++;

          if (_failedAttempts.value < MAX_FAILED_LOAD_ATTEMPTS) {
            // Retry after delay
            Future.delayed(widget.retryDelay, () {
              if (mounted) _loadAd();
            });
          } else {
            // Move to next ad unit
            _failedAttempts.value = 0;
            _currentIndex.value++;

            if (_currentIndex.value < widget.adUnitIds.length) {
              _loadAd();
            } else {
              // Reset index to try again after a longer delay
              _currentIndex.value = 0;
              Future.delayed(const Duration(seconds: 60), () {
                if (mounted) _loadAd();
              });
            }
          }

          // Force UI update
          if (mounted) setState(() {});
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
          _loadedAds.removeWhere((adData) => adData == ad);
          },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
          _refreshAd(ad);
        },
        onAdWillDismissScreen: (ad) {
          debugPrint('Banner ad will dismiss screen');
          _refreshAd(ad);
        },
        onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
        onPaidEvent: (ad, valueMicros, precision, currencyCode) =>
            debugPrint('Banner ad paid event: $currencyCode $valueMicros'),
      ),
    );

    bannerAd.load();
  }

  /// Refreshes the ad by disposing the current one and loading a new one
  void _refreshAd(Ad ad) {
    _disposeCurrentAd(ad);
    
    // Reset index to 0 to start loading from the beginning if we reached the end
    if (_currentIndex.value >= widget.adUnitIds.length) {
      _currentIndex.value = 0;
    }
    
    _loadAd();
  }

  /// Disposes the current ad and removes it from the list
  void _disposeCurrentAd(Ad ad) {
    if (_loadedAds.contains(ad)) {
      _loadedAds.remove(ad);
      ad.dispose();
    }
  }

  /// Disposes all loaded ads
  void _disposeAllAds() {
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    _loadedAds.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
      child: Obx(() {
        if (_loadedAds.isNotEmpty && deviceallow.allow()) {
          return SizedBox(
            width: _loadedAds.first.size.width.toDouble(),
            height: _loadedAds.first.size.height.toDouble(),
            child: AdWidget(ad: _loadedAds.first),
          );
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }

  @override
  void dispose() {
    _disposeAllAds();
    super.dispose();
  }
}
