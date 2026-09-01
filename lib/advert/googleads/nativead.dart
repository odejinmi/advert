import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../event_reporter.dart';

class NativeAdManager {
  // Constants
  static const int AUTO_CLOSE_DELAY_SECONDS = 20;
  static const String FACTORY_ID = 'adFactoryExample';
  static const Duration initialRetryDelay = Duration(seconds: 15);
  static const Duration maxRetryDelay = Duration(seconds: 120);
  static const Duration minRequestInterval = Duration(seconds: 15);

  // Global tracker
  static final Map<String, DateTime> _globalLastRequestTimes = {};
  static final Map<String, DateTime> _failedAdUnitCooldowns = {};

  final EventReporter _reporter;
  final String _adType;

  // Private variables
  final List<String> _adUnitIds;
  NativeAd? _nativeAd;
  final List<NativeAd> _loadingAds = []; // Track ads that are currently loading
  bool _isAdLoaded = false;
  bool _isMountedInWidget = false;
  int _currentAdIndex = 0;
  int _failedAttempts = 0;

  final String? factoryId;

  // Constructor
  NativeAdManager(
    this._adUnitIds,
    this._reporter, {
    String adType = 'Native',
    this.factoryId,
  }) : _adType = adType {
    if (_adUnitIds.isNotEmpty) {
      final jitter = Duration(milliseconds: Random().nextInt(2000));
      Future.delayed(jitter, loadAd);
    }
  }

  // Getters
  bool get isAdLoaded => _isAdLoaded;
  NativeAd? get currentAd => _nativeAd;

  void dispose() {
    _disposeCurrentAd();
    for (final ad in _loadingAds) {
      ad.dispose();
    }
    _loadingAds.clear();
  }

  /// Loads a native ad using the current ad unit ID
  void loadAd() {
    if (_adUnitIds.isEmpty) {
      debugPrint('No native ad unit IDs provided');
      return;
    }

    _disposeCurrentAd();
    _isAdLoaded = false;
    _isMountedInWidget = false;

    final adUnitId = _adUnitIds[_currentAdIndex % _adUnitIds.length];
    final now = DateTime.now();

    // FAILURE COOLDOWN CHECK
    final failedCooldown = _failedAdUnitCooldowns[adUnitId];
    if (failedCooldown != null && now.isBefore(failedCooldown)) {
      final waitTime = failedCooldown.difference(now);
      debugPrint('AdUnitId $adUnitId in failure backoff cooldown (Native). Waiting ${waitTime.inSeconds}s');
      return;
    }

    // GLOBAL THROTTLING CHECK
    final lastRequest = _globalLastRequestTimes[adUnitId];
    if (lastRequest != null && now.difference(lastRequest) < minRequestInterval) {
      final waitTime = minRequestInterval - now.difference(lastRequest);
      debugPrint('Global Throttling (Native): ID $adUnitId requested too recently. Waiting ${waitTime.inSeconds}s');
      Future.delayed(waitTime, loadAd);
      return;
    }

    _globalLastRequestTimes[adUnitId] = now;

    debugPrint('Loading native ad with ID: $adUnitId');

    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      nativeTemplateStyle: factoryId == null
          ? NativeTemplateStyle(
              templateType: TemplateType.small,
            )
          : null,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          final loadedAd = ad as NativeAd;
          _loadingAds.remove(loadedAd);
          _reporter.reportEvent(
            event: AdEvent.displayed,
            adProvider: 'Google',
            adType: _adType,
            placementId: loadedAd.adUnitId,
          );
          _onAdLoaded(loadedAd);
        },
        onAdFailedToLoad: (ad, error) {
          final failedAd = ad as NativeAd;
          _loadingAds.remove(failedAd);
          _reporter.reportEvent(
            event: AdEvent.failed,
            adProvider: 'Google',
            adType: _adType,
            placementId: failedAd.adUnitId,
            errorMessage: error.message,
          );
          _onAdFailedToLoad(failedAd, error);
        },
        onAdClicked: (ad) {
          debugPrint('Native ad clicked');
          _reporter.reportEvent(
            event: AdEvent.clicked,
            adProvider: 'Google',
            adType: _adType,
            placementId: ad.adUnitId,
          );
        },
        onAdImpression: (ad) => debugPrint('Native ad impression recorded'),
        onAdClosed: (ad) => debugPrint('Native ad closed'),
        onAdOpened: (ad) => debugPrint('Native ad opened'),
        onAdWillDismissScreen: (ad) =>
            debugPrint('Native ad will dismiss screen'),
        onPaidEvent: (ad, valueMicros, precision, currencyCode) =>
            debugPrint('Native ad paid event: $currencyCode $valueMicros'),
      ),
      request: const AdRequest(),
    );
    
    _nativeAd = nativeAd;
    _loadingAds.add(nativeAd);
    nativeAd.load();
  }

  void _onAdLoaded(Ad ad) {
    debugPrint('Native ad loaded successfully');
    _isAdLoaded = true;
    _failedAttempts = 0;
  }

  void _onAdFailedToLoad(Ad ad, LoadAdError error) {
    final nativeAd = ad as NativeAd;
    debugPrint('Native ad failed to load (${nativeAd.adUnitId}): ${error.message}');
    ad.dispose();
    _nativeAd = null;
    _isAdLoaded = false;
    _isMountedInWidget = false;
    _failedAttempts++;

    // Exponential Backoff
    final backoffMultiplier = pow(2, min(_failedAttempts - 1, 4)).toDouble();
    final backoffSeconds = backoffMultiplier * initialRetryDelay.inSeconds;
    final clampedSeconds = backoffSeconds.toInt().clamp(initialRetryDelay.inSeconds, maxRetryDelay.inSeconds);
    final actualDelay = Duration(seconds: clampedSeconds);

    _failedAdUnitCooldowns[nativeAd.adUnitId] = DateTime.now().add(actualDelay);

    debugPrint('Backing off (Native: $_adType) for ${actualDelay.inSeconds}s due to failure');

    if (_adUnitIds.length > 1) {
      _currentAdIndex = (_currentAdIndex + 1) % _adUnitIds.length;
    }

    Future.delayed(actualDelay, () {
      if (_failedAttempts <= 3) {
        loadAd();
      }
    });
  }

  void _disposeCurrentAd() {
    if (_nativeAd != null) {
      _nativeAd!.dispose();
      _nativeAd = null;
    }
    _isMountedInWidget = false;
  }

  void closeAd(BuildContext context) {
    Navigator.of(context).pop();
    _disposeCurrentAd();
    loadAd();
  }

  Widget buildAdWidget(BuildContext context, {bool autoClose = true}) {
    if (_nativeAd != null && _isAdLoaded) {
      final ad = _nativeAd!;

      if (_isMountedInWidget) {
        // Current native ad is already mounted on another active widget/screen
        loadAd();
        return const SizedBox.shrink();
      }

      if (autoClose) {
        Future.delayed(Duration(seconds: AUTO_CLOSE_DELAY_SECONDS))
            .then((_) {
              if (Navigator.of(context).canPop()) {
                closeAd(context);
              }
            });
      }

      return _NativeAdSlotWidget(
        ad: ad,
        onMounted: () => _isMountedInWidget = true,
        onUnmounted: () => _isMountedInWidget = false,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void showAdDialog(BuildContext context, {bool autoClose = true}) {
    if (!_isAdLoaded || _nativeAd == null) {
      debugPrint('Cannot show dialog: Native ad not loaded');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => closeAd(context),
                  ),
                ],
              ),
            ),
            Container(
              height: 300,
              padding: const EdgeInsets.all(8.0),
              child: buildAdWidget(context, autoClose: autoClose),
            ),
          ],
        ),
      ),
    );
  }
}

class _NativeAdSlotWidget extends StatefulWidget {
  final NativeAd ad;
  final VoidCallback onMounted;
  final VoidCallback onUnmounted;

  const _NativeAdSlotWidget({
    required this.ad,
    required this.onMounted,
    required this.onUnmounted,
  });

  @override
  State<_NativeAdSlotWidget> createState() => _NativeAdSlotWidgetState();
}

class _NativeAdSlotWidgetState extends State<_NativeAdSlotWidget> {
  @override
  void initState() {
    super.initState();
    widget.onMounted();
  }

  @override
  void dispose() {
    widget.onUnmounted();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ObjectKey(widget.ad),
      height: 90,
      child: AdWidget(key: ObjectKey(widget.ad), ad: widget.ad),
    );
  }
}
