import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

import '../device.dart';
import '../event_reporter.dart';

class BannerAdManager extends ChangeNotifier {
  // Constants
  static const int MAX_FAILED_LOAD_ATTEMPTS = 5;
  static const Duration initialRetryDelay = Duration(seconds: 15);
  static const Duration maxRetryDelay = Duration(seconds: 120);
  static const Duration minRequestInterval = Duration(seconds: 15);

  // Global tracker
  static final Map<String, DateTime> _globalLastRequestTimes = {};
  static final Map<String, DateTime> _failedAdUnitCooldowns = {};
  static final Map<String, int> _failedAttemptsPerAdUnit = {};

  final EventReporter _reporter;
  final String _adType;

  // Private variables
  final List<String> _adUnitIds;
  final List<BannerAd> _loadedAds = [];
  final List<BannerAd> _loadingAds = []; // Keep reference to ads while they load
  final Set<BannerAd> _reservedAds = {}; // Track ads reserved by active widgets
  int _currentLoadingIndex = 0;
  bool _isLoading = false;
  bool _bannerReady = false;

  // Constructor
  BannerAdManager(this._adUnitIds, this._reporter, {String adType = 'Banner'})
      : _adType = adType {
    _initializeListener();
    final jitter = Duration(milliseconds: Random().nextInt(2000));
    Future.delayed(jitter, loadAd);
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get bannerReady => _bannerReady && _loadedAds.isNotEmpty;
  bool get hasAds => _loadedAds.isNotEmpty;

  // Banner ad listener
  late final BannerAdListener _listener;

  @override
  void dispose() {
    _disposeAllAds();
    super.dispose();
  }

  /// Checks if a BannerAd is loaded, active in instanceManager, and managed by this manager
  bool isAdValid(BannerAd ad) {
    return _loadedAds.contains(ad) && instanceManager.adIdFor(ad) != null;
  }

  /// Initializes the banner ad listener
  void _initializeListener() {
    _listener = BannerAdListener(
      onAdLoaded: (ad) {
        final bannerAd = ad as BannerAd;
        debugPrint(
            'Banner ad loaded successfully: ${bannerAd.adUnitId}');
        
        _loadingAds.remove(bannerAd); // Move from loading to loaded
        
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Google',
          adType: _adType,
          placementId: bannerAd.adUnitId,
        );
        _loadedAds.add(bannerAd);
        _bannerReady = true;
        _failedAttemptsPerAdUnit[bannerAd.adUnitId] = 0;
        _isLoading = false;
        _currentLoadingIndex++;

        notifyListeners();

        if (_currentLoadingIndex < _adUnitIds.length) {
          loadAd();
        }
      },
      onAdFailedToLoad: (ad, error) {
        final bannerAd = ad as BannerAd;
        debugPrint('Banner ad failed to load (${bannerAd.adUnitId}): ${error.message}');
        
        _loadingAds.remove(bannerAd);
        
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Google',
          adType: _adType,
          placementId: bannerAd.adUnitId,
          errorMessage: error.message,
        );
        bannerAd.dispose();
        
        final attempts = (_failedAttemptsPerAdUnit[bannerAd.adUnitId] ?? 0) + 1;
        _failedAttemptsPerAdUnit[bannerAd.adUnitId] = attempts;
        _isLoading = false;

        notifyListeners();

        // Exponential Backoff per ad unit ID
        final backoffMultiplier = pow(2, min(attempts - 1, 4)).toDouble();
        final backoffSeconds = backoffMultiplier * initialRetryDelay.inSeconds;
        final clampedSeconds = backoffSeconds.toInt().clamp(initialRetryDelay.inSeconds, maxRetryDelay.inSeconds);
        final actualDelay = Duration(seconds: clampedSeconds);

        // Record failure cooldown for this ad unit ID
        _failedAdUnitCooldowns[bannerAd.adUnitId] = DateTime.now().add(actualDelay);

        debugPrint('Backing off (Banner: $_adType, ID: ${bannerAd.adUnitId}) for ${actualDelay.inSeconds}s (attempt #$attempts)');

        // Cycle to next ad unit ID if available
        if (_adUnitIds.length > 1) {
          _currentLoadingIndex = (_currentLoadingIndex + 1) % _adUnitIds.length;
        }

        Future.delayed(actualDelay, () {
          if ((_failedAttemptsPerAdUnit[bannerAd.adUnitId] ?? 0) < MAX_FAILED_LOAD_ATTEMPTS) {
            loadAd();
          } else {
            _failedAttemptsPerAdUnit[bannerAd.adUnitId] = 0;
            if (_adUnitIds.length <= 1) {
              _currentLoadingIndex = 0;
            }
          }
        });
      },
      onAdOpened: (ad) {
        debugPrint('Banner ad opened');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Google',
          adType: _adType,
          placementId: (ad as BannerAd).adUnitId,
        );
      },
      onAdClosed: (ad) {
        debugPrint('Banner ad closed');
        _refreshAd(ad as BannerAd);
      },
      onAdWillDismissScreen: (ad) {
        debugPrint('Banner ad will dismiss screen');
        _refreshAd(ad as BannerAd);
      },
      onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
      onPaidEvent: (ad, valueMicros, precision, currencyCode) =>
          debugPrint('Banner ad paid event: $currencyCode $valueMicros'),
    );
  }

  /// Loads a banner ad using the current ad unit ID
  void loadAd() {
    if (_adUnitIds.isEmpty) {
      debugPrint('No banner ad unit IDs provided');
      return;
    }

    if (_isLoading) {
      debugPrint('Banner ad load already in progress');
      return;
    }

    if (_currentLoadingIndex >= _adUnitIds.length) {
      _currentLoadingIndex = 0; // Cycle back to allow loading additional ad instances
    }

    final adUnitId = _adUnitIds[_currentLoadingIndex];
    final now = DateTime.now();

    // FAILURE COOLDOWN CHECK
    final failedCooldown = _failedAdUnitCooldowns[adUnitId];
    if (failedCooldown != null && now.isBefore(failedCooldown)) {
      final waitTime = failedCooldown.difference(now);
      debugPrint('AdUnitId $adUnitId in failure backoff cooldown (Banner). Waiting ${waitTime.inSeconds}s');
      _isLoading = false;
      
      // Attempt to find an alternative ad unit ID that is not in cooldown
      if (_adUnitIds.length > 1) {
        for (int i = 0; i < _adUnitIds.length; i++) {
          final nextIndex = (_currentLoadingIndex + 1 + i) % _adUnitIds.length;
          final altId = _adUnitIds[nextIndex];
          final altCooldown = _failedAdUnitCooldowns[altId];
          if (altCooldown == null || !now.isBefore(altCooldown)) {
            _currentLoadingIndex = nextIndex;
            loadAd();
            return;
          }
        }
      }

      // If all ad unit IDs are in cooldown, schedule loadAd when the nearest cooldown expires
      Future.delayed(waitTime, loadAd);
      return;
    }

    // GLOBAL THROTTLING CHECK
    final lastRequest = _globalLastRequestTimes[adUnitId];
    if (lastRequest != null && now.difference(lastRequest) < minRequestInterval) {
      final waitTime = minRequestInterval - now.difference(lastRequest);
      debugPrint('Global Throttling (Banner): ID $adUnitId requested too recently. Waiting ${waitTime.inSeconds}s');
      Future.delayed(waitTime, loadAd);
      return;
    }

    _globalLastRequestTimes[adUnitId] = now;
    _isLoading = true;

    debugPrint(
        'Loading banner ad ${_currentLoadingIndex + 1}/${_adUnitIds.length}: $adUnitId');

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: _listener,
    );
    
    _loadingAds.add(bannerAd); // Keep reference
    bannerAd.load();
  }

  /// Finds, reserves, and returns an unmounted/unreserved banner ad if available
  BannerAd? getUnmountedAd() {
    for (final ad in _loadedAds) {
      if (instanceManager.adIdFor(ad) != null &&
          !ad.isMounted &&
          !_reservedAds.contains(ad)) {
        _reservedAds.add(ad);
        return ad;
      }
    }
    // If all loaded ads are currently reserved or mounted elsewhere, trigger loading a new banner ad if available
    if (!_isLoading) {
      loadAd();
    }
    return null;
  }

  /// Releases a reserved ad when a widget unmounts
  void releaseAd(BannerAd ad) {
    _reservedAds.remove(ad);
    notifyListeners();
  }

  /// Refreshes an ad by disposing it and loading a new one
  void _refreshAd(BannerAd ad) {
    _reservedAds.remove(ad);
    final index =
        _loadedAds.indexWhere((loadedAd) => loadedAd.adUnitId == ad.adUnitId);
    if (index != -1) {
      _loadedAds.removeAt(index);
      ad.dispose();

      if (_currentLoadingIndex > 0) {
        _currentLoadingIndex--;
      }

      notifyListeners();
      loadAd();
    }
  }

  /// Disposes all loaded ads
  void _disposeAllAds() {
    _reservedAds.clear();
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    for (final ad in _loadingAds) {
      ad.dispose();
    }
    _loadedAds.clear();
    _loadingAds.clear();
    notifyListeners();
  }

  /// Returns a widget displaying the banner ad
  Widget adWidget() {
    return BannerAdSlotWidget(manager: this);
  }

  /// Creates and returns a banner ad widget with specified size
  Widget bannerAdWithSize({AdSize adSize = AdSize.banner}) {
    if (_adUnitIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final adUnitId = _adUnitIds.first;

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      listener: _listener,
      request: const AdRequest(),
    );

    return FutureBuilder(
      future: banner.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
          _adUnitIds.removeAt(0);
          _adUnitIds.add(adUnitId);

          return Container(
            key: ObjectKey(banner),
            alignment: Alignment.center,
            width: banner.size.width.toDouble(),
            height: banner.size.height.toDouble(),
            child: AdWidget(key: ObjectKey(banner), ad: banner),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class BannerAdSlotWidget extends StatefulWidget {
  final BannerAdManager manager;

  const BannerAdSlotWidget({super.key, required this.manager});

  @override
  State<BannerAdSlotWidget> createState() => _BannerAdSlotWidgetState();
}

class _BannerAdSlotWidgetState extends State<BannerAdSlotWidget> {
  BannerAd? _assignedAd;

  @override
  void initState() {
    super.initState();
    widget.manager.addListener(_onManagerChanged);
    _checkAndAssignAd();
  }

  @override
  void dispose() {
    if (_assignedAd != null) {
      widget.manager.releaseAd(_assignedAd!);
    }
    widget.manager.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (_assignedAd != null && !widget.manager.isAdValid(_assignedAd!)) {
      widget.manager.releaseAd(_assignedAd!);
      setState(() {
        _assignedAd = null;
      });
    }
    if (_assignedAd == null) {
      _checkAndAssignAd();
    }
  }

  void _checkAndAssignAd() {
    final ad = widget.manager.getUnmountedAd();
    if (ad != null && mounted) {
      setState(() {
        _assignedAd = ad;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_assignedAd != null &&
        widget.manager.isAdValid(_assignedAd!) &&
        deviceallow.allow()) {
      return Container(
        alignment: Alignment.center,
        width: _assignedAd!.size.width.toDouble(),
        height: _assignedAd!.size.height.toDouble(),
        child: AdWidget(key: ObjectKey(_assignedAd), ad: _assignedAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
