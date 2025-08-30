import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';

class BannerAdManager extends GetxController {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 3;

  // Private variables
  final List<String> _adUnitIds;
  final RxList<BannerAd> _loadedAds = <BannerAd>[].obs;
  final RxInt _currentLoadingIndex = 0.obs;
  final RxInt _failedAttempts = 0.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _bannerReady = false.obs;

  // Constructor
  BannerAdManager(this._adUnitIds);

  // Getters
  bool get isLoading => _isLoading.value;
  bool get bannerReady => _bannerReady.value && _loadedAds.isNotEmpty;
  bool get hasAds => _loadedAds.isNotEmpty;

  // Banner ad listener
  late final BannerAdListener _listener;

  @override
  void onInit() {
    super.onInit();
    _initializeListener();
  }

  @override
  void onClose() {
    // Dispose all ads when controller is closed
    _disposeAllAds();
    super.onClose();
  }

  /// Initializes the banner ad listener
  void _initializeListener() {
    _listener = BannerAdListener(
      onAdLoaded: (ad) {
        debugPrint(
            'Banner ad loaded successfully: ${(ad as BannerAd).adUnitId}');
        _loadedAds.add(ad as BannerAd);
        _bannerReady.value = true;
        _failedAttempts.value = 0;
        _isLoading.value = false;
        _currentLoadingIndex.value++;

        // Continue loading the next ad if there are more ad units
        if (_currentLoadingIndex.value < _adUnitIds.length) {
          loadAd();
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('Banner ad failed to load: ${error.message}');
        ad.dispose();
        _failedAttempts.value++;
        _isLoading.value = false;

        if (_failedAttempts.value < MAX_FAILED_LOAD_ATTEMPTS) {
          // Retry loading the same ad
          loadAd();
        } else {
          // Move to next ad unit after max retries
          _failedAttempts.value = 0;
          _currentLoadingIndex.value++;

          if (_currentLoadingIndex.value < _adUnitIds.length) {
            loadAd();
          }
        }
      },
      onAdOpened: (ad) {
        debugPrint('Banner ad opened');
      },
      onAdClosed: (ad) {
        debugPrint('Banner ad closed');
        _refreshAd(ad as BannerAd);
      },
      onAdWillDismissScreen: (ad) {
        debugPrint('Banner ad will dismiss screen');
        _refreshAd(ad as BannerAd);
      },
      onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
      onPaidEvent: (ad, valueMicros, precision, currencyCode) =>
          debugPrint('Banner ad paid event: $currencyCode $valueMicros'),
    );
  }

  /// Loads a banner ad using the current ad unit ID
  void loadAd() {
    // Don't load if we have no ad unit IDs
    if (_adUnitIds.isEmpty) {
      debugPrint('No banner ad unit IDs provided');
      return;
    }

    // Don't start a new load if one is in progress
    if (_isLoading.value) {
      debugPrint('Banner ad load already in progress');
      return;
    }

    // Don't load more ads if we've gone through all ad unit IDs
    if (_currentLoadingIndex.value >= _adUnitIds.length) {
      debugPrint('All banner ad units attempted');
      return;
    }

    _isLoading.value = true;
    final adUnitId = _adUnitIds[_currentLoadingIndex.value];

    debugPrint(
        'Loading banner ad ${_currentLoadingIndex.value + 1}/${_adUnitIds.length}: $adUnitId');

    // Create and load the banner ad
    BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: _listener,
    ).load();
  }

  /// Refreshes an ad by disposing it and loading a new one
  void _refreshAd(BannerAd ad) {
    final index =
        _loadedAds.indexWhere((loadedAd) => loadedAd.adUnitId == ad.adUnitId);
    if (index != -1) {
      _loadedAds.removeAt(index);
      ad.dispose();

      // Adjust the current index to reload this slot
      if (_currentLoadingIndex.value > 0) {
        _currentLoadingIndex.value--;
      }

      loadAd();
    }
  }

  /// Disposes all loaded ads
  void _disposeAllAds() {
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    _loadedAds.clear();
  }

  /// Returns a widget displaying the banner ad
  Widget adWidget() {
    return Obx(() {
      if (bannerReady && deviceallow.allow()) {
        return Container(
          alignment: Alignment.center,
          width: _loadedAds.first.size.width.toDouble(),
          height: _loadedAds.first.size.height.toDouble(),
          child: AdWidget(ad: _loadedAds.first),
        );
      } else {
        return const SizedBox.shrink();
      }
    });
  }

  /// Creates and returns a banner ad widget with specified size
  Widget bannerAdWithSize({AdSize adSize = AdSize.banner}) {
    if (_adUnitIds.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use the first ad unit ID and rotate it to the end of the list
    final adUnitId = _adUnitIds.first;

    // Create the banner ad
    final banner = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      listener: _listener,
      request: const AdRequest(),
    );

    // Load the ad and return a widget
    return FutureBuilder(
      future: banner.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Rotate the ad unit ID to the end of the list
          _adUnitIds.removeAt(0);
          _adUnitIds.add(adUnitId);

          return Container(
            alignment: Alignment.center,
            width: banner.size.width.toDouble(),
            height: banner.size.height.toDouble(),
            child: AdWidget(ad: banner),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
