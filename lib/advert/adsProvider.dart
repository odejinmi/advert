import 'package:flutter/material.dart';

import '../model/adsmodel.dart';
import '../model/advertresponse.dart';
import 'AdProgressDialog.dart';
import 'adcolonyProvider.dart';
import 'event_reporter.dart';
import 'googleProvider.dart';
import 'googleads/banner_admob.dart';
import 'googleads/bannerlist.dart';
import 'unityprovider.dart';

class AdManager {
  // Constants
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const Duration DEFAULT_RETRY_DELAY = Duration(seconds: 1);

  // Configuration
  final Adsmodel _adsConfig;
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
  bool isShowingAds = false;
  
  late String _currentAdType;
  String reasonads = "";
  late Map<String, String> _customData;
  late VoidCallback _onSequenceComplete;
  Function? _onAdClicked;
  Function? _onAdImpression;

  // Constructor
  AdManager(this._adsConfig) {
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
      _unityProvider = UnityProvider(_adsConfig.unitymodel!, _eventReporter);
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
    Function? onclick,
    Function? onAdClicked,
    Function? onAdImpression,
  }) async {
    _preloadInterstitialAds();
    if (_unityProvider != null &&
        _unityProvider!.unityintersAd1 &&
        _interstitialProviderIndex == 1) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts = 0;
      return _unityProvider!.showAd1(onclick);
    } else if (_googleProvider != null &&
        _googleProvider!.hasInterstitialAd &&
        _interstitialProviderIndex == 2) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts = 0;
      return _googleProvider!.showInterstitialAd();
    } else {
      return await _handleInterstitialRetry(
        onclick: onclick,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
      );
    }
  }

  Future<Advertresponse> _handleInterstitialRetry({
    Function? onclick,
    Function? onAdClicked,
    Function? onAdImpression,
  }) async {
    if (_interstitialRetryAttempts < MAX_RETRY_ATTEMPTS) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts++;
      await Future.delayed(DEFAULT_RETRY_DELAY);
      return showInterstitialAd(
        onclick: onclick,
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

  Future<Advertresponse> showmergeRewardedAd({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
    int retryDelaySeconds = 1,
  }) async {
    _preloadRewardedAds();

    // 1: Unity, 2: Google
    int turn = _rewardedProviderIndex;

    // TRY CURRENT TURN
    if (turn == 1) {
      if (_unityProvider != null && _unityProvider!.unityrewardedAd) {
        _rewardedProviderIndex = 2; // Success: Next turn Google
        _rewardedRetryAttempts = 0;
        return _unityProvider!.showRewardedAd(onRewarded, () {});
      } else {
        // Fallback to Google immediately if Unity is not ready
        if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
          _rewardedProviderIndex = 1; // Google played: Next turn Unity
          _rewardedRetryAttempts = 0;
          return _googleProvider!.showmergeRewardedAd(
            onRewarded: onRewarded,
            onAdClicked: onAdClicked,
            onAdImpression: onAdImpression,
            customData: customData,
          );
        }
      }
    } else {
      if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
        _rewardedProviderIndex = 1; // Success: Next turn Unity
        _rewardedRetryAttempts = 0;
        return _googleProvider!.showmergeRewardedAd(
          onRewarded: onRewarded,
          onAdClicked: onAdClicked,
          onAdImpression: onAdImpression,
          customData: customData,
        );
      } else {
        // Fallback to Unity immediately if Google is not ready
        if (_unityProvider != null && _unityProvider!.unityrewardedAd) {
          _rewardedProviderIndex = 2; // Unity played: Next turn Google
          _rewardedRetryAttempts = 0;
          return _unityProvider!.showRewardedAd(onRewarded, () {});
        }
      }
    }

    // BOTH FAILED: RETRY LOGIC
    if (_rewardedRetryAttempts < MAX_RETRY_ATTEMPTS) {
      _rewardedRetryAttempts++;
      // Switch the turn for the next retry attempt
      _rewardedProviderIndex = (turn == 1) ? 2 : 1;

      debugPrint(
          'No rewarded ads ready. Retry attempt ${_rewardedRetryAttempts}/$MAX_RETRY_ATTEMPTS');
      await Future.delayed(Duration(seconds: retryDelaySeconds));
      return showmergeRewardedAd(
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

  Future<Advertresponse> showspinAndWin({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasspinAndWin) {
      return _googleProvider!.showspinAndWin(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  Future<Advertresponse> showRewardedAd({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
      return _googleProvider!.showRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  Future<Advertresponse> showgooglemergeRewardedAd({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
    int retryDelaySeconds = 1,
  }) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
      _rewardedRetryAttempts = 0;
      return _googleProvider!.showmergeRewardedAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    } else {
      if (_rewardedRetryAttempts < MAX_RETRY_ATTEMPTS) {
        _rewardedRetryAttempts++;
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        return showgooglemergeRewardedAd(
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
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
      return _googleProvider!.showRewardedInterstitialAd(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  Future<Advertresponse> showfreemoney({
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasfreemoney) {
      return _googleProvider!.showfreemoney(
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  void _advanceRewardedProvider() {
    _rewardedProviderIndex = _rewardedProviderIndex % providerCount + 1;
  }

  Widget showNativeAd(BuildContext context) {
    if (_googleProvider != null) {
      _googleProvider!.loadNativeAd();
      return _googleProvider!.showNativeAd(context);
    }
    return Container();
  }

  Widget showBannerAd() {
    if (_googleProvider != null && _adsConfig.googlemodel != null) {
      return BannerAdWidget(adUnitIds: _adsConfig.googlemodel!.bannerAdUnitId);
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
  /// [adType] can be: 'mergeRewarded', 'rewarded', 'googleMergeRewarded', 'rewardedInterstitial', 'spinAndWin'
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
    isShowingAds = true;

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
    adsWatched++;
    if (adsWatched < totalAds) {
      _showAdProgressDialog(context);
    } else {
      isShowingAds = false;
      _onSequenceComplete();
      adsWatched = 0; // Reset only after successful completion
    }
  }

  void _showAdProgressDialog(BuildContext context) {
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
          isShowingAds = false;
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showRetryDialog(BuildContext context) {
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
              isShowingAds = false;
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
        result = await showmergeRewardedAd(
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
        );
        break;
      case 'rewarded':
        result = await showRewardedAd(
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
        );
        break;
      case 'googleMergeRewarded':
        result = await showgooglemergeRewardedAd(
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
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
        result = await showspinAndWin(
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
        );
        break;
      case 'freemoney':
        result = await showfreemoney(
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
        );
        break;
      default:
        result = await showRewardedAd(
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
        );
    }

    if (!result.status) {
      _showRetryDialog(context);
    }
  }

  void dispose() {
    _googleProvider?.dispose();
  }
}
