class Levelplaymodel {
  String _appKey = '';

  final Map<String, List<String>> rewardedPlacements = {};
  final Map<String, List<String>> interstitialPlacements = {};
  final List<String> _bannerPlacements = [];

  Levelplaymodel();

  set appKey(String value) => _appKey = value;
  String get appKey => _appKey;

  void addRewardedPlacement(String type, List<String> adUnitIds) {
    rewardedPlacements[type] = adUnitIds;
  }

  void addInterstitialPlacement(String type, List<String> adUnitIds) {
    interstitialPlacements[type] = adUnitIds;
  }

  void addBannerPlacement(List<String> adUnitIds) {
    _bannerPlacements.addAll(adUnitIds);
  }

  // Legacy/compatibility setters
  set bannerAdPlacementId(value) => _bannerPlacements.addAll(List<String>.from(value));
  List<String> get bannerAdPlacementId => _bannerPlacements;

  set interstitialVideoAdPlacementId(value) => addInterstitialPlacement('interstitial', List<String>.from(value));
  List<String> get interstitialVideoAdPlacementId => interstitialPlacements['interstitial'] ?? [];

  set rewardedVideoAdPlacementId(value) => addRewardedPlacement('rewarded', List<String>.from(value));
  List<String> get rewardedVideoAdPlacementId => rewardedPlacements['rewarded'] ?? [];
}
