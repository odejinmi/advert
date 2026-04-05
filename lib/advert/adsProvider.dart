import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/adsmodel.dart';
import '../model/advertresponse.dart';
import 'AdProgressDialog.dart';
import 'adcolonyProvider.dart';
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

  // Ad providers
  UnityProvider? _unityProvider;
  GoogleAdProvider? _googleProvider;
  final AdcolonyProvider _adcolonyProvider =
      Get.put(AdcolonyProvider(), permanent: true);

  // State variables for provider cycling
  final RxInt _interstitialProviderIndex = 1.obs;
  final RxInt _rewardedProviderIndex = 1.obs;
  final RxInt _interstitialRetryAttempts = 0.obs;
  final RxInt _rewardedRetryAttempts = 0.obs;
  final RxInt _bannerProviderIndex = 1.obs;

  // Ad Sequence State
  final RxInt adsWatched = 0.obs;
  final RxInt totalAds = 0.obs;
  final RxBool isShowingAds = false.obs;
  
  late String _currentAdType;
  final RxString reasonads = "".obs;
  late Map<String, String> _customData;
  late VoidCallback _onSequenceComplete;

  // Constructor
  AdManager(this._adsConfig);

  // Getters
  int get providerCount => _getAvailableProviderCount();
  bool get isRewardedAdReady => _isAnyRewardedAdReady();

  @override
  void onInit() {
    super.onInit();
    _initializeAdProviders();
    _startBannerRotation();
  }

  void _initializeAdProviders() {
    if (_adsConfig.googlemodel != null) {
      _googleProvider =
          Get.put(GoogleAdProvider(_adsConfig.googlemodel!), permanent: true);
    }

    if (_adsConfig.unitymodel != null) {
      _unityProvider =
          Get.put(UnityProvider(_adsConfig.unitymodel!), permanent: true);
    }
  }

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
  Future<Advertresponse> showInterstitialAd({Function? onclick}) async {
    _preloadInterstitialAds();
    if (_unityProvider != null && _unityProvider!.unityintersAd1 && _interstitialProviderIndex.value == 1) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts.value = 0;
      return _unityProvider!.showAd1(onclick);
    } else if (_googleProvider != null && _googleProvider!.hasInterstitialAd && _interstitialProviderIndex.value == 2) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts.value = 0;
      return _googleProvider!.showInterstitialAd();
    } else {
      return await _handleInterstitialRetry();
    }
  }

  Future<Advertresponse> _handleInterstitialRetry() async {
    if (_interstitialRetryAttempts.value < MAX_RETRY_ATTEMPTS) {
      _advanceInterstitialProvider();
      _interstitialRetryAttempts.value++;
      await Future.delayed(DEFAULT_RETRY_DELAY);
      return showInterstitialAd();
    } else {
      _interstitialRetryAttempts.value = 0;
      return Advertresponse.defaults();
    }
  }

  void _advanceInterstitialProvider() {
    _interstitialProviderIndex.value = _interstitialProviderIndex.value % providerCount + 1;
  }

  /// --- Standard Ad Show Methods ---

  Future<Advertresponse> showmergeRewardedAd(
      Function? onRewarded, Map<String, String> customData,
      [int retryDelaySeconds = 1]) async {
    _preloadRewardedAds();
    
    // 1: Unity, 2: Google
    int turn = _rewardedProviderIndex.value;

    // TRY CURRENT TURN
    if (turn == 1) {
      if (_unityProvider != null && _unityProvider!.unityrewardedAd) {
        _rewardedProviderIndex.value = 2; // Success: Next turn Google
        _rewardedRetryAttempts.value = 0;
        return _unityProvider!.showRewardedAd(onRewarded, () {});
      } else {
        // Fallback to Google immediately if Unity is not ready
        if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
          _rewardedProviderIndex.value = 1; // Google played: Next turn Unity
          _rewardedRetryAttempts.value = 0;
          return _googleProvider!.showmergeRewardedAd(onRewarded, customData);
        }
      }
    } else {
      if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
        _rewardedProviderIndex.value = 1; // Success: Next turn Unity
        _rewardedRetryAttempts.value = 0;
        return _googleProvider!.showmergeRewardedAd(onRewarded, customData);
      } else {
        // Fallback to Unity immediately if Google is not ready
        if (_unityProvider != null && _unityProvider!.unityrewardedAd) {
          _rewardedProviderIndex.value = 2; // Unity played: Next turn Google
          _rewardedRetryAttempts.value = 0;
          return _unityProvider!.showRewardedAd(onRewarded, () {});
        }
      }
    }

    // BOTH FAILED: RETRY LOGIC
    if (_rewardedRetryAttempts.value < MAX_RETRY_ATTEMPTS) {
      _rewardedRetryAttempts.value++;
      // Switch the turn for the next retry attempt
      _rewardedProviderIndex.value = (turn == 1) ? 2 : 1;
      
      debugPrint('No rewarded ads ready. Retry attempt ${_rewardedRetryAttempts.value}/$MAX_RETRY_ATTEMPTS');
      await Future.delayed(Duration(seconds: retryDelaySeconds));
      return showmergeRewardedAd(onRewarded, customData, retryDelaySeconds);
    } else {
      _rewardedRetryAttempts.value = 0;
      return Advertresponse.defaults();
    }
  }

  Future<Advertresponse> showspinAndWin(Function? onRewarded, Map<String, String> customData) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasspinAndWin) {
      return _googleProvider!.showspinAndWin(onRewarded, customData);
    }
    return Advertresponse.defaults();
  }

  Future<Advertresponse> showRewardedAd(Function? onRewarded, Map<String, String> customData) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
      return _googleProvider!.showRewardedAd(onRewarded, customData);
    }
    return Advertresponse.defaults();
  }

  Future<Advertresponse> showgooglemergeRewardedAd(Function? onRewarded, Map<String, String> customData,
  [int retryDelaySeconds = 1]) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
      _rewardedRetryAttempts.value = 0;
      return _googleProvider!.showmergeRewardedAd(onRewarded, customData);
    } else {
      if (_rewardedRetryAttempts.value < MAX_RETRY_ATTEMPTS) {
        _rewardedRetryAttempts.value++;
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        return showgooglemergeRewardedAd(onRewarded, customData, retryDelaySeconds);
      } else {
        _rewardedRetryAttempts.value = 0;
        return Advertresponse.defaults();
      }
    }
  }

  Future<Advertresponse> showRewardedInterstitialAd(Function? onRewarded, Map<String, String> customData) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasRewardedAd) {
      return _googleProvider!.showRewardedInterstitialAd(onRewarded, customData);
    }
    return Advertresponse.defaults();
  }

  Future<Advertresponse> showfreemoney(Function? onRewarded, Map<String, String> customData) async {
    _preloadRewardedAds();
    if (_googleProvider != null && _googleProvider!.hasfreemoney) {
      return _googleProvider!.showfreemoney(onRewarded, customData);
    }
    return Advertresponse.defaults();
  }

  void _advanceRewardedProvider() {
    _rewardedProviderIndex.value = _rewardedProviderIndex.value % providerCount + 1;
  }

  Widget showNativeAd() {
    if (_googleProvider != null) {
      _googleProvider!.loadNativeAd();
      return _googleProvider!.showNativeAd();
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
    _bannerProviderIndex.value = _bannerProviderIndex.value % providerCount + 1;
    update();
  }

  // --- Unified Ad Sequence Logic ---

  /// Starts a sequence of multiple ads.
  /// [adType] can be: 'mergeRewarded', 'rewarded', 'googleMergeRewarded', 'rewardedInterstitial', 'spinAndWin'
  void startAdSequence(BuildContext context, {
    required int total,
    required String adType,
    required String reason,
    required Map<String, String> customData,
    required VoidCallback onComplete
  }) {
    // adsWatched.value = 0;
    totalAds.value = total;
    _currentAdType = adType;
    _customData = customData;
    reasonads.value = reason;
    _onSequenceComplete = onComplete;
    isShowingAds.value = true;

    // If we've already watched some ads but the total changed (or we are just starting),
    // ensure we don't exceed the new total.
    // If you want to force reset on a NEW reason, you could compare 'reasonads.value'.
    if (adsWatched.value >= total) {
      adsWatched.value = 0;
    }

    if (total == 1) {
      _playCurrentAd(context);
    } else {
      _showAdProgressDialog(context);
    }
  }

  void _handleAdCompletion(BuildContext context) {
    adsWatched.value++;
    if (adsWatched.value < totalAds.value) {
      _showAdProgressDialog(context);
    } else {
      isShowingAds.value = false;
      _onSequenceComplete();
      adsWatched.value = 0; // Reset only after successful completion
    }
  }

  void _showAdProgressDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => AdProgressDialog(
        completed: adsWatched.value,
        total: totalAds.value,
        reason: reasonads.value,
        onTimerFinished: () {
          Navigator.of(dialogContext).pop();
          _playCurrentAd(context);
        },
        onCancel: () {
          isShowingAds.value = false;
          // adsWatched.value = 0;
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
        result = await showmergeRewardedAd(onRewarded, _customData);
        break;
      case 'rewarded':
        result = await showRewardedAd(onRewarded, _customData);
        break;
      case 'googleMergeRewarded':
        result = await showgooglemergeRewardedAd(onRewarded, _customData);
        break;
      case 'rewardedInterstitial':
        result = await showRewardedInterstitialAd(onRewarded, _customData);
        break;
      case 'spinAndWin':
        result = await showspinAndWin(onRewarded, _customData);
        break;
      case 'freemoney':
        result = await showfreemoney(onRewarded, _customData);
        break;
      default:
        result = await showRewardedAd(onRewarded, _customData);
    }

    if (!result.status) {
      _showRetryDialog(context);
    }
  }
}
