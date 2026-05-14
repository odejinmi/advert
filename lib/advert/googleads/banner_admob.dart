import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final List<BannerAd> _loadedAds = [];
  int _currentIndex = 0;
  int _failedAttempts = 0;
  bool _isLoading = false;

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

    if (!listEquals(widget.adUnitIds, oldWidget.adUnitIds) ||
        widget.adSize != oldWidget.adSize) {
      _disposeAllAds();
      _currentIndex = 0;
      _failedAttempts = 0;
      if (deviceallow.allow()) {
        _loadAd();
      }
    }
  }

  /// Loads a banner ad using the current ad unit ID
  void _loadAd() {
    if (widget.adUnitIds.isEmpty || !deviceallow.allow()) {
      return;
    }

    if (_isLoading) {
      debugPrint('Banner ad load already in progress');
      return;
    }

    if (_currentIndex >= widget.adUnitIds.length) {
      debugPrint('All banner ad units attempted');
      return;
    }

    _isLoading = true;
    final adUnitId = widget.adUnitIds[_currentIndex];

    debugPrint(
        'Loading banner ad ${_currentIndex + 1}/${widget.adUnitIds.length}: $adUnitId');

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully: ${ad.adUnitId}');
          setState(() {
            _loadedAds.add(ad as BannerAd);
            _isLoading = false;
            _failedAttempts = 0;
            _currentIndex++;
          });

          if (_currentIndex < widget.adUnitIds.length) {
            _loadAd();
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          _isLoading = false;
          _failedAttempts++;

          if (_failedAttempts < MAX_FAILED_LOAD_ATTEMPTS) {
            Future.delayed(widget.retryDelay, () {
              if (mounted) _loadAd();
            });
          } else {
            _failedAttempts = 0;
            _currentIndex++;

            if (_currentIndex < widget.adUnitIds.length) {
              _loadAd();
            } else {
              _currentIndex = 0;
              Future.delayed(const Duration(seconds: 60), () {
                if (mounted) _loadAd();
              });
            }
          }
          if (mounted) setState(() {});
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
          setState(() {
            _loadedAds.remove(ad as BannerAd);
          });
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

  void _refreshAd(Ad ad) {
    _disposeCurrentAd(ad);
    
    if (_currentIndex >= widget.adUnitIds.length) {
      _currentIndex = 0;
    }
    
    _loadAd();
  }

  void _disposeCurrentAd(Ad ad) {
    if (_loadedAds.contains(ad)) {
      setState(() {
        _loadedAds.remove(ad);
      });
      ad.dispose();
    }
  }

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
      child: (_loadedAds.isNotEmpty && deviceallow.allow())
          ? SizedBox(
              width: _loadedAds.first.size.width.toDouble(),
              height: _loadedAds.first.size.height.toDouble(),
              child: AdWidget(ad: _loadedAds.first),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _disposeAllAds();
    super.dispose();
  }
}
