class Vunglemodel {
  String _appId = '';

  final Map<String, List<String>> rewardedPlacements = {};
  final Map<String, List<String>> interstitialPlacements = {};
  final Map<String, List<String>> nativePlacements = {};
  final Map<String, List<String>> appOpenPlacements = {};
  final List<String> _bannerPlacements = [];

  Vunglemodel();

  set appId(String value) => _appId = value;
  String get appId => _appId;

  void addRewardedPlacement(String type, List<String> placementIds) {
    rewardedPlacements[type] = placementIds;
  }

  void addInterstitialPlacement(String type, List<String> placementIds) {
    interstitialPlacements[type] = placementIds;
  }

  void addNativePlacement(String type, List<String> placementIds) {
    nativePlacements[type] = placementIds;
  }

  void addAppOpenPlacement(String type, List<String> placementIds) {
    appOpenPlacements[type] = placementIds;
  }

  void addBannerPlacement(List<String> placementIds) {
    _bannerPlacements.addAll(placementIds);
  }

  // Legacy/compatibility setters
  set bannerAdPlacementId(value) => _bannerPlacements.addAll(List<String>.from(value));
  List<String> get bannerAdPlacementId => _bannerPlacements;

  set interstitialVideoAdPlacementId(value) => addInterstitialPlacement('interstitial', List<String>.from(value));
  List<String> get interstitialVideoAdPlacementId => interstitialPlacements['interstitial'] ?? [];

  set rewardedVideoAdPlacementId(value) => addRewardedPlacement('rewarded', List<String>.from(value));
  List<String> get rewardedVideoAdPlacementId => rewardedPlacements['rewarded'] ?? [];
}
