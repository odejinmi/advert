import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../event_reporter.dart';

class NativeAdManager {
  // Constants
  static const int AUTO_CLOSE_DELAY_SECONDS = 20;
  static const String FACTORY_ID = 'adFactoryExample';
  static const Duration initialRetryDelay = Duration(seconds: 5);
  static const Duration maxRetryDelay = Duration(seconds: 60);
  static const Duration minRequestInterval = Duration(seconds: 10);

  // Global tracker
  static final Map<String, DateTime> _globalLastRequestTimes = {};

  final EventReporter _reporter;
  final String _adType;

  // Private variables
  final List<String> _adUnitIds;
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  int _currentAdIndex = 0;
  int _failedAttempts = 0;

  // Constructor
  NativeAdManager(this._adUnitIds, this._reporter, {String adType = 'Native'})
      : _adType = adType {
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
  }

  /// Loads a native ad using the current ad unit ID
  void loadAd() {
    if (_adUnitIds.isEmpty) {
      debugPrint('No native ad unit IDs provided');
      return;
    }

    _disposeCurrentAd();
    _isAdLoaded = false;

    final adUnitId = _adUnitIds[_currentAdIndex % _adUnitIds.length];

    // GLOBAL THROTTLING CHECK
    final now = DateTime.now();
    final lastRequest = _globalLastRequestTimes[adUnitId];
    if (lastRequest != null && now.difference(lastRequest) < minRequestInterval) {
      final waitTime = minRequestInterval - now.difference(lastRequest);
      debugPrint('Global Throttling (Native): ID $adUnitId requested too recently. Waiting ${waitTime.inSeconds}s');
      Future.delayed(waitTime, loadAd);
      return;
    }

    _globalLastRequestTimes[adUnitId] = now;

    debugPrint('Loading native ad with ID: $adUnitId');

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white12,
        cornerRadius: 12.0,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white54,
          size: 12.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _reporter.reportEvent(
            event: AdEvent.displayed,
            adProvider: 'Google',
            adType: _adType,
            placementId: ad.adUnitId,
          );
          _onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          _reporter.reportEvent(
            event: AdEvent.failed,
            adProvider: 'Google',
            adType: _adType,
            placementId: ad.adUnitId,
            errorMessage: error.message,
          );
          _onAdFailedToLoad(ad, error);
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

    _nativeAd!.load();
  }

  void _onAdLoaded(Ad ad) {
    debugPrint('Native ad loaded successfully');
    _isAdLoaded = true;
    _failedAttempts = 0;
  }

  void _onAdFailedToLoad(Ad ad, LoadAdError error) {
    debugPrint('Native ad failed to load: ${error.message}');
    ad.dispose();
    _nativeAd = null;
    _isAdLoaded = false;
    _failedAttempts++;

    // Exponential Backoff
    final backoffMultiplier = pow(2, min(_failedAttempts - 1, 4)).toDouble();
    final backoffSeconds = backoffMultiplier * initialRetryDelay.inSeconds;
    final clampedSeconds = backoffSeconds.toInt().clamp(initialRetryDelay.inSeconds, maxRetryDelay.inSeconds);
    final actualDelay = Duration(seconds: clampedSeconds);

    debugPrint('Backing off (Native: $_adType) for ${actualDelay.inSeconds}s due to failure');

    Future.delayed(actualDelay, () {
      if (_failedAttempts <= 3 && _adUnitIds.length > 1) {
        _currentAdIndex = (_currentAdIndex + 1) % _adUnitIds.length;
        loadAd();
      }
    });
  }

  void _disposeCurrentAd() {
    if (_nativeAd != null) {
      _nativeAd!.dispose();
      _nativeAd = null;
    }
  }

  void closeAd(BuildContext context) {
    Navigator.of(context).pop();
    _disposeCurrentAd();
    loadAd();
  }

  Widget buildAdWidget(BuildContext context, {bool autoClose = true}) {
    if (_nativeAd != null && _isAdLoaded) {
      if (autoClose) {
        Future.delayed(Duration(seconds: AUTO_CLOSE_DELAY_SECONDS))
            .then((_) {
              if (Navigator.of(context).canPop()) {
                closeAd(context);
              }
            });
      }
      return SizedBox(
        height: 90,
        child: AdWidget(ad: _nativeAd!),
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
