import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final List<BannerAd> _loadedAds = [];
  int _currentIndex = 0;
  int _failedAttempts = 0;
  bool _isLoading = false;

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

    if (!listEquals(widget.adUnitIds, oldWidget.adUnitIds) ||
        widget.numberOfAdsToShow != oldWidget.numberOfAdsToShow ||
        widget.adSize != oldWidget.adSize) {
      _disposeAllAds();
      _currentIndex = 0;
      _failedAttempts = 0;
      if (deviceallow.allow()) {
        _loadAds();
      }
    }
  }

  /// Loads banner ads up to the specified number
  void _loadAds() {
    if (widget.adUnitIds.isEmpty || !deviceallow.allow()) {
      return;
    }

    if (_isLoading) {
      debugPrint('Banner ad load already in progress');
      return;
    }

    if (_loadedAds.length >= widget.numberOfAdsToShow) {
      debugPrint('Already have enough banner ads loaded');
      _startAutoScroll();
      return;
    }

    if (_currentIndex >= widget.adUnitIds.length) {
      _currentIndex = 0;
    }

    _isLoading = true;
    final adUnitId = widget.adUnitIds[_currentIndex];

    debugPrint(
        'Loading banner ad ${_currentIndex + 1}/${widget.adUnitIds.length}: $adUnitId');

    BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint(
              'Banner ad loaded successfully: ${(ad as BannerAd).adUnitId}');
          setState(() {
            _loadedAds.add(ad);
            _isLoading = false;
            _failedAttempts = 0;
            _currentIndex = (_currentIndex + 1) % widget.adUnitIds.length;
          });

          if (_loadedAds.length < widget.numberOfAdsToShow) {
            _loadAds();
          } else {
            _startAutoScroll();
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          _isLoading = false;
          _failedAttempts++;

          if (_failedAttempts < MAX_FAILED_LOAD_ATTEMPTS) {
            Future.delayed(RETRY_DELAY, () {
              if (mounted) _loadAds();
            });
          } else {
            _failedAttempts = 0;
            _currentIndex = (_currentIndex + 1) % widget.adUnitIds.length;

            if (_currentIndex == 0) {
              Future.delayed(LONG_RETRY_DELAY, () {
                if (mounted) _loadAds();
              });
            } else {
              _loadAds();
            }
          }
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

  void _refreshAd(BannerAd ad) {
    final index =
        _loadedAds.indexWhere((loadedAd) => loadedAd == ad);
    if (index != -1) {
      setState(() {
        _loadedAds[index].dispose();
        _loadedAds.removeAt(index);
      });
      _loadAds();
    }
  }

  void _disposeAllAds() {
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    _loadedAds.clear();
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();

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
  }

  @override
  void dispose() {
    _disposeAllAds();
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }
}
