import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdManager extends GetxController {
  // Constants
  static const int AUTO_CLOSE_DELAY_SECONDS = 20;
  static const String FACTORY_ID = 'adFactoryExample';

  // Private variables
  final List<String> _adUnitIds;
  final Rx<NativeAd?> _nativeAd = Rx<NativeAd?>(null);
  final RxBool _isAdLoaded = false.obs;
  final RxInt _currentAdIndex = 0.obs;
  final RxInt _failedAttempts = 0.obs;

  // Constructor
  NativeAdManager(this._adUnitIds);

  // Getters
  bool get isAdLoaded => _isAdLoaded.value;
  NativeAd? get currentAd => _nativeAd.value;

  @override
  void onInit() {
    super.onInit();
    // Load ad if ad unit IDs are available
    if (_adUnitIds.isNotEmpty) {
      loadAd();
    }
  }

  @override
  void onClose() {
    // Dispose ad when controller is closed
    _disposeCurrentAd();
    super.onClose();
  }

  /// Loads a native ad using the current ad unit ID
  void loadAd() {
    // Don't load if we have no ad unit IDs
    if (_adUnitIds.isEmpty) {
      debugPrint('No native ad unit IDs provided');
      return;
    }

    // Dispose any existing ad before creating a new one
    _disposeCurrentAd();

    // Reset ad loaded state
    _isAdLoaded.value = false;

    // Get current ad unit ID (with cycling through available IDs)
    final adUnitId = _adUnitIds[_currentAdIndex.value % _adUnitIds.length];

    debugPrint('Loading native ad with ID: $adUnitId');

    _nativeAd.value = NativeAd(
      adUnitId: adUnitId,
      factoryId: FACTORY_ID,
      listener: NativeAdListener(
        onAdLoaded: _onAdLoaded,
        onAdFailedToLoad: _onAdFailedToLoad,
        onAdClicked: (ad) => debugPrint('Native ad clicked'),
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

    _nativeAd.value!.load();
  }

  /// Callback when ad is successfully loaded
  void _onAdLoaded(Ad ad) {
    debugPrint('Native ad loaded successfully');
    _isAdLoaded.value = true;
    _failedAttempts.value = 0;
    update();
  }

  /// Callback when ad fails to load
  void _onAdFailedToLoad(Ad ad, LoadAdError error) {
    debugPrint('Native ad failed to load: ${error.message}');
    ad.dispose();
    _nativeAd.value = null;
    _isAdLoaded.value = false;

    _failedAttempts.value++;

    // Try the next ad unit ID after failure
    if (_failedAttempts.value <= 3 && _adUnitIds.length > 1) {
      _currentAdIndex.value = (_currentAdIndex.value + 1) % _adUnitIds.length;
      loadAd();
    }

    update();
  }

  /// Disposes the current ad if it exists
  void _disposeCurrentAd() {
    if (_nativeAd.value != null) {
      _nativeAd.value!.dispose();
      _nativeAd.value = null;
    }
  }

  /// Closes the ad dialog and reloads a new ad
  void closeAd() {
    Get.back();
    _disposeCurrentAd();
    loadAd();
  }

  /// Returns a widget containing the native ad or an empty container if not loaded
  Widget buildAdWidget({bool autoClose = true}) {
    if (_nativeAd.value != null && _isAdLoaded.value) {
      if (autoClose) {
        // Set up auto-close timer
        Future.delayed(Duration(seconds: AUTO_CLOSE_DELAY_SECONDS))
            .then((_) => closeAd());
      }
      return AdWidget(ad: _nativeAd.value!);
    } else {
      return const SizedBox.shrink();
    }
  }

  /// Shows the ad in a dialog
  void showAdDialog({bool autoClose = true}) {
    if (!_isAdLoaded.value || _nativeAd.value == null) {
      debugPrint('Cannot show dialog: Native ad not loaded');
      return;
    }

    Get.dialog(
      Dialog(
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
                    onPressed: closeAd,
                  ),
                ],
              ),
            ),
            Container(
              height: 300, // Adjust height as needed
              padding: const EdgeInsets.all(8.0),
              child: buildAdWidget(autoClose: autoClose),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
