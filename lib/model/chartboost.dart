class Chartboostmodel {
  String _appId = '';
  String _appSignature = '';

  final Map<String, List<String>> rewardedPlacements = {};
  final Map<String, List<String>> interstitialPlacements = {};
  final List<String> _bannerPlacements = [];

  Chartboostmodel();

  set appId(String value) => _appId = value;
  String get appId => _appId;

  set appSignature(String value) => _appSignature = value;
  String get appSignature => _appSignature;

  void addRewardedPlacement(String type, List<String> locations) {
    rewardedPlacements[type] = locations;
  }

  void addInterstitialPlacement(String type, List<String> locations) {
    interstitialPlacements[type] = locations;
  }

  void addBannerPlacement(List<String> locations) {
    _bannerPlacements.addAll(locations);
  }

  // Legacy/compatibility setters
  set bannerAdPlacementId(value) => _bannerPlacements.addAll(List<String>.from(value));
  List<String> get bannerAdPlacementId => _bannerPlacements;

  set interstitialVideoAdPlacementId(value) => addInterstitialPlacement('interstitial', List<String>.from(value));
  List<String> get interstitialVideoAdPlacementId => interstitialPlacements['interstitial'] ?? [];

  set rewardedVideoAdPlacementId(value) => addRewardedPlacement('rewarded', List<String>.from(value));
  List<String> get rewardedVideoAdPlacementId => rewardedPlacements['rewarded'] ?? [];
}
