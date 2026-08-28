class Unitymodel {
  String _gameid = '';
  
  // Maps to store dynamic placement names to their IDs
  final Map<String, List<String>> rewardedPlacements = {};
  final Map<String, List<String>> interstitialPlacements = {};
  final List<String> _bannerPlacements = [];

  Unitymodel();

  set gameId(String value) => _gameid = value;
  String get gameId => _gameid;

  // Generic methods to add placements
  void addRewardedPlacement(String type, List<String> placementIds) {
    rewardedPlacements[type] = placementIds;
  }

  void addInterstitialPlacement(String type, List<String> placementIds) {
    interstitialPlacements[type] = placementIds;
  }

  // Legacy compatibility setters
  set bannerAdPlacementId(value) => _bannerPlacements.addAll(List<String>.from(value));
  List get bannerAdPlacementId => _bannerPlacements;

  set interstitialVideoAdPlacementId(value) => addInterstitialPlacement('interstitial', List<String>.from(value));
  List get interstitialVideoAdPlacementId => interstitialPlacements['interstitial'] ?? [];

  set rewardedVideoAdPlacementId(value) => addRewardedPlacement('rewarded', List<String>.from(value));
  List get rewardedVideoAdPlacementId => rewardedPlacements['rewarded'] ?? [];
}
