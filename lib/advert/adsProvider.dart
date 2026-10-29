import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/ad_provider_type.dart';
import '../model/adsmodel.dart';
import '../model/advertresponse.dart';
import 'AdProgressDialog.dart';
import 'event_reporter.dart';
import 'googleProvider.dart';
import 'googleads/bannerad.dart';
import 'unityprovider.dart';
import 'vungleprovider.dart';
import 'chartboostprovider.dart';
import 'levelplayprovider.dart';

class AdManager extends GetxController with WidgetsBindingObserver {
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
  VungleProvider? _vungleProvider;
  ChartboostProvider? _chartboostProvider;
  LevelPlayProvider? _levelPlayProvider;

  // Provider Enabled/Disabled State
  final Map<AdProviderType, bool> _enabledProviders = {
    AdProviderType.google: true,
    AdProviderType.unity: true,
    AdProviderType.vungle: true,
    AdProviderType.chartboost: true,
    AdProviderType.levelplay: true,
  };

  // Provider Priority Order
  List<AdProviderType> _providerPriorityOrder = [
    AdProviderType.google,
    AdProviderType.unity,
    AdProviderType.vungle,
    AdProviderType.chartboost,
    AdProviderType.levelplay,
  ];

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
  void Function(Advertresponse)? _onAdWatched;
  Function? _onAdClicked;
  Function? _onAdImpression;

  // Ad State Control
  bool enableAppOpenOnResume = true;
  DateTime? _lastAppOpenTime;
  bool _isAnyFullScreenAdShowing = false;
  OverlayEntry? _loadingOverlayEntry;
  static const Duration appOpenCooldown = Duration(seconds: 30);

  // Constructor
  AdManager(this._adsConfig, this.testmode) {
    _eventReporter = EventReporter();
    _initializeAdProviders();
    _startBannerRotation();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && enableAppOpenOnResume) {
      final now = DateTime.now();
      
      if (_isAnyFullScreenAdShowing) {
        debugPrint('AppOpen Guard: Full-screen ad is active or recently closed, skipping trigger.');
        return;
      }
      
      if (_lastAppOpenTime != null && now.difference(_lastAppOpenTime!) < appOpenCooldown) {
        debugPrint('AppOpen Guard: Cooldown active, skipping lifecycle trigger.');
        return;
      }
      
      showAppOpenAd();
    }
  }

  void _initializeAdProviders() {
    if (_adsConfig.enabledProviders != null) {
      _enabledProviders.addAll(_adsConfig.enabledProviders!);
    }

    if (_adsConfig.providerPriorityOrder != null && _adsConfig.providerPriorityOrder!.isNotEmpty) {
      _providerPriorityOrder = List.from(_adsConfig.providerPriorityOrder!);
    }
    
    if (_adsConfig.googlemodel != null) {
      _googleProvider = GoogleAdProvider(_adsConfig.googlemodel!, _eventReporter);
    }

    if (_adsConfig.unitymodel != null) {
      _unityProvider = UnityProvider(_adsConfig.unitymodel!, _eventReporter, testmode);
    }

    if (_adsConfig.vunglemodel != null) {
      _vungleProvider = VungleProvider(_adsConfig.vunglemodel!, _eventReporter, testmode);
    }

    if (_adsConfig.chartboostmodel != null) {
      _chartboostProvider = ChartboostProvider(_adsConfig.chartboostmodel!, _eventReporter, testmode);
    }

    if (_adsConfig.levelplaymodel != null) {
      _levelPlayProvider = LevelPlayProvider(_adsConfig.levelplaymodel!, _eventReporter, testmode);
    }
  }

  // Dynamic Provider Control Methods
  void setProviderEnabled(AdProviderType provider, bool enabled) {
    _enabledProviders[provider] = enabled;
    debugPrint('Provider ${provider.nameString} ${enabled ? "ENABLED" : "DISABLED"}');
  }

  void enableProvider(AdProviderType provider) => setProviderEnabled(provider, true);
  void disableProvider(AdProviderType provider) => setProviderEnabled(provider, false);

  bool isProviderEnabled(AdProviderType provider) => _enabledProviders[provider] ?? true;

  void setProviderPriorityOrder(List<AdProviderType> order) {
    _providerPriorityOrder = List.from(order);
    debugPrint('Provider Priority Order Updated: ${_providerPriorityOrder.map((e) => e.nameString).join(" -> ")}');
  }

  List<AdProviderType> get providerPriorityOrder => List.unmodifiable(_providerPriorityOrder);

  /// Returns list of active, initialized, and enabled providers in priority order
  List<AdProviderType> getActiveOrderedProviders() {
    return _providerPriorityOrder.where((type) {
      if (!isProviderEnabled(type)) return false;
      switch (type) {
        case AdProviderType.google:
          return _googleProvider != null;
        case AdProviderType.unity:
          return _unityProvider != null;
        case AdProviderType.vungle:
          return _vungleProvider != null;
        case AdProviderType.chartboost:
          return _chartboostProvider != null;
        case AdProviderType.levelplay:
          return _levelPlayProvider != null;
      }
    }).toList();
  }

  // Getters
  GoogleAdProvider? get googleProvider => _googleProvider;
  UnityProvider? get unityProvider => _unityProvider;
  VungleProvider? get vungleProvider => _vungleProvider;
  ChartboostProvider? get chartboostProvider => _chartboostProvider;
  LevelPlayProvider? get levelPlayProvider => _levelPlayProvider;
  int get providerCount => _getAvailableProviderCount();
  bool get isRewardedAdReady => _isAnyRewardedAdReady();

  int _getAvailableProviderCount() {
    return getActiveOrderedProviders().length;
  }

  bool _isAnyRewardedAdReady() {
    for (final type in getActiveOrderedProviders()) {
      switch (type) {
        case AdProviderType.google:
          if (_googleProvider?.hasRewardedAd == true) return true;
        case AdProviderType.unity:
          if (_unityProvider?.unityrewardedAd == true) return true;
        case AdProviderType.vungle:
          if (_vungleProvider?.hasRewardedAd == true) return true;
        case AdProviderType.chartboost:
          if (_chartboostProvider?.hasRewardedAd == true) return true;
        case AdProviderType.levelplay:
          if (_levelPlayProvider?.hasRewardedAd == true) return true;
      }
    }
    return false;
  }

  void preloadAllAds() {
    _preloadInterstitialAds();
    _preloadRewardedAds();
  }

  void _preloadInterstitialAds() {
    for (final type in getActiveOrderedProviders()) {
      switch (type) {
        case AdProviderType.google:
          _googleProvider?.loadInterstitialAd();
        case AdProviderType.unity:
          _unityProvider?.loadinterrtitialad();
        case AdProviderType.vungle:
          _vungleProvider?.loadAllAds();
        case AdProviderType.chartboost:
          _chartboostProvider?.loadAllAds();
        case AdProviderType.levelplay:
          _levelPlayProvider?.loadAllAds();
      }
    }
  }

  void _preloadRewardedAds() {
    for (final type in getActiveOrderedProviders()) {
      switch (type) {
        case AdProviderType.google:
          _googleProvider?.loadRewardAds();
        case AdProviderType.unity:
          _unityProvider?.loadrewardedad();
        case AdProviderType.vungle:
          _vungleProvider?.loadAllAds();
        case AdProviderType.chartboost:
          _chartboostProvider?.loadAllAds();
        case AdProviderType.levelplay:
          _levelPlayProvider?.loadAllAds();
      }
    }
  }

  /// Shows an interstitial ad following active provider priority order
  Future<Advertresponse> showInterstitialAd({
    BuildContext? context,
    String type = 'interstitial',
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
  }) async {
    if (context != null) _showAdLoadingDialog(context);
    _preloadInterstitialAds();
    _isAnyFullScreenAdShowing = true;
    
    final internalOnDismissed = () {
      _isAnyFullScreenAdShowing = false;
      _hideAdLoadingDialog();
      if (onAdDismissed != null) onAdDismissed();
    };

    final activeProviders = getActiveOrderedProviders();

    for (final providerType in activeProviders) {
      switch (providerType) {
        case AdProviderType.google:
          if (_googleProvider != null && _googleProvider!.hasInterstitialAdByType(type)) {
            _interstitialRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _googleProvider!.showInterstitialAd(
              type: type, 
              onAdClicked: onAdClicked, 
              onAdImpression: onAdImpression, 
              onAdDismissed: internalOnDismissed
            );
          }
        case AdProviderType.unity:
          if (_unityProvider != null && _unityProvider!.hasInterstitialAdByType(type)) {
            _interstitialRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _unityProvider!.showAd1(() {
              internalOnDismissed();
              if (onAdClicked != null) onAdClicked();
            }, type: type);
          }
        case AdProviderType.vungle:
          if (_vungleProvider != null && _vungleProvider!.hasInterstitialAdByType(type)) {
            _interstitialRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _vungleProvider!.showInterstitialAd(() {
              internalOnDismissed();
              if (onAdClicked != null) onAdClicked();
            }, type: type);
          }
        case AdProviderType.chartboost:
          if (_chartboostProvider != null && _chartboostProvider!.hasInterstitialAdByType(type)) {
            _interstitialRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _chartboostProvider!.showInterstitialAd(() {
              internalOnDismissed();
              if (onAdClicked != null) onAdClicked();
            }, type: type);
          }
        case AdProviderType.levelplay:
          if (_levelPlayProvider != null && _levelPlayProvider!.hasInterstitialAdByType(type)) {
            _interstitialRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _levelPlayProvider!.showInterstitialAd(() {
              internalOnDismissed();
              if (onAdClicked != null) onAdClicked();
            }, type: type);
          }
      }
    }

    _isAnyFullScreenAdShowing = false;
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
      _hideAdLoadingDialog();
      return Advertresponse.defaults();
    }
  }

  void _advanceInterstitialProvider() {
    _interstitialProviderIndex = _interstitialProviderIndex % providerCount + 1;
  }

  /// Shows a rewarded ad with fallback logic (High -> Low -> ...).
  Future<Advertresponse> showRewardedAd({
    BuildContext? context,
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
    required Map<String, String> customData,
    int retryDelaySeconds = 1,
    bool useProviderCycling = true,
  }) async {
    if (context != null) _showAdLoadingDialog(context);
    _preloadRewardedAds();
    _isAnyFullScreenAdShowing = true;
    
    final internalOnDismissed = () {
      _isAnyFullScreenAdShowing = false;
      _hideAdLoadingDialog();
      if (onAdDismissed != null) onAdDismissed();
    };

    final internalOnRewarded = ([dynamic provider]) {
      if (onRewarded != null) {
        _invokeOnRewarded(onRewarded, provider);
      }
    };

    if (!useProviderCycling) {
      final res = await _showGoogleRewardedWaterfall(
        type: type,
        onRewarded: internalOnRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: internalOnDismissed,
        customData: customData,
        retryDelaySeconds: retryDelaySeconds,
      );
      if (!res.status) _isAnyFullScreenAdShowing = false;
      return res;
    }

    final activeProviders = getActiveOrderedProviders();

    for (final providerType in activeProviders) {
      switch (providerType) {
        case AdProviderType.google:
          if (_googleProvider != null && _googleProvider!.hasRewardedAdByType(type)) {
            _rewardedRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _googleProvider!.showRewardedAd(
              type: type,
              onRewarded: internalOnRewarded,
              onAdClicked: onAdClicked,
              onAdImpression: onAdImpression,
              onAdDismissed: internalOnDismissed,
              customData: customData,
            );
          }
        case AdProviderType.unity:
          if (_unityProvider != null && _unityProvider!.hasRewardedAdByType(type)) {
            _rewardedRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _unityProvider!.showRewardedAd(internalOnRewarded, () {
              if (onAdClicked != null) onAdClicked();
            }, type: type, onAdDismissed: internalOnDismissed);
          }
        case AdProviderType.vungle:
          if (_vungleProvider != null && _vungleProvider!.hasRewardedAdByType(type)) {
            _rewardedRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _vungleProvider!.showRewardedAd(
              internalOnRewarded,
              () { if (onAdClicked != null) onAdClicked(); },
              type: type,
              onAdDismissed: internalOnDismissed,
            );
          }
        case AdProviderType.chartboost:
          if (_chartboostProvider != null && _chartboostProvider!.hasRewardedAdByType(type)) {
            _rewardedRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _chartboostProvider!.showRewardedAd(
              internalOnRewarded,
              () { if (onAdClicked != null) onAdClicked(); },
              type: type,
              onAdDismissed: internalOnDismissed,
            );
          }
        case AdProviderType.levelplay:
          if (_levelPlayProvider != null && _levelPlayProvider!.hasRewardedAdByType(type)) {
            _rewardedRetryAttempts = 0;
            _hideAdLoadingDialog();
            return _levelPlayProvider!.showRewardedAd(
              internalOnRewarded,
              () { if (onAdClicked != null) onAdClicked(); },
              type: type,
              onAdDismissed: internalOnDismissed,
            );
          }
      }
    }

    // RETRY LOGIC
    if (_rewardedRetryAttempts < MAX_RETRY_ATTEMPTS) {
      _rewardedRetryAttempts++;
      debugPrint('No rewarded ads ($type) ready. Retry attempt ${_rewardedRetryAttempts}/$MAX_RETRY_ATTEMPTS');
      await Future.delayed(Duration(seconds: retryDelaySeconds));
      return showRewardedAd(
        context: context,
        type: type,
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onAdDismissed,
        customData: customData,
        retryDelaySeconds: retryDelaySeconds,
        useProviderCycling: useProviderCycling,
      );
    } else {
      _rewardedRetryAttempts = 0;
      _isAnyFullScreenAdShowing = false;
      _hideAdLoadingDialog();
      return Advertresponse.defaults();
    }
  }

  Future<Advertresponse> _showGoogleRewardedWaterfall({
    required String type,
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
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
        onAdDismissed: onAdDismissed,
        customData: customData,
      );
    } else {
      if (_rewardedRetryAttempts < MAX_RETRY_ATTEMPTS) {
        _rewardedRetryAttempts++;
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        return _showGoogleRewardedWaterfall(
          type: type,
          onRewarded: onRewarded,
          onAdClicked: onAdClicked,
          onAdImpression: onAdImpression,
          onAdDismissed: onAdDismissed,
          customData: customData,
          retryDelaySeconds: retryDelaySeconds,
        );
      } else {
        _rewardedRetryAttempts = 0;
        return Advertresponse.defaults();
      }
    }
  }

  /// Shows only the high priority rewarded ad (independent call)
  Future<Advertresponse> showHighRewardedAd({
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
    required Map<String, String> customData,
  }) async {
    _preloadRewardedAds();
    _isAnyFullScreenAdShowing = true;
    if (_googleProvider != null) {
      return _googleProvider!.showHighRewardedAd(
        type: type,
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: () {
          _isAnyFullScreenAdShowing = false;
          if (onAdDismissed != null) onAdDismissed();
        },
        customData: customData,
      );
    }
    _isAnyFullScreenAdShowing = false;
    return Advertresponse.defaults();
  }

  /// Shows only the low priority rewarded ad (independent call)
  Future<Advertresponse> showLowRewardedAd({
    String type = 'rewarded',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
    required Map<String, String> customData,
  }) async {
    _preloadRewardedAds();
    _isAnyFullScreenAdShowing = true;
    if (_googleProvider != null) {
      return _googleProvider!.showLowRewardedAd(
        type: type,
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: () {
          _isAnyFullScreenAdShowing = false;
          if (onAdDismissed != null) onAdDismissed();
        },
        customData: customData,
      );
    }
    _isAnyFullScreenAdShowing = false;
    return Advertresponse.defaults();
  }

  /// Shows only the high priority interstitial ad (independent call)
  Future<Advertresponse> showHighInterstitialAd({
    String type = 'interstitial',
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
  }) async {
    _preloadInterstitialAds();
    if (_googleProvider != null) {
      return _googleProvider!.showHighInterstitialAd(
        type: type,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onAdDismissed,
      );
    }
    return Advertresponse.defaults();
  }

  /// Shows only the low priority interstitial ad (independent call)
  Future<Advertresponse> showLowInterstitialAd({
    String type = 'interstitial',
    Function? onAdClicked,
    Function? onAdImpression,
    Function? onAdDismissed,
  }) async {
    _preloadInterstitialAds();
    if (_googleProvider != null) {
      return _googleProvider!.showLowInterstitialAd(
        type: type,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onAdDismissed,
      );
    }
    return Advertresponse.defaults();
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

  /// Shows only the high priority rewarded interstitial ad (independent call)
  Future<Advertresponse> showHighRewardedInterstitialAd({
    String type = 'rewardedInterstitial',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) async {
    _preloadRewardedAds();
    if (_googleProvider != null) {
      return _googleProvider!.showHighRewardedInterstitialAd(
        type: type,
        onRewarded: onRewarded,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        customData: customData,
      );
    }
    return Advertresponse.defaults();
  }

  /// Shows only the low priority rewarded interstitial ad (independent call)
  Future<Advertresponse> showLowRewardedInterstitialAd({
    String type = 'rewardedInterstitial',
    Function? onRewarded,
    Function? onAdClicked,
    Function? onAdImpression,
    required Map<String, String> customData,
  }) async {
    _preloadRewardedAds();
    if (_googleProvider != null) {
      return _googleProvider!.showLowRewardedInterstitialAd(
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
      final widgetGoogle = _googleProvider!.showNativeAd(context, type: type);
      if (widgetGoogle is! SizedBox) return widgetGoogle;
    }
    if (_vungleProvider != null) {
      _vungleProvider!.loadNativeAd(type: type);
      return _vungleProvider!.showNativeAd(context, type: type);
    }
    return const SizedBox.shrink();
  }

  Widget showBannerAd({String type = 'banner'}) {
    return UnifiedBannerSlotWidget(adManager: this, type: type, priority: 'all');
  }

  /// Returns only the high priority banner ad widget (independent call)
  Widget showHighBannerAd({String type = 'banner'}) {
    return UnifiedBannerSlotWidget(adManager: this, type: type, priority: 'high');
  }

  /// Returns only the low priority banner ad widget (independent call)
  Widget showLowBannerAd({String type = 'banner'}) {
    return UnifiedBannerSlotWidget(adManager: this, type: type, priority: 'low');
  }

  /// Shows an app open ad
  void showAppOpenAd({String type = 'appOpen', Function? onAdDismissed}) {
    if (_googleProvider != null && _googleProvider!.hasAppOpenAdByType(type)) {
      _isAnyFullScreenAdShowing = true;
      _lastAppOpenTime = DateTime.now();

      _googleProvider!.showAppOpenAd(
        type: type,
        onAdDismissed: () {
          // Add a short delay before allowing another App Open trigger
          // to prevent the "resume after ad activity close" loop.
          Future.delayed(const Duration(seconds: 5), () {
            _isAnyFullScreenAdShowing = false;
          });
          if (onAdDismissed != null) onAdDismissed();
        }
      );
    } else if (_vungleProvider != null && _vungleProvider!.hasAppOpenAdByType(type)) {
      _isAnyFullScreenAdShowing = true;
      _lastAppOpenTime = DateTime.now();

      _vungleProvider!.showAppOpenAd(
        type: type,
        onAdDismissed: () {
          Future.delayed(const Duration(seconds: 5), () {
            _isAnyFullScreenAdShowing = false;
          });
          if (onAdDismissed != null) onAdDismissed();
        }
      );
    }
  }

  /// Shows only the high priority app open ad
  void showHighAppOpenAd({String type = 'appOpen', Function? onAdDismissed}) {
    if (_googleProvider != null) {
      _googleProvider!.loadAppOpenAd(type: type);
      _googleProvider!.showAppOpenAd(type: type, onAdDismissed: onAdDismissed);
    }
  }

  /// Shows only the low priority app open ad
  void showLowAppOpenAd({String type = 'appOpen', Function? onAdDismissed}) {
    if (_googleProvider != null) {
      _googleProvider!.loadAppOpenAd(type: type);
      _googleProvider!.showAppOpenAd(type: type, onAdDismissed: onAdDismissed);
    }
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
  /// [onAdWatched] or [onAdCompleted] is called for each individual ad watched in the sequence, passing [Advertresponse].
  void startAdSequence(BuildContext context, {
    required int total,
    required String adType,
    required String reason,
    required Map<String, String> customData,
    required VoidCallback onComplete,
    void Function(Advertresponse response)? onAdWatched,
    void Function(Advertresponse response)? onAdCompleted,
    Function? onAdClicked,
    Function? onAdImpression,
  }) {
    totalAds = total;
    _currentAdType = adType;
    _customData = customData;
    reasonads = reason;
    _onSequenceComplete = onComplete;
    _onAdWatched = onAdWatched ?? onAdCompleted;
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

  void _handleAdCompletion(BuildContext context, Advertresponse response) {
    if (!context.mounted) return;
    adsWatched++;
    _onAdWatched?.call(response);
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
    _hideAdLoadingDialog();
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
          _hideAdLoadingDialog();
        },
      ),
    );
  }

  void _showRetryDialog(BuildContext context) {
    if (!context.mounted) return;
    _hideAdLoadingDialog();
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
              _hideAdLoadingDialog();
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

  void _showAdLoadingDialog(BuildContext context) {
    if (!context.mounted || _loadingOverlayEntry != null) return;

    try {
      final overlayState = Overlay.maybeOf(context);
      if (overlayState == null) return;

      _loadingOverlayEntry = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C23),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFF9C304),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Loading ad...",
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () {
                      _hideAdLoadingDialog();
                      isShowingAds.value = false;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      overlayState.insert(_loadingOverlayEntry!);
    } catch (e) {
      debugPrint("Error showing ad loading overlay: $e");
    }
  }

  void _hideAdLoadingDialog() {
    if (_loadingOverlayEntry != null) {
      try {
        _loadingOverlayEntry!.remove();
      } catch (_) {}
      _loadingOverlayEntry = null;
    }
  }

  Future<void> _playCurrentAd(BuildContext context) async {
    _showAdLoadingDialog(context);

    Advertresponse result;
    Advertresponse? currentAdResponse;

    final onRewarded = () {
      final response = currentAdResponse ?? Advertresponse.loaded();
      _handleAdCompletion(context, response);
    };

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
          // useProviderCycling: false,
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
          // useProviderCycling: false,
        );
        break;
      case 'freemoney':
        result = await showRewardedAd(
          type: 'freemoney',
          onRewarded: onRewarded,
          onAdClicked: _onAdClicked,
          onAdImpression: _onAdImpression,
          customData: _customData,
          // useProviderCycling: false,
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

    currentAdResponse = result;
    _hideAdLoadingDialog();

    if (!result.status) {
      if (context.mounted) {
        _showRetryDialog(context);
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _googleProvider?.dispose();
    super.dispose();
  }
}

void _invokeOnRewarded(Function? callback, [dynamic provider]) {
  if (callback == null) return;
  if (provider is String) {
    if (callback is void Function(String?)) {
      callback(provider);
      return;
    }
    if (callback is void Function(String)) {
      callback(provider);
      return;
    }
    if (callback is void Function(Advertresponse)) {
      callback(Advertresponse.loaded(provider: provider));
      return;
    }
  } else if (provider is Advertresponse) {
    if (callback is void Function(Advertresponse)) {
      callback(provider);
      return;
    }
    if (callback is void Function(String?)) {
      callback(provider.provider);
      return;
    }
    if (callback is void Function(String)) {
      callback(provider.provider ?? '');
      return;
    }
  }

  if (callback is void Function()) {
    callback();
    return;
  }

  try {
    (callback as dynamic)(provider);
  } catch (_) {
    try {
      (callback as dynamic)();
    } catch (_) {}
  }
}

class UnifiedBannerSlotWidget extends StatefulWidget {
  final AdManager adManager;
  final String type;
  final String priority;

  const UnifiedBannerSlotWidget({
    super.key,
    required this.adManager,
    this.type = 'banner',
    this.priority = 'all',
  });

  @override
  State<UnifiedBannerSlotWidget> createState() => _UnifiedBannerSlotWidgetState();
}

class _UnifiedBannerSlotWidgetState extends State<UnifiedBannerSlotWidget> {
  bool _googleFailed = false;

  @override
  void initState() {
    super.initState();
    _subscribeToGoogleBanner();
  }

  void _subscribeToGoogleBanner() {
    final google = widget.adManager.googleProvider;
    if (google == null) {
      _googleFailed = true;
      return;
    }

    BannerAdManager? highManager;
    BannerAdManager? lowManager;

    if (widget.priority == 'all' || widget.priority == 'high') {
      highManager = google.getBannerManager('${widget.type}_high');
    }
    if (widget.priority == 'all' || widget.priority == 'low') {
      lowManager = google.getBannerManager('${widget.type}_low');
    }

    void checkStatus() {
      if (!mounted) return;
      
      bool hasGoogleAd = false;
      bool googleFailed = true;

      if (widget.priority == 'high') {
        hasGoogleAd = highManager?.hasAds ?? false;
        googleFailed = highManager?.hasFailed ?? true;
      } else if (widget.priority == 'low') {
        hasGoogleAd = lowManager?.hasAds ?? false;
        googleFailed = lowManager?.hasFailed ?? true;
      } else {
        hasGoogleAd = (highManager?.hasAds ?? false) || (lowManager?.hasAds ?? false);
        googleFailed = (highManager == null || highManager.hasFailed) && 
                       (lowManager == null || lowManager.hasFailed);
      }

      if (!hasGoogleAd && googleFailed && !_googleFailed) {
        setState(() {
          _googleFailed = true;
        });
      } else if (hasGoogleAd && _googleFailed) {
        setState(() {
          _googleFailed = false;
        });
      }
    }

    highManager?.addListener(checkStatus);
    lowManager?.addListener(checkStatus);
    checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    final google = widget.adManager.googleProvider;
    final unity = widget.adManager.unityProvider;
    final vungle = widget.adManager.vungleProvider;
    final chartboost = widget.adManager.chartboostProvider;
    final levelplay = widget.adManager.levelPlayProvider;

    if (!_googleFailed && google != null) {
      if (widget.priority == 'high') {
        final widgetHigh = google.showHighBannerAd(type: widget.type);
        if (widgetHigh is! SizedBox) return widgetHigh;
      } else if (widget.priority == 'low') {
        final widgetLow = google.showLowBannerAd(type: widget.type);
        if (widgetLow is! SizedBox) return widgetLow;
      } else {
        final widgetAll = google.showBannerAd(type: widget.type);
        if (widgetAll is! SizedBox) return widgetAll;
      }
    }

    if (unity != null) {
      return unity.adWidget();
    }

    if (vungle != null) {
      return vungle.adWidget();
    }

    if (chartboost != null) {
      return chartboost.adWidget();
    }

    if (levelplay != null) {
      return levelplay.adWidget();
    }

    return const SizedBox.shrink();
  }
}
