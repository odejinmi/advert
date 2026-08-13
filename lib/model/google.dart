class Googlemodel {
  List<String> _interstitialAdUnitId = [];
  List<String> _interstitialAdUnitIdLow = [];
  
  List<String> _rewardedAdUnitId = [];
  List<String> _rewardedAdUnitIdLow = [];
  
  List<String> _spinAndWin = [];
  List<String> _spinAndWinLow = [];
  
  List<String> _freemoney = [];
  List<String> _freemoneyLow = [];
  List<String> _freemoneyInterstitial = [];
  
  List<String> _rewardedInterstitialAdUnitId = [];
  List<String> _rewardedInterstitialAdUnitIdLow = [];
  
  List<String> _nativeAdUnitId = [];
  List<String> _nativeAdUnitIdLow = [];
  
  List<String> _bannerAdUnitId = [];
  List<String> _bannerAdUnitIdLow = [];

  Googlemodel();

  bool get googleempty {
    return _interstitialAdUnitId.isEmpty &&
        _rewardedAdUnitId.isEmpty &&
        _rewardedInterstitialAdUnitId.isEmpty &&
        _nativeAdUnitId.isEmpty &&
        _bannerAdUnitId.isEmpty &&
        _freemoney.isEmpty &&
        _spinAndWin.isEmpty;
  }

  // Getters and Setters for High/Normal
  List<String> get interstitialAdUnitId => _interstitialAdUnitId;
  set interstitialAdUnitId(List<String> value) => _interstitialAdUnitId = value;

  List<String> get rewardedAdUnitId => _rewardedAdUnitId;
  set rewardedAdUnitId(List<String> value) => _rewardedAdUnitId = value;

  List<String> get spinAndWin => _spinAndWin;
  set spinAndWin(List<String> value) => _spinAndWin = value;

  List<String> get freemoney => _freemoney;
  set freemoney(List<String> value) => _freemoney = value;

  List<String> get rewardedInterstitialAdUnitId => _rewardedInterstitialAdUnitId;
  set rewardedInterstitialAdUnitId(List<String> value) => _rewardedInterstitialAdUnitId = value;

  List<String> get nativeAdUnitId => _nativeAdUnitId;
  set nativeAdUnitId(List<String> value) => _nativeAdUnitId = value;

  List<String> get bannerAdUnitId => _bannerAdUnitId;
  set bannerAdUnitId(List<String> value) => _bannerAdUnitId = value;

  // Getters and Setters for Low
  List<String> get interstitialAdUnitIdLow => _interstitialAdUnitIdLow;
  set interstitialAdUnitIdLow(List<String> value) => _interstitialAdUnitIdLow = value;

  List<String> get rewardedAdUnitIdLow => _rewardedAdUnitIdLow;
  set rewardedAdUnitIdLow(List<String> value) => _rewardedAdUnitIdLow = value;

  List<String> get spinAndWinLow => _spinAndWinLow;
  set spinAndWinLow(List<String> value) => _spinAndWinLow = value;

  List<String> get freemoneyLow => _freemoneyLow;
  set freemoneyLow(List<String> value) => _freemoneyLow = value;

  List<String> get freemoneyInterstitial => _freemoneyInterstitial;
  set freemoneyInterstitial(List<String> value) => _freemoneyInterstitial = value;

  List<String> get rewardedInterstitialAdUnitIdLow => _rewardedInterstitialAdUnitIdLow;
  set rewardedInterstitialAdUnitIdLow(List<String> value) => _rewardedInterstitialAdUnitIdLow = value;

  List<String> get nativeAdUnitIdLow => _nativeAdUnitIdLow;
  set nativeAdUnitIdLow(List<String> value) => _nativeAdUnitIdLow = value;

  List<String> get bannerAdUnitIdLow => _bannerAdUnitIdLow;
  set bannerAdUnitIdLow(List<String> value) => _bannerAdUnitIdLow = value;
}
