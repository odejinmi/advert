class Googlemodel {
  // Map of ad types to their high/low unit IDs
  final Map<String, List<String>> rewardedHigh = {};
  final Map<String, List<String>> rewardedLow = {};
  
  final Map<String, List<String>> interstitialHigh = {};
  final Map<String, List<String>> interstitialLow = {};
  
  final Map<String, List<String>> nativeHigh = {};
  final Map<String, List<String>> nativeLow = {};
  
  final Map<String, List<String>> bannerHigh = {};
  final Map<String, List<String>> bannerLow = {};
  
  final Map<String, List<String>> rewardedInterstitialHigh = {};
  final Map<String, List<String>> rewardedInterstitialLow = {};


  Googlemodel();

  bool get googleempty {
    return rewardedHigh.isEmpty &&
        interstitialHigh.isEmpty &&
        nativeHigh.isEmpty &&
        bannerHigh.isEmpty &&
        rewardedInterstitialHigh.isEmpty;
  }

  // Generic methods to add placements
  void addRewardedPlacement(String type, {required List<String> high, List<String>? low}) {
    rewardedHigh[type] = high;
    if (low != null) rewardedLow[type] = low;
  }

  void addInterstitialPlacement(String type, {required List<String> high, List<String>? low}) {
    interstitialHigh[type] = high;
    if (low != null) interstitialLow[type] = low;
  }

  void addNativePlacement(String type, {required List<String> high, List<String>? low}) {
    nativeHigh[type] = high;
    if (low != null) nativeLow[type] = low;
  }

  void addBannerPlacement(String type, {required List<String> high, List<String>? low}) {
    bannerHigh[type] = high;
    if (low != null) bannerLow[type] = low;
  }

  void addRewardedInterstitialPlacement(String type, {required List<String> high, List<String>? low}) {
    rewardedInterstitialHigh[type] = high;
    if (low != null) rewardedInterstitialLow[type] = low;
  }

  // Legacy compatibility setters
  set interstitialAdUnitId(List<String> value) => addInterstitialPlacement('interstitial', high: value);
  set interstitialAdUnitIdLow(List<String> value) => interstitialLow['interstitial'] = value;

  set rewardedAdUnitId(List<String> value) => addRewardedPlacement('rewarded', high: value);
  set rewardedAdUnitIdLow(List<String> value) => rewardedLow['rewarded'] = value;

  set rewardedInterstitialAdUnitId(List<String> value) => addRewardedInterstitialPlacement('rewardedInterstitial', high: value);
  set rewardedInterstitialAdUnitIdLow(List<String> value) => rewardedInterstitialLow['rewardedInterstitial'] = value;

  set nativeAdUnitId(List<String> value) => addNativePlacement('native', high: value);
  set nativeAdUnitIdLow(List<String> value) => nativeLow['native'] = value;

  set bannerAdUnitId(List<String> value) => addBannerPlacement('banner', high: value);
  set bannerAdUnitIdLow(List<String> value) => bannerLow['banner'] = value;

  // Legacy compatibility getters
  List<String> get interstitialAdUnitId => interstitialHigh['interstitial'] ?? [];
  List<String> get interstitialAdUnitIdLow => interstitialLow['interstitial'] ?? [];
  List<String> get rewardedAdUnitId => rewardedHigh['rewarded'] ?? [];
  List<String> get rewardedAdUnitIdLow => rewardedLow['rewarded'] ?? [];
  List<String> get rewardedInterstitialAdUnitId => rewardedInterstitialHigh['rewardedInterstitial'] ?? [];
  List<String> get rewardedInterstitialAdUnitIdLow => rewardedInterstitialLow['rewardedInterstitial'] ?? [];
  List<String> get nativeAdUnitId => nativeHigh['native'] ?? [];
  List<String> get nativeAdUnitIdLow => nativeLow['native'] ?? [];
  List<String> get bannerAdUnitId => bannerHigh['banner'] ?? [];
  List<String> get bannerAdUnitIdLow => bannerLow['banner'] ?? [];
}
