class Unitymodel{
  String _gameid = '';
  List _bannerAdPlacementId = [];
  List _interstitialVideoAdPlacementId = [];
  List _rewardedVideoAdPlacementId = [];

  Unitymodel();

  String get gameId {
    return _gameid;
  }

  List get bannerAdPlacementId {
    return _bannerAdPlacementId;
  }

  List get interstitialVideoAdPlacementId {
    return _interstitialVideoAdPlacementId;
  }

  List get rewardedVideoAdPlacementId {
    return _rewardedVideoAdPlacementId;
  }
}