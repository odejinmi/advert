import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../event_reporter.dart';

class NativeAdManager {
  // Constants
  static const int AUTO_CLOSE_DELAY_SECONDS = 20;
  static const String FACTORY_ID = 'adFactoryExample';

  final EventReporter _reporter;

  // Private variables
  final List<String> _adUnitIds;
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  int _currentAdIndex = 0;
  int _failedAttempts = 0;

  // Constructor
  NativeAdManager(this._adUnitIds, this._reporter) {
    if (_adUnitIds.isNotEmpty) {
      loadAd();
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

    debugPrint('Loading native ad with ID: $adUnitId');

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: FACTORY_ID,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _reporter.reportEvent(
            event: AdEvent.displayed,
            adProvider: 'Google',
            adType: 'Native',
            placementId: ad.adUnitId,
          );
          _onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          _reporter.reportEvent(
            event: AdEvent.failed,
            adProvider: 'Google',
            adType: 'Native',
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
            adType: 'Native',
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
      customOptions: {'custom-option-1': 'custom-value-1'},
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

    if (_failedAttempts <= 3 && _adUnitIds.length > 1) {
      _currentAdIndex = (_currentAdIndex + 1) % _adUnitIds.length;
      loadAd();
    }
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
      return AdWidget(ad: _nativeAd!);
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
