import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../device.dart';

class BannerListWidget extends StatefulWidget {
  final List<String> adUnitIds;
  final int numberOfAdsToShow;
  final Duration scrollInterval;
  final AdSize adSize;

  const BannerListWidget({
    Key? key,
    required this.adUnitIds,
    this.numberOfAdsToShow = 3,
    this.scrollInterval = const Duration(seconds: 2),
    this.adSize = AdSize.largeBanner,
  }) : super(key: key);

  @override
  BannerListWidgetState createState() => BannerListWidgetState();
}

class BannerListWidgetState extends State<BannerListWidget> {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 3;
  static const Duration RETRY_DELAY = Duration(seconds: 3);
  static const Duration LONG_RETRY_DELAY = Duration(seconds: 60);

  // Ad management variables
  final RxList<BannerAd> _loadedAds = <BannerAd>[].obs;
  final RxInt _currentIndex = 0.obs;
  final RxInt _failedAttempts = 0.obs;
  final RxBool _isLoading = false.obs;

  // Scroll control variables
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _scrollUp = true;

  @override
  void initState() {
    super.initState();
    if (deviceallow.allow()) {
      _loadAds();
    }
  }

  @override
  void didUpdateWidget(BannerListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If ad unit IDs or number of ads changed, reload ads
    if (!listEquals(widget.adUnitIds, oldWidget.adUnitIds) ||
        widget.numberOfAdsToShow != oldWidget.numberOfAdsToShow ||
        widget.adSize != oldWidget.adSize) {
      _disposeAllAds();
      _currentIndex.value = 0;
      _failedAttempts.value = 0;
      if (deviceallow.allow()) {
        _loadAds();
      }
    }
  }

  /// Loads banner ads up to the specified number
  void _loadAds() {
    // Don't load if we have no ad unit IDs or device is not allowed
    if (widget.adUnitIds.isEmpty || !deviceallow.allow()) {
      return;
    }

    // Don't start a new load if one is in progress
    if (_isLoading.value) {
      debugPrint('Banner ad load already in progress');
      return;
    }

    // If we have enough ads, don't load more
    if (_loadedAds.length >= widget.numberOfAdsToShow) {
      debugPrint('Already have enough banner ads loaded');
      _startAutoScroll();
      return;
    }

    // Reset index if we've gone through all ad unit IDs
    if (_currentIndex.value >= widget.adUnitIds.length) {
      _currentIndex.value = 0;
    }

    _isLoading.value = true;
    final adUnitId = widget.adUnitIds[_currentIndex.value];

    debugPrint(
        'Loading banner ad ${_currentIndex.value + 1}/${widget.adUnitIds.length}: $adUnitId');

    // Check if this ad unit ID is already loaded
    // if (_loadedAds.any((ad) => ad.adUnitId == adUnitId)) {
    //   debugPrint('Banner ad for $adUnitId already exists');
    //   _isLoading.value = false;
    //   _currentIndex.value = (_currentIndex.value + 1) % widget.adUnitIds.length;
    //   _loadAds();
    //   return;
    // }

    BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint(
              'Banner ad loaded successfully: ${(ad as BannerAd).adUnitId}');
          _loadedAds.add(ad as BannerAd);
          _isLoading.value = false;
          _failedAttempts.value = 0;
          _currentIndex.value =
              (_currentIndex.value + 1) % widget.adUnitIds.length;

          // Force UI update
          if (mounted) setState(() {});

          // Continue loading if we need more ads
          if (_loadedAds.length < widget.numberOfAdsToShow) {
            _loadAds();
          } else {
            // Start auto-scrolling when we have enough ads
            _startAutoScroll();
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          _isLoading.value = false;
          _failedAttempts.value++;

          if (_failedAttempts.value < MAX_FAILED_LOAD_ATTEMPTS) {
            // Retry after short delay
            Future.delayed(RETRY_DELAY, () {
              if (mounted) _loadAds();
            });
          } else {
            // Move to next ad unit
            _failedAttempts.value = 0;
            _currentIndex.value =
                (_currentIndex.value + 1) % widget.adUnitIds.length;

            if (_currentIndex.value == 0) {
              // We've tried all ad units, wait longer before retrying
              Future.delayed(LONG_RETRY_DELAY, () {
                if (mounted) _loadAds();
              });
            } else {
              // Try next ad unit
              _loadAds();
            }
          }

          // Force UI update
          if (mounted) setState(() {});
        },
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
          _refreshAd(ad as BannerAd);
        },
        onAdWillDismissScreen: (ad) {
          debugPrint('Banner ad will dismiss screen');
          _refreshAd(ad as BannerAd);
        },
        onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
      ),
    ).load();
  }

  /// Refreshes an ad by disposing it and loading a new one
  void _refreshAd(BannerAd ad) {
    final index =
        _loadedAds.indexWhere((loadedAd) => loadedAd == ad);
    if (index != -1) {
      _loadedAds[index].dispose();
      _loadedAds.removeAt(index);

      // Load a replacement ad
      _loadAds();
    }
  }

  /// Disposes all loaded ads
  void _disposeAllAds() {
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    _loadedAds.clear();
  }

  /// Starts auto-scrolling the banner list
  void _startAutoScroll() {
    // Cancel any existing timer
    _scrollTimer?.cancel();

    // Only start if we have enough ads to scroll
    if (_loadedAds.length <= 1) return;

    _scrollTimer = Timer.periodic(widget.scrollInterval, (timer) {
      if (_scrollController.hasClients) {
        if (_scrollUp) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: widget.scrollInterval,
            curve: Curves.easeInOut,
          );
          _scrollUp = false;
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: widget.scrollInterval,
            curve: Curves.easeInOut,
          );
          _scrollUp = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_loadedAds.isEmpty || !deviceallow.allow()) {
        return const SizedBox.shrink();
      }

      return ListView.builder(
        controller: _scrollController,
        itemCount: _loadedAds.length,
        itemBuilder: (context, index) {
          if (index < _loadedAds.length) {
            return Container(
              height: _loadedAds[index].size.height.toDouble(),
              width: _loadedAds[index].size.width.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _loadedAds[index]),
            );
          }
          return const SizedBox.shrink();
        },
      );
    });
  }

  @override
  void dispose() {
    _disposeAllAds();
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }
}
