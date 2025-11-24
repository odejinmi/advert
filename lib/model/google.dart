class Googlemodel {
  List<String> _interstitialAdUnitId = [];
  List<String> _rewardedAdUnitId = [];
  List<String> _rewardedInterstitialAdUnitId = [];
  List<String> _nativeAdUnitId = [];
  List<String> _bannerAdUnitId = [];

  Googlemodel();

  bool get googleempty {
    return _interstitialAdUnitId.isEmpty &&
        _rewardedAdUnitId.isEmpty &&
        _rewardedInterstitialAdUnitId.isEmpty &&
        _nativeAdUnitId.isEmpty &&
        _bannerAdUnitId.isEmpty;
  }

  List<String> get interstitialAdUnitId {
    return _interstitialAdUnitId;
  }

  set interstitialAdUnitId(value) {
    _interstitialAdUnitId = value;
  }

  List<String> get rewardedAdUnitId {
    return _rewardedAdUnitId;
  }

  set rewardedAdUnitId(value) {
    _rewardedAdUnitId = value;
  }

  List<String> get rewardedInterstitialAdUnitId {
    return _rewardedInterstitialAdUnitId;
  }

  set rewardedInterstitialAdUnitId(value) {
    _rewardedInterstitialAdUnitId = value;
  }

  List<String> get nativeAdUnitId {
    return _nativeAdUnitId;
  }

  set nativeAdUnitId(value) {
    _nativeAdUnitId = value;
  }

  List<String> get bannerAdUnitId {
    return _bannerAdUnitId;
  }

  set bannerAdUnitId(value) {
    _bannerAdUnitId = value;
  }
}
