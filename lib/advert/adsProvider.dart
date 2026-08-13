import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/adsmodel.dart';
import '../model/advertresponse.dart';
import 'AdProgressDialog.dart';
import 'adcolonyProvider.dart';
import 'event_reporter.dart';
import 'googleProvider.dart';
import 'googleads/banner_admob.dart';
import 'googleads/bannerlist.dart';
import 'unityprovider.dart';

class AdManager extends GetxController {
  // Constants
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const Duration DEFAULT_RETRY_DELAY = Duration(seconds: 1);

  // Configuration
  final Adsmodel _adsConfig;
  final bool testmode;
  late final EventReporter _eventReporter;

  // Ad providers
  UnityProvider? _unityProvider;
  GoogleAdProvider? _googleProvider;
  late final AdcolonyProvider _adcolonyProvider;

  // State variables for provider cycling
  int _interstitialProviderIndex = 1;
  int _rewardedProviderIndex = 1;
  int _interstitialRetryAttempts = 0;
  int _rewardedRetryAttempts = 0;
  int _bannerProviderIndex = 1;

  // Ad Sequence State
  int adsWatched = 0;
  int totalAds = 0;
  final RxBool isShowingAds = false.obs;
  
  late String _currentAdType;
  String reasonads = "";
  late Map<String, String> _customData;
  late VoidCallback _onSequenceComplete;
  Function? _onAdClicked;
  Function? _onAdImpression;

  // Constructor
  AdManager(this._adsConfig, this.testmode) {
    _eventReporter = EventReporter();
    _initializeAdProviders();
    _startBannerRotation();
  }

  void _initializeAdProviders() {
    _adcolonyProvider = AdcolonyProvider();
    
    if (_adsConfig.googlemodel != null) {
      _googleProvider = GoogleAdProvider(_adsConfig.googlemodel!, _eventReporter);
    }

    if (_adsConfig.unitymodel != null) {
      _unityProvider = UnityProvider(_adsConfig.unitymodel!, _eventReporter, testmode);
    }
  }

  // Getters
  int get providerCount => _getAvailableProviderCount();
  bool get isRewardedAdReady => _isAnyRewardedAdReady();

  int _getAvailableProviderCount() {
    int count = 0;
    if (_unityProvider != null) count++;
    if (_googleProvider != null) count++;
    return count > 0 ? count : 1;
  }

  bool _isAnyRewardedAdReady() {
    return (_unityProvider?.unityrewardedAd == true) ||
        (_googleProvider?.hasRewardedAd == true);
  }

  void preloadAllAds() {
    _preloadInterstitialAds();
    _preloadRewardedAds();
  }

  void _preloadInterstitialAds() {
    if (_unityProvider != null) _unityProvider!.loadinterrtitialad();
    if (_googleProvider != null) _googleProvider!.loadInterstitialAd();
  }

  void _preloadRewardedAds() {
    if (_unityProvider != null) _unityProvider!.loadrewardedad();
    if (_googleProvider != null) _googleProvider!.loadRewardAds();
  }

  /// Shows an interstitial ad
  Future<Advertresponse> showInterstitialAd({
    String type = 'interstitial',
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
  }) async {
    _preloadInterstitialAds();
    
    int turn = _interstitialProviderIndex;
    
    if (turn == 1) {
      // Try Unity first
      if (_unityProvider != null && _unityProvider!.hasInterstitialAdByType(type)) {
        _advanceInterstitialProvider();
        _interstitialRetryAttempts = 0;
        return _unityProvider!.showAd1(onAdClicked, type: type);
      } 
      // Fallback to Google
      else if (_googleProvider != null && _googleProvider!.hasInterstitialAdByType(type)) {
        _advanceInterstitialProvider();
        _interstitialRetryAttempts = 0;
        return _googleProvider!.showInterstitialAd(type: type, onAdClicked: onAdClicked, onAdImpression: onAdImpression, onAdDismissed: onAdDismissed);
      }
    } else {
      // Try Google first
      if (_googleProvider != null && _googleProvider!.hasInterstitialAdByType(type)) {
        _advanceInterstitialProvider();
        _interstitialRetryAttempts = 0;
        return _googleProvider!.showInterstitialAd(type: type, onAdClicked: onAdClicked, onAdImpression: onAdImpression, onAdDismissed: onAdDismissed);
      }
      // Fallback to Unity
      else if (_unityProvider != null && _unityProvider!.hasInterstitialAdByType(type)) {
        _advanceInterstitialProvider();
        _interstitialRetryAttempts = 0;
        return _unityProvider!.showAd1(onAdClicked, type: type);
      }
    }

    // Both failed or not ready, try retry logic
    return await _handleInterstitialRetry(
      type: type,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
    );
  }

  Future<Advertresponse> _handleInterstitialRetry({
    required String type,
    Function? onAdClicked,
    Function? onAdImpression,
  }) async {
    if (_interstitialRetryAttempts < MAX_RETRY_ATTEMPTS) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts++;
      await Future.delayed(DEFAULT_RETRY_DELAY);
      return showInterstitialAd(
        type: type,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
      );
    } else {
      _interstitialRetryAttempts = 0;
      return Advertresponse.defaults();
    }
  }

  void _advanceInterstitialProvider() {
    _interstitialProviderIndex = _interstitialProviderIndex % providerCount + 1;
  }

  /// --- Standard Ad Show Methods ---

  Future<Advertresponse> showRewardedAd({
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
    int retryDelaySeconds = 1,
    bool useProviderCycling = true,
  }) async {
    _preloadRewardedAds();

    if (!useProviderCycling) {
      return _showGoogleRewardedOnly(
        type: type,
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
        retryDelaySeconds: retryDelaySeconds,
      );
    }

    // 1: Unity, 2: Google
    int turn = _rewardedProviderIndex;

    if (turn == 1) {
      if (_unityProvider != null && _unityProvider!.unityrewardedAd) {
        _rewardedProviderIndex = 2; 
        _rewardedRetryAttempts = 0;
        return _unityProvider!.showRewardedAd(onRewarded, () {});
      } else {
        if (_googleProvider != null && _googleProvider!.hasRewardedAdByType(type)) {
          _rewardedProviderIndex = 1; 
          _rewardedRetryAttempts = 0;
          return _googleProvider!.showRewardedAd(
            type: type,
            onRewarded: onRewarded,
            onAdClicked: onAdClicked,
            onAdImpression: onAdImpression,
            customData: customData,
          );
        }
      }
    } else {
      if (_googleProvider != null && _googleProvider!.hasRewardedAdByType(type)) {
        _rewardedProviderIndex = 1; 
        _rewardedRetryAttempts = 0;
        return _googleProvider!.showRewardedAd(
          type: type,
          onRewarded: onRewarded,
          onAdClicked: onAdClicked,
          onAdImpression: onAdImpression,
          customData: customData,
        );
      } else {
        if (_unityProvider != null && _unityProvider!.unityrewardedAd) {
          _rewardedProviderIndex = 2; 
          _rewardedRetryAttempts = 0;
          return _unityProvider!.showRewardedAd(onRewarded, () {});
        }
      }
    }

    // RETRY LOGIC
    if (_rewardedRetryAttempts < MAX_RETRY_ATTEMPTS) {
      _rewardedRetryAttempts++;
      _rewardedProviderIndex = (turn == 1) ? 2 : 1;

      debugPrint('No rewarded ads ($type) ready. Retry attempt ${_rewardedRetryAttempts}/$MAX_RETRY_ATTEMPTS');
      await Future.delayed(Duration(seconds: retryDelaySeconds));
      return showRewardedAd(
        type: type,
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
        retryDelaySeconds: retryDelaySeconds,
      );
    } else {
      _rewardedRetryAttempts = 0;
      return Advertresponse.defaults();
    }
  }

  Future<Advertresponse> _showGoogleRewardedOnly({
    required String type,
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
    int retryDelaySeconds = 1,
  }) async {
    if (_googleProvider != null && _googleProvider!.hasRewardedAdByType(type)) {
      _rewardedRetryAttempts = 0;
      return _googleProvider!.showRewardedAd(
        type: type,
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    } else {
      if (_rewardedRetryAttempts < MAX_RETRY_ATTEMPTS) {
        _rewardedRetryAttempts++;
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        return _showGoogleRewardedOnly(
          type: type,
          onRewarded: onRewarded,
          onAdClicked: onAdClicked,
          onAdImpression: onAdImpression,
          customData: customData,
          retryDelaySeconds: retryDelaySeconds,
        );
      } else {
        _rewardedRetryAttempts = 0;
        return Advertresponse.defaults();
      }
    }
  }

  Future<Advertresponse> showRewardedInterstitialAd({
    String type = 'rewardedInterstitial',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) async {
    _preloadRewardedAds();
    if (_googleProvider != null) {
      return _googleProvider!.showRewardedInterstitialAd(
        type: type,
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  // Note: showRewardedAd(Map) already exists, I should rename the unified one or replace it.
  // The original showRewardedAd(Map) was Google-only and didn't have type parameter.
  // I will replace it.

  void _advanceRewardedProvider() {
    _rewardedProviderIndex = _rewardedProviderIndex % providerCount + 1;
  }

  Widget showNativeAd(BuildContext context, {String type = 'native'}) {
    if (_googleProvider != null) {
      _googleProvider!.loadNativeAd(type: type);
      return _googleProvider!.showNativeAd(context, type: type);
    }
    return Container();
  }

  Widget showBannerAd({String type = 'banner'}) {
    if (_googleProvider != null) {
      return _googleProvider!.showBannerAd(type: type);
    }
    return const SizedBox.shrink();
  }

  Widget showBannerListAd(int numberOfAds) {
    if (_googleProvider != null && _adsConfig.googlemodel != null) {
      return BannerListWidget(
        adUnitIds: _adsConfig.googlemodel!.bannerAdUnitId,
        numberOfAdsToShow: numberOfAds,
      );
    }
    return const SizedBox.shrink();
  }

  void _startBannerRotation() {
    Future.delayed(const Duration(seconds: 30), () {
      _rotateBannerProvider();
      _startBannerRotation();
    });
  }

  void _rotateBannerProvider() {
    _bannerProviderIndex = _bannerProviderIndex % providerCount + 1;
  }

  // --- Unified Ad Sequence Logic ---

  /// Starts a sequence of multiple ads.
  /// [adType] can be any registered placement name (e.g., 'rewarded', 'freemoney', 'giveaway')
  void startAdSequence(BuildContext context, {
    required int total,
    required String adType,
    required String reason,
    required Map<String, String> customData,
    required VoidCallback onComplete,
    Function? onAdClicked,
    Function? onAdImpression,
  }) {
    totalAds = total;
    _currentAdType = adType;
    _customData = customData;
    reasonads = reason;
    _onSequenceComplete = onComplete;
    _onAdClicked = onAdClicked;
    _onAdImpression = onAdImpression;
    isShowingAds.value = true;

    if (adsWatched >= total) {
      adsWatched = 0;
    }

    if (total == 1) {
      _playCurrentAd(context);
    } else {
      _showAdProgressDialog(context);
    }
  }

  void _handleAdCompletion(BuildContext context) {
    if (!context.mounted) return;
    adsWatched++;
    if (adsWatched < totalAds) {
      _showAdProgressDialog(context);
    } else {
      isShowingAds.value = false;
      _onSequenceComplete();
      adsWatched = 0; // Reset only after successful completion
    }
  }

  void _showAdProgressDialog(BuildContext context) {
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => AdProgressDialog(
        completed: adsWatched,
        total: totalAds,
        reason: reasonads,
        onTimerFinished: () {
          Navigator.of(dialogContext).pop();
          _playCurrentAd(context);
        },
        onCancel: () {
          isShowingAds.value = false;
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showRetryDialog(BuildContext context) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Ad Not Available",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "No video available at the moment. Would you like to try again?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              isShowingAds.value = false;
              Navigator.of(dialogContext).pop();
            },
            child: const Text("Cancel", style: TextStyle(color: Color(0xFFF9C304))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _playCurrentAd(context);
            },
            child: const Text("Retry", style: TextStyle(color: Color(0xFFF9C304), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _playCurrentAd(BuildContext context) async {
    Advertresponse result;
    final onRewarded = () => _handleAdCompletion(context);

    switch (_currentAdType) {
      case 'mergeRewarded':
        result = await showRewardedAd(
          type: 'rewarded',
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
        );
        break;
      case 'rewarded':
        result = await showRewardedAd(
          type: 'rewarded',
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
          useProviderCycling: false,
        );
        break;
      case 'googleMergeRewarded':
        result = await showRewardedAd(
          type: 'rewarded',
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
          useProviderCycling: false,
        );
        break;
      case 'rewardedInterstitial':
        result = await showRewardedInterstitialAd(
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
        );
        break;
      case 'spinAndWin':
        result = await showRewardedAd(
          type: 'spinAndWin',
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
          useProviderCycling: false,
        );
        break;
      case 'freemoney':
        result = await showRewardedAd(
          type: 'freemoney',
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
          useProviderCycling: false,
        );
        break;
      default:
        result = await showRewardedAd(
          type: 'rewarded',
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
        );
    }

    if (!result.status) {
      if (context.mounted) {
        _showRetryDialog(context);
      }
    }
  }

  void dispose() {
    _googleProvider?.dispose();
  }
}
