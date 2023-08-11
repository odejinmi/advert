class Unitymodel{
  String _gameid = '';
  List _bannerAdPlacementId = [];
  List _interstitialVideoAdPlacementId = [];
  List _rewardedVideoAdPlacementId = [];

  Unitymodel();

  set gameId(value)=> _gameid = value;
  String get gameId {
    return _gameid;
  }

  set bannerAdPlacementId(value)=> _bannerAdPlacementId = value;
  List get bannerAdPlacementId {
    return _bannerAdPlacementId;
  }

  set interstitialVideoAdPlacementId(value)=> _interstitialVideoAdPlacementId = value;
  List get interstitialVideoAdPlacementId {
    return _interstitialVideoAdPlacementId;
  }

  set rewardedVideoAdPlacementId(value)=> _rewardedVideoAdPlacementId = value;
  List get rewardedVideoAdPlacementId {
    return _rewardedVideoAdPlacementId;
  }
}