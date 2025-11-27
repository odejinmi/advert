class Googlemodel {
  List<String> _interstitialAdUnitId = [];
  List<String> _rewardedAdUnitId = [];
  String _spinAndWin = "";
  List<String> _rewardedInterstitialAdUnitId = [];
  List<String> _nativeAdUnitId = [];
  List<String> _bannerAdUnitId = [];

  Googlemodel();

  bool get googleempty {
    return _interstitialAdUnitId.isEmpty &&
        _rewardedAdUnitId.isEmpty &&
        _rewardedInterstitialAdUnitId.isEmpty &&
        _nativeAdUnitId.isEmpty &&
        _bannerAdUnitId.isEmpty&&
        _spinAndWin.isEmpty;
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

  String get spinAndWin {
    return _spinAndWin;
  }

  set spinAndWin(value) {
    _spinAndWin = value;
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
